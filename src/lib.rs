use tauri::{State, Manager, emit, Emitter};
use std::sync::Mutex;
use std::net::TcpStream;
use std::io::{Read, Write};
use std::sync::Arc;
use std::thread;

/// Estado compartido para la conexión del servidor
pub struct ServerConnection {
    pub stream: Option<TcpStream>,
    pub connected: bool,
    pub address: String,
}

impl ServerConnection {
    pub fn new() -> Self {
        Self {
            stream: None,
            connected: false,
            address: String::new(),
        }
    }
}

/// Direction of a frame based on the root field
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FrameDirection {
    Unknown,
    ServerPush, // Root field 1
    ClientRequest, // Root field 2
    ServerReply, // Root field 3
}

impl FrameDirection {
    pub fn from_root_field(field: u32) -> Self {
        match field {
            1 => FrameDirection::ServerPush,
            2 => FrameDirection::ClientRequest,
            3 => FrameDirection::ServerReply,
            _ => FrameDirection::Unknown,
        }
    }
}

/// Parsed envelope frame
#[derive(Debug, Clone)]
pub struct EnvelopeFrame {
    pub found: bool,
    pub direction: FrameDirection,
    pub opcode: Option<String>,
    pub payload: Vec<u8>,
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

    /// Reads a single field from a byte stream, returns (field_number, wire_type, bytes)
    fn read_field(data: &[u8], pos: usize) -> Option<(u32, u32, usize, usize)> {
        if pos >= data.len() {
            return None;
        }
        
        let (tag, bytes_read) = read_varint(data)?;
        let field_number = tag >> 3;
        let wire_type = tag & 0x7;
        
        if pos + bytes_read >= data.len() {
            return None;
        }
        
        // Read length of the field bytes (for wire type 2, length-delimited)
        if wire_type == 2 {
            let (length, len_bytes) = read_varint(&data[pos + bytes_read..])?;
            let field_end = pos + bytes_read + len_bytes + length as usize;
            if field_end > data.len() {
                return None;
            }
            return Some((
                field_number,
                wire_type,
                field_end,
                pos + bytes_read + len_bytes,
            ));
        }
        
        // For other wire types, we need to parse differently
        // For simplicity, assume length-delimited for now
        None
    }

    /// Reads a frame from a stream with VarInt length prefix
    pub fn read_frame(stream: &mut TcpStream) -> Option<Vec<u8>> {
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

    /// Open a Any field from bytes (field 1 = type URL, field 2 = value)
    pub fn open_any(bytes: &[u8]) -> Option<(String, Vec<u8>)> {
        // Parse the Any message: field 1 = TypePrefix + opcode, field 2 = value bytes
        let mut pos = 0;
        let mut type_url: Option<String> = None;
        let mut value_bytes: Vec<u8> = Vec::new();
        
        while pos < bytes.len() {
            let (tag, bytes_read) = read_varint(&bytes[pos..])?;
            let field_number = tag >> 3;
            let wire_type = tag & 0x7;
            
            if wire_type != 2 {
                break; // Only handle length-delimited
            }
            
            if pos + bytes_read >= bytes.len() {
                break;
            }
            
            let (length, len_bytes) = read_varint(&bytes[pos + bytes_read..])?;
            let field_end = pos + bytes_read + len_bytes + length as usize;
            
            if field_end > bytes.len() {
                break;
            }
            
            let field_bytes = &bytes[pos + bytes_read + len_bytes..field_end];
            
            if field_number == 1 {
                // Type URL should start with "type.ankama.com/"
                if field_bytes.len() > 20 {
                    let prefix = std::str::from_utf8(&field_bytes[..20]).ok()?;
                    if prefix == "type.ankama.com/" {
                        type_url = Some(String::from_utf8_lossy(&field_bytes[20..]).to_string());
                    }
                }
            } else if field_number == 2 {
                value_bytes = field_bytes.to_vec();
            }
            
            pos = field_end;
        }
        
        type_url.map(|url| (url, value_bytes))
    }

    /// Parse a frame into direction, opcode, and payload
    pub fn parse_frame(frame: &[u8]) -> EnvelopeFrame {
        if frame.is_empty() {
            return EnvelopeFrame { found: false, direction: FrameDirection::Unknown, opcode: None, payload: Vec::new() };
        }

        // Read the root tag
        let (tag, bytes_read) = match read_varint(frame) {
            Some(v) => v,
            None => return EnvelopeFrame { found: false, direction: FrameDirection::Unknown, opcode: None, payload: Vec::new() },
        };

        let root_field = tag >> 3;
        let _wire_type = tag & 0x7;

        let direction = FrameDirection::from_root_field(root_field);

        // Try to open as an Any message
        if bytes_read < frame.len() {
            if let Some((opcode, payload)) = open_any(&frame[bytes_read..]) {
                return EnvelopeFrame {
                    found: true,
                    direction,
                    opcode: Some(opcode),
                    payload,
                };
            }
        }

        EnvelopeFrame { found: true, direction, opcode: None, payload: frame[bytes_read..].to_vec() }
    }
}

/// Message received from server
#[derive(Debug, Clone)]
pub struct ServerMessage {
    pub direction: FrameDirection,
    pub opcode: Option<String>,
    pub opcode_str: String,
    pub raw_payload: Vec<u8>,
}

// TCP Bridge commands
#[tauri::command]
fn connect_server(
    state: State<Arc<Mutex<ServerConnection>>>,
    host: String,
    port: u16,
    app: tauri::AppHandle,
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

            {
                let mut conn = state.inner().lock().unwrap();
                conn.stream = Some(stream);
                conn.connected = true;
                conn.address = addr.clone();
            }
            
            // Clone app handle for the receiver thread
            let app_handle = app.clone();
            
            // Spawn a thread to receive messages
            thread::spawn(move || {
                loop {
                    // Check connection status
                    let connected = {
                        let conn = state.inner().lock().unwrap();
                        if !conn.connected {
                            break;
                        }
                        true
                    };
                    
                    if !connected {
                        break;
                    }
                    
                    // Try to read a frame
                    let stream_result = {
                        let conn = state.inner().lock().unwrap();
                        conn.stream.as_mut()
                    };
                    
                    if let Some(mut stream) = stream_result {
                        // Try to read a frame
                        if let Some(raw_frame) = protocol::read_frame(&mut stream) {
                            // Parse the envelope
                            let envelope = protocol::parse_frame(&raw_frame);
                            
                            // Build message for frontend
                            let message = ServerMessage {
                                direction: envelope.direction,
                                opcode: envelope.opcode.clone(),
                                opcode_str: envelope.opcode.clone().unwrap_or_else(|| "unknown".to_string()),
                                raw_payload: raw_frame,
                            };
                            
                            // Emit the parsed message to the frontend
                            let _ = app_handle.emit("server-message", message);
                        }
                    }
                    
                    // Small sleep to prevent busy-looping
                    thread::sleep(std::time::Duration::from_millis(50));
                }
            });

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
    conn.address = String::new();
    Ok("Disconnected from server".to_string())
}

#[tauri::command]
fn get_server_status(state: State<Arc<Mutex<ServerConnection>>>) -> String {
    let conn = state.inner().lock().unwrap();
    if conn.connected { format!("Connected to {}", conn.address) } else { "Disconnected".to_string() }
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
    } else if payload_hex.is_empty() {
        ""
    } else {
        &payload_hex
    };
    let payload = if hex_str.is_empty() {
        Vec::new()
    } else {
        hex::decode(hex_str).map_err(|e| format!("Invalid hex payload: {}", e))?
    };

    // Build envelope with opcode
    // Use field 1 = client-request (direction) for outbound messages
    let envelope = build_envelope(&opcode, &payload, FrameDirection::ClientRequest);

    let mut conn = state.inner().lock().unwrap();
    if conn.stream.is_none() {
        return Err("Not connected to server".to_string());
    }

    let stream = conn.stream.as_mut().unwrap();
    protocol::write_frame(stream, &envelope)
        .map_err(|e| format!("Failed to write frame: {}", e))?;

    Ok(format!("Message sent: {}", opcode))
}

/// Builds a protobuf envelope with the given opcode and payload.
/// Uses root field to indicate direction (1=server-push, 2=client-request, 3=server-reply).
fn build_envelope(opcode: &str, payload: &[u8], direction: FrameDirection) -> Vec<u8> {
    let mut result = Vec::new();

    // Determine root field based on direction
    // Field 1 = server-push, Field 2 = client-request, Field 3 = server-reply
    let root_field = match direction {
        FrameDirection::ServerPush => 1u32,
        FrameDirection::ClientRequest => 2u32,
        FrameDirection::ServerReply => 3u32,
        FrameDirection::Unknown => 1u32, // Default to server-push
    };

    // Root tag: field number << 3 | wire type (2 = length-delimited)
    let root_tag = root_field << 3 | 2;

    // First, build the inner Any message
    let mut inner_any = Vec::new();
    
    // Field 1 of inner Any: type.ankama.com/{opcode}
    let type_url = format!("type.ankama.com/{}", opcode);
    let type_url_bytes = type_url.as_bytes();
    inner_any.extend(protocol::write_varint(1 << 3 | 2)); // Inner field 1, wire type 2
    inner_any.extend(protocol::write_varint(type_url_bytes.len() as u32));
    inner_any.extend(type_url_bytes);

    // Field 2 of inner Any: actual payload
    inner_any.extend(protocol::write_varint(2 << 3 | 2)); // Inner field 2, wire type 2
    inner_any.extend(protocol::write_varint(payload.len() as u32));
    inner_any.extend(payload);

    // Wrap the inner Any as the value of the root field
    result.extend(protocol::write_varint(root_tag)); // Root field tag
    result.extend(protocol::write_varint(inner_any.len() as u32)); // Length of inner Any
    result.extend(inner_any);

    result
}

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