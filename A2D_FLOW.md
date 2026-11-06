# A2D Avatar Rendering Flow - DreamFus Dofus Client

## Overview

This document describes the complete flow for parsing A2D avatar files and rendering character selection screens in the DreamFus Godot client.

## Architecture

### Option A: Rust Backend (Reference Implementation)
```
DofusClient (Tauri Rust Backend - REFERENCE ONLY)
    │
    ├── src/lib.rs           # Core library - pure Rust, no Tauri macros
    ├── src-tauri/main.rs    # Tauri binary entry point with commands
    └── src/a2d/mod.rs       # A2D.Z parser module (Rust implementation)
          │
          └── A2D Format: A2DZ → A2D1 → WebP images
```

**NOTA**: El backend Rust/Tauri está DESACTIVADO. Este código se mantiene como referencia
para el parsing A2D.Z. El cliente Godot usa el parser GDScript en `godot-client/src/A2D/`.

### Option B: GDScript Parser (Active Implementation)
```
DofusClient (Godot-only Client)
    │
    ├── godot-client/
    │   ├── src/
    │   │   ├── A2D/
    │   │   │   ├── A2DParser.gd    # Main parser for A2D.Z files
    │   │   │   └── Bytes.gd          # Utility for byte operations
    │   │   ├── Core/                 # Game logic
    │   │   └── UI/                   # User interface
    │   └── ...                       # Scenes and assets
```

## Migration Notes

El cliente Godot ahora implementa su propio parser A2D.Z en GDScript:
- **Archivos de referencia**: `src/a2d/mod.rs` - Para comprender el formato
- **Implementación activa**: `godot-client/src/A2D/A2DParser.gd`
- **Límite actual**: La descompresión deflate requiere un GDExtension o pre-procesamiento

## A2D File Format Specification

### File Extension and Location

- **Extension**: `.a2d` or compressed `.a2d.z`
- **Location**: 
  - `d3pack/bones/` - Body/bones data
  - `d3pack/skins/` - Character appearance skins
- **Magic**: `A2DZ` (4 bytes) for compressed files

### Binary Structure

```
A2DZ Container:
┌─────────────┬───────────┬──────────────────────────────────┐
│ 4 bytes     │ 1 byte    │ N bytes (deflate compressed)     │
│ "A2DZ"      │ version   │                                  │
└─────────────┴───────────┴──────────────────────────────────┘

Decompressed A2D1:
┌─────────────┬───────────┬──────────────────────────────────┐
│ 4 bytes     │ 4 bytes   │ ...sprite data... │ ...WebP...   │
│ "A2D1"      │ version   │                  │              │
│             │ (u32 LE)  │                  │              │
└─────────────┴───────────┴──────────────────────────────────┘
```

### Decompression

The A2DZ format uses **raw deflate compression** (not zlib or gzip):
- Header: 8 bytes (`A2DZ` magic + version byte + 3 padding)
- Payload: Deflate-compressed data
- Decompression uses `flate2::read::DeflateDecoder`

## A2D Parser Module (`src/a2d/mod.rs`)

### Key Types Exported

```rust
pub struct A2D1 {
    pub version: u32,
    pub sprites: Vec<SpriteInfo>,
    pub images: Vec<ImageContainer>,
}

pub struct SpriteInfo {
    pub name: String,
    pub offset: u32,
    pub size: u32,
}

pub struct ImageContainer {
    pub sprite_name: String,
    pub width: u16,
    pub height: u16,
    pub data: Vec<u8>,  // Raw WebP bytes
}

pub struct A2DParseResult {
    pub sprites: Vec<SpriteInfo>,
    pub images: Vec<ImageContainer>,
}
```

### Parsing Functions

| Function | Description |
|----------|-------------|
| `parse_a2dz_file(path)` | Read, decompress, and parse full A2D file |
| `parse_a2d(path)` | Get sprites and images as A2DParseResult |
| `read_a2dz_header(path)` | Header info without full decompression |

## Tauri Commands (Frontend API)

### Connection Management Commands

| Command | Input | Output | Description |
|---------|-------|--------|-------------|
| `connect_auth` | host, port, token, installId, lang | String (result message) | WebSocket auth (port 5557) |
| `connect_game` | host, port, ticket | String (connected/disconnected) | TCP game connection (port 5555) |
| `get_connection_state` | - | ConnectionState enum | Current connection status |
| `disconnect` | - | String | Disconnect from server |
| `send_game_message` | opcode, payloadHex | String | Send game protocol message |

### Avatar Rendering Commands

| Command | Input | Output | Description |
|---------|-------|--------|-------------|
| `parse_character_a2d` | path: String | CharacterDisplayData | Parse A2D, return base64 WebP data URLs |
| `get_a2d_sprites` | path: String | Vec<String> | List sprite names |
| `check_a2d_file` | path: String | serde_json::Value | Check file exists, read header |

### Data Structures for Frontend

```typescript
// Character Display Data (sent to Godot frontend)
interface CharacterDisplayData {
  sprites: SpriteInfo[];
  images: AvatarImage[];
  breed_texture: AvatarImage | null;
}

interface AvatarImage {
  sprite_name: string;  // "body", "head", "eyes", etc.
  width: number;
  height: number;
  data_url: string;     // "data:image/webp;base64,..." - can be loaded as Texture2D
}

interface SpriteInfo {
  name: string;
  offset: number;
  size: number;
}
```

## Character Selection Flow

```
1. Launcher UI (Launcher.tscn)
   └─> User clicks "Conectar" (Connect)
   
2. SimpleProtocolClient.cs connects to WebSocket (port 5557)
   └─> Sends auth_request
   
3. GameManager.cs handles auth_response
   └─> Updates GameState.Launcher → GameState.Login
   
4. Server Selection Flow
   └─> Fetches server list from auth_response
   └─> User selects server
   └─> Requests server_selection
   └─> Receives ticket, host, ports
   
5. GameManager.cs navigates to CharacterSelect.tscn
   └─> TCP connection to game server (port 5555)
   
6. SimpleProtocolClient.cs
   └─> Sends ticket to GameNodeProxy
   
7. KVI (Key-Value Items) Character List
   └─> Response contains character data:
      - accountId
      - characterId  
      - look (appearance string)
      - breed, sex, level
      - position
```

### Look String Format

The `look` string encodes character appearance:

```
Format: "GuildId;[Colors...];[Effects...];[Options...]"
Example: "12345;5;#FF5500;#00FF00;..."

Used to:
1. Parse appearance data
2. Identify which A2D skin file to load
3. Render character avatar in selection screen
```

## Godot Integration

### GDScript WebSocket Client

El cliente Godot usa su propia conexión WebSocket directa al servidor:

```gdscript
# En Network/A2DClient.gd
var ws: WebSocketClient = WebSocketClient.new()

func connect_to_game(server_ip: String, port: int) -> void:
    ws.connect_to_url("ws://%s:%d" % [server_ip, port])

func _on_message_received(msg_type: String, data: Dictionary) -> void:
    match msg_type:
        "auth_response":
            _handle_auth_response(data)
        "character_list":
            _update_character_select(data)
```

### A2D Avatar Rendering (GDScript)

Desde Godot 4.8, el parser A2D.Z está disponible en GDScript:

```gdscript
# Usar el parser A2D directamente en GDScript
var result := A2DParser.parse_file("/path/to/character.a2d")

if result.error != "":
    push_error("Parse error: %s" % result.error)
else:
    for image_data in result.images:
        var texture := _load_webp_from_bytes(image_data.data)
        # Usar texture en UI...
```

### Alternative: HTTP API Bridge

Si se prefiere una API REST para el parsing:

```gdscript
func parse_character_a2d(path: String) -> Dictionary:
    var client := HTTPRequest.new()
    add_child(client)
    
    var err := client.request(
        "http://localhost:8080/api/a2d/parse",
        ["Content-Type": "application/json"],
        false,
        HTTPClient.METHOD_POST,
        JSON.stringify({"path": path})
    )
    
    return result
```

**NOTA**: Esta funcionalidad está pendiente de implementación. Ver `docs/ROADMAP.md` para el estado actual.

## File System Layout

```
DofusClient/                          
├── src/
│   ├── lib.rs                        # Library exports (REFERENCE - Tauri removed)
│   └── a2d/
│       └── mod.rs                    # A2D parser (Rust - REFERENCE ONLY)
│
├── godot-client/                     # Active Godot client (GDScript only)
│   ├── project.godot
│   ├── src/
│   │   ├── A2D/
│   │   │   ├── A2DParser.gd          # A2D.Z parser (active)
│   │   │   └── Bytes.gd              # Byte utilities
│   │   ├── Core/
│   │   │   └── Network/...           # WebSocket, protocol
│   │   └── UI/
│   │       └── ...                   # UI scripts
│   ├── scenes/
│   │   ├── Game.tscn
│   │   └── CharacterSelect.tscn
│   └── assets/
│       └── ...                       # UI textures, fonts
│
└── docs/                             # Architecture documentation
```

## Build and Run

### Debug Build
```bash
cd DofusClient
cargo build  # Compiles library + Tauri binary
cargo run    # Runs the Tauri app
```

### Production
```bash
cargo build --release
tauri build  # Creates distributable package
```

## Testing A2D Parsing

To test with actual game assets:

1. Locate `.a2d` or `.a2d.z` files in:
   - `d3pack/bones/` directory (from alea-client.exe extraction)
   - `d3pack/skins/` directory

2. Run test:
```rust
// In src/lib.rs
#[tokio::main]
async fn main() {
    let result = parse_a2d_command("/path/to/bone_1.a2d".to_string()).await;
    println!("{:?}", result);
}
```

3. Expected output:
```json
{
  "sprites": [{"name": "body", "offset": 0, "size": 100}],
  "images": [
    {"sprite_name": "body", "width": 54, "height": 84, "data_url": "data:image/webp;base64,..."}
  ],
  "breed_texture": null
}
```

## Known Limitations

1. **Sprite parsing is simplified** - Full A2D1 sprite entry parsing requires reverse-engineering game-specific formats
2. **Position 18,506,840** - KLO module contains character rendering logic at this memory offset in alea-client.exe
3. **WebP extraction** - Currently detects WebP signatures, full chunk parsing may need refinement

## Next Steps

1. ~~Connect Godot C# to Tauri commands~~ **DEPRECATED - Now using pure GDScript**
2. Implement character avatar display using Texture2D with WebP data URLs via A2DParser.gd
3. Enhance sprite parsing for complete character rendering
4. Add support for breed emblems (`d3picto/hint/{breed*10}.png`)
5. ~~Investigate deflate decompression in GDScript~~ **PENDIENTE**: Necesario GDExtension o pre-procesamiento

## TODO: Deflate Decompression

Godot no tiene soporte nativo para raw deflate en GDScript. Opciones:

1. **GDExtension en Rust** - Usar `src/a2d/mod.rs` como base para una extensión
2. **Pre-procesamiento offline** - Convertir .a2d.z a .webp antes de cargar en Godot
3. **Script de conversión** - Usar el parser Rust para generar archivos WebP estáticos

Ver `docs/DEFLATE_SOLUTION.md` para detalles de implementación.