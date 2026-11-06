# Protocolo Simple de DreamFus

## Visión General

El protocolo Simple es un sistema de comunicación WebSocket que permite al cliente:
1. Autenticación de usuarios
2. Selección de servidores
3. Comunicación con el servidor de juego

## Puertos

| Puerto | Uso | Protocolo |
|--------|-----|-----------|
| 5557 | Simple Protocol (JSON) | WebSocket |
| 5555 | GameNodeProxy (protobuf) | TCP |

## Formato de Mensajes

Los mensajes usan un prefijo de longitud de 4 bytes (big-endian) seguido del payload JSON.

```
[4 bytes length][N bytes JSON]
```

### Ejemplo de frame:
```
0x00 0x00 0x00 0x1A {"type":"ping"}
```

## Mensajes del Cliente

### auth_request

Solicita autenticación al servidor.

```json
{
  "type": "auth_request",
  "lang": "es",
  "token": "string",
  "installId": "string",
  "version": "3.6.10.10",
  "ticketId": "string"
}
```

### ping

Verifica conectividad.

```json
{
  "type": "ping"
}
```

### server_selection

Selecciona un servidor para conectarse.

```json
{
  "type": "server_selection",
  "lang": "es",
  "server_id": 290,
  "account_id": 188940901
}
```

## Mensajes del Servidor

### auth_response

Respuesta de autenticación.

```json
{
  "type": "auth_response",
  "success": true,
  "account_id": 188940901,
  "servers": [
    {
      "id": 290,
      "name": "DreamFus",
      "population": 0,
      "is_full": false
    }
  ]
}
```

### server_selection_response

Respuesta con detalles de conexión al servidor de juego.

```json
{
  "type": "server_selection_response",
  "success": true,
  "ticket": "32-char-hex-string",
  "host": "127.0.0.1",
  "ports": [5555, 5555]
}
```

### error

Mensaje de error.

```json
{
  "type": "error",
  "code": "INVALID_CREDENTIALS",
  "message": "Token not found or expired"
}
```

## Tipos de Errores Comunes

| Código | Mensaje | Descripción |
|--------|---------|-------------|
| INVALID_CREDENTIALS | Token and InstallId required | Credenciales incompletas |
| SERVICE_UNAVAILABLE | Auth handler not registered | Handler no registrado |
| INVALID_FORMAT | Missing 'type' field | Formato de mensaje inválido |
| UNKNOWN_TYPE | Unknown message type: X | Tipo de mensaje desconocido |
| RATE_LIMITED | Too many requests | Límite de rate excedido |
| FRAME_TOO_LARGE | Max 1MB | Payload demasiado grande |

## Flujo de Autenticación

```
Cliente → Servidor: auth_request
Servidor → Cliente: auth_response (success/error)
```

## Flujo de Selección de Servidor

```
Cliente → Servidor: server_selection
Servidor → Cliente: server_selection_response (ticket, host, ports)
Cliente: Conectar al GameNodeProxy en host:ports[0]
```

## Handshake TCP (Puerto 5555) - Protocolo Protobuf

Después de la autenticación WebSocket exitosa y la selección del servidor, el cliente establece conexión TCP con el GameNodeProxy. Este es el flujo de handshake y recepción de la lista de personajes:

### Flujo de Mensaje

```
Cliente → Servidor: kqz (ticket)
Servidor → Cliente: kra (acknowledgment, empty)
Servidor → Cliente: Lote de mensajes del "welcome burst":
  - kqp (3 veces, heartbeat markers)
  - lqu (clock sync request)
  - hoy (server greeting)
  - kqu (server heartbeat)
  - mgq/mgt/hpd (server state queries)
  - krs (ready state)
  - mgz (mailbox size)
  - kqp (additional heartbeat)
  - kvi (character list - 307 bytes, 4 personajes)
  - jtg (end of welcome burst)
  ↓
Cliente → Servidor: kvw (character selection, triggered by jtg)
```

**Implementación:** El kvw se envía automáticamente cuando el jugador selecciona un personaje desde `CharacterSelectUI`. El flujo completo:

1. `jtg` recibido → `GameManager` emite `characters_received`
2. UI muestra 4 personajes
3. Usuario hace click en botón → `_on_character_button_pressed()`
4. `GameManager.select_character()` → envía `kvw`
5. Cliente cambia a estado `IN_GAME`

### Opcode Reference

| Opcode | Dirección | Tipo | Descripción |
|--------|-----------|------|-------------|
| kqz | C→S | Request | Presenta el ticket de autenticación |
| kra | S→C | Push | Acknowledgment del ticket (payload vacío) |
| kqp | S→C | Push | Heartbeat marker (señal de reloj) |
| lqu | S→C | Push | Solicitud de sincronización de reloj |
| hoy | S→C | Push | Saludo del servidor - contains subscription/features |
| kqu | S→C | Push | Heartbeat del servidor |
| mgq | S→C | Push | Pregunta de estado del servidor |
| mgt | S→C | Push | Pregunta de tipo de servidor |
| hpd | S→C | Push | Pregunta de datos del juego |
| krs | S→C | Push | Estado ready |
| mgz | S→C | Push | Tamaño del buzón |
| kvi | S→C | Push | Lista de personajes del jugador |
| jtg | S→C | Push | Fin del welcome burst (trigger: UI char select) |
| kqy | S→C | Push | Unknown/sometimes appears |
| kvw | C→S | Push | Selección de personaje (enviar después de jtg) |

### Formato de Mensaje kqz (Ticket)

El cliente envía el ticket para autenticarse con el servidor de juego:

**Estructura protobuf:**
```
f2 { Any {
  f1: "type.ankama.com/kqz"
  f2: { f2: ticket, f3: language }
}
```

**Implementación en Godot:**
- Usa `GameClient.send_ticket(ticket, language)`
- Lenguaje opcional (por defecto "es")

### Formato de Mensaje kvi (Character List)

El servidor envía la lista de personajes en formato protobuf. El parsing es complejo debido a la anidación de campos.

**Estructura protobuf (verificado contra ConnectionProtocol.cs):**
```
kvi {
  f1 (repeated) {          // Un mensaje por personaje
    f1 {                  // Detalles del personaje
      f2: name (string)
      f3: level (int32)
      f4 {                // bloque de traits
        f2: { f3: sex }   // contenedor de sexo (presente vacío cuando sex=0)
        f6: look (bytes) // datos de apariencia
        f7: breed (int32) // raza del personaje
      }
    }
    f2: characterId (int64)
  }
}
```

**Importante:**
- Look (f6) y Breed (f7) están **dentro del bloque de traits (f4)**, no a nivel principal del personaje
- El sexo (f2.f3) también está dentro de f4
- El contenedor de sexo (f4.f2) es presente pero vacío cuando sex=0
- El `kvi` es un mensaje PUSH (root f1), no un request

### Formato de Mensaje kvw (Character Selection)

El cliente envía la selección del personaje después de recibir el burst completo:

**Estructura protobuf:**
```
kvw {
  f1: character_id (int64)
}
```

**Implementación en Godot:**
```gdscript
# Usa send_push porque kvw es un formato PUSH
GameClient.send_character_selection(character_id)
```

### Señal characters_received

La UI recibe la lista de personajes mediante una señal:

```gdscript
# En CharacterSelectUI.gd
signal characters_received(characters: Array)

# El GameManager emite:
characters_received.emit(_characters_list)  # después de jtg

# Los personajes son objetos CharacterData con:
# - id: int
# - name: String  
# - level: int
# - sex: int
# - breed: int
# - look: PackedByteArray
```

### Señal jtg como trigger

El mensaje `jtg` (end of welcome burst) es el trigger que indica que la lista está completa:

```gdscript
# En GameManager.gd
match opcode:
  "jtg":
    _in_welcome_burst = false
    characters_received.emit(_characters_list)
    _characters_list.clear()
```

## Formato de Mensajes TCP (Protobuf con VarInt)

### Prefijo de longitud

Todos los mensajes TCP usan un prefijo de 4 bytes big-endian indicando el tamaño del payload:

```
[VarInt size][protobuf message]
```

### Helper methods en Proto.gd

| Método | Uso |
|--------|-----|
| `Proto.write_varint(buf, value)` | Escribe un VarInt al final del buffer |
| `Proto.read_varint(buf, offset)` | Lee un VarInt desde un offset |
| `Proto.parse(buf)` | Parsea un mensaje protobuf en array de campos |
| `Proto.decode(frame)` | Decodifica un frame completo a dictionary |
| `Proto.push(opcode, payload)` | Construye un mensaje PUSH (root f1) |
| `Proto.request(opcode, payload)` | Construye un mensaje REQUEST (root f2) |

## Implementación en Godot 4.8

### GameClient.gd

El cliente TCP está implementado en `src/Network/GameClient.gd` con las siguientes características clave:

1. **Poll-based reading** (línea 27-59): Por la incompatibilidad de señales en Godot 4.8 beta2, se usa `_process()` con `get_available_bytes()` para leer datos.

2. **Framing**: Cada frame se descodifica según prefijo VarInt de longitud.

3. **Señales emitidas:**
   - `connected` - Cuando el TCP se conecta
   - `disconnected` - Cuando el TCP se desconecta
   - `message_received(opcode, payload, request_id)` - Cada frame parseado

### Límite de frames por frame

Para evitar bucles infinitos, el `_drain_buffer()` limitea a 10 frames por llamada (línea 233-235):
```gdscript
if frames_parsed > 10:
    print("[GameClient] Demasiados frames, deteniendo para evitar bucle infinito")
    break
```

## Referencias

- Código del servidor: `Jondo.Unity.Server\Network\ConnectionProtocol.cs`
- Handlers: `Jondo.Unity.Server\Handlers\CharacterSelectionHandler.cs`
- Tests: `Jondo.Unity.Tests\Protocol\WelcomeBurstTests.cs`
- Tests: `Jondo.Unity.Tests\Network\KqzProtocolTests.cs`