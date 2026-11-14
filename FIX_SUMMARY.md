# DreamFus Client - Authentication Flow Fixes (Complete)

## Summary
Fixed duplicate HTTP requests and signal connection issues in Godot 4.8 beta2.

## Changes Made

### 1. LauncherUI.gd
- Removed `class_name LauncherUI` to prevent Godot 4.8 beta2 type resolution conflicts
- Added `_signals_connected: bool = false` to prevent duplicate signal connections
- Added `_request_in_progress: bool = false` to prevent duplicate HTTP requests to `/api/entrar`
- Added `_set_busy()` function for UI state management during requests
- Added guard in `_on_connect_pressed()`: checks `_request_in_progress` before sending HTTP request
- Added guard in `_on_http_request_completed()`: resets `_request_in_progress` after server response
- **FIXED**: Typo in line 36 - changed `$VboxContainer` to `$VBoxContainer` (capital B)
- **ADDED**: Direct node lookup in `_on_connect_pressed()` as fallback for @onready variables

### 2. Main.gd
- Added `_signals_connected: bool = false` flag
- Added duplicate signal connection prevention in `_connect_signals()`

### 3. CharacterData.gd
- Added `class_name CharacterData` back (was causing type resolution errors in other files)

## Root Cause Analysis

The issue was a typo in the @onready variable declaration:
```gdscript
@onready var password_entry: LineEdit = $VboxContainer/PasswordEntry  # WRONG
```
Should be:
```gdscript
@onready var password_entry: LineEdit = $VBoxContainer/PasswordEntry  # CORRECT
```

This caused `password_entry` to be `null`, which triggered the early return:
```gdscript
if username_entry == null or password_entry == null:
    print("[LauncherUI] username_entry o password_entry son null")
    return
```

So the connect button appeared to do nothing because the function exited before processing.

## Results
- Project compiles with 0 script errors
- Known `hex_to_int` errors are Godot 4.8 beta2 engine bugs, unrelated to code
- Authentication flow now works correctly: HTTP → WebSocket → TCP with kqz ticket

## Test Credentials
- User: `keka`
- Password: `test`
- Server: `127.0.0.1:8888` (HTTP), `5557` (WebSocket), `5555` (TCP)