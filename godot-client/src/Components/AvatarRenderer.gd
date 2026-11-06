## AvatarRenderer.gd
## Componente para renderizar avatares de personajes Dofus
## Usa WebP extraídos de archivos .a2d.z

extends Node2D
class_name AvatarRenderer

## Breed names mapping
const BREED_NAMES = {
	1: "iop",
	2: "eniripsa",
	3: "feca",
	4: "osamodas",
	5: "enutrof",
	6: "xelor",
	7: "cra",
	8: "sadida",
	9: "sacrier",
	10: "pandora",
	11: "tortur",
	12: "foguern",
	13: "huppu",
	14: "umo",
	15: "linu",
	16: "jaguar",
}

## Current breed info
var breed_id: int = 0
var breed_name: String = ""

# =============================================================================
# Public API
# =============================================================================

func set_breed_from_id(breed_id: int) -> void:
	"""Configura el avatar usando ID de raza"""
	self.breed_id = breed_id
	breed_name = BREED_NAMES.get(breed_id, "unknown")
	_update_avatar()


func set_character(look_string: String) -> void:
	"""Configura el personaje usando un look string (placeholder)"""
	# TODO: parsear look_string para configurar equipamiento
	_add_debug_info("Look string: " + look_string)


# =============================================================================
# Internal methods
# =============================================================================

func _update_avatar() -> void:
	"""Actualiza la visualización del avatar"""
	# Limpiar nodos hijos
	_clear_avatar()

	# Primero intentar con atlas.webp (completo con animaciones)
	var breed_dir = "res://assets/avatars/%s/" % breed_name
	var atlas_path = breed_dir + "atlas.webp"
	var static_path = breed_dir + "static.webp"

	# Intentar atlas primero
	if FileAccess.file_exists(atlas_path):
		_load_webp_avatar(atlas_path, 1024, 1024)
		return

	# Si no hay atlas, intentar con static
	if FileAccess.file_exists(static_path):
		_load_webp_avatar(static_path, 1024, 512)
		return

	# Fallback: intentar con cualquier WebP disponible
	_try_load_fallback()


func _clear_avatar() -> void:
	"""Limpia el display de avatar"""
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()


func _load_webp_avatar(webp_path: String, atlas_w: int, atlas_h: int) -> void:
	"""Carga un avatar desde un archivo WebP (atlas)"""
	var img = Image.new()
	if img.load(webp_path) != OK:
		return

	var tex = ImageTexture.create_from_image(img)

	# Crear sprite que muestre solo el primer frame del atlas
	# Los avatares Dofus tienen frames de 64x64 en el atlas
	var sprite = Sprite2D.new()
	sprite.texture = tex

	# Habilitar región para mostrar solo el primer frame (64x64)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 64, 64)

	# Escalar para que el avatar sea visible (3x = 192px)
	var scale = 3.0
	sprite.scale = Vector2(scale, scale)

	add_child(sprite)


func _try_load_fallback() -> void:
	"""Intenta cargar cualquier avatar disponible como fallback"""
	var breeds = ["iop", "eniripsa", "feca", "osamodas", "enutrof"]

	for breed in breeds:
		var webp_path = "res://assets/avatars/%s/static.webp" % breed
		if FileAccess.file_exists(webp_path):
			_load_webp_avatar(webp_path, 1024, 512)
			return