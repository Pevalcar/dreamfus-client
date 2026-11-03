class_name LauncherUI
# @class LauncherUI
# Interfaz de inicio de sesión
# Maneja la pantalla de bienvenido y autenticación
extends Control

signal auth_requested(lang: String, token: String, install_id: String, host: String, port: int)

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var version_label: Label = $VBoxContainer/VersionLabel
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var connect_button: Button = $VBoxContainer/ConnectButton
@onready var lang_label: Label = $VBoxContainer/LangLabel
@onready var lang_option: OptionButton = $VBoxContainer/LangOption
@onready var token_entry: LineEdit = $VBoxContainer/TokenEntry
@onready var install_id_label: Label = $VBoxContainer/InstallIdLabel
@onready var server_host_label: Label = $VBoxContainer/ServerConfig/ServerHostLabel
@onready var server_host_entry: LineEdit = $VBoxContainer/ServerConfig/ServerHostEntry
@onready var server_port_label: Label = $VBoxContainer/ServerConfig/ServerPortLabel
@onready var server_port_spin: SpinBox = $VBoxContainer/ServerConfig/ServerPortSpin


func _ready() -> void:
	print("[LauncherUI] Preparando UI")
	_setup_defaults()
	_connect_signals()


func _setup_defaults() -> void:
	# Idioma por defecto
	if lang_option != null:
		lang_option.select(1)

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


func _connect_signals() -> void:
	if connect_button != null:
		connect_button.pressed.connect(_on_connect_pressed)


func _on_connect_pressed() -> void:
	if lang_option == null or token_entry == null or server_host_entry == null or server_port_spin == null:
		return

	var lang: int = lang_option.selected
	var token: String = token_entry.text
	var install_id: String = OS.get_unique_id()
	var host: String = server_host_entry.text
	var port: int = int(server_port_spin.value)

	if token == "":
		if status_label != null:
			status_label.text = "Token requerido"
		return

	if status_label != null:
		status_label.text = "Conectando..."
	if connect_button != null:
		connect_button.disabled = true

	emit_signal("auth_requested", lang, token, install_id, host, port)
