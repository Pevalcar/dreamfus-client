class_name SimpleProtocolClient
# SimpleProtocolClient - WebSocket client for game server communication
# Not using class_name to avoid conflicts with scene node assignments in Godot 4.8 beta2
extends Node

signal connection_state_changed(connected: bool)
signal message_received(message_type: String, payload: Dictionary)
signal error_received(error: String, details: String)
signal auth_response_received(success: bool, account_id: int, servers_json: Array, error: String)
signal server_selection_response_received(
	success: bool,
	ticket: String,
	host: String,
	ports: Array,
	error: String,
	language: String,
)

enum ClientState {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	ERROR,
}

## Preload ByteArrayExtensions helper para Godot 4.8
const ByteArrayExtensions = preload("res://src/Utils/ByteArrayExtensions.gd")

# WebSocketPeer.State values (Godot 4.8 beta2)
const STATE_CONNECTING: int = WebSocketPeer.STATE_CONNECTING
const STATE_OPEN: int = WebSocketPeer.STATE_OPEN
const STATE_CLOSING: int = WebSocketPeer.STATE_CLOSING
const STATE_CLOSED: int = WebSocketPeer.STATE_CLOSED

@export var host: String = "127.0.0.1"
@export var port: int = 5557 # WebSocket port for protocol 3.6.10.10
@export var connection_timeout: float = 10.0

## Reference to GameManager (accessed via singleton instance)
var game_manager: Node = null

var state: ClientState = ClientState.DISCONNECTED
var _websocket: WebSocketPeer = null
var _buffer: PackedByteArray = PackedByteArray()
var _pending_connections: Array = []
var _connection_logged: bool = false # Track if we logged state changes to reduce spam

## Auth parameters to send when connection opens
var _auth_lang: String = ""
var _auth_token: String = ""
var _auth_install_id: String = ""
var _lang_code: String = "" # Store lang for server selection


func _ready() -> void:
	print("[SimpleProtocolClient] Inicializado")
	_websocket = WebSocketPeer.new()
	_websocket.inbound_buffer_size = 262144 # 1 MB buffer for incoming data
	_websocket.outbound_buffer_size = 262144 # 1 MB buffer for outgoing data

	_pending_connections = []
	# Set reference to GameManager singleton
	if game_manager == null:
		if GameManager.instance != null:
			game_manager = GameManager.instance

	# Store exported configuration in instance variables
	host = host # Ensure exported values are copied
	port = port


func _process(delta: float) -> void:
	if _websocket == null:
		return
	_websocket.poll()

	var ws_state: int = _websocket.get_ready_state()

	# Always try to process incoming data when we have the OPEN state
	if ws_state == STATE_OPEN:
		_process_received_data()

		if state != ClientState.CONNECTED:
			# Connection just opened - emit only once
			if not _connection_logged:
				state = ClientState.CONNECTED
				print("[SimpleProtocolClient] Connection established! Sending auth_request...")
				connection_state_changed.emit(true)
				_connection_logged = true

			# Send auth request automatically if we have auth params
			if _auth_token != "" and _auth_install_id != "":
				send_auth_request(_auth_lang, _auth_token, _auth_install_id)
				# Clear after sending so we don't resend
				# Note: _auth_lang is kept for server selection -> kqz flow
				_auth_token = ""
				_auth_install_id = ""

			# Call any pending callbacks (shouldn't be needed now, but kept for safety)
			for pending_cb in _pending_connections:
				if pending_cb.is_valid():
					pending_cb.call()
			_pending_connections.clear()
	elif ws_state == STATE_CONNECTING:
		if state == ClientState.ERROR:
			state = ClientState.CONNECTING
	elif ws_state == STATE_CLOSED or ws_state == STATE_CLOSING:
		var was_connecting := state == ClientState.CONNECTING
		var was_connected := state == ClientState.CONNECTED

		# Reset connection logging for next connection attempt
		_connection_logged = false

		if was_connecting and not was_connected:
			# Normal closure after server_selection_response should NOT be an error
			# But if we never connected, it's an error
			print("[SimpleProtocolClient] WebSocket closed (was_connected=%s)" % was_connected)
		state = ClientState.DISCONNECTED
		connection_state_changed.emit(false)
		_pending_connections.clear()


func connect_to_server(
	target_host: String,
	target_port: int,
	lang: String = "",
	token: String = "",
	install_id: String = "",
) -> void:
	print("[SimpleProtocolClient] connect_to_server called: %s:%d" % [target_host, target_port])
	if state == ClientState.CONNECTED:
		print("[SimpleProtocolClient] Already connected!")
		connection_state_changed.emit(true)
		return

	self.host = target_host
	self.port = target_port
	state = ClientState.CONNECTING

	# Store auth params to send when connection opens
	_auth_lang = lang
	_auth_token = token
	_auth_install_id = install_id
	# Preserve lang for server selection -> kqz flow
	_lang_code = lang

	var url: String = "ws://%s:%d" % [host, port]
	print("[SimpleProtocolClient] Connecting to: %s" % url)

	var err := _websocket.connect_to_url(url)
	print(
		"[SimpleProtocolClient] connect_to_url result: %s (error=%d)"
		% ["OK" if err == OK else "ERROR", err]
	)

	if err != OK:
		printerr("[SimpleProtocolClient] Failed to start WebSocket connection: %d" % err)
		state = ClientState.ERROR
		connection_state_changed.emit(false)
		error_received.emit("WS_CONNECT", "Error al conectar WebSocket: %d" % err)
	else:
		print("[SimpleProtocolClient] WebSocket connection initiated successfully")


func disconnect_from_server() -> void:
	if _websocket != null and state == ClientState.CONNECTED:
		_websocket.close()
	_buffer.clear()
	state = ClientState.DISCONNECTED


func send_message(message_type: String, payload: Dictionary) -> void:
	if state != ClientState.CONNECTED:
		printerr(
			"[SimpleProtocolClient] No conectado, no se puede enviar mensaje (state=%s)" % state
		)
		return

	var json_str: String = JSON.stringify(payload)
	var json_bytes: PackedByteArray = json_str.to_utf8_buffer()

	var packet := PackedByteArray()
	packet.resize(4 + json_bytes.size())
	packet[0] = (json_bytes.size() >> 24) & 0xFF
	packet[1] = (json_bytes.size() >> 16) & 0xFF
	packet[2] = (json_bytes.size() >> 8) & 0xFF
	packet[3] = json_bytes.size() & 0xFF

	for i in range(json_bytes.size()):
		packet[4 + i] = json_bytes[i]

	var err := _websocket.put_packet(packet)
	if err != OK:
		printerr("[SimpleProtocolClient] Error enviando paquete: %d" % err)
	else:
		print("[SimpleProtocolClient] put_packet OK, size=%d" % packet.size())


func send_auth_request(lang: String, token: String, install_id: String) -> void:
	print("[SimpleProtocolClient] send_auth_request called (state=%s)" % state)
	var payload = {
		"type": "auth_request",
		"lang": lang,
		"token": token,
		"installId": install_id,
		"version": "3.6.10.10",
	}
	send_message("auth_request", payload)


func send_server_selection(server_id: int, account_id: int, lang: String) -> void:
	var payload = {
		"type": "server_selection",
		"server_id": server_id,
		"account_id": account_id,
		"lang": lang,
	}
	send_message("server_selection", payload)


func _process_received_data() -> void:
	while _websocket.get_available_packet_count() > 0:
		var packet: PackedByteArray = _websocket.get_packet()
		_buffer.append_array(packet)
		_process_buffer()


func _process_buffer() -> void:
	if _buffer.size() < 4:
		return

	var msg_len: int = (_buffer[0] << 24) | (_buffer[1] << 16) | (_buffer[2] << 8) | _buffer[3]
	if _buffer.size() < 4 + msg_len:
		return

	var json_bytes := ByteArrayExtensions.byte_subarray(_buffer, 4, msg_len)
	var json_str: String = json_bytes.get_string_from_utf8()
	_buffer = ByteArrayExtensions.byte_subarray_from(_buffer, 4 + msg_len)

	var json: JSON = JSON.new()
	var parse_result: int = json.parse(json_str)
	if parse_result != Error.OK:
		error_received.emit("JSON_PARSE", "Error parseando JSON: %d" % parse_result)
		return

	var payload: Variant = json.get_data()
	if typeof(payload) != TYPE_DICTIONARY:
		return

	var msg_type: String = payload.get("type", "unknown")

	if msg_type == "auth_response":
		auth_response_received.emit(
			payload.get("success", false),
			payload.get("account_id", 0),
			payload.get("servers", []) as Array,
			payload.get("error", ""),
		)
	elif msg_type == "server_selection_response":
		# Preserve the language from auth params for kqz ticket sending
		# Use _lang_code as the source of truth (set during connect_to_server)
		var lang := _lang_code if _lang_code != "" else "es"
		server_selection_response_received.emit(
			payload.get("success", false),
			payload.get("ticket", ""),
			payload.get("host", ""),
			payload.get("ports", []),
			payload.get("error", ""),
			lang,
		)
	elif msg_type == "characters_received":
		# Characters should come from TCP, not WebSocket
		# This is handled by GameClient.characters_received signal
		pass
	elif msg_type == "error":
		error_received.emit(
			payload.get("code", "UNKNOWN_ERROR"),
			payload.get("message", "Error desconocido"),
		)

	message_received.emit(msg_type, payload)
