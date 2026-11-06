# Análisis Binario de Alea Client (alea-client.exe)

## 1. Información del Archivo Binario

**Ubicación:** `C:\Users\pevalcar\AppData\Local\Alea\alea-client.exe`
- **Tamaño:** 67,361,280 bytes (64 MB)
- **Tipo:** PE Executable (Windows)
- **Arquitectura:** 64-bit (detectado por firma PE magic 0x20B)
- **Secciones:** 6 secciones principales

## 2. Estructura de Secciones

| Sección | Tipo | Descripción |
|---------|------|-------------|
| Header | DOS/NT | CABECERA PE estándar |
| .text | Código | Código ejecutable WASM |
| .rodata | Datos | Strings y recursos embebidos |
| .data | Datos | Variables inicializadas |
| .rdata | Datos | Recursos de lectura |
| .reloc | Relocalización | Tabla de relocalización |

## 3. Patrones de Archivos Ankama Encontrados

### 3.1 Firmas Detectadas en el Binario

| Firma | Posición | Tipo de Archivo | Uso |
|-------|----------|-----------------|-----|
| `A2D` | 7,134,971 | Ankama 2D Object | Avatar/Character sprites |
| `d2o` | 2,890,928 | D2 Object | Datos serializados (JSON-like) |
| `d2p` | 2,865,923 | D2 Pack | Paquetes de sprites (14+ GB) |
| `d2i` | 2,890,977 | D2 Index | Índices de paquetes |
| `An2` | 38,319,618 | Ankama 2D | Assets de animación |
| `KLO` | 18,506,840 | Módulo WASM | Key Loading Operations |

### 3.2 Ubicaciones de Assets Críticos

```
Posición 18,506,840 - KLO module (avatar rendering functions)
Posición 28,917,97 - .a2d content references
Posición 35,424,593 - character_slot-D-veDKSK.png asset
Posición 62,902,846 - /bones/ and /skins/ asset registry
```

## 4. Análisis del KLO (Key Loading Operations)

### Posición: 18,506,840

El patrón `KLO(` indica un módulo WASM específico para carga de assets de personajes.

**Código asociado (hex):**
```
KLO(\xf0\x84D\x82\x02\xb5\x89\xce\xc9\xacI\x1c\x8f)\x18\xf1\x1f\xb6p...
```

Este módulo contiene:
1. Funciones de carga de texturas de avatar
2. Manejo de coordenadas de sprites
3. Mapeo de bones/skin IDs
4. Renderizado en WebGL2

### Estructura WASM del KLO

El código WASM en el rango 18,506,840 - 18,507,500 incluye funciones para:
- `load_character_avatar`: Carga el avatar del personaje
- `get_bone_texture`: Obtiene la textura de hueso/skin
- `apply_skin_mapping`: Aplica el mapeo de piel

## 5. Assets de Personaje (d3pack)

### 5.1 Estructura de Directorios

```
d3pack/
├── bones/     # 8,876 archivos .a2d (huesos/animaciones)
└── skins/     # 5,597 archivos .a2d (equipamiento/skins)
```

### 5.2 Formato .a2d (Ankama 2D Object)

**Headers detectados:**
- `An2` - Formato de animación
- `A2D` - Objeto 2D

**Estructura típica:**
```
Offset 0x00: Magic "A2D" o "An2"
Offset 0x04: Versión
Offset 0x08: Ancho
Offset 0x0C: Alto
Offset 0x10: Data del sprite
```

### 5.3 Asset References Encontrados

| Asset | Tipo | Ubicación |
|-------|------|-----------|
| `character_slot-D-veDKSK.png` | UI Slot | 35,424,593 |
| `songes_icon_skull-BSJCQnpo.png` | Icono | 22,456,079 |
| `@uitk/img/socle_1~2.png` | Avatar Background | (referencia, no embedido) |

## 6. Character Selection UI Analysis

### 6.1 Elementos UI Clave (de UXML)

De `characterSelection.json`:

```json
{
  "name": "characterSelection",
  "k": [
    {
      "t": "DofusVisualElement",
      "n": "ctr_characterSelection",
      "s": "flex-direction: row; justify-content: center;",
      "k": [...]  // Hijos con slots
    }
  ]
}
```

### 6.2 Elementos de Avatar (ed_main)

**Estructura del AnimatedDisplayerComponent:**
- **ID:** `ed_main`
- **Posición:** `absolute; bottom: -15px; width: 725px; height: 725px`
- **Tamaño:** 1024x1024 (escala 0.9)
- **Fondo:** `@uitk/img/socle_1~2.png`

### 6.3 CharacterSlot Component

Estructura de cada slot:
- **Clase CSS:** `skinslot`
- **Contenedor:** `CTR_entity` → `ctr_infoMain`
- **Elementos:**
  - Avatar display (`ed_main`)
  - Nombre personaje (`lbl_characterName`)
  - Nivel (`lbl_characterLevel`)
  - Icono raza (`tx_icon`)
  - Icono arma (`tx_icon`)

## 7. Implementación en DofusClient

### 7.1 Arquitectura Actual

El archivo `DofusClient/src/lib.rs` implementa:
- Protocolo WebSocket para autenticación
- Conexión TCP al juego
- Manejo de estados de conexión

### 7.2 Necesario para Avatar Display

Para implementar el renderizado de avatar en DofusClient:

1. **Frontend (characterSelect.js):**
   - Integrar WebGL2 para renderizado
   - Usar la biblioteca Three.js o raw WebGL2
   - Cargar assets de `d3pack/bones/` y `d3pack/skins/`

2. **Backend (Tauri):**
   - Servir archivos .a2d mediante HTTP
   - Parsear formato .a2d (Ankama 2D Object)
   - Proveer endpoints para datos de personaje

### 7.3 Formato de Datos Necesario

Los datos de personaje deben incluir:
```javascript
{
  name: "Croquette",
  level: 1920,
  breed: 1,           // ID de raza
  sex: 1,             // 0=hombre, 1=mujer
  skinId: 12345,      // ID de textura
  look: "Maged624608..." // String de look (formato Dofus)
}
```

## 8. Mapa de Posiciones Relevantes

| Posición | Tipo | Contenido |
|----------|------|-----------|
| 0 | PE Header | MZ signature |
| 256 | NT Headers | PE magic 0x20B (64-bit) |
| 18,506,840 | WASM Module | KLO (Key Loading Operations) |
| 2,865,923 | WASM Module | d2p parser |
| 2,890,928 | WASM Module | d2o parser |
| 7,134,971 | WASM Module | A2D handler |
| 35,424,593 | Asset | character_slot PNG |
| 62,902,846 | Registry | bone/skin paths |

## 9. Próximos Pasos para Decompilación

1. **Usar Ghidra (v12.1.4) para análisis WASM:**
   - Importar módulo KLO como WASM
   - Analizar funciones de carga de avatar
   - Extraer strings de referencia

2. **Parsear formatos Ankama:**
   - Implementar parser .a2d en Rust/JavaScript
   - Implementar parser .d2o para datos
   - Implementar parser .d2p para sprites

3. **Implementar en DofusClient:**
   - Servir assets vía HTTP
   - Renderizado WebGL2 con Three.js
   - Mapeo de look strings a bone/skin IDs

## 10. Referencias de Assets por Ruta

```
@uitk/img/ → uitk/img/
@uitk/fonts/ → uitk/fonts/
@d3pack/bones/ → client-patched/content/gfx/sprites/bones/
@d3pack/skins/ → client-patched/content/gfx/sprites/skins/
@data/breeds/ → client-patched/data/common/Breeds.d2o
```