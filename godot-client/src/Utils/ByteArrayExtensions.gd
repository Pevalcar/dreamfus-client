# ByteArrayExtensions.gd - Extensions for PackedByteArray
class_name ByteArrayExtensions
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
	return ba[offset] | (ba[offset + 1] << 8) | (ba[offset + 2] << 16) | (ba[offset + 3] << 24) |
		(ba[offset + 4] << 32) | (ba[offset + 5] << 40) | (ba[offset + 6] << 48) | (ba[offset + 7] << 56)

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
	return ba.hexify()