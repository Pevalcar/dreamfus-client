# GameClient.gd - Handles game protocol messages and routes them to appropriate handlers
class_name GameClient
extends Node

signal message_received(opcode: int, payload: PackedByteArray)
signal character_data_received(character_id: int, data: Dictionary)
signal stats_received(stats: Dictionary)
signal jobs_received(jobs: Array)
signal spells_received(spells: Array)
signal inventory_received(kamas: int, items: Array)
signal spell_bar_received(bar_type: int, shortcuts: Array)

## References
var game_manager: GameManager

## Connection reference
var connection: WebSocketClient = null

## Track kvw allowed state (jtg sets it, kvw sends it, then blocks)
var kvw_allowed: bool = false

## Track if Block 1 has been received
var block1_received: bool = false

# Called when the node is added to the scene tree
func _ready() -> void:
	# Get or create GameManager
	if get_tree().get_root().has_node("/root/GameManager"):
		game_manager = get_tree().get_root().get_node("/root/GameManager")
	else:
		game_manager = GameManager.new()
		get_tree().get_root().add_child(game_manager)


# Handle a raw protocol message
# opcode: the message opcode
# payload: the raw bytes from the server
func handle_message(opcode: int, payload: PackedByteArray) -> void:
	emit_signal("message_received", opcode, payload)
	
	match opcode:
		# Block 1 opcodes - Player character data
		# 546 = kub (player stats)
		546:
			_handle_kub(payload)
		
		# 547 = irq (jobs/professions)
		547:
			_handle_irq(payload)
		
		# 571 = hms (spell list)
		571:
			_handle_hms(payload)
		
		# 572 = ivx (inventory)
		572:
			_handle_ivx(payload)
		
		# 612 = itg (shortcut bar)
		612:
			_handle_itg(payload)
		
		# Other opcodes would be handled here
		_:
			pass

# Handle kvw (character info) - must happen after jtg
# Returns true if allowed, false if not
func handle_kvw(payload: PackedByteArray) -> bool:
	if not kvw_allowed:
		print("[GameClient] kvw not allowed - must receive jtg first")
		return false
	
	# Process kvw
	var data = WorldProto.decode_kvw(payload)
	if data.found:
		emit_signal("character_data_received", data.character_id, data)
		kvw_allowed = false  # Disable after use
	
	return kvw_allowed

# Handle kva (character alive)
func handle_kva(payload: PackedByteArray) -> void:
	var data = WorldProto.decode_kva(payload)
	if data.found:
		# Character is alive and can receive Block 1
		pass


# Handle jtg (job target greeting) - enables kvw
func set_kvw_allowed(allowed: bool) -> void:
	kvw_allowed = allowed
	if kvw_allowed:
		print("[GameClient] kvw allowed - jtg received")


# Internal handler for kub (player stats)
func _handle_kub(payload: PackedByteArray) -> void:
	if game_manager == null:
		return
	
	game_manager._handle_kub(payload)
	emit_signal("stats_received", game_manager.player_stats)

	# Mark Block 1 as received when we get stats
	block1_received = true

# Internal handler for irq (jobs/professions)
func _handle_irq(payload: PackedByteArray) -> void:
	if game_manager == null:
		return
	
	game_manager._handle_irq(payload)
	emit_signal("jobs_received", game_manager.player_jobs)

# Internal handler for hms (spell list)
func _handle_hms(payload: PackedByteArray) -> void:
	if game_manager == null:
		return
	
	game_manager._handle_hms(payload)
	emit_signal("spells_received", game_manager.player_spells)

# Internal handler for ivx (inventory)
func _handle_ivx(payload: PackedByteArray) -> void:
	if game_manager == null:
		return
	
	game_manager._handle_ivx(payload)
	emit_signal("inventory_received", game_manager.player_inventory.kamas, game_manager.player_inventory.items)

# Internal handler for itg (shortcut bar)
func _handle_itg(payload: PackedByteArray) -> void:
	if game_manager == null:
		return
	
	game_manager._handle_itg(payload)
	emit_signal("spell_bar_received", game_manager.spell_bar.bar_type, game_manager.spell_bar.shortcuts)


# Check if Block 1 has been fully received
func is_block1_received() -> bool:
	return block1_received

# Get player summary for debugging
func get_player_summary() -> Dictionary:
	if game_manager == null:
		return {}
	return game_manager.get_player_summary()


# Initialize the client
func initialize() -> void:
	kvw_allowed = false
	block1_received = false

# Reset state
func reset() -> void:
	kvw_allowed = false
	block1_received = false
	if game_manager != null:
		game_manager.initialize_player()