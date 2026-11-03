# @class CharacterSelectUI
# UI de selección de personaje
# Muestra lista de personajes y permite crear uno nuevo o seleccionar existente

extends Control
class_name CharacterSelectUI

signal character_selected(character_id: int, character_name: String)
signal back_to_launcher

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var server_label: Label = $VBoxContainer/ServerLabel
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var character_list: VBoxContainer = $ScrollContainer/CharacterList
@onready var create_button: Button = $BottomPanel/CreateButton
@onready var back_button: Button = $BottomPanel/BackButton

var _characters: Array = []


func _ready() -> void:
	print("[CharacterSelectUI] Preparando UI")
	_connect_signals()

func _connect_signals() -> void:
	# Escuchar auth completado para mostrar servidores
	if GameManager.instance != null:
		GameManager.instance.auth_completed.connect(_on_auth_completed)
		GameManager.instance.error_received.connect(_on_error_received)

	# Conectar botones
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	if create_button != null:
		create_button.pressed.connect(_on_create_pressed)

func _on_auth_completed(account_id: int, servers_json: String) -> void:
	if title_label != null:
		title_label.text = "Selecciona tu personaje"
	if server_label != null:
		server_label.text = "Cuenta: %d" % account_id

	# Parsear servidores y mostrar
	_populate_characters(servers_json)

func _populate_characters(servers_json: String) -> void:
	# Limpiar lista existente
	for child in character_list.get_children():
		child.queue_free()

	_characters.clear()

	# Para demo, crear personajes de prueba
	var test_char1 := CharacterData.new()
	test_char1.id = 1
	test_char1.name = "Hero1"
	test_char1.level = 10
	_characters.append(test_char1)

	var test_char2 := CharacterData.new()
	test_char2.id = 2
	test_char2.name = "Warrior"
	test_char2.level = 5
	_characters.append(test_char2)

	# Crear botones para cada personaje
	for char in _characters:
		var char_button := Button.new()
		char_button.text = "%s (Nivel %d)" % [char.name, char.level]
		char_button.pressed.connect(_on_character_button_pressed.bind(char))
		character_list.add_child(char_button)

func _on_character_button_pressed(character: CharacterData) -> void:
	print("[CharacterSelectUI] Personaje seleccionado: %s" % character.name)
	emit_signal("character_selected", character.id, character.name)

func _on_back_pressed() -> void:
	print("[CharacterSelectUI] Volver al launcher")
	emit_signal("back_to_launcher")

func _on_create_pressed() -> void:
	print("[CharacterSelectUI] Crear personaje (placeholder)")
	# Placeholder - en producción abriría diálogo de creación

func _on_error_received(error_code: String, error_message: String) -> void:
	if server_label != null:
		server_label.text = "Error: %s" % error_message
	if title_label != null:
		title_label.text = "Error de conexión"

func _exit_tree() -> void:
	# Limpiar la lista de personajes al salir
	for child in character_list.get_children():
		child.queue_free()
