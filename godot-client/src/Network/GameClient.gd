## TCP Game Client for DreamFus
## Connects to the game server on port 5555 and handles protobuf framing.
## Compatible with Godot 4.8 beta2
class_name GameClient
extends Node

signal connected
signal disconnected
signal message_received(opcode: String, payload: PackedByteArray, request_id: int)
signal error_occurred(message: String)
signal characters_received(characters: Array)
signal auth_response_received(success: bool, account_id: int, servers: Array, error: String)
signal server_selection_response_received(
	success: bool,
	ticket: String,
	host: String,
	ports: Array,
	error: String,
	language: String,
)

const ByteArrayExtensions = preload("res://src/Utils/ByteArrayExtensions.gd")
const Proto = preload("res://src/Network/Proto.gd")
const WorldProto = preload("res://src/Network/WorldProto.gd")

const GAME_PORT := 5555
## Same ceiling as the server (NetworkMessage.MaxFrameLength): the world entry block
## is ~737 KB, so anything tighter rejects a legitimate frame.
const MAX_FRAME_SIZE := 8 * 1024 * 1024 # 8 MiB

var tcp: StreamPeerTCP = null
var buffer: PackedByteArray = PackedByteArray()

# Reference to GameManager (accessed via singleton instance)
var game_manager: Node = null

## Current ticket for kqz authentication (set before TCP connection)
var pending_ticket: String = ""
## Language to include in kqz message (from server_selection_response)
var pending_language: String = ""
## Track the expected ticket for verification (useful for debugging)
var _expected_ticket: String = ""
## Protocol methods using Proto.gd
var _host: String = "127.0.0.1"
var _port: int = GAME_PORT
var _connected: bool = false
var _bytes_received: int = 0 # Counter for debugging

## Current authentication stage for server selection flow
var _current_auth_stage: String = "initial_auth" # initial_auth, connecting_to_game, waiting_for_ticket, waiting_for_server_list, authenticated


## Auth parameters stored for sending on connection (for fallback auth flow)
var _auth_lang: String = "" # Must be explicitly set via start_connection_for_auth()
var _auth_token: String = ""
var _auth_server_id: int = 0


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


func _ready() -> void:
	print("[GameClient] Inicializado")
	# Set reference to GameManager singleton if not already set
	if game_manager == null:
		game_manager = GameManager.instance if GameManager.instance != null else null


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

				# CRITICAL: Send ticket IMMEDIATELY before reading any data
				# The server expects kqz as the first message, otherwise it sends
				# the welcome burst prematurely (using fallback hoy message)
				_send_kqz_immediate()
				connected.emit()

			# Read whatever is pending. This used to stop after the welcome burst
			# (jtg) on the belief that nothing else could arrive, but that is exactly
			# where the world entry starts: kvw is answered with ~330 frames.
			var available: int = tcp.get_available_bytes()
			if available > 0:
				_bytes_received = available
				var result: Array = tcp.get_data(available)
				var err: Error = result[0]
				var data: PackedByteArray = result[1]
				if err == OK:
					if data.size() > 0:
						buffer.append_array(data)
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


func connect_to_game(
	host: String,
	port: int,
	ticket: String = "",
	language: String = "es",
) -> Error:
	"""Connect to TCP game server.
	
	Args:
		host: Server address
		port: Server port
		ticket: Optional ticket to send after connection (kqz authentication)
		language: Language code for kqz message (default: "es")
	"""
	if _connected:
		disconnect_tcp()

	_host = host
	_port = port

	# Limpiar buffer anterior
	buffer.clear()
	_connected = false

	# If ticket is provided directly, set it (preferred way for kqz flow)
	if ticket != "":
		# Clear auth state and prioritize kqz flow
		# Important: _auth_lang must start empty to prevent stale auth from being sent
		_auth_token = ""
		_auth_lang = ""
		_auth_server_id = 0
		_current_auth_stage = "connecting_to_game"

		pending_ticket = ticket
		_expected_ticket = ticket
		pending_language = language.strip_edges().to_lower()
		print(
			"[GameClient] Ticket establecido directamente: %s... (full: %s), lang=%s"
			% [ticket.substr(0, 8), ticket, pending_language]
		)

	tcp = StreamPeerTCP.new()
	# Disable Nagle's algorithm to ensure immediate packet delivery
	tcp.set_no_delay(true)
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
## Protocol format (from GODOT_CLIENT_PROTOCOL.md):
##   Packet {
##     InnerMessage {
##       Any {
##         type_url = "type.ankama.com/kqz",
##         value = inner_kqz_message
##       }
##     }
##   }
## The outer message uses field 2 for the inner message (not field 1 like requests)
## Based on: Pb.New().Msg(2, any_msg).Build()
func send_ticket(ticket: String, language: String = "es") -> void:
	if tcp == null or not _connected:
		printerr("[GameClient] No conectado, no se puede enviar kqz")
		return

	# Normalize ticket: trim whitespace and ensure lowercase
	var normalized_ticket: String = ticket.strip_edges().to_lower()

	# Build the inner kqz message: { f2: ticket, f3: language }
	var kqz_inner: PackedByteArray = PackedByteArray()
	Proto.put_string(kqz_inner, 2, normalized_ticket) # f2 = ticket
	if language != "":
		Proto.put_string(kqz_inner, 3, language) # f3 = language (optional but per protocol)

	# Build the Any message: { f1: "type.ankama.com/kqz", f2: kqz_inner }
	# Note: using "value" field name per protobuf Any spec, field 2 in our case
	var any_msg: PackedByteArray = PackedByteArray()
	Proto.put_string(any_msg, 1, "type.ankama.com/kqz") # f1 = type_url
	Proto.put_bytes(any_msg, 2, kqz_inner) # f2 = inner kqz message (as value)

	# Build the full packet: f1 { f1: Any } per protocol spec
	# This matches the C#: Pb.New().Msg(1, any.Build()).Build()
	var packet: PackedByteArray = PackedByteArray()
	Proto.put_bytes(packet, 1, any_msg) # f1 = Any message (correct per protocol)

	# Add VarInt length prefix (Dofus wire format)
	var framed: PackedByteArray = PackedByteArray()
	Proto.write_varint(framed, packet.size())
	framed.append_array(packet)

	print(
		"[GameClient] Enviando kqz (ticket=%s..., lang=%s, %d bytes)"
		% [normalized_ticket.substr(0, 8), language, framed.size()]
	)
	print("[GameClient] kqz hex: %s" % framed.hex_encode())

	var err: Error = tcp.put_data(framed)
	if err != OK:
		printerr("[GameClient] Error enviando kqz: %d" % err)
		error_occurred.emit("Error enviando kqz")
	else:
		print("[GameClient] Ticket kqz enviado exitosamente")


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


## Build AuthenticationMessage for connection server (bare protobuf, no envelope)
## Used for initial auth with token before connecting to game server
func build_auth_message(lang: String, token: String, server_id: int = 0) -> PackedByteArray:
	"""Build bare protobuf AuthenticationMessage (GameMessage) for connection server.
	
	Format from GameProtocol.proto:
	GameMessage {
		f1: AuthenticationTicketMessage auth
	}
	
	AuthenticationTicketMessage {
		f1: string lang
		f3: AuthenticationTicket ticket
		f4: SelectedServerSelection selectedServer
	}
	
	AuthenticationTicket {
		f3: TokenData tokenData
	}
	
	TokenData {
		f1: string token
	}
	"""
	var auth_msg: PackedByteArray = PackedByteArray()

	# Field 1: lang (string)
	Proto.put_string(auth_msg, 1, lang)

	# Field 3: AuthenticationTicket (message)
	# ticket = { f3: tokenData } where tokenData = { f1: token }
	var token_data_msg: PackedByteArray = PackedByteArray()
	Proto.put_string(token_data_msg, 1, token)

	# Wrap TokenData in ticket (field 3 in AuthenticationTicket)
	var ticket_msg: PackedByteArray = PackedByteArray()
	Proto.put_bytes(ticket_msg, 3, token_data_msg) # f3 = tokenData

	# Add ticket (field 3) to auth_msg
	Proto.put_bytes(auth_msg, 3, ticket_msg)

	# Field 4: SelectedServerSelection (if server_id > 0)
	if server_id > 0:
		var server_msg: PackedByteArray = PackedByteArray()
		Proto.put_varint(server_msg, 1, server_id) # f1 = serverId
		Proto.put_bytes(auth_msg, 4, server_msg)

	# Wrap AuthenticationMessage in GameMessage: f1 { f1: auth_msg }
	var game_msg: PackedByteArray = PackedByteArray()
	Proto.put_bytes(game_msg, 1, auth_msg)

	return game_msg


## Send initial authentication to connection server (TCP 5555)
## This is called on first connection with token and lang for authentication
func send_auth_message(lang: String, token: String, server_id: int = 0) -> void:
	if tcp == null or not _connected:
		printerr("[GameClient] No conectado, no se puede enviar auth")
		return

	var auth_frame = build_auth_message(lang, token, server_id)

	# Build framed message: varint length + bytes
	var out: PackedByteArray = PackedByteArray()
	Proto.write_varint(out, auth_frame.size())
	out.append_array(auth_frame)

	print(
		"[GameClient] Enviando auth (lang=%s, server=%d, %d bytes)" % [lang, server_id, out.size()]
	)
	var err: Error = tcp.put_data(out)
	if err != OK:
		printerr("[GameClient] Error enviando auth: %d" % err)
		error_occurred.emit("AUTH_SEND", "Error enviando autenticación: %d" % err)


## Start a connection with auth parameters (for connection server phase)
func start_connection_for_auth(
	host: String,
	port: int,
	lang: String,
	token: String,
	server_id: int = 0,
) -> Error:
	"""Store auth parameters and initiate TCP connection.
	Auth message will be sent automatically when connection is established."""
	_auth_lang = lang
	_auth_token = token
	_auth_server_id = server_id

	return connect_to_game(host, port)


## Change auth stage - sets auth parameters manually
func change_auth_stage(stage: Array) -> void:
	_auth_lang = stage[0]
	_auth_token = stage[1]
	_auth_server_id = stage[2]


## Send kqz immediately upon TCP connection (must send before reading any data)
func _send_kqz_immediate() -> void:
	# This sends kqz synchronously in the same frame as connection
	# Critical: must send before the server expects it
	_send_kqz_if_ready()


## Helper method to send kqz after deferred processing (fixes race condition)
func _send_kqz_if_ready() -> void:
	# This runs in the next frame via call_deferred, ensuring pending_ticket is set
	if pending_ticket != "":
		print("[GameClient] Enviando ticket kqz...")
		send_ticket(pending_ticket, pending_language)
		pending_ticket = ""
		pending_language = "" # Don't reset - wait for new server_selection_response
		_current_auth_stage = "waiting_for_ticket"
	else:
		# No ticket to send - might be auth flow
		pass


func _drain_buffer() -> void:
	var frames_parsed: int = 0
	while buffer.size() > 0:
		# Server uses VarInt framing for length prefix
		# Each frame is: [VarInt length][payload]
		var header: Array = Proto.read_varint(buffer, 0)
		if header[0] == null:
			print(
				"[GameClient] Buffer incompleto, wait for more data (need VarInt length, have %d)"
				% [buffer.size()]
			)
			return # buffer incompleto

		var size: int = int(header[0])
		var end: int = int(header[1])

		# Sanity check: size should be reasonable
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


## Handle server selection response from connection server
func _handle_server_selection_response(result: Dictionary) -> void:
	"""Handle AuthenticationTicketResultMessage for server selection phase.
	
	This receives the ServerHostInfo with ticket, address, and ports.
	"""
	if result.has("selected_server") and result["selected_server"] != null:
		var selected_server = result["selected_server"]
		if selected_server.has("info") and selected_server["info"] != null:
			var info = selected_server["info"]
			var ticket = info.get("ticket", "")
			var host = info.get("address", "")
			var ports = info.get("ports", [])

			print(
				"[GameClient] Servidor seleccionado: ticket=%s..., host=%s, ports=%d"
				% [ticket.substr(0, 8), host, ports.size()]
			)

			server_selection_response_received.emit(true, ticket, host, ports, "", pending_language)
			_current_auth_stage = "connected_to_game"
		else:
			print("[GameClient] No se recibió info del servidor")
			server_selection_response_received.emit(
				false,
				"",
				"",
				[],
				"No server info received",
				"es",
			)
	elif result.has("refused") and result["refused"] != null:
		var refused = result["refused"]
		var reason = refused.get("reason", 0)
		print("[GameClient] Selección de servidor rechazada, razón: %d" % reason)
		server_selection_response_received.emit(
			false,
			"",
			"",
			[],
			"Server selection refused: reason %d" % reason,
			"es",
		)
	else:
		print("[GameClient] Respuesta inesperada de selección de servidor")
		server_selection_response_received.emit(false, "", "", [], "Unexpected response", "es")


## Handle authentication response from connection server
func _handle_auth_response(result: Dictionary) -> void:
	"""Handle authentication response (accepted/refused).
	
	Args:
		result: Dictionary with 'accepted' or 'refused' key
	"""
	if result.has("accepted") and result["accepted"] != null:
		var accepted = result["accepted"]
		var servers = accepted.get("servers", [])

		print("[GameClient] Autenticación aceptada, servidores: %d" % servers.size())

		# Convert server data for GameManager
		var server_list = []
		for server_data in servers:
			if server_data is Dictionary:
				var server_info = server_data.get("server", { })
				var status = server_data.get("status", 0)
				var char_data = server_data.get("characters", [])

				if server_info is Dictionary:
					server_list.append(
						{
							"id": int(server_info.get("server_id", 0)),
							"status": int(status),
							"name": "Server " + str(server_info.get("server_id", 0)),
							"character_count": int(server_info.get("character_count", 0)),
						}
					)

		print("[GameClient] Processed %d servers for selection" % server_list.size())
		auth_response_received.emit(true, int(accepted.get("account_id", 0)), server_list, "")
		_current_auth_stage = "waiting_for_server_list"

	elif result.has("refused") and result["refused"] != null:
		var refused = result["refused"]
		var reason = refused.get("reason", 0)
		print("[GameClient] Autenticación rechazada, razón: %d" % reason)
		auth_response_received.emit(false, 0, [], "Auth refused: reason %d" % reason)
	else:
		print("[GameClient] Autenticación sin resultado claro")
		auth_response_received.emit(false, 0, [], "Unknown response")
