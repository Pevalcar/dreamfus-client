## Protobuf utilities for the game protocol (TCP 5555)
## Implements VarInt encoding/decoding, field parsing, and envelope building.
## Compatible with Godot 4.8 (uses ByteArrayExtensions for byte array operations)
# No class_name to avoid preload circular dependency issues in Godot 4.8 beta2
extends RefCounted

## Preload ByteArrayExtensions helper para Godot 4.8
const ByteArrayExtensions = preload("res://src/Utils/ByteArrayExtensions.gd")

# Wire types
const WIRE_VARINT = 0
const WIRE_FIXED64 = 1
const WIRE_LENGTH_DELIMITED = 2
const WIRE_FIXED32 = 5


## Write a VarInt (unsigned) to the end of `buf`.
## Correctly implements protobuf VarInt encoding: 7 bits per byte, LSB first.
static func write_varint(buf: PackedByteArray, value: int) -> void:
	# Use unsigned shift to handle positive integers correctly
	var v: int = int(value) & 0x7FFFFFFFFFFFFFFF  # Ensure positive
	while v > 0x7F:
		# Write 7 bits with continuation flag
		buf.append((v & 0x7F) | 0x80)
		v >>= 7
	buf.append(v & 0x7F)


## Read a VarInt. Returns [value, next_offset] or [null, offset] if incomplete.
static func read_varint(ba: PackedByteArray, start_pos: int) -> Array:
	if ba == null or start_pos < 0 or start_pos >= ba.size():
		return [null, start_pos]

	var pos = start_pos
	var result = 0
	var shift = 0

	while pos < ba.size():
		var byte = ba[pos]
		pos += 1
		# Combine 7 bits
		result |= (byte & 0x7F) << shift
		# Check continuation flag
		if (byte & 0x80) == 0:
			return [result, pos]
		shift += 7
		# Safety check to prevent infinite loops
		if shift > 35:
			return [null, start_pos]

	return [null, start_pos]


## Read a 32-bit fixed32 value (little-endian)
static func read_fixed32(ba: PackedByteArray, start_pos: int) -> Array:
	if ba == null or start_pos + 4 > ba.size():
		return [0, start_pos]
	var value = ba[start_pos] | (ba[start_pos + 1] << 8) | (ba[start_pos + 2] << 16) | (ba[start_pos + 3] << 24)
	return [value, start_pos + 4]


## Read a 64-bit fixed64 value (little-endian)
static func read_fixed64(ba: PackedByteArray, start_pos: int) -> Array:
	if ba == null or start_pos + 8 > ba.size():
		return [0, start_pos]
	var value = ba[start_pos] | (ba[start_pos + 1] << 8) | (ba[start_pos + 2] << 16) | (ba[start_pos + 3] << 24) |
		(ba[start_pos + 4] << 32) | (ba[start_pos + 5] << 40) | (ba[start_pos + 6] << 48) | (ba[start_pos + 7] << 56)
	return [value, start_pos + 8]


## Read a length-delimited field (string, bytes, message, etc.)
## Returns [bytes, next_offset] or [null, offset] if incomplete
static func read_length_delimited(ba: PackedByteArray, start_pos: int) -> Array:
	var len_result = read_varint(ba, start_pos)
	if len_result[0] == null:
		return [null, start_pos]

	var len = len_result[0]
	var next_pos = len_result[1]

	if next_pos + len > ba.size():
		return [null, start_pos]

	return [ByteArrayExtensions.byte_subarray(ba, next_pos, len), next_pos + len]


## Parse a message from a byte array with a given message parser function
## message_parser should be a static func that takes PackedByteArray and returns Dictionary
static func parse_message(ba: PackedByteArray, start_pos: int, message_parser: callable) -> Array:
	var result = read_varint(ba, start_pos)
	if result[0] == null:
		return [null, start_pos]

	var len = result[0]
	var next_pos = result[1]

	if next_pos + len > ba.size():
		return [null, start_pos]

	var data = ByteArrayExtensions.byte_subarray(ba, next_pos, len)
	var message = message_parser.call(data)
	return [message, next_pos + len]


## Build a protobuf envelope with field number and value
## field_num: the field number (1-536870911)
## wire_type: the wire type (0=varint, 1=64bit, 2=length-delimited, 5=32bit)
## value: the value to encode
static func build_field(field_num: int, wire_type: int, value) -> PackedByteArray:
	var result = PackedByteArray()
	
	# Build tag: (field_num << 3) | wire_type
	var tag = (field_num << 3) | wire_type
	write_varint(result, tag)
	
	match wire_type:
		WIRE_VARINT:
			write_varint(result, value)
		WIRE_FIXED64:
			for i in range(8):
				result.append((value >> (i * 8)) & 0xFF)
		WIRE_LENGTH_DELIMITED:
			if value is PackedByteArray:
				write_varint(result, value.size())
				for b in value:
					result.append(b)
			elif value is String:
				var bytes = value.to_utf8_buffer()
				write_varint(result, bytes.size())
				for b in bytes:
					result.append(b)
		WIRE_FIXED32:
			for i in range(4):
				result.append((value >> (i * 8)) & 0xFF)
	
	return result


## Decode a complete message from a field
## This is a helper for decoding nested messages within a length-delimited field
static func decode_message(ba: PackedByteArray) -> Dictionary:
	# This is a generic decoder - specific formats should implement their own parsers
	var result = {}
	var pos = 0
	
	while pos < ba.size():
		var tag = ba[pos]
		var field_num = tag >> 3
		var wire_type = tag & 0x7
		pos += 1
		
		match wire_type:
			WIRE_VARINT:
				var varint_result = read_varint(ba, pos)
				if varint_result[0] != null:
					result["f%d" % field_num] = varint_result[0]
					pos = varint_result[1]
				else:
					break
			WIRE_FIXED64:
				var fixed_result = read_fixed64(ba, pos)
				result["f%d" % field_num] = fixed_result[0]
				pos = fixed_result[1]
			WIRE_LENGTH_DELIMITED:
				var len_result = read_varint(ba, pos)
				if len_result[0] != null:
					var len = len_result[0]
					pos = len_result[1] + len
				else:
					break
			WIRE_FIXED32:
				var fixed_result = read_fixed32(ba, pos)
				result["f%d" % field_num] = fixed_result[0]
				pos = fixed_result[1]
			_:
				break
	
	return result