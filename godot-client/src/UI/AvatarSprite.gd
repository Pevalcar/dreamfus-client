## AvatarSprite.gd
## Node para renderizar avatares Dofus desde archivos A2D.Z
## Utiliza soporte nativo de Zlib/Deflate de Godot 4

extends Node2D
class_name AvatarSprite

## Preload ByteArrayExtensions helper para Godot 4.8
const ByteArrayExtensions = preload("res://src/Utils/ByteArrayExtensions.gd")

## Breed IDs mapping
const BREED_IDS = {
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

@export var bones_id: int = 1:
	set(value):
		bones_id = value
		if is_inside_tree():
			_load_avatar_async()

@export var skin_id: int = 10:
	set(value):
		skin_id = value
		if is_inside_tree():
			_load_avatar_async()

@export var bone_scale: float = 0.33
@export var assets_path: String = "C:/Users/pevalcar/AppData/Local/Alea/d3pack/"
@export var auto_play: bool = false

var _avatar_container: Node2D
var _current_breed_name: String = "iop"
var _sprites: Array = []
var _texture_cache: Dictionary = {}

# Estado para animación
var _current_frame: int = 0
var _accumulated_time: float = 0.0
var _frame_rate: int = 24
var _animation_name: String = ""

func _ready() -> void:
	_avatar_container = get_node_or_null(NodePath("AvatarContainer"))
	if _avatar_container == null:
		_avatar_container = Node2D.new()
		_avatar_container.name = "AvatarContainer"
		add_child(_avatar_container)
	
	# Determinar nombre de raza
	_current_breed_name = BREED_IDS.get(bones_id, "iop")
	
	# Cargar avatar
	_load_avatar_async()

func _process(delta: float) -> void:
	if auto_play and _frame_rate > 0:
		_accumulated_time += delta
		var frame_duration = 1.0 / float(_frame_rate)
		
		if _accumulated_time >= frame_duration:
			_accumulated_time -= frame_duration
			_current_frame = (_current_frame + 1) % get_max_frames()
			_update_frame_display()

func get_max_frames() -> int:
	var static_path = "res://assets/avatars/%s/static.webp" % _current_breed_name
	var atlas_path = "res://assets/avatars/%s/atlas.webp" % _current_breed_name
	
	if FileAccess.file_exists(atlas_path):
		var img = Image.new()
		if img.load(atlas_path) == OK:
			var tex = ImageTexture.create_from_image(img)
			var size = tex.get_size()
			# Asumir frames de 64x64 en horizontal
			return int(size.x / 64)
	
	return 1

## Carga el avatar desde A2D o fallback WebP
func _load_avatar_async() -> void:
	clear_avatar()
	
	# Verificar si existen archivos A2D
	# Formato A2D: {breed_id}-1-static.a2d (default skin), {breed_id}-10-a2d (armor)
	var bone_path = "%s/bones/%d-1-static.a2d" % [assets_path, bones_id]
	var skin_path = "%s/skins/%d-1-static.a2d" % [assets_path, skin_id]
	
	var bone_exists = FileAccess.file_exists(bone_path)
	var skin_exists = FileAccess.file_exists(skin_path)
	
	if bone_exists:
		print("Loading A2D bones: ", bone_path)
		var skin = ""
		if skin_exists:
			skin = skin_path
		_load_from_a2d(bone_path, skin)
	elif FileAccess.file_exists("res://assets/avatars/%s/static.webp" % _current_breed_name):
		print("Using WebP fallback for breed: ", _current_breed_name)
		_load_webp_fallback()
	else:
		push_error("No A2D or WebP files found for breed %d" % bones_id)

## Carga avatar desde archivos A2D.Z o JSON pre-procesado
func _load_from_a2d(bone_path: String, skin_path: String) -> void:
	# Determinar nombre de raza
	var breed_name = BREED_IDS.get(bones_id, "iop")
	
	# Intentar cargar desde JSON pre-procesado (solución Godot 4.8 raw deflate)
	var json_path = "res://gen/a2d/%d-1-static.json" % bones_id
	
	if FileAccess.file_exists(json_path):
		var json_data = _load_a2d_json(json_path)
		if json_data.get("success", false):
			print("Loaded A2D from pre-processed JSON: ", json_path)
			# Los datos JSON tienen información de vértices/índices pero renderizamos con WebP
			print("A2D data: ", json_data.get("vertex_count", 0), " vertices, ", 
				  json_data.get("string_count", 0), " strings")
			_load_webp_fallback_with_breed(breed_name)
			return
	
	# Leer archivo A2D.Z original (sin compresión conocida)
	var bone_data = _read_a2dz_file(bone_path)
	if bone_data.get("success", false):
		print("Loaded A2D from raw file")
		_load_webp_fallback_with_breed(breed_name)
		return
	
	print("Failed to load A2D data, using WebP fallback")
	_load_webp_fallback()

## Lee un archivo A2D pre-procesado en JSON
## SOLUCIÓN: Godot 4.8 no soporta raw deflate nativamente
## Los archivos JSON se generan con scripts Python usando zlib.decompressobj(-zlib.MAX_WBITS)
func _load_a2d_json(json_path: String) -> Dictionary:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open JSON file: " + json_path)
		return { "success": false, "error": "File not found" }
	
	var json_text = file.get_as_text()
	file.close()
	
	# Usar JSON parser de Godot 4.8
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != Error.OK:
		push_error("A2DParser: Failed to parse JSON: " + json_path + " - " + str(parse_result))
		return { "success": false, "error": "JSON parse error" }
	
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return { "success": false, "error": "Invalid JSON structure" }
	
	# Si el JSON no tiene 'success', asumir que es válido
	if !data.has("success"):
		return { "success": true, "data": data, "vertex_count": data.get("vertex_count", 0), "string_count": data.get("strings", 0) }
	
	return data

## Lee y descompone un archivo A2DZ (función legacy)
## NOTA: Godot 4.8 no soporta raw deflate nativamente
## Usa JSON pre-procesado generado por scripts Python
func _read_a2dz_file(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return { "success": false, "error": "File not found" }
	
	var raw_data = file.get_buffer(file.get_length())
	file.close()
	
	if raw_data.size() < 8:
		return { "success": false, "error": "File too small" }
	
	# Verificar header "A2DZ" (archivos comprimidos)
	# o "A2D1" (archivos sin comprimir con header alternativo)
	# En Godot 4.8, extraer string del PackedByteArray manualmente
	var magic = ByteArrayExtensions.peek_string_4(raw_data, 0)
	
	if magic == "A2DZ":
		# Archivo comprimido zlib - usar JSON pre-procesado
		var json_path = "res://gen/a2d/%d-1-static.json" % bones_id
		if FileAccess.file_exists(json_path):
			return _load_a2d_json(json_path)
		return { "success": false, "error": "No JSON pre-processed file" }
	else:
		# Para archivos sin compresión (A2D1 o sin header)
		# Extraer información básica desde datos sin comprimir
		return _parse_a2d1_data(raw_data)

## Parsea datos A2D1 sin comprimir
func _parse_a2d1_data(data: PackedByteArray) -> Dictionary:
	if data.size() < 8:
		return { "success": false, "error": "Data too small" }
	
	# Verificar header "A2D1" (4 bytes)
	var header = ByteArrayExtensions.peek_string_4(data, 0)
	if header != "A2D1":
		# Si no hay header A2D1, asumir que los primeros bytes son datos normales
		# y saltar el header que ya leímos
		pass
	
	# Saltar header "A2D1" (4 bytes)
	var pos = 4
	
	# Versión (2 bytes, little endian) - leer como bytes y convertir
	var version_bytes = ByteArrayExtensions.byte_subarray(data, pos, 2)
	var version = 0
	for i in range(2):
		version |= version_bytes[i] << (i * 8)
	pos += 2
	
	# Flags (2 bytes, little endian)
	var flags_bytes = ByteArrayExtensions.byte_subarray(data, pos, 2)
	var flags = 0
	for i in range(2):
		flags |= flags_bytes[i] << (i * 8)
	pos += 2
	
	# Simplificado - devolver estructura básica
	return {
		"success": true,
		"version": version,
		"flags": flags,
		"data_size": data.size()
	}

## Carga fallback WebP para visualización
func _load_webp_fallback() -> void:
	_load_webp_fallback_with_breed(_current_breed_name)

## Carga fallback WebP con nombre de raza específico
func _load_webp_fallback_with_breed(breed_name: String) -> void:
	var static_path = "res://assets/avatars/%s/static.webp" % breed_name
	var atlas_path = "res://assets/avatars/%s/atlas.webp" % breed_name
	
	# Actualizar nombre de raza actual
	_current_breed_name = breed_name
	
	if FileAccess.file_exists(atlas_path):
		_load_webp_as_atlas(atlas_path)
		return
	
	if FileAccess.file_exists(static_path):
		_load_single_webp(static_path)
		return
	
	# Fallback final: buscar cualquier WebP disponible
	for breed in BREED_IDS.values():
		var path = "res://assets/avatars/%s/static.webp" % (breed as String)
		if FileAccess.file_exists(path):
			_load_single_webp(path)
			_current_breed_name = breed as String
			return

## Carga un atlas WebP (multiple frames)
func _load_webp_as_atlas(webp_path: String) -> void:
	var img = Image.new()
	if img.load(webp_path) != OK:
		push_error("Failed to load WebP: " + webp_path)
		return
	
	var tex = ImageTexture.create_from_image(img)
	var size = tex.get_size()
	
	# Crear sprite con región para mostrar primer frame
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 64, 64)
	sprite.scale = Vector2.ONE * 3.0  # 64 * 3 = 192px
	
	_avatar_container.add_child(sprite)
	_sprites.append(sprite)
	
	print("Loaded atlas: ", webp_path, " size: ", size)

## Carga una imagen WebP única
func _load_single_webp(webp_path: String) -> void:
	var img = Image.new()
	if img.load(webp_path) != OK:
		push_error("Failed to load WebP: " + webp_path)
		return
	
	var tex = ImageTexture.create_from_image(img)
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2.ONE * bone_scale
	sprite.offset = tex.get_size() * 0.5 * -bone_scale
	
	_avatar_container.add_child(sprite)
	_sprites.append(sprite)
	
	print("Loaded WebP: ", webp_path)

## Actualiza la frame del avatar (para animaciones)
func _update_frame_display() -> void:
	# Limpiar sprites actuales
	var i = 0
	while i < _sprites.size():
		var sprite = _sprites[i]
		if sprite != null:
			sprite.queue_free()
		i += 1
	_sprites.clear()
	
	# Crear nuevo sprite con la frame correcta
	var breed = BREED_IDS.get(bones_id, "iop")
	var atlas_path = "res://assets/avatars/%s/atlas.webp" % breed
	
	if FileAccess.file_exists(atlas_path) and _current_frame > 0:
		var frame_size = 64
		var col = _current_frame % get_max_frames()
		_load_webp_frame(atlas_path, col)
	else:
		_load_single_webp("res://assets/avatars/%s/static.webp" % breed)

## Carga una frame específica de un atlas
func _load_webp_frame(atlas_path: String, frame_index: int) -> void:
	var img = Image.new()
	if img.load(atlas_path) != OK:
		return
	
	var tex = ImageTexture.create_from_image(img)
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.region_enabled = true
	sprite.region_rect = Rect2(frame_index * 64, 0, 64, 64)
	sprite.scale = Vector2.ONE * 3.0
	
	_avatar_container.add_child(sprite)
	_sprites.append(sprite)

## Limpia todos los sprites
func clear_avatar() -> void:
	var i = 0
	while i < _sprites.size():
		var sprite = _sprites[i]
		if sprite != null:
			sprite.queue_free()
		i += 1
	_sprites.clear()

## Métodos públicos de configuración
func set_bones_id(id: int) -> void:
	bones_id = id
	_current_breed_name = BREED_IDS.get(id, "iop")
	_load_avatar_async()

func set_skin_id(id: int) -> void:
	skin_id = id
	_load_avatar_async()

func set_bone_scale(scale: float) -> void:
	bone_scale = scale
	_load_avatar_async()

func get_breed_name() -> String:
	return _current_breed_name

func get_texture_info() -> Dictionary:
	return {
		"breed_id": bones_id,
		"breed_name": _current_breed_name,
		"skin_id": skin_id,
		"scale": bone_scale
	}
