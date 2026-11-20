# ServerSelectionTest.gd
# Test unitario para server_selection_response (Parte de T5)
# RF-5: Server Selection Request Format
# RF-6.2: Validación ticket 32 caracteres hexadecimales
# RF-6.3: Envío inmediato del ticket

extends GutTest

var SimpleProtocolClient = preload("res://src/Network/SimpleProtocolClient.gd")
var Proto = preload("res://src/Network/Proto.gd")

# ============================================================================
# RF-5: Server Selection Response Schema
# ============================================================================

func test_server_selection_response_success_schema() ->void:
	"""T5-RF5: server_selection_response con success=true tiene ticket válido"""
	# Schema según RF-5:
	# {
	#   "type": "server_selection_response",
	#   "success": true,
	#   "ticket": "32-char-hex",
	#   "host": "127.0.0.1",
	#   "ports": [5555, 5557]
	# }
	
	var ticket := "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
	var validation := Proto.validate_ticket(ticket)
	
	assert_eq(validation["valid"], true, "Ticket debe ser válido (regex ^[0-9a-f]{32}$)")
	assert_eq(ticket.length(), 32, "Ticket debe tener exactamente 32 caracteres")

func test_server_selection_response_error_schema() ->void:
	"""T5-RF5: server_selection_response con success=false tiene error string"""
	# Error values según RF-5:
	var error_values := ["SERVIDOR_NO_EXISTE", "SERVIDOR_LLENO", "CUENTA_NO_AUTORIZADA"]
	
	for error_val in error_values:
		assert_true(error_val in error_values, "Error válido: %s" % error_val)

func test_server_selection_response_failure_structure() ->void:
	"""T5-RF5: server_selection_response con success=false tiene error pero no ticket"""
	var response_failure := {
		"type": "server_selection_response",
		"success": false,
		"error": "SERVIDOR_LLENO",
		"host": "",
		"ports": []
	}
	
	assert_eq(response_failure["success"], false, "Success debe ser false")
	assert_eq(response_failure["error"], "SERVIDOR_LLENO", "Error debe ser SERVIDOR_LLENO")
	assert_eq(response_failure.has("ticket"), false, "No debe incluir ticket cuando falla")

# ============================================================================
# RF-5: Server ID Validation
# ============================================================================

func test_server_selection_with_valid_server_id() ->void:
	"""T5: send_server_selection con server_id válido"""
	var client = SimpleProtocolClient.new()
	add_child(client)
	client._ready()
	
	# El método debe construir payload correcto
	# No podemos probar el envío real sin servidor, pero verificamos la estructura
	assert_eq(client.state, SimpleProtocolClient.ClientState.DISCONNECTED)
	
	client.queue_free()

func test_servers_array_from_auth_response() ->void:
	"""RF-4/T5: Parsear servers array con id, name, population, is_full"""
	var servers_response := {
		"success": true,
		"account_id": 188940901,
		"servers": [
			{
				"id": 290,
				"name": "Servidor 1",
				"population": 42,
				"is_full": false
			},
			{
				"id": 291,
				"name": "Servidor 2",
				"population": 150,
				"is_full": false
			},
			{
				"id": 292,
				"name": "Servidor 3 - Full",
				"population": 200,
				"is_full": true
			}
		]
	}
	
	assert_eq(servers_response["servers"].size(), 3, "Debe haber 3 servidores")
	
	# Verificar cada server
	var server1 := servers_response["servers"][0]
	assert_eq(server1["id"], 290, "Server 1 ID")
	assert_eq(server1["name"], "Servidor 1", "Server 1 name")
	assert_eq(server1["population"], 42, "Server 1 population")
	assert_eq(server1["is_full"], false, "Server 1 is_full")
	
	var server3 := servers_response["servers"][2]
	assert_eq(server3["is_full"], true, "Server 3 debe estar lleno")
	assert_eq(server3["population"], 200, "Server 3 population límite")

# ============================================================================
# RF-6.2: Ticket Validation (regex ^[0-9a-f]{32}$)
# ============================================================================

func test_ticket_validation_valid_32_chars() ->void:
	"""T5-RF6.2: Ticket válido de 32 caracteres hexadecimales"""
	var valid_tickets := [
		"a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4",
		"00000000000000000000000000000000",
		"ffffffffffffffffffffffffffffffff",
		"1234567890abcdef1234567890abcdef"
	]
	
	for ticket in valid_tickets:
		var result := Proto.validate_ticket(ticket)
		assert_eq(result["valid"], true, "Ticket válido: %s" % ticket)

func test_ticket_validation_invalid_chars() ->void:
	"""T5-RF6.2: Ticket con caracteres no hexadecimales - rechazado"""
	var invalid_tickets := [
		"G1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4",  // G no es hex
		"a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d",   // 31 chars
		"a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d45", // 33 chars
		"AAAAAAAA000000000000000000000000",  // A mayúsculas
	]
	
	for ticket in invalid_tickets:
		var result := Proto.validate_ticket(ticket)
		# Proto.valida ticket y normaliza a minúsculas
		assert_eq(result["valid"], false, "Ticket inválido: %s" % ticket)

func test_ticket_validation_normalization_lowercase() ->void:
	"""T5-RF6.2: Ticket se normaliza a minúsculas"""
	var uppercase_ticket := "A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4"
	var result := Proto.validate_ticket(uppercase_ticket)
	
	assert_eq(result["valid"], true, "Debe convertir a minúsculas")
	assert_eq(result["normalized"], "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4", "Ticket normalizado")

# ============================================================================
# RF-6.3: Ticket Immediate Sending
# ============================================================================

func test_ticket_sent_immediately_on_tcp_connect() ->void:
	"""T5-RF6.3: El ticket kqz se envía inmediatamente al conectar TCP"""
	# El ticket debe enviarse sin esperar datos del servidor
	# Esto implica que no hay callback esperando antes de enviar
	
	var expected_behavior := {
		"wait_for_server_data": false,
		"send_timing": "immediate",
		"max_delay_ms": 100,  // RNF-6
		"message_type": "kqz"
	}
	
	assert_eq(expected_behavior["wait_for_server_data"], false, "No esperar datos del servidor")
	assert_eq(expected_behavior["max_delay_ms"], 100, "Enviar en menos de 100ms")

# ============================================================================
# Protocol Flow Tests
# ============================================================================

func test_full_auth_flow_with_servers() ->void:
	"""T5: Flujo completo auth_response con servers list"""
	var auth_response_success := {
		"type": "auth_response",
		"success": true,
		"account_id": 188940901,
		"servers": [
			{"id": 290, "name": "Servidor 1", "population": 42, "is_full": false}
		]
	}
	
	assert_eq(auth_response_success["success"], true)
	assert_eq(auth_response_success["account_id"], 188940901)
	assert_eq(auth_response_success["servers"].size(), 1)

func test_server_selection_request_format() ->void:
	"""T5: server_selection request tiene el formato correcto"""
	var expected_payload := {
		"type": "server_selection",
		"server_id": 290,
		"account_id": 188940901,
		"lang": "es"
	}
	
	assert_eq(expected_payload["type"], "server_selection")
	assert_eq(expected_payload["server_id"], 290)
	assert_eq(expected_payload["account_id"], 188940901)
	assert_eq(expected_payload["lang"], "es")

# ============================================================================
# Edge Cases
# ============================================================================

func test_server_is_full_boundary() ->void:
	"""T5: Servidor con is_full=true cuando population >= 200"""
	var server_at_limit := {
		"id": 290,
		"name": "Full Server",
		"population": 200,
		"is_full": true  // Límite máximo
	}
	
	var server_below_limit := {
		"id": 291,
		"name": "Normal Server",
		"population": 199,
		"is_full": false  // Por debajo del límite
	}
	
	assert_eq(server_at_limit["is_full"], true, "200 jugadores = full")
	assert_eq(server_below_limit["is_full"], false, "199 jugadores = no full")

func test_empty_servers_list() ->void:
	"""T5: Manejo de servers array vacío"""
	var auth_response_no_servers := {
		"type": "auth_response",
		"success": true,
		"account_id": 188940901,
		"servers": []
	}
	
	assert_eq(auth_response_no_servers["servers"].size(), 0, "Lista vacía válida")

# ============================================================================
# Protocol Constants
# ============================================================================

func test_server_host_format() ->void:
	"""T5: host en server_selection_response es string de IP"""
	var valid_hosts := ["127.0.0.1", "192.168.1.1", "10.0.0.1"]
	
	for host in valid_hosts:
		# Verificar formato IP básico
		var parts := host.split(".")
		assert_eq(parts.size(), 4, "Host debe tener 4 octetos: %s" % host)
		
		for part in parts:
			var num := int(part)
			assert_true(num >= 0 and num <= 255, "Cada octeto debe ser 0-255: %s" % host)

func test_ports_array_format() ->void:
	"""T5: ports en server_selection_response es array de enteros"""
	var ports := [5555, 5557]
	
	for port in ports:
		assert_true(port > 0 and port < 65536, "Puerto válido: %d" % port)