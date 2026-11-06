class_name LauncherUI
# @class LauncherUI
# Interfaz de inicio de sesión
# Maneja la pantalla de bienvenido y autenticación
extends Control

# La señal cambió: ahora recibe usuario/contraseña, no token.
# Token obtenido de /api/entrar, guardado como variable de instancias para pasarlo a la señal.
var _auth_token: String = ""

signal auth_requested(
	token: String,
	lang: String,
	install_id: String,
	host: String,
	port: int,
)

# Lista de idiomas disponibles para el OptionButton
const LANGUAGES: Array = [
	["Español", "es"],
	["English", "en"],
	["Français", "fr"],
	["Deutsch", "de"],
]

# Idioma seleccionado por defecto (índice en LANGUAGES)
const DEFAULT_LANG_INDEX: int = 0

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var version_label: Label = $VBoxContainer/VersionLabel
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ConnectionProgress
@onready var connect_button: Button = $VBoxContainer/ConnectButton
@onready var lang_label: Label = $VBoxContainer/LangLabel
@onready var lang_option: OptionButton = $VBoxContainer/LangOption
@onready var username_entry: LineEdit = $VBoxContainer/UsernameEntry
@onready var password_entry: LineEdit = $VBoxContainer/PasswordEntry
@onready var server_host_label: Label = $VBoxContainer/ServerConfig/ServerHostLabel
@onready var server_host_entry: LineEdit = $VBoxContainer/ServerConfig/ServerHostEntry
@onready var server_port_label: Label = $VBoxContainer/ServerConfig/ServerPortLabel
@onready var server_port_spin: SpinBox = $VBoxContainer/ServerConfig/ServerPortSpin


func _ready() -> void:
	print("[LauncherUI] Preparando UI")
	# DEBUG: mostrar qué nodos existen en la escena
	print("[LauncherUI] Hijos de Launcher:")
	for child in get_children():
		print("[LauncherUI]   - %s (%s)" % [child.name, child.get_class()])
		if child.name == "VBoxContainer":
			for sub in child.get_children():
				print("[LauncherUI]     - %s (%s)" % [sub.name, sub.get_class()])
	print("[LauncherUI] HTTPRequest encontrado: %s" % (get_node_or_null("HTTPRequest") != null))
	_populate_languages()
	_setup_defaults()
	_connect_signals()


## Añade los idiomas al OptionButton ANTES de seleccionar.
func _populate_languages() -> void:
	if lang_option == null:
		return
	for item in LANGUAGES:
		lang_option.add_item(item[0])
	# select(0) es seguro porque ahora hay items.
	lang_option.select(DEFAULT_LANG_INDEX)


func _setup_defaults() -> void:
	# Servidor por defecto
	if server_host_entry != null:
		server_host_entry.text = "127.0.0.1"
	if server_port_spin != null:
		server_port_spin.value = 5557

	# Estado inicial
	if status_label != null:
		status_label.text = "Listo para conectar"
	if connect_button != null:
		connect_button.disabled = false
	if progress_bar != null:
		progress_bar.visible = false


func _connect_signals() -> void:
	if connect_button != null:
		connect_button.pressed.connect(_on_connect_pressed)
	if get_node_or_null("HTTPRequest") != null:
		var http: HTTPRequest = get_node("HTTPRequest") as HTTPRequest
		if http != null:
			http.request_completed.connect(_on_http_request_completed)


func _set_busy(busy: bool, status_message: String = "Conectando...") -> void:
	connect_button.disabled = busy
	if progress_bar != null:
		progress_bar.visible = busy
	if status_label != null:
		status_label.text = status_message
		print("[LauncherUI] Estado: %s" % status_message)


func _on_connect_pressed() -> void:
	if username_entry == null or password_entry == null:
		return

	var user: String = username_entry.text.strip_edges()
	var password: String = password_entry.text.strip_edges()
	var host: String = server_host_entry.text.strip_edges()
	var port: int = int(server_port_spin.value) if server_port_spin != null else 5557
	var lang_code: String = "es"
	if lang_option != null and lang_option.get_item_count() > 0:
		lang_code = LANGUAGES[lang_option.selected][1]

	if user.is_empty() or password.is_empty():
		_set_busy(false, "Usuario y contraseña requeridos")
		return

	_set_busy(true, "Autenticando...")

	# Construir la URL del endpoint de login
	var url := "http://%s:8888/api/entrar" % host
	var body := JSON.stringify({ "usuario": user, "clave": password, "ip": "127.0.0.1" })

	var http := get_node_or_null("HTTPRequest") as HTTPRequest
	print("[LauncherUI] HTTPRequest encontrado: %s" % (http != null))
	print("[LauncherUI] Hijos directos de Launcher:")
	for child in get_children():
		print("[LauncherUI]   - %s (%s)" % [child.name, child.get_class()])
	if http == null:
		_set_busy(false, "Error: HTTPRequest no encontrado en la escena")
		return

	# request() usa METHOD_POST = 1
	var err: Error = http.request(
		url,
		["Content-Type: application/json"],

		HTTPClient.METHOD_POST,

		body,
	)
	if err != OK:
		_set_busy(false, "Error al iniciar petición: %d" % err)


## Se dispara cuando el servidor responde a /api/entrar.
func _on_http_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
) -> void:
	_set_busy(false)

	if result != HTTPRequest.RESULT_SUCCESS:
		status_label.text = "Error de red"
		print("[LauncherUI] Estado: %s" % status_label.text)
		return

	if response_code != 200:
		status_label.text = "Error del servidor: %d" % response_code
		print("[LauncherUI] Estado: %s" % status_label.text)
		return

	var json_raw: String = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_result = json.parse(json_raw)
	if parse_result != Error.OK:
		status_label.text = "Respuesta inválida del servidor"
		print("[LauncherUI] Estado: %s" % status_label.text)
		return
	
	var resp: Dictionary = json.get_data() as Dictionary

	if not (resp as Dictionary).get("bien", false):
		var motivo: String = (resp as Dictionary).get("motivo", "Error desconocido") as String
		status_label.text = "Fallo de autenticación: %s" % motivo
		print("[LauncherUI] Estado: %s" % status_label.text)
		return

	# Respuesta exitosa: extraer campos
	var token: String = (resp as Dictionary).get("token", "") as String
	var account_id: int = (resp as Dictionary).get("cuenta", 0) as int
	var apodo: String = (resp as Dictionary).get("apodo", "") as String
	var rol: int = (resp as Dictionary).get("rol", 0) as int

	if token.is_empty():
		status_label.text = "El servidor no devolvió token"
		print("[LauncherUI] Estado: %s" % status_label.text)
		return

	# Guardar token para pasarlo a la señal
	_auth_token = token

	status_label.text = "Autenticado como %s (cuenta %d)" % [apodo, account_id]
	print("[LauncherUI] Estado: %s" % status_label.text)
	print("[LauncherUI] Token obtenido: %s..." % _auth_token.substr(0, 8))
	print("[LauncherUI] Enviando auth_requested...")

	var install_id: String = OS.get_unique_id()
	emit_signal(
		"auth_requested",
		_auth_token,
		_lang_code(),
		install_id,
		server_host_entry.text.strip_edges(),
		int(server_port_spin.value) if server_port_spin != null else 5557,
	)
	print("[LauncherUI] auth_requested emitido")


## Devuelve el código de idioma seleccionado como String.
func _lang_code() -> String:
	if lang_option == null or lang_option.get_item_count() == 0:
		return "es"
	var idx: int = lang_option.selected
	if idx < LANGUAGES.size():
		return LANGUAGES[idx][1]
	return "es"