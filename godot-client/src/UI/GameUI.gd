# @class GameUI
# Interfaz del juego
# Muestra el HUD durante la partida

extends Control
class_name GameUI

signal back_to_select

@onready var character_label: Label = $HUDContainer/CharacterLabel
@onready var level_label: Label = $HUDContainer/LevelLabel
@onready var health_label: Label = $HUDContainer/HealthLabel
@onready var health_bar: ProgressBar = $HUDContainer/HealthBar
@onready var xp_bar: ProgressBar = $HUDContainer/XPBar
@onready var xp_label: Label = $HUDContainer/XPLabel
@onready var back_to_select_button: Button = $HUDContainer/BackToSelect


func _ready() -> void:
	print("[GameUI] Preparando UI")
	_connect_signals()
	_update_display()

func _connect_signals() -> void:
	if back_to_select_button != null:
		back_to_select_button.pressed.connect(_on_back_pressed)

func _update_display() -> void:
	if GameManager.instance == null:
		return

	var char := GameManager.instance.selected_character
	if char != null:
		if character_label != null:
			character_label.text = char.name
		if level_label != null:
			level_label.text = "Niv. %d" % char.level
		if health_label != null:
			health_label.text = "HP: 100/100"
		if health_bar != null:
			health_bar.value = 100
		if xp_label != null:
			xp_label.text = "XP: 0/100"
	else:
		if character_label != null:
			character_label.text = "Sin personaje"
		if level_label != null:
			level_label.text = "Niv. -"

func _on_back_pressed() -> void:
	print("[GameUI] Volver a selección")
	emit_signal("back_to_select")
