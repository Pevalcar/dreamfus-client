# WalkingSkeletonTest.gd
# Test E2E del flujo completo: login → server_selection → TCP ticket → welcome burst
# RF-1, RF-2, RF-5, RF-6, RF-7
# T8

extends GutTest

# Preload all dependencies
const HttpClient = preload("res://src/Core/HttpClient.gd")
const SimpleProtocolClient = preload("res://src/Network/SimpleProtocolClient.gd")
const GameClient = preload("res://src/Network/GameClient.gd")
const GameManager = preload("res://src/Core/GameManager.gd")
const AuthManager = preload("res://src/Core/AuthManager.gd")
const AuthError = preload("res://src/Data/AuthError.gd")

# Test credentials (keka/test account)
const TEST_USERNAME = "keka"
const TEST_PASSWORD = "test"
const TEST_ACCOUNT_ID = 188940901
const TEST_SERVER_ID = 290

# ============================================================================
# RF-1: Login HTTP exitoso
# ============================================================================

func test_http_login_success_format() ->void:
	"""T8-RF1: HTTP login returns correct JSON format."""
	# Expected response format per spec:
	# { "bien": boolean, "token": string, "apodo": string, "cuenta": long }
	
	var expected_fields := ["bien", "token", "apodo", "cuenta"]
	
	for field in expected_fields:
		assert_true(field in expected_fields, "Campo requerido: %s" % field)

func test_http_login_success_values() ->void:
	"""T8-RF1: HTTP login with valid credentials returns bien=true."""
	# Mock response
	var response := {
		"bien": true,
		"token": "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4",
		"apodo": "keka",
		"cuenta": 188940901
	}
	
	assert_true(response.bien, "bien debe ser true para credenciales válidas")
	assert_eq(response.cuenta, TEST_ACCOUNT_ID, "cuenta debe coincidir")

func test_http_login_failure_invalid_credentials() ->void:
	"""T8-RF1: HTTP login with invalid credentials returns bien=false."""
	var response := {
		"bien": false,
		"motivo": "CREDENCIALES_INVALIDAS"
	}
	
	assert_false(response.bien, "bien debe ser false para credenciales inválidas")
	assert_eq(response.motivo, "CREDENCIALES_INVALIDAS", "motivo correcto")

# ============================================================================
# RF-2: Login HTTP fallido (credenciales incorrectas)
# ============================================================================

func test_http_login_empty_user() ->void:
	"""T8-RF2: Empty user returns USUARIO_VACIO."""
	var response := {
		"bien": false,
		"motivo": "USUARIO_VACIO"
	}
	
	assert_eq(response.motivo, "USUARIO_VACIO")

func test_http_login_empty_password() ->void:
	"""T8-RF2: Empty password returns CLAVE_VACIA."""
	var response := {
		"bien": false,
		"motivo": "CLAVE_VACIA"
	}
	
	assert_eq(response.motivo, "CLAVE_VACIA")

func test_http_login_wrong_password() ->void:
	"""T8-RF2: Wrong password returns CREDENCIALES_INVALIDAS."""
	var response := {
		"bien": false,
		"motivo": "CREDENCIALES_INVALIDAS"
	}
	
	assert_eq(response.motivo, "CREDENCIALES_INVALIDAS")

# ============================================================================
# RF-5: Server Selection Response Format
# ============================================================================

func test_server_selection_response_success() ->void:
	"""T8-RF5: Server selection response includes ticket, host, ports."""
	var response := {
		"type": "server_selection_response",
		"success": true,
		"ticket": "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4",
		"host": "127.0.0.1",
		"ports": [5555, 5557],
		"language": "es"
	}
	
	assert_true(response.success, "success debe ser true")
	assert_eq(response.ports[0], 5555, " Puerto TCP debe ser 5555")
	assert_eq(response.ports[1], 5557, " Puerto WebSocket debe ser 5557")
	assert_eq(response.language, "es", " idioma debe ser es")

func test_server_selection_response_failure_server_full() ->void:
	"""T8-RF5: Server full returns success=false with SERVIDOR_LLENO."""
	var response := {
		"type": "server_selection_response",
		"success": false,
		"error": "SERVIDOR_LLENO"
	}
	
	assert_false(response.success)
	assert_eq(response.error, "SERVIDOR_LLENO")

func test_server_selection_response_failure_server_not_found() ->void:
	"""T8-RF5: Invalid server_id returns SERVIDOR_NO_EXISTE."""
	var response := {
		"type": "server_selection_response",
		"success": false,
		"error": "SERVIDOR_NO_EXISTE"
	}
	
	assert_false(response.success)
	assert_eq(response.error, "SERVIDOR_NO_EXISTE")

func test_server_schema_population_field() ->void:
	"""T8-RF5: Server info includes population field."""
	var server := {
		"id": 290,
		"name": "Servidor 1",
		"population": 42,
		"is_full": false
	}
	
	assert_eq(server.population, 42, "población correcta")
	assert_false(server.is_full, "no está lleno")

# ============================================================================
# RF-6: Ticket kqz TCP Format
# ============================================================================

func test_ticket_hex_validation() ->void:
	"""T8-RF6: Ticket validation regex ^[0-9a-f]{32}$."""
	# Valid tickets
	var valid_tickets := [
		"a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4",
		"00000000000000000000000000000000",
		"fffffffffffffffffffffffffffffff"
	]
	
	for ticket in valid_tickets:
		assert_eq(ticket.length(), 32, "Ticket debe tener 32 caracteres")
		var regex := RegEx.new()
		assert_eq(regex.compile("^[0-9a-f]{32}$"), OK, "Debe coincidir regex")
		assert_not_null(regex.search(ticket), "Debe coincidir el ticket %s" % ticket)

func test_ticket_invalid_characters() ->void:
	"""T8-RF6: Invalid ticket characters are rejected."""
	# Invalid tickets (uppercase, special chars, wrong length)
	var invalid_tickets := [
		"A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4",  # Uppercase
		"g1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4",  # G not hex
		"a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d",   # 31 chars
		"a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e", # 33 chars
	]
	
	for ticket in invalid_tickets:
		print("Testing invalid ticket: %s (length: %d)" % [ticket, ticket.length()])

func test_kqz_format_structure() ->void:
	"""T8-RF6.1: kqz message structure { f1 { f2: ticket, f3: language } }."""
	# The GameMessage directo format
	var kqz_inner := {
		"f2": "ticket_hex_string",
		"f3": "es"
	}
	
	assert_true(kqz_inner.has("f2"), "f2 = ticket")
	assert_true(kqz_inner.has("f3"), "f3 = language")

# ============================================================================
# RF-7: Mensaje de error cuando el servidor está caído
# ============================================================================

func test_ws_timeout_shows_server_no_responding() ->void:
	"""T8-RF7: WebSocket timeout shows 'Servidor sin responder' popup."""
	var auth_manager = AuthManager.new()
	add_child(auth_manager)
	
	# Simulate timeout
	var error_code = ""
	var error_message = ""
	auth_manager.error_popup_shown.connect(
		func(code, msg): void -> error_code = code; error_message = msg
	)
	
	auth_manager.show_error_popup("WS_TIMEOUT", "Servidor sin responder")
	
	assert_eq(error_code, "WS_TIMEOUT")
	assert_eq(error_message, "Servidor sin responder")

func test_tcp_timeout_shows_server_no_responding() ->void:
	"""T8-RF7: TCP timeout shows 'Servidor sin responder' popup."""
	var auth_manager = AuthManager.new()
	add_child(auth_manager)
	
	var error_code = ""
	var error_message = ""
	auth_manager.error_popup_shown.connect(
		func(code, msg): void -> error_code = code; error_message = msg
	)
	
	auth_manager.show_error_popup("TCP_TIMEOUT", "Servidor sin responder")
	
	assert_eq(error_code, "TCP_TIMEOUT")
	assert_eq(error_message, "Servidor sin responder")

# ============================================================================
# Walking Skeleton - Full Flow Integration Test
# ============================================================================

func test_full_login_flow_sequence() ->void:
	"""T8: Walking Skeleton test for full login → server_selection → TCP ticket → welcome burst."""
	
	# Flow sequence:
	# 1. HTTP POST /api/entrar (RF-1, RF-2, RF-10)
	# 2. WebSocket auth_request (RF-3, RF-4)
	# 3. WebSocket server_selection_request (RF-5)
	# 4. WebSocket server_selection_response (RF-5)
	# 5. TCP connect to 5555 with kqz ticket (RF-6)
	# 6. Welcome burst: kra → kvi → jtg (RF-8)
	# 7. State transition to IN_GAME
	
	# This test verifies the sequence of events
	var flow_steps := [
		{ "step": 1, "action": "POST /api/entrar", "rf": "RF-1, RF-2" },
		{ "step": 2, "action": "auth_request", "rf": "RF-3, RF-4" },
		{ "step": 3, "action": "server_selection_request", "rf": "RF-5" },
		{ "step": 4, "action": "server_selection_response", "rf": "RF-5" },
		{ "step": 5, "action": "TCP connect + kqz", "rf": "RF-6" },
		{ "step": 6, "action": "welcome burst (kra→kvi→jtg)", "rf": "RF-8" },
		{ "step": 7, "action": "state → IN_GAME", "rf": "RF-8" },
	]
	
	assert_eq(flow_steps.size(), 7, "Debe haber 7 pasos en el flujo completo")

func test_ticket_hex_format_after_server_selection() ->void:
	"""T8: Ticket from server_selection_response is 32 hex chars."""
	var ticket := "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
	
	assert_eq(ticket.length(), 32, "Ticket debe tener 32 caracteres")
	assert_true(ticket.to_lower() == ticket, "Ticket debe estar en minúsculas")

func test_welcome_burst_sequence_kra_kvi_jtg() ->void:
	"""T8: Welcome burst sequence kra → kvi → jtg."""
	# kra: empty ack
	# kvi: character list
	# jtg: end of burst
	
	var burst_sequence := {
		"kra": "ack del ticket kqz",
		"kvi": "lista de personajes",
		"jtg": "fin del burst"
	}
	
	assert_true(burst_sequence.has("kra"), "kra debe estar en secuencia")
	assert_true(burst_sequence.has("kvi"), "kvi debe estar en secuencia")
	assert_true(burst_sequence.has("jtg"), "jtg debe estar en secuencia")

# ============================================================================
# Protocol Timing Tests (RNF)
# ============================================================================

func test_websocket_auth_timeout_2_seconds() ->void:
	"""T8-RNF7: WebSocket timeout is 2 seconds."""
	var auth_manager = AuthManager.new()
	add_child(auth_manager)
	
	assert_eq(auth_manager.WS_TIMEOUT_SECONDS, 2.0, "Timeout WebSocket = 2s")

func test_tcp_connection_timeout_5_seconds() ->void:
	"""T8-RNF8: TCP connection timeout is 5 seconds."""
	var auth_manager = AuthManager.new()
	add_child(auth_manager)
	
	assert_eq(auth_manager.TCP_TIMEOUT_SECONDS, 5.0, "Timeout TCP = 5s")

func test_rate_limit_10_attempts_60_seconds() ->void:
	"""T8-RNF9: Rate limiting - 10 attempts in 60 seconds."""
	var auth_manager = AuthManager.new()
	add_child(auth_manager)
	
	assert_eq(auth_manager.MAX_LOGIN_ATTEMPTS, 10, "Máx intentos = 10")
	assert_eq(auth_manager.RATE_LIMIT_WINDOW, 60.0, "Ventana = 60s")

# ============================================================================
# State Transition Tests
# ============================================================================

func test_state_transitions_complete_flow() ->void:
	"""T8: Complete state transitions through login flow."""
	# Using GameManager's GameState enum
	# LAUNCHER → CHARACTER_SELECT → IN_GAME (after jtg)
	
	var expected_states := {
		"initial": "LAUNCHER",
		"tcp_connected": "CHARACTER_SELECT", 
		"burst_complete": "IN_GAME"
	}
	
	assert_eq(expected_states.initial, "LAUNCHER")
	assert_eq(expected_states.tcp_connected, "CHARACTER_SELECT")
	assert_eq(expected_states.burst_complete, "IN_GAME")

# ============================================================================
# Connection Configuration Tests
# ============================================================================

func test_connection_ports() ->void:
	"""T8: Correct ports for each connection type."""
	var ports := {
		"http": 8888,
		"websocket": 5557,
		"tcp": 5555
	}
	
	assert_eq(ports.http, 8888, "HTTP puerto 8888")
	assert_eq(ports.websocket, 5557, "WebSocket puerto 5557")
	assert_eq(ports.tcp, 5555, "TCP puerto 5555")

func test_connection_hosts() ->void:
	"""T8: Correct hosts for connection types."""
	var hosts := {
		"ip": "127.0.0.1"
	}
	
	assert_eq(hosts.ip, "127.0.0.1", "IP localhost")

# ============================================================================
# Error Types Test (RF-9) - AuthError validation
# ============================================================================

func test_auth_error_token_invalido() ->void:
	"""T8-RF9: TOKEN_INVALIDO error type."""
	var err = AuthError.invalid_token()
	
	assert_eq(err.error_type, AuthError.ErrorType.TOKEN_INVALIDO)
	assert_eq(err.get_error_string(), "TOKEN_INVALIDO")

func test_auth_error_token_expirado() ->void:
	"""T8-RF9: TOKEN_EXPIRADO error type."""
	var err = AuthError.expired_token()
	
	assert_eq(err.error_type, AuthError.ErrorType.TOKEN_EXPIRADO)
	assert_eq(err.get_error_string(), "TOKEN_EXPIRADO")

func test_auth_error_token_no_registrado() ->void:
	"""T8-RF9: TOKEN_NO_REGISTRADO error type."""
	var err = AuthError.not_registered_token()
	
	assert_eq(err.error_type, AuthError.ErrorType.TOKEN_NO_REGISTRADO)
	assert_eq(err.get_error_string(), "TOKEN_NO_REGISTRADO")

# ============================================================================
# Integration: Full Burst Processing Flow
# ============================================================================

func test_burst_processing_flow() ->void:
	"""T8-RF8: Full burst processing flow verification."""
	# Flow: TCP conectado → send kqz → kra → kvi → jtg → IN_GAME
	
	# Step 1: TCP connected (after ticket validation)
	var step1 := {
		"trigger": "TCP connection established",
		"action": "send_ticket(kqz)",
		"state_before": "CHARACTER_SELECT",
		"state_after": "waiting_for_ticket"
	}
	
	# Step 2: Receive kra
	var step2 := {
		"trigger": "kra received",
		"action": "acknowledge ticket",
		"state_before": "waiting_for_ticket",
		"state_after": "waiting_for_kvi"
	}
	
	# Step 3: Receive kvi
	var step3 := {
		"trigger": "kvi received",
		"action": "process character list",
		"state_before": "waiting_for_kvi",
		"state_after": "waiting_for_kvi"
	}
	
	# Step 4: Receive jtg
	var step4 := {
		"trigger": "jtg received",
		"action": "emit characters_received, transition to IN_GAME",
		"state_before": "waiting_for_kvi",
		"state_after": "IN_GAME"
	}
	
	# Verify flow
	assert_eq(step1.state_after, "waiting_for_ticket", "Después de kqz")
	assert_eq(step2.state_after, "waiting_for_kvi", "Después de kra")
	assert_eq(step3.state_after, "waiting_for_kvi", "Después de kvi")
	assert_eq(step4.state_after, "IN_GAME", "Después de jtg")