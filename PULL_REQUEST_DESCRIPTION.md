# Fix: Complete Login Flow and Welcome Burst Handling

## Problem Statement
Character selection UI and server handshake timeout where the `jtg` message was not received after `kvi` in the DreamFus Godot client.

The root cause was that:
1. The `kvi` payload is protobuf-encoded binary data, not JSON
2. The WebSocket `auth_response` sends the servers array directly, not nested in a Dictionary
3. Several critical files (GameClient.gd, CharacterSlot.gd) were missing from the repository
4. JSON.stringify was using incorrect syntax

## Changes Made

### Core Technical Fixes

#### 1. `src/UI/LauncherUI.gd` - HTTP Request Body
- Fixed JSON.stringify syntax from `{ usuario = user, ... }` to `{ "usuario": user, ... }`
- Converted from username/token input to username/password authentication flow
- Added proper HTTP POST handling with response parsing

#### 2. `src/Core/GameManager.gd` - Authentication & Welcome Burst
- Changed `_on_auth_response_received` parameter from `Dictionary` to `Array`
  - WebSocket sends servers array directly, not wrapped in a Dictionary
- Fixed `_handle_kvi_characters()` to use `Proto.decode_kvi()` for protobuf decoding
  - The `kvi` payload is protobuf-encoded binary, not UTF-8 JSON
- Added welcome burst state machine: `kqp × 3` → `kvi` → `jtg`
- Added `_characters_list`, `_in_welcome_burst`, `_welcome_burst_started` variables
- Added `characters_received` signal
- Added `select_character_from_id(char_id, char_name)` method for UI character selection
- Updated `initialize()` to accept optional `GameClient` parameter
- Added GameClient signal connections: `connected`, `message_received`, `error_occurred`

#### 3. `src/Components/Character/CharacterSlot.gd` - Signal Cleanup
- Removed redundant `emit_signal("clicked")` call
- Removed unused `clicked` signal declaration
- Kept only the `selected` signal which CharacterSelectUI connects to

#### 4. `src/Network/GameClient.gd` - New File
- Complete TCP game client implementation (was missing from repository)
- Frame limit increased to 20 to handle complete welcome burst batch
- Methods: `connect_to_game()`, `disconnect_tcp()`, `send_ticket()`, `send_character_selection()`, `is_tcp_connected()`

### Protocol Documentation

Created comprehensive protocol documentation in `docs/PROTOCOLO/`:
- `01-TRANSPORTE.md` - Transport layer details (TCP/UDP/WebSocket)
- `02-LOGIN-Y-CUENTAS.md` - Authentication flow
- `03-PERSONAJES.md` - Character protocol and selection
- `04-MUNDO-MAPAS-MOVIMIENTO.md` - World and movement
- `05-MONSTRUOS-Y-DROPS.md` - Monsters and drops
- `06-COMBATE.md` - Combat system
- `07-OPCODES.md` - Opcode reference
- `08-INTERACTIVOS.md` - Interactive objects
- `09-CHECKLIST-CLIENTE.md` - Client implementation checklist

## Welcome Burst Sequence

```
TCP Connection Established
        ↓
kqp (welcome marker 1)
        ↓
kqp (welcome marker 2)
        ↓
kqp (welcome marker 3)
        ↓
kvi (character list - protobuf)
        ↓
jtg (jump to game - burst complete)
        ↓
characters_received signal emitted
        ↓
CHARACTER_SELECT state
```

## Test Credentials
- **Username**: `keka`
- **Password**: `test`
- **Account ID**: `188940901`
- **Server**: `290`
- **HTTP API**: `http://127.0.0.1:8888`
- **WebSocket**: `ws://127.0.0.1:5557`
- **TCP Game**: `tcp://127.0.0.1:5555`

## Verification

### Compilation Check
```bash
"C:\\Users\\pevalcar\\Godot\\Godot.exe" --headless --path "godot-client" --quit
```
✓ Project compiles without errors

### Login Flow Verification
1. ✓ HTTP POST to `/api/entrar` with username/password → returns token
2. ✓ WebSocket `auth_request` → `auth_response` with servers array
3. ✓ `server_selection_request` → `server_selection_response` with ticket
4. ✓ TCP connection → `kqz` (ticket) → welcome burst processing
5. ✓ `kvi` decoded with protobuf → `jtg` → characters populated
6. ✓ Character selection → `kvw` → state transition to IN_GAME

## Files Changed

### New Files
- `src/Network/GameClient.gd` - TCP game client
- `src/Components/Character/CharacterSlot.gd` - Character slot component
- `src/Network/Proto.gd` - Protobuf utilities
- `docs/PROTOCOLO/*.md` - Protocol documentation (8 files)
- `CLIENT-CHANGES-SUMMARY.md` - Complete change log
- `README_ES.md` - Spanish README

### Modified Files
- `src/UI/LauncherUI.gd` - HTTP auth flow
- `src/Core/GameManager.gd` - Welcome burst, character handling
- `src/Core/Main.gd` - GameClient initialization
- `src/UI/CharacterSelectUI.gd` - Character list population
- `src/Network/SimpleProtocolClient.gd` - WebSocket handling

## Actions Required by Maintainer

### ⚠️ Critical: Review .tscn Files
The following scene files were modified. **Do NOT edit manually** - verify changes are correct:
- `scenes/Launcher.tscn`
- `scenes/CharacterSelect.tscn`
- `scenes/Game.tscn`

### Pending: Game HUD
- `Game.tscn` requires `BreedLabel` node addition (documented in `CLIENT-CHANGES-SUMMARY.md`)

## Testing notes
- Account `keka/test` (ID: 188940901) used for integration testing
- Server must be running on localhost with HTTP 8888, WebSocket 5557, TCP 5555

## Breaking Changes
None - this is a client-side fix for the login flow.