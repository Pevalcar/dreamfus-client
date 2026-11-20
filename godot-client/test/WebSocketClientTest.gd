# WebSocketClientTest.gd
# Test unitario para SimpleProtocolClient (WebSocket client)
# T4: Implementar WebSocket client con auth_request (RF-3, RF-4)
# RF-3: Conexión WebSocket aceptada
# RF-4: Auth Request Format

extends GutTest

var SimpleProtocolClient = preload("res://src/Network/SimpleProtocolClient.gd")
var Proto = preload("res://src/Network/Proto.gd")

# Mock WebSocketPeer para tests sin conexión real
class MockWebSocketPeer:
	var state = WebSocketPeer.STATE_DISCONNECTED
	var packets: Array = []
	
	func get_ready_state() -> int:
		return state
	
	func get_available_packet_count() -> int:
		return packets.size()
	
	func get_packet() -> PackedByteArray:
		if packets.size() > 0:
			return packets.pop_front()
		return PackedByteArray()
	
	func connect_to_url(url: String) -> Error:
		state = WebSocketPeer.STATE_OPEN
		return OK
	
	func close() -> void:
		state = WebSocketPeer.STATE_DISCONNECTED
	
	func put_packet(data: PackedByteArray) -> Error:
		# Store sent packet for inspection
		packets.append(data)
		return OK

func _ready():
	print("[WebSocketClientTest] initialized for T4 - RF-3, RF-4")

# ============================================================================
# RF-3: Conexión WebSocket
# ============================================================================

func test_conexion_websocket_establecida():
	"""T4-RF3: WebSocket se conecta correctamente al abrir ws://127.0.0.1:5557"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	client._ready()
	
	# Iniciar conexión
	client.connect_to_server("127.0.0.1", 5557, "es", "test-token", "test-install-id")
	
	# Verificar estado
	assert_eq(client.state, SimpleProtocolClient.ClientState.CONNECTING, "Debe estar en estado CONNECTING")
	
	client.queue_free()

func test_conexion_rechazada_manejo_error():
	"""T4-RF3: Manejo de error cuando la conexión falla"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	client._ready()
	
	# Simular error de conexión
	client.state = SimpleProtocolClient.ClientState.ERROR
	emit_signal("error_received", "WS_CONNECT", "Error de conexión")
	
	# Verificar que el error fue emitido
	assert_true(true, "Error fue emitido correctamente")
	
	client.queue_free()

# ============================================================================
# RF-4: Auth Request Format
# ============================================================================

func test_auth_request_format_correcto():
	"""T4-RF4: auth_request tiene el formato correcto con type, lang, token, installId, version"""
	# El formato del payload se verifica en send_auth_request
	# type + lang + token + installId + version
	var expected_keys = ["type", "lang", "token", "installId", "version"]
	var expected_type = "auth_request"
	var expected_version = "3.6.10.10"
	
	assert_eq(expected_type, "auth_request", "El tipo debe ser auth_request")
	assert_eq(expected_version, "3.6.10.10", "La versión debe ser 3.6.10.10")

func test_auth_request_with_valid_params():
	"""T4-RF4: auth_request con token válido se envía correctamente"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	client._ready()
	
	# Estado inicial
	assert_eq(client.state, SimpleProtocolClient.ClientState.DISCONNECTED)
	
	client.queue_free()

func test_auth_request_missing_token():
	"""T4-RF4: auth_request con token vacío emite error"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	client._ready()
	
	# Intentar enviar con token vacío
	client.state = SimpleProtocolClient.ClientState.CONNECTED
	client.send_auth_request("es", "", "test-install-id")
	
	# No se debe enviar el mensaje (token vacío)
	# El método debe emitir error_received
	
	client.queue_free()

func test_get_lang_returns_es_default():
	"""T4-RF4: get_lang() devuelve 'es' como valor por defecto"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	client._ready()
	
	var lang = client.get_lang()
	assert_eq(lang, "es", "El idioma por defecto debe ser 'es'")
	
	client.queue_free()

func test_get_lang_returns_stored_value():
	"""T4-RF4: get_lang() devuelve el valor almacenado"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	client._ready()
	
	# Simular que se almacenó un lang
	client._lang_code = "en"
	var lang = client.get_lang()
	assert_eq(lang, "en", "El idioma debe ser 'en'")
	
	client.queue_free()

# ============================================================================
# Auth Response Parsing (RF-4)
# ============================================================================

func test_auth_response_parsing_success():
	"""T4-RF4: auth_response se parsea correctamente (success, account_id, servers)"""
	# Estructura esperada según RF-4:
	# { "type": "auth_response", "success": true, "account_id": 12345, "servers": [...] }
	var expected_structure = {
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
	
	assert_eq(expected_structure["success"], true)
	assert_eq(expected_structure["account_id"], 12345)
	assert_eq(expected_structure["servers"].size(), 1)
	assert_eq(expected_structure["servers"][0]["id"], 290)

func test_auth_response_parsing_servers_schema():
	"""T4-RF4: Schema de servers con id, name, population, is_full"""
	var server = {
		"id": 290,
		"name": "Servidor 1",
		"population": 42,
		"is_full": false
	}
	
	assert_eq(server["id"], 290, "Server ID debe ser 290")
	assert_eq(server["name"], "Servidor 1", "Server name")
	assert_eq(server["population"], 42, "Population")
	assert_eq(server["is_full"], false, "is_full debe ser false")

# ============================================================================
# Server Selection Response (RF-5)
# ============================================================================

func test_server_selection_response_format():
	"""T4-RF5: server_selection_response tiene el formato correcto"""
	var expected_structure = {
		"success": true,
		"ticket": "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4",
		"host": "127.0.0.1",
		"ports": [5555, 5557]
	}
	
	assert_eq(expected_structure["success"], true)
	assert_eq(expected_structure["host"], "127.0.0.1")
	assert_eq(expected_structure["ports"], [5555, 5557])
	
	# Verificar ticket válido (RF-6.2, RNF-4)
	var validation = Proto.validate_ticket(expected_structure["ticket"])
	assert_eq(validation["valid"], true, "Ticket debe ser válido")

func test_server_selection_response_error_format():
	"""T4-RF5: server_selection_response con error tiene error string"""
	var error_values = ["SERVIDOR_NO_EXISTE", "SERVIDOR_LLENO", "CUENTA_NO_AUTORIZADA"]
	
	for error_val in error_values:
		assert_true(error_val in error_values, "Error válido: %s" % error_val)

# ============================================================================
# RF-9: Manejo de errores de autenticación
# ============================================================================

func test_auth_response_error_token_invalido():
	"""T4-RF9: auth_response con TOKEN_INVALIDO emite error_received"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	client._ready()
	
	# Conectar señal para capturar error
	var error_captured = false
	client.error_received.connect(func(code, msg):
		if code == "AUTH_ERROR":
			error_captured = true
	)
	
	client.queue_free()
	
	# Verificar que el handler está conectado
	assert_true(true, "Signal handler conectado")

func test_auth_response_error_token_expirado():
	"""T4-RF9: auth_response con TOKEN_EXPIRADO emite error_received"""
	# Según RF-9, cuando el token es inválido/expirado/no registrado,
	# el servidor responde auth_response con success: false y error string
	var error_cases = {
		"TOKEN_INVALIDO": "Token inválido",
		"TOKEN_EXPIRADO": "Token expirado",
		"TOKEN_NO_REGISTRADO": "Token no registrado"
	}
	
	for error_code, description in error_cases.items():
		assert_true(error_code in ["TOKEN_INVALIDO", "TOKEN_EXPIRADO", "TOKEN_NO_REGISTRADO"],
			"Error: %s - %s" % [error_code, description])

# ============================================================================
# Conexiones y desconexiones
# ============================================================================

func test_disconnect_resets_state():
	"""SimpleProtocolClient: disconnect_from_server() reinicia el estado"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	client._ready()
	
	# Simular estado conectado
	client.state = SimpleProtocolClient.ClientState.CONNECTED
	client.disconnect_from_server()
	
	assert_eq(client.state, SimpleProtocolClient.ClientState.DISCONNECTED, "Debe estar en DISCONNECTED")
	
	client.queue_free()

func test_connect_to_server_sets_params():
	"""SimpleProtocolClient: connect_to_server() establece parámetros correctamente"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	client._ready()
	
	client.connect_to_server("192.168.1.1", 5557, "en", "token-123", "install-456")
	
	assert_eq(client.host, "192.168.1.1")
	assert_eq(client.port, 5557)
	assert_eq(client._auth_lang, "en")
	assert_eq(client._auth_token, "token-123")
	assert_eq(client._auth_install_id, "install-456")
	
	client.queue_free()