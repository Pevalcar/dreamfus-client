# Sobre de Mensaje de Juego (`hea`) — Protocolo para Cliente Godot Mono C#

Documenta la estructura del sobre Protobuf `hea`, los roles event/request/response, el campo `Any`, el `uid` obligatorio, y el ejemplo byte a byte del mensaje `kqz` (presentación de ticket).

## Estructura del sobre `hea`

Cada mensaje de juego por TCP (puerto 5555) SHALL ir envuelto en el sobre Protobuf `hea` (`type.ankama.com/hea`), que contiene un oneof con tres roles:

| Campo del sobre | Rol | Significado |
|-----------------|-----|-------------|
| 1 | Evento (`hdx`) | Notificación sin correlación de request/response |
| 2 | Petición (`hdy`) | Mensaje que el cliente envía y espera respuesta |
| 3 | Respuesta (`hdw`) | Respuesta del servidor a una petición |

Cada petición (`hea.request`, campo 2) SHALL llevar un `uid` (int32 firmado, campo 2 del sobre). El valor `-1` indica que no se espera correlación.

El payload serializado del mensaje SHALL ir dentro de un `google.protobuf.Any` anidado en el sobre `hea` (campo 1 del `Any` = `type_url`, campo 2 = payload serializado), nunca en la raíz del frame.

## Jerarquía del sobre

```
hea (campo 2 = request/hdy)
  └─ 1: Any
       ├─ 1: "type.ankama.com/<opcode>"   <- type_url del Any
       └─ 2: <payload serializado>        <- campo 2 del Any: el mensaje real
  └─ 2: <uid>                            <- campo 2 del sobre: int32 firmado (-1 si sin correlación)
```

## Formato kqz CORRECTO (TCP puerto 5555) - IMPORTANTE

**⚠️ CRÍTICO:** El ticket kqz se envía como `GameMessage` DIRECTO, SIN wrapper `hea` ni `Any`.

El servidor GameNode SOLO acepta GameMessage directo para kqz (sin wrapper Any). Esto es diferente del formato WebSocket.

### Trama correcta (byte a byte) - GameMessage DIRECTO

```
Hex: 0A-3D-12-20-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-1A-02-65-73-10-2D
```

**NOTA:** El primer byte `0A` es el tag del campo 1 del GameMessage (varint 1<<3 | 2 = 10 = 0x0A), que contiene el sub-mensaje interno.

### Desglose - GameMessage DIRECTO

| Bytes | Campo | Descripción |
|-------|-------|-------------|
| `0A 3D` | Campo 1 del GameMessage | Sub-mensaje interno (61 bytes): f1 del GameMessage |
| `12 20 <ticket 32 x's>` | Campo 2 del sub-mensaje interno | TicketKey (`f2`): ticket de 32 caracteres hex |
| `1A 02 "es"` | Campo 3 del sub-mensaje interno | LanguageCode (`f3`): código de idioma |

### Trama defectuosa (cliente Godot actual — NO usar)

```
Hex: 0A-3D-0A-13-74-79-70-65-2E-61-6E-6B-61-6D-61-2E-63-6F-6D-2F-6B-71-7A-12-26-12-20-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-1A-02-65-73
```

Este ejemplo envía el wrapper `Any` con `type_url = "type.ankama.com/kqz"`. El servidor lo rechaza como:
```
UNHANDLED CLIENT PACKET DETECTED: type.ankama.com/kqz
```

## Formato kqz WebSocket (puerto 5557) - SOLO PARA REFERENCIA

El formato con `hea.request` y wrapper `Any` es CORRECTO SOLO para el WebSocket, NO para TCP:

### Trama WebSocket (byte a byte)

```
Hex: 12-3D-0A-13-74-79-70-65-2E-61-6E-6B-61-6D-61-2E-63-6F-6D-2F-6B-71-7A-12-26-12-20-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-1A-02-65-73-10-2D
```

## Reglas de codificación/decodificación para Godot Mono C#

### Para Ticket kqz (TCP puerto 5555)

1. **NO usar `hea.request`**: El ticket kqz se envía como GameMessage DIRECTO, sin wrapper `hea` ni `Any`.
2. **NO incluir `uid`**: No se usa el sobre `hea` para kqz.
3. **NO usar `type_url`**: El opcode va en el campo `f1` del GameMessage, no como `type_url`.
4. **Ticket en minúsculas**: El ticket de 32 caracteres hex debe ir en minúsculas.
5. **Formato de GameMessage**: `GameMessage { f1 { f2: ticket, f3: language } }`

### Para otros mensajes

1. **Envolver en `hea.request`**: Nunca enviar el `Any` suelto en la raíz del frame.
2. **Incluir `uid`**: Siempre int32 firmado; usar `-1` si no se espera correlación.
3. **`type_url` correcto**: El campo 1 del `Any` debe ser `type.ankama.com/<opcode>`.
4. **Ticket en minúsculas**: El ticket de 32 caracteres hex debe ir en minúsculas.
5. **Payload en campo 2 del Any**: El campo 1 es el `type_url`, el campo 2 es el payload serializado.

## Referencia para Godot Mono C#

- Usar `Google.Protobuf` 3.35.1 para serialización/deserialización.
- Usar `System.Net.Sockets.TcpClient` para el canal 5555.
- Documentación oficial de Godot 4.x: https://docs.godotengine.org/es/4.x/