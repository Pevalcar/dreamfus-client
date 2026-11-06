# ItemData.gd
# Data class representing an item in the game
# Mirrors the AlterationData (ba) and ly data structures found in the DreamFus client

class_name ItemData
extends Resource

# === IDENTIFICATION ===
var item_id: int = 0              # Unique item ID
var object_id: int = 0              # Object type ID
var uid: int = 0                    # Unique identifier (from mmd())

# === POSITION DATA ===
var position: Vector2 = Vector2.ZERO   # Grid position (x, y) in inventory
var position_type: int = 0            # PositionType enum value

# === ITEM PROPERTIES ===
var name: String = ""               # Item name (from ckh())
var description: String = ""        # Item description
var level: int = 0                   # Required level
var weight: int = 0                  # Item weight
var quantity: int = 1              # Stack size

# === DURABILITY ===
var max_durability: int = 0        # Maximum durability
var current_durability: int = 0    # Current durability (-1 = indestructible)

# === RARITY & TYPE ===
var rarity: Rarity = Rarity.COMMON
var item_type: int = 0             # Item type enum
var effect: Dictionary = {}       # Effects (stats, spells, etc.)

# === VISUAL ===
var icon_id: int = 0               # Figma icon ID (from fguv())
var image: Texture2D = null        # Cached texture
var glow_color: Color = Color(1, 1, 1, 1)  # Rarity-based glow

# === EQUIPMENT DATA ===
var equipment_slot: String = ""    # Where item can be equipped
var position_in_outfit: Vector2 = Vector2.ZERO  # Visual offset

# === STAT Bonuses ===
var stat_bonuses: Dictionary = {
    "strength": 0,
    "agility": 0,
    "intelligence": 0,
    "vitality": 0,
    "wisdom": 0,
    "initiative": 0,
    "endurance": 0
}

# === Rarity enum ===
enum Rarity {
    COMMON = 0,
    UNCOMMON = 1,
    RARE = 2,
    EPIC = 3,
    LEGENDARY = 4,
    UNIQUE = 5,
    ARTIFACT = 6
}

# === PositionType enum ===
enum PositionType {
    BASIC_CONTENTS = 0,
    CRAFT_CONTENTS = 1,
    CONSUMABLES = 2,
    STORAGE = 3,
    QUICK_SLOTS = 4
}

# Create from raw item data (as received from protocol)
static func from_raw_data(data: Dictionary) -> ItemData:
    var item = ItemData.new()
    item.item_id = data.get("item_id", 0)
    item.object_id = data.get("object_id", 0)
    item.uid = data.get("uid", 0)
    item.position = data.get("position", Vector2.ZERO)
    item.position_type = data.get("position_type", 0)
    item.name = data.get("name", "")
    item.description = data.get("description", "")
    item.level = data.get("level", 1)
    item.quantity = data.get("quantity", 1)
    item.rarity = data.get("rarity", Rarity.COMMON)
    item.item_type = data.get("item_type", 0)
    item.icon_id = data.get("icon_id", 0)
    return item

# Get unique item ID (wrapper for mmd() method if available via API)
func get_unique_id() -> int:
    """Returns the unique item identifier (mmd in C# API)"""
    return uid

# Get item name (wrapper for ckh() method if available via API)
func get_name() -> String:
    """Returns the item name (ckh in C# API)"""
    return name

# Get icon reference (wrapper for fguv() method if available via API)
func get_icon_id() -> int:
    """Returns the Figma icon ID (fguv in C# API)"""
    return icon_id

# Check if this is a special/unique item
func is_unique() -> bool:
    """Check if item is unique based on ID lists or properties"""
    # TODO: Populate with actual unique item IDs from gameplay
    var unique_ids = [
        # Example: 12345, 67890, 111111
        # These should be discovered through gameplay/testing
    ]
    return unique_ids.has(item_id) or unique_ids.has(uid)

# Get total stat bonuses from item
func get_total_stat_bonus() -> Dictionary:
    """Returns combined stat bonuses from all effects"""
    var total = {}
    for stat in stat_bonuses:
        total[stat] = stat_bonuses[stat]
    
    # Add effects
    for effect_key in effect:
        if effect_key.begins_with("stat."):
            var stat_name = effect_key.substr(5)
            total[stat_name] = total.get(stat_name, 0) + effect[effect_key]
    
    return total

# Update texture from external assets
func update_texture(catalog: AssetCatalog) -> void:
    """Load item texture using AssetCatalog"""
    if catalog:
        image = catalog.load_item_icon(icon_id)

# Check if item can be stacked
func can_stack() -> bool:
    """Returns true if item can exist in stack"""
    if quantity <= 1:
        return true
    # Consumables, materials, potions can stack
    return item_type in [0, 1, 2, 3, 4]  # Common stackable types

# Merge two items of same type
func merge_with(other: ItemData) -> int:
    """Merge other item into this one. Returns remaining quantity."""
    if item_id != other.item_id:
        return other.quantity
    
    var available_space = 999 - quantity  # Max stack size
    if available_space <= 0:
        return other.quantity
    
    var to_merge = min(available_space, other.quantity)
    quantity += to_merge
    other.quantity -= to_merge
    
    return other.quantity

# Durability methods
func has_durability() -> bool:
    return max_durability > 0

func is_broken() -> bool:
    return has_durability() and current_durability <= 0

func damage(amount: int) -> void:
    if has_durability() and not is_broken():
        current_durability = max(0, current_durability - amount)

func repair(amount: int) -> void:
    if has_durability():
        current_durability = min(max_durability, current_durability + amount)