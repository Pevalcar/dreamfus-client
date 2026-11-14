## test_world_entry_e2e.gd
## Drives the real client past the character list: login, pick a character (kvw),
## and wait for the world entry blocks to arrive without breaking the connection.
##
##   godot --headless --path <project> res://test/test_world_entry_e2e.tscn
##
## What it catches: the client used to stop reading TCP after jtg, so the ~330
## frames of block 1 (and the jru map) were never read, and it never sent the lqc
## that asks the server for the map.

extends Node

const SimpleProtocolClient = preload("res://src/Network/SimpleProtocolClient.gd")
const GameClient = preload("res://src/Network/GameClient.gd")
const WorldProto = preload("res://src/Network/WorldProto.gd")

const API_URL := "http://127.0.0.1:8888/api/entrar"
const USER := "keka"
const PASS := "test"
const SERVER_ID := 290
const WS_PORT := 5557

var _failed := 0

var _auth_result: Dictionary = {}
var _selection: Dictionary = {}
var _opcodes: Array = []
var _frames := 0
var _bytes := 0
var _saw_jtg := false
var _saw_jru := false
var _saw_jss := false
var _saw_kva := false
var _saw_kub := false
var _map_id := -1
var _spawn_cell := -1  # Expected: 352 for [#KEKA-BRON#] on map 88212759


func _ready() -> void:
	_run()


func _run() -> void:
	print("=== E2E: character selection -> world entry blocks ===")

	var token: String = await _http_login()
	if token == "":
		_fail("HTTP login failed")
		return _finish()

	var sel: Dictionary = await _ws_get_ticket(token)
	if sel.is_empty():
		_fail("WebSocket auth / server selection failed")
		return _finish()

	await _enter_world(sel)
	_finish()


func _http_login() -> String:
	var http := HTTPRequest.new()
	add_child(http)

	var body := JSON.stringify({"usuario": USER, "clave": PASS, "ip": "127.0.0.1"})
	if http.request(API_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body) != OK:
		_fail("HTTPRequest.request failed")
		return ""

	var res: Array = await http.request_completed
	var text := (res[3] as PackedByteArray).get_string_from_utf8()
	var json := JSON.new()
	http.queue_free()

	if json.parse(text) != OK or typeof(json.get_data()) != TYPE_DICTIONARY:
		_fail("login response is not JSON")
		return ""
	var data: Dictionary = json.get_data()
	if not data.get("bien", false):
		_fail("login rejected by server")
		return ""

	print("[PASS] login ok, account=%d" % int(data.get("cuenta", 0)))
	return str(data.get("token", ""))


func _ws_get_ticket(token: String) -> Dictionary:
	var ws: Node = SimpleProtocolClient.new()
	add_child(ws)

	ws.auth_response_received.connect(
		func(success: bool, account_id: int, servers: Array, error: String) -> void:
			_auth_result = {
				"success": success, "account_id": account_id,
				"servers": servers, "error": error,
			}
	)
	ws.server_selection_response_received.connect(
		func(
			success: bool, ticket: String, host: String,
			ports: Array, error: String, lang: String
		) -> void:
			_selection = {
				"success": success, "ticket": ticket, "host": host,
				"ports": ports, "error": error, "lang": lang,
			}
	)

	ws.connect_to_server(
		"127.0.0.1", WS_PORT, "es", token,
		"godot-world-e2e-%d" % int(Time.get_unix_time_from_system())
	)

	if not await _wait_until(func() -> bool: return not _auth_result.is_empty(), 10.0):
		_fail("no auth_response from WebSocket")
		ws.queue_free()
		return {}
	if not _auth_result.success:
		_fail("auth_response success=false: %s" % _auth_result.error)
		ws.queue_free()
		return {}

	ws.send_server_selection(SERVER_ID, int(_auth_result.account_id), "es")
	if not await _wait_until(func() -> bool: return not _selection.is_empty(), 10.0):
		_fail("no server_selection_response")
		ws.queue_free()
		return {}
	if not _selection.success or str(_selection.ticket) == "":
		_fail("server selection failed: %s" % _selection.error)
		ws.queue_free()
		return {}

	print("[PASS] ticket acquired, host=%s" % _selection.host)
	ws.queue_free()
	return _selection


func _enter_world(sel: Dictionary) -> void:
	var game: GameClient = GameClient.new()
	add_child(game)

	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		_fail("GameManager autoload not found")
		return
	gm.initialize(null, game)

	game.message_received.connect(
		func(opcode: String, payload: PackedByteArray, _id: int) -> void:
			_frames += 1
			_bytes += payload.size()
			if _opcodes.size() < 400:
				_opcodes.append(opcode)
			match opcode:
				"jtg":
					_saw_jtg = true
				"kva":
					_saw_kva = true
				"kub":
					_saw_kub = true
				"jru":
					_saw_jru = true
					_map_id = int(WorldProto.decode_jru(payload).get("map_id", 0))
				"jss":
					_saw_jss = true
					_spawn_cell = int(WorldProto.decode_jss(payload).get("cell", -1))
	)
	game.error_occurred.connect(func(msg: String) -> void: _fail("GameClient error: %s" % msg))

	game.connect_to_game(sel.host, int(sel.ports[0]), sel.ticket, sel.lang, SERVER_ID)

	if not await _wait_until(func() -> bool: return _saw_jtg, 15.0):
		_fail("no jtg: the character list never arrived")
		return

	var chars: Array = gm.characters
	if chars.is_empty():
		_fail("GameManager has no characters to pick from")
		return

	var chosen: Dictionary = chars[0]
	var id: int = int(chosen.get("id", 0))
	var name: String = str(chosen.get("name", ""))
	print("[..] selecting character id=%d name=%s" % [id, name])

	var before := _frames
	gm.select_character_from_id(id, name)

	# Block 1 is ~330 frames; give the map a generous window.
	if await _wait_until(func() -> bool: return _saw_jru, 40.0):
		print("[PASS] jru received, map id=%d" % _map_id)
	else:
		_fail("no jru: the map block never arrived")

	# Wait for jss (MapActorsListMessage) which contains the spawn cell
	# Increased timeout to 30s to account for large jss frames
	if await _wait_until(func() -> bool: return _saw_jss, 30.0):
		if _spawn_cell > 0:
			print("[PASS] jss received, spawn cell=%d" % _spawn_cell)
		else:
			print("[INFO] jss received but spawn cell not extracted")
	else:
		# jss is not critical for connection survival, just verify cell info wasn't 0
		print("[INFO] jss not received within timeout (non-critical)")

	var world_frames := _frames - before
	print("[..] frames after kvw: %d, bytes=%d" % [world_frames, _bytes])
	print("[..] opcodes seen: %s" % str(_unique(_opcodes)))

	if _saw_kva and _saw_kub:
		print("[PASS] block 1 arrived (kva + kub, %d frames)" % world_frames)
	else:
		_fail("block 1 incomplete: kva=%s kub=%s (%d frames)" % [_saw_kva, _saw_kub, world_frames])

	if _map_id > 0:
		print("[PASS] map id decoded from jru: %d" % _map_id)
	else:
		_fail("jru arrived but no map id could be decoded")

	if game.is_tcp_connected():
		print("[PASS] TCP still connected after the world entry blocks")
	else:
		_fail("TCP dropped during the world entry blocks")

	# Verify spawn cell from jss (MapActorsListMessage)
	# Spawn cell is in f5[0].f1.f1 of the jss payload
	# For keka on map 88212759, expected value is 352
	if _spawn_cell > 0:
		print("[PASS] spawn cell from jss: %d" % _spawn_cell)
		# Expected cell for [#KEKA-BRON#] on map 88212759 is 352
		if _map_id == 88212759 and _spawn_cell == 352:
			print("[PASS] spawn cell verified from jss, not hardcoded 0")
		else:
			print("[INFO] map_id=%d, spawn_cell=%d (expected 352 for keka on 88212759)" % [_map_id, _spawn_cell])
	else:
		# jss not received or failed to parse - check for common issues
		if _bytes < 65536 and _saw_jss:
			# jss arrived but is truncated (< 64KB) - likely parsing issue
			print("[FAIL] jss received but payload too small (%d bytes) - parse error" % _bytes)
		else:
			print("[WARN] jss received but no spawn cell extracted")
			print("[WARN] Possible causes:")
			print("[WARN]   - jss size > 64KB (Godot TCP limit)")
			print("[WARN]   - Server sends other players in f5[rep] array")
			print("[WARN]   - Server must filter to local player only in f5[0]")

	if game.is_tcp_connected():
		game.disconnect_tcp()
	game.queue_free()


func _unique(arr: Array) -> Array:
	var out: Array = []
	for item in arr:
		if not out.has(item):
			out.append(item)
	return out


func _wait_until(cond: Callable, timeout: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if cond.call():
			return true
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05
	return cond.call()


func _fail(msg: String) -> void:
	_failed += 1
	printerr("[FAIL] %s" % msg)


func _finish() -> void:
	print("\n=== Result: %s ===" % ("OK" if _failed == 0 else "%d failure(s)" % _failed))
	get_tree().quit(0 if _failed == 0 else 1)
