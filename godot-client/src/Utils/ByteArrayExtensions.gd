# ByteArrayExtensions.gd - Extensions for PackedByteArray
# No class_name to avoid preload issues in Godot 4.8 beta2
# Use preload("res://src/Utils/ByteArrayExtensions.gd") to access this script
extends RefCounted


# Extract a byte subarray from a PackedByteArray
static func byte_subarray(ba: PackedByteArray, start: int, length: int) -> PackedByteArray:
	if ba == null or start < 0 or length <= 0:
		return PackedByteArray()
	var result = PackedByteArray()
	var end = min(start + length, ba.size())
	for i in range(start, end):
		result.append(ba[i])
	return result


# Read a 32-bit unsigned integer in little-endian format
static func read_u32_le(ba: PackedByteArray, offset: int) -> int:
	if ba == null or offset + 4 > ba.size():
		return 0
	return ba[offset] | (ba[offset + 1] << 8) | (ba[offset + 2] << 16) | (ba[offset + 3] << 24)


# Read a 64-bit unsigned integer in little-endian format
static func read_u64_le(ba: PackedByteArray, offset: int) -> int:
	if ba == null or offset + 8 > ba.size():
		return 0
	return ba[offset] | (ba[offset + 1] << 8) | (ba[offset + 2] << 16) | (ba[offset + 3] << 24) | (
		ba[offset + 4] << 32
	) | (ba[offset + 5] << 40) | (ba[offset + 6] << 48) | (ba[offset + 7] << 56)


# Pad array to specific size with trailing zeros
static func pad_array(ba: PackedByteArray, size: int) -> PackedByteArray:
	if ba.size() >= size:
		return ba.duplicate()
	var result = ba.duplicate()
	while result.size() < size:
		result.append(0)
	return result


# Check if byte array starts with specific prefix
static func starts_with(ba: PackedByteArray, prefix: PackedByteArray) -> bool:
	if ba == null or prefix == null or ba.size() < prefix.size():
		return false
	for i in range(prefix.size()):
		if ba[i] != prefix[i]:
			return false
	return true


# Convert byte array to hex string
static func to_hex(ba: PackedByteArray) -> String:
	if ba == null:
		return ""
	return ba.hex_encode()


# Extract a portion of byte array without moving the reading position (peek)
# If length is -1 (default), extracts from start to end of array
static func byte_subarray_from(ba: PackedByteArray, start: int, length: int = -1) -> PackedByteArray:
	if ba == null or start < 0 or start >= ba.size():
		return PackedByteArray()
	if length == -1:
		# Extract from start to end of array
		var result = PackedByteArray()
		for i in range(start, ba.size()):
			result.append(ba[i])
		return result
	return byte_subarray(ba, start, length)


# Peek a 4-byte string from byte array at specific position
static func peek_string_4(ba: PackedByteArray, pos: int) -> String:
	if ba == null or pos + 4 > ba.size():
		return ""
	var result := ""
	for i in range(pos, pos + 4):
		result += char(ba[i])
	return result


# Convert byte array bytes to ASCII string within range
static func bytes_to_string_ascii(ba: PackedByteArray, start: int, length: int) -> String:
	if ba == null or start < 0 or length <= 0:
		return ""
	var result := ""
	var end = min(start + length, ba.size())
	for i in range(start, end):
		result += char(ba[i])
	return result
