## A2DParser.gd
## Parser para el formato A2D.Z (Ankama Animated Display)
## 
## Formato: A2DZ → A2D1 → WebP images
## Usado para renderizar avatares de personajes en Dofus/DreamFus
##
## Referencias:
## - src/a2d/mod.rs (Rust reference implementation)
## - A2D_FLOW.md (documentación del formato)
##
## NOTA: Este parser implementa el esqueleto del formato. La parseación completa
## de sprites y la extracción de WebP requiere ajustes según el análisis real
## de los archivos de juego.

extends RefCounted
class_name A2DParser

## Constantes del formato A2D.Z
const MAGIC_A2DZ: PackedStringArray = ["A", "2", "D", "Z"]
const MAGIC_A2D1: PackedStringArray = ["A", "2", "D", "1"]
const WEBP_RIFF: String = "RIFF"
const WEBP_WEBP: String = "WEBP"

## Tamaño máximo de archivo (8MB como en el parser Rust)
const MAX_FILE_SIZE: int = 8 * 1024 * 1024

## Resultado del parsing
class_name A2DParseResult
extends RefCounted
var sprites: Array = []  # [{"name": String, "offset": int, "size": int}]
var images: Array = []   # [{"sprite_name": String, "width": int, "height": int, "data": PackedByteArray}]
var error: String = ""

## Header de A2DZ
class_name A2DZHeader
extends RefCounted
var magic: PackedStringArray = []
var version_byte: int = 0

## Header de A2D1
class_name A2D1Header
extends RefCounted
var magic: PackedStringArray = []
var version: int = 0

# =============================================================================
# API Principal
# =============================================================================

## Parsea un archivo A2D.Z desde una ruta
static func parse_file(path: String) -> A2DParseResult:
	var result := A2DParseResult.new()
	
	if not FileAccess.file_exists(path):
		result.error = "File not found: %s".format([path])
		return result
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		result.error = "Failed to open file: %s".format([path])
		return result
	
	# Leer todo el archivo
	var data := file.get_buffer(file.get_length())
	file.close()
	
	return parse_bytes(data)

## Parsea datos A2D.Z desde un PackedByteArray
static func parse_bytes(data: PackedByteArray) -> A2DParseResult:
	var result := A2DParseResult.new()
	
	# Verificar tamaño máximo
	if data.size() > MAX_FILE_SIZE:
		result.error = "File too large: %d bytes (max: %d)".format([data.size(), MAX_FILE_SIZE])
		return result
	
	# Parsear header A2DZ
	var header_result := _parse_a2dz_header(data)
	if header_result.error != "":
		result.error = header_result.error
		return result
	
	# Descomprimir
	var decompressed := _decompress_a2dz(data)
	if decompressed == null or decompressed.size() == 0:
		result.error = "Decompression failed"
		return result
	
	# Parsear header A2D1
	var a2d1_header_result := _parse_a2d1_header(decompressed)
	if a2d1_header_result.error != "":
		result.error = a2d1_header_result.error
		return result
	
	# Extraer sprites e imágenes
	result.sprites = _extract_sprites(decompressed)
	result.images = _extract_webp_images(decompressed)
	
	return result

# =============================================================================
# Parsing Headers
# =============================================================================

## Parsea y valida el header A2DZ sin descomprimir
static func _parse_a2dz_header(data: PackedByteArray) -> A2DZHeader:
	var result := A2DZHeader.new()
	
	if data.size() < 8:
		result.magic = []
		return result
	
	# Verificar magic "A2DZ"
	for i in range(4):
		result.magic.append(char(data[i]))
	
	if result.magic != MAGIC_A2DZ:
		result.error = "Invalid magic: expected A2DZ, got %s".format([result.magic.join("")])
		return result
	
	# Versión
	result.version_byte = data[4]
	
	return result

## Parsea el header A2D1 después de descompresión
static func _parse_a2d1_header(data: PackedByteArray) -> A2D1Header:
	var result := A2D1Header.new()
	
	if data.size() < 8:
		result.error = "Data too short for A2D1 header"
		return result
	
	# Verificar magic "A2D1"
	for i in range(4):
		result.magic.append(char(data[i]))
	
	if result.magic != MAGIC_A2D1:
		result.error = "Invalid magic: expected A2D1, got %s".format([result.magic.join("")])
		return result
	
	# Versión (u32 little-endian)
	result.version = Bytes.get_u32_le(data, 4)
	
	return result

# =============================================================================
# Decompression
# =============================================================================

## Descomprime datos A2DZ usando zlib/deflate
## Godot tiene soporte nativo para zlib en el núcleo
static func _decompress_a2dz(data: PackedByteArray) -> PackedByteArray:
	# Header A2DZ: 8 bytes (magic 4 + version 1 + padding 3)
	if data.size() < 8:
		return []
	
	# Datos comprimidos empiezan en offset 8
	var compressed_data: PackedByteArray = data.slice(8)
	
	# Usar MathDeflate de Godot para descomprimir
	# NOTA: Godot 4.8 usa zlib, no raw deflate
	# Necesitamos agregar un header zlib o usar una extensión
	
	return _zlib_decompress(compressed_data)

## Descompresión zlib (wrapper para compatibilidad)
static func _zlib_decompress(data: PackedByteArray) -> PackedByteArray:
	# Godot no tiene una API directa para zlib en GDScript
	# Necesitaríamos usar un GDExtension o pre-procesar los archivos
	#
	# Alternativa: usar FileAccess.open_with_compressed() si disponible
	# o implementar un pequeño wrapper C++ que use zlib
	
	# Por ahora, retornar datos vacíos y documentar esta limitación
	push_error("A2DParser: Zlib decompression not directly available in GDScript. Consider using a GDExtension or pre-processing files.")
	return []

# =============================================================================
# Sprite and Image Extraction
# =============================================================================

## Extrae información de sprites del A2D1 parsing
static func _extract_sprites(data: PackedByteArray) -> Array:
	var sprites: Array = []
	
	if data.size() < 8:
		return sprites
	
	# El formato de sprite varía según el versión y el análisis del juego
	# Este es un esqueleto básico que debe ser rellenado con datos reales
	
	# Buscar patrones de sprite en los datos
	# Los sprites de Dofus suelen tener estructuras específicas
	
	return sprites

## Extrae imágenes WebP de los datos A2D1
static func _extract_webp_images(data: PackedByteArray) -> Array:
	var images: Array = []
	
	# Buscar firmas RIFF...WEBP
	var offset := 8  # Saltar header A2D1 + versión
	var image_index := 0
	
	while offset + 12 <= data.size():
		# Verificar si hay un contenedor WebP
		if data[offset] == ord("R") and \
		   data[offset + 1] == ord("I") and \
		   data[offset + 2] == ord("F") and \
		   data[offset + 3] == ord("F") and \
		   offset + 8 < data.size() and \
		   data[offset + 8] == ord("W") and \
		   data[offset + 9] == ord("E") and \
		   data[offset + 10] == ord("B") and \
		   data[offset + 11] == ord("P"):
			
			# Leer tamaño del archivo WebP
			var riff_size := Bytes.get_u32_le(data, offset + 4)
			var webp_total_size := 12 + riff_size
			
			if offset + webp_total_size <= data.size():
				var image_data := data.slice(offset, offset + webp_total_size)
				var dimensions := _get_webp_dimensions(image_data)
				
				images.append({
					"sprite_name": "sprite_%d".format([image_index]),
					"width": dimensions.x,
					"height": dimensions.y,
					"data": image_data
				})
				
				image_index += 1
				offset += webp_total_size
			else:
				offset += 1
		else:
			offset += 1
	
	return images

## Obtiene dimensiones de una imagen WebP
static func _get_webp_dimensions(data: PackedByteArray) -> Vector2:
	# WebP tiene dimensiones en los chunks VP8 o VP8L
	# Este es un parser básico - puede necesitar ajustes
	
	if data.size() < 12:
		return Vector2.ZERO
	
	# Saltar header RIFF...WEBP (12 bytes)
	var offset := 12
	
	while offset + 8 <= data.size():
		var chunk_type := data.subptr(offset, 4)
		var chunk_size := Bytes.get_u32_le(data, offset + 4)
		
		# Verificar chunk VP8 (lossy)
		if chunk_type[0] == ord("V") and \
		   chunk_type[1] == ord("P") and \
		   chunk_type[2] == ord("8") and \
		   chunk_type[3] == ord(" "):
			# Dimensiones en offset 0x12-0x17 (18-23)
			if offset + 0x18 <= data.size():
				var width := Bytes.get_u16_le(data, offset + 0x12) + 1
				var height := Bytes.get_u16_le(data, offset + 0x16) + 1
				return Vector2(width, height)
		
		# Verificar chunk VP8L (lossless)
		if chunk_type[0] == ord("V") and \
		   chunk_type[1] == ord("P") and \
		   chunk_type[2] == ord("8") and \
		   chunk_type[3] == ord("L"):
			# Dimensiones en byte 6-7 del chunk
			if offset + 10 <= data.size():
				var features := Bytes.get_u32_le(data, offset + 6)
				var w_hex := (features & 0x3FFF) as int
				var h_hex := ((features >> 14) & 0x3FFF) as int
				return Vector2(w_hex + 1, h_hex + 1)
		
		# Saltar al siguiente chunk
		offset += 8 + chunk_size
	
	return Vector2.ZERO

# =============================================================================
# Utility Functions for Godot
# =============================================================================

## Carga una imagen WebP desde datos brutejos
static func load_webp_from_data(data: PackedByteArray) -> Image:
	var image := Image.new()
	
	# Godot 4.8 puede cargar WebP directamente con Image.load()
	# pero necesita un archivo temporal o usar Image.load_from_buffer()
	
	var temp_path := "res://temp_webp_cache_%d.webp".format([Time.get_ticks_msec()])
	
	# Guardar temporalmente
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file != null:
		file.store_buffer(data)
		file.close()
		
		# Cargar con Image.load()
		image.load(temp_path)
		
		# Limpiar archivo temporal
		DirAccess.remove_absolute(temp_path)
	
	return image

## Convierte un PackedByteArray a Texture2D
static func image_to_texture(img: Image) -> Texture2D:
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)