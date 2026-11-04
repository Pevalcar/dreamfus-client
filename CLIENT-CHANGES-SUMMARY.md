# Resumen de Cambios Cliente - Conexión a TCP 5555 y Lista de Personajes

## 🎯 Objetivo del Sprint
Corregir el flujo de selección de personajes y depurar el timeout del handshake del servidor donde el mensaje `jtg` no se recibía después de `kvi` en el cliente DreamFus Godot.

## Estado Actual del Sprint

### ✅ Cambios Completados Hoy

#### 1. **LauncherUI.gd** - Corregido JSON.stringify
- **Problema**: Sintaxis incorrecta en `JSON.stringify()`
- **Antes**: `JSON.stringify({ usuario = user, clave = password, ip = "127.0.0.1" })`
- **Después**: `JSON.stringify({ "usuario": user, "clave": password, "ip": "127.0.0.1" })`
- **Impacto**: La petición HTTP al endpoint `/api/entrar` ahora envía el JSON correctamente

#### 2. **GameManager.gd** - Corregido tipo de parámetro en `_on_auth_response_received`
- **Problema**: El parámetro `servers_json` se declaraba como `Dictionary` pero el WebSocket envía los servidores como Array directamente
- **Antes**: `servers_json: Dictionary`
- **Después**: `servers_array: Array`
- **Impacto**: El parsing de servidores funciona correctamente al usar `servers_array.get("servers", [])` como Array ya no es necesario

#### 3. **GameManager.gd** - Corregido `_handle_kvi_characters` para usar protobuf
- **Problema**: Se intentaba parsear el payload de `kvi` como JSON UTF-8, pero es protobuf binario
- **Antes**: `var decoded: String = payload.get_string_from_utf8()` + JSON.parse()
- **Después**: `Proto.decode_kvi(payload)` - uso del decodificador protobuf existente
- **Impacto**: La lista de personajes se decodifica correctamente del formato protobuf del protocolo

#### 4. **CharacterSlot.gd** - Limpieza de señales redundantes
- **Problema**: Se emitía señal `clicked` además de `selected`, causando posible doble disparo
- **Cambio**: Eliminado `emit_signal("clicked")` y la declaración `signal clicked`
- **Impacto**: Solo se emite `selected` que es manejada por CharacterSelectUI

#### 5. **GameClient.gd** - Verificado límite de frames en `_drain_buffer`
- **Estado**: El límite ya estaba incrementado de 10 a 20 frames
- **Propósito**: Permite procesar el batch completo del welcome burst (kqp×3 + kvi + jtg)

### 📋 Componentes Verificados y Correctos

#### Flujo de Autenticación Completo
1. **HTTP POST** a `http://127.0.0.1:8888/api/entrar` con usuario/contraseña
2. **WebSocket** a `ws://127.0.0.1:5557` con mensaje `auth_request`
3. **Respuesta WebSocket** `auth_response` con lista de servidores
4. **Solicitud de selección de servidor** → respuesta con ticket
5. **TCP** a `127.0.0.1:5555` con el ticket (`kqz`)
6. **Welcome Burst**: `kqp × 3` → `kvi` → `jtg`
7. **Emisión de `characters_received`** con lista de personajes
8. **Selección de personaje** → envío de `kvw` al servidor
9. **Respuesta `hpd`** → transición a estado IN_GAME

### 🧪 Credenciales de Prueba
- **Usuario**: `keka`
- **Contraseña**: `test`
- **Account ID**: 188940901
- **Servidor**: 290
- **HTTP API**: `http://127.0.0.1:8888`
- **WebSocket**: `ws://127.0.0.1:5557`
- **TCP Game**: `tcp://127.0.0.1:5555`

## 📝 Estado de Archivos

### Archivos Modificados (Pendiente de commit)
| Archivo | Cambios |
|---------|---------|
| `src/UI/LauncherUI.gd` | JSON.stringify con claves correctas |
| `src/Core/GameManager.gd` | Parámetro Array en auth_response, Proto.decode_kvi en kvi |
| `src/Components/Character/CharacterSlot.gd` | Señal `selected` única, eliminada `clicked` |

### Archivos Nuevos (Stageados)
| Archivo | Propósito |
|---------|-----------|
| `docs/PROTOCOLO/README.md` | Índice de documentación del protocolo |
| `docs/PROTOCOLO/01-TRANSPORTE.md` | Documentación de capa de transporte |
| `docs/PROTOCOLO/02-LOGIN-Y-CUENTAS.md` | Flujo de login y gestión de cuentas |
| `docs/PROTOCOLO/03-PERSONAJES.md` | Protocolo de personajes y selección |
| `docs/PROTOCOLO/04-MUNDO-MAPAS-MOVIMIENTO.md` | Mundo, mapas y sistema de movimiento |
| `docs/PROTOCOLO/05-MONSTRUOS-Y-DROPS.md` | Monstruos y sistema de drops |
| `docs/PROTOCOLO/06-COMBATE.md` | Sistema de combate |
| `docs/PROTOCOLO/07-OPCODES.md` | Referencia de opcodes del protocolo |
| `docs/PROTOCOLO/08-INTERACTIVOS.md` | Objetos interactivos |
| `docs/PROTOCOLO/09-CHECKLIST-CLIENTE.md` | Checklist de implementación cliente |

## 🔧 Próximos Pasos

### Acción del Programador Requerida
El archivo `scenes/Launcher.tscn` fue modificado. **NO editar manualmente** - revisar el diff y aprobar los cambios si son correctos.

Los cambios a `.tscn` están en:
- `scenes/Launcher.tscn`
- `scenes/CharacterSelect.tscn`
- `scenes/Game.tscn`

### Reglas del Proyecto
- **PROHIBIDO** editar archivos `.tscn` manualmente - el formato puede corromperse
- GameClient se instancia dinámicamente en Main.gd - NO añadir GameClient a la escena
- Todas las variables de UI deben usar rutas `@onready` correctas

## 📚 Documentación Técnica

### Flujo de Señales
```
WebSocket Client → GameManager
    ├─ auth_response_received(success, account_id, servers_array, error)
    ├─ server_selection_response_received(success, ticket, host, ports, error)
    └─ connection_state_changed(connected)

TCP GameClient → GameManager  
    ├─ connected
    ├─ message_received(opcode, payload, request_id)
    │   ├─ "kqp" → marcador de bienvenida
    │   ├─ "kvi" → lista de personajes (protobuf)
    │   └─ "jtg" → fin del burst
    └─ error_occurred(message)
```

### Opcodes Clave del Protocolo
- `kqp` - Welcome marker (se envía 3 veces al conectar)
- `kvi` - Character info list (protobuf encode/decode)
- `jtg` - Jump to game (significa fin del burst)
- `kqz` - Present ticket (autenticación TCP)
- `kvw` - Select character (envío después de selección UI)
- `hpd` - Character loaded (respuesta del servidor)

## 📍 Instalaciones Referenciadas

| Ubicación | Propósito | Notas |
|-----------|-----------|-------|
| Cliente Alea | Cliente oficial de Dofus para análisis de UI | `C:\Users\pevalcar\AppData\Local\Alea` |
| DreamFus Cliente | Cliente alternativo basado en IA | `C:\Users\pevalcar\AppData\Local\DreamFus\Cliente` |
| Servidor | Endpoint de autenticación y juego | `C:\Users\pevalcar\Proyects\jondo-servidor` |
| UI Analysis | Referencia de elementos UI Dofus | `C:\Users\pevalcar\AppData\Local\Alea\ui_analysis.json` |

---

## 🎨 Estado del HUD y Manejo de Errores

### ✅ Completado
1. **Visualización de raza en HUD**
   - `GameUI.gd` con soporte para `BreedLabel` usando `get_node_or_null()`
   - Nombres de raza implementados (1-16): Feca, Osamodas, Enutrof, Sacrieur, Sadida, Xelor, Chafouis, Iop, Cra, Sram, Ecaflip, Ouginak, Tymador, Rubbaduck, Steamer, Eliotrope

2. **Manejo de errores TCP**
   - Timeouts implementados con `Timer.new()`
   - Timeout conexión TCP: 10 segundos
   - Timeout welcome burst: 15 segundos
   - Señales de error emitidas

### ⏳ Pendiente - Acción del Programador

**ÚNICAMENTE** requiere intervención del programador:
- Agregar `BreedLabel` a `Game.tscn` (HUD) - el nodo no existe en la escena

## 📦 Verificación

```bash
# Compilación Godot (sin errores)
"C:\Users\pevalcar\Godot\Godot.exe" --headless --path "C:\Users\pevalcar\Proyects\jondo-servidor\DofusClient\godot-client" --quit
```

Salida correcta:
```
[GameManager] Inicializado
[SimpleProtocolClient] Inicializado
[Main] Inicializando juego...
[GameClient] Inicializado
[LauncherUI] Preparando UI
[CharacterSelectUI] Preparando UI
[GameUI] Preparando UI del juego
[GameManager] TCP desconectado
```