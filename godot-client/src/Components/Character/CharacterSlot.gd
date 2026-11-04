class_name CharacterSlot
# @class CharacterSlot
# Componente reutilizable para mostrar un personaje en el selector
# Diseñado para ser instanciado dinámicamente en CharacterSelectUI
# Estructura esperada (coincide con CharacterSlot.tscn):
#   CharacterSlot (Button)
#   └── CharacterVisual (HBoxContainer)
#       ├── IconContainer (TextureRect)
#       └── VBoxContainer (VBoxContainer)
#           ├── NameLabel (Label)
#           ├── BreedLabel (Label)
#           └── LevelLabel (Label)
#       └── ArrowIndicator (TextureRect)
extends Button

signal selected(character_slot: CharacterSlot)

const GAME_ASSETS_BASE_PATH := "C:/Users/pevalcar/AppData/Local/Alea/"

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

@export var character_id: int = 0
@export var character_name: String = ""
@export var character_breed: int = 0
@export var character_level: int = 1

@onready var icon_container: TextureRect = $CharacterVisual/IconContainer
@onready var name_label: Label = $CharacterVisual/VBoxContainer/NameLabel
@onready var breed_label: Label = $CharacterVisual/VBoxContainer/BreedLabel
@onready var level_label: Label = $CharacterVisual/VBoxContainer/LevelLabel
@onready var arrow_indicator: TextureRect = $ArrowIndicator


func _ready() -> void:
	_update_ui()
	# Conectar señal pressed del Button base para emitir 'selected'
	pressed.connect(_on_pressed)


func set_character_data(data) -> void:
	"""Configura el slot con datos de personaje desde el servidor
	Acepta CharacterData, Dictionary o cualquier objeto con propiedades id, name, breed, level
	"""
	if data is CharacterData:
		character_id = data.id
		character_name = data.name
		character_breed = data.breed
		character_level = data.level
	elif data is Dictionary:
		character_id = data.get("id", 0)
		character_name = data.get("name", "")
		character_breed = data.get("breed", 0)
		character_level = data.get("level", 1)
	else:
		# Intentar acceder como objeto (CharacterData o similar)
		character_id = data.id if data.has_method("get") else data.id
		character_name = data.name if data.has_method("get") else data.name
		character_breed = data.breed if data.has_method("get") else data.breed
		character_level = data.level if data.has_method("get") else data.level

	_update_ui()


func _on_pressed() -> void:
	# Emitir señal de selección - el CharacterSelectUI la conecta
	emit_signal("selected", self)


func _update_ui() -> void:
	"""Actualiza la UI con los datos del personaje"""
	# Verificar que los nodos existen antes de acceder a ellos
	if name_label != null:
		name_label.text = character_name
	if breed_label != null:
		breed_label.text = _get_breed_name(character_breed)
	if level_label != null:
		level_label.text = "Niv. %d" % character_level

	var emblem := _get_breed_emblem(character_breed)
	if emblem != null and icon_container != null:
		icon_container.texture = emblem


func _get_breed_emblem(breed: int) -> Texture2D:
	"""Carga el emblem de raza desde los assets externos de Alea
	Los emblems están numerados: breed=1 → 10.png, breed=2 → 20.png, etc.
	"""
	if breed < 1 or breed > 16:
		return null

	var file_num = breed * 10
	var emblem_path = GAME_ASSETS_BASE_PATH + "d3picto/hint/%d.png" % file_num

	if ResourceLoader.exists(emblem_path):
		return load(emblem_path)

	return null


func _get_breed_name(breed: int) -> String:
	"""Devuelve el nombre legible de la raza"""
	return BREED_NAMES.get(breed, "Desconocida")
