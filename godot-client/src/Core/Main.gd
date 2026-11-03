# @class Main
# Punto de entrada principal del juego
# Instancia todos los componentes y coordina la UI

extends Node
class_name Main

@onready var game_manager: GameManager = $GameManager
@onready var ws_client: SimpleProtocolClient = $WebSocketClient

@export var server_host: String = "127.0.0.1"
@export var server_port: int = 5557

# Contenedores de UI
var launcher_container: Node = null
var character_select_container: Node = null
var game_container: Node = null

# Referencias a UI instanciada
var launcher_ui: LauncherUI = null
var character_select_ui: CharacterSelectUI = null
var game_ui: GameUI = null


func _ready() -> void:
	print("[Main] Inicializando juego...")

	# Configurar referencias del GameManager
	game_manager.server_host = server_host
	game_manager.server_port = server_port

	# Conectar señales del GameManager
	game_manager.auth_completed.connect(_on_auth_completed)
	game_manager.error_received.connect(_on_error_received)
	game_manager.character_selected.connect(_on_character_selected)

	# Inicializar GameManager con el cliente WebSocket
	game_manager.initialize(ws_client)

	# Instanciar UI desde escenas
	_instantiate_ui()

	# Mostrar pantalla de launcher
	_show_launcher()


func _instantiate_ui() -> void:
	# Instanciar Launcher UI
	var LauncherScene: PackedScene = preload("res://scenes/Launcher.tscn")
	launcher_ui = LauncherScene.instantiate() as LauncherUI
	$LauncherContainer.add_child(launcher_ui)

	# Instanciar CharacterSelect UI
	var CharacterSelectScene: PackedScene = preload("res://scenes/CharacterSelect.tscn")
	character_select_ui = CharacterSelectScene.instantiate() as CharacterSelectUI
	$CharacterSelectContainer.add_child(character_select_ui)

	# Instanciar Game UI
	var GameScene: PackedScene = preload("res://scenes/Game.tscn")
	game_ui = GameScene.instantiate() as GameUI
	$GameContainer.add_child(game_ui)

	# Conectar señales de UI
	launcher_ui.auth_requested.connect(_on_auth_requested)
	character_select_ui.back_to_launcher.connect(_show_launcher)
	game_ui.back_to_select.connect(_show_character_select)


func _on_auth_requested(lang: String, token: String, install_id: String, host: String, port: int) -> void:
	print("[Main] Solicitud de auth recibida: lang=%s, token=%s, install_id=%s, host=%s, port=%d" % [lang, token, install_id, host, port])
	game_manager.server_host = host
	game_manager.server_port = port
	game_manager.attempt_login(lang, token, install_id)

func _on_auth_completed(account_id: int, servers_json: String) -> void:
	print("[Main] Auth completado, mostrando selección de personajes")
	_show_character_select()

func _on_character_selected(character_id: int, character_name: String) -> void:
	print("[Main] Personaje seleccionado")
	_show_game()

func _on_error_received(error_code: String, error_message: String) -> void:
	printerr("[Main] Error: %s - %s" % [error_code, error_message])

func _show_launcher() -> void:
	print("[Main] Mostrando launcher")
	$LauncherContainer.visible = true
	$CharacterSelectContainer.visible = false
	$GameContainer.visible = false
	game_manager.change_state(GameManager.GameState.LAUNCHER)

func _show_character_select() -> void:
	print("[Main] Mostrando selección de personajes")
	$LauncherContainer.visible = false
	$CharacterSelectContainer.visible = true
	$GameContainer.visible = false
	game_manager.change_state(GameManager.GameState.CHARACTER_SELECT)

func _show_game() -> void:
	print("[Main] Mostrando juego")
	$LauncherContainer.visible = false
	$CharacterSelectContainer.visible = false
	$GameContainer.visible = true
	game_manager.change_state(GameManager.GameState.IN_GAME)
