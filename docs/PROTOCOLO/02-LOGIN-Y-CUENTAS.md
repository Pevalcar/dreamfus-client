# 02 — Login y cuentas

El flujo de autenticación tiene tres fases: HTTP → WebSocket → TCP. Cada fase usa un token intermedio que se pasa del servidor anterior al siguiente.

---

## 1. Paso 1: HTTP `/api/entrar` (HAAPI)

### 1.1 Petición

```http
POST http://127.0.0.1:8888/api/entrar
Content-Type: application/json

{
  "usuario": "keka",
  "clave": "test",
  "ip": "127.0.0.1"      // opcional, se pone localhost si falta
}
```

**Importante:** El servidor **ignora** el IP del cuerpo si no viene. No se puede pasar un IP falso. La contraseña va en `clave`, no `password`.

### 1.2 Respuesta correcta

```json
{
  "bien": true,
  "token": "a1b2c3d4e5f6... (32 caracteres hex)",
  "apodo": "keka",
  "cuenta": 188940901,
  "rol": 0
}
```

**Campos:**
- `bien`: booleano, `true` = login OK
- `token`: 32 caracteres hexadecimales, guía del flujo. El mismo token sirve para `/api/recordar-token` en la siguiente sesión.
- `apodo`: el nickname del jugador
- `cuenta`: ID numérico de la cuenta (también llamado `accountId`)
- `rol`: normalmente 0; 1 o 2 es administrador

### 1.3 Respuesta fallida

```json
{
  "bien": false,
  "motivo": "Contraseña incorrecta"
}
```

**Los posibles valores de `motivo`:**
- `"Cuenta no encontrada"`
- `"Contraseña incorrecta"` 
- `"Cuenta bloqueada"` (por intentos fallidos)
- `"Error de red"` (problema interno)

**Nota:** El campo se llama `motivo`, no `error`. El cliente debe leer exactamente este nombre.

### 1.4 Código del servidor

En `Network/ControlApi.cs:581-609` (`Entrar`):
- Valida credenciales con `DatabaseManager.ValidateAccountCredentials`
- Genera token con `Guid.NewGuid().ToString("N")`
- Registra token en `ClientLaunchRegistry.RegisterToken(accountId, token)`

---

## 2. Paso 2: WebSocket `/auth_request` y `/server_selection` (puerto 5557)

### 2.1 Conexión WebSocket

```
ws://127.0.0.1:5557
```

Formato: **mensajes binarios** con prefijo de 4 bytes big-endian + JSON UTF-8. Ver `01-TRANSPORTE.md` §1.1.

### 2.2 Mensaje `auth_request` (cliente → servidor)

```json
{
  "type": "auth_request",
  "token": "a1b2c3d4e5f6...",
  "installId": "ID_UNICA_DEL_DISPOSITIVO",
  "lang": "es",
  "version": "3.6.10.10"   // recomendado, aunque opcional
}
```

**Campos obligatorios:**
- `type`: string literal `"auth_request"`
- `token`: el token de `/api/entrar`
- `installId`: identificador único del dispositivo (obtener con `OS.get_unique_id()` o similar)

**Campos opcionales:**
- `lang`: código de idioma, `"es"`, `"en"`, `"en_US"`, etc.
- `version`: versión del cliente, `"3.6.10.10"`. El servidor no la exige, pero enviarla evita problemas si hay validaciones de versión.

### 2.3 Respuesta `auth_response` (servidor → cliente)

**Éxito:**
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

**Error:**
```json
{
  "type": "error",
  "code": "INVALID_CREDENTIALS",
  "message": "Token not found or expired"
}
```

**Posibles códigos de error:**
- `UNKNOWN_TYPE`: opcode desconocido
- `INVALID_CREDENTIALS`: token vacío, malo o expirado
- `UNAUTHORIZED`: `account_id` no coincide con la sesión

### 2.4 Mensaje `server_selection_request` (cliente → servidor)

```json
{
  "type": "server_selection",
  "server_id": 290,
  "account_id": 188940901,
  "lang": "es"
}
```

**Regla crítica:** `account_id` **debe coincidir** con el de `auth_response`. El servidor verifica esto y rechaza si no coincide.

### 2.5 Respuesta `server_selection_response` (servidor → cliente)

**Éxito:**
```json
{
  "type": "server_selection_response",
  "success": true,
  "ticket": "32_caracteres_hex...",
  "host": "127.0.0.1",
  "ports": [5555, 5555]   // [puerto_conexion, puerto_partida]
}
```

**Error:**
```json
{
  "type": "error", 
  "code": "SERVER_NOT_AVAILABLE",
  "message": "Server not available"
}
```

**Importante:** El servidor **cierra el WebSocket** aproximadamente 100 ms después de enviar `server_selection_response`. Esto es normal: es el handoff al TCP.

### 2.6 El ticket y el registro

El ticket es un valor de 32 caracteres hexadecimales emitido por `SessionRegistry.Issue()`. Este ticket:
- Se presenta en el TCP 5555 para entrar al mundo
- Vence temporalmente (no hay expiración explícita en el código, pero el ticket es único por sesión)
- No se puede usar dos veces: el segundo intento falla

**No hagas esto:** El código de referencia `src/lib.rs` tiene `connect_game` que envía `{"ticket":"..."}` por TCP 5555 sin el envelope protobuf. Eso es incorrecto. El ticket va dentro de un mensaje `kqz`.

---

## 3. Paso 3: TCP 5555 — Presentar el ticket

Ver `04-MUNDO-MAPAS-MOVIMIENTO.md` §3 para el flujo completo del TCP. En resumen:

```
kqz {f2: ticket} + krt  →  ráfaga de bienvenida (kvc, krv, kvi, kvd)
                                →  kvw (personaje) + lqc
                                →  jru (mapa 191105026)
```

---

## 4. Registro de sesión y "kick"

- **Un solo cliente por cuenta:** Si un jugador intenta conectarse desde otro dispositivo, el anterior es expulsado.
- **Token único:** Cada login genera un token nuevo. El anterior se invalida.
- **No persistir tokens:** El token es efímero. Para recordar sesión, usar `/api/recordar-token`.

---

## 5. Crear cuenta (opcional)

```http
POST http://127.0.0.1:8888/api/crear-cuenta
Content-Type: application/json

{
  "usuario": "nuevo_usuario",
  "clave": "mi_contraseña", 
  "apodo": "ApodoDelJugador"
}
```

Respuesta:
```json
{
  "bien": true,        // o false si falla
  "motivo": ""         // vacío si éxito, motivo si falla
}
```

**Motivos posibles:**
- Vacío = cuenta creada
- `"Nombre de usuario ya existe"` = nombre de usuario tomado
- `"Contraseña demasiado corta"` = menos de 6 caracteres
- `"Nombre de personaje no válido"` = apodo rechazado

---

## 6. Nodo necesario para el launcher

El programador debe crear en `Launcher.tscn` un nodo `HTTPRequest` como hijo directo de `Launcher` y añadir estos campos en `VBoxContainer` entre `ConnectionProgress` y `ConnectButton`:

```
Launcher (Control, script: LauncherUI.gd)
├── HTTPRequest (HTTPRequest)
├── VBoxContainer (VBoxContainer)
    ├── ... (nodes existentes)
    ├── UsernameLabel (Label, text="Usuario:")        ← nuevo
    ├── UsernameEntry (LineEdit, placeholder="Usuario") ← nuevo
    ├── PasswordLabel (Label, text="Contraseña:")     ← nuevo  
    ├── PasswordEntry (LineEdit, secret=true, placeholder="Contraseña") ← nuevo
    ├── ... (otros nodes)
```

**Ruta que usará el script:** `$VBoxContainer/UsernameEntry`, `$VBoxContainer/PasswordEntry`

---

## 7. Errores conocidos del cliente actual

1. `send_auth_request` omite `version` → añadir
2. `auth_response_received` declara `servers_json: Dictionary` pero el servidor envía un Array
3. El error de `lang_option.select(1)` con lista vacía → añadir items al OptionButton
4. La señal emite `lang: int` pero `LauncherUI.gd:72` declara `lang: String`