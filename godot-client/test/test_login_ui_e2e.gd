## test_login_ui_e2e.gd
## Drives the real client end to end: instantiates Main.tscn, fills the launcher and
## emits the connect button, then waits for the character screen to be populated.
##
##   godot --headless --path <project> res://test/test_login_ui_e2e.tscn
##
## This is the last mile the lower-level tests cannot see: GameManager.characters_received
## -> Main._on_characters_from_tcp -> CharacterSelectUI.receive_characters -> slots.

extends Node

const MAIN_SCENE = preload("res://scenes/Main.tscn")
const TARGET_CHARACTERS := 4

var _failed := 0


func _ready() -> void:
	_run()


func _run() -> void:
	print("=== E2E UI: connect button -> character list on screen ===")

	var main: Node = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame

	var launcher: Node = main.get_node("LauncherContainer").get_child(0)
	var user := launcher.get_node_or_null("VBoxContainer/UsernameEntry") as LineEdit
	var password := launcher.get_node_or_null("VBoxContainer/PasswordEntry") as LineEdit
	var button := launcher.get_node_or_null("VBoxContainer/ConnectButton") as Button
	if user == null or password == null or button == null:
		_fail("launcher inputs not found (UsernameEntry/PasswordEntry/ConnectButton)")
		return _finish()

	user.text = "keka"
	password.text = "test"
	button.pressed.emit()

	var select_container: Node = main.get_node("CharacterSelectContainer")
	var select_ui: Node = select_container.get_child(0)
	var list := select_ui.get_node_or_null(
		"VBoxContainer/HBoxContainer/ScrollContainer/CharacterList"
	)
	if list == null:
		_fail("CharacterList node not found in CharacterSelect scene")
		return _finish()

	if await _wait_until(func() -> bool: return list.get_child_count() >= TARGET_CHARACTERS, 25.0):
		print("[PASS] CharacterList populated: %d slots" % list.get_child_count())
	else:
		_fail(
			"CharacterList has %d slot(s) after 25s (expected %d)"
			% [list.get_child_count(), TARGET_CHARACTERS]
		)

	if select_container.visible:
		print("[PASS] character selection screen is visible")
	else:
		_fail("character selection screen never became visible")

	_finish()


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
