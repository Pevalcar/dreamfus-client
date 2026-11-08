# Cambios Implementados

## Resumen
Se han implementado los siguientes cambios para arreglar el flujo de selección de personajes y agregar soporte para los opcodes de Block 1 (kub, irq, hms, ivx, itg) que transmiten stats, jobs, spells, inventory y shortcut bars después de la selección de personaje.

## Cambios Completados

### 1. ByteArrayExtensions.gd - Extensión de utilidades para byte arrays
**Archivo:** `godot-client/src/Utils/ByteArrayExtensions.gd`
- `byte_subarray()` - Extrae subarrays de PackedByteArray
- `read_u32_le()` - Lee enteros 32-bit en little-endian
- `read_u64_le()` - Lee enteros 64-bit en little-endian
- `pad_array()` - Rellena arrays a un tamaño específico
- `starts_with()` - Verifica prefijo de byte array
- `to_hex()` - Convierte a string hexadecimal

### 2. Proto.gd - Utilidades protobuf
**Archivo:** `godot-client/src/Network/Proto.gd`
- `write_varint()` - Codifica VarInt protobuf
- `read_varint()` - Decodifica VarInt protobuf (retorna Array [value, next_offset])
- `read_fixed32()` / `read_fixed64()` - Lectura de valores fijos
- `read_length_delimited()` - Lectura de campos longitud-delimited
- `build_field()` - Construye campos protobuf
- Constantes de wire type

### 3. CharacterData.gd - Modelo de datos del personaje
**Archivo:** `godot-client/src/Data/CharacterData.gd`
- Propiedades exportadas para ID, nombre, nivel, experiencia, kamas
- Arrays para stats, jobs, spells, inventory
- Dictionary para spell_bar y alignment
- Métodos de ayuda: `has_stat()`, `get_stat_value()`, `get_total_stat()`, etc.
- Métodos de serialización: `to_dict()`, `from_dict()`

### 4. WorldProto.gd - Decodificadores de protocolo
**Archivo:** `godot-client/src/Network/WorldProto.gd`

#### Decodificadores implementados:
- `decode_jru()` - Cambio de mapa
- `decode_kkr()` - Datos del mapa
- `decode_kvw()` - Información del personaje (nuevo)
- `decode_kva()` - Character alive (nuevo)
- `decode_kub()` - **Stats del jugador** ✅
- `decode_irq()` - **Jobs/Profesiones** ✅
- `decode_hms()` - **Lista de hechizos** ✅
- `decode_ivx()` - **Inventario** ✅
- `decode_itg()` - **Barra de atajos** ✅

#### Helper functions:
- `_parse_kub_stat()` - Parsea estadística individual de kub
- `_parse_kub_alignment()` - Parsea alineación de kub
- `_parse_irq_job()` - Parsea profesión de irq
- `_parse_hms_spell()` - Parsea hechizo de hms
- `_parse_ivx_item()` - Parsea item de inventario
- `_parse_ivx_item_body()` - Parsea body del item
- `_parse_itg_shortcut()` - Parsea atajo del shortcut bar
- `_parse_itg_spell_ref()` - Parsea referencia de hechizo
- `_parse_itg_item_ref()` - Parsea referencia de item
- `_varint_size()`, `_field_size()` - Utilidades de cálculo

### 5. GameManager.gd - Gestor del estado del juego
**Archivo:** `godot-client/src/Core/GameManager.gd`

#### Variables de estado Block 1:
- `player_stats` - Diccionario de estadísticas
- `player_jobs` - Array de profesiones
- `player_spells` - Array de hechizos aprendidos
- `player_inventory` - Diccionario con kamas e items
- `spell_bar` - Datos de la barra de atajos

#### Handlers implementados:
- `_handle_kub()` - Maneja stats del jugador
- `_handle_irq()` - Maneja profesiones
- `_handle_hms()` - Maneja hechizos
- `_handle_ivx()` - Maneja inventario
- `_handle_itg()` - Maneja barra de atajos
- `initialize_player()` - Inicializa estado del jugador
- `get_player_summary()` - Resumen para debug

### 6. GameClient.gd - Cliente de protocolo
**Archivo:** `godot-client/src/Core/GameClient.gd`
- Recepción y despacho de mensajes por opcode
- Señales para cada tipo de dato recibido
- Control de estado `kvw_allowed` y `block1_received`
- Handlers internos para cada opcode Block 1

### 7. project.godot - Configuración del proyecto
**Archivo:** `godot-client/project.godot`
- Configuración básica de Godot 4.8
- Ventana 1280x720, VSync habilitado
- Auto-load de GameManager

## Formatos de Protocolo Implementados

### kub (opcode 546) - Stats del jugador
```
f2 { f1 { f1: stat_id, f4/f5/f2: value }, f7: experience, f8: next_level, f9: alignment, f10: kamas }
```

### irq (opcode 547) - Profesiones
```
f1 { f1: profession, f2: next_level, f3: level, f4: floor, f5: total } (repeated)
```

### hms (opcode 571) - Lista de hechizos
```
f1 { f1: grade, f3: spell_id, f4: origin } (repeated), f2: 1 at end
```

### ivx (opcode 572) - Inventario
```
f1: kamas, f3 { f1: slot, f5 { f1: template, effects }, f3: count, f4: uid } (repeated)
```

### itg (opcode 612) - Barra de atajos
```
f1 { f2: slot, f6 { f2: spell_id } } for spells, f9: items; f2: bar_type (1=spell, 0=item)
```

## Verificación
- ✅ Proyecto compila sin errores (`godot --headless --path godot-client --quit`)
- ✅ Todos los decodificadores de Block 1 implementados
- ✅ Helpers con tipos de retorno correctos (Dictionary vacío en lugar de null)
- ✅ Uso correcto de Proto.read_varint para patrones Array-return
- ✅ Estructura de datos extendida (CharacterData.gd)

## Próximos Pasos
- [ ] Probar con credenciales reales: `keka/test`, ID `188940901`, servidor `290`
- [ ] Verificar datos recibidos en consola durante la conexión
- [ ] Integrar datos con UI del inventario y hechizos (trabajo futuro)

## Flujo de Protocolo Soportado
```
1. Welcome Burst: kqp×3 → kvi → jtg
2. Character Select: kvw → kva  
3. Block 1: kub → irq → hms → ivx → itg  ← ✅ IMPLEMENTADO
4. Block 2: kkr → (map data)
5. Block 3: jss → lva → jpv → hpd
```

## Notas Técnicas
- **kvw_allowed flag**: Se establece en `true` al recibir jtg, se pone en `false` después de enviar kvw. No se vuelve a habilitar.
- **No se requieren confirmaciones lqc/kqo**: El flujo simplificado asume que el servidor envía los 3 bloques secuencialmente.
- **kvw no es replayado**: El servidor construye kub desde la base de datos, no desde capture.