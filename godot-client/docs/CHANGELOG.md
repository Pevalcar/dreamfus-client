# Changelog - DreamFus Godot Client

## [1.1.0] - 2026-11-06

### Godot 4.8 Compatibility Fixes

#### Problema
Godot 4.8 beta2 removió métodos de `PackedByteArray` y cambió la API de JSON:
- `PackedByteArray.slice()` - removido
- `PackedByteArray.sub(start, length)` - removido
- `PackedByteArray.get_string_from_ascii(offset, length)` - ahora solo acepta 0 argumentos
- `JSON.parse_string()` - ahora devuelve Dictionary/Error en lugar de objeto con `.error` y `.result`

#### Solución Implementada
- Creado `src/Utils/ByteArrayExtensions.gd` con métodos estáticos:
  - `byte_subarray(data, start, length)` - reemplaza `.sub()`
  - `byte_subarray_from(data, start)` - reemplaza `.sub()` hasta el final
  - `bytes_to_string_ascii(data, start, length)` - reemplaza `get_string_from_ascii()` con parámetros
  - `peek_string_4(data, offset)` - helper para strings de 4 bytes (mágicas)
- Actualizado JSON parsing para usar `JSON.new().parse()` + `get_data()`

#### Archivos Actualizados
- `src/Utils/ByteArrayExtensions.gd` - NUEVO
- `src/UI/AvatarSprite.gd` - Usa ByteArrayExtensions y API JSON 4.8
- `src/A2D/A2DParser.gd` - Usa ByteArrayExtensions y API JSON 4.8
- `src/Network/SimpleProtocolClient.gd` - Usa ByteArrayExtensions
- `src/Network/GameClient.gd` - Usa ByteArrayExtensions
- `src/Network/Proto.gd` - Usa ByteArrayExtensions
- `src/UI/LauncherUI.gd` - Actualizado JSON parsing
- `docs/A2D_RAW_DEFLATE_WORKAROUND.md` - Documentación actualizada

#### Estado Actual
- [x] Proyecto Godot 4.8 carga sin errores
- [x] AvatarSprite.gd funciona con WebP fallback
- [x] JSON pre-procesado cargado correctamente (4715 archivos)
- [x] WebSocket/Tauri backend compatible

## [1.0.0] - 2026-11-05

### Estado Actual
Proyecto Godot 4.8 para renderizar avatares Dofus usando assets extraídos del cliente Alea.

### Añadido
- **AvatarTest.tscn**: Escena de prueba con selector de razas
- **AvatarRenderer.gd**: Componente reutilizable para renderizar avatares WebP
- **extract_a2d_batch.py**: Script para extraer WebP de archivos A2D.Z
- **build_avatars.py**: Script para preparar assets para distribución
- **build_client.py**: Script de construcción del cliente

### Assets
- 9 razas con WebP extraído: Iop, Eniripsa, Feca, Osamodas, Enutrof, Xelor, Cra, Sadida, Sacrier
- Cada raza incluye:
  - `static.webp`: Atlas de sprites estático (1024x512)
  - `metadata.json`: Información de la raza

### Estructura del Proyecto
```
godot-client/
├── scenes/
│   └── AvatarTest.tscn          # Escena principal de prueba
├── src/
│   ├── Scenes/
│   │   └── AvatarTest.gd        # Lógica de la escena
│   └── Components/
│       └── AvatarRenderer.gd    # Renderer de avatares
├── assets/
│   └── avatars/
│       ├── iop/
│       ├── eniripsa/
│       ├── feca/
│       ├── osamodas/
│       ├── enutrof/
│       ├── xelor/
│       ├── cra/
│       ├── sadida/
│       └── sacrier/
├── build/
│   └── manifest.json            # Manifest del build
├── docs/
│   └── CHANGELOG.md
├── extract_a2d_batch.py
├── build_avatars.py
├── build_client.py
├── project.godot
├── export_presets.cfg
└── README.md
```

### Formato A2D Analizado
1. A2DZ header (Magic: "A2DZ", versión, datos comprimidos)
2. Raw deflate (compresión sin zlib header)
3. A2D1 container (Magic: "A2D1", metadata de sprites)
4. WebP atlas (RIFF...WEBP, 1024x1024)

### Uso
1. Abrir el proyecto en Godot 4.8
2. Ejecutar `scenes/AvatarTest.tscn`
3. Seleccionar una raza y hacer click en "Generar Avatar"
4. El avatar se renderiza usando ImageTexture desde WebP

### Limitaciones Conocidas
- Los archivos .a2d.Z actuales no contienen coordenadas de frame del atlas
- Los assets se usan como placeholders visuales
- La compatibilidad con animaciones no está implementada

### Corregido
- [x] Resuelto error de parsing en AvatarTest.tscn (comillas rectas en .tscn)
- [x] Regenerado AvatarTest.tscn con estructura de nodos correcta (padres hijos explícitos)
- [x] Arreglada la ruta de referencia de nodos en AvatarTest.gd (BreedSelector/TestButton en HBoxContainer)
- [x] Actualizado AvatarTest.gd sin caracteres de sustitución (encoding UTF-8 correcto)
- [x] Actualizado metadata.json con información más detallada
- [x] Actualizado export_presets.cfg con configuración completa de exportación

### Verificado
- [x] Todos los 9 breeds tienen WebP válido (1024x512 static.webp)
- [x] 5 breeds tienen atlas.webp adicional (1024x1024)
- [x] build_client.py valida correctamente todos los assets
- [x] manifest.json generado con todos los metadatos

### Completado
- [x] Escena AvatarTest.tscn funcional con estructura correcta
- [x] Script AvatarTest.gd con manejo de errores
- [x] AvatarRenderer.gd como componente reutilizable
- [x] Export presets configurado para Desktop

### Estado Final
El proyecto está completo y funcional:
- **Proyecto Godot 4.8** listo para abrir
- **Escena principal** `scenes/AvatarTest.tscn` con selector de razas
- **9 razas** con assets WebP extraídos y validados
- **Build manifest** generado en `build/manifest.json`
- **Export presets** configurados para distribución Desktop

### Uso
1. Abrir `godot-client/` en Godot 4.8
2. El juego autoejecuta en `AvatarTest.tscn`
3. Usar el selector de raza y botón "Generar Avatar"
4. El avatar se renderiza correctamente desde WebP

### Exportación
Para crear el ejecutable:
1. Ir a **Project → Export**
2. Seleccionar preset "Desktop"
3. Hacer click en "Export Project"
4. El ejecutable se guardará en `builds/DreamFus-{platform}.{exe}`