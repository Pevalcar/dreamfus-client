//! A2D.Z (Ankama Animated Display) file format parser
//! 
//! A2D files contain character/avatar sprites used in Dofus.
//! Format: A2DZ (compressed) -> A2D1 (container) -> WebP images
//!
//! Format specification:
//! - A2DZ container: "A2DZ" magic (4 bytes) + version byte (1 byte) + 3 padding bytes + deflate-compressed data
//! - A2D1 container: "A2D1" magic (4 bytes) + version (4 bytes LE) + sprite entries + WebP images

use std::io::{Cursor, Read};
use flate2::read::DeflateDecoder;
use thiserror::Error;
use serde::{Serialize, Deserialize};

#[derive(Error, Debug)]
pub enum A2DError {
    #[error("Invalid magic bytes")]
    InvalidMagic,
    
    #[error("Decompression failed: {0}")]
    DecompressionFailed(String),
    
    #[error("Invalid A2D1 format")]
    InvalidA2D1,
    
    #[error("WebP parsing error: {0}")]
    WebPError(String),
    
    #[error("IO error: {0}")]
    IoError(String),
    
    #[error("Image decoding error")]
    ImageError,
    
    #[error("Unsupported format version: {0:?}")]
    UnsupportedVersion([u8; 4]),
}

/// Header information from an A2DZ file
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HeaderInfo {
    #[serde(skip)]
    pub magic: [u8; 4],
    pub version_byte: u8,
}

/// A2DZ container format (compressed)
pub struct A2DZ {
    pub header: HeaderInfo,
    pub compressed_data: Vec<u8>,
}

/// Parsed A2D1 container
pub struct A2D1 {
    pub version: u32,
    pub sprites: Vec<SpriteInfo>,
    pub images: Vec<ImageContainer>,
}

/// Information about a sprite in the A2D file
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SpriteInfo {
    pub name: String,
    pub offset: u32,
    pub size: u32,
}

/// An image container extracted from A2D1
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImageContainer {
    #[serde(rename = "spriteName")]
    pub sprite_name: String,
    pub width: u16,
    pub height: u16,
    #[serde(skip)]
    pub data: Vec<u8>,
}

/// Result of parsing an A2D file
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct A2DParseResult {
    pub sprites: Vec<SpriteInfo>,
    #[serde(skip)]
    pub images: Vec<ImageContainer>,
}

impl A2DZ {
    /// Parse an A2DZ file from raw bytes
    pub fn parse(data: &[u8]) -> Result<Self, A2DError> {
        if data.len() < 8 {
            return Err(A2DError::InvalidMagic);
        }
        
        // Verify magic "A2DZ"
        let magic = [data[0], data[1], data[2], data[3]];
        if magic != *b"A2DZ" {
            return Err(A2DError::InvalidMagic);
        }
        
        Ok(A2DZ {
            header: HeaderInfo {
                magic,
                version_byte: data[4],
            },
            compressed_data: data[8..].to_vec(),
        })
    }
    
    /// Get header information from raw A2DZ bytes (without full parsing)
    pub fn get_header(data: &[u8]) -> Result<HeaderInfo, A2DError> {
        if data.len() < 5 {
            return Err(A2DError::InvalidMagic);
        }
        
        let magic = [data[0], data[1], data[2], data[3]];
        if magic != *b"A2DZ" {
            return Err(A2DError::InvalidMagic);
        }
        
        Ok(HeaderInfo {
            magic,
            version_byte: data[4],
        })
    }
    
    /// Decompress to A2D1 format
    pub fn decompress(&self) -> Result<A2D1, A2DError> {
        // Use raw deflate decompression
        let cursor = Cursor::new(&self.compressed_data);
        let mut decoder = DeflateDecoder::new(cursor);
        let mut decompressed = Vec::new();
        
        decoder.read_to_end(&mut decompressed)
            .map_err(|e| A2DError::DecompressionFailed(e.to_string()))?;
        
        A2D1::parse(&decompressed)
    }
}

impl A2D1 {
    /// Parse A2D1 format from decompressed data
    pub fn parse(data: &[u8]) -> Result<Self, A2DError> {
        if data.len() < 8 {
            return Err(A2DError::InvalidA2D1);
        }
        
        // Verify magic "A2D1"
        if &data[0..4] != b"A2D1" {
            return Err(A2DError::UnsupportedVersion(
                [data[0], data[1], data[2], data[3]]
            ));
        }
        
        // Parse version field (little-endian u32)
        let version = u32::from_le_bytes([data[4], data[5], data[6], data[7]]);
        
        // Parse sprite entries and WebP images
        let sprites = Vec::new();
        let images = Self::extract_webp_images(data)?;
        
        Ok(A2D1 {
            version,
            sprites,
            images,
        })
    }
    
    /// Extract all WebP images from A2D1 data
    fn extract_webp_images(data: &[u8]) -> Result<Vec<ImageContainer>, A2DError> {
        let mut images = Vec::new();
        let mut offset = 8; // Skip "A2D1" + version
        
        // Look for RIFF headers (WebP starts with RIFF...WEBP)
        while offset + 12 <= data.len() {
            // Check for RIFF webp signature
            if &data[offset..offset+4] == b"RIFF" && 
               offset + 8 <= data.len() && 
               &data[offset+8..offset+12] == b"WEBP" {
                // Read WebP size
                let riff_size = u32::from_le_bytes([
                    data[offset+4], data[offset+5], data[offset+6], data[offset+7]
                ]) as usize;
                let webp_size = 12 + riff_size;
                
                if offset + webp_size > data.len() {
                    break;
                }
                
                let image_data = data[offset..offset+webp_size].to_vec();
                
                // Get dimensions
                if let Ok((width, height)) = Self::get_webp_dimensions(&image_data) {
                    images.push(ImageContainer {
                        sprite_name: format!("sprite_{}", images.len()),
                        width,
                        height,
                        data: image_data,
                    });
                }
                
                offset += webp_size;
            } else {
                // Look for sprite names or skip ahead
                if offset + 1 < data.len() {
                    // Try to find null-terminated string starting with "sprite_"
                    let remaining = &data[offset..];
                    
                    // Check for sprite_ pattern
                    if remaining.starts_with(b"sprite_") || remaining.starts_with(b"sprite") {
                        let name_end = remaining.iter().position(|&b| b == 0).unwrap_or(16);
                        if name_end > 0 && name_end < remaining.len() {
                            offset += name_end + 1 + 8; // Skip name + null + 2 u32 fields
                            continue;
                        }
                    }
                    
                    // Skip one byte and search for RIFF
                    offset += 1;
                } else {
                    break;
                }
            }
        }
        
        Ok(images)
    }
    
    /// Get WebP image dimensions by parsing the VP8/VP8L chunk headers
    fn get_webp_dimensions(data: &[u8]) -> Result<(u16, u16), A2DError> {
        if data.len() < 12 {
            return Err(A2DError::WebPError("Data too short for WebP header".to_string()));
        }
        
        // Verify RIFF header
        if &data[0..4] != b"RIFF" || &data[8..12] != b"WEBP" {
            return Err(A2DError::WebPError("Not a WebP file".to_string()));
        }
        
        // Parse chunks starting after "RIFF" + size + "WEBP" (12 bytes)
        let mut offset = 12;
        
        while offset + 8 <= data.len() {
            let chunk_type = &data[offset..offset+4];
            let chunk_size = u32::from_le_bytes([
                data[offset+4], data[offset+5], data[offset+6], data[offset+7]
            ]);
            
            let chunk_end = offset + 8 + chunk_size as usize;
            
            if chunk_type == b"VP8 " {
                // VP8 format: dimensions at offset 0x12-0x17
                if chunk_end >= 0x18 {
                    let width = u16::from_le_bytes([data[offset+0x12], data[offset+0x13]]) + 1;
                    let height = u16::from_le_bytes([data[offset+0x16], data[offset+0x17]]) + 1;
                    return Ok((width, height));
                }
            } else if chunk_type == b"VP8L" {
                // VP8L (lossless) format: dimensions in feature byte pair
                if offset + 10 <= data.len() {
                    // Read the 14-bit width and 14-bit height from bytes 6-7 (relative to chunk start)
                    // Format: w_hex (14 bits) + h_hex (14 bits) in little-endian 16-bit value + padding bits
                    let features: u32 = u32::from_le_bytes([
                        data[offset+6], data[offset+7], 
                        data[offset+8], data[offset+9]
                    ]);
                    let w_hex = (features & 0x3FFF) as u16;
                    let h_hex = ((features >> 14) & 0x3FFF) as u16;
                    return Ok((w_hex + 1, h_hex + 1));
                }
            } else if chunk_type == b"ANIM" {
                // Animated WebP - continue searching for image data
            }
            
            offset = chunk_end;
        }
        
        Err(A2DError::WebPError("Could not find image chunk with dimensions".to_string()))
    }
}

/// Parse an A2DZ file directly from path
pub fn parse_a2dz_file(path: &str) -> Result<A2D1, A2DError> {
    let data = std::fs::read(path)
        .map_err(|e| A2DError::IoError(e.to_string()))?;
    
    let a2dz = A2DZ::parse(&data)?;
    a2dz.decompress()
}

/// Parse A2D file and return both sprites and images
pub fn parse_a2d(path: &str) -> Result<A2DParseResult, A2DError> {
    let a2d1 = parse_a2dz_file(path)?;
    Ok(A2DParseResult {
        sprites: a2d1.sprites,
        images: a2d1.images,
    })
}

/// Read A2DZ header info without full decompression
pub fn read_a2dz_header(path: &str) -> Result<HeaderInfo, A2DError> {
    let data = std::fs::read(path)
        .map_err(|e| A2DError::IoError(e.to_string()))?;
    A2DZ::get_header(&data)
}

/// Get breed emblem image path for a given breed ID
/// Breed ID mapping: breed=1 → 10.png, breed=2 → 20.png, etc.
pub fn get_breed_emblem_path(breed_id: u32) -> String {
    format!("d3picto/hint/{}.png", breed_id * 10)
}

/// Parse character look string to extract appearance data
/// Look string format: "GuildId;Color1;Color2;..."
pub fn parse_look_string(look: &str) -> Result<Vec<String>, A2DError> {
    let parts: Vec<String> = look.split(';')
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string())
        .collect();
    Ok(parts)
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_breed_emblem_path() {
        assert_eq!(get_breed_emblem_path(1), "d3picto/hint/10.png");
        assert_eq!(get_breed_emblem_path(2), "d3picto/hint/20.png");
    }
    
    #[test]
    fn test_look_string_parse() {
        let result = parse_look_string("123;456;789").unwrap();
        assert_eq!(result.len(), 3);
        assert_eq!(result[0], "123");
    }
}