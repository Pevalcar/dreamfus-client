# JSS Buffer Limitation Issue - Godot 4.8

## Problem Summary

Godot 4.8 has an internal limitation of 64KB for TCP socket reads via `get_available_bytes()` and `get_data()`. When the server sends a MapActorsListMessage (jss) larger than 64KB, Godot can only read the first 64KB, and the remaining data stays in the OS socket buffer but is not accessible through Godot's API.

### Error Example
```
[GameClient] Buffer insuficiente: need 101962, have 65536
```

This means:
- Full jss frame: 101,962 bytes (~99.5 KB)
- Godot could read: 65,536 bytes (64 KB)
- Missing: 36,426 bytes

## jss Structure

According to `docs/PROTOCOLO/04-MUNDO-MAPAS-MOVIMIENTO.md`, the jss has this structure:

```
jss: f2 {                  // mapId
    f6: subarea_id,        // subárea
    f5 (repeated) {        // actor individual - PROBLEMATIC IF LARGE
        f1: cell,            // celda ocupada
        f2: facing,          // dirección
        f3: contextual_id,   // ID contextual (jugador/NPC/monstruo)
        f7: tipo_actor,    // 1 = jugador, 4 = monstruo, 7 = NPC
        ... other fields ...
    }
    f11: interactivos,     // IDs de elementos
    f12: peleas,           // IDs de celdas de lucha
}
```

## Root Cause

The most likely cause of the oversized jss is that `f5` contains **multiple players** (other players on the map). Each player adds data to the `f5[rep]` array.

## Server-Side Solutions

### Solution 1: Reduce jss Size by Filtering Other Players (Recommended)

In the server's `BuildMapActors()` method:

```csharp
// Instead of including all players from SessionRegistry.OnMap()
// Only include the local player who triggered the map send
foreach (var actor in allActors)
{
    if (actor.IsLocalPlayer && actor.MapId == mapId)
    {
        // Only add the local player to jss
        jss.Actors.Add(actor);
    }
    // Skip other players
}
```

### Solution 2: Fragment jss into Multiple Messages

If the jss must contain other players, fragment it:

```csharp
// Send jss in chunks
const int MAX_JSS_SIZE = 60000; // Leave margin for safety

if (jss.TotalSize > MAX_JSS_SIZE)
{
    // Split into multiple messages
    // jss_part1, jss_part2, etc.
    // Each under 64KB
}
```

### Solution 3: Reduce Data Per Player

Remove non-essential fields from each PlayerActor:

```csharp
// Before: PlayerActor with many fields
// After: PlayerActor with only essential fields: f1(cell), f2(facing), f7(tipo_actor=1)
```

## Client-Side Workaround

The client already implements:
- Reading up to 64KB per `get_data()` call
- Buffer accumulation until complete frame
- Timeout handling for world entry blocks

If the jss exceeds 64KB, the connection will stall waiting for the complete frame that can never arrive through Godot's API.

## Verification Steps

1. Check if there are other players on map 88212759:
   - Query the session registry
   - Check `SessionRegistry.OnMap()` in `BuildMapActors()`

2. Verify jss size in server logs:
   - Log the serialized jss size before sending
   - Compare with expected size after NPC/mob removal

3. Test with empty map (no other players):
   - Should result in jss < 10KB
   - Confirms the issue is other players in f5

## Expected Behavior

After server fix:
- jss size should be < 64KB
- GameClient should receive complete jss in one read
- Spawn cell extraction should work correctly
- Test `test_world_entry_e2e.gd` should pass

## Diagnosis: Other Players in Map

After server-side optimizations (commenting out NPCs, mobs, tax collectors, prism, house, and interactive elements), the jss is still ~102KB. This confirms the root cause is **other players currently on the map** in the `f5[rep]` array.

### Why This Happens

The server sends ALL players currently on the map in `SessionRegistry.OnMap()`:
- Each player adds ~500-1000+ bytes to the `f5` array
- With 2-3 other players, jss can easily exceed 64KB
- The local player (keka) expects the spawn cell in `f5[0].f1.f1`

### Required Server Fix

**Option A (Recommended)**: Filter players in `BuildMapActors()`:

```csharp
// In ConnectionProtocol.cs / BuildMapActors()
// ONLY include the local player who triggered the map send
foreach (var actor in allActors.Where(a => a.IsLocalPlayer))
{
    jss.Actors.Add(actor);
}
```

**Option B**: Limit jss size per player

**Option C**: Fragment jss into multiple messages (`jss_1`, `jss_2`, etc.)

### Verification

Map 88212759 spawn cell is **352** (verified in world.db Characters table).

If server fixes jss size < 64KB, the client will correctly receive and parse it.

### Immediat solution (recommended)

**The server must filter other players from jss.** This is the only viable short-term solution.

1. Modify `BuildMapActors()` in `ConnectionProtocol.cs`:
   - Only include the local player in `f5[0]`
   - Do NOT include other players on the same map

2. Verify jss final size is < 64KB

3. Run E2E test which should pass completely

**Alternative solutions (not recommended):**
- Fragment jss into multiple messages (high complexity)
- Increase Godot limit (not possible from client)
- Use HTTP API to get spawn cell (requires server changes)

## Files to Check

- `godot-client/src/Network/GameClient.gd` - TCP reading logic
- `godot-client/src/Network/WorldProto.gd` - jss parsing
- `godot-client/test/test_world_entry_e2e.gd` - E2E test for spawn cell
- `docs/PROTOCOLO/04-MUNDO-MAPAS-MOVIMIENTO.md` - jss format reference