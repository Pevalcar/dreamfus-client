# DreamFus Godot Client - Architecture Documentation

## 📋 Overview

This document describes the architecture for the Godot client implementation of DreamFus/Dofus.

**Project Location:** `C:\Users\pevalcar\Proyectos\jondo-servidor\DofusClient\godot-client`

---

## 🗺️ MAP SYSTEM (World/Map)

### MapManager Architecture

```
GameMap (Resource) - src/Data/GameMap.gd
├── map_id: int                     # Internal map ID
├── map_name: String                 # Display name
├── x_size: int / y_size: int        # Map dimensions in cells
├── cells: Array[CellData]          # 2D array of map cells
├── walkable: Array[bool]           # Walkable grid
├── spawns: Array                   # NPC spawn points
└── positions: Array                # Interactive object positions

CellData (Resource) - Embedded in GameMap.gd
├── cell_id: int                    # Unique cell identifier from protocol
├── x: int / y: int                 # Grid coordinates
├── element_type: int               # GRASS, WATER, WALL, etc.
├── states: Array                   # Cell states (doppler, teleport, spawn)
├── cells: Array                    # Sub-cells for composite cells
└── cells_content: Array            # Content in this cell level
```

### Element Types Enum

```gdscript
enum ElementType {
    GRASS = 0,
    WATER = 1,
    WALL = 2,
    DOUBT = 3,
    METALLIC = 4,
    STONE = 5,
    SAND = 6,
    DIRT = 7
}
```

### Map Loading Flow

```
1. Connect to game server
2. Request map data via protocol
3. Receive Map Complement message
4. Deserialize cells from protocol
5. Create VisualElement instances for cells
6. Place players/NPCs at spawn points
7. Enable player input for movement
```

---

## 👤 CHARACTER SYSTEM

### CharacterData Resource Structure (src/Data/CharacterData.gd)

```gdscript
class_name CharacterData
extends Resource

# === IDENTIFICATION ===
var id: int = 0                   # Character ID
var name: String = ""            # Character name
var breed: int = 0               # 1-16 different breeds
var sex: int = 0                 # 0 = male, 1 = female

# === LEVEL & EXPERIENCE ===
var level: int = 1               # Current level
var experience: int = 0          # Current XP

# === STATISTICS ===
var stats: Dictionary = {
    "wear": 0,                  # Strength (Feca/Osamodas)
    "range": 0,                 # Agility (Sadida/Xelor/etc)
    "vision": 0,              # Intelligence (Enutrof/Iop/etc)
    "effur": 0,               # Vitality (Sacrieur/Rubbaduck/etc)
    "careful": 0,             # Wisdom
    "initiative": 0,
    "endurance": 0,
    "strength": 0,
    "stamina": 0,
    "intellect": 0,
    "agility": 0
}

# === APPEARANCE ===
var colors: Dictionary = {
    "skin": Color(1, 1, 1),
    "hair": Color(1, 1, 1),
    "eyebrows": Color(1, 1, 1),
    "lips": Color(1, 1, 1)
}

# === CLAN/GUILD ===
var guild_id: int = 0            # Guild membership
var guild_rank: int = 0          # Guild rank
var relationship: int = 0        # Alignment (Kali/Koutoulou)

# === INVENTORY ===
var bank_contents: Array = []    # Bank storage items
var basic_contents: Array = []   # Basic inventory slots
var craft_contents: Array = []   # Creation slots
var consumables: Array = []      # Consumable slots

# === MAP POSITION ===
var world_x: float = 0.0         # World coordinates
var world_y: float = 0.0
var current_map_id: int = 0      # Current map ID
```

### Breeds Reference

```gdscript
BREED_NAMES = {
    1: "Feca",
    2: "Osamodas",
    3: "Enutrof",
    4: "Sacrieur",
    5: "Sadida",
    6: "Xelor",
    7: "Chafouis",
    8: "Iop",
    9: "Cra",
    10: "Sram",
    11: "Ecaflip",
    12: "Ouginak",
    13: "Tymador",
    14: "Rubbaduck",
    15: "Steamer",
    16: "Eliotrope",
}
```

---

## 🎒 INVENTORY SYSTEM

### ItemData Resource Structure (src/Data/ItemData.gd)

```
ItemData (Resource)
├── item_id: int                    # Item type ID
├── uid: int                        # Unique item ID (mmd method)
├── position: Vector2               # Grid position (x, y)
├── position_type: int              # BASIC_CONTENTS, CRAFT_CONTENTS, etc.
├── name: String                   # Item name (ckh method)
├── description: String             # Item description
├── level: int                      # Required level
├── quantity: int                   # Stack count
├── rarity: Rarity                  # Enum: COMMON → ARTIFACT
├── item_type: int                  # Item type classification
├── icon_id: int                    # Figma icon ID (fguv method)
├── stat_bonuses: Dictionary       # Stat bonuses for equipped items
├── max_durability: int             # -1 if indestructible
└── current_durability: int         # Current wear
```

### Item Enums

```gdscript
enum Rarity {
    COMMON = 0,
    UNCOMMON = 1,
    RARE = 2,
    EPIC = 3,
    LEGENDARY = 4,
    UNIQUE = 5,
    ARTIFACT = 6
}

enum PositionType {
    BASIC_CONTENTS = 0,
    CRAFT_CONTENTS = 1,
    CONSUMABLES = 2,
    STORAGE = 3,
    QUICK_SLOTS = 4
}
```

### Item Data API Methods

Based on decompiled C# API analysis (`ly`/`ba` = AlterationData):

| C# Method | GDScript Equivalent | Returns |
|-----------|---------------------|---------|
| `mmd()` | `get_unique_id()` | UInt32 - unique item ID |
| `ckh()` | `get_name()` | String - item name |
| `fguv()` | `get_icon_id()` | Int32 - Figma icon enum |

---

## 🎭 EQUIPMENT & CHARACTER VISUALS

### Equipment Slots Configuration

```gdscript
# Equipment positions map to character body parts
EQUIPMENT_SLOTS = {
    "weapon1": { "position": Vector2(0, -12), "offset": Vector2(0, 0) },
    "weapon2": { "position": Vector2(0, -12), "offset": Vector2(0, 0) },
    "shield": { "position": Vector2(-10, -8), "offset": Vector2(0, 0) },
    "head": { "position": Vector2(0, -35), "offset": Vector2(0, -15) },   # Sombrero
    "body": { "position": Vector2(0, 5), "offset": Vector2(0, 0) },       # Manto
    "accessory1": { "position": Vector2(15, -5), "offset": Vector2(0, 0) },
    "accessory2": { "position": Vector2(-15, -5), "offset": Vector2(0, 0) },
}
```

### Character Visual Highlight System

```gdscript
# To make certain items shine/highlight when equipped:
func highlight_equipped_item(slot_type: String, item_id: int) -> void:
    if item_is_special(item_id):
        # Apply glow effect
        modulate = Color(1, 1, 1, 1)
        # Add emissive material or particle effect
        add_child(preload("res://effects/ItemHighlight.tscn").instantiate())

func item_is_special(item_id: int) -> bool:
    var special_items = [12345, 67890, 111111]  # TODO: Populate with actual IDs
    return special_items.has(item_id)
```

---

## 📡 PROTOCOL COMMUNICATION

### Network Architecture

```
GameClient
└── SimpleProtocolClient
    ├── connected: bool
    ├── host: String
    ├── port: int
    ├── sessionId: String
    └── listeners: Dictionary<opcode, Function>

Protocol Messages:
- 0x01: Identify Account
- 0x05: Map Complement (map data)
- 0x06: Map Data (players, NPCs, cells)
- 0x08: Object Add (item added to inventory)
- 0x09: Object Remove (item removed)
- 0x0B: Current Map (entering map)
- 0x0F: Skill Use (casting spells)
```

---

## 🖼️ RENDERING SYSTEM

### AssetCatalog (src/Core/AssetCatalog.gd)

```gdscript
# AssetCatalog handles loading assets from external Alea installation
var alea_install_path: String = ""
var default_assets_path: String = "res://assets/"

# Key methods:
load_texture(asset_name)        # Load texture with fallback
load_breed_emblem(breed: int)   # Load breed icon (10.png, 20.png...)
load_item_icon(icon_id)         # Load item from Figma icon ID
detect_alea_install()           # Auto-detect Alea client path
clear_cache()                   # Clear texture caches
```

### Tile/Item Rendering

Items use a tile-based rendering system with rarity-based backgrounds.

---

## 📦 CURRENT FILE STRUCTURE

```
godot-client/
├── docs/
│   └── MAP_INVENTORY_CHARACTER_ARCHITECTURE.md
├── src/
│   ├── Core/
│   │   ├── AssetCatalog.gd    # Asset loading system
│   │   └── GameManager.gd     # Game state management
│   └── Data/
│       ├── CharacterData.gd     # Character data structure
│       ├── GameMap.gd         # Map/cell data structures
│       └── ItemData.gd        # Item/alteration data structure
└── [other directories: assets/, scenes/, test/ empty]
```

---

## 🛠️ DEVELOPMENT GUIDE

### Adding Unique Item Highlighting

1. **Identify unique item IDs** from gameplay exploration
2. **Populate `unique_item_ids` HashSet** in SlotModifier.cs
3. **Apply CSS class** `custom-unique` to slot element
4. **Add visual effect** - glow, animation, or shader

### AssetCatalog Usage

```gdscript
# Detect Alea installation
var catalog = AssetCatalog.new()
catalog.detect_alea_install()

# Load item texture
var texture = catalog.load_item_icon(icon_id)

# Load breed emblem
var emblem = catalog.load_breed_emblem(breed_id)
```

---

## 📈 PERFORMANCE NOTES

### Virtual Scrolling

The inventory uses virtual scroll recycling for performance. Slots are reused when scrolling. For custom slot modifications, Harmony Postfix patches are required (see C# mod project).

### Asset Caching

- Textures are cached in `texture_cache` Dictionary
- External Alea assets loaded first, fallback to default
- Use `clear_cache()` when reloading assets

---

## 📞 DOCUMENTATION VERSION

**Version:** 1.1  
**Last Updated:** November 2026  
**Compatible with:** Godot 4.x, DreamFus 3.6.10  

*This documentation is auto-generated from source analysis of the Godot client implementation project.*