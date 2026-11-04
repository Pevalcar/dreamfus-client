class_name GameManager
# @class GameManager
# Administrador principal del juego
# Gestiona el estado global, la conexión al servidor y la navegación entre pantallas
extends Node

signal game_state_changed(new_state: int)
signal auth_completed(account_id: int, servers_json: String)
signal character_selected(character_id: int, character_name: String)
signal characters_received(characters: Array)
signal error_received(error_code: String, error_message: String)

enum GameState {
	LAUNCHER = 0,
	PLAYER_LOGIN = 1,
	CHARACTER_SELECT = 2,
	IN_GAME = 3,
	ERROR = 4,
}

# Singleton
static var instance: GameManager = null

# Configuración
@export var server_host: String = "127.0.0.1"
@export var server_port: int = 5557
@export var default_language: String = "es"

var current_state: GameState = _current_state:
	get:
		return _current_state

# Datos de la sesión
var account_id: int = 0
var available_servers: Array = []
var selected_character: CharacterData = null
# Estado del juego
var _current_state: GameState = GameState.LAUNCHER

# Referencias a clientes
var _proto_client: SimpleProtocolClient = null
var _game_client: GameClient = null

# Welcome burst handling
var _characters_list: Array = []
var _in_welcome_burst: bool = false
var _welcome_burst_started: bool = false


func _enter_tree() -> void:
	if instance == null:
		instance = self


func _ready() -> void:
	print("[GameManager] Inicializado")

	# Singleton
	if instance != null and instance != self:
		printerr("[GameManager] Singleton ya existe! QueueFreeing...")
		queue_free()
		return


func _exit_tree() -> void:
	cleanup()


func initialize(proto_client: SimpleProtocolClient, game_client: GameClient = null) -> void:
	_proto_client = proto_client
	_game_client = game_client

	# Conectar señales del cliente WebSocket
	proto_client.connection_state_changed.connect(_on_connection_state_changed)
	proto_client.auth_response_received.connect(_on_auth_response_received)
	proto_client.server_selection_response_received.connect(_on_server_selection_response_received)
	proto_client.error_received.connect(_on_error_received)

	# Conectar señales del cliente TCP (GameClient)
	if _game_client != null:
		_game_client.connected.connect(_on_game_client_connected)
		_game_client.disconnected.connect(_on_game_client_disconnected)
		_game_client.message_received.connect(_on_game_client_message_received)
		_game_client.error_occurred.connect(_on_game_client_error)


func change_state(new_state: GameState) -> void:
	if _current_state == new_state:
		return

	print("[GameManager] Cambio de estado: %s -> %s" % [_current_state, new_state])
	_current_state = new_state
	game_state_changed.emit(new_state)


# ============================================================
# AUTENTICACIÓN
# ============================================================
func attempt_login(lang: String, token: String, install_id: String) -> void:
	if _proto_client == null:
		return

	change_state(GameState.PLAYER_LOGIN)

	# Conectar si no está conectado
	if _proto_client.state == SimpleProtocolClient.ClientState.DISCONNECTED:
		_proto_client.connect_to_server(server_host, server_port)

		# Esperar a que el estado sea CONNECTED (polling explícito)
		var wait_time: float = 0.0
		var max_wait: float = 10.0 # Timeout de 10 segundos
		while (
			_proto_client.state != SimpleProtocolClient.ClientState.CONNECTED
			and wait_time < max_wait
		):
			await get_tree().process_frame
			wait_time += 0.016 # Aproximadamente 60 FPS

		if _proto_client.state != SimpleProtocolClient.ClientState.CONNECTED:
			printerr("[GameManager] Timeout esperando conexión WebSocket")
			error_received.emit("CONNECTION_ERROR", "Timeout esperando conexión")
			change_state(GameState.ERROR)
			return

		print("[GameManager] WebSocket conectado, enviando auth")

	# Enviar solicitud de auth
	_proto_client.send_auth_request(lang, token, install_id)


# ============================================================
# SELECCIÓN DE SERVIDOR
# ============================================================
func select_server(server_id: int) -> void:
	if _proto_client == null:
		return

	print("[GameManager] Solicitando conexión al servidor %d" % server_id)
	# NO cambiar estado aquí - esperar a respuesta del servidor y welcome burst

	# Enviar solicitud de selección de servidor
	_proto_client.send_server_selection(server_id, account_id, default_language)


func get_servers_json() -> String:
	var servers_array: Array = []
	for server in available_servers:
		servers_array.append(
			{
				"id": server.id,
				"name": server.name,
				"population": server.population,
				"is_full": server.is_full,
			}
		)
	return JSON.stringify({ "servers": servers_array })


# ============================================================
# SELECCIÓN DE PERSONAJE
# ============================================================
func select_character(character: CharacterData) -> void:
	if character == null:
		return

	print("[GameManager] Personaje seleccionado: %s (ID: %d)" % [character.name, character.id])
	selected_character = character

	character_selected.emit(character.id, character.name)
	change_state(GameState.IN_GAME)


func select_character_from_id(char_id: int, char_name: String) -> void:
	"""
	Selecciona un personaje usando solo ID y nombre (desde UI).
	Usado cuando la UI emite character_selected con estos parámetros.
	"""
	if char_id <= 0:
		printerr("[GameManager] ID de personaje inválido: %d" % char_id)
		return

	print("[GameManager] Personaje seleccionado desde UI: %s (ID: %d)" % [char_name, char_id])

	# Crear CharacterData básico
	var char_data := CharacterData.new()
	char_data.id = char_id
	char_data.name = char_name
	selected_character = char_data

	# Enviar kvw (selección de personaje) al servidor
	if _game_client != null and _game_client.is_tcp_connected():
		print("[GameManager] Enviando kvw para personaje ID: %d" % char_id)
		_game_client.send_character_selection(char_id)
	else:
		printerr("[GameManager] GameClient no conectado, no se puede enviar kvw")


# ============================================================
# LIMPIEZA
# ============================================================
func cleanup() -> void:
	if _proto_client != null:
		_proto_client.disconnect_from_server()
	if _game_client != null:
		_game_client.disconnect_tcp()
	account_id = 0
	selected_character = null
	available_servers = []
	_characters_list.clear()
	_in_welcome_burst = false
	_welcome_burst_started = false


func parse_character_from_json(json_str: String) -> CharacterData:
	if json_str == "" or json_str == null:
		return null

	var json := JSON.new()
	var parse_result := json.parse(json_str)
	if parse_result != Error.OK:
		printerr("[GameManager] Error parseando personaje: %d" % parse_result)
		return null

	return CharacterData.from_json(json.get_data() as Dictionary)


func _on_auth_response_received(
	success: bool,
	account_id_param: int,
	servers_array: Array,
	error: String,
) -> void:
	var acct_id: int = account_id_param

	if success:
		account_id = acct_id
		available_servers = []

		# Parsear servidores - servers_array is already an Array of server objects
		for server_dict in servers_array:
			var server: ServerInfo = ServerInfo.from_json(server_dict)
			available_servers.append(server)

		print("[GameManager] Auth exitoso. AccountId: %d, servidores: %d" % [account_id, available_servers.size()])
		auth_completed.emit(account_id, JSON.stringify(servers_array) )

		# Seleccionar primer servidor disponible
		if available_servers.size() > 0:
			select_server(available_servers[0].id)
	else:
		printerr("[GameManager] Auth fallido: %s" % error)
		change_state(GameState.ERROR)


func _on_server_selection_response_received(
	success: bool,
	ticket: String,
	host: String,
	ports: Array,
	error: String,
) -> void:
	if success:
		print("[GameManager] Servidor seleccionado: %s:%s" % [host, ports])

		# Conectar al GameClient para el welcome burst
		if _game_client != null:
			_game_client.connect_to_game(host, int(ports[0]))

			# Esperar a que esté conectado (polling explícito para evitar race conditions)
			var wait_time: float = 0.0
			var max_wait: float = 5.0
			while not _game_client.is_tcp_connected() and wait_time < max_wait:
				await get_tree().process_frame
				wait_time += 0.016 # Aproximadamente 60 FPS

			if not _game_client.is_tcp_connected():
				printerr("[GameManager] Timeout esperando TCP connection")
				error_received.emit("TCP_ERROR", "Timeout conectando TCP")
				return

			# Procesar frames extra para asegurar que el buffer está limpio
			await get_tree().process_frame
			await get_tree().process_frame

			# Enviar ticket (kqz)
			print("[GameManager] Enviando ticket (kqz) al servidor")
			_game_client.send_ticket(ticket, default_language)
	else:
		printerr("[GameManager] Error selección servidor: %s" % error)
		error_received.emit("SERVER_SELECT_ERROR", error)
		change_state(GameState.ERROR)


func _on_game_client_connected() -> void:
	print("[GameManager] TCP conectado para welcome burst")
	# Activar modo welcome burst para procesar kqp×3 + kvi + jtg
	_in_welcome_burst = true
	_characters_list = [] # Resetear lista por si acaso
	print("[GameManager] Modo welcome burst activado")


func _on_game_client_disconnected() -> void:
	print("[GameManager] TCP desconectado")
	_in_welcome_burst = false


func _on_game_client_error(message: String) -> void:
	printerr("[GameManager] Error TCP: %s" % message)
	error_received.emit("TCP_ERROR", message)


func _on_game_client_message_received(
	opcode: String,
	payload: PackedByteArray,
	request_id: int,
) -> void:
	print("[GameManager] Mensaje TCP recibido: %s" % opcode)

	if _in_welcome_burst:
		match opcode:
			"kqp":
				# First kqp signals start of welcome burst (server sends kqp×3)
				if not _welcome_burst_started:
					_welcome_burst_started = true
					print("[GameManager] Primer kqp recibido - bienvenida al servidor")
				# Subsequent kqp are just markers (no-op)
				pass
			"kvi":
				print("[GameManager] kvi recibido - parseando lista de personajes")
				_handle_kvi_characters(payload)
			"jtg":
				# End of welcome burst - burst is complete
				print(
					"[GameManager] jtg recibido - burst completado (%d personajes)"
					% _characters_list.size()
				)
				_in_welcome_burst = false
				_welcome_burst_started = false
				characters_received.emit(_characters_list)
				change_state(GameState.CHARACTER_SELECT)
			_:
				pass # Otros mensajes durante el burst
	else:
		# Ya estamos en el juego
		match opcode:
			"hpd":
				# Personaje cargado, empezar partida
				print("[GameManager] hpd recibido - personaje cargado")
				change_state(GameState.IN_GAME)
			_:
				pass


func _handle_kvi_characters(payload: PackedByteArray) -> void:
	# Parsear payload de kvi usando decodificador protobuf
	# El payload es una secuencia de caracteres en formato protobuf, no JSON
	_characters_list = Proto.decode_kvi(payload)
	
	if _characters_list.size() > 0:
		print("[GameManager] kvi: recibidos %d personajes" % _characters_list.size())
	else:
		print("[GameManager] kvi: lista vacía de personajes")


func _on_connection_state_changed(connected: bool) -> void:
	# No cambiar estado si estamos en medio de un proceso de login
	if not connected and _current_state != GameState.PLAYER_LOGIN:
		change_state(GameState.LAUNCHER)


func _on_error_received(error: String, details: String) -> void:
	printerr("[GameManager] Error: %s - %s" % [error, details])
	error_received.emit(error, details)
	if error != "AUTH_ERROR":
		change_state(GameState.ERROR)
