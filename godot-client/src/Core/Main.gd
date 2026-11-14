# Main.gd - Punto de entrada principal del juego
# Instancia todos los componentes y coordina la UI
extends Node

# Preload scripts for dynamic instantiation
const GameClientScript = preload("res://src/Network/GameClient.gd")
const SimpleProtocolClientScript = preload("res://src/Network/SimpleProtocolClient.gd")
const MapManagerScript = preload("res://src/Core/MapManager.gd")
const CharacterNodeScript = preload("res://src/Components/CharacterNode.gd")

# Server configuration (exported for editor, stored in GameManager)
@export var server_host: String = "127.0.0.1"
@export var server_port: int = 5555

# Componentes dinámicos 
var ws_client: Node = null
var game_client: GameClient = null

# Referencias a UI instanciada
var launcher_ui: LauncherUI = null
var character_select_ui: CharacterSelectUI = null
var game_ui: GameUI = null

# Juego activo (instanciados perezosamente al entrar en IN_GAME)
var map_manager = null
var character_node = null

# Referencia al CharacterSelectUI instanciado (para llamadas directas)
var character_select_ui_ref: CharacterSelectUI = null
# Track signal connection state to prevent duplicates
var _signals_connected: bool = false
var _request_in_progress: bool = false
# Track pending server selection ID for kqz ticket
var _pending_server_selection_id: int = 0

# Contenedores de UI
@onready var launcher_container: Node = $LauncherContainer
@onready var character_select_container: Node = $CharacterSelectContainer
@onready var game_container: Node = $GameContainer


func _ready() -> void:
	print("[Main] Inicializando juego...")

	# GameManager autoload should be available immediately in Godot 4.8
	# No need to wait for it

	# Create WebSocket client
	ws_client = SimpleProtocolClientScript.new()
	ws_client.name = "SimpleProtocolClient"
	ws_client.host = server_host
	ws_client.port = 5557
	add_child(ws_client)

	# Create GameClient for TCP connections (ticket/kqz flow)
	game_client = GameClientScript.new()
	game_client.name = "GameClient"
	add_child(game_client)

	# Configure GameManager with both clients (WebSocket for auth, TCP for game)
	GameManager.instance.server_host = server_host
	GameManager.instance.server_port = 5557 # WebSocket port

	# Conectar señales
	_connect_signals()

	# Initialize GameManager with WebSocket client
	GameManager.instance.initialize(ws_client, game_client)

	# Instanciar UI desde escenas
	_instantiate_ui()

	# Mostrar pantalla de launcher
	_show_launcher()


func _connect_signals() -> void:
	# Prevent duplicate signal connections
	if _signals_connected:
		print("[Main] Señales ya conectadas, saltando duplicados")
		return

	# Connect signals del GameManager
	GameManager.instance.error_received.connect(_on_error_received)
	GameManager.instance.character_selected.connect(_on_character_selected)

	# Connect signals del GameClient (TCP) - for ticket and characters
	# Note: Auth and server selection now handled via WebSocket
	game_client.connected.connect(_on_game_client_connected)
	game_client.disconnected.connect(_on_game_client_disconnected)
	# NOTE: message_received is NOT connected here. GameManager.initialize() already
	# connects it to _on_tcp_message_received; wiring it twice processed every burst
	# twice and painted the character list duplicated (8 slots for 4 characters).
	# The burst end (jtg) is detected in GameManager, so that is the emitter that
	# actually fires; the GameClient signal was never emitted by anything.
	GameManager.instance.characters_received.connect(_on_characters_from_tcp)
	# Auth and server selection responses are now handled via WebSocket
	# game_client.auth_response_received.connect(_on_tcp_auth_response)
	# game_client.server_selection_response_received.connect(_on_tcp_server_selection_response)

	# Connect signals del WebSocket client
	if ws_client != null:
		ws_client.auth_response_received.connect(_on_ws_auth_response)
		ws_client.server_selection_response_received.connect(_on_ws_server_selection_response)
		ws_client.connection_state_changed.connect(_on_ws_connected)
		ws_client.error_received.connect(_on_ws_error)

	_signals_connected = true


func _instantiate_ui() -> void:
	# Instanciar Launcher UI
	var LauncherScene: PackedScene = preload("res://scenes/Launcher.tscn")
	launcher_ui = LauncherScene.instantiate() as LauncherUI
	launcher_container.add_child(launcher_ui)

	# Instanciar CharacterSelect UI
	var CharacterSelectScene: PackedScene = preload("res://scenes/CharacterSelect.tscn")
	character_select_ui = CharacterSelectScene.instantiate() as CharacterSelectUI
	character_select_container.add_child(character_select_ui)
	character_select_ui_ref = character_select_ui # Store direct reference

	# Instanciar Game UI
	var GameScene: PackedScene = preload("res://scenes/Game.tscn")
	game_ui = GameScene.instantiate() as GameUI
	game_container.add_child(game_ui)

	# Conectar señales de UI
	launcher_ui.auth_requested.connect(_on_auth_requested)
	character_select_ui.back_to_launcher.connect(_show_launcher)
	character_select_ui.character_selected.connect(_on_character_from_select)
	character_select_ui.character_detail_confirmed.connect(_on_character_from_select)


func _on_auth_requested(
	token: String,
	lang: String,
	install_id: String,
	host: String,
	port: int,
) -> void:
	print(
		"[Main] Solicitud de auth recibida: lang=%s, token=%s, host=%s"
		% [lang, token.substr(0, 8), host]
	)
	# Store lang for later use in server selection
	GameManager.instance._pending_auth_lang = lang

	# Connect via WebSocket to port 5557
	if ws_client != null:
		ws_client.connect_to_server(host, 5557, lang, token, install_id)
	else:
		printerr("[Main] WebSocket client no inicializado!")


# Handle TCP auth response from GameClient
func _on_tcp_auth_response(success: bool, account_id: int, servers: Array, error: String) -> void:
	print(
		"[Main] TCP Auth response received: success=%s, account_id=%d, servers=%d"
		% [success, account_id, servers.size()]
	)
	if success:
		if servers.size() > 0:
			# Store account ID and server list
			if GameManager.instance != null:
				GameManager.instance.player_id = account_id
				GameManager.instance.servers = servers

			# Auto-select first server for testing
			var first_server = servers[0]
			var server_id = first_server.get("id", 0)
			print("[Main] Auto-selecting server %d" % server_id)

			# Request server selection via TCP
			if GameManager.instance != null:
				GameManager.instance.request_server_selection(server_id, account_id)
		else:
			printerr("[Main] No servers available in TCP auth response")
			if GameManager.instance != null:
				GameManager.instance.error_received.emit("NO_SERVERS", "No servers available")
				GameManager.instance.change_state(GameManager.GameState.LAUNCHER)
	else:
		print("[Main] TCP Auth failed: %s" % error)
		if GameManager.instance != null:
			GameManager.instance.error_received.emit("AUTH_FAILED", error)


func _on_character_selected(character_id: int, character_name: String) -> void:
	print("[Main] Personaje seleccionado")
	_show_game()


# Handle TCP server selection response (from GameClient)
func _on_tcp_server_selection_response(
	ticket: String,
	host: String,
	ports: Array,
	error: String,
	server_id: int = 0,
) -> void:
	print(
		"[Main] TCP Server selection response: ticket=%s..., host=%s, ports=%s"
		% [ticket.substr(0, 8), host, str(ports)]
	)
	if error != "":
		printerr("[Main] TCP Server selection error: %s" % error)
		if GameManager.instance != null:
			GameManager.instance.error_received.emit("SERVER_SELECT_FAILED", error)
		return

	# Delegate to GameManager's handler with language and server_id
	if GameManager.instance != null:
		GameManager.instance.handle_server_selection(ticket, host, ports, "es", server_id)


# Handle WebSocket auth response
func _on_ws_auth_response(success: bool, account_id: int, servers: Array, error: String) -> void:
	print(
		"[Main] WS Auth response received: success=%s, account_id=%d, servers=%d"
		% [success, account_id, servers.size()]
	)
	if success:
		if servers.size() > 0:
			# Store account ID and server list
			GameManager.instance.player_id = account_id
			GameManager.instance.servers = servers

			# IMMEDIATELY send server_selection to get ticket before server closes
			# The server closes after ~100ms, so we must send this immediately
			var first_server = servers[0]
			var server_id = first_server.get("id", 0)
			_pending_server_selection_id = server_id  # Store for kqz
			# Use stored lang from _pending_auth_lang
			var lang = (
				GameManager.instance._pending_auth_lang
				if GameManager \
						.instance \
						._pending_auth_lang
				!= ""
				else "es"
			)
			print(
				"[Main] Sending server_selection immediately: server_id=%d, account_id=%d"
				% [server_id, account_id]
			)
			ws_client.send_server_selection(server_id, account_id, lang)
		else:
			print("[Main] No servers available in WS auth response")
			GameManager.instance.error_received.emit("NO_SERVERS", "No servers available")
	else:
		print("[Main] WS Auth failed: %s" % error)
		GameManager.instance.error_received.emit("AUTH_FAILED", error)


# Handle WebSocket server selection response (contains ticket for TCP) 
func _on_ws_server_selection_response(
	success: bool,
	ticket: String,
	host: String,
	ports: Array,
	error: String,
	language: String = "es",
) -> void:
	print(
		"[Main] WS Server selection response: ticket=%s..., host=%s, ports=%s, lang=%s"
		% [ticket.substr(0, 8), host, str(ports), language]
	)
	if not success or error != "":
		var err_msg = error if error != "" else "Server selection failed"
		print("[Main] Server selection error: %s" % err_msg)
		if GameManager.instance != null:
			GameManager.instance.error_received.emit("SERVER_SELECT_FAILED", err_msg)
		return

	# Delegate to GameManager's handler with language and server_id
	if GameManager.instance != null:
		GameManager.instance.handle_server_selection(ticket, host, ports, language, _pending_server_selection_id)


# Handle WebSocket connection state change
func _on_ws_connected(connected: bool) -> void:
	if not connected and _request_in_progress:
		# Try to show error if we were connecting
		if GameManager.instance != null:
			GameManager.instance.error_received.emit("WS_DISCONNECTED", "WebSocket connection lost")


# Handle WebSocket error
func _on_ws_error(error_code: String, error_message: String) -> void:
	print("[Main] WebSocket error: %s - %s" % [error_code, error_message])
	if GameManager.instance != null:
		GameManager.instance.error_received.emit(error_code, error_message)


# Handle characters received from TCP (after ticket presentation)
func _on_characters_from_tcp(characters: Array) -> void:
	print("[Main] Personajes recibidos del TCP (kvi): %d" % characters.size())
	# Store characters in GameManager and update UI
	if GameManager.instance != null:
		GameManager.instance.characters = characters
	# Forward to CharacterSelectUI and show the selection UI
	if character_select_ui_ref != null:
		character_select_ui_ref.receive_characters(characters)
	_show_character_select()


# GameClient TCP connection handlers
func _on_game_client_connected() -> void:
	print("[Main] GameClient conectado a TCP")
	# TCP is ready, GameManager can now handle the welcome burst


func _on_game_client_disconnected() -> void:
	print("[Main] GameClient desconectado")
	# Handle disconnection if needed


func _on_character_from_select(character_id: int, character_name: String) -> void:
	"""
	Maneja la selección de personaje desde CharacterSelectUI.
	Envía kvw al servidor y cambia el estado.
	"""
	print("[Main] Personaje seleccionado desde UI: %s (ID: %d)" % [character_name, character_id])
	if GameManager.instance != null:
		# GameManager envía kvw y cambia estado a IN_GAME
		GameManager.instance.select_character_from_id(character_id, character_name)


func _on_error_received(error_code: String, error_message: String) -> void:
	printerr("[Main] Error: %s - %s" % [error_code, error_message])


func _on_detail_confirmed(character_id: int, character_name: String) -> void:
	"""Handle confirmed character from detail panel."""
	print("[Main] Character detail confirmed: %s (ID: %d)" % [character_name, character_id])
	_on_character_from_select(character_id, character_name)


func _show_launcher() -> void:
	print("[Main] Mostrando launcher")
	launcher_container.visible = true
	character_select_container.visible = false
	game_container.visible = false
	GameManager.instance.change_state(GameManager.GameState.LAUNCHER)


func _show_character_select() -> void:
	print("[Main] Mostrando selección de personajes")
	launcher_container.visible = false
	character_select_container.visible = true
	game_container.visible = false
	GameManager.instance.change_state(GameManager.GameState.CHARACTER_SELECT)


func _show_game() -> void:
	print("[Main] Mostrando juego")
	launcher_container.visible = false
	character_select_container.visible = false
	game_container.visible = true
	GameManager.instance.change_state(GameManager.GameState.IN_GAME)

	# Lazily create map + character nodes (only once per session).
	if map_manager == null:
		map_manager = MapManagerScript.new()
		map_manager.name = "MapManager"
		game_container.add_child(map_manager)
		print("[Main] MapManager añadido al juego")

	if character_node == null:
		character_node = CharacterNodeScript.new()
		character_node.name = "Character"
		game_container.add_child(character_node)
		character_node.set_map_manager(map_manager)
		# Use breed from current character if available
		if GameManager.instance.current_character != null:
			character_node.breed_id = GameManager.instance.current_character.breed
		print("[Main] CharacterNode añadido al juego")

	# Connect jru signal — fires when server sends the initial map block.
	var gm = GameManager.instance
	if not gm.map_loaded.is_connected(_on_map_loaded):
		gm.map_loaded.connect(_on_map_loaded)


func _on_map_loaded(map_id: int, cell_id: int) -> void:
	print("[Main] map_loaded signal: map_id=%d cell_id=%d" % [map_id, cell_id])
	if map_manager == null:
		return
	# Centre the camera on the starting cell.
	map_manager.load_map_by_id(map_id)
	if character_node != null:
		character_node.place_at(cell_id)
		print("[Main] Personaje situado en celda %d del mapa %d" % [cell_id, map_id])
