# Solución para Raw Deflate en Godot 4.8

## Problema

El formato de archivo A2D.Z de Dofus utiliza **raw deflate** (sin header zlib estándar), implementado en Python con:

```python
decompressor = zlib.decompressobj(-zlib.MAX_WBITS)
```

Sin embargo, **Godot 4.8 `PackedByteArray.decompress()` no soporta raw deflate** nativamente. Godot espera datos zlib estándar con un header de 2 bytes (`0x78 0x9C` para deflate normal).

## Solución Implementada: Pre-procesamiento JSON

### Correcciones Godot 4.8

**Godot 4.8 beta2 eliminó varios métodos de PackedByteArray:**
- `PackedByteArray.slice()` - removido
- `PackedByteArray.sub(start, length)` - removido  
- `PackedByteArray.get_string_from_ascii(offset, length)` - ahora solo acepta 0 argumentos

**Solución:** Crear una clase helper `ByteArrayExtensions.gd` con métodos estáticos:

```gdscript
# ByteArrayExtensions.gd (res://src/Utils/ByteArrayExtensions.gd)
class_name ByteArrayExtensions

# Reemplaza PackedByteArray.sub(data, start, length)
static func byte_subarray(data: PackedByteArray, start: int, length: int) -> PackedByteArray

# Reemplaza PackedByteArray.sub(data, start) hasta el final
static func byte_subarray_from(data: PackedByteArray, start: int) -> PackedByteArray

# Extrae string ASCII de bytes (equivalente a get_string_from_ascii con offset/length)
static func bytes_to_string_ascii(data: PackedByteArray, start: int, length: int) -> String

# Helper para strings de 4 bytes (mágicas como "A2DZ", "A2D1")
static func peek_string_4(data: PackedByteArray, offset: int) -> String
```

### Arquitectura

```
A2D.Z archivos (raw deflate)
    │
    ▼
Python scripts (zlib.decompressobj(-zlib.MAX_WBITS))
    │
    ▼
JSON pre-procesado (gen/a2d/XXX-1-static.json)
    │
    ▼
Godot 4.8 (carga JSON sin descompresión)
    │
    ▼
WebP fallback visual (assets/avatars/XXX/)
```

### Archivos Generados

Los scripts Python convierten archivos A2D.Z a JSON que Godot puede leer:

- `scripts/a2d_to_json.py` - Conversor de un archivo
- `scripts/generate_a2d_json.py` - Procesador por lotes (4715+ archivos generados)

### Uso

```bash
# Procesar directorio completo
python scripts/generate_a2d_json.py d3pack/bones/ gen/a2d/

# Verificar archivos generados
ls gen/a2d/
# Resultado: 1-1-static.json, 2-1-static.json, ..., 2351-1-static.json, etc.
```

### Integración con Godot (AvatarSprite.gd)

```gdscript
# Flujo de carga:
# 1. Busca JSON pre-procesado: res://gen/a2d/{bones_id}-1-static.json
# 2. Si existe, carga y parsea JSON
# 3. Muestra información de vértices/índices en log
# 4. Renderiza usando WebP fallback visual

func _load_from_a2d(bone_path: String, skin_path: String) -> void:
    var json_path = "res://gen/a2d/%d-1-static.json" % bones_id
    if FileAccess.file_exists(json_path):
        var json_data = _load_a2d_json(json_path)
        if json_data != null:
            # Datos parseados disponibles en json_data
            _load_webp_fallback_with_breed(breed_name)
```

## Alternativas Consideradas

1. **Implementar decoder raw deflate en GDScript** - Demasiado lento para runtime
2. **Usar C# con System.IO.Compression** - Complejidad adicional
3. **WebAssembly zlib decoder** - Overhead innecesario
4. **WebP fallback** - Solución recomendada para producción (ya implementada)

### JSON Parsing en Godot 4.8

En Godot 4.8, la API de JSON cambió:

```gdscript
# Antes (Godot 4.7 y anteriores)
var result = JSON.parse_string(json_text)
if result.error == OK:
    var data = result.result

# Ahora (Godot 4.8)
var json = JSON.new()
var parse_result = json.parse(json_text)
if parse_result == OK:
    var data = json.get_data()
```

**Importante:** `JSON.parse_string()` ya no devuelve un objeto con `.error` y `.result`. Usar `JSON.new().parse()` y `get_data()` es la forma correcta.

## Estructura JSON Generada

```json
{
  "version": 1,
  "flags": 1,
  "strings": [],
  "vertex_count": 1178,
  "vertices": [[24.0, 130.0], ...],
  "uvs": [[0, 0], ...],
  "colors": [0, ...],
  "indices": [0, 1, 2, ...],
  "parts": [...],
  "textures": [...],
  "_source_file": "1-1-static.a2d",
  "_source_size": 578952,
  "_decompressed_bytes": 1421208
}
```

## Limitaciones

- El parser actual usa WebP como fallback visual (más estable que renderizado mesh)
- Para renderizado completo de meshes, se necesitaría implementar:
  - Creación de MeshInstance2D desde vertices e índices
  - Binding de texturas para parts/chunks
  - Sistema de animación para frames

## Flujo de Carga Actual

1. `AvatarSprite.gd` busca: `{assets_path}/bones/{bones_id}-1-static.a2d`
2. Si existe, verifica JSON pre-procesado en: `res://gen/a2d/{bones_id}-1-static.json`
3. Si JSON existe, lo parsea y extrae metadatos
4. Renderiza usando `res://assets/avatars/{breed}/static.webp` o `atlas.webp`

## Referencias

- Formato A2D documentado en: `docs/A2D_FORMAT.md`
- Archivos WebP de ejemplo: `res://assets/avatars/iop/static.webp`
- Script de conversión original: `src/a2d/convert_a2d.py` (en servidor `jondo-servidor`)