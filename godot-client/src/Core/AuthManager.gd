# AuthManager.gd
# Manejo de errores, estados de conexión y rate limiting
# RF-7: Mensaje de error cuando el servidor está caído
# RNF-7: Timeout WebSocket 2s
# RNF-9: Rate limiting 10/60s

extends Node

## Singleton instance
static var instance: AuthManager = null

## Connection timeout configuration (RNF-7, RNF-8)
const WS_TIMEOUT_SECONDS := 2.0
const TCP_TIMEOUT_SECONDS := 5.0

## Rate limiting configuration (RNF-9)
const MAX_LOGIN_ATTEMPTS := 10
const RATE_LIMIT_WINDOW := 60.0  # seconds

## State tracking
var login_attempts: Array = []  # Timestamps of failed attempts
var connection_timeout_timer: Timer = null
var tcp_timeout_timer: Timer = null

## UI reference for showing error popups
var error_popup_ui: Node = null

## Signal for external listeners
signal error_popup_shown(error_code: String, error_message: String)

func _ready() -> void:
	"""Initialize AuthManager as singleton."""
	instance = self
	connect_timers()

func connect_timers() -> void:
	"""Create timeout timers for WebSocket and TCP connections."""
	_create_ws_timeout_timer()
	_create_tcp_timeout_timer()

# ========== WebSocket Timeout (RNF-7) ==========

func _create_ws_timeout_timer() -> void:
	"""Create timer for WebSocket authentication timeout (2 seconds)."""
	connection_timeout_timer = Timer.new()
	connection_timeout_timer.wait_time = WS_TIMEOUT_SECONDS
	connection_timeout_timer.one_shot = true
	connection_timeout_timer.connect("timeout", _on_ws_timeout)
	add_child(connection_timeout_timer)
	print("[AuthManager] WebSocket timeout timer created (%ds)" % WS_TIMEOUT_SECONDS)

func start_ws_timeout() -> void:
	"""Start WebSocket authentication timeout."""
	if connection_timeout_timer:
		connection_timeout_timer.stop()
		connection_timeout_timer.start()
		print("[AuthManager] WebSocket timeout started")

func cancel_ws_timeout() -> void:
	"""Cancel WebSocket authentication timeout."""
	if connection_timeout_timer and connection_timeout_timer.is_stopped():
		connection_timeout_timer.stop()
		print("[AuthManager] WebSocket timeout cancelled")

func _on_ws_timeout() -> void:
	"""Called when WebSocket auth doesn't respond in 2 seconds (RNF-7)."""
	print("[AuthManager] WebSocket timeout - server no responding")
	error_popup_shown.emit("WS_TIMEOUT", "Servidor sin responder")

# ========== TCP Timeout (RNF-8) ==========

func _create_tcp_timeout_timer() -> void:
	"""Create timer for TCP connection timeout (5 seconds)."""
	tcp_timeout_timer = Timer.new()
	tcp_timeout_timer.wait_time = TCP_TIMEOUT_SECONDS
	tcp_timeout_timer.one_shot = true
	tcp_timeout_timer.connect("timeout", _on_tcp_timeout)
	add_child(tcp_timeout_timer)
	print("[AuthManager] TCP timeout timer created (%ds)" % TCP_TIMEOUT_SECONDS)

func start_tcp_timeout() -> void:
	"""Start TCP connection timeout."""
	if tcp_timeout_timer:
		tcp_timeout_timer.stop()
		tcp_timeout_timer.start()
		print("[AuthManager] TCP timeout started")

func cancel_tcp_timeout() -> void:
	"""Cancel TCP connection timeout."""
	if tcp_timeout_timer and not tcp_timeout_timer.is_stopped():
		tcp_timeout_timer.stop()
		print("[AuthManager] TCP timeout cancelled")

func _on_tcp_timeout() -> void:
	"""Called when TCP connection doesn't establish in 5 seconds (RNF-8)."""
	print("[AuthManager] TCP timeout - server no responding")
	error_popup_shown.emit("TCP_TIMEOUT", "Servidor sin responder")

# ========== Rate Limiting (RNF-9) ==========

func _prune_old_attempts() -> void:
	"""Remove login attempts older than the rate limit window."""
	var current_time = Time.get_unix_time_from_system()
	login_attempts = login_attempts.filter(
		func(attempt_time: float) -> bool:
			return current_time - attempt_time < RATE_LIMIT_WINDOW
	)

func record_login_attempt() -> void:
	"""Record a login attempt for rate limiting."""
	_prune_old_attempts()
	login_attempts.append(Time.get_unix_time_from_system())
	print("[AuthManager] Login attempt recorded (%d in window)" % login_attempts.size())

func is_rate_limited() -> bool:
	"""Check if rate limit exceeded (10 attempts in 60 seconds = RNF-9)."""
	_prune_old_attempts()
	return login_attempts.size() >= MAX_LOGIN_ATTEMPTS

func get_remaining_attempts() -> int:
	"""Get remaining attempts before rate limiting."""
	_prune_old_attempts()
	return max(0, MAX_LOGIN_ATTEMPTS - login_attempts.size())

func reset_login_attempts() -> void:
	"""Reset login attempts counter."""
	login_attempts.clear()
	print("[AuthManager] Login attempts reset")

# ========== Error Handling (RF-7) ==========

func show_error_popup(error_code: String, error_message: String) -> void:
	"""Show error popup to user (RF-7)."""
	print("[AuthManager] Error popup: %s - %s" % [error_code, error_message])
	error_popup_shown.emit(error_code, error_message)

func handle_connection_error(error_code: String, error_message: String) -> void:
	"""Handle connection error with popup (RF-7)."""
	# Log the error
	print("[AuthManager] Connection error: %s - %s" % [error_code, error_message])
	
	# Emit signal for UI to show popup
	error_popup_shown.emit(error_code, error_message)

# ========== Connection State Management ==========

func get_connection_state() -> Dictionary:
	"""Get current connection state for debugging."""
	return {
		"ws_timeout_active": connection_timeout_timer != null and connection_timeout_timer.is_stopped() == false,
		"tcp_timeout_active": tcp_timeout_timer != null and tcp_timeout_timer.is_stopped() == false,
		"login_attempts_in_window": login_attempts.size(),
		"rate_limited": is_rate_limited(),
		"remaining_attempts": get_remaining_attempts(),
	}

func reset_all_timeouts() -> void:
	"""Reset all timeout timers."""
	cancel_ws_timeout()
	cancel_tcp_timeout()
	print("[AuthManager] All timeouts reset")