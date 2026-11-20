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
	CREDENCIALES_INVALIDAS = "CREDENCIALES_INVALIDAS",
	CUENTA_BLOQUEADA = "CUENTA_BLOQUEADA",
	USUARIO_VACIO = "USUARIO_VACIO",
	CLAVE_VACIA = "CLAVE_VACIA",
	CUENTA_NO_EXISTE = "CUENTA_NO_EXISTE"
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

## RF-1: Login HTTP exitoso
## CUANDO el jugador envía sus credenciales válidas al endpoint /api/entrar,
## EL SISTEMA devuelve una respuesta JSON con bien: true, token, apodo y cuenta observables.
static func login(credentials: Dictionary) -> Dictionary:
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
			"motivo": AuthMotivo.USUARIO_VACIO
		}
	
	# RF-10: Validar clave
	if not _validate_clave(clave):
		return {
			"bien": false,
			"token": "",
			"apodo": "",
			"cuenta": 0,
			"motivo": AuthMotivo.CLAVE_VACIA
		}
	
	# RF-10: Normalizar IP
	var normalized_ip = _normalize_ip(ip)
	
	# Preparar payload según spec.md
	var payload = {
		"usuario": usuario,
		"clave": clave,
		"ip": normalized_ip
	}
	
	# Crear HTTPClient
	var http = HTTPClient.new()
	var err = http.connect_to_host("127.0.0.1", 8888)
	
	if err != OK:
		print("[HttpClient] Error conectando: %d" % err)
		return {
			"bien": false,
			"token": "",
			"apodo": "",
			"cuenta": 0,
			"motivo": AuthMotivo.CREDENCIALES_INVALIDAS
		}
	
	# Esperar conexión
	await get_tree().create_timer(0.1).timeout
	
	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		print("[HttpClient] Conexión no establecida")
		return {
			"bien": false,
			"token": "",
			"apodo": "",
			"cuenta": 0,
			"motivo": AuthMotivo.CREDENCIALES_INVALIDAS
		}
	
	# Enviar request
	var body = JSON.stringify(payload)
	var headers = [
		"Content-Type: application/json",
		"Content-Length: " + str(body.length())
	]
	
	err = http.request(HTTPClient.METHOD_POST, "/api/entrar", headers, body.to_utf8_buffer())
	
	if err != OK:
		print("[HttpClient] Request failed: %d" % err)
		return {
			"bien": false,
			"token": "",
			"apodo": "",
			"cuenta": 0,
			"motivo": AuthMotivo.CREDENCIALES_INVALIDAS
		}
	
	# Leer respuesta
	var response_data = http.read_response_body_chunk()
	var response_text = ""
	while response_data.size() > 0:
		response_text += response_data.get_string_from_utf8()
		response_data = http.read_response_body_chunk()
	
	http.disconnect_from_host()
	
	# Parsear JSON
	var json = JSON.parse_string(response_text)
	if json == null:
		print("[HttpClient] JSON parse failed")
		return {
			"bien": false,
			"token": "",
			"apodo": "",
			"cuenta": 0,
			"motivo": AuthMotivo.CREDENCIALES_INVALIDAS
		}
	
	var data = json as Dictionary
	var bien = data.get("bien", false)
	
	if not bien:
		# RF-2: Login fallido con motivo
		var motivo = data.get("motivo", AuthMotivo.CREDENCIALES_INVALIDAS)
		return {
			"bien": false,
			"token": "",
			"apodo": "",
			"cuenta": 0,
			"motivo": motivo
		}
	
	# RF-1: Login exitoso
	return {
		"bien": true,
		"token": data.get("token", ""),
		"apodo": data.get("apodo", ""),
		"cuenta": data.get("cuenta", 0),
		"motivo": ""  # Vacío en caso exitoso
	}

## Helper para validar credenciales de entrada (usado por tests)
static func validate_credentials(usuario: String, clave: String) -> Dictionary:
	"""Valida credenciales y retorna resultado con motivo si aplica.
	
	Uso para tests unitarios y validación frontend.
	"""
	# RF-10: usuario vacío, nulo o > 50 caracteres
	if not _validate_usuario(usuario):
		return {"valid": false, "motivo": AuthMotivo.USUARIO_VACIO}
	
	# RF-10: clave vacía o nula
	if not _validate_clave(clave):
		return {"valid": false, "motivo": AuthMotivo.CLAVE_VACIA}
	
	return {"valid": true, "motivo": ""}

## Helper para obtener valores de enum como string
static func get_motivo_string(motivo_int: int) -> String:
	"""Convierte valor de enum a string legible."""
	match motivo_int:
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