extends Resource
class_name CharacterData

@export var id: int = 0
@export var name: String = ""
@export var level: int = 1
@export var experience: int = 0
@export var sex: int = 0
@export var breed: int = 0
@export var look: PackedByteArray = PackedByteArray()
@export var stats: Array = Array()


static func from_json(json: Dictionary) -> CharacterData:
	var char_data := CharacterData.new()
	if json.size() == 0:
		return char_data

	char_data.id = json.get("id", 0)
	char_data.name = json.get("name", "")
	char_data.level = json.get("level", 1)
	char_data.experience = json.get("experience", 0)
	char_data.sex = json.get("sex", 0)
	char_data.breed = json.get("breed", 0)
	char_data.look = json.get("look", PackedByteArray())
	char_data.stats = json.get("stats", [])
	return char_data


func to_json() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"level": level,
		"experience": experience,
		"sex": sex,
		"breed": breed,
		"look": look,
		"stats": stats
	}