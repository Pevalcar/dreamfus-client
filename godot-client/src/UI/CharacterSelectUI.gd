class_name CharacterSelectUI
# @class CharacterSelectUI
# UI de selección de personaje
# Muestra lista de personajes y permite crear uno nuevo o seleccionar existente
# Diseñado inspirándose en la estructura de Alea/Dofus: win_characterSelection
extends Control

signal back_to_launcher
signal character_selected(character_id: int, character_name: String)
signal character_detail_confirmed(character_id: int, character_name: String)

# Ruta a assets de emblems (razas) - Temporalmente desde Alea
# Cuando se cree la copia DreamFus, cambiar a: "../DreamFus/"
const GAME_ASSETS_BASE_PATH := "C:/Users/pevalcar/AppData/Local/Alea/"

# Nombres de raza completos y consistentes con el protocolo Dofus
# Los emblems están numerados: breed=1 → 10.png, breed=2 → 20.png, etc.
const BREED_NAMES := {
	1: "Feca",
	2: "Osamodas",
	3: "Enutrof",
	4: "Sacrieur",
	5: "Sadida",
	6: "Xelor",
	7: "Chafouis",
	8: "Iop",
	9: "Cra",
	10: "Sram",
	11: "Ecaflip",
	12: "Ouginak",
	13: "Tymador",
	14: "Rubbaduck",
	15: "Steamer",
	16: "Eliotrope",
}

var _characters: Array = Array()

# Referencias a nodos principales (ajustado a estructura CharacterSelect.tscn)
@onready var title_label: Label = $VBoxContainer/VBoxContainer/TitleLabel
@onready var server_label: Label = $VBoxContainer/VBoxContainer/ServerLabel
@onready var scroll_container: ScrollContainer = $VBoxContainer/HBoxContainer/ScrollContainer
@onready var character_list: VBoxContainer = $VBoxContainer/HBoxContainer/ScrollContainer/CharacterList
@onready var create_button: Button = $VBoxContainer/BottomPanel/CreateButton
@onready var back_button: Button = $VBoxContainer/BottomPanel/BackButton

# Referencia al CharacterDetailPanel (panel de detalles del personaje)
@onready var detail_panel: PanelContainer = $VBoxContainer/HBoxContainer/CharacterDetailPanel

# Referencia a la escena CharacterButton (instancia para cada personaje)
const CHARACTER_BUTTON_SCENE := preload("uid://buc7isx7s1hjh")


func _ready() -> void:
	print("[CharacterSelectUI] Preparando UI")
	_connect_signals()


func _exit_tree() -> void:
	# Limpiar la lista de personajes al salir
	for child in character_list.get_children():
		child.queue_free()


func populate_characters(characters: Array) -> void:
	_characters = characters
	_populate_character_list()


func _connect_signals() -> void:
	# Listen for auth completed to handle server list (if needed for manual selection)
	# For now, server selection is handled automatically by Main.gd
	
	# Listen for error events
	if GameManager.instance != null:
		if GameManager.instance.has_signal("error_received"):
			GameManager.instance.error_received.connect(_on_error_received)

	# Conectar botones
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	if create_button != null:
		create_button.pressed.connect(_on_create_pressed)

	# Conectar señales del CharacterDetailPanel (if exists in scene)
	if detail_panel != null and detail_panel.has_method("connect"):
		if detail_panel.has_signal("confirmed"):
			detail_panel.confirmed.connect(_on_detail_confirmed)
		if detail_panel.has_signal("cancelled"):
			detail_panel.cancelled.connect(_on_detail_cancelled)
		if detail_panel.has_signal("delete_requested"):
			detail_panel.delete_requested.connect(_on_detail_delete_requested)


func _on_auth_completed(account_id: int, servers_json: String) -> void:
	if title_label != null:
		title_label.text = "Selecciona tu personaje"
	if server_label != null:
		server_label.text = "Cuenta: %d" % account_id


## Public method to receive characters from TCP connection
func receive_characters(characters: Array) -> void:
	print("[CharacterSelectUI] Recibidos %d personajes del servidor" % characters.size())
	_characters = characters
	_populate_character_list()

func _on_characters_received(characters: Array) -> void:
	receive_characters(characters)


func _populate_character_list() -> void:
	# Limpiar lista existente
	for child in character_list.get_children():
		child.queue_free()

	# Crear contenedor para cada personaje con estilo Dofus/Alea
	_create_character_slots()


func _create_character_slots() -> void:
	# Instanciar CharacterButton.tscn para cada personaje
	for char_data in _characters:
		var character_button: CharacterSlot = CHARACTER_BUTTON_SCENE.instantiate()
		# Use character_name as fallback if id field not available
		var char_id = char_data.get("id", char_data.get("character_id", 0))
		character_button.name = "CharacterSlot_%d" % char_id
		
		# Configurar datos del personaje
		character_button.set_character_data(char_data)
		
		# Conectar señal de selección - el CharacterSlot emite consigo mismo
		character_button.selected.connect(_on_character_button_pressed)
		
		# Añadir a la lista
		character_list.add_child(character_button)

	# Mostrar mensaje si no hay personajes
	if _characters.size() == 0:
		_show_empty_state()


func _show_empty_state() -> void:
	# Limpiar y mostrar mensaje de estado vacío
	for child in character_list.get_children():
		child.queue_free()

	var empty_label: Label = Label.new()
	empty_label.text = "No hay personajes creados.\nHaz clic en 'Crear Personaje' para empezar."
	empty_label.alignment = 0
	empty_label.autowrap_mode = 0
	empty_label.modulate = Color(0.5, 0.5, 0.5)
	empty_label.custom_minimum_size.y = 100
	character_list.add_child(empty_label)


func _get_breed_emblem(breed: int) -> Texture2D:
	"""Obtiene el emblem visual de raza desde los assets de Alea/Dofus
	Los emblems están numerados: breed=1 → 10.png, breed=2 → 20.png, etc.
	"""
	if breed < 1 or breed > 16:
		return null

	# Convertir breed (1-16) a número de archivo (10, 20, 30...)
	var file_num: int = breed * 10
	var emblem_path: String = GAME_ASSETS_BASE_PATH + "d3picto/hint/%d.png" % file_num

	if ResourceLoader.exists(emblem_path):
		return load(emblem_path)

	return null


func _get_breed_name(breed: int) -> String:
	"""Devuelve el nombre legible de la raza"""
	if BREED_NAMES.has(breed):
		return BREED_NAMES[breed]
	return "Desconocida"


func _get_breed_symbol(breed: int) -> String:
	"""Devuelve símbolo Unicode para la raza (fallback visual)"""
	match breed:
		1:
			return "🛡️" # Feca - Escudo
		2:
			return "🐢" # Osamodas - Tortuga
		3:
			return "🪙" # Enutrof - Monedas
		4:
			return "💪" # Sacrieur - Fuerza
		5:
			return "🐕" # Sadida - Perro
		6:
			return "⏳" # Xelor - Reloj
		7:
			return "🐝" # Chafouis - Abeja
		8:
			return "⚔️" # Iop - Espada
		9:
			return "🏹" # Cra - Arco
		10:
			return "🐍" # Sram - Serpiente
		11:
			return "🐱" # Ecaflip - Gato
		12:
			return "🦄" # Ouginak - Pavo real
		13:
			return "🎭" # Tymador - Máscara
		14:
			return "🦆" # Rubbaduck - Pato
		15:
			return "⚙️" # Steamer - Engranaje
		16:
			return "🐸" # Eliotrope - Rana
		_:
			return "❓"


func _on_character_button_pressed(character_slot: CharacterSlot) -> void:
	print("[CharacterSelectUI] Personaje seleccionado: %s (ID: %d)" % [character_slot.character_name, character_slot.character_id])
	
	# Mostrar detalles del personaje en el panel antes de confirmar
	if detail_panel != null:
		# Obtener datos completos del personaje
		var char_data := {
			"id": character_slot.character_id,
			"name": character_slot.character_name,
			"level": character_slot.character_level,
			"breed": character_slot.character_breed,
			"sex": 0,  # Placeholder - se obtendrá del servidor
			"experience": 0,  # Placeholder - se obtendrá del servidor
			"stats": []  # Placeholder - se obtendrá del servidor
		}
		detail_panel.show_character(char_data)
	else:
		# Fallback: emitir directamente si el panel no existe
		character_selected.emit(character_slot.character_id, character_slot.character_name)


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


# --- Manejadores del CharacterDetailPanel ---

func _on_detail_confirmed(character_id: int, character_name: String) -> void:
	"""Confirmado por el jugador - enviar al servidor la selección del personaje."""
	print("[CharacterSelectUI] Selección confirmada: %s (ID: %d)" % [character_name, character_id])
	
	# Ocultar el panel de detalles
	if detail_panel != null:
		detail_panel.hide_panel()
	
	# Emitir señal para que Main la maneje
	character_detail_confirmed.emit(character_id, character_name)


func _on_detail_cancelled() -> void:
	"""Cancelado por el jugador - volver a la lista."""
	print("[CharacterSelectUI] Selección cancelada")
	
	if detail_panel != null:
		detail_panel.hide_panel()


func _on_detail_delete_requested(character_id: int, character_name: String) -> void:
	"""Solicitud de eliminación de personaje."""
	print("[CharacterSelectUI] Solicitud de borrar personaje: %s (ID: %d)" % [character_name, character_id])
	# Placeholder - en producción abriría diálogo de confirmación
	if detail_panel != null:
		detail_panel.hide_panel()
