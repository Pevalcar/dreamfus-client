class_name LauncherUI
# @class LauncherUI
# Interfaz de inicio de sesión
# Maneja la pantalla de bienvenido y autenticación
# Flujo: usuario/contraseña -> HTTP POST /api/entrar -> token -> WebSocket auth_request
extends Control

signal auth_requested(lang: String, token: String, install_id: String, host: String, port: int)

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var version_label: Label = $VBoxContainer/VersionLabel
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var connect_button: Button = $VBoxContainer/ConnectButton
@onready var lang_label: Label = $VBoxContainer/LangLabel
@onready var lang_option: OptionButton = $VBoxContainer/LangOption
@onready var username_entry: LineEdit = $VBoxContainer/UsernameEntry
@onready var password_entry: LineEdit = $VBoxContainer/PasswordEntry
@onready var install_id_label: Label = $VBoxContainer/InstallIdLabel
@onready var server_host_label: Label = $VBoxContainer/ServerConfig/ServerHostLabel
@onready var server_host_entry: LineEdit = $VBoxContainer/ServerConfig/ServerHostEntry
@onready var server_port_label: Label = $VBoxContainer/ServerConfig/ServerPortLabel
@onready var server_port_spin: SpinBox = $VBoxContainer/ServerConfig/ServerPortSpin
@onready var http_request: HTTPRequest = $HTTPRequest

const LOGIN_URL: String = "http://127.0.0.1:8888/api/entrar"

var _install_id: String = ""

func _ready() -> void:
	print("[LauncherUI] Preparando UI")
	_setup_defaults()
	_connect_signals()


func _setup_defaults() -> void:
	# Idioma por defecto
	if lang_option != null:
		# Limpiar opciones previas
		lang_option.clear()
		lang_option.add_item("Español", 0)
		lang_option.add_item("English", 1)
		lang_option.add_item("Français", 2)
		lang_option.add_item("Deutsch", 3)
		lang_option.select(1)

	# Servidor por defecto
	if server_host_entry != null:
		server_host_entry.text = "127.0.0.1"
	if server_port_spin != null:
		server_port_spin.value = 5557

	# Install ID
	_install_id = OS.get_unique_id()
	if install_id_label != null:
		install_id_label.text = "Install ID: %s" % _install_id

	# Estado inicial
	if status_label != null:
		status_label.text = "Listo para conectar"
	if connect_button != null:
		connect_button.disabled = false


func _connect_signals() -> void:
	if connect_button != null:
		connect_button.pressed.connect(_on_connect_pressed)
	if http_request != null:
		http_request.request_completed.connect(_on_http_request_completed)


func _on_connect_pressed() -> void:
	if lang_option == null or username_entry == null or password_entry == null:
		return

	var username: String = username_entry.text.strip_edges()
	var password: String = password_entry.text.strip_edges()

	if username == "" or password == "":
		if status_label != null:
			status_label.text = "Usuario y contraseña requeridos"
		return

	if status_label != null:
		status_label.text = "Obteniendo token..."
	if connect_button != null:
		connect_button.disabled = true

	# Hacer HTTP request para obtener token
	var body: String = JSON.stringify({"usuario": username, "clave": password})
	var headers: PackedStringArray = ["Content-Type: application/json"]

	var err := http_request.request(LOGIN_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		if status_label != null:
			status_label.text = "Error HTTP: %d" % err
		if connect_button != null:
			connect_button.disabled = false


func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if status_label != null:
		status_label.text = "HTTP response: %d" % response_code

	if response_code != 200:
		if status_label != null:
			status_label.text = "Error del servidor (HTTP %d)" % response_code
		if connect_button != null:
			connect_button.disabled = false
		return

	var json_str: String = body.get_string_from_utf8()
	var json := JSON.new()
	var parse_result := json.parse(json_str)

	if parse_result != Error.OK:
		if status_label != null:
			status_label.text = "Error parseando respuesta"
		if connect_button != null:
			connect_button.disabled = false
		return

	var data: Variant = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		if status_label != null:
			status_label.text = "Respuesta inválida"
		if connect_button != null:
			connect_button.disabled = false
		return

	var bien: bool = data.get("bien", false)
	var token: String = data.get("token", "")
	var account_id: int = data.get("cuenta", 0)
	var apodo: String = data.get("apodo", "")

	if not bien or token == "":
		var error_msg: String = data.get("error", "Error de autenticación")
		if status_label != null:
			status_label.text = "Error: %s" % error_msg
		if connect_button != null:
			connect_button.disabled = false
		return

	# Token obtenido exitosamente
	print("[LauncherUI] Token obtenido para cuenta %d (%s)" % [account_id, apodo])
	if status_label != null:
		status_label.text = "Token obtenido, conectando..."

	# Enviar signal con el token para conectar WebSocket
	var lang: String = lang_option.get_item_text(lang_option.selected) if lang_option != null else "en"
	var host: String = server_host_entry.text if server_host_entry != null else "127.0.0.1"
	var port: int = int(server_port_spin.value) if server_port_spin != null else 5557

	emit_signal("auth_requested", lang, token, _install_id, host, port)