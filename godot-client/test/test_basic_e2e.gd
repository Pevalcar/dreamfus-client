## test_basic_e2e.gd
## Test basic E2E flow to verify the testing system works.
## This test verifies the minimal login -> character select -> world entry flow.
##
## Run with: godot --headless --path <project> res://test/test_basic_e2e.tscn

extends Node

const API_URL := "http://127.0.0.1:8888/api/entrar"
const USER := "keka"
const PASS := "test"
const SERVER_ID := 290
const WS_PORT := 5557

var _failed = 0
var _steps_done = []
var _steps_failed = []

func _ready() -> void:
	_run_test()

func _run_test() -> void:
	print("=== Básico E2E Test: Verificar sistema de testing ===")
	
	# Step 1: Verificar que podemos hacer login HTTP
	if not await _test_http_login():
		return _finish()
	
	# Step 2: Verificar WebSocket auth y server selection
	if not await _test_ws_flow():
		return _finish()
	
	# Step 3: Entrar al mundo
	if not await _test_game_flow():
		return _finish()
	
	_finish()

func _test_http_login() -> bool:
	print("[Step 1] Probando login HTTP...")
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var body = JSON.stringify({"usuario": USER, "clave": PASS, "ip": "127.0.0.1"})
	var err = http.request(API_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	
	if err != OK:
		_fail("HTTPRequest.request failed")
		http.queue_free()
		return false
	
	var res = await http.request_completed
	var text = (res[3] as PackedByteArray).get_string_from_utf8()
	var json = JSON.new()
	http.queue_free()
	
	if json.parse(text) != OK:
		_fail("Respuesta no es JSON: %s" % text)
		return false
	
	var data = json.get_data()
	if not data.get("bien", false):
		_fail("Login rechazado por el servidor")
		return false
	
	var token = str(data.get("token", ""))
	if token == "":
		_fail("No se recibió token")
		return false
	
	print("  ✓ Login HTTP exitoso, token=%s..." % token.substr(0, 10))
	_steps_done.append("http_login")
	return true

func _test_ws_flow() -> bool:
	print("[Step 2] Probando flujo WebSocket...")
	
	var SimpleProtocolClient = preload("res://src/Network/SimpleProtocolClient.gd")
	var ws = SimpleProtocolClient.new()
	add_child(ws)
	
	var auth_result = {}
	var selection_result = {}
	
	ws.auth_response_received.connect(
		func(success: bool, account_id: int, servers: Array, error: String) -> void:
			auth_result = {"success": success, "account_id": account_id, "error": error}
	)
	
	ws.server_selection_response_received.connect(
		func(success: bool, ticket: String, host: String, ports: Array, error: String, lang: String) -> void:
			selection_result = {"success": success, "ticket": ticket, "host": host, "error": error}
	)
	
	ws.connect_to_server("127.0.0.1", WS_PORT, "es", "test_token", "test_session")
	
	# Esperar autenticación
	if not await _wait_for_dict(auth_result, 10.0):
		_fail("Timeout sin auth_response")
		ws.queue_free()
		return false
	
	if not auth_result.get("success", false):
		_fail("Auth fallido: %s" % auth_result.get("error", "unknown"))
		ws.queue_free()
		return false
	
	# Pedir selección de servidor
	ws.send_server_selection(SERVER_ID, int(auth_result.get("account_id", 0)), "es")
	
	if not await _wait_for_dict(selection_result, 10.0):
		_fail("Timeout sin server_selection_response")
		ws.queue_free()
		return false
	
	if not selection_result.get("success", false):
		_fail("Server selection fallido: %s" % selection_result.get("error", "unknown"))
		ws.queue_free()
		return false
	
	print("  ✓ WebSocket flow exitoso, host=%s" % selection_result.get("host", ""))
	_steps_done.append("ws_flow")
	ws.queue_free()
	return true

func _test_game_flow() -> bool:
	print("[Step 3] Probando flujo del juego...")
	
	var game = preload("res://src/Network/GameClient.gd").new()
	add_child(game)
	
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		_fail("GameManager autoload no encontrado")
		game.queue_free()
		return false
	
	gm.initialize(null, game)
	
	# Conectar y esperar un mensaje básico
	var saw_jtg = false
	var connection_ok = false
	
	game.message_received.connect(
		func(opcode: String, payload: PackedByteArray, id: int) -> void:
			if opcode == "jtg":
				saw_jtg = true
				print("    ✓ Mensaje jtg recibido")
	)
	
	game.error_occurred.connect(
		func(msg: String) -> void:
			print("    ! Error GameClient: %s" % msg)
	)
	
	game.connect_to_game("127.0.0.1", 5555, "test_ticket", "es")
	
	# Verificar conexión TCP - using polling approach
	var start_time = Time.get_ticks_msec()
	var timeout_ms = 10000
	var connected_to_tcp = false
	while (Time.get_ticks_msec() - start_time) < timeout_ms:
		if game.is_tcp_connected():
			connected_to_tcp = true
			break
		await get_tree().create_timer(0.1).timeout
	
	if connected_to_tcp == false:
		_fail("No se pudo conectar al servidor de juego")
		game.queue_free()
		return false
	
	connection_ok = true
	print("  ✓ Conexión TCP establecida")
	
	# Esperar jtg (character list)
	start_time = Time.get_ticks_msec()
	timeout_ms = 15000
	while (Time.get_ticks_msec() - start_time) < timeout_ms:
		if saw_jtg:
			print("  ✓ Mensaje jtg recibido")
			break
		await get_tree().create_timer(0.1).timeout
	
	if saw_jtg == false:
		_fail("Timeout sin recibir jtg")
		if game.is_tcp_connected():
			game.disconnect_tcp()
		game.queue_free()
		return false
	
	_steps_done.append("game_flow")
	
	if connection_ok:
		game.disconnect_tcp()
	game.queue_free()
	return true

func _fail(msg: String) -> void:
	_failed += 1
	printerr("[FAIL] %s" % msg)
	_steps_failed.append(msg)

func _wait_for_dict(dict_ref: Dictionary, timeout: float) -> bool:
	var elapsed = 0.0
	while elapsed < timeout:
		if not dict_ref.is_empty():
			return true
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	return dict_ref.size() > 0

func _finish() -> void:
	print("\n=== Resultados ===")
	print("Pasos completados: %s" % str(_steps_done))
	if _steps_failed.size() > 0:
		print("Pasos fallidos: %s" % str(_steps_failed))
	if _failed > 0:
		print("Total: OK - %d failure(s)" % _failed)
	else:
		print("Total: OK")
	get_tree().quit(1 if _failed > 0 else 0)