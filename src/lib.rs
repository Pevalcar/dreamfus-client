use tauri::{State, Manager};
use std::sync::Mutex;
use std::net::TcpStream;
use std::io::{Read, Write};
use std::sync::Arc;

/// Estado compartido para la conexión del servidor
pub struct ServerConnection {
    pub stream: Option<TcpStream>,
    pub connected: bool,
}

impl ServerConnection {
    pub fn new() -> Self {
        Self {
            stream: None,
            connected: false,
        }
    }
}

/// Protocol utilities for Jondo/DreamFus wire format
pub mod protocol {
    use super::*;

    /// Maximum frame length (8MB)
    pub const MAX_FRAME_LENGTH: usize = 8 * 1024 * 1024;

    /// Reads a VarInt from a byte slice, returns (value, bytes_read)
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
                return None; // VarInt too long
            }
        }
        None
    }

    /// Writes a VarInt to a vector
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

    /// Reads a frame from a stream with VarInt length prefix
    pub fn read_frame(stream: &mut TcpStream, _timeout_ms: u64) -> Option<Vec<u8>> {
        // Read VarInt length (max 5 bytes for u32)
        let mut len_bytes = [0u8; 5];

        for i in 0..5 {
            let mut buf = [0u8; 1];
            match stream.read(&mut buf) {
                Ok(0) => return None, // Connection closed
                Ok(_) => {
                    len_bytes[i] = buf[0];
                    if (buf[0] & 0x80) == 0 {
                        // Last byte
                        let (length, _) = read_varint(&len_bytes[..=i])?;
                        if length as usize > MAX_FRAME_LENGTH {
                            return None;
                        }
                        // Read payload
                        let mut payload = vec![0u8; length as usize];
                        let mut read_pos = 0;
                        while read_pos < payload.len() {
                            match stream.read(&mut payload[read_pos..]) {
                                Ok(0) => return None,
                                Ok(n) => read_pos += n,
                                Err(_) => return None,
                            }
                        }
                        return Some(payload);
                    }
                }
                Err(_) => return None,
            }
        }
        None
    }

    /// Writes a frame with VarInt length prefix
    pub fn write_frame(stream: &mut TcpStream, payload: &[u8]) -> std::io::Result<()> {
        let len_varint = write_varint(payload.len() as u32);
        stream.write_all(&len_varint)?;
        stream.write_all(payload)?;
        stream.flush()
    }
}

// TCP Bridge commands
#[tauri::command]
fn connect_server(
    state: State<Arc<Mutex<ServerConnection>>>,
    host: String,
    port: u16,
) -> Result<String, String> {
    let addr = format!("{}:{}", host, port);

    // Check if already connected
    {
        let conn = state.inner().lock().unwrap();
        if conn.connected {
            return Err("Already connected to server".to_string());
        }
    }

    match TcpStream::connect(&addr) {
        Ok(stream) => {
            // Set read timeout
            stream.set_read_timeout(Some(std::time::Duration::from_secs(30))).unwrap();

            let mut conn = state.inner().lock().unwrap();
            conn.stream = Some(stream);
            conn.connected = true;
            Ok(format!("Connected to {}", addr))
        }
        Err(e) => Err(format!("Error connecting to {}: {}", addr, e)),
    }
}

#[tauri::command]
fn disconnect_server(state: State<Arc<Mutex<ServerConnection>>>) -> Result<String, String> {
    let mut conn = state.inner().lock().unwrap();
    conn.stream = None;
    conn.connected = false;
    Ok("Disconnected from server".to_string())
}

#[tauri::command]
fn get_server_status(state: State<Arc<Mutex<ServerConnection>>>) -> String {
    let conn = state.inner().lock().unwrap();
    if conn.connected { "Connected".to_string() } else { "Disconnected".to_string() }
}

#[tauri::command]
fn send_message(
    state: State<Arc<Mutex<ServerConnection>>>,
    opcode: String,
    payload_hex: String,
) -> Result<String, String> {
    // Decode hex payload (support both with and without 0x prefix)
    let hex_str = if payload_hex.starts_with("0x") {
        &payload_hex[2..]
    } else {
        &payload_hex
    };
    let payload = hex::decode(hex_str)
        .map_err(|e| format!("Invalid hex payload: {}", e))?;

    // Build envelope with opcode
    // Simple envelope: field 1 = opcode string, field 2 = payload bytes
    let envelope = build_envelope(&opcode, &payload);

    let mut conn = state.inner().lock().unwrap();
    if conn.stream.is_none() {
        return Err("Not connected to server".to_string());
    }

    let stream = conn.stream.as_mut().unwrap();
    protocol::write_frame(stream, &envelope)
        .map_err(|e| format!("Failed to write frame: {}", e))?;

    Ok(format!("Message sent: {}", opcode))
}

/// Builds a simple protobuf envelope with the given opcode and payload.
/// Uses field 1 for type URL and field 2 for payload bytes (Any format).
fn build_envelope(opcode: &str, payload: &[u8]) -> Vec<u8> {
    let mut result = Vec::new();

    // Field 1: type.ankama.com/{opcode} as string
    let type_url = format!("type.ankama.com/{}", opcode);
    let type_url_bytes = type_url.as_bytes();
    result.extend(protocol::write_varint(1 << 3 | 2)); // Field 1, wire type 2 (length-delimited)
    result.extend(protocol::write_varint(type_url_bytes.len() as u32));
    result.extend(type_url_bytes);

    // Field 2: payload as bytes
    result.extend(protocol::write_varint(2 << 3 | 2)); // Field 2, wire type 2
    result.extend(protocol::write_varint(payload.len() as u32));
    result.extend(payload);

    result
}

// Add hex crate to decode payloads
// Note: In a full implementation, we'd use the 'hex' crate or implement manual decoding

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            connect_server,
            disconnect_server,
            get_server_status,
            send_message
        ])
        .setup(|app| {
            app.manage(Arc::new(Mutex::new(ServerConnection::new())));
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}