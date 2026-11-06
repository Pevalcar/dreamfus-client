# KLO Binary Analysis - Detailed

## Binary Structure

### KLO Module Location
- **Position:** 18,506,840 bytes (0x011A63E8 in hex)
- **Size:** Variable (module data follows marker)
- **Marker Pattern:** `4b 4c 4f 28 f0 84 44...` = `KLO(\xf0\x84\x44...`

### Hex Dump (first 128 bytes)
```
011a63f0: 42 82 0e 35 9e 83 21 76 88 71 66 f0 55 10 43 cd
011a6400: e1 ab 43 cc b6 80 af 1a 31 e3 02 be e8 e0 55 8d
011a6410: dc b9 33 92 26 e2 50 ec a2 bc 2c b6 0c 1f 5d c8
011a6420: 7a 03 fb 9d 89 74 a4 51 0b 14 b8 24 6f 57 7d de
011a6430: 89 6a f7 af b3 e0 ee 1d 68 5e 80 a1 5f e7 8d 85
011a6440: 94 03 ae 33 1e ed cd 12 14 2f 12 72 69 94 8e 7b
011a6450: 2e 5a 68 90 4b 4c 4f 28 f0 84 44 82 02 b5 89 ce
011a6460: c9 ac 49 1c 8f 29 18 f1 1f b6 70 1c 5f a4 1a 5b
011a6470: f1 5f 66 ff 8e c7 8c 23 bc b7 1a b6 f8 1a 43 ee
```

## KLO Format Analysis

### Marker Structure
The `KLO(` marker appears to indicate:
- `KLO` = Key Loading Operations
- `(` = Start of module data
- `\xf0\x84\x44` = Extended marker (possibly compression or encryption flag)

### String Analysis
Strings found near KLO position:
- `KLO(` - Module start marker
- `IO3Q7...` through `7KH7t...` - Base64 encoded or compressed data
- `/uuRu5h...` - Additional data

## Function Signatures (from WASM_KLO_ANALYSIS.md)

| Function | Description |
|----------|-------------|
| `load_character_avatar` | Loads avatar texture from character data |
| `parse_look_data` | Parses Dofus look string format |
| `get_bone_texture` | Retrieves bone texture from .a2d file |
| `apply_color_mapping` | Applies color tinting to textures |
| `render_avatar_to_buffer` | Renders final avatar to output buffer |

## A2D File Format Analysis

### Files Found
- **Path:** `C:\Users\pevalcar\AppData\Local\Anea\d3pack\bones\`
- **Example:** `27.a2d` (25,950 bytes)
- **Magic:** `A2DZ` (compressed variant of A2D)

### A2DZ Header Structure
```
Offset 0x00: "A2DZ" (4 bytes) - Compressed 2D Object magic
Offset 0x04: Variant/compression flag (4 bytes)
Offset 0x08: Header size (4 bytes)
Offset 0x0C: Data offset (4 bytes)
Offset 0x10: Compressed data [...]
```

### A2D (Uncompressed) Header Structure
```
Offset 0x00: "A2D\0" (4 bytes) - Magic
Offset 0x04: Version (4 bytes) - UInt32
Offset 0x08: Width (4 bytes) - UInt32
Offset 0x0C: Height (4 bytes) - UInt32
Offset 0x10: Data offset (4 bytes) - UInt32
Offset 0x14: Texture data [...]
```

## ed_main (AnimatedDisplayerComponent) Analysis

### Location in characterSelection.json
```
Path: /[0]/ctr_characterSelection[0]/VisualElement[1]/ctr_display[0]/[0]/VisualElement[0]/VisualElement[0]/[1]/ctr_center[0]/ctr_entity[0]

ed_main properties:
- Name: ed_main
- Type: AnimatedDisplayerComponent
- Style: position: absolute; bottom: -15px; width: 725px; height: 725px;
- Dimensions: 725x725 pixels
- Position: absolute, bottom-aligned
```

### Parent Structure
```
ctr_entity (DofusVisualElement)
├── Style: width: 100%; align-items: center; justify-content: flex-end; height: 605px;
└── ed_main (AnimatedDisplayerComponent)
    └── Style: position: absolute; bottom: -15px; width: 725px; height: 725px;

ctr_center (DofusVisualElement)
├── Style: align-items: center; flex-direction: column-reverse; opacity: 1;
├── ctr_entity
└── ctr_infoMain
```

## Important Strings in Binary

| Position | Content |
|----------|---------|
| 18,506,840 | KLO module marker |
| 2,890,928 | d2o files registry |
| 2,865,923 | d2p files registry |
| 7,134,971 | A2D file signature |
| 35,424,593 | character_slot-D-veDKSK.png |
| 62,902,846 | /bones/ and /skins/ registry |

## Asset Paths Referenced

### Character Assets
- `/assets/character_slot-D-veDKSK.png`
- `/uitk/img/socle_1~2.png` (avatar background)

### Bone/Skin Archives
- `/d3pack/bones/{id}.a2d` - 8,876 files
- `/d3pack/skins/{id}.a2d` - 5,597 files

### Breed Emblems
- `C:\Users\pevalcar\AppData\Local\Aea\d3picto\hint\10.png` (Feca)
- `C:\Users\pevalcar\AppData\Local\Aea\d3picto\hint\20.png` (Osamodas)
- ... up to 160.png (Eliotrope)

## Implementation Requirements

### 1. Look String Parser
Dofus look string format: `{ breed }{ sex }{ colors... }{ item_looks... }`
- First char: Breed ID (A=1, B=2, ..., M=8 (Iop), etc.)
- Second char: Sex (m=male, f=female, d=undefined)
- Remaining: Base64 encoded color/item indices

### 2. A2D/Z Parser (Rust/JS)
Need to implement:
```rust
pub struct A2DHeader {
    pub magic: [u8; 4],
    pub version: u32,
    pub width: u32,
    pub height: u32,
    pub data_offset: u32,
}

pub enum A2D {
    Uncompressed(A2DHeader, Vec<u8>),
    Compressed { header_size: u32, data: Vec<u8> },
}

pub fn parse_a2d(data: &[u8]) -> Option<A2D>
```

### 3. Tauri Command for Character Avatar
```rust
#[tauri::command]
pub async fn get_character_avatar(
    character_id: i32,
    look: String
) -> Result<CharacterAvatar, String> {
    // 1. Parse look string
    // 2. Load bone textures from d3pack/bones/*.a2d
    // 3. Load skin textures from d3pack/skins/*.a2d
    // 4. Apply color mapping
    // 5. Render composite
    // 6. Return as base64 URL or raw bytes
}
```

### 4. Godot Integration
```gdscript
# In CharacterSelectUI.gd
func _render_avatar(character: Dictionary) -> Texture2D:
    if Tauri != null:
        var avatar_data = Tauri.invoke("get_character_avatar", {
            "characterId": character.id,
            "look": character.look
        })
        return avatar_data.avatar_texture
    return null
```

## Next Steps for Decompiler

1. **Extract WASM module** from binary at position 18,506,840
2. **Disassemble WASM** using wasm2wat or wasm-decompile
3. **Identify function boundaries** and export tables
4. **Decompile KLO functions** to understand avatar rendering
5. **Reimplement in Rust/JS** for DofusClient backend