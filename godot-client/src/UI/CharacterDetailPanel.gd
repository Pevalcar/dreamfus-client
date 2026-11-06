## CharacterDetailPanel.gd
## Script para el CharacterDetailPanel existente en CharacterSelect.tscn.
## Muestra las estadísticas detalladas de un personaje y requiere confirmación
## antes de enviar la selección al servidor.
##
## Flujo:
##   CharacterSlot → CharacterSelectUI → CharacterDetailPanel → CharacterSelectUI → GameManager
##
## Árbol esperado (CharacterDetailPanel.tscn):
##   CharacterDetailPanel (PanelContainer)
##     ├── TextureRect (fondo decorativo)
##     ├── VBoxContainer
##     │   ├── CharacterIcon (TextureRect)
##     │   ├── NameLabel (Label)
##     │   ├── BreedLabel (Label)
##     │   ├── LevelLabel (Label)
##     │   ├── StatsContainer (VBoxContainer)
##     │   │   └── StatRow (HBoxContainer)
##     │   │       ├── StatName (Label)
##     │   │       └── StatValue (Label)
##     │   └── ActionButtons (HBoxContainer)
##     │       ├── SelectButton (Button)
##     │       └── DeleteButton (Button)

extends PanelContainer

signal confirmed(character_id: int, character_name: String)
signal cancelled()
signal delete_requested(character_id: int, character_name: String)

# Datos del personaje a mostrar (puede ser Dictionary o CharacterData)
var _character_data = null
var _is_visible: bool = false

# Referencias a nodos
@onready var character_icon: TextureRect = $VBoxContainer/CharacterIcon
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var breed_label: Label = $VBoxContainer/BreedLabel
@onready var level_label: Label = $VBoxContainer/LevelLabel
@onready var stats_container: VBoxContainer = $VBoxContainer/StatsContainer
@onready var select_button: Button = $VBoxContainer/ActionButtons/SelectButton
@onready var delete_button: Button = $VBoxContainer/ActionButtons/DeleteButton


func _ready() -> void:
	# Ocultar panel al inicio
	visible = false

	# Conectar señales de botones
	select_button.pressed.connect(_on_select_pressed)
	delete_button.pressed.connect(_on_delete_pressed)

	# Conectar mouse_exited para ocultar panel al salir del CharacterSlot
	# (se gestiona desde CharacterSelectUI)


func show_character(data) -> void:
	"""Muestra el panel con los datos del personaje."""
	if data == null:
		hide_panel()
		return

	_character_data = data
	visible = true
	_is_visible = true

	# Actualizar UI - soporta CharacterData, Dictionary o cualquier objeto
	var char_name: String = ""
	var char_level: int = 1
	var char_breed: int = 0
	var char_id: int = 0
	var char_sex: int = 0
	var char_experience: int = 0
	var char_stats: Array = []

	if data is CharacterData:
		char_id = data.id
		char_name = data.name
		char_level = data.level
		char_breed = data.breed
		char_sex = data.sex
		char_experience = data.experience
		char_stats = data.stats
	elif data is Dictionary:
		char_id = data.get("id", 0)
		char_name = data.get("name", "")
		char_level = data.get("level", 1)
		char_breed = data.get("breed", 0)
		char_sex = data.get("sex", 0)
		char_experience = data.get("experience", 0)
		char_stats = data.get("stats", [])

	_character_data = {
		"id": char_id,
		"name": char_name,
		"level": char_level,
		"breed": char_breed,
		"sex": char_sex,
		"experience": char_experience,
		"stats": char_stats
	}

	if name_label != null:
		name_label.text = char_name

	if level_label != null:
		level_label.text = "Nivel %d" % char_level

	if breed_label != null:
		breed_label.text = "Raza: %s" % _get_breed_name(char_breed)

	# Cargar icono de raza
	var emblem: Texture2D = _get_breed_emblem(char_breed)
	if emblem != null and character_icon != null:
		character_icon.texture = emblem

	# Mostrar estadísticas
	_update_stats_display(data)


func hide_panel() -> void:
	"""Oculta el panel y limpia datos."""
	_character_data = null
	visible = false
	_is_visible = false


func _update_stats_display(data) -> void:
	"""Actualiza la visualización de estadísticas."""
	if stats_container == null:
		return

	# Limpiar stats anteriores
	for child in stats_container.get_children():
		child.queue_free()

	# Extraer datos del CharacterData o Dictionary
	var char_level := 1
	var char_experience := 0
	var char_sex := 0
	var char_stats: Array = []

	if data is CharacterData:
		char_level = data.level
		char_experience = data.experience
		char_sex = data.sex
		char_stats = data.stats
	elif data is Dictionary:
		char_level = data.get("level", 1)
		char_experience = data.get("experience", 0)
		char_sex = data.get("sex", 0)
		char_stats = data.get("stats", [])

	# Crear filas de estadísticas
	_add_stat_row("Nivel", str(char_level))
	_add_stat_row("Experiencia", str(char_experience))
	_add_stat_row("Sexo", "Hombre" if char_sex == 0 else "Mujer")

	# Stats adicionales si existen
	if char_stats.size() > 0:
		for stat in char_stats:
			if stat is Dictionary:
				var stat_name: String = stat.get("name", "?")
				var stat_value: String = str(stat.get("value", "?"))
				_add_stat_row(stat_name, stat_value)
	else:
		# Stats por defecto si no hay datos del servidor
		_add_stat_row("PV", "100")
		_add_stat_row("PA", "3")
		_add_stat_row("PM", "2")
		_add_stat_row("Fuerza", "50")
		_add_stat_row("Inteligencia", "50")
		_add_stat_row("Agilidad", "50")
		_add_stat_row("Suerte", "50")


func _add_stat_row(name: String, value: String) -> void:
	"""Añade una fila de estadística al contenedor."""
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_lbl: Label = Label.new()
	name_lbl.text = name
	name_lbl.custom_minimum_size.x = 120

	var value_lbl: Label = Label.new()
	value_lbl.text = value
	value_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))

	row.add_child(name_lbl)
	row.add_child(value_lbl)
	stats_container.add_child(row)


func _get_breed_name(breed: int) -> String:
	"""Devuelve el nombre legible de la raza."""
	var breed_names := {
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
	return breed_names.get(breed, "Desconocida")


func _get_breed_emblem(breed: int) -> Texture2D:
	"""Carga el emblem de raza desde los assets externos."""
	if AssetCatalog != null:
		return AssetCatalog.load_breed_emblem(breed)
	return null


# --- Manejadores de eventos ---

func _on_select_pressed() -> void:
	"""Confirmar selección y enviar al servidor."""
	if _character_data != null:
		confirmed.emit(_character_data.id, _character_data.name)
	hide_panel()


func _on_delete_pressed() -> void:
	"""Solicitar eliminación del personaje."""
	if _character_data != null:
		delete_requested.emit(_character_data.id, _character_data.name)
	hide_panel()