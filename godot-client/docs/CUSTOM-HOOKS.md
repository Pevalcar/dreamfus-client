# Custom Hooks Reference

## Overview
This document tracks custom hooks implemented in the Godot client to extend the server protocol.

## Block 1 Message Handlers

### OnBlock1StatsReceived
**Location:** GameClient.gd
**Trigger:** When kub (player stats) is decoded from opcode 546
**Purpose:** Notify systems that player stats are available after character selection
**Signal:** `stats_received(stats: Dictionary)`

### OnBlock1JobsReceived
**Location:** GameClient.gd
**Trigger:** When irq (jobs/professions) is decoded from opcode 547
**Purpose:** Notify systems that player jobs are available
**Signal:** `jobs_received(jobs: Array)`

### OnBlock1SpellsReceived
**Location:** GameClient.gd
**Trigger:** When hms (spell list) is decoded from opcode 571
**Purpose:** Notify systems that player spells are available
**Signal:** `spells_received(spells: Array)`

### OnBlock1InventoryReceived
**Location:** GameClient.gd
**Trigger:** When ivx (inventory) is decoded from opcode 572
**Purpose:** Notify systems that player inventory is available
**Signal:** `inventory_received(kamas: int, items: Array)`

### OnBlock1ShortcutBarReceived
**Location:** GameClient.gd
**Trigger:** When itg (shortcut bar) is decoded from opcode 612
**Purpose:** Notify systems that shortcut bar is available
**Signal:** `spell_bar_received(bar_type: int, shortcuts: Array)`

### OnBlock1Complete
**Location:** GameClient.gd
**Trigger:** When all Block 1 messages have been received
**Purpose:** Mark character as fully loaded and ready for gameplay
**State Variable:** `block1_received: bool`

## Implementation File Locations

| Handler | File | Function |
|---------|------|----------|
| kub | WorldProto.gd | `decode_kub()` |
| irq | WorldProto.gd | `decode_irq()` |
| hms | WorldProto.gd | `decode_hms()` |
| ivx | WorldProto.gd | `decode_ivx()` |
| itg | WorldProto.gd | `decode_itg()` |
| GameClient | GameClient.gd | `handle_message()` dispatcher |
| GameManager | GameManager.gd | State storage and processing |

## State Management

### kvw_allowed Flag
- Set to `true` by `set_kvw_allowed(true)` after jtg receipt
- Set to `false` after kvw message is processed
- Never re-enabled - one-time character info request

### block1_received Flag
- Set to `true` when kub stats are received (as a proxy for any Block 1 message)
- Used to determine if character is ready for gameplay

## Usage Example

```gdscript
# In a UI node
func _ready():
    var game_client = get_node("/root/GameClient")
    game_client.connect("stats_received", Callable(self, "_on_stats_received"))
    game_client.connect("inventory_received", Callable(self, "_on_inventory_received"))

func _on_stats_received(stats):
    update_ui_stats(stats)

func _on_inventory_received(kamas, items):
    update_ui_inventory(kamas, items)
```