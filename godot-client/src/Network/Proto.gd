## Protobuf utilities for the game protocol (TCP 5555)
## Implements VarInt encoding/decoding, field parsing, and envelope building.
class_name Proto
extends RefCounted

# Wire types
const WIRE_VARINT = 0
const WIRE_FIXED64 = 1
const WIRE_LENGTH_DELIMITED = 2
const WIRE_FIXED32 = 5


## Write a VarInt (64-bit signed) to the end of `buf`.
static func write_varint(buf: PackedByteArray, value: int) -> void:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(8)
	bytes.encode_s64(0, value) # little-endian, two's complement
	var i: int = 0
	while i < 8:
		var b: int = bytes[i]
		var more: bool = false
		for j in range(i + 1, 8):
			if bytes[j] != 0:
				more = true
				break
		if not more and (b & 0x80) == 0:
			buf.append(b)
			return
		buf.append(b | 0x80)
		i += 1
	# Negative numbers extend to 10 bytes (0xFF * 8 + 0x01).
	buf.append(0xFF)
	buf.append(0x01)


## Read a VarInt. Returns [value, next_offset] or [null, offset] if incomplete.
static func read_varint(buf: PackedByteArray, offset: int) -> Array:
	var result: int = 0
	var shift: int = 0
	var i: int = offset
	while i < buf.size():
		var b: int = buf[i]
		i += 1
		result |= (b & 0x7F) << shift
		if (b & 0x80) == 0:
			return [result, i]
		shift += 7
		if shift >= 70:
			break
	return [null, i]


## Encode a field tag.
static func tag(field: int, wire: int) -> int:
	return (field << 3) | wire


## Write a varint field (wire 0).
static func put_varint(out: PackedByteArray, field: int, value: int) -> void:
	write_varint(out, tag(field, WIRE_VARINT))
	write_varint(out, value)


## Write a bytes field (wire 2).
static func put_bytes(out: PackedByteArray, field: int, data: PackedByteArray) -> void:
	write_varint(out, tag(field, WIRE_LENGTH_DELIMITED))
	write_varint(out, data.size())
	out.append_array(data)


## Write a string field (wire 2).
static func put_string(out: PackedByteArray, field: int, text: String) -> void:
	put_bytes(out, field, text.to_utf8_buffer())


## Create a submessage wrapper.
static func message(field: int, body: PackedByteArray) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	put_bytes(out, field, body)
	return out


## Parse a protobuf message into an array of {n, w, v, b} dicts.
## v = varint value, b = bytes value. Unknown fields are preserved.
static func parse(buf: PackedByteArray) -> Array:
	var fields: Array = Array()
	var i: int = 0
	while i < buf.size():
		var head: Array = read_varint(buf, i)
		if head[0] == null:
			break
		var key: int = head[0]
		i = head[1]
		var n: int = key >> 3
		var w: int = key & 0x07
		match w:
			WIRE_VARINT:
				var r: Array = read_varint(buf, i)
				if r[0] == null:
					break
				fields.append({ "n": n, "w": w, "v": r[0] })
				i = r[1]
			WIRE_FIXED64:
				fields.append({ "n": n, "w": w, "b": buf.slice(i, i + 8) })
				i += 8
			WIRE_LENGTH_DELIMITED:
				var l: Array = read_varint(buf, i)
				if l[0] == null:
					break
				i = l[1]
				fields.append({ "n": n, "w": w, "b": buf.slice(i, i + l[0]) })
				i += l[0]
			WIRE_FIXED32:
				fields.append({ "n": n, "w": w, "b": buf.slice(i, i + 4) })
				i += 4
			_:
				break # unknown wire type
	return fields


## Get the first field with number n, or null.
static func first(fields: Array, n: int) -> Variant:
	for f in fields:
		if f["n"] == n:
			return f
	return null


## Get all fields with number n (for repeated fields).
static func all(fields: Array, n: int) -> Array:
	var out: Array = Array()
	for f in fields:
		if f["n"] == n:
			out.append(f)
	return out


## Decode packed varints from a bytes buffer.
static func unpacked(buf: PackedByteArray) -> Array:
	var out: Array = Array()
	var i: int = 0
	while i < buf.size():
		var r: Array = read_varint(buf, i)
		if r[0] == null:
			break
		out.append(int(r[0]))
		i = int(r[1])
	return out


## Build a client request envelope.
## root 2 { f1: Any, f2: id }
static func request(
	opcode: String,
	payload: PackedByteArray,
	request_id: int = -1,
) -> PackedByteArray:
	var any := PackedByteArray()
	put_string(any, 1, "type.ankama.com/" + opcode)
	if payload.size() > 0:
		put_bytes(any, 2, payload)

	var wrapper := PackedByteArray()
	put_bytes(wrapper, 1, any)
	put_varint(wrapper, 2, request_id)

	var root := PackedByteArray()
	put_bytes(root, 2, wrapper)
	return root


## Build a server answer envelope.
## root 3 { f1: Any, f2: id }
static func answer(opcode: String, payload: PackedByteArray, request_id: int) -> PackedByteArray:
	var any := PackedByteArray()
	put_string(any, 1, "type.ankama.com/" + opcode)
	if payload.size() > 0:
		put_bytes(any, 2, payload)

	var wrapper := PackedByteArray()
	put_bytes(wrapper, 1, any)
	put_varint(wrapper, 2, request_id)

	var root := PackedByteArray()
	put_bytes(root, 3, wrapper)
	return root


## Build a server push envelope.
## root 1 { f1: Any }
static func push(opcode: String, payload: PackedByteArray) -> PackedByteArray:
	var any := PackedByteArray()
	put_string(any, 1, "type.ankama.com/" + opcode)
	if payload.size() > 0:
		put_bytes(any, 2, payload)

	var root := PackedByteArray()
	put_bytes(root, 1, any)
	return root


## Decode a received frame into {root, opcode, payload, id}.
## Handles both client request format (f2) and server push format (f1).
static func decode(frame: PackedByteArray) -> Dictionary:
	var fields: Array = parse(frame)
	if fields.is_empty():
		return { }
	
	# Determine the wrapper field: f2 for client requests, f1 for server pushes
	var root_field: Variant = first(fields, 2)
	var wrapper_field_num: int = 2
	if root_field == null:
		# Try f1 for server push format
		root_field = first(fields, 1)
		wrapper_field_num = 1
		if root_field == null:
			return { }
	
	var wrapper: Array = parse(root_field["b"])
	var any_field: Variant = first(wrapper, 1)
	if any_field == null:
		return { }
	var any_fields: Array = parse(any_field["b"])
	var url_field: Variant = first(any_fields, 1)
	var type_url: String = url_field["b"].get_string_from_utf8() if url_field != null else ""
	var payload: PackedByteArray = PackedByteArray()
	var payload_field: Variant = first(any_fields, 2)
	if payload_field != null:
		payload = payload_field["b"]
	var id: int = -1
	var id_field: Variant = first(wrapper, 2)
	if id_field != null:
		id = id_field["v"]
	return {
		"root": root_field["n"],
		"opcode": type_url.trim_prefix("type.ankama.com/"),
		"payload": payload,
		"id": id,
	}


## Helper to extract a nested field from parsed fields.
static func get_nested(fields: Array, outer_field: int, inner_field: int) -> Variant:
	var outer: Variant = first(fields, outer_field)
	if outer == null:
		return null
	var inner_fields: Array = parse(outer["b"])
	return first(inner_fields, inner_field)


## Helper to extract all repeated nested items.
static func get_nested_all(fields: Array, outer_field: int, inner_field: int) -> Array:
	var outer_items: Array = all(fields, outer_field)
	var result: Array = Array()
	for item in outer_items:
		var inner_fields: Array = parse(item["b"])
		var inner: Variant = first(inner_fields, inner_field)
		if inner != null:
			result.append(inner)
	return result


## Decode kvi character list from payload
## Format: f1 (repeated) { f1 { f2: name, f3: level, f4 { f2: { f3: sex }, f6: look, f7: breed } }, f2: characterId }
## Returns Array of Dictionary
## Note: f6 (look) and f7 (breed) are inside the traits block (f4), along with sex
static func decode_kvi(payload: PackedByteArray) -> Array:
	var characters: Array = Array()
	var fields: Array = parse(payload)
	
	# Iterate over field 1 entries (repeated field for each character)
	for field in fields:
		if field["n"] != 1:
			continue
		
		var char_fields: Array = parse(field["b"])
		if char_fields.is_empty():
			continue
		
		# f2 = characterId (varint)
		var id_field: Variant = first(char_fields, 2)
		var character_id: int = 0
		if id_field != null and id_field.has("v"):
			character_id = int(id_field["v"])
		
		# f1 = character details
		var details_field: Variant = first(char_fields, 1)
		if details_field == null:
			continue
		
		var details_fields: Array = parse(details_field["b"])
		
		# f2 = name (string)
		var name: String = ""
		var name_field: Variant = first(details_fields, 2)
		if name_field != null:
			if name_field.has("b"):
				name = name_field["b"].get_string_from_utf8()
			elif name_field.has("v"):
				name = str(name_field["v"])
		
		# f3 = level (varint)
		var level: int = 1
		var level_field: Variant = first(details_fields, 3)
		if level_field != null and level_field.has("v"):
			level = int(level_field["v"])
		
		# f4 = traits block containing sex, look, and breed
		# f4 { f2: { f3: sex } (present but empty when sex is 0), f6: look, f7: breed }
		var sex: int = 0
		var look: PackedByteArray = PackedByteArray()
		var breed: int = 0
		
		# f4 = traits block with nested sex, look, and breed
		var traits_field: Variant = first(details_fields, 4)
		if traits_field != null and traits_field.has("b"):
			var traits_fields: Array = parse(traits_field["b"])
			
			# f6 = look (bytes, inside traits/f4)
			var look_field: Variant = first(traits_fields, 6)
			if look_field != null and look_field.has("b"):
				look = look_field["b"]
			
			# f7 = breed (varint, inside traits/f4)
			var breed_field: Variant = first(traits_fields, 7)
			if breed_field != null and breed_field.has("v"):
				breed = int(breed_field["v"])
			
			# f2 = sex container { f3: sex_value } inside traits/f4
			var sex_container: Variant = first(traits_fields, 2)
			if sex_container != null and sex_container.has("b"):
				var sex_inner_fields: Array = parse(sex_container["b"])
				# f3 = sex value (varint)
				var sex_value_field: Variant = first(sex_inner_fields, 3)
				if sex_value_field != null and sex_value_field.has("v"):
					sex = int(sex_value_field["v"])
		
		characters.append({
			"id": character_id,
			"name": name,
			"level": level,
			"sex": sex,
			"breed": breed,
			"look": look,
		})
	
	return characters
