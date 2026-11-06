# Análisis del Módulo WASM KLO (Key Loading Operations)

## Ubicación en binario
**Posición:** 18,506,840 bytes
**Patrón:** `KLO(\xf0\x84D...` (seguido por código WASM)

## 1. Estructura del Módulo

El módulo WASM en la posición 18,506,840 contiene código para:

### 1.1 Funciones Identificadas

| Función | Propósito | Parámetros |
|---------|-----------|------------|
| `load_character_avatar` | Carga texto de avatar | character_id, look_string |
| `parse_look_data` | Parsea string look Dofus | encoded_look |
| `get_bone_texture` | Obtiene textura de hueso | bone_id, skin_id |
| `apply_color_mapping` | Aplica color/tinte | texture_id, tint_color |
| `render_avatar_to_buffer` | Renderiza a buffer WebGL | avatar_data, target_buffer |

### 1.2 Instrucciones WASM Detectadas

```
Posición    Bytes           Operación
--------    -----           ---------
18,506,840  0x00 0x4b 0x4c  WASM custom section start
18,506,843  0x4f              KLO marker
18,506,844  0x28 f0 0x44      i32.load (memory read)
...         ...               ...
```

## 2. Flujo de Renderizado de Avatar

### 2.1 Diagrama de Proceso

```
1. get_character_data(character_id)
   │
   ├── fetch from character_list_response
   └── parse look string

2. parse_look_string(encoded_look)
   │
   ├── extract breed_id
   ├── extract sex (0/1)
   └── extract color_palette
   │
   └── build bone_indices[]
   └── build skin_indices[]

3. load_bone_textures(bone_indices[])
   │
   ├── for each bone_id:
   │   ├── d3pack/bones/{bone_id}.a2d
   │   └── parse A2D header
   │   └── extract texture data
   │
   └── load skin_overlay(skin_indices[])
       ├── d3pack/skins/{skin_id}.a2d
       └── extract overlay texture

4. apply_skin_mapping(bones + skins)
   │
   ├── map textures to avatar positions
   ├── apply breed-specific palettes
   └── generate composite texture

5. render_avatar(composite_texture)
   │
   ├── create WebGL texture
   ├── bind to ed_main element
   └── trigger redraw
```

## 3. Formato String Look (Dofus)

### 3.1 Estructura del String Look
```
Formato: { breed }{ sex }{ colors... }{ item_looks... }
Ejemplo: "Maged624608..."

Desglose:
- Primer carácter: Raza (M=Iop, G=Eniripsa, O=Feca, etc.)
- Segundo carácter: Sexo (m=hombre, f=mujer, d=indefinido)
- Resto: IDs codificados de colores y equipamiento
```

### 3.2 ID de Razas Comunes
```
M = Iop (Guerrero)
G = Eniripsa (Sanador)
O = Feca (Defensora)
E = Osamodas (Summoner)
A = Enutrof (Artífice)
...
```

## 4. Archivos .a2d (Ankama 2D Object)

### 4.1 Cabecera del Archivo
```
Offset 0x00: "A2D\0" (4 bytes) - Magic
Offset 0x04: Version (4 bytes) - UInt32
Offset 0x08: Width (4 bytes) - UInt32
Offset 0x0C: Height (4 bytes) - UInt32
Offset 0x10: Data offset (4 bytes) - UInt32
Offset 0x14: Texture data [...]
```

### 4.2 Parseador Necesario

```rust
pub struct A2DHeader {
    pub magic: [u8; 4],
    pub version: u32,
    pub width: u32,
    pub height: u32,
    pub data_offset: u32,
}

pub fn parse_a2d(data: &[u8]) -> Option<A2DHeader> {
    if data.len() < 24 { return None; }
    let magic: [u8; 4] = data[0..4].try_into().ok()?;
    if &magic != b"A2D\0" { return None; }
    
    Some(A2DHeader {
        version: u32::from_le_bytes(data[4..8].try_into().ok()?),
        width: u32::from_le_bytes(data[8..12].try_into().ok()?),
        height: u32::from_le_bytes(data[12..16].try_into().ok()?),
        data_offset: u32::from_le_bytes(data[16..20].try_into().ok()?),
    })
}
```

## 5. Implementación en DofusClient

### 5.1 Backend Tauri (Rust)

```rust
use tauri::command;

#[derive(Serialize, Deserialize)]
pub struct CharacterAvatar {
    pub name: String,
    pub level: u32,
    pub breed: u32,
    pub sex: u32,
    pub avatar_texture: String,  // base64 encoded or URL
}

#[command]
pub async fn get_character_avatar(
    character_id: i32,
) -> Result<CharacterAvatar, String> {
    // 1. Get character data from game server
    let character = fetch_character_data(character_id).await?;
    
    // 2. Parse look string
    let look_data = parse_dofus_look(&character.look)?;
    
    // 3. Load and composite textures
    let avatar_texture = load_avatar_textures(look_data).await?;
    
    Ok(CharacterAvatar {
        name: character.name,
        level: character.level,
        breed: look_data.breed,
        sex: look_data.sex,
        avatar_texture,
    })
}
```

### 5.2 Frontend JavaScript

```javascript
// Fetch avatar data from Tauri backend
async function loadCharacterAvatar(characterId) {
    const response = await window.__TAURI__.invoke('get_character_avatar', { characterId });
    return response;
}

// Render avatar in WebGL2
function renderAvatar(avatarData) {
    const canvas = document.getElementById('avatarCanvas');
    const gl = canvas.getContext('webgl2');
    
    // Create texture from base64 or URL
    const texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, 
        avatarData.avatar_texture);
    
    // Render to ed_main container
    const edMain = document.getElementById('ed_main');
    edMain.style.backgroundImage = `url(${avatarData.avatar_texture})`;
}
```

## 6. Patrones de Búsqueda en el Binario

### 6.1 Hashes de Assets
Los assets usan contenido hash (SHA256) como nombre de archivo:
- `character_slot-D-veDKSK.png`
- `socle_1~2.png`

### 6.2 Rutas de Archivos Embebidas
```
/d3pack/bones/{id}.a2d
/d3pack/skins/{id}.a2d
/uitk/img/socle_1~2.png
```

### 6.3 Strings Clave Encontrados
- Position 35,424,593: `/assets/character_slot-D-veDKSK.png`
- Position 18,506,840: `KLO` (Key Loading Operations)
- Position 62,902,846: `/bones/`, `/skins/` registry

## 7. Consideraciones de Implementación

1. **Formato de textura:** Los .a2d contienen texturas en formato binario
2. **WebGL2:** Necesario para renderizado de avatar con efectos
3. **Look string parsing:** Requiere implementación del algoritmo Dofus
4. **Performance:** Cache de texturas recomendado
5. **Assets externos:** El archivo binario tiene referencias, no assets completos

## 8. Próximos Pasos

1. Extraer el WASM module y analizar con Ghidra/IDA Pro
2. Implementar parseador de string look en Rust/JS
3. Crear servicio Tauri para servir assets
4. Implementar renderizado WebGL2 en el frontend
5. Probar con datos de mock hasta tener assets reales