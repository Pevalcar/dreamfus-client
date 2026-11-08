# GameManager.gd - Manages game state and handles protocol messages
class_name GameManager
extends Node

## Protocol decoder
const WorldProto = preload("res://src/Network/WorldProto.gd")

## Character data
var current_character: CharacterData = null

## Player state from Block 1 messages
var player_stats: Dictionary = {}
var player_jobs: Array = []
var player_spells: Array = []
var player_inventory: Dictionary = { "kamas": 0, "items": [] }
var spell_bar: Dictionary = { "bar_type": 0, "shortcuts": [] }

## Player info from earlier messages
var player_id: int = 0
var player_name: String = ""

## Connection state
var is_connected: bool = false
var is_character_loaded: bool = false


# Called when the node is added to the scene tree
func _ready() -> void:
	# Initialize with default CharacterData
	current_character = CharacterData.new()

# Initialize player state for a new session
func initialize_player() -> void:
	player_stats = {}
	player_jobs = []
	player_spells = []
	player_inventory = { "kamas": 0, "items": [], "found": false }
	spell_bar = { "bar_type": 0, "shortcuts": [], "found": false }
	current_character = CharacterData.new()
	is_character_loaded = false

# Handle kvw (character info) message - should be called from WorldEntry
func handle_kvw(payload: PackedByteArray) -> void:
	# kvw is handled elsewhere for character metadata
	pass

# Handle kva (character alive) message - should be called from WorldEntry
func handle_kva(payload: PackedByteArray) -> void:
	# kva is handled elsewhere for character alive status
	pass

# Handle kub (player stats) - Block 1
func _handle_kub(payload: PackedByteArray) -> void:
	# Handle kub (player stats).
	# kub format: f2 { f1 { f1: characteristic_id, f4/f5/f2: value }, f7: experience, f8: next_level, f9: alignment, f10: kamas }
	var data = WorldProto.decode_kub(payload)
	if data.found:
		print("[GameManager] kub - stats recibidos para personaje")
		player_stats = data.stats
		current_character.experience = data.experience
		current_character.next_level_experience = data.next_level
		current_character.kamas = data.kamas
		current_character.alignment = data.alignment
		
		# Print stat details
		for stat_id in player_stats:
			var stat = player_stats[stat_id]
			if stat is Dictionary:
				print("[GameManager]   Estadistica ID %d: base=%d, scroll=%d, equipment=%d" 
					% [stat_id, stat.get("base", 0), stat.get("scroll", 0), stat.get("equipment", 0)])
		
		# Update character's total stats
		_update_character_stats()

# Handle irq (jobs/professions) - Block 1
func _handle_irq(payload: PackedByteArray) -> void:
	# Handle irq (player jobs).
	# irq format: f1 (repeated) { f1: profession, f2: next_level, f3: level, f4: floor, f5: total }
	var data = WorldProto.decode_irq(payload)
	if data.found:
		print("[GameManager] irq - %d profesiones recibidas" % data.jobs.size())
		player_jobs = data.jobs
		
		for job in data.jobs:
			print("[GameManager]   Profesion ID %d: nivel %d (next: %d)" 
				% [job.profession, job.level, job.next_level])

# Handle hms (spell list) - Block 1
func _handle_hms(payload: PackedByteArray) -> void:
	# Handle hms (spell list).
	# hms format: f1 (repeated) { f1: grade, f3: spell_id, f4: origin }, f2: 1 at end
	var data = WorldProto.decode_hms(payload)
	if data.found:
		print("[GameManager] hms - %d hechizos aprendidos" % data.spells.size())
		player_spells = data.spells
		
		for spell in data.spells:
			print("[GameManager]   Hechizo ID %d: grado %d, origen %d" 
				% [spell.spell_id, spell.grade, spell.origin])

# Handle ivx (inventory) - Block 1
func _handle_ivx(payload: PackedByteArray) -> void:
	# Handle ivx (inventory).
	# ivx format: f1: kamas, f3 (repeated) { f1: slot, f5 { f1: template, effects }, f3: count, f4: uid }
	var data = WorldProto.decode_ivx(payload)
	if data.found or data.kamas > 0:
		print("[GameManager] ivx - inventario recibido")
		player_inventory = data
		print("[GameManager]   Kamas: %d" % data.kamas)
		print("[GameManager]   Items: %d" % data.items.size())
		
		for item in data.items:
			print("[GameManager]      Item slot %d: template=%d, count=%d, uid=%d" 
				% [item.slot, item.template, item.count, item.uid])

# Handle itg (shortcut bar) - Block 1
func _handle_itg(payload: PackedByteArray) -> void:
	# Handle itg (shortcut bar).
	# itg format: f1 (repeated) { f2: slot, f6 { f2: spell_id } } for spells, f9: items; f2: bar_type (1=spell, 0=item)
	var data = WorldProto.decode_itg(payload)
	if data.found:
		print("[GameManager] itg - barra de atajos recibida")
		spell_bar = data
		
		if data.bar_type == 1:
			print("[GameManager]   Tipo: Spell Bar (%d atajos)" % data.shortcuts.size())
		else:
			print("[GameManager]   Tipo: Item Bar (%d atajos)" % data.shortcuts.size())
		
		for shortcut in data.shortcuts:
			if shortcut.is_item:
				print("[GameManager]     Slot %d: Item template %d" 
					% [shortcut.slot, shortcut.item_template])
			else:
				print("[GameManager]     Slot %d: Spell ID %d" 
					% [shortcut.slot, shortcut.spell_id])

# Update character stats from player_stats dictionary
func _update_character_stats() -> void:
	current_character.stats = player_stats

# Get character display name
func get_character_name() -> String:
	return current_character.character_name if current_character else ""

# Check if character is fully loaded
func is_character_ready() -> bool:
	return is_character_loaded

# Mark character as loaded after Block 1
func mark_character_loaded() -> void:
	is_character_loaded = true

# Get summary of player state for debugging
func get_player_summary() -> Dictionary:
	return {
		"name": get_character_name(),
		"level": current_character.level if current_character else 1,
		"kamas": current_character.kamas if current_character else 0,
		"stats_count": player_stats.size(),
		"jobs_count": player_jobs.size(),
		"spells_count": player_spells.size(),
		"items_count": player_inventory.items.size() if player_inventory else 0,
		"shortcuts_count": spell_bar.shortcuts.size() if spell_bar else 0
	}