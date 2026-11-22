# CharacterManager.gd - Transformador de datos de personajes
# Convierte datos del protocolo kvi (protobuf) a CharacterData
class_name CharacterManager
extends Node

## Señal emitida cuando la lista de personajes está lista
signal characters_loaded(characters: Array)
signal error_loading(message: String)

## Preload CharacterData for type safety
const CharacterData = preload("res://src/Data/CharacterData.gd")

## Transforma datos kvi (de WorldProto.decode_kvi) a CharacterData
## Cada entrada en kvi_data es un Dictionary con: id, name, level, breed, look, sex
func transform_kvi_data(kvi_data: Array) -> Array:
	if kvi_data == null or kvi_data.size() == 0:
		emit_characters_loaded([])
		return []
	
	var characters: Array = []
	for char_dict in kvi_data:
		if char_dict is Dictionary:
			var char_data = _create_character_data(char_dict)
			if char_data != null:
				characters.append(char_data)
	
	emit_characters_loaded(characters)
	return characters

## Crea un CharacterData desde un diccionario del protocolo
func _create_character_data(char_dict: Dictionary) -> CharacterData:
	if char_dict == null:
		return null
	
	var char_data = CharacterData.new()
	
	# ID del personaje
	char_data.character_id = int(char_dict.get("id", 0))
	
	# Nombre
	char_data.character_name = str(char_dict.get("name", "???"))
	char_data.display_name = char_data.character_name
	
	# Nivel (1-200)
	char_data.level = int(char_dict.get("level", 1))
	
	# Raza/Breed (0-11)
	char_data.breed = int(char_dict.get("breed", 0))
	char_data.race = char_data.breed  # Alias para spec
	
	# Sexo (0=f, 1=m) - el protocolo usa 'sex', el spec lo llama 'sex' también
	char_data.sex = int(char_dict.get("sex", 0))
	
	# Aspecto/Look - puede ser bytes o string base64
	var look_data = char_dict.get("look", PackedByteArray())
	if look_data is PackedByteArray:
		# Convertir bytes a base64 si es necesario
		char_data.aspect = look_data.hex_encode()
	elif look_data is String:
		char_data.aspect = look_data
	
	return char_data

## Parsea respuesta directa del servidor (formato espec)
func parse_character_list_response(response: Dictionary) -> Array:
	if response == null:
		return []
	
	if not response.get("bien", false):
		var motivo = response.get("motivo", "Error desconocido")
		emit_error("Respuesta HTTP: " + motivo)
		return []
	
	var characters_data = response.get("personajes", [])
	return transform_kvi_data(characters_data)

## Emitir señal de caracteres cargados
func emit_characters_loaded(characters: Array) -> void:
	characters_loaded.emit(characters)

## Emitir señal de error
func emit_error(message: String) -> void:
	error_loading.emit(message)