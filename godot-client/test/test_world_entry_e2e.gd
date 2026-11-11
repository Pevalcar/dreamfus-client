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
var _saw_kva := false
var _saw_kub := false
var _map_id := -1


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
	)
	game.error_occurred.connect(func(msg: String) -> void: _fail("GameClient error: %s" % msg))

	game.connect_to_game(sel.host, int(sel.ports[0]), sel.ticket, sel.lang)

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
