# Capa de Red — Protocolo para Cliente Godot Mono C#

Documenta el handshake de autenticación, el framing de paquetes y la canalización de red que el cliente Godot Mono C# debe implementar para conectarse al servidor DreamFus.

## Puertos y servicios

| Puerto | Protocolo | Uso para el cliente Godot |
|--------|-----------|---------------------------|
| 5557   | WebSocket (SimpleProtocol) | Autenticación, selección de servidor, emisión del ticket de juego |
| 5555   | TCP + Protobuf (Game Wire) | Juego: envío del ticket `kqz`, rafaga de bienvenida, mensajes de juego |
| 8888   | TCP (Zaap) | Autenticación y metadatos (no usado directamente por Godot en este flujo) |
| 6337   | TCP (Chat/TLS) | Chat de juego |
| 15881  | TCP (HAAPI) | API de control y lanzamiento |

## Formato de trama WebSocket (puerto 5557)

Cada mensaje del SimpleProtocol consiste en un prefijo de 4 bytes con la longitud del payload en big-endian, seguido del payload UTF-8 JSON.

```
[4 bytes: longitud del payload, big-endian][payload UTF-8 JSON]
```

### Tipos de mensaje JSON del SimpleProtocol

| Tipo de entrada | Tipo de respuesta | Descripción |
|-----------------|-------------------|-------------|
| `auth_request`  | `auth_response`   | Autenticación con token e installId |
| `server_selection` | `server_selection_response` | Selección de servidor y emisión de ticket |
| `ping`          | `pong`            | Heartbeat / keep-alive |
| —               | `error`           | Error del servidor (cualquier mensaje) |

### Flujo de autenticación

1. Cliente Godot abre `ws://127.0.0.1:5557/`
2. Cliente envía `auth_request` con `token`, `installId`, `lang`, `version`
3. Servidor responde `auth_response` con `success=true`, `account_id`, lista de servidores
4. Cliente envía `server_selection` con `server_id`, `account_id`
5. Servidor responde `server_selection_response` con `success=true`, `ticket` (32 hex), `host`, `ports=[5555, 5557]`
6. Cliente cierra la WebSocket y conecta por TCP al puerto 5555 presentando el ticket

### Ejemplo de intercambio (del log del servidor)

```
[SimpleProtocol] RX [session-1]: {"installId":"{33fdef81-...}","lang":"es","token":"18748c1da2914ac6b582d1fe587bb35b","type":"auth_request","version":"3.6.10.10"}
[SimpleProtocol] TX: {"type":"auth_response","success":true,"account_id":188940901,"servers":[{"id":290,"name":"DreamFus","population":0,"is_full":false}]}
[SimpleProtocol] RX [session-1]: {"account_id":188940901,"lang":"es","server_id":290,"type":"server_selection"}
[SimpleProtocol] TX: {"type":"server_selection_response","success":true,"error":"","ticket":"5557d56a0fb3ef3eea86f47e75c454c8","host":"127.0.0.1","ports":[5555,5557]}
```

## Redirección al puerto de juego (TCP 5555)

Tras recibir el ticket, el cliente Godot SHALL:
1. Cerrar la WebSocket de autenticación
2. Conectar por TCP a `127.0.0.1:5555`
3. Enviar el ticket `kqz` envuelto en el sobre `hea.request` (ver `docs/godot/game-envelopes/`)

## Reglas de comportamiento del servidor

- Un solo WebSocket por cuenta; una nueva conexión cierra la anterior con `PolicyViolation`.
- El ticket es de 32 caracteres hexadecimales en minúsculas.
- Cada sesión tiene su propio semáforo de turno y su estado aislado; nada se comparte globalmente entre cuentas.
- Al desconectar, el servidor limpia el caché de la sesión.

## Referencia para Godot Mono C#

- Usar `System.Net.WebSockets.ClientWebSocket` para el canal 5557.
- Usar `System.Net.Sockets.TcpClient` para el canal 5555.
- Serialización JSON con `System.Text.Json`.
- Serialización Protobuf con `Google.Protobuf` 3.35.1.
- Documentación oficial de Godot 4.x: https://docs.godotengine.org/es/4.x/
