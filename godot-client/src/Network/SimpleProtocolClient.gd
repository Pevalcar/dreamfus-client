# SimpleProtocolClient - WebSocket client for game server communication
# Not using class_name to avoid conflicts with scene node assignments in Godot 4.8 beta2
class_name SimpleProtocolClient
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
)

enum ClientState {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	ERROR,
}

# WebSocketPeer.State values (Godot 4.8 beta2)
const STATE_CONNECTING: int = 0
const STATE_OPEN: int = 1
const STATE_CLOSING: int = 2
const STATE_CLOSED: int = 3

@export var host: String = "127.0.0.1"
@export var port: int = 5557
@export var connection_timeout: float = 10.0

var state: ClientState = ClientState.DISCONNECTED
var _websocket: WebSocketPeer = null
var _buffer: PackedByteArray = PackedByteArray()
var _pending_connections: Array = []


func _ready() -> void:
	print("[SimpleProtocolClient] Inicializado")
	_websocket = WebSocketPeer.new()
	_pending_connections = []


func _process(delta: float) -> void:
	if _websocket == null:
		return
	_websocket.poll()

	# Polling-based state management (compatible with Godot 4.8 beta2)
	var ws_state: int = _websocket.get_ready_state()
	match ws_state:
		STATE_OPEN:
			if state != ClientState.CONNECTED:
				state = ClientState.CONNECTED
				connection_state_changed.emit(true)
				for pending_cb in _pending_connections:
					if pending_cb.is_valid():
						pending_cb.call()
				_pending_connections.clear()
			# Process any received data
			_process_received_data()
		STATE_CLOSING, STATE_CLOSED:
			if state == ClientState.CONNECTING or state == ClientState.CONNECTED:
				state = ClientState.DISCONNECTED
				connection_state_changed.emit(false)
		_:
			if state == ClientState.CONNECTING:
				state = ClientState.DISCONNECTED
				connection_state_changed.emit(false)


func connect_to_server(target_host: String, target_port: int) -> void:
	if state == ClientState.CONNECTED:
		connection_state_changed.emit(true)
		return

	self.host = target_host
	self.port = target_port
	state = ClientState.CONNECTING
	# NO emitir aquí - esperar a que _process detecte el estado real del WebSocket
	# Esto evita que los 'await' captúren esta emisión prematura

	var url: String = "ws://%s:%d" % [host, port]
	var err := _websocket.connect_to_url(url)
	if err != OK:
		state = ClientState.ERROR
		connection_state_changed.emit(false)
		error_received.emit("WS_CONNECT", "Error al conectar WebSocket: %d" % err)


func disconnect_from_server() -> void:
	if _websocket != null and state == ClientState.CONNECTED:
		_websocket.close()
	_buffer.clear()
	state = ClientState.DISCONNECTED


func send_message(message_type: String, payload: Dictionary) -> void:
	print(
		"[SimpleProtocolClient] send_message: type=%s, state=%s, ws_state=%s"
		% [message_type, state, _websocket.get_ready_state() if _websocket else "null"]
	)
	if state != ClientState.CONNECTED:
		printerr(
			"[SimpleProtocolClient] No conectado, no se puede enviar mensaje (state=%s)" % state
		)
		return

	var json_str: String = JSON.stringify(payload)
	print("[SimpleProtocolClient] Enviando JSON: %s" % json_str.substr(0, 100))
	var json_bytes: PackedByteArray = json_str.to_utf8_buffer()

	# Crear paquete con prefijo de longitud de 4 bytes (big-endian)
	var packet := PackedByteArray()
	packet.resize(4 + json_bytes.size())

	# Big-endian length prefix
	packet[0] = (json_bytes.size() >> 24) & 0xFF
	packet[1] = (json_bytes.size() >> 16) & 0xFF
	packet[2] = (json_bytes.size() >> 8) & 0xFF
	packet[3] = json_bytes.size() & 0xFF

	# Copiar bytes JSON
	for i in range(json_bytes.size()):
		packet[4 + i] = json_bytes[i]

	print("[SimpleProtocolClient] Enviando paquete de %d bytes" % packet.size())
	var err := _websocket.put_packet(packet)
	if err != OK:
		printerr("[SimpleProtocolClient] Error enviando paquete: %d" % err)


func send_auth_request(lang: String, token: String, install_id: String) -> void:
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
	# Necesitamos al menos 4 bytes para leer el largo
	if _buffer.size() < 4:
		return

	# Leer longitud del mensaje (primeros 4 bytes - big endian)
	var msg_len: int = (_buffer[0] << 24) | (_buffer[1] << 16) | (_buffer[2] << 8) | _buffer[3]

	# Verificar si tenemos todos los bytes
	if _buffer.size() < 4 + msg_len:
		return

	# Extraer el payload JSON
	var json_bytes := _buffer.slice(4, 4 + msg_len)
	var json_str: String = json_bytes.get_string_from_utf8()

	# Limpiar el buffer
	_buffer = _buffer.slice(4 + msg_len)

	# Parsear JSON
	var json: JSON = JSON.new()
	var parse_result: int = json.parse(json_str)
	if parse_result != Error.OK:
		error_received.emit("JSON_PARSE", "Error parseando JSON: %d" % parse_result)
		return

	var payload: Variant = json.get_data()
	if typeof(payload) != TYPE_DICTIONARY:
		return

	var msg_type: String = payload.get("type", "unknown")

	# Emitir señales específicas según el tipo de mensaje
	if msg_type == "auth_response":
		auth_response_received.emit(
			payload.get("success", false),
			payload.get("account_id", 0),
			payload.get("servers", []) as Array,
			payload.get("error", ""),
		)
	elif msg_type == "server_selection_response":
		server_selection_response_received.emit(
			payload.get("success", false),
			payload.get("ticket", ""),
			payload.get("host", ""),
			payload.get("ports", []),
			payload.get("error", ""),
		)
	elif msg_type == "error":
		error_received.emit(
			payload.get("code", "UNKNOWN_ERROR"),
			payload.get("message", "Error desconocido"),
		)

	message_received.emit(msg_type, payload)
