## test_character_selection.gd
## Test for kvw character selection message format.
## Run with: Godot_console.exe --headless --path <project> -s test/test_character_selection.gd
##
## The kvw message must have the format: { f1: character_id } where f1 is a varint.
## The bug was: client sent { f1: { f1: id } } (nested message) instead of flat varint.

extends "res://addons/gut/test.gd"

# Simplified VarInt utilities for testing (copy of Proto.gd logic)
static func put_varint(data: PackedByteArray, field_number: int, value: int) -> PackedByteArray:
	var result := data.duplicate()
	var tag := (field_number << 3) | 0  # wire type 0 = varint
	
	# Encode tag
	while tag > 0x7F:
		result.append((tag & 0x7F) | 0x80)
		tag >>= 7
	result.append(tag & 0x7F)
	
	# Encode value
	while value > 0x7F:
		result.append((value & 0x7F) | 0x80)
		value >>= 7
	result.append(value & 0x7F)
	
	return result

static func build_character_selection(character_id: int) -> PackedByteArray:
	if character_id <= 0:
		print("[ERROR] Invalid character_id: %d" % character_id)
		return PackedByteArray()
	return put_varint(PackedByteArray(), 1, character_id)

static func read_varint(buff: PackedByteArray, pos: int) -> Array:
	var result: int = 0
	var shift: int = 0
	var i: int = pos
	while i < buff.size():
		var b := buff[i]
		result |= (b & 0x7F) << shift
		i += 1
		if (b & 0x80) == 0:
			return [result, i]
		shift += 7
	return [null, pos]

func test_build_character_selection_produces_flat_varint_format():
	var character_id: int = 13825558
	var payload: PackedByteArray = build_character_selection(character_id)
	
	# Expected: field 1 (f1=1, wire=0) as varint tag, followed by the ID as varint
	var expected_prefix := 0x08  # tag for field 1, wire type 0 (varint)
	var actual_first_byte := payload[0] if payload.size() > 0 else 0
	
	assert_eq(actual_first_byte, expected_prefix, "first byte is 0x%02X (field 1, wire type 0)" % actual_first_byte)

func test_payload_contains_correct_character_id_as_varint():
	var character_id: int = 13825558
	var payload: PackedByteArray = build_character_selection(character_id)
	
	var result := read_varint(payload, 1)  # Skip tag byte
	var parsed_id := result[0] as int
	
	assert_eq(parsed_id, character_id, "ID matches: %d" % parsed_id)

func test_payload_is_flat_not_nested():
	var character_id: int = 13825558
	var payload: PackedByteArray = build_character_selection(character_id)
	
	var actual_first_byte := payload[0] if payload.size() > 0 else 0
	
	assert_true((actual_first_byte & 0x07) == 0, "wire type is varint (type 0), not length-delimited (type 2)")

func test_small_character_id_format():
	var small_id: int = 123
	var small_payload: PackedByteArray = build_character_selection(small_id)
	var small_result := read_varint(small_payload, 1)
	var small_parsed := small_result[0] as int
	
	assert_eq(small_parsed, small_id, "small ID %d encoded correctly" % small_id)

func test_byte_count_reasonable():
	var character_id: int = 13825558
	var payload: PackedByteArray = build_character_selection(character_id)
	
	# For character_id = 13825558, we expect:
	# - 1 byte for tag (0x08)
	# - 3-4 bytes for the varint value
	var byte_count_ok := payload.size() >= 3 and payload.size() <= 6
	assert_true(byte_count_ok, "payload size %d bytes is reasonable" % payload.size())

func test_boundary_character_id_127():
	var max_one_byte: int = 127
	var max_payload: PackedByteArray = build_character_selection(max_one_byte)
	var max_result := read_varint(max_payload, 1)
	var max_parsed := max_result[0] as int
	
	assert_eq(max_parsed, max_one_byte, "boundary ID %d encoded correctly" % max_one_byte)