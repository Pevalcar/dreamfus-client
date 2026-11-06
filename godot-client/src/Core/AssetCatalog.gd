## AssetCatalog.gd
## Autoload singleton for external asset loading from Alea installation.
##
## Provides a unified interface to resolve and load assets:
## - Resolve paths by kind and id
## - Open images directly to Image objects
## - Query availability and status
##
## Usage:
##   var path = AssetCatalog.resolve(AssetKind.Kind.ITEMS, "100001")
##   var image = AssetCatalog.load_image(AssetKind.Kind.ITEMS, "100001")
class_name AssetCatalog
extends RefCounted

## Maximum cache sizes
const MAX_IMAGE_CACHE_SIZE: int = 200
const MAX_JSON_CACHE_SIZE: int = 50

## Cache for loaded images (path → Image)
var _image_cache: Dictionary = { }

## Cache for JSON manifests
var _json_cache: Dictionary = { }


## Loads a picto hint image by breed ID.
## Breed 1 → 10.png, Breed 2 → 20.png, etc.
## Returns Texture2D or null if not found.
static func load_breed_emblem(breed: int) -> Texture2D:
	if breed < 1 or breed > 16:
		return null

	var root: String = get_root()
	if root == "":
		return null

	var emblem_path: String = root.path_join("d3picto").path_join("hint").path_join(
		str(breed * 10) + ".png"
	)

	# Validate path is within root (security check)
	# Using begins_with() instead of is_relative_to_root() (not available in Godot 4.8)
	if not emblem_path.begins_with(root):
		return null

	if not FileAccess.file_exists(emblem_path):
		return null

	# Load image using Image.load() (Godot 4.8 compatible)
	var img: Image = Image.new()
	img.load(emblem_path)
	if img.is_empty():
		return null

	return ImageTexture.create_from_image(img)


## Returns the current asset root path, or empty if not available.
static func get_root() -> String:
	return AssetRoot.find_root()


func _init():
	# Clear caches on initialization
	_image_cache.clear()
	_json_cache.clear()


## Returns true if an external Alea installation is available.
func is_available() -> bool:
	return AssetRoot.has_valid_root()


## Returns the current mode (NONE, LOCAL, DEV).
func get_mode() -> int:
	return AssetRoot.get_mode()


## Returns the mode as a human-readable string.
func get_mode_string() -> String:
	match get_mode():
		AssetRoot.Mode.NONE:
			return "none"
		AssetRoot.Mode.LOCAL:
			return "local"
		AssetRoot.Mode.DEV:
			return "dev"
		_:
			return "unknown"


## Resolves the full path for an asset by kind and id.
## Returns empty string if no valid root or path is invalid.
func resolve(kind: int, id: String) -> String:
	return AssetPath.resolve(kind, id)


## Loads an image from the asset catalog.
## Returns null if the image cannot be loaded.
## The image is cached for subsequent calls.
func load_image(kind: int, id: String) -> Image:
	if not AssetKind.is_image(kind):
		push_error(
			"AssetCatalog.load_image: Invalid kind for image loading: " + AssetKind.name_of(kind)
		)
		return null

	var path: String = resolve(kind, id)
	if path == "":
		return null

	# Check cache first
	if _image_cache.has(path):
		return _image_cache[path]

	# Load the image using Image.load() (Godot 4.8 compatible)
	var img: Image = Image.new()
	img.load(path)
	if img.is_empty():
		push_error(
			"AssetCatalog.load_image: Failed to load image at " + path
		)
		return null

	# Cache the image
	_cache_image(path, img)

	return img


## Loads an image with explicit path construction.
## Useful when you need to load images with numeric IDs directly.
func load_image_by_id(kind: int, id: String) -> Image:
	return load_image(kind, id)


## Opens a texture for a UI element by kind and id.
## Returns a Texture2D or null if loading fails.
func load_texture(kind: int, id: String) -> Texture2D:
	var img: Image = load_image(kind, id)
	if img == null:
		return null

	return ImageTexture.create_from_image(img)


## Loads a font file from the asset catalog.
## Returns the font path or empty string if not available.
func load_font(font_name: String) -> String:
	return resolve(AssetKind.Kind.FONTS, font_name)


## Loads a UI XML file by name.
## Returns the XML content as String, or empty string if not found.
func load_ui_xml(xml_name: String) -> String:
	var path: String = resolve(AssetKind.Kind.UXML, xml_name)
	if path == "":
		return ""

	return _load_text_file(path)


## Loads a theme CSS file.
## Returns the CSS content as String, or empty string if not found.
func load_theme() -> String:
	var root: String = get_root()
	if root == "":
		return ""

	var theme_path: String = root.path_join("uitk/theme.css")
	return _load_text_file(theme_path)


## Loads audio file path for playback.
## Returns the absolute path or empty string if not found.
func load_audio(sound_id: String) -> String:
	return resolve(AssetKind.Kind.AUDIO, sound_id)


## Loads a map file.
## Returns the path or empty string if not found.
## Uses MAPS kind (d3maps) for phase 3 container format (.d2p).
func load_map(map_id: String) -> String:
	return resolve(AssetKind.Kind.MAPS, map_id)


## Loads an image for items by numeric ID.
## This is the primary method for item icons.
func load_item_icon(gid: int) -> Texture2D:
	return load_texture(AssetKind.Kind.ITEMS, str(gid))


## Loads a spell icon by spell ID.
func load_spell_icon(spell_id: int) -> Texture2D:
	return load_texture(AssetKind.Kind.SPELLS, str(spell_id))


## Clears the image cache.
func clear_cache():
	_image_cache.clear()


## Clears all caches.
func clear_all_caches():
	_image_cache.clear()
	_json_cache.clear()


## Returns debug information about the catalog state.
func get_debug_info() -> Dictionary:
	return {
		"root": get_root(),
		"available": is_available(),
		"mode": get_mode_string(),
		"image_cache_size": _image_cache.size(),
		"json_cache_size": _json_cache.size(),
	}


## Checks if a specific file exists.
func file_exists(kind: int, id: String) -> bool:
	var path: String = resolve(kind, id)
	if path == "":
		return false

	return FileAccess.file_exists(path)


## Loads a text file from the given path.
func _load_text_file(path: String) -> String:
	if path == "":
		return ""

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	var content: String = file.get_as_text()
	file.close()
	return content


## Caches an image to prevent repeated disk access.
func _cache_image(path: String, img: Image):
	# Trim cache if too large
	while _image_cache.size() >= MAX_IMAGE_CACHE_SIZE:
		var keys: Array = _image_cache.keys()
		var first_key = keys[0]
		_image_cache.erase(first_key)

	_image_cache[path] = img
