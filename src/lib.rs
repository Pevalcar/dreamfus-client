//! DreamFus Client - Tauri Backend
//! 
//! This module handles:
//! 1. WebSocket authentication (port 5557) - auth_request, server_selection
//! 2. TCP game connection (port 5555) - SimpleProtocol with VarInt framing
//! 3. Ticket-based server handoff
//!
//! Architecture: Separate reader tasks, no blocking Mutex during I/O

use serde::{Deserialize, Serialize};
use std::sync::Arc;
use std::time::Duration;
use tauri::{emit, Emitter, Manager, State};
use tokio::net::{TcpListener, TcpStream, WebSocketStream};
use tokio::sync::{mpsc, Mutex, RwLock};
use tokio_tungstenite::tungstenite::protocol::Message;

// =============================================================================
// State Management
// =============================================================================

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConnectionState {
    Disconnected,
    Connecting,
    Authenticating,
    Authenticated { accountId: i64, ticket: String },
    ConnectingGame { host: String, port: u16 },
    InGame,
    Error(String),
}

impl std::fmt::Display for ConnectionState {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ConnectionState::Disconnected => write!(f, "Disconnected"),
            ConnectionState::Connecting => write!(f, "Connecting"),
            ConnectionState::Authenticating => write!(f, "Authenticating"),
            ConnectionState::Authenticated { accountId, .. } => {
                write!(f, "Authenticated(accountId={accountId})")
            }
            ConnectionState::ConnectingGame { host, port } => {
                write!(f, "ConnectingGame({host}:{port})")
            }
            ConnectionState::InGame => write!(f, "InGame"),
            ConnectionState::Error(msg) => write!(f, "Error: {msg}"),
        }
    }
}

pub struct ClientConnection {
    pub state: ConnectionState,
    pub host: String,
    pub port: u16,
    pub account_id: i64,
    pub ticket: String,
    pub game_stream: Option<TcpStream>,
}

impl Default for ClientConnection {
    fn default() -> Self {
        Self {
            state: ConnectionState::Disconnected,
            host: String::new(),
            port: 5555,
            account_id: 0,
            ticket: String::new(),
            game_stream: None,
        }
    }
}

#[derive(Debug)]
pub struct AppState {
    pub connection: Arc<RwLock<ClientConnection>>,
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            connection: Arc::new(RwLock::new(ClientConnection::default())),
        }
    }
}

// =============================================================================
// Protocol Messages (JSON)
// =============================================================================

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct AuthRequest {
    #[serde(rename = "type")]
    pub type_field: String,
    pub token: String,
    pub install_id: String,
    pub lang: String,
    pub version: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ServerSelectionRequest {
    #[serde(rename = "type")]
    pub type_field: String,
    pub account_id: i64,
    pub server_id: i32,
    pub lang: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ServerSelectionResponse {
    #[serde(rename = "type")]
    pub type_field: String,
    pub success: bool,
    pub error: Option<String>,
    pub ticket: Option<String>,
    pub host: Option<String>,
    pub ports: Option<Vec<u32>>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AuthResponse {
    #[serde(rename = "type")]
    pub type_field: String,
    pub success: bool,
    pub error: Option<String>,
    pub account_id: Option<i64>,
    pub servers: Option<Vec<ServerInfo>>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ServerInfo {
    pub id: i32,
    pub name: String,
    pub population: i32,
    #[serde(rename = "is_full")]
    pub is_full: bool,
}

// =============================================================================
// Protocol Utilities (VarInt + framing for game server)
// =============================================================================

pub mod protocol {
    use super::*;

    pub const MAX_FRAME_LENGTH: usize = 8 * 1024 * 1024; // 8MB

    /// Read a VarInt from bytes
    pub fn read_varint(data: &[u8]) -> Option<(u32, usize)> {
        let mut result: u32 = 0;
        let mut shift: u32 = 0;
        let mut position: usize = 0;

        while position < data.len() {
            let byte = data[position];
            position += 1;
            result |= ((byte & 0x7F) as u32) << shift;
            if (byte & 0x80) == 0 {
                return Some((result, position));
            }
            shift += 7;
            if shift > 28 {
                return None;
            }
        }
        None
    }

    /// Write a VarInt
    pub fn write_varint(mut value: u32) -> Vec<u8> {
        let mut result = Vec::new();
        loop {
            let mut byte = (value & 0x7F) as u8;
            value >>= 7;
            if value != 0 {
                byte |= 0x80;
            }
            result.push(byte);
            if value == 0 {
                break;
            }
        }
        result
    }

    /// Read a frame with VarInt length prefix (for game server protocol)
    pub async fn read_frame(stream: &mut TcpStream) -> Option<Vec<u8>> {
        use tokio::io::{AsyncReadExt, ReadBuf};

        let mut len_bytes = [0u8; 5];
        let mut read_pos = 0;

        while read_pos < 5 {
            let mut buf = [0u8; 1];
            match stream.read(&mut buf).await {
                Ok(0) => return None, // Connection closed
                Ok(_) => {
                    len_bytes[read_pos] = buf[0];
                    read_pos += 1;
                    if (buf[0] & 0x80) == 0 {
                        break;
                    }
                }
                Err(_) => return None,
            }
        }

        let (length, _) = read_varint(&len_bytes[..read_pos])?;
        if length as usize > MAX_FRAME_LENGTH {
            return None;
        }

        let mut payload = vec![0u8; length as usize];
        let mut total_read = 0;
        while total_read < payload.len() {
            match stream.read(&mut payload[total_read..]).await {
                Ok(0) => return None,
                Ok(n) => total_read += n,
                Err(_) => return None,
            }
        }

        Some(payload)
    }

    /// Write a frame with VarInt length prefix
    pub async fn write_frame(stream: &mut TcpStream, payload: &[u8]) -> std::io::Result<()> {
        use tokio::io::AsyncWriteExt;

        let len_varint = write_varint(payload.len() as u32);
        stream.write_all(&len_varint).await?;
        stream.write_all(payload).await?;
        stream.flush().await
    }
}

// =============================================================================
// Connection Commands
// =============================================================================

#[tauri::command]
async fn connect_auth(
    state: State<AppState>,
    host: String,
    port: u16,
    token: String,
    install_id: String,
    lang: String,
) -> Result<String, String> {
    let auth_port = if port == 5555 { 5557 } else { port };

    {
        let conn = state.connection.read().await;
        if conn.state == ConnectionState::Authenticated {
            return Err("Already authenticated".to_string());
        }
    }

    // Update state to connecting
    {
        let mut conn = state.connection.write().await;
        conn.state = ConnectionState::Connecting;
        conn.host = host.clone();
        conn.port = port;
    }

    let ws_url = format!("ws://{}:{}", host, auth_port);
    let conn_state = state.connection.clone();

    let result = tauri::async_runtime::spawn(async move {
        let (ws_stream, _) = tokio_tungstenite::connect_async(&ws_url.parse().unwrap())
            .await
            .map_err(|e| format!("WebSocket connection failed: {}", e))?;

        let (mut write, mut read) = ws_stream.split();
        let (msg_tx, mut msg_rx) = mpsc::channel::<String>(16);

        // Spawn reader task
        let msg_tx_clone = msg_tx.clone();
        let reader_task = tauri::async_runtime::spawn(async move {
            while let Some(msg) = read.next().await {
                let msg = msg.map_err(|e| e.to_string())?;
                match msg {
                    Message::Binary(buf) => {
                        if let Ok(json) = String::from_utf8(buf.to_vec()) {
                            let _ = msg_tx_clone.send(json).await;
                        }
                    }
                    _ => {}
                }
            }
        });

        // Send auth request
        let auth_req = AuthRequest {
            type_field: "auth_request".to_string(),
            token,
            install_id,
            lang,
            version: "3.6.10.10".to_string(),
        };

        let json = serde_json::to_string(&auth_req)
            .map_err(|e| format!("Failed to serialize auth request: {}", e))?;

        write.send(Message::Binary(json.into())).await?;

        // Wait for auth response
        let auth_response: AuthResponse = loop {
            match msg_rx.recv().await {
                Some(msg) => {
                    let parsed: serde_json::Value =
                        serde_json::from_str(&msg).map_err(|e| e.to_string())?;
                    if parsed.get("type") == Some(&serde_json::json!("auth_response")) {
                        return serde_json::from_value(parsed).map_err(|e| e.to_string());
                    }
                    if parsed.get("type") == Some(&serde_json::json!("error")) {
                        return Err(parsed.get("message").unwrap_or("Auth error").to_string());
                    }
                }
                None => return Err("WebSocket closed".to_string()),
            }
        };

        Ok::<_, String>(auth_response)
    })
    .await.map_err(|e| format!("Spawn error: {:?}", e))?;

    match result {
        Ok(auth_resp) => {
            if !auth_resp.success {
                let err = auth_resp.error.unwrap_or("Unknown error".to_string());
                (*state.connection.write().await) = ClientConnection::default();
                return Err(err);
            }

            let account_id = auth_resp.account_id.unwrap_or(0);
            let servers = auth_resp.servers.unwrap_or_default();

            // Auto-select server 290 (DreamFus)
            let server_info = servers
                .iter()
                .find(|s| s.id == 290)
                .cloned()
                .unwrap_or(ServerInfo {
                    id: 290,
                    name: "DreamFus".to_string(),
                    population: 0,
                    is_full: false,
                });

            // Update state to authenticated
            {
                let mut conn = state.connection.write().await;
                conn.state = ConnectionState::Authenticated {
                    accountId: account_id,
                    ticket: String::new(),
                };
                conn.account_id = account_id;
            }

            // Request server selection
            let selection_req = ServerSelectionRequest {
                type_field: "server_selection".to_string(),
                account_id,
                server_id: server_info.id,
                lang: lang.clone(),
            };

            let selection_json =
                serde_json::to_string(&selection_req).map_err(|e| e.to_string())?;

            // Send server selection and wait for response
            let host = state.connection.read().await.host.clone();
            let port = state.connection.read().await.port;

            // For simplicity, we return the server info and let the frontend handle the rest
            Ok(format!(
                "Authenticated account_id={} servers=[{}]",
                account_id,
                serde_json::to_string(&servers).unwrap_or_default()
            ))
        }
        Err(e) => {
            (*state.connection.write().await) = ClientConnection::default();
            Err(e)
        }
    }
}

#[tauri::command]
async fn connect_game(
    state: State<AppState>,
    host: String,
    port: u16,
    ticket: String,
) -> Result<String, String> {
    // Connect to the game server via TCP with ticket
    let addr = format!("{}:{}", host, port);

    match TcpStream::connect(&addr).await {
        Ok(mut stream) => {
            // Send ticket as first message (game server expects this)
            let ticket_msg = format!("{{\"ticket\":\"{}\"}}", ticket);
            let frame = protocol::write_varint(ticket_msg.len() as u32);
            let mut full_msg = frame;
            full_msg.extend(ticket_msg.as_bytes());

            use tokio::io::AsyncWriteExt;
            stream.write_all(&full_msg).await?;

            // Update state
            {
                let mut conn = state.connection.write().await;
                conn.game_stream = Some(stream);
                conn.state = ConnectionState::InGame;
                conn.ticket = ticket;
            }

            Ok(format!("Connected to game server at {}:{}", host, port))
        }
        Err(e) => Err(format!("Game server connection failed: {}", e)),
    }
}

#[tauri::command]
async fn get_connection_state(state: State<AppState>) -> ConnectionState {
    state.connection.read().await.state.clone()
}

#[tauri::command]
async fn disconnect(state: State<AppState>) -> Result<String, String> {
    let mut conn = state.connection.write().await;
    conn.game_stream = None;
    conn.state = ConnectionState::Disconnected;
    conn.account_id = 0;
    conn.ticket = String::new();
    Ok("Disconnected".to_string())
}

#[tauri::command]
async fn send_game_message(
    state: State<AppState>,
    opcode: String,
    payload_hex: String,
) -> Result<String, String> {
    use tokio::io::AsyncWriteExt;

    let hex_str = if payload_hex.starts_with("0x") {
        &payload_hex[2..]
    } else if payload_hex.is_empty() {
        ""
    } else {
        &payload_hex
    };

    let payload = if hex_str.is_empty() {
        Vec::new()
    } else {
        hex::decode(hex_str).map_err(|e| format!("Invalid hex: {}", e))?
    };

    // Build envelope
    let envelope = build_envelope(&opcode, &payload);

    let mut conn = state.connection.write().await;
    if let Some(stream) = &mut conn.game_stream {
        protocol::write_frame(stream, &envelope)
            .await
            .map_err(|e| format!("Write failed: {}", e))?;
        Ok(format!("Sent {}", opcode))
    } else {
        Err("Not connected to game server".to_string())
    }
}

// =============================================================================
// Helper Functions
// =============================================================================

#[derive(Debug, Clone, Copy, PartialEq)]
enum FrameDirection {
    Unknown,
    ServerPush,
    ClientRequest,
    ServerReply,
}

fn build_envelope(opcode: &str, payload: &[u8]) -> Vec<u8> {
    let mut result = Vec::new();

    // Root field 2 = client-request
    let root_field = 2u32;

    // Build inner Any message
    let mut inner_any = Vec::new();

    // Field 1 of inner Any: type.ankama.com/{opcode}
    let type_url = format!("type.ankama.com/{}", opcode);
    let type_url_bytes = type_url.as_bytes();
    inner_any.extend(protocol::write_varint(1 << 3 | 2));
    inner_any.extend(protocol::write_varint(type_url_bytes.len() as u32));
    inner_any.extend(type_url_bytes);

    // Field 2 of inner Any: actual payload
    inner_any.extend(protocol::write_varint(2 << 3 | 2));
    inner_any.extend(protocol::write_varint(payload.len() as u32));
    inner_any.extend(payload);

    // Wrap as root field
    result.extend(protocol::write_varint(root_field << 3 | 2));
    result.extend(protocol::write_varint(inner_any.len() as u32));
    result.extend(inner_any);

    result
}

// =============================================================================
// Tauri Entry Point
// =============================================================================

#[tauri::command]
#[tauri::emit]
fn register_commands(app: tauri::AppHandle) {
    app.emit("connection-state-changed", "initialized");
}

fn main() {
    tauri::Builder::default()
        .manage(AppState::default())
        .invoke_handler(tauri::generate_handler![
            connect_auth,
            connect_game,
            get_connection_state,
            disconnect,
            send_game_message,
            register_commands
        ])
        .setup(|app| {
            let handle = app.handle().clone();
            tauri::async_runtime::spawn(async move {
                tokio::time::sleep(Duration::from_millis(100)).await;
                let _ = handle.emit("client-ready", "DreamFus client backend initialized");
            });
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}