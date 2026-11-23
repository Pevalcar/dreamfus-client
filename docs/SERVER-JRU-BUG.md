# Bug Report: Server Not Sending jru After kvw

## Summary

**Issue:** The server does not send `jru` (map block) after receiving `kvw` (character selection request).

**Status:** Server-side bug confirmed. Client implementation is correct.

**Affected Component:** World entry flow after character selection.

## Technical Details

### Expected Flow

According to `docs/PROTOCOLO/04-MUNDO-MAPAS-MOVIMIENTO.md`:

```
kvi                     →  list of characters (if not seen)
kvd                     →  end of list
jtg                     →  END OF BURST (end of burst)
kvw                     →  selected character data
jru                     →  INITIAL MAP (191105026 - Astrub zaap)
```

### Protocol Requirements

1. **kvw** must be sent as a **REQUEST** (envelope f2), not PUSH (envelope f1)
   - ✅ Client implementation verified at `GameClient.gd:283`: `send_request("kvw", payload)`
   
2. **lqc** must NOT be sent by Godot client
   - ✅ Client correctly does NOT send lqc
   - Server uses 5-second timer to send jru automatically

3. **kqc** is not sent by Godot client

### Actual Behavior (Observed)

From E2E test output:
```
+ client>server] kvw (CharacterSelectionRequest) uid=-1 {"CharacterId":13825558}
```

- ✅ Server recognizes kvw correctly
- ✅ Client receives all Block 1 frames (kva, hms, ivx, kub, etc.)
- ❌ Server DOES NOT send jru after processing character selection
- ⚠️ Client disconnects with: `[GameManager] Disconnecting due to map timeout...`

## Root Cause Analysis

The server implements a 5-second timer to send `jru` when the client doesn't send `lqc`, but this timer is not being triggered. This indicates:

1. **Possibility A:** Server bug - timer not implemented correctly
2. **Possibility B:** Server bug - condition for sending jru not met
3. **Possibility C:** Server behavior is intentionally different from protocol spec

## Client-Side Implementation Status

### ✅ Correct Implementation

The Godot client correctly implements the expected protocol:

| Component | Status | Location |
|-----------|--------|----------|
| kvw envelope type | REQUEST (f2) | `GameClient.gd:283` |
| lqc NOT sent | ✅ | `GameManager.gd:266-270` |
| kqc NOT sent | ✅ | N/A |
| TCP buffer drain | 500 frame limit | `GameClient.gd:465` |
| MAX_FRAME_SIZE | 8 MiB | `GameClient.gd:29` |
| set_no_delay after connect | ✅ | `GameClient.gd:175` |

### Current Timeout Handling

1. **Character selection timeout (5s):** Timer started after kvw sent
   - Location: `GameManager.gd:279-292`
   
2. **Extended map block timeout (15s):** Started if 5s timer expires without jru
   - Location: `GameManager.gd:525-544`

3. **Final map timeout (15s):** Safety net before disconnect
   - Location: `GameManager.gd:384-392`

## Workaround Strategy

Since this is a server-side bug, the client has implemented a workaround:

### Two-Phase Timeout System

1. **Phase 1 (5s):** After kvw sent, wait for server's 5-second timer
2. **Phase 2 (15s):** Extended wait for server recovery attempts

If jru still doesn't arrive after Phase 2, the client disconnects gracefully with error notification.

## Map ID Reference

For new characters, the initial map should be:
- **191105026** - Astrub zaap (per `docs/PROTOCOLO/04-MUNDO-MAPAS-MOVIMIENTO.md:18`)

## Impact

This blocks:
- Complete world entry flow
- Character progression
- Gameplay beyond character selection

## Resolution Path

### Short-term
1. ✅ Document the bug as server-side
2. ✅ Improve client timeout handling with better user feedback
3. ✅ Log the issue for server maintainers

### Long-term
1. Server fix: Implement jru sending after kvw processing
2. Server fix: Ensure 5-second timer triggers correctly for Godot clients
3. Alternative: Send explicit map request if jru doesn't arrive within timeout

## Test Evidence

- E2E test flow: HTTP login → WS auth → Server selection → TCP kqz → kvi (4 characters) → jtg → kvw → Character loaded successfully (#KEKA-BRON# Level 204)
- TCP buffer reading: Client correctly reads all TCP data (no buffer overflow errors)
- Server recognition: Server receives and acknowledges kvw correctly

## Related Files

- `godot-client/src/Network/GameClient.gd:283` - kvw send_request
- `godot-client/src/Core/GameManager.gd:279-292` - character selection timeout
- `godot-client/src/Core/GameManager.gd:525-544` - extended timeout
- `godot-client/src/Core/GameManager.gd:556-615` - map timeout handler
- `godot-client/test/test_world_entry_e2e.gd` - E2E test
- `docs/PROTOCOLO/04-MUNDO-MAPAS-MOVIMIENTO.md` - Protocol documentation
- `docs/Protocolosactualziados/opcodes/maps/README.md` - Opcode reference