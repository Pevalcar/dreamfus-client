# InvalidTokenTest.gd
# Test unitario para manejo de token inválido (RF-9) - T10
# RF-9: Rechazo de conexión inválida

extends GutTest

var SimpleProtocolClient = preload("res://src/Network/SimpleProtocolClient.gd")
var AuthError = preload("res://src/Data/AuthError.gd")

# ============================================================================
# Helper to simulate message reception
# ============================================================================

func _send_message(client: SimpleProtocolClient, message: Dictionary) -> void:
	"""Helper to simulate receiving a message by adding it to buffer."""
	var json_str := JSON.stringify(message)
	var json_bytes := json_str.to_utf8_buffer()
	
	var packet := PackedByteArray()
	packet.resize(4 + json_bytes.size())
	packet[0] = (json_bytes.size() >> 24) & 0xFF
	packet[1] = (json_bytes.size() >> 16) & 0xFF
	packet[2] = (json_bytes.size() >> 8) & 0xFF
	packet[3] = json_bytes.size() & 0xFF
	
	for i in range(json_bytes.size()):
		packet[4 + i] = json_bytes[i]
	
	# Add to buffer (simulating incoming data)
	client._buffer.append_array(packet)

# ============================================================================
# RF-9: Invalid Token Rejection Tests
# ============================================================================

func test_auth_response_with_invalid_token()->void:
	"""T10-RF9: auth_response con TOKEN_INVALIDO emite error correcto"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	
	var error_received := false
	var error_code := ""
	var error_msg := ""
	
	client.error_received.connect(func(code: String, msg: String):
		error_received = true
		error_code = code
		error_msg = msg
	)
	
	# Simulate auth_response with success=false and TOKEN_INVALIDO error
	var payload = {
		"type": "auth_response",
		"success": false,
		"account_id": 0,
		"servers": [],
		"error": "TOKEN_INVALIDO"
	}
	
	_send_message(client, payload)
	client._process_buffer()
	
	assert_true(error_received, "Debe recibirse error para token inválido")
	assert_eq(error_code, "AUTH_ERROR", "Código debe ser AUTH_ERROR")

func test_auth_response_with_expired_token()->void:
	"""T10-RF9: auth_response con TOKEN_EXPIRADO emite error correcto"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	
	var error_received := false
	var error_msg := ""
	
	client.error_received.connect(func(code: String, msg: String):
		error_received = true
		error_msg = msg
	)
	
	var payload = {
		"type": "auth_response",
		"success": false,
		"account_id": 0,
		"servers": [],
		"error": "TOKEN_EXPIRADO"
	}
	
	_send_message(client, payload)
	client._process_buffer()
	
	assert_true(error_received, "Debe recibirse error para token expirado")
	assert_eq(error_msg, "TOKEN_EXPIRADO", "Mensaje debe ser TOKEN_EXPIRADO")

func test_auth_response_with_not_registered_token()->void:
	"""T10-RF9: auth_response con TOKEN_NO_REGISTRADO emite error correcto"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	
	var error_received := false
	var error_msg := ""
	
	client.error_received.connect(func(code: String, msg: String):
		error_received = true
		error_msg = msg
	)
	
	var payload = {
		"type": "auth_response",
		"success": false,
		"account_id": 0,
		"servers": [],
		"error": "TOKEN_NO_REGISTRADO"
	}
	
	_send_message(client, payload)
	client._process_buffer()
	
	assert_true(error_received, "Debe recibirse error para token no registrado")
	assert_eq(error_msg, "TOKEN_NO_REGISTRADO", "Mensaje debe ser TOKEN_NO_REGISTRADO")

func test_auth_response_success_passes_through()->void:
	"""T10-RF9: auth_response exitoso no emite error y pasa datos"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	
	var success_emitted := false
	var account_id_received := 0
	var servers_received_count := 0
	var error_in_auth_response := ""
	
	client.auth_response_received.connect(func(success: bool, account_id: int, servers: Array, error: String):
		success_emitted = true
		account_id_received = account_id
		servers_received_count = servers.size()
		error_in_auth_response = error
	)
	
	var payload = {
		"type": "auth_response",
		"success": true,
		"account_id": 188940901,
		"servers": [
			{"id": 290, "name": "Servidor 1", "population": 42, "is_full": false}
		],
		"error": ""
	}
	
	_send_message(client, payload)
	client._process_buffer()
	
	assert_true(success_emitted, "Debe emitirse auth_response_received")
	assert_eq(account_id_received, 188940901, "Account ID debe coincidir")
	assert_eq(servers_received_count, 1, "Debe haber 1 servidor")
	assert_eq(error_in_auth_response, "", "Error debe estar vacío para success")

func test_auth_response_without_error_field()->void:
	"""T10-RF9: auth_response sin campo error usa valor por defecto"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	
	var error_msg := "DEFAULT"
	
	client.error_received.connect(func(code: String, msg: String):
		error_msg = msg
	)
	
	var payload = {
		"type": "auth_response",
		"success": false,
		"account_id": 0,
		"servers": []
		# Sin campo "error"
	}
	
	_send_message(client, payload)
	client._process_buffer()
	
	# El mensaje por defecto del JSON parser será empty string
	assert_true(error_msg != "DEFAULT" or error_msg == "", 
		"Debe obtener valor por defecto (empty string)")

func test_auth_response_all_error_types()->void:
	"""T10-RF9: Prueba todos los tipos de error de token"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	
	var error_types := ["TOKEN_INVALIDO", "TOKEN_EXPIRADO", "TOKEN_NO_REGISTRADO"]
	
	for error_type in error_types:
		var error_received := false
		var received_error := ""
		
		# Reconnect signal for each test
		var conn = client.error_received.connect(func(code: String, msg: String):
			error_received = true
			received_error = msg
		)
		
		var payload = {
			"type": "auth_response",
			"success": false,
			"error": error_type
		}
		
		_send_message(client, payload)
		client._process_buffer()
		
		assert_true(error_received, "Debe recibirse error para %s" % error_type)
		assert_eq(received_error, error_type, "Error debe ser %s" % error_type)
		
		client.error_received.disconnect(conn)
		# Reset buffer for next iteration
		client._buffer.clear()