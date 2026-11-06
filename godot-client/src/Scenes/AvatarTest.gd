## AvatarTest.gd
## Script de prueba para renderizar avatares usando AvatarSprite.gd (GDScript nativo)
## Utiliza soporte nativo de Zlib/Deflate de Godot 4 para archivos A2D.Z
## Fallback a WebP cuando A2D no está disponible o para visualización rápida

extends Control

const BREED_IDS = {
	"Iop": 1,
	"Eniripsa": 2,
	"Feca": 3,
	"Osamodas": 4,
	"Enutrof": 5,
	"Xelor": 6,
	"Cra": 7,
	"Sadida": 8,
	"Sacrier": 9,
}

## Path to A2D files (Alea client installation)
const A2D_BONES_PATH = "C:/Users/pevalcar/AppData/Local/Alea/d3pack/bones/"
const A2D_SKINS_PATH = "C:/Users/pevalcar/AppData/Local/Alea/d3pack/skins/"

var avatar_display: Node2D
var breed_selector: OptionButton
var test_button: Button
var debug_output: TextEdit
var current_avatar_node: Node

func _ready() -> void:
	avatar_display = $VBoxContainer/AvatarDisplay
	breed_selector = $VBoxContainer/BreedSelector
	test_button = $VBoxContainer/TestButton
	debug_output = $VBoxContainer/DebugOutput

	_setup_breed_selector()

	breed_selector.connect("item_selected", Callable(self, "_on_breed_selected"))
	test_button.connect("pressed", Callable(self, "_on_test_button_pressed"))

	_add_debug_info("=== Avatar Renderer Test ===")
	_add_debug_info("Usando AvatarSprite.gd (GDScript nativo Godot 4)")
	_add_debug_info("Soporte Zlib/Deflate integrado para A2D.Z files")
	_add_debug_info("")

	_on_breed_selected(0)

func _setup_breed_selector() -> void:
	var keys = BREED_IDS.keys()
	var i = 0
	while i < keys.size():
		breed_selector.add_item(keys[i])
		i += 1

func _on_breed_selected(idx: int) -> void:
	if idx < 0:
		return

	var breed_name = breed_selector.get_item_text(idx)
	var breed_id = BREED_IDS.get(breed_name, 0)

	_add_debug_info("")
	_add_debug_info("Breed: " + breed_name + " (ID: " + str(breed_id) + ")")

	_load_avatar_for_breed(breed_id)

func _on_test_button_pressed() -> void:
	var idx = breed_selector.selected
	if idx >= 0:
		_on_breed_selected(idx)

func _load_avatar_for_breed(breed_id: int) -> void:
	_clear_avatar_display()
	
	_add_debug_info("Loading AvatarSprite.gd...")
	
	var breed_name = ""
	var keys = BREED_IDS.keys()
	var i = 0
	while i < keys.size():
		var name = keys[i]
		var id = BREED_IDS.get(name, 0)
		if id == breed_id:
			breed_name = name.to_lower()
			break
		i += 1
	
	if breed_name == "":
		_add_debug_info("Error: Breed no encontrado")
		return
	
	# Check for A2D files (format: {id}-1-static.a2d)
	var a2d_bone_exists = FileAccess.file_exists(A2D_BONES_PATH + str(breed_id) + "-1-static.a2d")
	var a2d_skin_exists = FileAccess.file_exists(A2D_SKINS_PATH + str(breed_id * 10) + "-1-static.a2d")
	
	_add_debug_info("A2D files: Bone=" + str(a2d_bone_exists) + " Skin=" + str(a2d_skin_exists))
	
	# Load via AvatarSprite.gd (GDScript with native Zlib support)
	var loaded = _try_load_avatar_sprite_gd(breed_id)
	
	if not loaded:
		_add_debug_info("Falling back to WebP assets...")
		_load_webp_fallback(breed_name)

func _try_load_avatar_sprite_gd(breed_id: int) -> bool:
	"""Load avatar using AvatarSprite.gd (GDScript with native Zlib/Deflate)"""
	var avatar_scene = preload("res://scenes/AvatarSprite.tscn")
	var avatar = avatar_scene.instantiate()
	
	# Configure using the exported properties
	avatar.set("bones_id", breed_id)
	avatar.set("skin_id", breed_id * 10)
	avatar.set("bone_scale", 0.33)
	
	# Position at center of display
	avatar.position = Vector2(256, 256)
	avatar_display.add_child(avatar)
	current_avatar_node = avatar
	
	_add_debug_info("AvatarSprite.gd loaded successfully")
	return true

func _load_webp_fallback(breed_name: String) -> void:
	"""Load fallback WebP assets"""
	var atlas_path = "res://assets/avatars/" + breed_name + "/atlas.webp"
	var static_path = "res://assets/avatars/" + breed_name + "/static.webp"

	if FileAccess.file_exists(atlas_path):
		_load_webp_avatar(atlas_path, "ATLAS")
		return
	
	if FileAccess.file_exists(static_path):
		_load_webp_avatar(static_path, "STATIC")
		return

	_add_debug_info("WebP no encontrado")
	_try_load_fallback()

func _load_webp_avatar(webp_path: String, source: String) -> bool:
	"""Carga un WebP atlas o imagen individual"""
	var img = Image.new()
	if img.load(webp_path) != OK:
		_add_debug_info("Error cargando: " + webp_path)
		return false

	var tex = ImageTexture.create_from_image(img)
	var img_size = tex.get_size()

	# Crear sprite
	var sprite = Sprite2D.new()
	sprite.texture = tex

	# Para atlas, usar region; para imágenes completas, escalar
	if source == "ATLAS":
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, 64, 64)
		sprite.scale = Vector2.ONE * 3.0
	else:
		sprite.scale = Vector2.ONE * 0.3
		sprite.offset = img_size * 0.5 * -sprite.scale.x

	avatar_display.add_child(sprite)
	_add_debug_info("Cargado desde " + source + ": " + webp_path)
	_add_debug_info("Tamano: " + str(img_size.x) + "x" + str(img_size.y))

	return true

func _clear_avatar_display() -> void:
	if current_avatar_node != null:
		current_avatar_node.queue_free()
		current_avatar_node = null
		return
	
	var children = avatar_display.get_children()
	var i = 0
	while i < children.size():
		var child = children[i]
		if child is Sprite2D or child is Node2D:
			child.queue_free()
		i += 1

func _try_load_fallback() -> void:
	var breeds = ["iop", "eniripsa", "feca", "osamodas", "enutrof"]
	var i = 0
	while i < breeds.size():
		var breed = breeds[i]
		var static_path = "res://assets/avatars/" + breed + "/static.webp"
		if FileAccess.file_exists(static_path):
			_load_webp_avatar(static_path, "FALLBACK")
			_add_debug_info("Fallback: " + breed)
			return
		i += 1

func _add_debug_info(text: String) -> void:
	debug_output.text += text + "\n"
