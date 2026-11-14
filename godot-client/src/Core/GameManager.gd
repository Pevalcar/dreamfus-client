# GameManager.gd - Manages game state and handles protocol messages
# Note: This is a singleton autoload, do not use class_name with autoload
extends Node

## Signals
signal auth_completed(account_id: int, servers_json: String)
signal error_received(error_code: String, error_message: String)
signal character_selected(character_id: int, character_name: String)
signal characters_received(characters: Array)
## Emitted when jru map block arrives; carries map_id and starting cell_id
signal map_loaded(map_id: int, cell_id: int)

## Game state enum
enum GameState {
	LAUNCHER,
	CHARACTER_SELECT,
	IN_GAME,
	DISCONNECTED,
}

## Protocol decoder
const WorldProto = preload("res://src/Network/WorldProto.gd")
const Proto = preload("res://src/Network/Proto.gd")
const CharacterData = preload("res://src/Data/CharacterData.gd")

## Static reference to this singleton instance
static var instance: GameManager = null

## Character data
var current_character: CharacterData = null

## Player state from Block 1 messages
var player_stats: Dictionary = { }
var player_jobs: Array = []
var player_spells: Array = []
var player_inventory: Dictionary = { "kamas": 0, "items": [] }
var spell_bar: Dictionary = { "bar_type": 0, "shortcuts": [] }

## Player info from earlier messages
var player_id: int = 0
var player_name: String = ""

## Current map position (set by jru handler)
var current_map_id: int = 0
var current_cell_id: int = 0

## Connection state
var is_connected: bool = false
var is_character_loaded: bool = false

## Server connection configuration (TCP protobuf port 5555)
var server_host: String = "127.0.0.1"
var server_port: int = 5555

## Connection references
var ws_client: Node = null
var game_client: GameClient = null

## Current game state 
var state: GameState = GameState.LAUNCHER

## Selected character (alias for current_character for GameUI compatibility)
var selected_character: Node = null

## Character list for selection UI
var characters: Array = []

## Server list from auth_response
var servers: Array = []

## Selected server info
var selected_server_id: int = 0
## Pending map id waiting for jss to resolve cell position
var _pending_map_id: int = 0

## Auth parameters stored for TCP connection (used before connection)
# Note: These are now stored in GameClient._auth_token, _auth_lang, etc.
# Keeping for backward compatibility but deprecated
var _pending_auth_token: String = ""
var _pending_auth_lang: String = "" # Must be set before use - prevents stale values
var _pending_auth_install_id: String = ""

## TCP connection attempt in progress
var _tcp_connecting: bool = false

## Map block reception tracking
## Used to prevent UI freeze - wait at most 15s for map block (jru)
var _map_block_received: bool = false
var _map_block_timeout: Timer = null


# Called when the node is added to the scene tree for the first time.
func _ready() -> void:
	# Initialize with default CharacterData
	current_character = CharacterData.new()
	selected_character = current_character
	# Register self as the singleton instance
	instance = self


# Initialize the GameManager with client references
func initialize(ws: Node = null, game: Node = null) -> void:
	print(
		"[GameManager] initialize called with ws_client=%s, game_client=%s"
		% [ws != null, game != null]
	)
	ws_client = ws
	game_client = game

	# Store reference back to this instance in the network clients
	if ws_client != null:
		ws_client.game_manager = self
	if game_client != null:
		game_client.game_manager = self
		# Connect TCP client signals
		game_client.connected.connect(_on_tcp_connected)
		game_client.disconnected.connect(_on_tcp_disconnected)
		game_client.message_received.connect(_on_tcp_message_received)
		game_client.characters_received.connect(_on_characters_received)

	print("[GameManager] Initialization complete")


# Change game state
func change_state(new_state: GameState) -> void:
	print("[GameManager] State change: %s -> %s" % [state, new_state])
	state = new_state


# Initialize player state for a new session
func initialize_player() -> void:
	player_stats = { }
	player_jobs = []
	player_spells = []
	player_inventory = { "kamas": 0, "items": [], "found": false }
	spell_bar = { "bar_type": 0, "shortcuts": [], "found": false }
	current_character = CharacterData.new()
	is_character_loaded = false


# Authenticate with the game server via WebSocket (protocol 3.6.10.10)
func attempt_login_ws(lang: String, token: String, install_id: String) -> void:
	print(
		"[GameManager] attempt_login_ws: token=%s..., port=%d" % [token.substr(0, 8), server_port]
	)

	# Connect via WebSocket
	if ws_client != null:
		ws_client.connect_to_server(server_host, 5557, lang, token, install_id)
		print("[GameManager] WebSocket connection initiated to %s:%d" % [server_host, 5557])
	else:
		printerr("[GameManager] ERROR: ws_client is NULL!")
		error_received.emit("WS_NULL", "WebSocket client not initialized")


# Authenticate with the game server via TCP (protobuf on port 5555)
func attempt_login(lang: String, token: String, install_id: String) -> void:
	print("[GameManager] attempt_login: token=%s..., port=%d" % [token.substr(0, 8), server_port])

	# Connect to the TCP game server (protobuf protocol)
	if game_client != null:
		# Store auth params for when TCP connects
		_pending_auth_token = token
		_pending_auth_lang = lang
		_pending_auth_install_id = install_id

		var err = game_client.connect_to_game(server_host, server_port)
		if err != OK:
			error_received.emit("TCP_CONNECT", "Failed to connect to game server: %d" % err)
		else:
			print("[GameManager] TCP connection initiated to %s:%d" % [server_host, server_port])
	else:
		printerr("[GameManager] ERROR: game_client is NULL!")
		error_received.emit("TCP_NULL", "TCP client not initialized")


# Handle server selection response (ticket for TCP connection)
## WebSocket closes 500ms after sending server_selection_response (server timeout).
## Client must connect TCP and send kqz within this window.
func handle_server_selection(
	ticket: String,
	host: String,
	ports: Array,
	language: String = "es",
	server_id: int = 0,
) -> void:
	print(
		"[GameManager] Server selection, ticket=%s..., host=%s, ports=%s, lang=%s, server=%d"
		% [ticket.substr(0, 8), host, str(ports), language, server_id]
	)
	if ports.size() > 0:
		var port = ports[0]
		# Connect to TCP game server
		if game_client != null:
			# Pass ticket, language, and server_id to connect_to_game (handles kqz automatically)
			# Note: Do NOT call change_auth_stage() here - that's for connection server phase
			var err = game_client.connect_to_game(host, port, ticket, language, server_id)
			if err != OK:
				error_received.emit("TCP_CONNECT", "Failed to connect to game server")
			else:
				print(
					"[GameManager] Conexión TCP iniciada con ticket=%s..., lang=%s, server=%d"
					% [ticket.substr(0, 8), language, server_id]
				)
		else:
			printerr("[GameManager] ERROR: game_client is NULL!")
			error_received.emit("TCP_NULL", "TCP client not initialized")
	else:
		error_received.emit("NO_PORTS", "No ports available in server selection")


# Request a server to connect to (called from Main.gd when user selects server)
func request_server_selection(server_id: int, account_id: int) -> void:
	print(
		"[GameManager] request_server_selection: server_id=%d, account_id=%d"
		% [server_id, account_id]
	)
	# Send server selection via WebSocket to get ticket
	if ws_client != null:
		var lang = _pending_auth_lang if _pending_auth_lang != "" else "es"
		ws_client.send_server_selection(server_id, account_id, lang)
		print("[GameManager] Enviando selección de servidor vía WebSocket")
	elif game_client != null and game_client.is_tcp_connected():
		# Fallback to TCP if WebSocket not available
		game_client.select_server_with_id(server_id)
		print("[GameManager] Enviando selección de servidor vía TCP")
	else:
		printerr("[GameManager] Ningún cliente disponible para selección de servidor")
		error_received.emit("PROXY_NULL", "No client available for server selection")


# Auto-select first available server (called after auth response)
func auto_select_first_server() -> void:
	print("[GameManager] auto_select_first_server: servers=%d" % servers.size())
	if servers.size() > 0:
		var first_server = servers[0]
		var server_id = first_server.get("id", 0)
		var account_id = player_id
		print(
			"[GameManager] Seleccionando automáticamente servidor %d (cuenta %d)"
			% [server_id, account_id]
		)
		request_server_selection(server_id, account_id)
	else:
		print("[GameManager] No hay servidores disponibles para auto-select")
		error_received.emit("NO_SERVERS", "No servers available for auto-selection")


# Select character by ID (called from Main.gd)
func select_character_from_id(character_id: int, character_name: String) -> void:
	print("[GameManager] select_character_from_id: id=%d, name=%s" % [character_id, character_name])
	current_character = CharacterData.new()
	current_character.character_id = character_id
	current_character.character_name = character_name
	current_character.display_name = character_name # Sync display_name field for GameUI compatibility
	current_character.level = 1 # Initialize level
	is_character_loaded = true
	selected_character = current_character # Update selected_character alias
	if game_client != null:
		game_client.send_character_selection(character_id)
		# lqc is the client saying it has digested block 1; the server answers with
		# the map. It is sent here rather than on a later trigger because the
		# emulator sends block 1 and 2 before it reads the next frame, so this
		# queues behind them and the order on the wire is the real one.
		game_client.send_push("lqc")

	# Emit character selected signal
	character_selected.emit(character_id, character_name)

	# The map block arrives after the lqc that select_character_from_id sends;
	# this timer is only the safety net if it never does.
	start_map_block_timer()


# Getter for selected character (used by GameUI via _get_selected_character)
func get_selected_character() -> CharacterData:
	return current_character


# Handle kvw (character info) message - should be called from WorldEntry
func handle_kvw(payload: PackedByteArray) -> void:
	# kvw is handled elsewhere for character metadata
	pass


# Handle kva (character alive) message - should be called from WorldEntry
func handle_kva_with_id(payload: PackedByteArray, character_id: int) -> void:
	# kva is handled elsewhere for character alive status
	# This confirms the character is ready to receive Block 1
	print("[GameManager] handle_kva_with_id: character_id=%d" % character_id)
	if not is_character_loaded:
		current_character.character_id = character_id
		is_character_loaded = true
		selected_character = current_character


# Handle TCP message by opcode
func handle_tcp_message(opcode: String, payload: PackedByteArray) -> void:
	match opcode:
		"kvi":
			_handle_kvi_messages(payload)
		"jru":
			_handle_jru_map_block(payload)
		"jss":
			_handle_jss_map_actors(payload)
		"jtg":
			_handle_jtg_end_of_burst(payload)
		"kva":
			_handle_kva(payload)
		"kub":
			_handle_kub(payload)
		"irq":
			_handle_irq(payload)
		"hms":
			_handle_hms(payload)
		"ivx":
			_handle_ivx(payload)
		"itg":
			_handle_itg(payload)
		_:
			print("[GameManager] Ignorando opcode TCP: %s" % opcode)


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
		"shortcuts_count": spell_bar.shortcuts.size() if spell_bar else 0,
	}


## Handle server selection error
func handle_server_selection_error(error: String) -> void:
	print("[GameManager] Server selection error: %s" % error)
	error_received.emit("SERVER_SELECTION_FAILED", error)
	state = GameState.LAUNCHER


# ========== Map Block Timeout Handlers ==========
## Manage timeout for map block (jru) reception.
## The map block follows the lqc sent after kvw; the timer only covers the case
## where the server never answers, so the UI does not sit waiting forever.
func create_map_block_timeout() -> void:
	"""Create timer that will trigger if map block is not received."""
	_map_block_timeout = Timer.new()
	_map_block_timeout.wait_time = 15.0
	_map_block_timeout.one_shot = true
	_map_block_timeout.connect("timeout", _on_map_block_timeout)
	add_child(_map_block_timeout)
	_map_block_timeout.start()
	print("[GameManager] Map block timeout timer created (15s)")


func start_map_block_timer() -> void:
	"""Start waiting for map block. Call this when ticket is sent."""
	_map_block_received = false
	_map_block_timeout = null
	create_map_block_timeout()


func on_map_block_received(map_id: int) -> void:
	"""Called when map block (jru) is received. Stop the timer."""
	_map_block_received = true
	if _map_block_timeout:
		_map_block_timeout.stop()
		_map_block_timeout.queue_free()
		_map_block_timeout = null
		print("[GameManager] Map block received (map_id=%d), timeout cancelled" % map_id)


# TCP Connection handlers
func _on_tcp_connected() -> void:
	print("[GameManager] TCP connected")
	is_connected = true
	change_state(GameState.CHARACTER_SELECT)


func _on_tcp_disconnected() -> void:
	print("[GameManager] TCP disconnected")
	is_connected = false
	change_state(GameState.DISCONNECTED)


func _on_tcp_message_received(opcode: String, payload: PackedByteArray, request_id: int) -> void:
	print("[GameManager] TCP message: opcode=%s" % opcode)
	# Forward to TCP message handler
	handle_tcp_message(opcode, payload)


func _on_characters_received(characters: Array) -> void:
	print("[GameManager] Characters received: %d" % characters.size())
	# Re-emit to UI
	characters_received.emit(characters)


# Handle selected character getter (used for property access)
func _get_selected_character() -> CharacterData:
	return current_character


# Handle selected character setter
func _set_selected_character(value: CharacterData) -> void:
	current_character = value


# Handle kva (character alive) message - server confirms character is available
func _handle_kva(payload: PackedByteArray) -> void:
	# kva indicates the character is alive and can receive Block 1 messages
	# The character_id is extracted from the payload during TCP handshake
	print("[GameManager] kva recibido — character alive confirmation")


# Handle kvi (character list) message - part of welcome burst
func _handle_kvi_messages(payload: PackedByteArray) -> void:
	print("[GameManager] kvi recibido en burst")
	var chars = WorldProto.decode_kvi(payload)
	if chars != null and chars.size() > 0:
		for char_data in chars:
			print(
				"[GameManager]    Personaje: id=%s, name=%s, level=%s, breed=%s, sex=%s"
				% [
					char_data.get("id", 0),
					char_data.get("name", "???"),
					char_data.get("level", 0),
					char_data.get("breed", 0),
					char_data.get("sex", 0),
				]
			)
		# Character list is now emitted by GameClient.characters_received
		# This is stored in GameManager for other handlers if needed
		if GameManager.instance != null:
			GameManager.instance.characters = chars


# Handle jtg (end of burst) message
func _handle_jtg_end_of_burst(payload: PackedByteArray) -> void:
	print("[GameManager] jtg recibido — burst completo (%d personajes)" % characters.size())
	# Emit characters_received to UI after jtg signals burst completion
	# Per protocol: jtg is the trigger that the character list is complete
	characters_received.emit(characters)


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
				print(
					"[GameManager]   Estadistica ID %d: base=%d, scroll=%d, equipment=%d"
					% [
						stat_id,
						stat.get("base", 0),
						stat.get("scroll", 0),
						stat.get("equipment", 0),
					]
				)

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
			print(
				"[GameManager]   Profesion ID %d: nivel %d (next: %d)"
				% [job.profession, job.level, job.next_level]
			)


# Handle hms (spell list) - Block 1
func _handle_hms(payload: PackedByteArray) -> void:
	# Handle hms (spell list).
	# hms format: f1 (repeated) { f1: grade, f3: spell_id, f4: origin }, f2: 1 at end
	var data = WorldProto.decode_hms(payload)
	if data.found:
		print("[GameManager] hms - %d hechizos aprendidos" % data.spells.size())
		player_spells = data.spells

		for spell in data.spells:
			print(
				"[GameManager]   Hechizo ID %d: grado %d, origen %d"
				% [spell.spell_id, spell.grade, spell.origin]
			)


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
			print(
				"[GameManager]      Item slot %d: template=%d, count=%d, uid=%d"
				% [item.slot, item.template, item.count, item.uid]
			)


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
				print(
					"[GameManager]     Slot %d: Item template %d"
					% [shortcut.slot, shortcut.item_template]
				)
			else:
				print("[GameManager]     Slot %d: Spell ID %d" % [shortcut.slot, shortcut.spell_id])


# Update character stats from player_stats dictionary
func _update_character_stats() -> void:
	current_character.stats = player_stats


# Handle jru (map block / CurrentMapMessage) - CRITICAL for Godot client
func _handle_jru_map_block(payload: PackedByteArray) -> void:
	"""Handle map block message - stores map_id, waits for jss to resolve cell."""
	if _map_block_timeout:
		var map_data = WorldProto.decode_jru(payload)
		if map_data.has("map_id") and map_data.map_id > 0:
			print("[GameManager] jru - Map block received: map_id=%d" % map_data.map_id)
			on_map_block_received(map_data.map_id)
			current_map_id = map_data.map_id
			_pending_map_id = map_data.map_id
			# Don't emit yet — wait for jss which carries the actual cell position
		else:
			print("[GameManager] jru - Map block with invalid data")
	else:
		print("[GameManager] jru received, but no timeout timer active")


func _handle_jss_map_actors(payload: PackedByteArray) -> void:
	"""Extract player cell from jss (MapActorsListMessage) and emit map_loaded."""
	var data = WorldProto.decode_jss(payload)
	if data.has("cell") and data.cell > 0:
		current_cell_id = data.cell
		if _pending_map_id > 0:
			print(
				"[GameManager] jss - Player cell: %d on map %d" % [current_cell_id, _pending_map_id]
			)
			map_loaded.emit(_pending_map_id, current_cell_id)
			_pending_map_id = 0
		else:
			print(
				"[GameManager] jss - cell=%d but no pending map (jru already emitted?)"
				% current_cell_id
			)
	else:
		print("[GameManager] jss - no cell info (might be other actors only)")


func _on_map_block_timeout() -> void:
	"""Called when map block timeout expires."""
	if not _map_block_received:
		printerr("[GameManager] ERROR: Map block (jru) not received after 15s!")
		printerr("[GameManager] Possible reasons:")
		printerr("[GameManager]   - Server delay processing")
		printerr("[GameManager]   - Server bug - not sending jru")
		printerr("[GameManager]   - Network issue")
		# Fallback: if jss never arrived, emit with map_id and cell=0
		if _pending_map_id > 0:
			print(
				"[GameManager] Timeout: emitting map_loaded with map_id=%d cell=0 (no jss)"
				% _pending_map_id
			)
			map_loaded.emit(_pending_map_id, 0)
			_pending_map_id = 0
		# Disconnect safely
		if game_client and game_client.is_tcp_connected():
			print("[GameManager ] Disconnecting due to map timeout...")
			game_client.game_manager = null
			game_client.disconnect_tcp()
		# Notify user
		error_received.emit("MAP_TIMEOUT", "Map block not received after 15s")
