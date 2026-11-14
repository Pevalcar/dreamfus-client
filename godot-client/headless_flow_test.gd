# headless_flow_test.gd — Test automatizado del flujo completo.
# Sigue el mismo patrón que test_world_entry_e2e.gd y test_kqz_burst_e2e.gd
# Ejecutar: Godot_console.exe --headless --path <project> --scene res://scenes/test_headless_flow.tscn --quit
extends Node

const SimpleProtocolClient = preload("res://src/Network/SimpleProtocolClient.gd")

const API_URL := "http://127.0.0.1:8888/api/entrar"
const USER := "keka"
const PASS := "test"
const SERVER_ID := 290
const WS_PORT := 5557

var _failed := 0
var _auth_result: Dictionary = {}
var _selection: Dictionary = {}


func _ready() -> void:
	print("[TEST] Inicio test flujo completo")
	_run()


func _run() -> void:
	var token: String = await _http_login()
	if token == "":
		_fail("HTTP login failed")
		return _finish()

	var sel: Dictionary = await _ws_get_ticket(token)
	if sel.is_empty():
		_fail("WebSocket auth / server selection failed")
		return _finish()

	print("[TEST] Flow completado: HTTP + WS OK, ticket=%s..." % str(sel.get("ticket", "")).substr(0, 8))
	_finish()


func _add(tag: String, msg: String):
	print("[%s] %s" % [tag, msg])

func _fail(msg: String):
	_failed += 1
	printerr("[FAIL] %s" % msg)

func _finish():
	print("")
	print("=== Result: %s ===" % ("OK" if _failed == 0 else "%d failure(s)" % _failed))
	get_tree().quit(0 if _failed == 0 else 1)


# ── Paso 1: HTTP Login ─────────────────────────────────────────────────────

func _http_login() -> String:
	var http := HTTPRequest.new()
	add_child(http)

	var body := JSON.stringify({"usuario": USER, "clave": PASS, "ip": "127.0.0.1"})
	var err: int = http.request(API_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if err != OK:
		_fail("HTTPRequest.request error %d" % err)
		http.queue_free()
		return ""

	var res: Array = await http.request_completed
	var code: int = res[1]
	var text := (res[3] as PackedByteArray).get_string_from_utf8()
	print("[..] /api/entrar -> HTTP %d: %s" % [code, text.substr(0, 120)])

	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.get_data()) != TYPE_DICTIONARY:
		_fail("login response is not JSON")
		http.queue_free()
		return ""

	var data: Dictionary = json.get_data()
	http.queue_free()

	if not data.get("bien", false):
		_fail("login rejected by server")
		return ""

	print("[PASS] login ok, account=%d" % int(data.get("cuenta", 0)))
	return str(data.get("token", ""))


# ── Paso 2: WebSocket auth + server selection ──────────────────────────────

func _ws_get_ticket(token: String) -> Dictionary:
	var ws := SimpleProtocolClient.new()
	add_child(ws)

	ws.auth_response_received.connect(
		func(success: bool, account_id: int, servers: Array, error: String) -> void:
			_auth_result = {
				"success": success, "account_id": account_id,
				"servers": servers, "error": error,
			}
	)
	ws.server_selection_response_received.connect(
		func(success: bool, ticket: String, host: String, ports: Array, error: String, lang: String) -> void:
			_selection = {
				"success": success, "ticket": ticket, "host": host,
				"ports": ports, "error": error, "lang": lang,
			}
	)

	var install_id := "godot-headless-%d" % int(Time.get_unix_time_from_system())
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


# ── Helper: Await condition with timeout ───────────────────────────────────

func _wait_until(cond: Callable, timeout: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if cond.call():
			return true
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05
	return cond.call()
