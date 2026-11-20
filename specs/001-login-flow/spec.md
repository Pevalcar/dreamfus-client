# Spec 001 — Flujo de Login (Walking Skeleton)

## Contexto y objetivo

**Propósito:** Permitir que un jugador se conecte al servidor DreamFus desde el cliente Godot 4.8 + GDScript pura y acceda al juego mediante el flujo de login completo: HTTP → WebSocket → TCP → Welcome Burst.

**Historia de referencia:**  
H1 — As a jugador, I want iniciar sesión y conectarme al servidor, so that puedo acceder al juego desde el cliente. *(Walking Skeleton)*

---

## Usuarios / actores

- **Jugador:** Conoce sus credenciales de prueba (`keka` / `test`), quiere iniciar sesión y jugar.
- **Servidor DreamFus:** Emulador que expone los endpoints de login (HTTP) y protocolo de juego (WebSocket/TCP).
- **GameManager:** Orquestador del cliente que coordina el flujo de autenticación.

---

## Historias de usuario

| ID | Historia |
|----|------------|
| **H1** | Como jugador, quiero iniciar sesión y conectarme al servidor, para acceder al juego desde el cliente. |
| **H2** | Como jugador, quiero ver mi lista de personajes y seleccionar uno, para jugar con mi avatare. |
| **H3** | Como jugador, quiero entrar al mapa con mi personaje visible y ver otros jugadores, para interactuar con el mundo. |

---

## Contratos de frontera (Dominio)

### Entradas y validaciones

**Login HTTP (puerto 8888):**
- Endpoint: `POST http://127.0.0.1:8888/api/entrar`
- Payload JSON: `{ "usuario": string, "clave": string, "ip": string }`
- `usuario`: alfanumérico, 1-50 caracteres
- `clave`: cualquier cadena
- `ip`: dirección IP del cliente (se usa `127.0.0.1` si está vacío)

**WebSocket Auth (puerto 5557):**
- Conexión: `ws://127.0.0.1:5557`
- `auth_request`: `{ "type": "auth_request", "token": string, "installId": string, "lang": string, "version": string }`
- `token`: string de autenticación (variable)
- `installId`: UUID del cliente, formato `{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}`
- `lang`: código de idioma ISO 639-1, `es` o `en`
- `version`: versión del cliente

**TCP Ticket kqz (puerto 5555):**
- Formato GameMessage directo (sin wrapper Any)
- Estructura: `f1 { f2: ticket, f3: language }`
- `ticket`: string de 32 caracteres hexadecimales minúsculas, válido según regex `^[0-9a-f]{32}$`
- `language`: código ISO 639-1, ejemplo: "es"

### Salidas y efectos observables

**Respuesta HTTP login:**
```json
{ "bien": boolean, "token": string, "apodo": string, "cuenta": long }
```

**Respuesta WebSocket auth:**
```json
{ "type": "auth_response", "success": boolean, "account_id": long, "servers": [...] }
```

**Respuesta WebSocket server_selection:**
```json
{ "type": "server_selection_response", "success": boolean, "ticket": string, "host": "127.0.0.1", "ports": [5555, 5557] }
```

**Welcome Burst (TCP):**
- Mensaje kra: Ack del ticket kqz
- Mensaje kvi: Lista de personajes
- Mensaje jtg: Fin del burst, transición a juego

### Invariantes (reglas inviolables)

- **I1:** El token devuelto por HTTP es el mismo que se envía en WebSocket `auth_request`
- **I2:** El `account_id` en WebSocket coincide con `cuenta` en respuesta HTTP
- **I3:** El ticket es siempre de 32 caracteres hexadecimales minúsculas
- **I4:** El ticket es de un solo uso; reutilizarlo devuelve error `PolicyViolation`
- **I5:** Un solo WebSocket por cuenta; una nueva conexión cierra la anterior
- **I6:** El servidor GameNode SOLO acepta GameMessage directo para kqz (sin wrapper Any)

---

## Matriz de estados y transiciones

| Estado inicial | Evento / Acción | Estado final | ¿Permitido? | Regla / RF asociado |
|----------------|-----------------|--------------|-------------|---------------------|
| `disconnected` | Click "Login" con credenciales válidas | `http_sent` | Sí | RF-1 |
| `disconnected` | Click "Login" con `usuario` vacío | `login_failed` | Sí | RF-10 |
| `disconnected` | Click "Login" con `clave` vacía | `login_failed` | Sí | RF-10 |
| `http_sent` | Respuesta HTTP con `bien=true` | `ws_connected` | Sí | RF-2 |
| `http_sent` | Respuesta HTTP con `bien=false` | `login_failed` | Sí | RF-2 |
| `ws_connected` | Enviar `auth_request` válido | `auth_sent` | Sí | RF-4 |
| `ws_connected` | Enviar `auth_request` con token inválido | `auth_failed` | Sí | RF-9 |
| `auth_sent` | Recibir `auth_response` con `success=true` | `server_selection_sent` | Sí | RF-5 |
| `auth_sent` | Recibir `auth_response` con `success=false` | `auth_failed` | Sí | RF-9 |
| `server_selection_sent` | Recibir `server_selection_response` | `tcp_ticket_ready` | Sí | RF-6 |
| `server_selection_sent` | Recibir `server_selection_response` con `success=false` | `server_selection_failed` | Sí | RF-5 |
| `tcp_ticket_ready` | Conectar a TCP 5555 y enviar ticket | `in_game` | Sí | RF-7 |
| `tcp_ticket_ready` | Ticket expirado/usado | `tcp_error` | Sí | RF-6 (error) |
| `tcp_ticket_ready` | Timeout de conexión TCP (5s) | `tcp_error` | Sí | RNF-7 |
| `ws_connected` | Socket se cierra sin auth_response | `disconnected` | Sí | RF-7 |
| `in_game` | Socket TCP se cierra inesperadamente | `disconnected` | Sí | RF-7 |

---

## Requisitos funcionales (criterios de aceptación en EARS)

### RF-1 — Login HTTP exitoso [H1]
**CUANDO** el jugador envía sus credenciales válidas al endpoint `/api/entrar`, **EL SISTEMA** devuelve una respuesta JSON con `bien: true`, `token`, `apodo` y `cuenta` observables.

### RF-2 — Login HTTP fallido (credenciales incorrectas) [H1]
**SI** las credenciales son incorrectas, **ENTONCES EL SISTEMA** devuelve `{"bien": false, "motivo": string}` donde `motivo` toma uno de estos valores exactos:
- `"CREDENCIALES_INVALIDAS"` — usuario o contraseña incorrectos
- `"CUENTA_BLOQUEADA"` — cuenta suspendida o prohibida
- `"USUARIO_VACIO"` — campo `usuario` vacío o nulo
- `"CLAVE_VACIA"` — campo `clave` vacío o nulo
- `"CUENTA_NO_EXISTE"` — cuenta no registrada

### RF-3 — Conexión WebSocket aceptada [H1]
**CUANDO** el cliente abre `ws://127.0.0.1:5557`, **EL SISTEMA** acepta la conexión y espera el primer mensaje.

### RF-4 — Auth Request Format [H1]
**SI** el cliente envía `auth_request` con token válido, `installId` válido, `lang` y `version`, **ENTONCES EL SISTEMA** responde `auth_response` con `success: true`, `account_id` y `servers` con esta estructura:
```json
{
  "type": "auth_response",
  "success": true,
  "account_id": 12345,
  "servers": [
    {
      "id": 290,
      "name": "Servidor 1",
      "population": 42,
      "is_full": false
    }
  ]
}
```
Donde cada servidor tiene:
- `id`: integer, identificador único del servidor
- `name`: string, nombre visible del servidor
- `population": integer, cantidad de jugadores conectados
- `is_full`: boolean, `true` si el servidor está lleno (máximo 200 jugadores)

### RF-5 — Server Selection Request Format [H1]
**SI** el cliente envía `server_selection` con un `server_id` válido, **ENTONCES EL SISTEMA** responde `server_selection_response` con `ticket` de 32 caracteres hexadecimales.  
**SI** el `server_id` es inválido o el servidor está lleno (`is_full: true`), **ENTONCES EL SISTEMA** responde `server_selection_response` con `success: false` y `error` string con uno de estos valores:
- `"SERVIDOR_NO_EXISTE"` — server_id no encontrado
- `"SERVIDOR_LLENO"` — server está lleno (≥200 jugadores)
- `"CUENTA_NO_AUTORIZADA"` — cuenta no tiene permiso para este servidor

### RF-6 — Ticket kqz TCP Format [H1]
**CUANDO** el cliente envía el ticket kqz a TCP 5555, **EL CLIENTE** construye y envía un `GameMessage` con el opcode `kqz` directamente, sin wrapper `Any`, permitiendo que el servidor GameNode procese el ticket.

### RF-6.1 — Formato del ticket [H1]
**CUANDO** el cliente envía el ticket kqz por TCP 5555, **EL CLIENTE** construye el GameMessage con:
- Campo 1 (f1): contiene el mensaje interno
- Campo 2 (f2): ticket de 32 caracteres hexadecimales minúsculas
- Campo 3 (f3): código de idioma ISO 639-1

### RF-6.2 — Validación y normalización del ticket [H1]
**CUANDO** el cliente recibe el ticket, **EL CLIENTE** valida que cumpla el patrón `^[0-9a-f]{32}$` y normaliza a minúsculas antes de enviarlo.

### RF-6.3 — Envío inmediato del ticket [H1]
**CUANDO** la conexión TCP se establece, **EL CLIENTE** envía el ticket kqz en el mismo frame sin esperar datos del servidor.

### RF-7 — Mensaje de error cuando el servidor está caído [H1]
**CUANDO** el cliente no recibe respuesta WebSocket en 2 segundos o el socket se cierra inesperadamente, **EL CLIENTE** mostrará un popup con mensaje "Servidor sin responder".

### RF-8 — Welcome Burst processing [H1]
**CUANDO** el servidor envía el welcome burst (kra → kvi → jtg), **EL CLIENTE** procesa los mensajes en orden y transiciona al estado `in_game` al recibir `jtg`.

### RF-9 — Rechazo de conexión inválida [H1]
**SI** el token proporcionado en `auth_request` es inválido, expirado o no registrado, **ENTONCES EL SISTEMA** responde `auth_response` con `success: false` y un `error` string descriptivo, y cierra la conexión WebSocket.

### RF-10 — Validación de credenciales de entrada [H1]
**SI** el campo `usuario` está vacío, nulo o supera los 50 caracteres, **ENTONCES EL SISTEMA** devuelve `{"bien": false, "motivo": "USUARIO_VACIO"}` sin contactar al servidor de autenticación.  
**SI** el campo `clave` está vacío o nulo, **ENTONCES EL SISTEMA** devuelve `{"bien": false, "motivo": "CLAVE_VACIA"}` sin contactar al servidor de autenticación.  
**SI** el campo `ip` está vacío, **ENTONCES EL SISTEMA** usa `127.0.0.1` como valor por defecto.

---

## Requisitos no funcionales (RNF)

- **RNF-1:** El flujo completo (login → mapa) debe completarse en menos de 5 segundos en condiciones normales (red local).
- **RNF-2:** Todos los endpoints usan JSON con encoding UTF-8.
- **RNF-3:** Las credenciales nunca se almacenan en texto plano en logs del cliente.
- **RNF-4:** El ticket de 32 caracteres hexadecimales debe validarse con regex `^[0-9a-f]{32}$` en el cliente antes de usarlo.
- **RNF-5:** Heartbeat `kqo`/`kqy` se envía cada 5 segundos; el cliente considera el servidor caído si no recibe respuesta en 2 segundos.
- **RNF-6:** El envío del ticket kqz debe completarse en menos de 100ms después de conexión TCP.
- **RNF-7:** Timeout de conexión WebSocket: 2 segundos para recibir respuesta de `auth_request`. Si se excede, se muestra popup "Servidor sin responder".
- **RNF-8:** Timeout de conexión TCP: 5 segundos para establecer conexión. Si se excede, se muestra popup "Servidor sin responder".
- **RNF-9:** Rate limiting: 10 intentos fallidos de login en 60 segundos devuelven HTTP 429.

---

## Casos límite

| Caso | Entrada | Comportamiento esperado | RF |
|------|---------|--------------------------|-----|
| Conexión rechazada | WebSocket abierto | Popup "Servidor sin responder" | RF-7 |
| Token inválido | `auth_request` con token no registrado | Respuesta `success: false` | RF-9 |
| Servidor lleno | `server_selection` a servidor con `is_full: true` | Respuesta `success: false` con error "SERVIDOR_LLENO" | RF-5 |
| Ticket expirado/usado | Conexión TCP con ticket ya redimido | Error `PolicyViolation`, cerrar conexión | RF-6 |
| Múltiples intentos de login | 10 intentos fallidos en 1 minuto | Rate limiting, respuesta HTTP 429 | RNF-9 |
| Ticket inválido | Ticket que no pasa regex `^[0-9a-f]{32}$` | Error en envío kqz, `error_occurred` emitido | RF-6.2 |
| Credenciales vacías | `usuario` o `clave` vacíos | Respuesta `{"bien": false, "motivo": "USUARIO_VACIO"}` o `"CLAVE_VACIA"` | RF-10 |
| Timeout WebSocket | Sin respuesta en 2 segundos | Popup "Servidor sin responder" | RF-7 |
| Timeout TCP | Sin conexión en 5 segundos | Popup "Servidor sin responder" | RF-7 |

---

## Fuera de alcance

- Registro de cuentas (gestión por el launcher)
- Recuperación de contraseña
- Autenticación OAuth
- Almacenamiento persistente de tokens en el cliente
- Sistema de amigos o chat
- Sistema de inventario
- Gráficos 3D avanzados (solo sprite 2D)

---

## Criterios de finalización

- [x] Flujo login → server_selection → TCP ticket testeado exitosamente
- [x] Manejo de errores con popup visible implementado
- [x] Tests GUT unitarios pasan para: HTTP login format, WebSocket auth format, ticket generation/validación, formato kqz correcto
- [x] Implementación `send_ticket()` usa GameMessage directo (sin wrapper Any)
- [x] Documentación de protocolos actualizada

---

## Dudas abiertas

Ninguna