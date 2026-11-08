//! DreamFus Tauri Backend - Entry Point

#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::time::Duration;
use tokio::net::TcpStream;
use tokio_tungstenite::tungstenite::protocol::Message;
use futures_util::stream::StreamExt;
use futures_util::SinkExt;
use serde_json::json;
use tokio::sync::mpsc;
use tokio::io::AsyncWriteExt;

use dreamfus_client::{
    AppState, ConnectionState, ClientConnection,
    AuthRequest, AuthResponse,
    protocol,
    parse_a2d_command, get_a2d_sprites_command, check_a2d_file_command,
    CharacterDisplayData,
};

// =============================================================================
// Tauri Commands - Connection Management
// =============================================================================

#[tauri::command]
async fn connect_auth(
    state: tauri::State<'_, AppState>,
    host: String,
    port: u16,
    token: String,
    install_id: String,
    lang: String,
) -> Result<String, String> {
    let auth_port = if port == 5555 { 5557 } else { port };

    {
        let conn = state.connection.read().await;
        if matches!(conn.state, ConnectionState::Authenticated { .. }) {
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

    // Spawn the main auth loop
    let auth_fut = async move {
        let (ws_stream, _) = tokio_tungstenite::connect_async(&ws_url)
            .await
            .map_err(|e| format!("WebSocket connection failed: {}", e))?;

        let (mut write, mut read) = ws_stream.split();
        let (msg_tx, mut msg_rx) = mpsc::channel::<String>(16);

        // Spawn reader task
        let msg_tx_clone = msg_tx.clone();
        let _reader_task = tauri::async_runtime::spawn(async move {
            while let Some(msg_result) = read.next().await {
                if let Ok(msg) = msg_result {
                    match msg {
                        Message::Binary(buf) => {
                            if let Ok(json) = String::from_utf8(buf.to_vec()) {
                                let _ = msg_tx_clone.send(json).await;
                            }
                        }
                        _ => {}
                    }
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

        write.send(Message::Binary(json.into())).await.map_err(|e| e.to_string())?;

        // Wait for auth response
        let mut auth_response: Option<AuthResponse> = None;
        loop {
            match msg_rx.recv().await {
                Some(msg) => {
                    let parsed: serde_json::Value =
                        serde_json::from_str(&msg).map_err(|e| e.to_string())?;
                    if parsed.get("type") == Some(&serde_json::json!("auth_response")) {
                        auth_response = Some(serde_json::from_value(parsed).map_err(|e| e.to_string())?);
                        break;
                    }
                    if parsed.get("type") == Some(&serde_json::json!("error")) {
                        return Err(parsed.get("message").and_then(|v| v.as_str()).unwrap_or("Auth error").to_string());
                    }
                }
                None => return Err("WebSocket closed".to_string()),
            }
        }
        
        Ok(auth_response.unwrap())
    };

    let auth_resp = auth_fut.await.map_err(|e| format!("Auth error: {:?}", e))?;

    if !auth_resp.success {
        let err = auth_resp.error.unwrap_or("Unknown error".to_string());
        { let _ = state.connection.write().await; *state.connection.write().await = ClientConnection::default(); }
        return Err(err);
    }

    let account_id = auth_resp.account_id.unwrap_or(0);
    let servers = auth_resp.servers.unwrap_or_default();

    // Update state to authenticated
    {
        let mut conn = state.connection.write().await;
        conn.state = ConnectionState::Authenticated {
            account_id,
            ticket: String::new(),
        };
        conn.account_id = account_id;
    }

    // For simplicity, we return the server info and let the frontend handle the rest
    Ok(format!(
        "Authenticated account_id={} servers=[{}]",
        account_id,
        serde_json::to_string(&servers).unwrap_or_default()
    ))
}

#[tauri::command]
async fn connect_game(
    state: tauri::State<'_, AppState>,
    host: String,
    port: u16,
    ticket: String,
) -> Result<String, String> {
    // Connect to the game server via TCP with ticket
    let addr = format!("{}:{}", host, port);

    match TcpStream::connect(&addr).await {
        Ok(mut stream) => {
            // Send ticket as first message (game server expects this)
            let ticket_msg = json!({"ticket": &ticket});
            let ticket_json = serde_json::to_string(&ticket_msg)
                .map_err(|e| format!("JSON encode error: {}", e))?;
            let frame = protocol::write_varint(ticket_json.len() as u32);
            let mut full_msg = frame;
            full_msg.extend(ticket_json.as_bytes());

            stream.write_all(&full_msg).await.map_err(|e| e.to_string())?;

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
async fn get_connection_state(state: tauri::State<'_, AppState>) -> Result<ConnectionState, String> {
    Ok(state.connection.read().await.state.clone())
}

#[tauri::command]
async fn disconnect(state: tauri::State<'_, AppState>) -> Result<String, String> {
    let mut conn = state.connection.write().await;
    conn.game_stream = None;
    conn.state = ConnectionState::Disconnected;
    conn.account_id = 0;
    conn.ticket = String::new();
    Ok("Disconnected".to_string())
}

#[tauri::command]
async fn send_game_message(
    state: tauri::State<'_, AppState>,
    opcode: String,
    payload_hex: String,
) -> Result<String, String> {
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
// Tauri Commands - A2D Avatar Parsing
// =============================================================================

#[tauri::command]
async fn parse_character_a2d(path: String) -> Result<CharacterDisplayData, String> {
    parse_a2d_command(path).await
}

#[tauri::command]
async fn get_a2d_sprites(path: String) -> Result<Vec<String>, String> {
    get_a2d_sprites_command(path).await
}

#[tauri::command]
async fn check_a2d_file(path: String) -> Result<serde_json::Value, String> {
    check_a2d_file_command(path).await
}

// =============================================================================
// Helper Functions
// =============================================================================

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

fn main() {
    tauri::Builder::default()
        .manage(AppState::default())
        .invoke_handler(tauri::generate_handler![
            connect_auth,
            connect_game,
            get_connection_state,
            disconnect,
            send_game_message,
            parse_character_a2d,
            get_a2d_sprites,
            check_a2d_file
        ])
        .setup(|app| {
            use tauri::Emitter;
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