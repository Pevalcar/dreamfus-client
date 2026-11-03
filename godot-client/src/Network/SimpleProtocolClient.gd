class_name SimpleProtocolClient
extends Node

signal connection_state_changed(connected: bool)
signal message_received(message_type: String, payload: Dictionary)
signal error_received(error: String, details: String)
signal auth_response_received(
	success: bool,
	account_id: int,
	servers_json: Dictionary,
	error: String,
)
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

@export var host: String = "127.0.0.1"
@export var port: int = 5557
@export var connection_timeout: float = 10.0

var state: ClientState = ClientState.DISCONNECTED
var _websocket: WebSocketPeer = null
var _buffer: PackedByteArray = PackedByteArray()
var _pending_connections: Array[Callable] = []
var _last_ws_state: int = 0


func _ready() -> void:
	print("[SimpleProtocolClient] Inicializado")
	_websocket = WebSocketPeer.new()
	# Usar conect() con strings para compatibilidad con Godot 4.8 beta2
	_websocket.connect("connection_established", _on_connection_established)
	_websocket.connect("connection_closed", _on_connection_closed)
	_websocket.connect("data_received", _on_data_received_signal)


func _process(delta: float) -> void:
	if _websocket == null:
		return
	_websocket.poll()
	# Monitorear cambios de estado manualmente como fallback
	var current_state: int = _websocket.get_connection_state()
	if current_state != _last_ws_state:
		_last_ws_state = current_state
		if current_state == 2:  # CONNECTED
			if state != ClientState.CONNECTED:
				state = ClientState.CONNECTED
				connection_state_changed.emit(true)
				for pending_cb in _pending_connections:
					if pending_cb.is_valid():
						pending_cb.call()
				_pending_connections.clear()
		elif current_state == 3 or current_state == 4:  # CLOSING or CLOSED
			if state == ClientState.CONNECTING or state == ClientState.CONNECTED:
				state = ClientState.DISCONNECTED
				connection_state_changed.emit(false)


func connect_to_server(target_host: String, target_port: int) -> void:
	if state == ClientState.CONNECTED:
		connection_state_changed.emit(true)
		return

	self.host = target_host
	self.port = target_port
	state = ClientState.CONNECTING
	connection_state_changed.emit(false)

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
	if state != ClientState.CONNECTED:
		printerr("[SimpleProtocolClient] No conectado, no se puede enviar mensaje")
		return

	var json_str: String = JSON.stringify(payload)
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

	var err := _websocket.put_packet(packet)
	if err != OK:
		printerr("[SimpleProtocolClient] Error enviando paquete: %d" % err)


func send_auth_request(lang: String, token: String, install_id: String) -> void:
	var payload = { "type": "auth_request", "lang": lang, "token": token, "installId": install_id }
	send_message("auth_request", payload)


func send_server_selection(server_id: int, account_id: int, lang: String) -> void:
	var payload = {
		"type": "server_selection",
		"server_id": server_id,
		"account_id": account_id,
		"lang": lang,
	}
	send_message("server_selection", payload)


func _on_connection_established() -> void:
	state = ClientState.CONNECTED
	connection_state_changed.emit(true)
	for pending_cb in _pending_connections:
		if pending_cb.is_valid():
			pending_cb.call()
	_pending_connections.clear()
	print("[SimpleProtocolClient] Conexión establecida")


func _on_connection_closed(code: int = 0, reason: String = "") -> void:
	if state == ClientState.CONNECTING or state == ClientState.CONNECTED:
		state = ClientState.DISCONNECTED
		connection_state_changed.emit(false)
	print("[SimpleProtocolClient] Conexión cerrada: %s" % reason)


func _on_data_received_signal() -> void:
	if state != ClientState.CONNECTED:
		return

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
	var json := JSON.new()
	var parse_result := json.parse(json_str)
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
			payload.get("servers", { }),
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
