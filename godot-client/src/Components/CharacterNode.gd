# CharacterNode.gd
# Player avatar placed on the isometric tilemap. Handles WASD/arrow movement
# with smooth tweening between cells and seamless neighbour-map transitions.
class_name CharacterNode
extends Node2D

const COLS := 14
const COL_W := 32   # half-tile width in pixels
const ROW_H := 16   # half-tile height in pixels
const MOVE_DURATION := 0.15  # seconds per cell

@export var breed_id: int = 1       # Dofus breed ID (1-16)
@export var look_string: String = ""

var _current_map_manager: MapManager = null
var _cell_col: int = 0
var _cell_row: int = 0
var _is_moving: bool = false
var _pending_direction: String = ""  # "top"|"bottom"|"left"|"right"

# Breeds visual mapping — colour used by _draw().
const BREED_COLOURS := {
	1: Color(0.9, 0.2, 0.2),   # iop  - red
	2: Color(0.2, 0.8, 0.2),   # eniripsa - green
	3: Color(0.2, 0.2, 0.9),   # feca - blue
	4: Color(0.9, 0.6, 0.1),   # osamodas - gold
	5: Color(0.6, 0.6, 0.6),   # enutrof - grey
	6: Color(0.9, 0.9, 0.2),   # xelor - yellow
	7: Color(0.2, 0.9, 0.9),   # cra - cyan
	8: Color(0.9, 0.4, 0.6),   # sadida - pink
	9: Color(0.8, 0.4, 0.1),   # sacrier - orange
	10: Color(0.4, 0.8, 0.4),  # pandora - lime
}


func _unhandled_input(event: InputEvent) -> void:
	if _is_moving or get_parent() == null:
		return
	var dir: String = ""
	if event is InputEventKey:
		if not event.pressed:
			return
		match event.physical_keycode:
			KEY_W, KEY_UP:    dir = "top"
			KEY_S, KEY_DOWN:  dir = "bottom"
			KEY_A, KEY_LEFT:  dir = "left"
			KEY_D, KEY_RIGHT: dir = "right"
	if dir.is_empty():
		return
	_pending_direction = dir
	_try_move(dir)


func set_map_manager(mm: MapManager) -> void:
	"""Call after the map manager has been added as a parent sibling."""
	_current_map_manager = mm


func place_at(cell_id: int) -> void:
	"""Set initial position without animation."""
	_cell_col = cell_id % COLS
	_cell_row = cell_id / COLS
	_update_sprite_position()


func _try_move(direction: String) -> void:
	var data: MapData = _get_current_map_data()
	if data == null:
		return
	var col := _cell_col
	var row := _cell_row
	var target_col := col
	var target_row := row
	match direction:
		"top":    row -= 1
		"bottom": row += 1
		"left":   col -= 1
		"right":  col += 1

	# Boundary check within current map
	if col < 0 or col >= COLS or row < 0 or row >= 40:
		_cross_boundary(direction, data.neighbors)
		return

	var target_cell := row * COLS + col
	if not _is_walkable(data, target_cell):
		return

	_move_to_cell(target_col, target_row)


func _cross_boundary(direction: String, neighbors: Dictionary) -> void:
	var next_map_id: int = neighbors.get(direction, 0)
	if next_map_id == 0:
		print("[CharacterNode] No neighbor map for direction '%s'" % direction)
		return
	# Move sprite slightly past edge so it looks like it's exiting.
	_is_moving = true
	var exit_pos := _cell_to_pixel(_cell_col, _cell_row)
	var offset := Vector2.ONE * 8  # peek 8px into the void
	match direction:
		"top":    exit_pos.y -= 16
		"bottom": exit_pos.y += 16
		"left":   exit_pos.x -= 16
		"right":  exit_pos.x += 16
	_tween_to(exit_pos, 0.08, func() -> void:
		_load_and_enter_map(next_map_id, direction)
	)


func _load_and_enter_map(next_id: int, entering_from: String) -> void:
	if _current_map_manager == null:
		return
	_current_map_manager.load_neighbor(next_id)
	# Enter from the opposite side of where we crossed.
	var col := 0
	var row := 0
	match entering_from:
		"top":    row = 39  # entered from bottom
		"bottom": row = 0
		"left":   col = 13
		"right":  col = 0
	_cell_col = col
	_cell_row = row
	_update_sprite_position()
	_is_moving = false
	print("[CharacterNode] Entered map %d from %s at (%d,%d)" % [next_id, entering_from, col, row])


func _move_to_cell(col: int, row: int) -> void:
	_cell_col = col
	_cell_row = row
	var target := _cell_to_pixel(col, row)
	_tween_to(target, MOVE_DURATION, func() -> void:
		_is_moving = false
	)
	_is_moving = true


func _tween_to(pos: Vector2, duration: float, callback: Callable) -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if callback.is_valid():
		tween.tween_callback(callback)


func _cell_to_pixel(col: int, row: int) -> Vector2:
	return Vector2((col - row) * COL_W, (col + row) * ROW_H)


func _update_sprite_position() -> void:
	position = _cell_to_pixel(_cell_col, _cell_row)
	queue_redraw()
	_is_moving = false


func _is_walkable(data: MapData, cell_id: int) -> bool:
	return cell_id in data.walkable_cells


func _get_current_map_data() -> MapData:
	if _current_map_manager == null:
		return null
	# Try to get data from the active map's render state.
	# Shortcut: use the TileMapLayer's built-in method; fall back to caching.
	return _current_map_manager.get_current_data()


func _draw() -> void:
	# Draw a small circle representing the player.
	draw_circle(Vector2(0, 0), 10, BREED_COLOURS.get(breed_id, Color.RED))
