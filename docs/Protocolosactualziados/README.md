# Documentación de Protocolos de Comunicación — Cliente Godot Mono C#

Índice de toda la documentación de red para conectar el cliente Godot Mono C# al servidor DreamFus. Cada carpeta documenta un dominio de protocolo con sus mensajes, framing, opcodes y ejemplos de bytes reales.

## Carpetas de dominio de protocolo

| Carpeta | Dominio | Contenido |
|---------|---------|-----------|
| `network/` | Capa de red | WebSocket 5557 (auth), TCP 5555 (juego), framing, handshake, ticket `kqz` |
| `game-envelopes/` | Envelopes de juego | Sobre `hea`, roles event/request/response, campo `Any`, `uid`, ejemplo byte a byte del `kqz` |
| `inventory/` | Inventario | Objetos, equipamiento, uso, movimiento entre ranuras, almacenamiento |
| `combat/` | Combate | Iniciar pelea, unirse, acciones de turno, recompensas, derrota |
| `movement/` | Movimiento | Desplazamiento, carga de mapa, cambio de mapa |
| `maps/` | Mapas | Portales, zaap, teletransporte, bloque de mapa |
| `npcs/` | NPCs | Diálogo, trueque, misiones |
| `economy/` | Economía | Tiendas, compra/venta, trueque, mercado, banco, fabricación |

## Flujo de conexión del cliente Godot

```
1. WebSocket ws://127.0.0.1:5557/  →  auth_request → auth_response
2. WebSocket 5557                  →  server_selection → server_selection_response (ticket 32 hex)
3. TCP 127.0.0.1:5555             →  kqz envuelto en hea.request → vinculación de sesión
4. TCP 5555                        →  Mensajes de juego (inventario, combate, movimiento, etc.)
```

## Reglas clave para el cliente Godot Mono C#

1. **WebSocket 5557**: framing de 4 bytes big-endian + payload JSON UTF-8.
2. **TCP 5555**: Protobuf con sobre `hea` (campo 2 = request), `Any` anidado, `uid` obligatorio (int32, `-1` si sin correlación).
3. **Ticket**: 32 caracteres hexadecimales en minúsculas; de un solo uso.
4. **Un solo WebSocket por cuenta**: una nueva conexión cierra la anterior con `PolicyViolation`.
5. **Aislamiento por sesión**: cada sesión tiene su propio estado; nada se comparte globalmente entre cuentas.

## Referencias externas

- Documentación oficial de Godot 4.x (español): https://docs.godotengine.org/es/4.x/
- `Google.Protobuf` 3.35.1 para serialización Protobuf.
- `System.Net.WebSockets` para el canal 5557.
- `System.Net.Sockets.TcpClient` para el canal 5555.

## Especificaciones formales (OpenSpec)

Las especificaciones de comportamiento (contrato delta) viven en:

```
openspec/changes/documentar-todos-protocolos-godot/specs/
```

Cada dominio tiene su propio `spec.md` con requisitos y escenarios `WHEN/THEN`.
