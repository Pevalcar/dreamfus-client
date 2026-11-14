# MapData.gd
# Godot Resource holding the cell data for one Dofus map.
# Generated from server-side JSON (see tools/alea_to_godot.py) and
# exported as .tres files under assets/maps/<bucket>/<id>.tres.
class_name MapData
extends Resource

@export var map_id: int = 0
@export var map_coordinades: Vector2i = Vector2i.ZERO

# World metadata — populated from world.db during export.
@export var sub_area_id: int = 0          # minimap zone / level
@export var is_outdoor: bool = true       # false = dungeon/casa/interior
@export var name_id: int = 0              # string key in strings.tsv
@export var map_flags: int = 0            # ArenaFlags, RaidArenaFlags, etc.
@export var tactical_mode_id: int = 0     # combat tactic template
@export var world_map_offset: Vector2i = Vector2i.ZERO  # world-map widget offset

# Cell topology (primary render data).
@export var walkable_cells: PackedInt32Array = []
@export var fight_cells: PackedInt32Array = []
@export var blocked_cells: PackedInt32Array = []
@export var neighbors: Dictionary = { }   # {"top": id, "bottom": id, ...}

# Entity data — filled at export time, consumed by future systems.
@export var npc_ids: PackedInt32Array = []
@export var mob_groups_json: PackedStringArray = []  # raw JSON strings per spawn group
@export var teleports: Array = []         # InteractiveTeleport entries

# Reserved slots for content not yet rendered.
@export var background_layer: int = 0
@export var decor_objects: Array = []
