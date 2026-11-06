# Solución para A2D.Z Deflate en Godot

## Problema

Godot 4.8 no tiene soporte nativo para **raw deflate** (el formato usado por A2D.Z) en GDScript. El parser Rust en `src/a2d/mod.rs` usa `flate2::read::DeflateDecoder` que trabaja con raw deflate, no zlib.

## Opciones de Solución

### Opción 1: GDExtension en Rust (Recomendado)

Crear una GDExtension que exponga el parser Rust directamente a Godot.

**Ventajas**:
- Reutiliza código existente probado
- Soporte completo para deflate y WebP
- Rendimiento óptimo

**Desventajas**:
- Necesita compilación adicional
- Complejidad de build para usuarios

**Implementación**:
```rust
// En godot-rust/src/lib.rs
#[godot::classes::init]
impl EXTENSION_NAME {
    fn init(gd: gd::InitHandle) {
        gd.add_class::<A2DParser>();
    }
}

#[godot::classes::class]
pub struct A2DParser;

#[godot::classes::methods]
impl A2DParser {
    #[godot::methods::constructor]
    fn new() -> Self {
        Self
    }

    #[godot::methods::method]
    fn parse_file(path: &str) -> Result<Dictionary, Error> {
        // Usar código de src/a2d/mod.rs
    }
}
```

### Opción 2: Script de Conversión Offline

Usar el script Python `src/a2d/convert_a2d.py` para pre-procesar archivos.

**Flujo**:
1. Usuario instala archivos de juego (A2D.Z)
2. Ejecutar `python convert_a2d.py input.a2d output.webp`
3. Los archivos WebP resultantes se usan directamente en Godot

**Comando de conversión por lote**:
```bash
python src/a2d/convert_a2d.py \
    --input-dir "C:/Alea/d3pack/bones/" \
    --output-dir "godot-client/assets/avatars/" \
    --recursive
```

### Opción 3: Usar zlib con header adicional

Modificar el parser para agregar un header zlib antes del raw deflate:

```python
import zlib

def decompress_a2dz(data: bytes) -> bytes:
    # Agregar header zlib (78 9C es el header estándar)
    zlib_header = bytes([0x78, 0x9C])
    return zlib.decompress(zlib_header + data[8:])
```

**Problema**: No todos los A2D.Z usan el mismo formato de compresión.

### Opción 4: GDExtension C++ con zlib

Crear una pequeña librería C++ que use zlib directamente:

```cpp
// deflate_wrapper.cpp
#include <zlib.h>

extern "C" {
    int decompress_raw(unsigned char* input, size_t input_len, 
                       unsigned char* output, size_t* output_len) {
        z_stream strm = {};
        strm.next_in = input;
        strm.avail_in = input_len;
        
        // Descompresión raw (sin header zlib)
        int ret = inflateInit2(&strm, -MAX_WBITS);
        // ... implementar inflar
    }
}
```

## Recomendación

Para DreamFus, usar **Opción 2 (Script de conversión)** como flujo principal:

1. **Desarrollo**: Usar script Python para generar WebP durante el desarrollo
2. **Producción**: Los archivos WebP pre-procesados se incluyen en el build
3. **Alternativa futura**: Implementar GDExtension cuando sea necesario soporte dinámico

## Archivos Involucrados

| Archivo | Propósito |
|---------|-----------|
| `src/a2d/mod.rs` | Parser Rust original (referencia) |
| `src/a2d/convert_a2d.py` | Script de conversión Python |
| `godot-client/src/A2D/A2DParser.gd` | Parser GDScript (sin deflate) |
| `godot-client/src/A2D/Bytes.gd` | Utilidades de byte manipulation |

## Flujo de Trabajo Recomendado

```
1. Extraer archivos del juego (A2D.Z)
   ↓
2. Ejecutar script de conversión
   python src/a2d/convert_a2d.py input.a2d output.webp
   ↓
3. Verificar en Godot
   - Cargar WebP como Texture2D
   - Validar dimensiones y contenido
   ↓
4. Si necesario, ajustar el parser GDScript
```

## Validación

Para verificar que los archivos WebP se cargan correctamente:

```gdscript
# En Godot Editor
func test_webp_load(path: String) -> void:
    var img := Image.new()
    img.load(path)
    if img.is_empty():
        push_error("Failed to load WebP: %s" % path)
    else:
        print("Loaded: %dx%d" % [img.get_width(), img.get_height()])
```