## A2DParser.gd - Parser para el formato A2D.Z (Ankama Animated Display)
## 
## LIMITACIÓN CONOCIDA Godot 4.8:
## PackedByteArray.decompress() NO soporta raw deflate (formato usado por A2D.Z)
## Solución: Usar JSON pre-procesado generado por scripts Python
## 
## Uso alternativo:
## - Scripts: scripts/generate_a2d_json.py
## - JSON: gen/a2d/{id}-1-static.json
## - Documentación: docs/A2D_RAW_DEFLATE_WORKAROUND.md

extends RefCounted
class_name A2DParser

## Preload ByteArrayExtensions helper para Godot 4.8
const ByteArrayExtensions = preload("res://src/Utils/ByteArrayExtensions.gd")

## Constantes del formato A2D.Z
const MAGIC_A2DZ = "A2DZ"
const MAGIC_A2D1 = "A2D1"

## Tamaño máximo de archivo (8MB)
const MAX_FILE_SIZE = 8 * 1024 * 1024

## Parsea un archivo A2D.Z desde una ruta
func parse_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("A2DParser: File not found: " + path)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("A2DParser: Failed to open file: " + path)
		return {}
	
	var data = file.get_buffer(file.get_length())
	file.close()
	
	return parse_bytes(data)

## Parsea datos A2D.Z desde un PackedByteArray
func parse_bytes(data: PackedByteArray) -> Dictionary:
	# Verificar tamaño máximo
	if data.size() > MAX_FILE_SIZE:
		push_error("A2DParser: File too large: %d bytes" % data.size())
		return {}
	
	# Parsear header A2DZ
	if data.size() < 8:
		push_error("A2DParser: Data too short")
		return {}
	
	# Descomprimir usando Zlib nativo de Godot 4
	var decompressed = _decompress_a2dz(data)
	if decompressed.is_empty():
		push_error("A2DParser: Decompression failed")
		return {}
	
	# Verificar header A2D1
	var a2d1_magic = ByteArrayExtensions.peek_string_4(decompressed, 0)
	if a2d1_magic != MAGIC_A2D1:
		push_error("A2DParser: Invalid A2D1 magic")
		return {}
	
	# Parsear versión A2D1
	var reader = A2DReader.new(decompressed)
	var version = reader.read_u16()
	
	if version != 1:
		push_error("A2DParser: Unsupported version: %d" % version)
		return {}
	
	# Parsear flags
	var a2d_flags = reader.read_u16()
	
	# Leer tabla de strings
	var strings = _read_string_table(reader)
	
	# Parsear vértices
	var vertex_count = reader.read_u32()
	var positions = []
	var uvs = []
	var i = 0
	while i < vertex_count:
		positions.append(reader.read_f32())  # x
		positions.append(reader.read_f32())  # y
		uvs.append(reader.read_u16())
		uvs.append(reader.read_u16())
		i += 1
	reader.align(4)
	
	var colors_buffer = reader.read_bytes(vertex_count)
	reader.align(4)
	
	# Leer índices
	var index_count = reader.read_u32()
	var indices = reader.read_u16_array(index_count)
	reader.align(4)
	
	# Leer gráficos (parts)
	var n_parts = reader.read_u32()
	var parts = {}
	i = 0
	while i < n_parts:
		var graphic = _read_graphic(reader, strings)
		if graphic.has("key") and graphic.key != -1:
			parts[graphic.key] = graphic
		i += 1
	
	# Leer referencias
	var referenced = _read_string_list(reader, strings)
	var empty_customisations = _read_string_list(reader, strings)
	
	# Leer definición/animación si está presente
	var definition = {}
	var animations = {}
	
	if (flags & 1) != 0:
		var frame_rate = reader.read_u32()
		var max_node_count = reader.read_u32()
		var exposed = _read_string_list(reader, strings)
		
		var n_graphics = reader.read_u32()
		var def_graphics = []
		i = 0
		while i < n_graphics:
			def_graphics.append(_read_graphic(reader, strings))
			i += 1
		
		var n_anims = reader.read_u32()
		i = 0
		while i < n_anims:
			var anim_name = strings[reader.read_u32()] if reader.read_u32() < strings.size() else ("anim_" + str(i))
			reader.seek(reader.position - 4)
			var name_idx = reader.read_u32()
			var bounds = reader.read_float_array(4)
			var offset = reader.read_u32()
			var length = reader.read_u32()
			
			if name_idx < strings.size():
				animations[strings[name_idx]] = {
					"name": strings[name_idx],
					"bounds": bounds,
					"offset": offset,
					"length": length
				}
			i += 1
		
		definition = {
			"frame_rate": frame_rate,
			"max_node_count": max_node_count,
			"exposed_node_names": exposed,
			"graphics": def_graphics,
			"animations": animations
		}
	
	# Leer blob de animación
	var blob_len = reader.read_u32()
	var blob = reader.read_bytes(blob_len)
	
	# Parsear animaciones del blob
	if not animations.is_empty() and blob.size() > 0:
		var anim_reader = A2DReader.new(blob)
		for key in animations.keys():
			var anim = animations[key]
			if anim.offset + anim.length <= blob.size():
				anim.data = _byte_subarray(blob, anim.offset, anim.length)
	
	# Leer texturas
	var n_textures = reader.read_u32()
	var textures = []
	i = 0
	while i < n_textures:
		var kind_byte = reader.read_u8()
		reader.read_u8()  # padding
		var width = reader.read_u16()
		var height = reader.read_u16()
		reader.read_u16()  # padding
		var b_len = reader.read_u32()
		var t_bytes = reader.read_bytes(b_len)
		reader.align(4)
		
		textures.append({
			"kind": kind_byte == 1 ? "webp" : "png",
			"width": width,
			"height": height,
			"bytes": t_bytes
		})
		i += 1
	
	return {
		"version": version,
		"flags": flags,
		"strings": strings,
		"vertex_count": vertex_count,
		"positions": positions,
		"uvs": uvs,
		"colors": colors_buffer,
		"indices": indices,
		"parts": parts,
		"referenced": referenced,
		"empty_customisations": empty_customisations,
		"definition": definition,
		"textures": textures
	}

## Descompresión Raw Deflate (formato A2DZ de Dofus)
## El archivo A2DZ usa raw deflate (no zlib estándar con header)
## NOTA: Godot 4.8 PackedByteArray.decompress() NO soporta raw deflate
## Solución: Verificar si existe JSON pre-procesado y usarlo
func _decompress_a2dz(data: PackedByteArray) -> PackedByteArray:
	if data.size() < 8:
		return PackedByteArray()
	
	# Datos comprimidos empiezan en offset 8
	var compressed = ByteArrayExtensions.byte_subarray_from(data, 8)
	
	if compressed.is_empty():
		return PackedByteArray()
	
	# ISSUE: Godot 4.8 PackedByteArray.decompress(comp_size, comp_type) no funciona
	# con raw deflate ( necesario para A2DZ de Dofus)
	#
	# El archivo A2DZ contiene raw deflate (wbits=-15 en zlib)
	# Godot espera datos zlib estándar con header de 2 bytes (0x78)
	#
	# Solución: Verificar si existe JSON pre-procesado
	# El archivo bones_id se establece externamente al parser
	
	# Este método retorna empty para forzar uso de WebP fallback
	# Para usar JSON pre-procesado, llamar a _load_json_avatars() directamente
	push_error("A2DParser: Raw deflate not supported in Godot 4.8. Use pre-processed JSON or WebP fallback.")
	return PackedByteArray()

## Carga datos de un archivo A2D desde JSON pre-procesado
## SOLUCIÓN: Los scripts Python generan JSON que Godot puede leer sin descompresión
func load_from_json(json_path: String) -> Dictionary:
	if not FileAccess.file_exists(json_path):
		push_error("A2DParser: JSON file not found: " + json_path)
		return {}
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("A2DParser: Failed to open JSON: " + json_path)
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != Error.OK:
		push_error("A2DParser: Failed to parse JSON: " + str(parse_result))
		return {}
	
	return json.get_data()

## Lee tabla de strings
func _read_string_table(reader: A2DReader) -> Array[String]:
	var count = reader.read_u32()
	var strings: Array[String] = []
	var i = 0
	while i < count:
		var slen = reader.read_u16()
		var sbytes = reader.read_bytes(slen)
		strings.append(sbytes.get_string_from_utf8())
		i += 1
	reader.align(4)
	return strings

## Lee lista de strings (referencias)
func _read_string_list(reader: A2DReader, strings: Array) -> Array:
	var count = reader.read_u32()
	var list: Array = []
	var i = 0
	while i < count:
		var idx = reader.read_u32()
		if idx < strings.size():
			list.append(strings[idx])
		else:
			list.append("")
		i += 1
	return list

## Lee un graphic/struct
func _read_graphic(reader: A2DReader, strings: Array) -> Dictionary:
	var name_idx = reader.read_u32()
	var key = reader.read_u32()
	var n_entries = reader.read_u32()
	
	var entries = []
	var i = 0
	while i < n_entries:
		var sym_id = reader.read_i32()
		var e_count = reader.read_i32()
		var mat = reader.read_float_array(6)
		# Transform: [a, b, c, d, tx, ty] -> render [a, -b, -c, d, tx, -ty]
		entries.append({
			"symbol_id": sym_id,
			"entries_count": e_count,
			"matrix": [mat[0], -mat[1], -mat[2], mat[3], mat[4], -mat[5]]
		})
		i += 1
	
	var n_chunks = reader.read_u32()
	var chunks = []
	i = 0
	while i < n_chunks:
		chunks.append({
			"start_vertex": reader.read_u32(),
			"vertex_count": reader.read_u32(),
			"start_index": reader.read_u32(),
			"index_count": reader.read_u32(),
			"texture": reader.read_u8(),
			"mask": reader.read_u8()
		})
		reader.read_u16()  # padding
		i += 1
	
	return {
		"name": strings[name_idx] if name_idx < strings.size() else ("graphic_" + str(key)),
		"key": key,
		"entries": entries,
		"chunks": chunks
	}

## Lee animación desde blob de datos
func parse_animation_blob(data: PackedByteArray) -> Dictionary:
	if data.size() < 8:
		return {}
	
	var reader = A2DReader.new(data)
	var frame_count = reader.read_u16()
	var node_count = reader.read_u16()
	var label_count = reader.read_u16()
	
	if frame_count == 0 or node_count == 0:
		push_error("A2DParser: Empty timeline")
		return {}
	
	# Saltar 8 bytes
	reader.seek(8)
	
	# Leer labels
	var labels = []
	var i = 0
	while i < label_count:
		var frame = reader.read_u16()
		var vlen = reader.read_u8()
		var l_bytes = reader.read_bytes(vlen)
		labels.append({
			"frame": frame,
			"label": l_bytes.get_string_from_utf8()
		})
		i += 1
	reader.align(2)
	reader.align(4)
	
	# Leer offsets de frames
	var offsets = []
	i = 0
	while i < frame_count:
		offsets.append(reader.read_i32())
		i += 1
	
	# Leer datos de frames
	var nodes = {}
	var frames = []
	
	i = 0
	while i < frame_count:
		reader.seek(offsets[i])
		var row = []
		var n = 0
		while n < node_count:
			var idx = reader.read_i16()
			
			if idx < 0 or idx >= node_count:
				push_error("A2DParser: Node index out of range: " + str(idx))
			
			# Lee estado del nodo
			var state = {
				"node": idx,
				"sprite_index": -1,
				"customisation_index": -1,
				"children_recursive_count": -1,
				"opacity": 1.0,
				"multiply": [],
				"additive": [],
				"matrix": [],
				"mask_flags": 0,
				"blend_mode": 0
			}
			
			var flags = reader.read_u8()
			if (flags & 2) != 0:
				state.opacity = reader.read_u8() / 127.0
			reader.align(4)
			
			if (flags & 33) != 0:
				state.sprite_index = reader.read_i16()
				state.customisation_index = reader.read_i16()
				state.children_recursive_count = reader.read_i16()
				reader.align(4)
			
			if (flags & 4) != 0:
				state.multiply = [
					reader.read_i8() / 127.0, reader.read_i8() / 127.0,
					reader.read_i8() / 127.0, reader.read_i8() / 127.0
				]
			
			if (flags & 8) != 0:
				state.additive = [
					reader.read_i8() / 127.0, reader.read_i8() / 127.0,
					reader.read_i8() / 127.0, reader.read_i8() / 127.0
				]
			
			if (flags & 16) != 0:
				state.matrix = [
					reader.read_f32(), reader.read_f32(), reader.read_f32(),
					state.matrix.size() < 6 ? 0 : state.matrix[3],
					reader.read_f32(), reader.read_f32()
				]
			
			if (flags & 64) != 0:
				state.mask_flags = reader.read_u8()
				reader.seek(reader.position + 3)
			
			if (flags & 128) != 0:
				var p = reader.read_u8()
				state.blend_mode = reader.read_u8()
				reader.seek(reader.position + 2)
				if (p & 64) != 0:
					reader.seek(reader.position + 80)
				var sub_count = reader.read_u8()
				var sc = 0
				while sc < sub_count:
					var fl = reader.read_u8()
					reader.align(4)
					if (fl & 1) != 0: reader.seek(reader.position + 32)
					if (fl & 2) != 0: reader.seek(reader.position + 12)
					if (fl & 4) != 0: reader.seek(reader.position + 24)
					sc += 1
				reader.align(4)
			
			nodes[idx] = state
			row.append(state)
			n += 1
		
		frames.append(row)
		i += 1
	
	return {
		"frame_count": frame_count,
		"node_count": node_count,
		"labels": labels,
		"frames": frames
	}

## Helper class for binary reading
class_name A2DReader

var _buffer: PackedByteArray
var _pos: int = 0

func _init(buffer: PackedByteArray):
	_buffer = buffer

func get position() -> int:
	return _pos

func get length() -> int:
	return _buffer.size()

func need(n: int) -> void:
	if _pos + n > _buffer.size():
		push_error("A2DParser: Truncated read at %d (+ %d)" % [_pos, n])

func read_u8() -> int:
	need(1)
	var v = _buffer[_pos]
	_pos += 1
	return v

func read_i8() -> int:
	need(1)
	return int(_buffer[_pos]) - 128 if _buffer[_pos] > 127 else int(_buffer[_pos])

func read_u16() -> int:
	need(2)
	var v = _buffer.get_u16(_pos)
	_pos += 2
	return v

func read_i16() -> int:
	need(2)
	return int(_buffer.get_u16(_pos)) - 65536 if _buffer.get_u16(_pos) > 32767 else int(_buffer.get_u16(_pos))

func read_u32() -> int:
	need(4)
	var v = _buffer.get_u32(_pos)
	_pos += 4
	return v

func read_i32() -> int:
	need(4)
	var v = _buffer.get_u32(_pos)
	_pos += 4
	return int(v) - 4294967296 if v > 2147483647 else int(v)

func read_f32() -> float:
	need(4)
	return _buffer.get_float(_pos)
	_pos += 4

func read_bytes(n: int) -> PackedByteArray:
	need(n)
	var result = ByteArrayExtensions.byte_subarray(_buffer, _pos, n)
	_pos += n
	return result

func read_u16_array(count: int) -> Array:
	var result = []
	var i = 0
	while i < count:
		result.append(read_u16())
		i += 1
	return result

func read_float_array(count: int) -> Array:
	var result = []
	var i = 0
	while i < count:
		result.append(read_f32())
		i += 1
	return result

func align(alignment: int = 4) -> void:
	_pos = int(float(_pos) / float(alignment)) * alignment

func seek(pos: int) -> void:
	_pos = pos

func read_string_at(idx: int) -> String:
	if idx < 0 or idx >= _buffer.size():
		return ""
	# Leer string desde idx hasta encontrar un byte nulo o fin de buffer
	var end = idx
	while end < _buffer.size() and _buffer[end] != 0:
		end += 1
	return ByteArrayExtensions.bytes_to_string_ascii(_buffer, idx, end - idx)