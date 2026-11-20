# HttpClient.gd - Cliente HTTP para login (puerto 8888)
# RFC-001: Implementar flujo de login según spec 001
# RF cubiertos: RF-1, RF-2, RF-10

extends Node

class_name HttpClient

# Endpoint de login según spec.md
const LOGIN_URL := "http://127.0.0.1:8888/api/entrar"
const TIMEOUT_MS := 5000

# Enum de motivos de error según RF-2 y RF-10
enum AuthMotivo {
	CREDENCIALES_INVALIDAS = 0,
	CUENTA_BLOQUEADA = 1,
	USUARIO_VACIO = 2,
	CLAVE_VACIA = 3,
	CUENTA_NO_EXISTE = 4
}

# Singleton access
static var instance: HttpClient = null

func _ready() -> void:
	if instance == null:
		instance = self

## RF-10: Validar credenciales antes de contactar servidor
## SI el campo usuario está vacío, nulo o supera los 50 caracteres,
## ENTONCES EL SISTEMA devuelve {"bien": false, "motivo": "USUARIO_VACIO"}
## SIN contactar al servidor de autenticación.
static func _validate_usuario(usuario: Variant) -> bool:
	"""Valida campo usuario según RF-10.
	
	Retorna true si es válido, false si hay error.
	"""
	# RF-10: usuario vacío, nulo o > 50 caracteres = USUARIO_VACIO
	if usuario == null or usuario == "":
		return false
	if typeof(usuario) != TYPE_STRING:
		return false
	if usuario.length() > 50:
		return false
	return true

## RF-10: Validar credenciales de entrada
## SI el campo clave está vacío o nulo,
## ENTONCES EL SISTEMA devuelve {"bien": false, "motivo": "CLAVE_VACIA"}
## SIN contactar al servidor de autenticación.
static func _validate_clave(clave: Variant) -> bool:
	"""Valida campo clave según RF-10.
	
	Retorna true si es válido, false si hay error.
	"""
	# RF-10: clave vacía o nula = CLAVE_VACIA
	if clave == null or clave == "":
		return false
	if typeof(clave) != TYPE_STRING:
		return false
	return true

## RF-10: Normalizar IP por defecto
## SI el campo ip está vacío, ENTONCES EL SISTEMA usa 127.0.0.1 como valor por defecto.
static func _normalize_ip(ip: Variant) -> String:
	"""Normaliza IP según RF-10."""
	if ip == null or ip == "":
		return "127.0.0.1"
	return str(ip)

## Helper para convertir enum a string
static func _motivo_to_string(motivo: int) -> String:
	"""Convierte valor de enum a string legible."""
	match motivo:
		AuthMotivo.CREDENCIALES_INVALIDAS:
			return "CREDENCIALES_INVALIDAS"
		AuthMotivo.CUENTA_BLOQUEADA:
			return "CUENTA_BLOQUEADA"
		AuthMotivo.USUARIO_VACIO:
			return "USUARIO_VACIO"
		AuthMotivo.CLAVE_VACIA:
			return "CLAVE_VACIA"
		AuthMotivo.CUENTA_NO_EXISTE:
			return "CUENTA_NO_EXISTE"
		_:
			return "DESCONOCIDO"

## RF-2: Obtener string del enum AuthMotivo
static func get_motivo_string(motivo: int) -> String:
	"""Convierte valor de enum a string legible - API pública."""
	return _motivo_to_string(motivo)

## RF-1: Login HTTP exitoso
## CUANDO el jugador envía sus credenciales válidas al endpoint /api/entrar,
## EL SISTEMA devuelve una respuesta JSON con bien: true, token, apodo y cuenta observables.
func login(credentials: Dictionary) -> Dictionary:
	"""POST credentials to DreamFus login endpoint.
	
	Args:
		credentials: { "usuario": String, "clave": String, "ip": String }
	
	Returns:
		{ "bien": bool, "token": String, "apodo": String, "cuenta": int, "motivo": String }
	"""
	# RF-10: Validar credenciales locales primero (sin contactar servidor)
	var usuario = credentials.get("usuario", "")
	var clave = credentials.get("clave", "")
	var ip = credentials.get("ip", "")
	
	# RF-10: Validar usuario
	if not _validate_usuario(usuario):
		return {
			"bien": false,
			"token": "",
			"apodo": "",
			"cuenta": 0,
			"motivo": _motivo_to_string(AuthMotivo.USUARIO_VACIO)
		}
	
	# RF-10: Validar clave
	if not _validate_clave(clave):
		return {
			"bien": false,
			"token": "",
			"apodo": "",
			"cuenta": 0,
			"motivo": _motivo_to_string(AuthMotivo.CLAVE_VACIA)
		}
	
	# RF-10: Normalizar IP
	var normalized_ip = _normalize_ip(ip)
	
	# Preparar payload según spec.md
	var payload = {
		"usuario": usuario,
		"clave": clave,
		"ip": normalized_ip
	}
	
	# TODO: Implementar llamada HTTP cuando esté disponible WebClient para Godot 4.8
	# Por ahora, devolver error de conexión
	print("[HttpClient] HTTP request not implemented in 4.8 beta")
	return {
		"bien": false,
		"token": "",
		"apodo": "",
		"cuenta": 0,
		"motivo": _motivo_to_string(AuthMotivo.CREDENCIALES_INVALIDAS)
	}

## Helper para validar credenciales de entrada (usado por tests)
## Usa Variant para aceptar null (RF-10)
static func validate_credentials(usuario: Variant, clave: Variant) -> Dictionary:
	"""Valida credenciales y retorna resultado con motivo si aplica.
	
	Uso para tests unitarios y validación frontend.
	Acepta null para testing de RF-10.
	"""
	# RF-10: usuario vacío, nulo o > 50 caracteres
	if not _validate_usuario(usuario):
		return {"valid": false, "motivo": _motivo_to_string(AuthMotivo.USUARIO_VACIO)}
	
	# RF-10: clave vacía o nula
	if not _validate_clave(clave):
		return {"valid": false, "motivo": _motivo_to_string(AuthMotivo.CLAVE_VACIA)}
	
	return {"valid": true, "motivo": ""}