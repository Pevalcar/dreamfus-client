//! DreamFus Client - Core Library
//!
//! This module provides:
//! 1. WebSocket authentication (port 5557) - auth_request, server_selection
//! 2. TCP game connection (port 5555) - SimpleProtocol with VarInt framing
//! 3. Ticket-based server handoff
//! 4. Character avatar rendering via A2D parser

pub mod a2d;

use std::sync::Arc;
use serde::{Serialize, Deserialize};
use tokio::net::TcpStream;
use tokio::sync::RwLock;

// Re-export types from a2d module for convenience
pub use a2d::{A2D1, A2DZ, SpriteInfo, ImageContainer, A2DParseResult, HeaderInfo, A2DError};

// =============================================================================
// State Management
// =============================================================================

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub enum ConnectionState {
    Disconnected,
    Connecting,
    Authenticating,
    Authenticated { account_id: i64, ticket: String },
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
            ConnectionState::Authenticated { account_id, .. } => {
                write!(f, "Authenticated(accountId={account_id})")
            }
            ConnectionState::ConnectingGame { host, port } => {
                write!(f, "ConnectingGame({host}:{port})")
            }
            ConnectionState::InGame => write!(f, "InGame"),
            ConnectionState::Error(msg) => write!(f, "Error: {msg}"),
        }
    }
}

#[derive(Debug)]
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
        use tokio::io::AsyncReadExt;

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
// A2D Character Avatar Command Implementations (called from Tauri commands)
// =============================================================================

/// Character avatar representation for frontend
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CharacterAvatar {
    pub name: String,
    pub level: i32,
    pub breed: i32,
    pub sex: i32,
    pub look: String,
    pub avatar_images: Vec<AvatarImage>,
    pub background_url: Option<String>,
}

/// An image component for character avatar
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AvatarImage {
    pub sprite_name: String,
    pub width: u16,
    pub height: u16,
    pub data_url: String, // base64 data URL for image delivery
}

/// Result from parsing an A2D file for character display
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CharacterDisplayData {
    pub sprites: Vec<SpriteInfo>,
    pub images: Vec<AvatarImage>,
    pub breed_texture: Option<AvatarImage>,
}

/// Get breed emblem image path
pub fn get_breed_emblem_path(breed: i32) -> String {
    format!("d3picto/hint/{}.png", breed * 10)
}

/// Parse an A2D file and return character display data
pub async fn parse_a2d_command(path: String) -> Result<CharacterDisplayData, String> {
    use crate::a2d::parse_a2d;
    use base64::{engine::general_purpose, Engine as _};
    
    let result = parse_a2d(&path).map_err(|e| e.to_string())?;
    
    let images: Vec<AvatarImage> = result.images
        .iter()
        .map(|img| {
            let data_url = format!("data:image/webp;base64,{}", 
                general_purpose::STANDARD.encode(&img.data));
            AvatarImage {
                sprite_name: img.sprite_name.clone(),
                width: img.width,
                height: img.height,
                data_url,
            }
        })
        .collect();
    
    Ok(CharacterDisplayData {
        sprites: result.sprites,
        images,
        breed_texture: None,
    })
}

/// Get all sprite names from an A2D file
pub async fn get_a2d_sprites_command(path: String) -> Result<Vec<String>, String> {
    use crate::a2d::parse_a2dz_file;
    
    let a2d1 = parse_a2dz_file(&path).map_err(|e| e.to_string())?;
    Ok(a2d1.sprites.iter().map(|s| s.name.clone()).collect())
}

/// Check if an A2D file exists and get its header
pub async fn check_a2d_file_command(path: String) -> Result<serde_json::Value, String> {
    use crate::a2d::read_a2dz_header;
    use serde_json::json;
    
    if std::path::Path::new(&path).exists() {
        let metadata = std::fs::metadata(&path).map_err(|e| e.to_string())?;
        if let Ok(header) = read_a2dz_header(&path) {
            Ok(json!({
                "exists": true,
                "size": metadata.len(),
                "magic": String::from_utf8_lossy(&header.magic).to_string(),
                "version_byte": format!("0x{:02x}", header.version_byte)
            }))
        } else {
            Ok(json!({
                "exists": true,
                "size": metadata.len(),
                "error": "Failed to read header"
            }))
        }
    } else {
        Ok(json!({
            "exists": false
        }))
    }
}