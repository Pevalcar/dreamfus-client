# Debug: Why Connect Button Does Nothing

## Problem
User enters credentials but nothing happens when clicking Connect. Server receives no requests.

## Root Cause (Hypothesis)
The `_on_connect_pressed()` function returns early at line 128-130 because `user.is_empty()` or `password.is_empty()` is true, even though the user sees text in the fields.

## What to Look For in Godot Console

When you click Connect, check the Godot console output for these debug messages:

### Expected Debug Output:
```
[LauncherUI] user.text='keka' password.text='test' host='127.0.0.1'
[LauncherUI] user.is_empty()=false password.is_empty()=false
```
or
```
[LauncherUI] user.text='' password.text='' host='127.0.0.1'
[LauncherUI] user.is_empty()=true password.is_empty()=true
```

### If you see:
- `user.text='keka' password.text='test'` → The text IS there, but `is_empty()` might be buggy in Godot 4.8 beta2
- `user.text='' password.text=''` → The fields are actually empty (might be a focus issue)
- No debug messages at all → The function might not be called (signal connection issue)

## Possible Fixes

### Fix 1: Bypass the is_empty() check
Change lines 128-130 to always proceed:
```gdscript
# if user.is_empty() or password.is_empty():
#     _set_busy(false, "Usuario y contraseña requeridos")
#     return
# Proceed anyway (will fail at HTTP with clearer error)
```

### Fix 2: Check text length instead
```gdscript
if user.length() == 0 or password.length() == 0:
    _set_busy(false, "Usuario y contraseña requeridos")
    return
```

### Fix 3: Print and force non-empty
```gdscript
if user.is_empty():
    # Try to get text directly from the LineEdit
    if username_entry != null:
        user = username_entry.text  # Don't strip_edges
```

### Fix 4: Check if fields have focus
Ensure the LineEdit fields have focus before reading text.

## How to Test
1. Run Godot
2. Enter `keka` in Username, `test` in Password
3. Click Connect
4. Check Godot console for the debug messages above
5. Report back what you see