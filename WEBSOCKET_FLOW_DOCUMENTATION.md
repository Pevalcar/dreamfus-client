# WebSocket Flow Documentation - DreamFus Godot Client

## Visión General

Esta documentación describe el flujo de conexión completo para el cliente Godot que utiliza WebSocket para autenticación y selección de servidor, seguido de TCP para el juego.

**Flujo Principal:**
```
HTTP POST /api/entrar → WebSocket (5557) → auth_request → auth_response → 
server_selection → server_selection_response (ticket) → TCP (5555) → send_ticket(kqz) → kvi (personajes)
```

---

## 1. Autenticación Inicial (HTTP POST)

### Endpoint
```
POST http://host:8888/api/entrar
Content-Type: application/json

{
  "usuario": "nombre_usuario",
  "clave": "contraseña_hash"
}
```

### Respuesta
```json
{
  "bien": true,
  "token": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
  "cuenta": 12345,
  "apodo": "keka",
  "rol": 0
}
```

---

## 2. Flujo WebSocket (Puerto 5557)

### Conexión
```
ws://host:5557
```

### Mensaje de autenticación (auth_request)
```json
{
  "type": "auth_request",
  "token": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
  "installId": "uuid-del-cliente",
  "lang": "es",
  "version": "3.6.10.10"
}
```

### Respuesta de autenticación (auth_response)
```json
{
  "type": "auth_response",
  "success": true,
  "account_id": 12345,
  "nick_name": "keka",
  "has_vip_rights": false,
  "community_address": "290",
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

### Mensaje de selección de servidor (server_selection)
```json
{
  "type": "server_selection",
  "account_id": 12345,
  "server_id": 290,
  "lang": "es"
}
```

### Respuesta con ticket (server_selection_response)
```json
{
  "type": "server_selection_response",
  "success": true,
  "ticket": "a1b2c3d4e5f6678901234567890abcdef",
  "host": "127.0.0.1",
  "ports": [5555, 5555]
}
```

---

## 3. Conexión TCP (Puerto 5555)

### Formato del mensaje kqz (Presentación del ticket)

**Estructura protobuf:**
```
f2 { Any {
  f1: "type.ankama.com/kqz"
  f2: { f2: ticket, f3: language }
} }
```

### Implementación en Godot (GameClient.gd)
```gdscript
func send_ticket(ticket: String, language: String = "es") -> void:
    var kqz_inner: PackedByteArray = PackedByteArray()
    Proto.put_string(kqz_inner, 2, ticket)
    if language != "":
        Proto.put_string(kqz_inner, 3, language)
    
    var any_msg: PackedByteArray = PackedByteArray()
    Proto.put_string(any_msg, 1, "type.ankama.com/kqz")
    Proto.put_message(any_msg, 2, kqz_inner)
    
    send_request("kqz", any_msg)
```

---

## 4. Servidor-Side Architecture

### Servidor WebSocket
**Archivo:** `Jondo.Unity.Server/Custom/Core/SimpleProtocolHandler.cs`

- Lista en puerto 5557
- Maneja mensajes con prefijo de longitud de 4 bytes big-endian
- Dispacha tipos: `auth_request`, `server_selection`, `ping`

### Handlers de autenticación
**Archivo:** `Jondo.Unity.Server/Custom/SimpleProtocol/AuthHandlers.cs`

- `OnAuthRequestAsync`: Resuelve token a account_id, devuelve lista de servidores
- `OnServerSelectionAsync`: Genera ticket vía `SessionRegistry.Issue()`

### Registro de tickets
**Archivo:** `Jondo.Unity.Server/Network/SessionRegistry.cs`

- `Issue(accountId, serverId, language)`: Genera ticket de 32 caracteres hex
- `Redeem(value)`: Canjea el ticket para obtener la sesión
- Ticket es de un solo uso con expiración de 5 minutos

---

## 5. Credenciales de Prueba

- Usuario: `keka`
- Contraseña: `test`
- ID de cuenta: `188940901`
- Servidor: `290` (DreamFus)

---

## 6. Implementación en Godot

### SimpleProtocolClient.gd
- `send_auth_request(lang, token, install_id)` - Envía auth_request
- `send_server_selection(server_id, account_id, lang)` - Envía server_selection

### GameClient.gd
- `send_ticket(ticket, language)` - Envía el ticket kqz vía TCP

### GameManager.gd
- `attempt_login_ws(lang, token, install_id)` - Inicia flujo WebSocket
- `auto_select_first_server()` - Selecciona automáticamente el primer servidor
- `handle_server_selection(ticket, host, ports)` - Procesa ticket y conecta TCP
- Señal `characters_received` - Notifica cuando se reciben los personajes

### Main.gd
- `_on_ws_connected` - Manejador de conexión WebSocket
- `_on_ws_auth_response` - Procesa auth_response
- `_on_ws_server_selection_response` - Procesa ticket y llama a TCP
- `_on_ws_error` - Manejador de errores WebSocket