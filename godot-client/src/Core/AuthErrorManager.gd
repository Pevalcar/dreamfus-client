# AuthErrorManager.gd
# Gestor centralizado de errores de autenticación
# RF-7: Mensaje de error cuando el servidor está caído
# RF-9: Rechazo de conexión inválida
# RNF-7: Timeout WebSocket 2s
# RNF-8: Timeout TCP 5s
# RNF-9: Rate limiting 10/60s

extends Node

## AuthError class for error objects
const AuthError = preload("res://src/Data/AuthError.gd")

## Singleton instance
static var instance: AuthErrorManager = null

## Connection timeout configuration (RNF-7, RNF-8)
const WS_TIMEOUT_SECONDS := 2.0
const TCP_TIMEOUT_SECONDS := 5.0

## Rate limiting configuration (RNF-9)
const MAX_LOGIN_ATTEMPTS := 10
const RATE_LIMIT_WINDOW := 60.0  # seconds

## Timer references
var _ws_timeout_timer: Timer = null
var _tcp_timeout_timer: Timer = null

## Track login attempts for rate limiting
var _login_attempts: Array = []

## Signals for UI integration
signal error_popup_shown(error_code: String, error_message: String)
signal auth_error_occurred(error: Resource)
signal server_selection_error(error_code: String, error_message: String)
signal rate_limit_exceeded()

func _ready() -> void:
	"""Initialize AuthErrorManager as singleton."""
	instance = self
	_create_timers()
	print("[AuthErrorManager] Inicializado")

# ========== Timer Creation ==========

func _create_timers() -> void:
	"""Create timeout timers for WebSocket and TCP connections."""
	_create_ws_timeout_timer()
	_create_tcp_timeout_timer()

func _create_ws_timeout_timer() -> void:
	"""Create timer for WebSocket authentication timeout (2 seconds)."""
	_ws_timeout_timer = Timer.new()
	_ws_timeout_timer.wait_time = WS_TIMEOUT_SECONDS
	_ws_timeout_timer.one_shot = true
	_ws_timeout_timer.connect("timeout", _on_ws_timeout_expired)
	add_child(_ws_timeout_timer)
	print("[AuthErrorManager] Timer WebSocket creado (%ds)" % WS_TIMEOUT_SECONDS)

func _create_tcp_timeout_timer() -> void:
	"""Create timer for TCP connection timeout (5 seconds)."""
	_tcp_timeout_timer = Timer.new()
	_tcp_timeout_timer.wait_time = TCP_TIMEOUT_SECONDS
	_tcp_timeout_timer.one_shot = true
	_tcp_timeout_timer.connect("timeout", _on_tcp_timeout_expired)
	add_child(_tcp_timeout_timer)
	print("[AuthErrorManager] Timer TCP creado (%ds)" % TCP_TIMEOUT_SECONDS)

# ========== WebSocket Timeout (RNF-7) ==========

func start_ws_timeout() -> void:
	"""Start WebSocket authentication timeout (RF-7)."""
	if _ws_timeout_timer:
		_ws_timeout_timer.stop()
		_ws_timeout_timer.start()
		print("[AuthErrorManager] Timeout WebSocket iniciado")

func cancel_ws_timeout() -> void:
	"""Cancel WebSocket authentication timeout."""
	if _ws_timeout_timer and not _ws_timeout_timer.is_stopped():
		_ws_timeout_timer.stop()
		print("[AuthErrorManager] Timeout WebSocket cancelado")

func _on_ws_timeout_expired() -> void:
	"""Called when WebSocket auth doesn't respond in 2 seconds (RNF-7)."""
	print("[AuthErrorManager] TIMEOUT WebSocket - Servidor sin responder")
	error_popup_shown.emit("WS_TIMEOUT", "Servidor sin responder")

func is_ws_timeout_stopped() -> bool:
	"""Check if WebSocket timeout timer is stopped."""
	return _ws_timeout_timer == null or _ws_timeout_timer.is_stopped()

# ========== TCP Timeout (RNF-8) ==========

func start_tcp_timeout() -> void:
	"""Start TCP connection timeout (RNF-8)."""
	if _tcp_timeout_timer:
		_tcp_timeout_timer.stop()
		_tcp_timeout_timer.start()
		print("[AuthErrorManager] Timeout TCP iniciado")

func cancel_tcp_timeout() -> void:
	"""Cancel TCP connection timeout."""
	if _tcp_timeout_timer and not _tcp_timeout_timer.is_stopped():
		_tcp_timeout_timer.stop()
		print("[AuthErrorManager] Timeout TCP cancelado")

func _on_tcp_timeout_expired() -> void:
	"""Called when TCP connection doesn't establish in 5 seconds (RNF-8)."""
	print("[AuthErrorManager] TIMEOUT TCP - Servidor sin responder")
	error_popup_shown.emit("TCP_TIMEOUT", "Servidor sin responder")

func is_tcp_timeout_stopped() -> bool:
	"""Check if TCP timeout timer is stopped."""
	return _tcp_timeout_timer == null or _tcp_timeout_timer.is_stopped()

# ========== Rate Limiting (RNF-9) ==========

func _prune_old_attempts() -> void:
	"""Remove login attempts older than the rate limit window."""
	var current_time = Time.get_unix_time_from_system()
	_login_attempts = _login_attempts.filter(
		func(attempt_time: float) -> bool:
			return current_time - attempt_time < RATE_LIMIT_WINDOW
	)

func record_failed_login() -> void:
	"""Record a failed login attempt for rate limiting."""
	_prune_old_attempts()
	_login_attempts.append(Time.get_unix_time_from_system())
	print("[AuthErrorManager] Intento fallido registrado (%d en ventana)" % _login_attempts.size())

func check_rate_limit() -> void:
	"""Check if rate limit exceeded and emit signal."""
	_prune_old_attempts()
	if _login_attempts.size() >= MAX_LOGIN_ATTEMPTS:
		print("[AuthErrorManager] Rate limit excedido (%d intentos)" % _login_attempts.size())
		rate_limit_exceeded.emit()
		return false
	return true

func get_remaining_attempts() -> int:
	"""Get remaining attempts before rate limiting (RNF-9)."""
	_prune_old_attempts()
	return max(0, MAX_LOGIN_ATTEMPTS - _login_attempts.size())

func is_rate_limited() -> bool:
	"""Check if rate limit exceeded (10 attempts in 60 seconds = RNF-9)."""
	_prune_old_attempts()
	return _login_attempts.size() >= MAX_LOGIN_ATTEMPTS

# ========== Auth Error Handling (RF-9) ==========

func handle_auth_rejection(error_string: String, detail_message: String) -> void:
	"""Handle auth rejection by creating and emitting appropriate AuthError (RF-9)."""
	print("[AuthErrorManager] Manejo de rechazo auth: %s - %s" % [error_string, detail_message])
	
	var auth_error: AuthError = _create_auth_error_from_string(error_string)
	auth_error.message = detail_message
	auth_error.timestamp = Time.get_unix_time_from_system()
	
	auth_error_occurred.emit(auth_error)

func _create_auth_error_from_string(error_string: String) -> AuthError:
	"""Create appropriate AuthError from server error string (RF-9)."""
	match error_string:
		"TOKEN_INVALIDO":
			return AuthError.invalid_token()
		"TOKEN_EXPIRADO":
			return AuthError.expired_token()
		"TOKEN_NO_REGISTRADO":
			return AuthError.not_registered_token()
		_:
			# Unknown error - return generic invalid token
			var default_error = AuthError.invalid_token()
			default_error.message = "Error de autenticación desconocido: %s" % error_string
			return default_error

# ========== Server Selection Error Handling (RF-5) ==========

func handle_server_selection_error(error_code: String, error_message: String) -> void:
	"""Handle server selection error by emitting signal (RF-5)."""
	print("[AuthErrorManager] Error selección servidor: %s - %s" % [error_code, error_message])
	server_selection_error.emit(error_code, error_message)

# ========== Connection Error Handling (RF-7) ==========

func handle_connection_dropped_during_auth() -> void:
	"""Handle connection dropped during authentication (RF-7)."""
	print("[AuthErrorManager] Conexión perdida durante autenticación")
	error_popup_shown.emit("WS_DISCONNECTED", "Conexión perdida durante la autenticación")

func show_error(error_code: String, error_message: String) -> void:
	"""Show error popup with custom code and message (RF-7)."""
	print("[AuthErrorManager] Error: %s - %s" % [error_code, error_message])
	error_popup_shown.emit(error_code, error_message)

# ========== Reset All Timeouts ==========

func reset_all_timeouts() -> void:
	"""Reset all timeout timers."""
	cancel_ws_timeout()
	cancel_tcp_timeout()
	print("[AuthErrorManager] Todos los timeouts reiniciados")

# ========== Get Connection State (for debugging) ==========

func get_connection_state() -> Dictionary:
	"""Get current connection state for debugging."""
	_prune_old_attempts()
	return {
		"ws_timeout_active": not is_ws_timeout_stopped(),
		"tcp_timeout_active": not is_tcp_timeout_stopped(),
		"login_attempts_in_window": _login_attempts.size(),
		"rate_limited": is_rate_limited(),
		"remaining_attempts": get_remaining_attempts(),
		"ws_timeout_seconds": WS_TIMEOUT_SECONDS,
		"tcp_timeout_seconds": TCP_TIMEOUT_SECONDS,
	}

# ========== Reset Rate Limiting ==========

func reset_login_attempts() -> void:
	"""Reset login attempts counter."""
	_login_attempts.clear()
	print("[AuthErrorManager] Intentos de login reiniciados")