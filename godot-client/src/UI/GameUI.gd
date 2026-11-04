class_name GameUI
# @class GameUI
# Interfaz del juego
# Muestra el HUD durante la partida
extends Control

signal back_to_select

# BreedLabel es opcional - puede no existir en la escena inicial
var breed_label: Label = null
var _breed_label_path := "HUDContainer/BreedLabel"

# Estado del juego
var _character_data: CharacterData = null

@onready var character_label: Label = $HUDContainer/CharacterLabel
@onready var level_label: Label = $HUDContainer/LevelLabel
@onready var health_label: Label = $HUDContainer/HealthLabel
@onready var health_bar: ProgressBar = $HUDContainer/HealthBar
@onready var xp_bar: ProgressBar = $HUDContainer/XPBar
@onready var xp_label: Label = $HUDContainer/XPLabel
@onready var back_to_select_button: Button = $HUDContainer/BackToSelect


func _enter_tree() -> void:
	# Actualizar cuando la escena entra en árbol (después de GameManager cambiar a IN_GAME)
	_update_display()


func _ready() -> void:
	print("[GameUI] Preparando UI del juego")
	# Intentar obtener BreedLabel de forma segura (puede no existir)
	breed_label = get_node_or_null(_breed_label_path)
	if breed_label == null:
		print("[GameUI] BreedLabel no encontrada en ruta: %s" % _breed_label_path)
	_connect_signals()


func _connect_signals() -> void:
	if back_to_select_button != null:
		back_to_select_button.pressed.connect(_on_back_pressed)


func _update_display() -> void:
	if GameManager.instance == null:
		printerr("[GameUI] GameManager.instance es null")
		return

	_character_data = GameManager.instance.selected_character

	if _character_data != null:
		_update_character_display()
	else:
		_clear_character_display()


func _update_character_display() -> void:
	if _character_data == null:
		return

	print("[GameUI] Mostrando datos de personaje: %s" % _character_data.name)

	# Nombre del personaje
	if character_label != null:
		character_label.text = _character_data.name

	# Nivel
	if level_label != null:
		level_label.text = "Niv. %d" % _character_data.level

	# Raza (mostrar nombre legible)
	var breed_name: String = _get_breed_name(_character_data.breed)
	if breed_label != null:
		breed_label.text = "[%s]" % breed_name
		breed_label.visible = true

	# Salud
	_update_health()

	# XP
	_update_xp()


func _clear_character_display() -> void:
	if character_label != null:
		character_label.text = "Sin personaje"
	if level_label != null:
		level_label.text = "Niv. -"
	if breed_label != null:
		breed_label.visible = false
	# Health y XP pueden mostrarse vacíos


func _update_health() -> void:
	# Placeholder: en el futuro se obtendrá del servidor
	var max_health: int = 100
	var current_health: int = 100

	if health_label != null:
		health_label.text = "HP: %d/%d" % [current_health, max_health]
	if health_bar != null:
		health_bar.value = float(current_health) / float(max_health) * 100


func _update_xp() -> void:
	# Placeholder: en el futuro se obtendrá del servidor
	var xp_for_next: int = 100
	var current_xp: int = 0

	if xp_label != null:
		xp_label.text = "XP: %d/%d" % [current_xp, xp_for_next]
	if xp_bar != null:
		xp_bar.value = float(current_xp) / float(xp_for_next) * 100


func _get_breed_name(breed: int) -> String:
	# Nombres de raza basados en el protocolo Dofus (1-16)
	# Fuente: docs/PROTOCOL.md y datos del servidor
	match breed:
		1:
			return "Feca"
		2:
			return "Osamodas"
		3:
			return "Enutrof"
		4:
			return "Sacrieur"
		5:
			return "Sadida"
		6:
			return "Xelor"
		7:
			return "Chafouis"
		8:
			return "Iop"
		9:
			return "Cra"
		10:
			return "Sram"
		11:
			return "Xelor" # Xelor-11 is a special variant
		12:
			return "Ecaflip"
		13:
			return "Opr" # Opr (Ogre-like)
		14:
			return "Rubbaduck"
		15:
			return "Panda"
		16:
			return "Foggba"
		_:
			return "Desconocida"


func _on_back_pressed() -> void:
	print("[GameUI] Volver a selección de personajes")

	# Limpiar el personaje seleccionado
	if GameManager.instance != null:
		GameManager.instance.selected_character = null

	emit_signal("back_to_select")
