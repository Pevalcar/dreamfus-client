# ErrorHandlingTest.gd
# Test unitario para AuthErrorManager (T9 - RF-7)
# RF-7: Mensaje de error cuando el servidor está caído
# RF-9: Rechazo de conexión inválida

extends GutTest

var AuthErrorManager = preload("res://src/Core/AuthErrorManager.gd")
var AuthError = preload("res://src/Data/AuthError.gd")

# ============================================================================
# Setup
# ============================================================================

func before_each():
	# Crear instancia nueva para cada test
	_auth_manager = AuthErrorManager.new()
	add_child(_auth_manager)

# ============================================================================
# RF-7: WebSocket Timeout (2 segundos) - Servidor sin responder
# ============================================================================

func test_ws_timeout_shows_error_popup()->void:
	"""T9-RF7: Timeout WebSocket de 2s muestra popup 'Servidor sin responder'"""
	# Escuchar la señal
	var popup_shown := false
	_auth_manager.error_popup_shown.connect(func(code: String, msg: String):
		popup_shown = true
		assert_eq(code, "WS_TIMEOUT", "Código debe ser WS_TIMEOUT")
		assert_eq(msg, "Servidor sin responder", "Mensaje debe ser 'Servidor sin responder'")
	)
	
	# Iniciar timeout WebSocket
	_auth_manager.start_ws_timeout()
	
	# Simular paso del tiempo (esperar 2.1 segundos)
	await get_tree().create_timer(2.1).timeout
	
	assert_true(popup_shown, "Popup debe mostrarse después del timeout")

func test_ws_timeout_can_be_cancelled()->void:
	"""T9-RF7: Timeout WebSocket puede ser cancelado si server responde"""
	var popup_shown := false
	_auth_manager.error_popup_shown.connect(func(code: String, msg: String):
		popup_shown = true
	)
	
	# Iniciar timeout y cancelar antes de que expire
	_auth_manager.start_ws_timeout()
	_auth_manager.cancel_ws_timeout()
	
	# Esperar más de 2 segundos
	await get_tree().create_timer(2.5).timeout
	
	assert_false(popup_shown, "Popup no debe mostrarse si timeout fue cancelado")

# ============================================================================
# RF-7: TCP Timeout (5 segundos) - Servidor sin responder
# ============================================================================

func test_tcp_timeout_shows_error_popup()->void:
	"""T9-RF7: Timeout TCP de 5s muestra popup 'Servidor sin responder'"""
	var popup_shown := false
	_auth_manager.error_popup_shown.connect(func(code: String, msg: String):
		popup_shown = true
		assert_eq(code, "TCP_TIMEOUT", "Código debe ser TCP_TIMEOUT")
		assert_eq(msg, "Servidor sin responder", "Mensaje debe ser 'Servidor sin responder'")
	)
	
	_auth_manager.start_tcp_timeout()
	await get_tree().create_timer(5.5).timeout
	
	assert_true(popup_shown, "Popup debe mostrarse después del timeout TCP")

func test_tcp_timeout_can_be_cancelled()->void:
	"""T9-RF7: Timeout TCP puede ser cancelado si server responde"""
	var popup_shown := false
	_auth_manager.error_popup_shown.connect(func(code: String, msg: String):
		popup_shown = true
	)
	
	_auth_manager.start_tcp_timeout()
	_auth_manager.cancel_tcp_timeout()
	
	await get_tree().create_timer(6.0).timeout
	
	assert_false(popup_shown, "Popup no debe mostrarse si timeout TCP fue cancelado")

# ============================================================================
# RF-7: Connection Lost During Auth - Servidor sin responder
# ============================================================================

func test_connection_dropped_during_auth()->void:
	"""T9-RF7: Si la conexión se pierde durante autenticación, muestra popup"""
	var popup_shown := false
	_auth_manager.error_popup_shown.connect(func(code: String, msg: String):
		popup_shown = true
		assert_eq(code, "WS_DISCONNECTED", "Código debe ser WS_DISCONNECTED durante auth")
	)
	
	_auth_manager.handle_connection_dropped_during_auth()
	
	assert_true(popup_shown, "Popup debe mostrarse al perder conexión durante auth")

# ============================================================================
# RF-9: Invalid Token Rejection
# ============================================================================

func test_handle_invalid_token()->void:
	"""T9-RF9: Manejo de token inválido (TOKEN_INVALIDO)"""
	var error_emitted := false
	var emitted_error: AuthError = null
	
	_auth_manager.auth_error_occurred.connect(func(error: AuthError):
		error_emitted = true
		emitted_error = error
	)
	
	_auth_manager.handle_auth_rejection("TOKEN_INVALIDO", "Token de autenticación inválido")
	
	assert_true(error_emitted, "Se debe emitir error")
	assert_not_null(emitted_error, "Error no debe ser null")
	assert_eq(emitted_error.error_type, AuthError.ErrorType.TOKEN_INVALIDO, "Tipo de error correcto")

func test_handle_expired_token()->void:
	"""T9-RF9: Manejo de token expirado (TOKEN_EXPIRADO)"""
	var error_emitted := false
	var emitted_error: AuthError = null
	
	_auth_manager.auth_error_occurred.connect(func(error: AuthError):
		error_emitted = true
		emitted_error = error
	)
	
	_auth_manager.handle_auth_rejection("TOKEN_EXPIRADO", "Token de autenticación expirado")
	
	assert_true(error_emitted, "Se debe emitir error")
	assert_eq(emitted_error.error_type, AuthError.ErrorType.TOKEN_EXPIRADO, "Tipo de error correcto")

func test_handle_not_registered_token()->void:
	"""T9-RF9: Manejo de token no registrado (TOKEN_NO_REGISTRADO)"""
	var error_emitted := false
	var emitted_error: AuthError = null
	
	_auth_manager.auth_error_occurred.connect(func(error: AuthError):
		error_emitted = true
		emitted_error = error
	)
	
	_auth_manager.handle_auth_rejection("TOKEN_NO_REGISTRADO", "Token no registrado en el sistema")
	
	assert_true(error_emitted, "Se debe emitir error")
	assert_eq(emitted_error.error_type, AuthError.ErrorType.TOKEN_NO_REGISTRADO, "Tipo de error correcto")

func test_handle_unknown_error_type()->void:
	"""T9-RF9: Manejo de tipo de error desconocido"""
	var error_emitted := false
	
	_auth_manager.auth_error_occurred.connect(func(error: AuthError):
		error_emitted = true
	)
	
	_auth_manager.handle_auth_rejection("ERROR_DESCPCONOCIDO", "Error desconocido")
	
	assert_true(error_emitted, "Se debe emitir error incluso para tipo desconocido")

# ============================================================================
# Rate Limiting (RNF-9)
# ============================================================================

func test_rate_limit_exceeded()->void:
	"""T9-RNF9: Cuando se excede el límite (10 intentos/60s), se emite señal"""
	var rate_limited_emitted := false
	_auth_manager.rate_limit_exceeded.connect(func():
		rate_limited_emitted = true
	)
	
	# Simular 11 intentos fallidos
	for i in range(12):
		_auth_manager.record_failed_login()
	
	_auth_manager.check_rate_limit()
	
	assert_true(rate_limited_emitted, "Se debe emitir señal de rate limiting")

func test_remaining_attempts()->void:
	"""T9-RNF9: get_remaining_attempts devuelve correcto"""
	var initial = _auth_manager.get_remaining_attempts()
	assert_eq(initial, 10, "Inicialmente quedan 10 intentos")
	
	_auth_manager.record_failed_login()
	var after_one = _auth_manager.get_remaining_attempts()
	assert_eq(after_one, 9, "Después de 1 intento, quedan 9")

# ============================================================================
# Server Selection Errors (RF-5)
# ============================================================================

func test_server_selection_error_server_not_found()->void:
	"""T9-RF5: Error de servidor no encontrado"""
	var error_code := ""
	var error_msg := ""
	
	_auth_manager.server_selection_error.connect(func(code: String, msg: String):
		error_code = code
		error_msg = msg
	)
	
	_auth_manager.handle_server_selection_error("SERVIDOR_NO_EXISTE", "El servidor solicitado no existe")
	
	assert_eq(error_code, "SERVIDOR_NO_EXISTE", "Código de error correcto")
	assert_eq(error_msg, "El servidor solicitado no existe", "Mensaje correcto")

func test_server_selection_error_server_full()->void:
	"""T9-RF5: Error de servidor lleno"""
	var error_code := ""
	var error_msg := ""
	
	_auth_manager.server_selection_error.connect(func(code: String, msg: String):
		error_code = code
		error_msg = msg
	)
	
	_auth_manager.handle_server_selection_error("SERVIDOR_LLENO", "El servidor está lleno (máximo 200 jugadores)")
	
	assert_eq(error_code, "SERVIDOR_LLENO", "Código de error correcto")
	assert_eq(error_msg, "El servidor está lleno (máximo 200 jugadores)", "Mensaje correcto")

func test_server_selection_error_unauthorized()->void:
	"""T9-RF5: Error de cuenta no autorizada"""
	var error_code := ""
	var error_msg := ""
	
	_auth_manager.server_selection_error.connect(func(code: String, msg: String):
		error_code = code
		error_msg = msg
	)
	
	_auth_manager.handle_server_selection_error("CUENTA_NO_AUTORIZADA", "Cuenta no tiene permiso para este servidor")
	
	assert_eq(error_code, "CUENTA_NO_AUTORIZADA", "Código de error correcto")
	assert_eq(error_msg, "Cuenta no tiene permiso para este servidor", "Mensaje correcto")

# ============================================================================
# Convenience Methods for UI Integration
# ============================================================================

func test_show_error_with_code_and_message()->void:
	"""T9: show_error() emite popup con código y mensaje personalizados"""
	var popup_emitted := false
	_auth_manager.error_popup_shown.connect(func(code: String, msg: String):
		popup_emitted = true
		assert_eq(code, "TEST_ERROR", "Código personalizado")
		assert_eq(msg, "Mensaje de prueba", "Mensaje personalizado")
	)
	
	_auth_manager.show_error("TEST_ERROR", "Mensaje de prueba")
	
	assert_true(popup_emitted, "Popup debe emitirse")

func test_reset_all_timeouts()->void:
	"""T9: reset_all_timeouts detiene todos los timers"""
	_auth_manager.start_ws_timeout()
	_auth_manager.start_tcp_timeout()
	
	_auth_manager.reset_all_timeouts()
	
	# Verificar que los timers están detenidos
	assert_true(_auth_manager.is_ws_timeout_stopped(), "WebSocket timeout debe estar detenido")
	assert_true(_auth_manager.is_tcp_timeout_stopped(), "TCP timeout debe estar detenido")