# CharacterData.gd - Player character data model
# Note: Plain data class that can be used as a Node for character selection
class_name CharacterData
extends Node

# Character identification
@export var character_id: int = 0
@export var character_name: String = ""
@export var display_name: String = ""  # Alias for compatibility with GameUI

# Property alias for character_id (CharacterData.id -> character_id)
func get_id() -> int:
	return character_id

func set_id(value: int) -> void:
	character_id = value

# Basic attributes
@export var level: int = 1
@export var experience: int = 0
@export var next_level_experience: int = 0

# Breed
@export var breed: int = 0

# Economy
@export var kamas: int = 0

# Stats - mapped by stat ID to values
@export var stats: Dictionary = {}

# Jobs/Professions
@export var jobs: Array = []

# Spells learned
@export var spells: Array = []

# Inventory items
@export var inventory: Array = []

# Shortcut bar
@export var spell_bar: Dictionary = {
	"bar_type": 0,
	"shortcuts": []
}

# Character alignment
@export var alignment: Dictionary = {
	"side": 0,
	"grade": 0,
	"honor": 0
}


# Check if character has specific stat
func has_stat(stat_id: int) -> bool:
	return stats.has(stat_id) and stats[stat_id] is Dictionary

# Get stat value
func get_stat_value(stat_id: int, value_type: String = "equipment") -> int:
	if stats.has(stat_id) and stats[stat_id] is Dictionary:
		return stats[stat_id].get(value_type, 0)
	return 0

# Get total stat (sum of base + scroll + equipment)
func get_total_stat(stat_id: int) -> int:
	if stats.has(stat_id) and stats[stat_id] is Dictionary:
		var s = stats[stat_id]
		return s.get("base", 0) + s.get("scroll", 0) + s.get("equipment", 0)
	return 0

# Check if character has learned spell
func has_spell(spell_id: int) -> bool:
	for spell in spells:
		if spell is Dictionary and spell.spell_id == spell_id:
			return true
	return false

# Get spell grade
func get_spell_grade(spell_id: int) -> int:
	for spell in spells:
		if spell is Dictionary and spell.spell_id == spell_id:
			return spell.grade
	return 0

# Get spell origin
func get_spell_origin(spell_id: int) -> int:
	for spell in spells:
		if spell is Dictionary and spell.spell_id == spell_id:
			return spell.origin
	return 0

# Add or update job
func set_job(profession: int, level: int, next_level: int = 0, floor: int = 0, total: int = 0) -> void:
	for i in range(jobs.size()):
		if jobs[i].profession == profession:
			jobs[i].level = level
			jobs[i].next_level = next_level
			jobs[i].floor = floor
			jobs[i].total = total
			return
	jobs.append({
		"profession": profession,
		"level": level,
		"next_level": next_level,
		"floor": floor,
		"total": total
	})

# Check if character has job
func has_job(profession: int) -> bool:
	for job in jobs:
		if job.profession == profession:
			return true
	return false

# Save character state to dictionary
func to_dict() -> Dictionary:
	return {
		"id": character_id,
		"character_id": character_id,
		"name": character_name,
		"character_name": character_name,
		"level": level,
		"experience": experience,
		"next_level_experience": next_level_experience,
		"kamas": kamas,
		"stats": stats,
		"jobs": jobs,
		"spells": spells,
		"inventory": inventory,
		"spell_bar": spell_bar,
		"alignment": alignment
	}

# Load character state from dictionary
func from_dict(data: Dictionary) -> void:
	if data.has("id"):
		character_id = data.id
	if data.has("character_id"):
		character_id = data.character_id
	if data.has("character_name"):
		character_name = data.character_name
	if data.has("name"):
		character_name = data.name  # Keep both in sync
	if data.has("level"):
		level = data.level
	if data.has("experience"):
		experience = data.experience
	if data.has("next_level_experience"):
		next_level_experience = data.next_level_experience
	if data.has("kamas"):
		kamas = data.kamas
	if data.has("stats"):
		stats = data.stats
	if data.has("jobs"):
		jobs = data.jobs
	if data.has("spells"):
		spells = data.spells
	if data.has("inventory"):
		inventory = data.inventory
	if data.has("spell_bar"):
		spell_bar = data.spell_bar
	if data.has("alignment"):
		alignment = data.alignment