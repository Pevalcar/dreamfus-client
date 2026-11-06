## ByteArrayExtensions.gd
## Helper functions para manejar PackedByteArray en Godot 4.8
## donde el método slice() ha sido removido

extends RefCounted
class_name ByteArrayExtensions

## Helper para extraer subByteArray en Godot 4.8
## En Godot 4.8, PackedByteArray.slice() y .sub() han sido removidos
## Este método proporciona un reemplazo eficiente
static func byte_subarray(data: PackedByteArray, start: int, length: int) -> PackedByteArray:
	if start < 0 or length < 0 or start + length > data.size():
		return PackedByteArray()
	
	var result = PackedByteArray()
	result.resize(length)
	for i in range(length):
		result[i] = data[start + i]
	return result

## Helper para extraer subByteArray hasta el final
static func byte_subarray_from(data: PackedByteArray, start: int) -> PackedByteArray:
	if start < 0 or start >= data.size():
		return PackedByteArray()
	return byte_subarray(data, start, data.size() - start)

## Helper para convertir subByteArray a string ASCII
## En Godot 4.8, get_string_from_ascii(offset, length) no existe
static func bytes_to_string_ascii(data: PackedByteArray, start: int, length: int) -> String:
	var bytes = byte_subarray(data, start, length)
	var result = ""
	for i in range(bytes.size()):
		result += char(bytes[i])
	return result

## Helper para extraer un string de 4 bytes (mágicas/códigos)
static func peek_string_4(data: PackedByteArray, offset: int) -> String:
	var bytes = byte_subarray(data, offset, 4)
	var result = ""
	for i in range(4):
		result += char(bytes[i])
	return result