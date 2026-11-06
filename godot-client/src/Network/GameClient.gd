## TCP Game Client for DreamFus
## Connects to the game server on port 5555 and handles protobuf framing.
## Compatible with Godot 4.8 beta2
class_name GameClient
extends Node

## Preload ByteArrayExtensions helper para Godot 4.8
const ByteArrayExtensions = preload("res://src/Utils/ByteArrayExtensions.gd")

signal connected
signal disconnected
signal message_received(opcode: String, payload: PackedByteArray, request_id: int)
signal error_occurred(message: String)

const GAME_PORT := 5555
const MAX_FRAME_SIZE := 131072 # 128 KiB

var tcp: StreamPeerTCP = null
var buffer: PackedByteArray = PackedByteArray()
var _host: String = "127.0.0.1"
var _port: int = GAME_PORT
var _connected: bool = false
var _bytes_received: int = 0 # Counter for debugging


func _ready() -> void:
	print("[GameClient] Inicializado")


func _process(_delta: float) -> void:
	if tcp == null:
		return

	tcp.poll()
	var status: int = tcp.get_status()

	match status:
		StreamPeerTCP.STATUS_CONNECTED:
			if not _connected:
				_connected = true
				print("[GameClient] Conectado a TCP")
				connected.emit()

			# CRITICAL: Check available bytes BEFORE attempting to read
			# Godot 4.8 beta2 has unreliable signal handling, so we must poll
			# Note: get_available_bytes() can change between calls, so we store it
			var available: int = tcp.get_available_bytes()
			if available > 0:
				_bytes_received = available
				# get_data() returns [Error, PackedByteArray]
				var result: Array = tcp.get_data(available)
				var err: Error = result[0]
				var data: PackedByteArray = result[1]
				if err == OK:
					print(
						"[GameClient] Recibidos %d bytes (disponibles: %d)"
						% [data.size(), available]
					)
					if data.size() > 0:
						buffer.append_array(data)
						print("[GameClient] Buffer total: %d bytes" % buffer.size())
						_drain_buffer()
				else:
					print("[GameClient] get_data error: %d" % err)

		StreamPeerTCP.STATUS_CONNECTING:
			pass # Still connecting
		StreamPeerTCP.STATUS_NONE, StreamPeerTCP.STATUS_ERROR:
			if _connected:
				print("[GameClient] TCP desconectado (status=%d)" % status)
				_connected = false
				disconnected.emit()
			tcp = null


func connect_to_game(host: String, port: int) -> Error:
	if _connected:
		disconnect_tcp()

	_host = host
	_port = port

	# Limpiar buffer anterior
	buffer.clear()
	_connected = false
	
	tcp = StreamPeerTCP.new()
	var err := tcp.connect_to_host(host, port)
	if err != OK:
		printerr("[GameClient] Error conectando TCP: %d" % err)
		error_occurred.emit("Error conectando al servidor: %d" % err)
		return err

	print("[GameClient] Conectando a TCP %s:%d..." % [host, port])
	return OK


func disconnect_tcp() -> void:
	if tcp != null:
		tcp.disconnect_from_host()
		tcp = null
	_connected = false
	disconnected.emit()


## Build and send a client request message.
func send_request(opcode: String, payload: PackedByteArray = PackedByteArray()) -> void:
	if tcp == null or not _connected:
		printerr("[GameClient] No conectado, no se puede enviar: %s" % opcode)
		return

	var body: PackedByteArray = Proto.request(opcode, payload)
	var out: PackedByteArray = PackedByteArray()
	Proto.write_varint(out, body.size())
	out.append_array(body)

	print("[GameClient] Enviando %s (%d bytes)" % [opcode, out.size()])
	var err: Error = tcp.put_data(out)
	if err != OK:
		printerr("[GameClient] Error enviando %s: %d" % [opcode, err])
		error_occurred.emit("Error enviando %s" % opcode)


## Send a push message (server-style, for special cases).
func send_push(opcode: String, payload: PackedByteArray = PackedByteArray()) -> void:
	if tcp == null or not _connected:
		printerr("[GameClient] No conectado, no se puede enviar push: %s" % opcode)
		return

	var body: PackedByteArray = Proto.push(opcode, payload)
	var out: PackedByteArray = PackedByteArray()
	Proto.write_varint(out, body.size())
	out.append_array(body)

	print("[GameClient] Push %s: %d bytes (payload=%d)" % [opcode, out.size(), payload.size()])
	var err: Error = tcp.put_data(out)
	if err != OK:
		printerr("[GameClient] Error enviando push %s: %d" % [opcode, err])
		error_occurred.emit("Error enviando push %s" % opcode)


## Build and send kqz (present ticket).
## kqz is a client request presenting a ticket for authentication.
## Protocol format (from server tests):
##   f2 { f1: Any { f1: "type.ankama.com/kqz", f2: { f2: ticket, f3: language } }, f2: -1 }
## Note: Server accepts kqz with just ticket in field 2, language in field 3 is optional
func send_ticket(ticket: String, language: String = "es") -> void:
	if tcp == null or not _connected:
		printerr("[GameClient] No conectado, no se puede enviar kqz")
		return

	# Build the inner kqz message: { f2: ticket, f3: language }
	# Language is optional per protocol docs; server accepts ticket only
	var kqz_inner: PackedByteArray = PackedByteArray()
	Proto.put_string(kqz_inner, 2, ticket) # f2 = ticket
	if language != "":
		Proto.put_string(kqz_inner, 3, language) # f3 = language (optional)

	# Build the Any message: { f1: "type.ankama.com/kqz", f2: kqz_inner }
	var any_msg: PackedByteArray = PackedByteArray()
	Proto.put_string(any_msg, 1, "type.ankama.com/kqz") # f1 = type_url
	Proto.put_bytes(any_msg, 2, kqz_inner) # f2 = inner kqz message

	# Build the request wrapper: f2 { f1: Any, f2: -1 }
	var wrapper: PackedByteArray = PackedByteArray()
	Proto.put_bytes(wrapper, 1, any_msg) # f1 = Any
	Proto.put_varint(wrapper, 2, -1) # f2 = request_id (-1)

	# Build the root message: f2 { wrapper }
	var envelope: PackedByteArray = PackedByteArray()
	Proto.put_bytes(envelope, 2, wrapper) # f2 = wrapper

	# Add VarInt length prefix (Dofus wire format)
	var framed: PackedByteArray = PackedByteArray()
	Proto.write_varint(framed, envelope.size())
	framed.append_array(envelope)

	print("[GameClient] Enviando kqz (ticket=%s...)" % ticket.substr(0, 8))
	var err: Error = tcp.put_data(framed)
	if err != OK:
		printerr("[GameClient] Error enviando kqz: %d" % err)
		error_occurred.emit("Error enviando kqz")


## Build and send kvw (select character by ID).
## kvw format: f1 { f1: character_id } - but the payload passed to push() is just the inner message { f1: id }
## The push() function wraps it in the Any envelope with the opcode URL.
## Server expects: field 1 as varint containing the character ID.
static func build_character_selection(character_id: int) -> PackedByteArray:
	"""Build kvw payload: { f1: character_id } as a flat varint message."""
	if character_id <= 0:
		printerr("[GameClient] Invalid character_id: %d" % character_id)
		return PackedByteArray()
	var payload: PackedByteArray = PackedByteArray()
	Proto.put_varint(payload, 1, character_id)
	return payload


func send_character_selection(character_id: int) -> void:
	var payload := build_character_selection(character_id)
	if payload.is_empty():
		return
	send_push("kvw", payload)


## Build and send kqo (heartbeat, every 5 seconds).
func send_heartbeat() -> void:
	send_request("kqo")


## Check if client is connected to TCP server.
## Not is_connected() due to conflict with Object.is_connected()
func is_tcp_connected() -> bool:
	return _connected and tcp != null


## Get the current host.
func get_host() -> String:
	return _host


## Get the current port.
func get_port() -> int:
	return _port


func _drain_buffer() -> void:
	var frames_parsed: int = 0
	while buffer.size() > 0:
		var header: Array = Proto.read_varint(buffer, 0)
		if header[0] == null:
			print(
				"[GameClient] Buffer incompleto, wait for more data (need %d bytes, have %d)"
				% [header[1] - buffer.size(), buffer.size()]
			)
			return # buffer incompleto

		var size: int = int(header[0])
		var end: int = int(header[1])

		if size > MAX_FRAME_SIZE:
			printerr("[GameClient] Frame demasiado grande: %d bytes" % size)
			buffer.clear()
			error_occurred.emit("Frame demasiado grande: %d bytes" % size)
			return

		if buffer.size() < end + size:
			print(
				"[GameClient] Buffer insuficiente: need %d, have %d" % [end + size, buffer.size()]
			)
			return # esperar más datos

		var frame: PackedByteArray = ByteArrayExtensions.byte_subarray(buffer, end, size)
		buffer = ByteArrayExtensions.byte_subarray_from(buffer, end + size)
		frames_parsed += 1

		# Aumentar límite para permitir batch completo del welcome burst (hasta 20 frames)
		if frames_parsed > 20:
			print("[GameClient] Demasiados frames, deteniendo para evitar bucle infinito")
			break

		var msg: Dictionary = Proto.decode(frame)
		if not msg.is_empty():
			print(
				"[GameClient] -> Emitiendo mensaje: opcode=%s, payload=%d bytes"
				% [msg.get("opcode", ""), msg.get("payload", PackedByteArray()).size()]
			)
			message_received.emit(msg["opcode"], msg["payload"], msg["id"])

	if frames_parsed > 0:
		print(
			"[GameClient] Frames parseados: %d, buffer restante: %d bytes"
			% [frames_parsed, buffer.size()]
		)
