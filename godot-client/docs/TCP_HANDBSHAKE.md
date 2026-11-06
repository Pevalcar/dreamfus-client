# TCP Handshake Implementation - DreamFus Godot Client

## Visión General

Este documento documenta la implementación del handshake TCP para la comunicación con el servidor de juego (GameNodeProxy) en el puerto 5555.

## Arquitectura

### Componentes Involucrados

| Archivo | Propósito |
|---------|-----------|
| `src/Network/GameClient.gd` | Cliente TCP que maneja el handshake y la recepción de mensajes |
| `src/Network/Proto.gd` | Utilidades protobuf para codificación/decodificación |
| `src/Core/GameManager.gd` | Orquestador que coordina el handshake y emite señales |
| `src/UI/CharacterSelectUI.gd` | UI que muestra la lista de personajes |

### Diagrama del Flujo

```
┌─────────────────────────────────────────────────────────────────┐
│                     HANDSHAKE SECUENCIA                         │
└─────────────────────────────────────────────────────────────────┘

WebSocket Auth Complete
        │
        ▼
GameManager.select_server() 
        │
        ▼
GameManager._on_server_selection_response_received()
        │  ticket = "e7193a7a..."
        │  host = "127.0.0.1"
        │  port = 5555
        ▼
GameClient.connect_to_game()  ──────► TCP Connect (5555)
        │
        ▼
GameClient.send_ticket()
        │  Frame: kqz with ticket
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                  WELCOME BURST (Múltiples mensajes)            │
├─────────────────────────────────────────────────────────────────┤
│  kra     ← Ack (vacío)                                         │
│  kqp     ← Heartbeat marker (x3)                               │
│  lqu     ← Clock sync request                                    │
│  hoy     ← Server greeting (f6=language, f7=200 feature mask)  │
│  kqu     ← Server heartbeat                                      │
│  mgq/mgt/hpd ← Server state queries                             │
│  krs     ← Ready state                                          │
│  mgz     ← Mailbox size                                         │
│  kqp     ← Additional heartbeat                                │
│  kvi     ← Character list (307 bytes, 4 characters)            │
│  jtg     ← END OF BURST → emite characters_received()          │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
CharacterSelectUI muestra lista de personajes
```

## Implementación por Archivo

### 1. Proto.gd - Utilidades Protobuf

#### decode_kvi() - Parsing de Lista de Personajes

**Propósito:** Decodificar el mensaje kvi que contiene la lista de personajes.

**Estructura inversa (lo que contiene el servidor):**
```protobuf
message kvi {
  repeated Character characters = 1;
}

message Character {
  string name = 2;
  int32 level = 3;
  Traits traits = 4;
  int64 id = 2;  // Dentro de character, no fuera
}

message Traits {
  SexContainer sex_container = 2;  // Empty cuando sex=0
  bytes look = 6;
  int32 breed = 7;
}

message SexContainer {
  int32 sex = 3;
}
```

**Crucial:** `look` (f6) y `breed` (f7) están dentro de `traits` (f4), no a nivel de personaje.

#### send_push() - Enviar Mensajes PUSH

**Propósito:** Enviarse mensajes con formato server push (root field f1).

**Uso en kvw:**
```gdscript
# kvw es un mensaje PUSH, no REQUEST
# Formato: f1 { f1: { f1: character_id } }
func send_character_selection(character_id: int) -> void:
    var inner_msg = Proto.message(1, Proto.put_varint_data(1, character_id))
    send_push("kvw", inner_msg)
```

### 2. GameClient.gd - Cliente TCP

#### _process() - Polling para Godot 4.8 Beta2

**Desafío:** Las señales de WebSocket/TCP no funcionan fiablemente en Godot 4.8 beta2.

**Solución:** Usar `_process()` con polling explícito:

```gdscript
func _process(_delta: float) -> void:
    if tcp == null:
        return
    
    tcp.poll()
    var status: int = tcp.get_status()
    
    if status == StreamPeerTCP.STATUS_CONNECTED:
        if not _connected:
            _connected = true
            connected.emit()
        
        # CRITICAL: Check available bytes BEFORE reading
        var available: int = tcp.get_available_bytes()
        if available > 0:
            # get_data() returns [Error, PackedByteArray] en Godot 4.8
            var result = tcp.get_data(available)
            var err = result[0]
            var data = result[1]
            # ... process data
```

#### send_ticket() - Envío de Ticket

**Formato esperado por el servidor:**
```
kqz {
  f2 {           // Any wrapper
    f1: "type.ankama.com/kqz"
    f2: kqz_inner
  }
}

kqz_inner {
  f2: ticket
  f3: language  // opcional
}
```

### 3. GameManager.gd - Orquestador

#### _on_game_client_connected()

**Flujo:**
1. El GameClient se conecta al TCP
2. Se envía el ticket pendiente: `_game_client.send_ticket(_pending_ticket)`
3. Se activa el modo burst: `_in_welcome_burst = true`

#### _on_game_client_message_received()

**Manejo del welcome burst:**

```gdscript
if _in_welcome_burst:
    match opcode:
        "kqp":
            pass  # Ignorar heartbeat markers
        
        "kvi":
            _handle_kvi_characters(payload)
            # Parsea el payload con Proto.decode_kvi()
            # Agrega personajes a _characters_list
        
        "jtg":
            # FIN del burst - emitir señal
            _in_welcome_burst = false
            characters_received.emit(_characters_list)
            _characters_list.clear()
        
        "kqy", "lqu":
            # Heartbeat - responder con kqo
            _game_client.send_heartbeat()
        
        _:
            pass  # Ignorar otros opcodes del burst
```

#### _handle_kvi_characters()

**Proceso:**
1. `var kvi_chars = Proto.decode_kvi(payload)`
2. Para cada personaje:
   - Crear objeto `CharacterData.new()`
   - Asignar id, name, level, sex, breed, look
   - Agregar a `_characters_list`

### 4. CharacterSelectUI.gd - UI de Selección

#### Conexión de Señales

```gdscript
func _connect_signals():
    if GameManager.instance != null:
        GameManager.instance.characters_received.connect(_on_characters_received)
```

#### _on_characters_received()

```gdscript
func _on_characters_received(characters: Array):
    _characters = characters
    _populate_character_list()
```

## Detalles de Protocolo

### Frame Format

**Prefijo de longitud:** 4 bytes big-endian + VarInt de longitud variable

```
[VarInt: payload_size][protobuf_envelope]
```

### VarInt Encoding

El VarInt usa codificación estándar de protobuf:
- 7 bits de datos por byte
- Bit 7 como flag de continuación
- Números negativos usan 10 bytes (complemento a dos)

### Envelope Structure

**CLIENT REQUEST (kqz, kvw):**
```
f2 {               // Root = 2 (request)
  f1: Any {        // Wrapper
    f1: "type.ankama.com/opcode"
    f2: payload
  }
  f2: request_id  // -1 para nuevos
}
```

**SERVER PUSH (lqu, hoy, kvi, jtg):**
```
f1 {               // Root = 1 (push)
  f1: Any {        // Wrapper
    f1: "type.ankama.com/opcode"
    f2: payload
  }
}
```

## Debugging

### Logs Clave

```
[GameClient] Enviando kqz (ticket=e7193a7a...)
[GameClient] Conectado a TCP
[GameManager] Mensaje TCP recibido: opcode='kra', payload_size=0
[GameManager] kvi recibido en burst — parseando lista de personajes
[CharacterSelectUI] Recibidos 4 personajes del servidor
```

### Verificación de Handshake

Para verificar que el handshake funciona correctamente:

1. **Conexión TCP establecida:**
   - Log: `[GameClient] Conectado a TCP`
   - Log: `[GameManager] GameClient conectado a TCP`

2. **Ticket enviado:**
   - Log: `[GameClient] Enviando kqz (ticket=...)`

3. **kvi recibido:**
   - Log: `[GameClient] Recibidos 307 bytes`
   - Log: `[GameManager] kvi recibido en burst`

4. **Lista de personajes parseada:**
   - Log: `[GameManager] Personaje recibido: id=..., name=..., level=..., sex=..., breed=...`

5. **jtg emitido:**
   - Log: `[GameManager] jtg recibido — burst completo (4 personajes)`
   - Log: `[CharacterSelectUI] Recibidos 4 personajes del servidor`

## Cambios Realizados

### Commit de Arreglo: decode_kvi()

**Problema:** Look (f6) y breed (f7) se estaban leyendo en el nivel equivocado.

**Error original:**
```gdscript
# INCORRECTO - buscaba fuera del bloque de traits
var look_field = first(char_fields, 6)    # f6 a nivel de personaje
var breed_field = first(char_fields, 7)  # f7 a nivel de personaje
```

**Corrección:**
```gdscript
# CORRECTO - look y breed están dentro de traits/f4
var traits_field = first(details_fields, 4)
if traits_field != null:
    var traits_fields = parse(traits_field["b"])
    
    var look_field = first(traits_fields, 6)    # f6 dentro de traits
    var breed_field = first(traits_fields, 7)  # f7 dentro de traits
```

### Commit de Arreglo: send_character_selection()

**Problema:** Se usaba `send_request()` en lugar de `send_push()`.

**Error original:**
```gdscript
# INCORRECTO - kvw no es un request
func send_character_selection(character_id: int):
    var payload = Proto.request("kvw", ...)  # Wrong!
```

**Corrección:**
```gdscript
# CORRECTO - kvw es un PUSH
func send_character_selection(character_id: int):
    var payload = Proto.push("kvw", ...)  # Correct!
```

## Referencias

- Servidor: `Jondo.Unity.Server/Network/ConnectionProtocol.cs`
- Definición kvi: Líneas 365-377
- Definición hoy: Líneas 337-346
- Handlers: `Jondo.Unity.Server/Handlers/CharacterSelectionHandler.cs`
- Tests: `Jondo.Unity.Tests/Protocol/WelcomeBurstTests.cs`