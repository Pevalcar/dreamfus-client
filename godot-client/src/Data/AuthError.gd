# AuthError.gd
# Estructura de errores para autenticación (RFC para RF-9)
# RF-9: Rechazo de conexión inválida

class_name AuthError
extends Resource

# === Enum de errores de autenticación ===
# RF-9: Cuando el token es inválido, expirado o no registrado,
# el servidor responde auth_response con success: false y este error
enum ErrorType {
	TOKEN_INVALIDO = 0,     # Token no válido
	TOKEN_EXPIRADO = 1,     # Token expirado
	TOKEN_NO_REGISTRADO = 2 # Token no registrado en el sistema
}

# Mapeo de enum a string para respuestas JSON
const ERROR_STRINGS = {
	ErrorType.TOKEN_INVALIDO: "TOKEN_INVALIDO",
	ErrorType.TOKEN_EXPIRADO: "TOKEN_EXPIRADO",
	ErrorType.TOKEN_NO_REGISTRADO: "TOKEN_NO_REGISTRADO",
}

# === Propiedades ===
var error_type: ErrorType = ErrorType.TOKEN_INVALIDO
var message: String = ""
var timestamp: int = 0

# === Constructores ===

static func invalid_token() -> AuthError:
	"""Crea error para token inválido (RF-9)"""
	var err = AuthError.new()
	err.error_type = ErrorType.TOKEN_INVALIDO
	err.message = "Token de autenticación inválido"
	err.timestamp = Time.get_unix_time_from_system()
	return err

static func expired_token() -> AuthError:
	"""Crea error para token expirado (RF-9)"""
	var err = AuthError.new()
	err.error_type = ErrorType.TOKEN_EXPIRADO
	err.message = "Token de autenticación expirado"
	err.timestamp = Time.get_unix_time_from_system()
	return err

static func not_registered_token() -> AuthError:
	"""Crea error para token no registrado (RF-9)"""
	var err = AuthError.new()
	err.error_type = ErrorType.TOKEN_NO_REGISTRADO
	err.message = "Token no registrado en el sistema"
	err.timestamp = Time.get_unix_time_from_system()
	return err

# === Métodos ===

func get_error_string() -> String:
	"""Devuelve el string del error para JSON response"""
	return ERROR_STRINGS.get(error_type, "TOKEN_INVALIDO")

func is_valid() -> bool:
	"""Un AuthError nunca es 'válido' como respuesta exitosa"""
	return false

func has_error() -> bool:
	"""Un AuthError siempre tiene error"""
	return true

func to_dict() -> Dictionary:
	"""Convierte a dictionary para serialización JSON"""
	return {
		"success": false,
		"error": get_error_string(),
		"message": message,
		"timestamp": timestamp
	}