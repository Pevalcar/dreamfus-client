# DreamFus Godot Client

Un cliente Godot 4.8 para renderizar avatares de personajes Dofus usando assets extraídos del cliente Alea.

## Compatibilidad Godot 4.8

**Este proyecto requiere Godot 4.8 beta2+ debido a cambios significativos en la API de PackedByteArray:**

- `PackedByteArray.slice()` y `.sub()` han sido removidos → Usa `ByteArrayExtensions.byte_subarray()`
- `get_string_from_ascii(offset, length)` con parámetros no está disponible → Usa `ByteArrayExtensions.bytes_to_string_ascii()`
- `JSON.parse_string()` cambió de API → Usa `JSON.new().parse()` + `get_data()`

### ByteArrayExtensions

La clase `src/Utils/ByteArrayExtensions.gd` proporciona métodos estáticos de compatibilidad:

| Método | Uso |
|--------|-----|
| `byte_subarray(data, start, length)` | Reemplaza `.sub(start, length)` |
| `byte_subarray_from(data, start)` | Reemplaza `.sub(start)` hasta el final |
| `bytes_to_string_ascii(data, start, length)` | Reemplaza `get_string_from_ascii()` con parámetros |
| `peek_string_4(data, offset)` | Helper para strings de 4 bytes (mágicas como "A2DZ") |

## Estructura del Proyecto

```
godot-client/
├── scenes/
│   └── AvatarTest.tscn    # Escena de prueba para renderer de avatares
├── src/
│   ├── Scenes/
│   │   └── AvatarTest.gd  # Script de la escena de prueba
│   └── Components/
│       └── AvatarRenderer.gd  # Componente reutilizable para renderizar avatares
├── assets/
│   └── avatars/
│       ├── iop/
│       │   ├── static.webp      # Atlas de sprites para Iop
│       │   ├── atlas.webp       # Atlas completo
│       │   └── metadata.json    # Metadatos del avatar
│       ├── eniripsa/
│       ├── feca/
│       ├── osamodas/
│       └── ... (otros breeds)
├── project.godot
└── export_presets.cfg
```

## Requisitos

- Godot 4.8 (o superior)
- WebP support (nativo en Godot 4.8)

## Flujo de Trabajo

### 1. Extraer Assets desde Alea

Usar el script `extract_a2d_batch.py` en el directorio raíz:

```bash
python extract_a2d_batch.py --input "C:/Users/pevalcar/AppData/Local/Alea/d3pack/bones/" --output "./godot-client/assets/avatars/"
```

### 2. Generar Atlas de Avatares

Para distribución, usar `build_avatars.py`:

```bash
python build_avatars.py --input "C:/Users/pevalcar/AppData/Local/Alea/d3pack/bones/" --output "./godot-client/assets/avatars/"
```

### 3. Probar en Godot

1. Abrir el proyecto en Godot 4.8
2. El escenario principal es `AvatarTest.tscn`
3. Usar el selector de raza y presionar "Generar Avatar"

### 4. Exportar para Distribución

1. Ir a **Project → Export**
2. Agregar preset para "Desktop"
3. Ejecutar exportación

## Breed IDs (Dofus)

| ID | Nombre | Letra Look String |
|----|--------|-------------------|
| 1 | Iop | M |
| 2 | Eniripsa | G |
| 3 | Feca | O |
| 4 | Osamodas | E |
| 5 | Enutrof | A |
| 6 | Xelor | X |
| 7 | Cra | C |
| 8 | Sadida | S |
| 9 | Sacrier | I |

## Uso del AvatarRenderer

```gdscript
# Desde cualquier script
var renderer = AvatarRenderer.new()
add_child(renderer)

# Configurar por ID de raza
renderer.set_breed_from_id(1)  # Iop

# Configurar desde look string
renderer.set_character("Maged624608...")  # Iop
```

## Formato A2D

Los assets de avatar vienen en el formato Ankama 2D Object (A2D):

1. **A2DZ header**: Magic "A2DZ", versión, datos comprimidos
2. **Raw deflate**: Compresión sin zlib header (no soportado nativamente en Godot 4.8)
3. **A2D1 container**: Metadata y referencias a sprites
4. **WebP atlas**: Imagen compuesta con todos los sprites

### Solución Raw Deflate Godot 4.8

Godot 4.8 no soporta raw deflate nativamente. La solución implementada:

1. **JSON Pre-processing**: Scripts Python convierten A2D.Z → JSON usando `zlib.decompressobj(-zlib.MAX_WBITS)`
2. **4715+ archivos JSON**: Generados en `gen/a2d/`
3. **WebP Fallback**: Usado para renderizado visual rápido y estable

Ver `docs/A2D_RAW_DEFLATE_WORKAROUND.md` para detalles completos.

## Notas

- Los archivos WebP son atlases de 1024x1024 píxeles
- Cada sprite mide 64x64 píxeles
- La coordenada del sprite se determina por el índice en el atlas