# GameMap.gd
# Data class representing a game map/area
# Maps the internal cell data structure to Godot-friendly format
class_name GameMap

# === CELL STATES ===
# Extra states a cell can have
# State 0: Normal (grass)
# State 1: Doppelganger
# State 2: Dopplemeuble
# State 3: Teleport (return)
# State 4: Teleport (random)
# State 5: Teleport (cell link)
# ... more states
# === Cell Data Structure ===
class_name CellData
extends Resource
extends Resource

# === ELEMENT TYPE (TERRAIN) ===
# These define what kind of ground/cell it is
enum ElementType {
	GRASS = 0,
	WATER = 1,
	WALL = 2,
	DOUBT = 3,
	METALLIC = 4,
	STONE = 5,
	SAND = 6,
	DIRT = 7,
}

# === MAP IDENTIFICATION ===
var map_id: int = 0 # Internal map ID
var map_name: String = "" # Display name
var sub_area_id: int = 0 # For subAreas in Dofus architecture
var version: int = 0 # Map version for hot-reload detection

# === POSITION & SCALE ===
var x_size: int = 0 # Map width in cells
var y_size: int = 0 # Map height in cells
var world_x: int = 0 # World coordinates
var world_y: int = 0

# === CELL DATA ===
var cells: Array = [] # 2D array of CellData [y][x]
var walkable: Array = [] # 2D boolean array of walkable cells
var background: int = 0 # Background element ID

# === ENTITIES ===
var positions: Array = [] # Entity positions at map level
var cells_content: Array = [] # Cell content data

# === SPAWN POINTS ===
var spawns: Array = [] # NPC spawn points
var points: Array = [] # Interactive object positions
var start_positions: Array = [] # Player spawn points

# === MAP PROPERTIES ===
var has_bonus: bool = false # Has bonus zone
var has_seal: bool = false # Has seal protection
var has_key: bool = false # Has key requirement
var is_submarine: bool = false # Underwater map
var is_coloured: bool = false # Color filter applied

# === MOVEMENT RESTRICTIONS ===
var king_palace: bool = false # Has king palace restriction
var reverse_colours: bool = false # Reverse colour mode
var reverse_hunt: bool = false # Reverse hunt mode

var cell_id: int = 0 # Unique cell ID
var x: int = 0 # X coordinate
var y: int = 0 # Y coordinate
var element_type: int = 0 # ElementType enum
var states: Array = [] # Array of state IDs
var cells: Array # Array of sub-cell IDs (-1 if leaf)
var cells_content: Array # Content at this cell level
var cells_content_element_state: Array # Element states for content


# Create cell from map data tuple
static func create_cell(cell_data: Array) -> CellData:
	var cell = CellData.new()
	if cell_data.size() >= 8:
		cell.cell_id = cell_data[0]
		cell.x = cell_data[1]
		cell.y = cell_data[2]
		cell.element_type = cell_data[3] if cell_data[3] != null else 0
		cell.states = cell_data[4] if cell_data[4] != null else []
		cell.cells = cell_data[5] if cell_data[5] != null else []
		cell.cells_content = cell_data[6] if cell_data[6] != null else []
		cell.cells_content_element_state = cell_data[7] if cell_data[7] != null else []
	return cell


# Convert map data from protocol format
static func from_protocol_data(data: Dictionary) -> GameMap:
	var map = GameMap.new()
	map.map_id = data.get("mapId", 0)
	map.map_name = data.get("name", "")
	map.sub_area_id = data.get("subAreaId", 0)
	map.x_size = data.get("xSize", 0)
	map.y_size = data.get("ySize", 0)
	map.world_x = data.get("worldX", 0)
	map.world_y = data.get("worldY", 0)

	# Parse cells
	var raw_cells = data.get("cells", [])
	map.cells = []
	map.walkable = []

	for row in raw_cells:
		var cell_row = []
		var walkable_row = []
		for cell_data in row:
			cell_row.append(CellData.create_cell(cell_data))
			walkable_row.append(true) # Default to walkable
		map.cells.append(cell_row)
		map.walkable.append(walkable_row)

	return map


# Check if cell is walkable
func is_walkable(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= x_size or y >= y_size:
		return false
	if walkable.size() > y and walkable[y].size() > x:
		return walkable[y][x]
	return false


# Get cell at position
func get_cell(x: int, y: int) -> CellData:
	if y >= 0 and y < cells.size() and x >= 0 and x < cells[y].size():
		return cells[y][x]
	return null


# Check if cell is on doppler (special state)
func is_doppler(x: int, y: int) -> bool:
	var cell = get_cell(x, y)
	if cell and cell.states.size() > 1:
		return cell.states[1] == 3 # Dopple type
	return false


# Get cell content
func get_cell_content(x: int, y: int) -> Dictionary:
	var cell = get_cell(x, y)
	if cell and cell.cells_content.size() > 0:
		return cell.cells_content[0]
	return { }


# Convert map to scene instances for rendering
func create_visual_elements() -> Array:
	"""Creates VisualElement2D instances for each cell for rendering"""
	var elements = []
	for y in range(cells.size()):
		for cell_id in range(cells[y].size()):
			var cell = cells[y][cell_id]
			if cell:
				var element = preload("res://scenes/VisualElement2D.tscn").instantiate()
				element.position = Vector2(cell.x, cell.y)
				element.cell_id = cell.cell_id
				element.z_index = get_z_index_for_element(cell)
				elements.append(element)
	return elements


# Get z-index for rendering order
func get_z_index_for_element(cell: CellData) -> int:
	"""Calculate proper z-index based on element type and positions"""
	if cell.element_type == ElementType.WALL:
		return -10 # Walls render behind
	elif cell.element_type == ElementType.WATER:
		return 10 # Water renders on top
	return 0


# Get spawn points for players
func get_spawn_points() -> Array:
	"""Return list of valid spawn points for new players"""
	var spawns = []
	for cell in cells:
		if cell.states.has(8): # Spawn point state
			spawns.append(Vector2(cell.x, cell.y))
	if spawns.empty():
		# Default to center of map
		spawns.append(Vector2(x_size / 2, y_size / 2))
	return spawns


# Get interactive objects
func get_interactive_objects() -> Array:
	"""Get positions of doors, NPCs, and other interactables"""
	var objects = []
	for row in cells:
		for cell in row:
			if cell and cell.cells_content.size() > 0:
				for content in cell.cells_content:
					if typeof(content) == TYPE_DICTIONARY:
						objects.append(
							{
								"position": Vector2(cell.x, cell.y),
								"id": content.get("id", 0),
								"type": content.get("typeId", 0),
							}
						)
	return objects
