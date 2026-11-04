# 09 — Checklist del cliente Godot

Estado actual del cliente Godot de DreamFus y plan para implementarlo.

---

## 1. Estado actual

| Módulo | Estado | Notas |
|--------|--------|-------|
| Login HTTP `/api/entrar` | ❌ NO IMPLEMENTADO | No hay `HTTPRequest` en escena ni código que lo llame |
| WebSocket login (5557) | ⚠️ PARCIAL | `SimpleProtocolClient.gd` tiene la infraestructura pero con bugs |
| Selección de servidor | ❌ NO IMPLEMENTADO | No se envía `server_selection_request` |
| TCP 5555 (partida) | ❌ NO EXISTE | No hay cliente TCP en el código actual |
| Lista de personajes (`kvi`) | ❌ NO IMPLEMENTADO | No hay escena de selección |
| Movimiento (`jrw`) | ❌ NO IMPLEMENTADO | No hay sistema de mapa |
| Combate | ❌ NO IMPLEMENTADO | Ver `06-COMBATE.md` |

---

## 2. Plan de implementación (orden recomendado)

### Fase 1: Login básico

**Objetivo:** Que el jugador pueda autenticarse y recibir `auth_response`.

#### 2.1.1 Añadir HTTPRequest a Launcher

**El programador debe añadir estos nodos a `Launcher.tscn`:**

```
Launcher (Control, script: LauncherUI.gd)
├── HTTPRequest (HTTPRequest)           ← nuevo, hijo directo de Launcher
└── VBoxContainer (VBoxContainer)
    ├── (existing nodes...)
    ├── UsernameLabel (Label, text="Usuario:")        ← nuevo
    ├── UsernameEntry (LineEdit, placeholder="Usuario") ← nuevo
    ├── PasswordLabel (Label, text="Contraseña:")     ← nuevo
    ├── PasswordEntry (LineEdit, secret=true, placeholder="Contraseña") ← nuevo
    ├── TokenEntry (LineEdit)              ← mover o reemplazar cuando funcione el HTTP
    └── ... (resto existente)
```

**Rutas que usará el script:**
- `$HTTPRequest` (para pedir el token)
- `$VBoxContainer/UsernameEntry` (usuario)
- `$VBoxContainer/PasswordEntry` (password)

#### 2.1.2 Modificar `LauncherUI.gd`

```gdscript
# Cambiar la señal (agregar usuario/clave):
signal auth_requested(lang: String, token: String, install_id: String, 
                      user: String, pass: String, host: String, port: int)

func _on_login_pressed() -> void:
    var user = $VBoxContainer/UsernameEntry.text
    var pass = $VBoxContainer/PasswordEntry.text
    
    if user.empty() or pass.empty():
        _show_status("Usuario y contraseña requeridos")
        return
    
    # Pedir token por HTTP
    var url = "http://%s:8888/api/entrar" % $VBoxContainer/ServerHostEntry.text
    var body = JSON.stringify({
        usuario = user,
        clave = pass,
        ip = "127.0.0.1"
    })
    
    $HTTPRequest.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _on_http_request_completed(result, response_code, headers, body) -> void:
    if response_code != 200:
        _show_status("Error de conexión: %d" % response_code)
        return
    
    var json = JSON.parse_string(body.get_string_from_utf8())
    if not json.bien:
        _show_status("Error: %s" % json.motivo)
        return
    
    # Success - emit signal with token
    emit_signal("auth_requested",
        lang_option.selected,
        json.token,
        OS.get_unique_id(),
        json.apodo,
        user,
        pass,
        $VBoxContainer/ServerHostEntry.text,
        int($VBoxContainer/ServerPortSpin.value)
    )
```

### Fase 2: Corregir WebSocket client

#### 2.2.1 Bugs identificados en `SimpleProtocolClient.gd`

| Bug | Línea | Causa | Solución |
|-----|-------|-------|----------|
| Falta campo `version` | ~linea 85 | `send_auth_request` no añade `version` | Añadir `"version": "3.6.10.10"` al JSON |
| `servers_json: Dictionary` declarado | lineas 7-12 | El servidor envía un **Array**, no un Dictionary | Cambiar a `servers_json: Array` |
| `GameManager._on_auth_response_received` llama `.get("servers")` | GameManager | `servers` es un Array | Cambiar a `.size()` o iterar directamente |

#### 2.2.2 Código correcto para `auth_request`

```gdscript
func send_auth_request(token: String, install_id: String, lang: String) -> void:
    var message = {
        "type": "auth_request",
        "token": token,
        "installId": install_id,
        "lang": lang,
        "version": "3.6.10.10"   # ← CORREGIDO: añadir versión
    }
    send_message(JSON.stringify(message))
```

#### 2.2.3 Código correcto para manejar respuesta

```gdscript
signal auth_response_received(
    success: bool,
    account_id: int,
    servers_json: Array,          # ← CORREGIDO: Array, no Dictionary
    error: String
)

func _on_auth_response_received(msg: Dictionary) -> void:
    var servers = msg.get("servers", []) as Array   # ← CORREGIDO
    emit_signal("auth_response_received",
        msg.get("success", false),
        msg.get("account_id", 0),
        servers,
        msg.get("error", "")
    )
```

### Fase 3: Server selection

#### 2.3.1 Enviar `server_selection_request`

```gdscript
func select_server(server_id: int, account_id: int, lang: String) -> void:
    var message = {
        "type": "server_selection",
        "server_id": server_id,
        "account_id": account_id,
        "lang": lang
    }
    send_message(JSON.stringify(message))
```

#### 2.3.2 Manejar `server_selection_response`

```gdscript
signal server_selection_response_received(
    success: bool,
    ticket: String,
    host: String,
    ports: Array,
    error: String
)

func _on_server_selection_response(msg: Dictionary) -> void:
    if not msg.success:
        emit_signal("server_selection_response_received", false, "", "", [], msg.error)
        return
    
    emit_signal("server_selection_response_received",
        true,
        msg.ticket,
        msg.host,
        msg.ports as Array,
        ""
    )
    
    # El servidor cierra el WebSocket ~100ms después
    # Preparar conexión TCP al host/port de msg
```

### Fase 4: TCP 5555 (Game Protocol)

#### 2.4.1 Necesidad de un cliente TCP

**Crear nuevo script `src/Network/GameClient.gd`:**

```gdscript
class_name GameClient
extends Node

signal connected
signal disconnected
signal message_received(opcode: String, payload: PackedByteArray, request_id: int)
signal error_occurred(message: String)

var tcp: StreamPeerTCP = null
var buffer: PackedByteArray = PackedByteArray()
var request_id_counter: int = 0

func connect_to_game(host: String, port: int) -> void:
    tcp = StreamPeerTCP.new()
    var err = tcp.connect_to_host(host, port)
    if err != OK:
        emit_signal("error_occurred", "TCP connect failed: %s" % Error.get_error_message(err))
        return
    
    tcp.put_data(build_kqz_packet(ticket))  # ver §2.4.2

func _process(delta: float) -> void:
    if tcp == null: return
    
    tcp.poll()
    var status = tcp.get_status()
    
    if status == StreamPeerTCP.STATUS_CONNECTED:
        var data = tcp.get_data(65536)
        if data[0] == OK and data[1].size() > 0:
            buffer.append_array(data[1])
            _drain_buffer()
    elif status == StreamPeerTCP.STATUS_ERROR:
        disconnect()

func _drain_buffer() -> void:
    while buffer.size() >= 1:
        var header = Proto.read_varint(buffer, 0)
        if header[0] == null: return  # buffer incomplete
        
        var size: int = header[0]
        var end: int = header[1]
        
        if size > 131072:  # 128 KiB limit
            printerr("Frame too large: %d bytes" % size)
            buffer.clear()
            return
        
        if buffer.size() < end + size:
            return  # wait for more data
        
        var frame = buffer.slice(end, end + size)
        buffer = buffer.slice(end + size)
        
        var msg = Proto.decode(frame)
        if not msg.is_empty():
            emit_signal("message_received", 
                msg.opcode, msg.payload, msg.id)

func build_kqz_packet(ticket: String) -> PackedByteArray:
    return Proto.push("kqz", Proto.message(2, ticket.to_utf8_buffer()))

func build_krt_packet() -> PackedByteArray:
    return Proto.push("krt", PackedByteArray())

func send_message(opcode: String, payload: PackedByteArray = PackedByteArray()) -> void:
    var body = Proto.request(opcode, payload, request_id_counter)
    request_id_counter -= 1  # typically -1 in 98.9% of requests
    
    var frame = PackedByteArray()
    Proto.write_varint(frame, body.size())
    frame.append_array(body)
    
    tcp.put_data(frame)
```

#### 2.4.2 Flujo de conexión TCP

```
Conectar a TCP 5555
↓
Enviar: kqz {f2: ticket}
Enviar: krt {}
↓
Recibir: ráfaga de bienvenida (kvc, krv, kvi, kvd)
↓
Enviar: kvw {f1: {f1: id}} o kvl {f1: id}
↓
Recibir: kva, hms, ivx, kub, etc. (bloque 1)
↓
Enviar: lqc {}
↓
Recibir: catálogos (bloque 2)
↓
Enviar: kqo {} (heartbeat cada 5s)
Recibir: kqy {f1: 1}
↓
Recibir: kmr (desconocido) → jru {f2: map_id}
↓
¡ESTÁ EN EL JUEGO!
```

### Fase 5: Escena de selección de personaje

#### 2.5.1 Crear `CharacterSelect.tscn`

```
CharacterSelect (Control, script: CharacterSelectUI.gd)
├── VBoxContainer (VBoxContainer)
    ├── TitleLabel (Label, text="Selecciona tu personaje")
    ├── CharacterList (ItemList)          ← nuevo
    ├── CreateButton (Button, text="Crear") ← nuevo
    ├── PlayButton (Button, text="Jugar") ← nuevo
    └── BackButton (Button, text="Atrás") ← nuevo
```

#### 2.5.2 Procesar `kvi` (lista de personajes)

```gdscript
func _on_kvi_received(fields: Array) -> void:
    character_list.clear()
    
    for char_data in fields:
        var name = get_field(char_data, 1, 2) as String   # f1.f2
        var level = get_field(char_data, 1, 3) as int     # f1.f3
        character_list.add_item("%s (Nv. %d)" % [name, level])
```

### Fase 6: Sistema de movimiento

#### 2.6.1 Manejar `jru` (cargar mapa)

```gdscript
func _on_jru_received(fields: Array) -> void:
    var map_id = get_field(fields, 2, 2) as int  # f2.f2
    load_map(map_id)
```

#### 2.6.2 Manejar `hjk` (posiciones de actores)

```gdscript
func _on_hjk_received(fields: Array) -> void:
    var packed_cells = Proto.packed(get_field(fields, 1, 1)["b"])
    render_actors(packed_cells)
```

#### 2.6.3 Manejar movimiento (`jrw`)

```gdscript
func send_move(cell: int, facing: int) -> void:
    var packed = (facing << 12) | cell
    send_message("jrw", Proto.message(1, 
        Proto.message(1, Proto.message(1, current_map_id))
        .merge(Proto.message(2, packed.to_byte_array()))
    ))
```

### Fase 7: Escena de juego (Game.tscn)

#### 2.7.1 Escena básica

```
Game (Control, script: GameUI.gd)
├── MapView (SubViewportContainer, layer=0)
├── ActorLayer (CanvasLayer, layer=1)
│   └── Actors (Node2D)
├── UIOverlay (CanvasLayer, layer=2)
│   ├── HPBar (TextureProgressBar)
│   ├── PA Bar (Label)
│   ├── PM Bar (Label)
│   └── ChatBox (TextEdit)
└── SpellBar (HBoxContainer)
    └── SpellSlots (Array of 10)
```

---

## 3. Errores conocidos que hay que arreglar

| # | Error | Archivo | Línea | Causa | Arreglo |
|---|-------|---------|-------|-------|---------|
| 1 | Falta `version` en `auth_request` | `SimpleProtocolClient.gd` | ~85 | No se añadió | Añadir `"version": "3.6.10.10"` |
| 2 | `servers_json: Dictionary` es incorrecto | `SimpleProtocolClient.gd` | 7-12 | El servidor envía Array | Cambiar a `servers_json: Array` |
| 3 | `GameManager._on_auth_response_received` llama `.get("servers")` | `GameManager.gd` | ~50 | `servers` es Array, no Diccionario | Usar `.size()` o iterar |
| 4 | `await connection_state_changed` espera `false` que nunca llega | `GameManager.gd` | ~80 | `connect_to_server` emite `false` sincronamente | Reestructurar el estado asíncrono |
| 5 | `_on_server_selection_response_received` crea `TestHero` fake | `GameManager.gd` | ~130 | No hay conexión TCP | Implementar `GameClient` |
| 6 | `lang_option` sin items en `_setup_defaults` | `LauncherUI.gd` | 32 | No se llenó el OptionButton | Añadir items en `_ready` |
| 7 | `lang` emitido como `int` pero `auth_requested` declara `String` | `LauncherUI.gd` | 72 | Señal mal declarada | Cambiar tipo a `int` o emitir como String |

---

## 4. Dependencias entre módulos

```
Fase 1 (Login HTTP)
    ↓
Fase 2 (WebSocket corregido)
    ↓
Fase 3 (Server selection)
    ↓
Fase 4 (TCP + kqz)
    ↓
Fase 5 (Character select)
    ↓
Fase 6 (Movimiento)
    ↓
Fase 7 (Juego completo)
```

---

## 5. Pruebas de integración

### 5.1 Probar login HTTP

```bash
curl -X POST http://127.0.0.1:8888/api/entrar \
  -H "Content-Type: application/json" \
  -d '{"usuario":"keka","clave":"test","ip":"127.0.0.1"}'
```

Debe devolver: `{"bien":true,"token":"...","apodo":"keka","cuenta":188940901,"rol":0}`

### 5.2 Probar WebSocket

```bash
node -e "
const ws = new WebSocket('ws://127.0.0.1:5557');
ws.onopen = () => {
  ws.send(Buffer.concat([
    Buffer.from([0,0,0,55]), // length 55
    JSON.stringify({type:'auth_request',token:'xxx',installId:'test',lang:'es'}).utf8Bytes
  ]));
};
"
```

### 5.3 Probar con `cliente_falso.py`

```bash
cd ../..
py tools/cliente_falso.py --step auth --step select --step tcp
```

---

## 6. Qué NO implementar todavía

| Feature | Razón |
|---------|-------|
| Combate | Requiere handshake de pelea completo; está documentado en `06-COMBATE.md` |
| Guilds (gremios) | 71 opcodes, sistema complejo; prioridad baja |
| Trading (intercambio) | No crítico para jugabilidad básica |
| Chat | Se puede ignorar hasta fase final |
| Mazmorras | Depende de combate |
| Cajas fuertes / haven bag avanzado | No esencial para prototipo |

---

## 7. Cuentas de prueba

| Cuenta | Contraseña | Nivel |
|--------|-----------|-------|
| keka | test | Tutorial (150+ kamas, Adventurer set) |
| admin | admin123 | Nivel alto (si existe) |

**Mapa inicial:** 191105026 (Astrub zaap).

---

## 8. Resumen

**Lo que funciona hoy:** Solo la conexión WebSocket y recepción de datos crudos.

**Lo que falta para que funcione:**
1. ✅ HTTP login (Fase 1)
2. ⚠️ WebSocket bugs (Fase 2)
3. ⬜ Server selection (Fase 3)
4. ⬜ TCP 5555 client (Fase 4)
5. ⬜ Character select scene (Fase 5)
6. ⬜ Movement system (Fase 6)
7. ⬜ Game scene (Fase 7)

**El bloque principal:** Sin TCP 5555 y sin presentación de ticket (`kqz`), el cliente no puede entrar al mundo. Implementar Fase 4 es la prioridad número 1.