#!/usr/bin/env gscript
# @class GameManager
# Administrador principal del juego
# Gestiona el estado global, la conexión al servidor y la navegación entre pantallas

extends Node
class_name GameManager

signal game_state_changed(new_state: int)
signal auth_completed(account_id: int, servers_json: String)
signal character_selected(character_id: int, character_name: String)
signal error_received(error_code: String, error_message: String)

enum GameState {
	LAUNCHER = 0,
	PLAYER_LOGIN = 1,
	CHARACTER_SELECT = 2,
	IN_GAME = 3,
	ERROR = 4
}

# Singleton
static var instance: GameManager = null

# Estado del juego
var _current_state: GameState = GameState.LAUNCHER
var current_state: GameState = _current_state:
	get:
		return _current_state

# Datos de la sesión
var account_id: int = 0
var available_servers: Array = []
var selected_character: CharacterData = null

# Referencias
var _proto_client: SimpleProtocolClient = null

# Configuración
@export var server_host: String = "127.0.0.1"
@export var server_port: int = 5557
@export var default_language: String = "es"

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

func initialize(proto_client: SimpleProtocolClient) -> void:
	_proto_client = proto_client

	# Conectar señales del cliente usando el nuevo nombre de métodos
	proto_client.connection_state_changed.connect(_on_connection_state_changed)
	proto_client.auth_response_received.connect(_on_auth_response_received)
	proto_client.server_selection_response_received.connect(_on_server_selection_response_received)
	proto_client.error_received.connect(_on_error_received)

func change_state(new_state: GameState) -> void:
	if _current_state == new_state:
		return

	print("[GameManager] Cambio de estado: %s -> %s" % [_current_state, new_state])
	_current_state = new_state
	emit_signal("game_state_changed", new_state)

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
		# Esperar a que se establezca la conexión
		await _proto_client.connection_state_changed
		await get_tree().process_frame

	if _proto_client.state != SimpleProtocolClient.ClientState.CONNECTED:
		emit_signal("error_received", "CONNECTION_ERROR", "No se pudo conectar al servidor")
		change_state(GameState.ERROR)
		return

	# Enviar solicitud de auth
	_proto_client.send_auth_request(lang, token, install_id)

func _on_auth_response_received(success: bool, account_id_param: int, servers_json: Dictionary, error: String) -> void:
	var acct_id: int = account_id_param

	if success:
		account_id = acct_id
		available_servers = []

		# Parsear servidores
		var servers_data: Array = servers_json.get("servers", [])
		for server_dict in servers_data:
			var server: ServerInfo = ServerInfo.from_json(server_dict)
			available_servers.append(server)

		print("[GameManager] Auth exitoso. AccountId: %d" % account_id)
		emit_signal("auth_completed", account_id, JSON.stringify(servers_json))

		# Seleccionar primer servidor disponible
		if available_servers.size() > 0:
			select_server(available_servers[0].id)
	else:
		printerr("[GameManager] Auth fallido: %s" % error)
		change_state(GameState.ERROR)

# ============================================================
# SELECCIÓN DE SERVIDOR
# ============================================================

func select_server(server_id: int) -> void:
	if _proto_client == null:
		return

	print("[GameManager] Seleccionando servidor %d" % server_id)
	change_state(GameState.CHARACTER_SELECT)

	# Enviar solicitud de selección de servidor
	_proto_client.send_server_selection(server_id, account_id, default_language)

func get_servers_json() -> String:
	var servers_array: Array = []
	for server in available_servers:
		servers_array.append({
			"id": server.id,
			"name": server.name,
			"population": server.population,
			"is_full": server.is_full
		})
	return JSON.stringify({"servers": servers_array})

func _on_server_selection_response_received(success: bool, ticket: String, host: String, ports: Array, error: String) -> void:
	if success:
		print("[GameManager] Servidor seleccionado: %s:%s" % [host, ports])

		# Simulamos un personaje de prueba
		selected_character = CharacterData.new()
		selected_character.id = account_id % 1000 + 1
		selected_character.name = "TestHero"
		selected_character.level = 1

		change_state(GameState.IN_GAME)
	else:
		printerr("[GameManager] Error selección servidor: %s" % error)
		emit_signal("error_received", "SERVER_SELECT_ERROR", error)
		change_state(GameState.ERROR)

func _on_connection_state_changed(connected: bool) -> void:
	if not connected:
		change_state(GameState.LAUNCHER)

func _on_error_received(error: String, details: String) -> void:
	printerr("[GameManager] Error: %s - %s" % [error, details])
	emit_signal("error_received", error, details)
	if error != "AUTH_ERROR":
		change_state(GameState.ERROR)

# ============================================================
# SELECCIÓN DE PERSONAJE
# ============================================================

func select_character(character: CharacterData) -> void:
	if character == null:
		return

	print("[GameManager] Personaje seleccionado: %s" % character.name)
	selected_character = character

	emit_signal("character_selected", character.id, character.name)
	change_state(GameState.IN_GAME)

func parse_character_from_json(json_str: String) -> CharacterData:
	if json_str == "" or json_str == null:
		return null

	var json := JSON.new()
	var parse_result := json.parse(json_str)
	if parse_result != Error.OK:
		printerr("[GameManager] Error parseando personaje: %d" % parse_result)
		return null

	return CharacterData.from_json(json.get_data() as Dictionary)

# ============================================================
# LIMPIEZA
# ============================================================

func cleanup() -> void:
	if _proto_client != null:
		_proto_client.disconnect_from_server()
	account_id = 0
	selected_character = null
	available_servers = []

func _exit_tree() -> void:
	cleanup()
