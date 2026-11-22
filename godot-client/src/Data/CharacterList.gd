# CharacterList.gd - Lista de personajes ordenada con helpers
# Para uso en CharacterSelectionUI
class_name CharacterList
extends Resource

## Preload CharacterData for type safety
const CharacterData = preload("res://src/Data/CharacterData.gd")

## Lista de personajes
@export var characters: Array = []

## Añade un personaje a la lista
func add_character(char_data: CharacterData) -> void:
	if char_data == null:
		return
	characters.append(char_data)

## Limpia la lista
func clear() -> void:
	characters.clear()

## Obtener cantidad de personajes
func size() -> int:
	return characters.size()

## Verificar si está vacía
func is_empty() -> bool:
	return characters.size() == 0

## Obtener personaje por índice
func get_at(index: int) -> CharacterData:
	if index >= 0 and index < characters.size():
		return characters[index]
	return null

## Obtener primer personaje
func first() -> CharacterData:
	if characters.size() > 0:
		return characters[0]
	return null

## Obtener último personaje
func last() -> CharacterData:
	if characters.size() > 0:
		return characters[characters.size() - 1]
	return null

## Filtrar por raza
func filter_by_race(race: int) -> Array:
	var result: Array = []
	for char in characters:
		if char is CharacterData and char.race == race:
			result.append(char)
	return result

## Filtrar por nivel mínimo
func filter_by_level(min_level: int) -> Array:
	var result: Array = []
	for char in characters:
		if char is CharacterData and char.level >= min_level:
			result.append(char)
	return result

## Buscar por nombre
func find_by_name(name: String) -> CharacterData:
	for char in characters:
		if char is CharacterData and char.character_name == name:
			return char
	return null

## Buscar por ID
func find_by_id(id: int) -> CharacterData:
	for char in characters:
		if char is CharacterData and char.character_id == id:
			return char
	return null

## Cargar desde array de diccionarios (desde kvi)
func load_from_kvi(kvi_data: Array) -> void:
	clear()
	for char_dict in kvi_data:
		if char_dict is Dictionary:
			var char_data = CharacterData.new()
			char_data.from_dict(char_dict)
			add_character(char_data)

## Convertir a array de diccionarios para UI
func to_dict_array() -> Array:
	var result: Array = []
	for char in characters:
		if char is CharacterData:
			result.append(char.to_dict())
	return result