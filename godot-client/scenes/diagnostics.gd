# diagnostics.gd — Low-level HTTPClient test (no coroutine, no signal)
extends Node

const API_URL := "http://localhost:8888/api/entrar"
const USER := "keka"
const PASS := "test"

var _step := 0
var _client := HTTPClient.new()
var _body_data: PackedByteArray


func _ready() -> void:
	print("[DIAG] Starting...")
	_step = 1
	_connect()


func _process(_delta: float) -> void:
	match _step:
		1:
			pass # should not happen
		2:
			_client.poll()
			var state: int = _client.get_status()
			if state == HTTPClient.STATUS_CONNECTED:
				print("[DIAG] connected!")
				_step = 3
			elif state == HTTPClient.STATUS_CONNECTION_ERROR:
				printerr("[DIAG] connection error")
				_exit(1)
			else:
				print("[DIAG] status=%d" % state)
		3:
			var body := JSON.stringify({ "usuario": USER, "clave": PASS, "ip": "127.0.0.1" })
			var err: int = _client.perform_request(
				API_URL,
				["Content-Type: application/json"],
				HTTPClient.METHOD_POST,
				body,
			)
			print("[DIAG] perform_request err=%d" % err)
			_step = 4
		4:
			_client.poll()
			var state: int = _client.get_status()
			if state == HTTPClient.STATUS_BODY:
				_body_data = _client.read_response_body_chunks()
				print("[DIAG] body got %d bytes" % _body_data.size())
				_step = 5
			elif state == HTTPClient.STATUS_DISCONNECTED:
				_body_data = _client.read_response_body_chunks()
				print("[DIAG] disconnected with %d bytes" % _body_data.size())
				_step = 5
			else:
				print("[DIAG] request status=%d" % state)
		5:
			var text := _body_data.get_string_from_utf8()
			print("[DIAG] Response: %s" % text.substr(0, min(text.length(), 200)))
			_client.close()
			_client = null
			_exit(0)


func _connect() -> void:
	var err: int = _client.connect_to_host("localhost", 8888, TLSOptions.client())
	print("[DIAG] connect_to_host err=%d" % err)
	_step = 2


func _exit(code: int) -> void:
	if _client != null:
		_client.close()
		_client = null
	get_tree().quit(code)
