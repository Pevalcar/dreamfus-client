# 01 — Transporte

Dos transportes distintos, en dos puertos distintos, con dos formatos distintos. No se mezclan.

| | WebSocket 5557 | TCP 5555 |
|---|---|---|
| Qué lleva | Login y selección de servidor | La partida entera |
| Formato | JSON UTF-8 | Protobuf |
| Prefijo | 4 bytes big-endian | VarInt |
| Quién lo implementa hoy en el cliente | `SimpleProtocolClient.gd` | **nadie todavía** |

---

## 1. WebSocket 5557 (SimpleProtocol)

### 1.1 Formato exacto

Cada mensaje es **un frame binario de WebSocket** cuyo contenido es:

```
[4 bytes: longitud N, big-endian] [N bytes: JSON UTF-8]
```

El prefijo está **dentro** del mensaje de WebSocket, no fuera. El servidor lee 4 bytes, luego lee
exactamente N y parsea ese JSON (`Custom/Core/SimpleProtocolHandler.cs:101-117`). El cliente Godot
ya lo hace bien en `send_message()` / `_process_buffer()`.

Detalles del servidor:

- Acepta una sola conexión por mensaje: no hay mensajes partidos ni continuaciones.
- Límite: `payloadLen > 1_048_576` → error `FRAME_TOO_LARGE` y cierra. 1 MiB.
- Rate limit por IP: token bucket de 10 por segundo con ráfaga de 20
  (`TokenBucket(10, 20)`). Al pasarse: `RATE_LIMITED` y cierra.
- Los mensajes se envían como `WebSocketMessageType.Binary`. No llegan como texto.
- `{"type":"ping"}` → `{"type":"pong","timestamp":...}`. Es opcional, el cliente no lo necesita.

### 1.2 Tipos de mensaje

| `type` | Dirección | Payload |
|---|---|---|
| `auth_request` | C → S | `token`, `installId`, `lang`, `version` (opcional) |
| `auth_response` | S → C | `success`, `account_id`, `servers[]` o `error` |
| `server_selection` | C → S | `server_id`, `account_id`, `lang` |
| `server_selection_response` | S → C | `success`, `ticket`, `host`, `ports[]` o `error` |
| `error` | S → C | `code`, `message` |
| `ping` / `pong` | ambos | `timestamp` |

El detalle de cada uno, en `02-LOGIN-Y-CUENTAS.md`.

### 1.3 Nombres de campo

El servidor serializa con `JsonNamingPolicy.CamelCase` y deserializa con
`PropertyNameCaseInsensitive = true`. En la práctica:

- Petición: `installId` (camel), pero `install_id` también se acepta por la insensibilidad.
- Respuesta de auth: `account_id` (con guion bajo, tal cual se declaró) y `is_full` para servidores.
- `account_id` en `server_selection` es obligatorio y **tiene que coincidir** con la sesión
  autenticada, o el servidor contesta `UNAUTHORIZED`.

---

## 2. TCP 5555 (partida)

### 2.1 El puerto lleva dos protocolos

`GameServerProxy.HandleGameClient` decide por el **primer frame**:

- Contiene la cadena `type.ankama.com` → es una sesión de partida, va a `GameNodeProxy`.
- No la contiene → es el servidor de conexión, que habla un protobuf pequeño y distinto (§5).

El cliente abre una conexión nueva para cada fase. El ticket de `server_selection` se presenta en la
conexión de partida.

### 2.2 Framing

```
[VarInt: longitud N] [N bytes: un mensaje protobuf]
```

- Sin compresión, sin cifrado, sin handshake propio.
- Un frame = un mensaje. Medido en 103.808 frames: **ningún** mensaje ocupa dos frames.
- VarInt: 7 bits por byte, bit alto = "sigue". Como en protobuf. `-1` ocupa 10 bytes
  (`FF FF FF FF FF FF FF FF FF 01`).

### 2.3 El envelope

El mensaje tiene **exactamente un campo raíz**. El número de ese campo es la dirección:

```
root {
  1 { f1: Any }               // servidor -> cliente, push
  2 { f1: Any, f2: id }       // cliente -> servidor, petición
  3 { f1: Any, f2: id }       // servidor -> cliente, respuesta
}

Any {
  f1: "type.ankama.com/" + opcode de 3 letras   (string)
  f2: payload                                    (bytes)
}
```

| Campo raíz | Quién | Significado | Frames medidos |
|---|---|---|---|
| `f1` | servidor | Push | 83.146 |
| `f2` | cliente | Petición | 15.583 |
| `f3` | servidor | Respuesta, con id | 5.047 |

**No son intercambiables.** `jsq` (permiso para salir del mapa) mandado en `f1` en vez de `f3` se
ignora: el cliente nunca manda `jqk` y el personaje se queda clavado en el borde.

Un frame real, 33 bytes, un `jru` que dice "carga el mapa 154010882":

```
20 0a 1e 0a 1c 0a 13 74 79 70 65 2e 61 6e 6b 61 6d 61 2e 63 6f 6d 2f 6a 72 75 12 05 10 82 8a b8 49
│  │  │  │  │  └── "type.ankama.com/jru"
│  │  │  │  └───── campo 1 (type URL), longitud 19
│  │  │  └──────── Any, longitud 28
│  │  └─────────── campo 1 del root, longitud 30
│  └────────────── longitud del frame: 32
└───────────────── varint 0x20
```

### 2.4 Request id

El cliente manda `-1` en 15.416 de 15.583 peticiones (98,9 %). El servidor devuelve el mismo id en
`f2` de la respuesta.

Consecuencia: **el emparejamiento real es por orden de llegada**. Y por eso:

- Dos peticiones iguales en vuelo no se pueden distinguir.
- Un push puede parecer una respuesta. Empareja primero por campo raíz, luego por orden.
- Un mensaje perdido desincroniza todo lo que venga después, en silencio.

Regla: al contestar, lee el id del frame recibido y devuélvelo. Nunca escribas `-1` a mano.

Excepciones medidas: `lqf`, `ify`, `krl`, `kro`, `igy`, `krv`, `kum`, `lux`, `kxh`, `iio`, `iha`,
`luy`, `ihf`, `ihs`, `iin`, `iiy` usan id real e incremental.

### 2.5 Límites

- **131.072 bytes por mensaje** (128 KiB). Es un límite del cliente, no del servidor. Pasarse no da
  error en el servidor: el cliente lo tira dentro de su capa TCP. El síntoma es un panel vacío.
- El inventario (`ivx`) es el caso típico: viaja entero en un solo mensaje. Presupuesta ~56 bytes
  por objeto (el servidor los escribe así de gordos).
- El opcode debe medir **exactamente 3 letras**. Si no, el cliente ignora el mensaje sin avisar.

### 2.6 Tipos de wire de protobuf

| Wire | Número | Cómo se lee |
|---|---|---|
| varint | 0 | entero de longitud variable |
| fixed64 | 1 | 8 bytes |
| length-delimited | 2 | varint de longitud + bytes (strings, submensajes, packed) |
| fixed32 | 5 | 4 bytes |

Proto3 omite los campos con valor cero. Por eso un mensaje puede estar vacío y seguir siendo
significativo (`lva`, `jsq`, `kqy` con `f1:1`).

---

## 3. Recetas GDScript

Estas funciones son la base de todo lo demás. Van en un script aparte
(`src/Network/Proto.gd`, `class_name Proto`) para no repetirlas.

### 3.1 VarInt

```gdscript
class_name Proto
extends RefCounted

## Escribe un VarInt (64 bits con signo) al final de `buf`.
static func write_varint(buf: PackedByteArray, value: int) -> void:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_s64(0, value)  # little-endian, complemento a dos
	var i := 0
	while i < 8:
		var b: int = bytes[i]
		var more := false
		for j in range(i + 1, 8):
			if bytes[j] != 0:
				more = true
				break
		if not more and (b & 0x80) == 0:
			buf.append(b)
			return
		buf.append(b | 0x80)
		i += 1
	# Los negativos se extienden a 10 bytes (0xFF * 8 + 0x01).
	buf.append(0xFF)
	buf.append(0x01)


## Lee un VarInt. Devuelve [valor, siguiente_offset] o [null, offset] si falta.
static func read_varint(buf: PackedByteArray, offset: int) -> Array:
	var result: int = 0
	var shift := 0
	var i := offset
	while i < buf.size():
		var b: int = buf[i]
		i += 1
		result |= (b & 0x7F) << shift
		if (b & 0x80) == 0:
			return [result, i]
		shift += 7
		if shift >= 70:
			break
	return [null, i]
```

Comprobación rápida: `write_varint(-1)` tiene que dar exactamente
`FF FF FF FF FF FF FF FF FF 01`.

### 3.2 Campos

```gdscript
static func tag(field: int, wire: int) -> int:
	return (field << 3) | wire


## Campo varint (wire 0).
static func put_varint(out: PackedByteArray, field: int, value: int) -> void:
	write_varint(out, tag(field, 0))
	write_varint(out, value)


## Campo de bytes (wire 2).
static func put_bytes(out: PackedByteArray, field: int, data: PackedByteArray) -> void:
	write_varint(out, tag(field, 2))
	write_varint(out, data.size())
	out.append_array(data)


## Campo string (wire 2).
static func put_string(out: PackedByteArray, field: int, text: String) -> void:
	put_bytes(out, field, text.to_utf8_buffer())


## Submensaje: construye aparte y mete sus bytes como wire 2.
static func message(field: int, body: PackedByteArray) -> PackedByteArray:
	var out := PackedByteArray()
	put_bytes(out, field, body)
	return out
```

### 3.3 Leer un mensaje

```gdscript
## Devuelve un Array de diccionarios: {n, w, v, b}
## v = varint, b = bytes (wire 2). Los campos desconocidos se conservan.
static func parse(buf: PackedByteArray) -> Array:
	var fields: Array = []
	var i := 0
	while i < buf.size():
		var head: Array = read_varint(buf, i)
		if head[0] == null:
			break
		var key: int = head[0]
		i = head[1]
		var n: int = key >> 3
		var w: int = key & 0x07
		match w:
			0:
				var r: Array = read_varint(buf, i)
				if r[0] == null:
					break
				fields.append({"n": n, "w": 0, "v": r[0]})
				i = r[1]
			1:
				fields.append({"n": n, "w": 1, "b": buf.slice(i, i + 8)})
				i += 8
			2:
				var l: Array = read_varint(buf, i)
				if l[0] == null:
					break
				i = l[1]
				fields.append({"n": n, "w": 2, "b": buf.slice(i, i + l[0])})
				i += l[0]
			5:
				fields.append({"n": n, "w": 5, "b": buf.slice(i, i + 4)})
				i += 4
			_:
				break  # wire desconocido: no se puede seguir con seguridad
	return fields


## Primer campo con ese número, o null.
static func first(fields: Array, n: int) -> Variant:
	for f in fields:
		if f["n"] == n:
			return f
	return null


## Todos los campos con ese número (repetidos).
static func all(fields: Array, n: int) -> Array:
	var out: Array = []
	for f in fields:
		if f["n"] == n:
			out.append(f)
	return out


## Varints empaquetados (packed, wire 2) -> Array de enteros.
static func packed(buf: PackedByteArray) -> Array:
	var out: Array = []
	var i := 0
	while i < buf.size():
		var r: Array = read_varint(buf, i)
		if r[0] == null:
			break
		out.append(r[0])
		i = r[1]
	return out
```

### 3.4 Construir un envelope

```gdscript
## Petición del cliente: root 2 { f1: Any, f2: id }.
static func request(opcode: String, payload: PackedByteArray, request_id: int = -1) -> PackedByteArray:
	var any := PackedByteArray()
	put_string(any, 1, "type.ankama.com/" + opcode)
	if payload.size() > 0:
		put_bytes(any, 2, payload)

	var wrapper := PackedByteArray()
	put_bytes(wrapper, 1, any)
	put_varint(wrapper, 2, request_id)

	var root := PackedByteArray()
	put_bytes(root, 2, wrapper)
	return root


## Respuesta del servidor: root 3, con el id recibido.
static func answer(opcode: String, payload: PackedByteArray, request_id: int) -> PackedByteArray:
	var any := PackedByteArray()
	put_string(any, 1, "type.ankama.com/" + opcode)
	if payload.size() > 0:
		put_bytes(any, 2, payload)

	var wrapper := PackedByteArray()
	put_bytes(wrapper, 1, any)
	put_varint(wrapper, 2, request_id)

	var root := PackedByteArray()
	put_bytes(root, 3, wrapper)
	return root


## Push del servidor: root 1, sin id.
static func push(opcode: String, payload: PackedByteArray) -> PackedByteArray:
	var any := PackedByteArray()
	put_string(any, 1, "type.ankama.com/" + opcode)
	if payload.size() > 0:
		put_bytes(any, 2, payload)

	var root := PackedByteArray()
	put_bytes(root, 1, any)
	return root
```

### 3.5 Leer un envelope recibido

```gdscript
## Devuelve {root: 1|2|3, opcode: String, payload: PackedByteArray, id: int}
static func decode(frame: PackedByteArray) -> Dictionary:
	var fields := parse(frame)
	if fields.is_empty():
		return {}
	var root_field: Dictionary = fields[0]
	var wrapper := parse(root_field["b"])
	var any_field: Variant = first(wrapper, 1)
	if any_field == null:
		return {}
	var any := parse(any_field["b"])
	var url_field: Variant = first(any, 1)
	var type_url: String = url_field["b"].get_string_from_utf8() if url_field != null else ""
	var payload: PackedByteArray = PackedByteArray()
	var payload_field: Variant = first(any, 2)
	if payload_field != null:
		payload = payload_field["b"]
	var id := -1
	var id_field: Variant = first(wrapper, 2)
	if id_field != null:
		id = id_field["v"]
	return {
		"root": root_field["n"],
		"opcode": type_url.trim_prefix("type.ankama.com/"),
		"payload": payload,
		"id": id,
	}
```

### 3.6 El framing TCP

```gdscript
var _tcp := StreamPeerTCP.new()
var _rx := PackedByteArray()

func _process(_delta: float) -> void:
	_tcp.poll()
	if _tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return
	var chunk := _tcp.get_partial_data(65536)
	if chunk[0] == OK and chunk[1].size() > 0:
		_rx.append_array(chunk[1])
	_drain()

func _drain() -> void:
	while true:
		var head: Array = Proto.read_varint(_rx, 0)
		if head[0] == null:
			return
		var size: int = head[0]
		if size > 131072:
			printerr("Frame demasiado grande del servidor: %d" % size)
			_rx.clear()
			return
		if _rx.size() < head[1] + size:
			return  # esperar más
		var frame := _rx.slice(head[1], head[1] + size)
		_rx = _rx.slice(head[1] + size)
		var msg := Proto.decode(frame)
		if not msg.is_empty():
			message_received.emit(msg)

func send_opcode(opcode: String, payload: PackedByteArray = PackedByteArray()) -> void:
	var body := Proto.request(opcode, payload)
	var out := PackedByteArray()
	Proto.write_varint(out, body.size())
	out.append_array(body)
	_tcp.put_data(out)
```

`StreamPeerTCP` es bloqueante-ish, pero `poll()` + `get_partial_data()` desde `_process` es
suficiente para este protocolo y no hay que pelearse con hilos.

---

## 4. Qué mandar en cada momento (resumen)

| Cuándo | Opcode | Dirección | Payload |
|---|---|---|---|
| Nada más conectar al 5555 | `kqz` | C→S | `f2: ticket` (string) |
| Justo detrás | `krt` | C→S | vacío |
| Al elegir personaje | `kvw` | C→S | `f1: id` (varint) |
| Tras la ráfaga de bienvenida | `kvc` | C→S | vacío (CharacterListRequest) |
| Tras recibir `kub` | `lqc` | C→S | vacío (SequenceNumberRequest) |
| Cada 5 s | `kqo` | C→S | vacío (PingRequest) |
| Al cargar un mapa | `jrh` (+ `kmv`) | C→S | vacío |
| Al caminar | `jrw` | C→S | `f1: mapa`, `f2: packed (facing<<12)\|celda` |
| Al llegar a un borde | `jqi` | C→S | vacío |
| Tras el `jsq` | `jqk` | C→S | `f2: mapa` |

Nada más. Todo lo demás lo manda el servidor.

> **Nota:** En login normal, el servidor **no responde** a `kvc`/`krv` porque ya envió `kvi` en el burst. En reconexión a combate/koliseo, el servidor sí responde con `kvi` + `kvd`.

Nada más. Todo lo demás lo manda el servidor.

---

## 5. El servidor de conexión (el otro protocolo del 5555)

Solo se usa si implementas el flujo "oficial" de Dofus (cliente real). El cliente Godot **no lo
necesita**: obtiene el ticket por el WebSocket y lo presenta en la conexión de partida
directamente.

Por si acaso, su formato es un protobuf normal, sin envelope:

```proto
message GameMessage {
    AuthenticationTicketMessage       auth       = 1;  // cliente -> servidor
    AuthenticationTicketResultMessage authResult = 2;  // servidor -> cliente
}
```

Seleccionar servidor son 11 bytes:

```
0a 0a 08 0a 01 31 22 03 08 a2 02
│  │  │  └ "1" (lang)     │  └ serverId 290 (varint a2 02)
│  │  └ campo 1 del auth  └ campo 4 (selectedServer)
│  └ auth, 8 bytes
└ frame de 10 bytes
```

La respuesta trae ticket, host y puertos empaquetados, y apunta a `127.0.0.1:5555`.

---

## 6. Trampas de transporte

1. **El prefijo del WebSocket es de 4 bytes fijos, no VarInt.** El del TCP es VarInt. No los
   mezcles.
2. **El WebSocket entrega binario.** No uses `get_packet().get_string_from_utf8()` sin quitar los
   4 bytes de longitud.
3. **`-1` en VarInt son 10 bytes.** Un `int` de GDScript desplazado aritméticamente se queda
   negativo para siempre; usa `encode_s64` como en la receta.
4. **Proto3 omite ceros.** `jsq` vacío es una respuesta válida. `kqy` con `f1:1` parece casi vacío
   y no lo es.
5. **El campo raíz decide el destinatario.** Una respuesta en `f1` se ignora.
6. **Un `jru` de más recarga el mundo en bucle.**
7. **El servidor cierra el WebSocket 100 ms después de `server_selection_response`.** No lo tomes
   por un error: es el handoff al TCP.
