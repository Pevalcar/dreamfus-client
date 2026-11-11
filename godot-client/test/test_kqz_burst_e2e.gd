## test_kqz_burst_e2e.gd
## End-to-end check of the real login chain against a running server:
##   HTTP /api/entrar -> WS auth -> WS server_selection -> TCP kqz -> welcome burst
## Asserts the burst arrives and that kvi decodes into characters.
##
## Runs as a scene so the project autoloads exist (GameClient/SimpleProtocolClient
## reference the GameManager singleton at load time, which --script mode lacks):
##   godot --headless --path <project> res://test/test_kqz_burst_e2e.tscn
##
## Regression under test: the server frames with a VarInt length prefix
## (NetworkMessage.WriteFrameAsync -> CodedOutputStream.WriteUInt32, which is a
## varint, not a fixed32). Reading it as uint32 LE turned the 25-byte "kra" frame
## (19 0A 17 0A ...) into 169282073 and killed the connection.

extends Node

const SimpleProtocolClient = preload("res://src/Network/SimpleProtocolClient.gd")
const GameClient = preload("res://src/Network/GameClient.gd")
const Proto = preload("res://src/Network/Proto.gd")
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
var _kvi_payloads: Array = []
var _saw_jtg := false


func _ready() -> void:
	_run()


func _run() -> void:
	print("=== E2E: login -> kqz -> welcome burst ===")

	_test_framing_regression()

	var token: String = await _http_login()
	if token == "":
		_fail("HTTP login failed")
		return _finish()

	var ticket_data: Dictionary = await _ws_get_ticket(token)
	if ticket_data.is_empty():
		_fail("WebSocket auth / server selection failed")
		return _finish()

	await _tcp_burst(ticket_data)
	_finish()


## The bug in one assertion: a "kra" frame is 25 bytes, prefixed 0x19.
func _test_framing_regression() -> void:
	var frame := PackedByteArray([0x19, 0x0A, 0x17, 0x0A, 0x13])
	var read: Array = Proto.read_varint(frame, 0)
	if read[0] == 25 and read[1] == 1:
		print("[PASS] VarInt prefix 0x19 -> 25 bytes (offset 1)")
	else:
		_fail("VarInt prefix misread: %s" % [str(read)])


func _http_login() -> String:
	var http := HTTPRequest.new()
	add_child(http)

	var body := JSON.stringify({"usuario": USER, "clave": PASS, "ip": "127.0.0.1"})
	var err: int = http.request(
		API_URL,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		body,
	)
	if err != OK:
		_fail("HTTPRequest.request error %d" % err)
		return ""

	var res: Array = await http.request_completed
	var code: int = res[1]
	var text := (res[3] as PackedByteArray).get_string_from_utf8()
	print("[..] /api/entrar -> HTTP %d: %s" % [code, text.substr(0, 120)])

	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.get_data()) != TYPE_DICTIONARY:
		_fail("login response is not JSON")
		return ""

	var data: Dictionary = json.get_data()
	http.queue_free()

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

	var install_id := "godot-e2e-%d" % int(Time.get_unix_time_from_system())
	ws.connect_to_server("127.0.0.1", WS_PORT, "es", token, install_id)

	if not await _wait_until(func() -> bool: return not _auth_result.is_empty(), 10.0):
		_fail("no auth_response from WebSocket")
		ws.queue_free()
		return {}

	if not _auth_result.success:
		_fail("auth_response success=false: %s" % _auth_result.error)
		ws.queue_free()
		return {}

	var account_id: int = int(_auth_result.account_id)
	print("[PASS] WS auth ok, account=%d, servers=%d" % [
		account_id, (_auth_result.servers as Array).size()
	])

	ws.send_server_selection(SERVER_ID, account_id, "es")

	if not await _wait_until(func() -> bool: return not _selection.is_empty(), 10.0):
		_fail("no server_selection_response")
		ws.queue_free()
		return {}

	if not _selection.success or str(_selection.ticket) == "":
		_fail("server selection failed: %s" % _selection.error)
		ws.queue_free()
		return {}

	print("[PASS] ticket=%s... host=%s ports=%s" % [
		str(_selection.ticket).substr(0, 8), _selection.host, str(_selection.ports)
	])
	ws.queue_free()
	return _selection


func _tcp_burst(sel: Dictionary) -> void:
	var ports: Array = sel.ports
	if ports.is_empty():
		_fail("server selection returned no ports")
		return

	var game: GameClient = GameClient.new()
	add_child(game)

	# Drive the production path too: GameManager is what decodes kvi and fires
	# characters_received for the UI (and what stops reading after jtg).
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.initialize(null, game)
	else:
		_fail("GameManager autoload not found")

	game.message_received.connect(
		func(opcode: String, payload: PackedByteArray, _id: int) -> void:
			_opcodes.append(opcode)
			if opcode == "kvi":
				_kvi_payloads.append(payload)
			elif opcode == "jtg":
				_saw_jtg = true
	)
	game.error_occurred.connect(func(msg: String) -> void: _fail("GameClient error: %s" % msg))

	game.connect_to_game(sel.host, int(ports[0]), sel.ticket, sel.lang)

	await _wait_until(func() -> bool: return _saw_jtg, 15.0)

	print("[..] opcodes received: %s" % str(_opcodes))

	if _opcodes.has("kra"):
		print("[PASS] kra (ticket acked)")
	else:
		_fail("no kra: the server did not accept the kqz ticket")

	if _kvi_payloads.is_empty():
		_fail("no kvi: character list never arrived")
	else:
		print("[PASS] kvi received (%d frame(s))" % _kvi_payloads.size())
		var chars: Array = WorldProto.decode_kvi(_kvi_payloads[0])
		if chars.is_empty():
			_fail("kvi decoded to 0 characters")
		else:
			print("[PASS] kvi decoded %d character(s):" % chars.size())
			for c in chars:
				print("        id=%s name=%s level=%s breed=%s sex=%s" % [
					str(c.get("id", 0)), str(c.get("name", "?")),
					str(c.get("level", 0)), str(c.get("breed", 0)), str(c.get("sex", 0)),
				])

	if _saw_jtg:
		print("[PASS] jtg (end of burst)")
	else:
		_fail("no jtg: burst never completed")

	if gm != null:
		if gm.characters.size() > 0:
			print("[PASS] GameManager.characters = %d (UI signal path)" % gm.characters.size())
		else:
			_fail("GameManager received no characters: the UI would stay empty")

	if game.is_tcp_connected():
		game.disconnect_tcp()
	game.queue_free()


## Await a condition, polling the main loop so nodes keep processing.
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
