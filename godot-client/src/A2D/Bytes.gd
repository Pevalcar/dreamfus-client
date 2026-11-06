## Bytes.gd
## Utilidades para manipulación de bytes en GDScript
## 
## Provee funciones para leer valores multi-byte de PackedByteArray
## con control de endianness (little-endian por defecto)

extends RefCounted
class_name Bytes

## Lee un u16 (unsigned 16-bit) little-endian desde un PackedByteArray
static func get_u16_le(data: PackedByteArray, offset: int) -> int:
	if offset + 2 > data.size():
		return 0
	
	# Little-endian: byte[0] es el menos significativo
	return data[offset] | (data[offset + 1] << 8)

## Lee un u32 (unsigned 32-bit) little-endian desde un PackedByteArray
static func get_u32_le(data: PackedByteArray, offset: int) -> int:
	if offset + 4 > data.size():
		return 0
	
	# Little-endian: byte[0] es el menos significativo
	return (data[offset] & 0xFF) | \
	       ((data[offset + 1] & 0xFF) << 8) | \
	       ((data[offset + 2] & 0xFF) << 16) | \
	       ((data[offset + 3] & 0xFF) << 24)

## Lee un u64 (unsigned 64-bit) little-endian desde un PackedByteArray
static func get_u64_le(data: PackedByteArray, offset: int) -> int:
	if offset + 8 > data.size():
		return 0
	
	return (data[offset] & 0xFF) | \
	       ((data[offset + 1] & 0xFF) << 8) | \
	       ((data[offset + 2] & 0xFF) << 16) | \
	       ((data[offset + 3] & 0xFF) << 24) | \
	       ((data[offset + 4] & 0xFF) << 32) | \
	       ((data[offset + 5] & 0xFF) << 40) | \
	       ((data[offset + 6] & 0xFF) << 48) | \
	       ((data[offset + 7] & 0xFF) << 56)

## Crea un PackedByteArray desde un entero little-endian de 32 bits
static func from_u32_le(value: int) -> PackedByteArray:
	var result := PackedByteArray.new()
	result.resize(4)
	result[0] = value & 0xFF
	result[1] = (value >> 8) & 0xFF
	result[2] = (value >> 16) & 0xFF
	result[3] = (value >> 24) & 0xFF
	return result

## Convierte String a PackedByteArray (ASCII/UTF-8)
static func from_string(s: String) -> PackedByteArray:
	return s.to_utf8_buffer()

## Convierte PackedByteArray a String (UTF-8)
static func to_string(data: PackedByteArray) -> String:
	return data.get_string_from_utf8()