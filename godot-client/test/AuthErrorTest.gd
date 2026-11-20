# AuthErrorTest.gd
# Test unitario para AuthError (RFC para RF-9)
# RF-9: Rechazo de conexión inválida

extends GutTest

var AuthError = preload("res://src/Data/AuthError.gd")

func _ready():
	print("[AuthErrorTest] initialized for T3 - RF-9 error structure")

# ============================================================================
# Enum ErrorType - 3 valores exactos según RF-9
# ============================================================================

func test_enum_token_invalido():
	"""T3-RF9: TOKEN_INVALIDO = 0"""
	assert_eq(AuthError.ErrorType.TOKEN_INVALIDO, 0, "TOKEN_INVALIDO debe ser 0")

func test_enum_token_expirado():
	"""T3-RF9: TOKEN_EXPIRADO = 1"""
	assert_eq(AuthError.ErrorType.TOKEN_EXPIRADO, 1, "TOKEN_EXPIRADO debe ser 1")

func test_enum_token_no_registrado():
	"""T3-RF9: TOKEN_NO_REGISTRADO = 2"""
	assert_eq(AuthError.ErrorType.TOKEN_NO_REGISTRADO, 2, "TOKEN_NO_REGISTRADO debe ser 2")

# ============================================================================
# ERROR_STRINGS mapping
# ============================================================================

func test_error_string_token_invalido():
	"""T3-RF9: ERROR_STRINGS mapping for TOKEN_INVALIDO"""
	var expected = "TOKEN_INVALIDO"
	var actual = AuthError.ERROR_STRINGS[AuthError.ErrorType.TOKEN_INVALIDO]
	assert_eq(actual, expected, "ERROR_STRINGS debe mapear TOKEN_INVALIDO")

func test_error_string_token_expirado():
	"""T3-RF9: ERROR_STRINGS mapping for TOKEN_EXPIRADO"""
	var expected = "TOKEN_EXPIRADO"
	var actual = AuthError.ERROR_STRINGS[AuthError.ErrorType.TOKEN_EXPIRADO]
	assert_eq(actual, expected, "ERROR_STRINGS debe mapear TOKEN_EXPIRADO")

func test_error_string_token_no_registrado():
	"""T3-RF9: ERROR_STRINGS mapping for TOKEN_NO_REGISTRADO"""
	var expected = "TOKEN_NO_REGISTRADO"
	var actual = AuthError.ERROR_STRINGS[AuthError.ErrorType.TOKEN_NO_REGISTRADO]
	assert_eq(actual, expected, "ERROR_STRINGS debe mapear TOKEN_NO_REGISTRADO")

# ============================================================================
# Factory methods
# ============================================================================

func test_invalid_token_factory():
	"""T3-RF9: invalid_token() factory creates correct error"""
	var err = AuthError.invalid_token()
	
	assert_not_null(err, "Debe crear instancia AuthError")
	assert_eq(err.error_type, AuthError.ErrorType.TOKEN_INVALIDO, "Tipo debe ser TOKEN_INVALIDO")
	assert_eq(err.get_error_string(), "TOKEN_INVALIDO", "String debe ser TOKEN_INVALIDO")
	assert_true(err.message.length() > 0, "Debe tener mensaje")

func test_expired_token_factory():
	"""T3-RF9: expired_token() factory creates correct error"""
	var err = AuthError.expired_token()
	
	assert_not_null(err, "Debe crear instancia AuthError")
	assert_eq(err.error_type, AuthError.ErrorType.TOKEN_EXPIRADO, "Tipo debe ser TOKEN_EXPIRADO")
	assert_eq(err.get_error_string(), "TOKEN_EXPIRADO", "String debe ser TOKEN_EXPIRADO")
	assert_true(err.message.length() > 0, "Debe tener mensaje")

func test_not_registered_token_factory():
	"""T3-RF9: not_registered_token() factory creates correct error"""
	var err = AuthError.not_registered_token()
	
	assert_not_null(err, "Debe crear instancia AuthError")
	assert_eq(err.error_type, AuthError.ErrorType.TOKEN_NO_REGISTRADO, "Tipo debe ser TOKEN_NO_REGISTRADO")
	assert_eq(err.get_error_string(), "TOKEN_NO_REGISTRADO", "String debe ser TOKEN_NO_REGISTRADO")
	assert_true(err.message.length() > 0, "Debe tener mensaje")

# ============================================================================
# is_valid() / has_error() methods
# ============================================================================

func test_is_valid_returns_false():
	"""T3-RF9: is_valid() siempre devuelve false para AuthError"""
	var err = AuthError.invalid_token()
	assert_false(err.is_valid(), "AuthError nunca es válido")

func test_has_error_returns_true():
	"""T3-RF9: has_error() siempre devuelve true para AuthError"""
	var err = AuthError.invalid_token()
	assert_true(err.has_error(), "AuthError siempre tiene error")

# ============================================================================
# to_dict() method - RF-9 JSON response format
# ============================================================================

func test_to_dict_has_success_false():
	"""T3-RF9: to_dict() debe tener success: false"""
	var err = AuthError.invalid_token()
	var dict = err.to_dict()
	
	assert_eq(dict.success, false, "success debe ser false")
	assert_true(dict.has("error"), "Debe tener campo error")

func test_to_dict_has_error_string():
	"""T3-RF9: to_dict() debe tener error string correcto"""
	var err = AuthError.expired_token()
	var dict = err.to_dict()
	
	assert_eq(dict.error, "TOKEN_EXPIRADO", "Campo error debe ser TOKEN_EXPIRADO")

func test_to_dict_has_timestamp():
	"""T3-RF9: to_dict() debe tener timestamp"""
	var err = AuthError.not_registered_token()
	var dict = err.to_dict()
	
	assert_true(dict.has("timestamp"), "Debe tener timestamp")
	assert_eq(dict.timestamp, err.timestamp, "timestamp debe coincidir")

func test_to_dict_has_message():
	"""T3-RF9: to_dict() debe tener message"""
	var err = AuthError.invalid_token()
	var dict = err.to_dict()
	
	assert_true(dict.has("message"), "Debe tener message")
	assert_eq(dict.message, err.message, "message debe coincidir")

# ============================================================================
# Timestamp validation
# ============================================================================

func test_timestamp_set_on_creation():
	"""T3-RF9: timestamp se establece al crear el error"""
	var before = Time.get_unix_time_from_system()
	var err = AuthError.invalid_token()
	var after = Time.get_unix_time_from_system()
	
	assert_ge(err.timestamp, before, "timestamp debe ser al menos antes de crear")
	assert_le(err.timestamp, after, "timestamp debe ser aproximadamente ahora")