# Fix for jss 64KB TCP Limitation (Godot Client)

## Problem
Godot 4.8's `StreamPeerTCP.get_available_bytes()` has a hard limit of 64KB per read operation. When the server sends a MapActorsListMessage (jss) larger than 64KB, Godot can only read the first 64KB, and the remaining data stays in the OS socket buffer but is not accessible through Godot's API.

**Error:**
```
[GameClient] Buffer insuficiente: need 101962, have 65536
```

## Root Cause
The server sends ALL players currently on the map in the `f5[rep]` array. Each player adds ~500-1000+ bytes, causing jss to exceed 64KB.

**Expected result:**
- Map 88212759, spawn cell: 352 (verified in world.db Characters table)
- jss size target: < 64KB

## Solution: Filter Other Players in BuildMapActors()

### Location
File: `jondo-servidor/Jondo.Unity.Server/Network/ConnectionProtocol.cs`

### Code Change

Find the `BuildMapActors()` method and modify it to only include the local player:

```csharp
// BEFORE (problematic):
foreach (var actor in allActors)
{
    jss.Actors.Add(actor);
}

// AFTER (fixed):
// ONLY include the local player who triggered the map send
// This ensures jss stays under 64KB for Godot client
var localPlayer = actors.FirstOrDefault(a => a.IsLocalPlayer || a.AccountId == localAccountId);
if (localPlayer != null)
{
    jss.Actors.Add(localPlayer);
}
// Do NOT include other online players on the same map
```

### Alternative: Check if player is the session's character

If there's no `IsLocalPlayer` flag, use the character ID from the session:

```csharp
// Get the character ID from the current session
int characterId = session.CharacterId;  // or however you track the selected character

// Only add the local player's actor to f5[0]
foreach (var actor in actors.Where(a => a.CharacterId == characterId))
{
    jss.Actors.Add(actor);
}
```

## Verification Steps

1. Deploy the fix to your server
2. Start the server and ensure it builds without errors
3. Run the E2E test:
   ```bash
   cd C:\Users\pevalcar\Proyectos\DofusClient\godot-client
   "C:\Program Files\Godot\v4.8.beta2.mono\GodotEditor.exe" --headless --path . --scene "res://test/test_world_entry_e2e.tscn" --quit
   ```
4. Expected output:
   ```
   [PASS] jss received, spawn cell=352
   [PASS] spawn cell verified from jss, not hardcoded 0
   [PASS] TCP still connected after the world entry blocks
   Result: OK
   ```

## Why This Matters

Without this fix:
- The jss message arrives truncated at 64KB
- The protobuf parsing fails
- The spawn cell cannot be extracted
- The client appears to work but doesn't know where to place the character

## Technical Details

**jss structure:**
```
f2 {                  // mapId
    f6: subarea_id,   // subarea
    f5 (repetido) {   // actor individual - THIS IS THE PROBLEM
        f1: cell,     // celda ocupada
        f2: facing,   // dirección
        f7: tipo_actor, // 1 = jugador, 4 = monstruo, 7 = NPC
    }
    f11: interactivos,   // elementos interactivos
    f12: peleas,           // celdas de lucha
}
```

**Each additional player adds:**
- ~500-1000 bytes to the payload
- With 2-3 other players, jss exceeds 64KB
- Godot cannot read the full message

## Related Files (Client-Side)
- `docs/TCP_64KB_LIMITATION.md` - Full analysis of the issue
- `godot-client/src/Network/GameClient.gd` - Límite detectado en `_drain_buffer()`
- `godot-client/src/Network/WorldProto.gd` - Decodificador jss
- `godot-client/test/test_world_entry_e2e.gd` - Test E2E con verificación del spawn cell (352)