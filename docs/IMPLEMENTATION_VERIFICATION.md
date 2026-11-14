# Verification Checklist: Godot Client Documentation vs Implementation

**Date**: 2026-11-10
**Documentation Version**: Updated per new server protocol
**Server Version**: 3.6.10.10

---

## ✅ Documented Requirements vs Implementation Status

### 1. WebSocket Flow

| Requirement | Implementation | Status | Notes |
|-------------|----------------|--------|-------|
| Connect to port 5557 | ✓ present in SimpleProtocolClient.gd | ✅ PASS | Handles auth, server list, server selection |
| Send auth request | ✓ present in WS client | ✅ PASS | Structured message sent |
| Receive server list | ✓ present in WS client | ✅ PASS | ServerChanged event |
| Receive server selection response | ✓ present in WS client | ✅ PASS | ServerChanged event with ticket |
| Convert ticket to kqz message | ✓ present in GameClient.gd::send_ticket() | ✅ PASS | Proper protobuf construction |

### 2. TCP Game Connection

| Requirement | Implementation | Status | Notes |
|-------------|----------------|--------|-------|
| Connect to port 5555 | ✓ GameClient.gd::connect_to_game() | ✅ PASS |
| Send kqz message | ✓ GameClient.gd::send_ticket() | ✅ PASS | Protobuf encoding verified |
| Ticket in field 2 only (no language) | ✓ GameClient.gd:351-406 | ✅ PASS | Language field omitted |
| VarInt framing | ✓ Proto.write_varint() | ✅ PASS | Proper varint encoding |
| Receive character list (kvi) | ✓ WorldProto.decode_kvi() | ✅ PASS | Parses character data |
| Receive map block (jru) | ✓ WorldProto.decode_jru() | ✅ PASS | Extracts mapId |

### 3. Map Block Delivery Logic

| Requirement | Implementation | Status | Risk |
|-------------|----------------|--------|------|
| **NO lqc sent** | ✅ No send_lqc() found | ✅ PASS | ✓ Correct - no lqc |
| **NO kqo sent** | ✅ No send_kqo() found | ✅ PASS | ✓ Correct - no kqo |
| **Wait for jru after 5s** | ⚠️ *Missing timeout timer* | ⚠️ WARNING | Client only reacts, doesn't wait |
| **15s max timeout for map** | ❌ Not implemented | ⚠️ WARNING | Could freeze UI indefinitely |

### 4. Server-Side Detection

| Requirement | Implementation | Server Side Status |
|-------------|----------------|-------------------|
| Session marking as Godot | ⚠️ *GodotClientEntry not in repo* | ⚠️ TODO | Needs server-side |
| Hook events (SessionBound, WorldEntered) | ⚠️ *Not defined in game client* | ⚠️ TODO | Needs server-side |
| Map block claim mechanism | ⚠️ *Not mirrored in client* | ⚠️ TODO | Needs server-side |

---

## 📋 Missing Implementations (Risk Analysis)

### **HIGH PRIORITY: Map Block Timeout**

**Location**: `GameManager.gd` or `Main.gd`

**Current Behavior**: Client waits indefinitely for jru

**Problem**: If server delays map block beyond 5s, client freezes with no indication

**Recommended Fix**:
```gdscript
# Add to GameManager.gd
var _map_block_received: bool = false
var _map_block_timeout: Timer = null

func create_map_block_timeout() -> void:
    _map_block_timeout = Timer.new()
    _map_block_timeout.wait_time = 15.0  # generous timeout
    _map_block_timeout.one_shot = true
    _map_block_timeout.auto_start = true
    _map_block_timeout.connect("timeout", _on_map_block_timeout)
    add_child(_map_block_timeout)

func _on_map_block_timeout() -> void:
    if not _map_block_received:
        print("[GameManager] Map block timeout after 15s, reconnecting...")
        _disconnect_safe()
        error_received.emit("MAP_TIMEOUT", "Map block not received")

func on_map_block_received(map_id) -> void:
    _map_block_received = true
    if _map_block_timeout:
        _map_block_timeout.stop()
        _map_block_timeout.queue_free()
```

**Integration**: Call `create_map_block_timeout()` in `handle_server_selection()`
Call `on_map_block_received()` in `_handle_kvi_messages()` when jru received

---

### **MEDIUM PRIORITY: Server-Side Marking**

**Location**: Server files (not in current Godot client repo)

**Current Behavior**: No indication to server that client is Godot

**Problem**: Server may treat all clients as standard, causing different behavior

**Needed Files** (in `jondo-servidor/`):
1. `Custom/Godot/GodotClientEntry.cs` - Mark sessions as Godot
2. `GameSession.IsGodotClient` property
3. `CustomHooks`, `SessionBound`, `WorldEntered` implementation

**Estimate**: ~200 lines of C# code

---

### **LOW PRIORITY: Request ID Generation**

**Location**: `GameClient.gd`

**Current Behavior**: Messages sent without request ID

**Problem**: Server cannot track request/response correlation

**Recommended Fix**:
```gdscript
class_name GameClient:
    var _request_id_counter: int = 0

    func send_kqz_message(ticket: String) -> void:
        # ... existing code ...
        var request_id = _request_id_counter
        _request_id_counter += 1
        # ... send with request_id in message ...
```

**Note**: Optional for Godot client, finite timeouts make correlation unnecessary

---

## 🔍 Verification Steps

### Unit Tests

```go
# (N/A - Godot client)
```

### Integration Tests

```bash
# Test the complete flow manually
1. Start jondo-server (handled separately)
2. Start Godot client with --headless --quit
3. Monitor stdout for：
   - [GameClient] Connecting TCP with ticket=
   - [GameClient] kqz hex: ... (matches server expectation)
   - [GameManager] kvi messages received
   - [GameManager] ignoring opcode TCP: <some> (never sees lqc/kqo)
4. Check if evertyon works in ~5-15s
```

### Expected Output

```
[DofusClient] Documentation Verification Report
=============================================
✓ WebSocket flow: COMPLETE
✓ kqz construction: COMPLETE
✓ kvi parsing: COMPLETE
✓ jru parsing: COMPLETE
⚠️  Map timeout: MISSING (will freeze if server delays)
⚠️  Server marking: MISSING (client not marked as Godot)
✓ No lqc/kqo spams: COMPLETE
✓ VarInt framing: COMPLETE
```

---

## 📊 Risk Summary

| Risk | Severity | Probability | Mitigation |
|------|----------|-------------|------------|
| Infinite wait for map block | **HIGH** | **HIGH** (server win condition) | Add 15s timeout |
| UI never updates | **HIGH** | **MED** (depends on timeout) | Show "loading..." status |
| Server throws error | **MEDIUM** | **LOW** (if kqz correct) | Server bug already known |
| Token/Server mismatch | **MEDIUM** | **LOW** (validation present) | Validate server ID |
| Session not marked as Godot | **LOW** | **MEDIUM** | Implement hook |

---

## 🎯 Next Steps

### Immediate (Fix freeze bug)
1. Add 15s timeout to GameManager
2. Test with server delay
3. Verify no infinite loop

### Short-term (Add robustness)
1. Implement request ID generation
2. Add specific opcode handlers (jru, jss)
3. Improve error messages

### Long-term (Complete protocol)
1. Factory server-side Godot marking
2. Implement custom hooks bidirectional
3. Profiling for performance

---

## ✅ Conclusion

The Godot client implementation is **nearly complete and correct** for standard operation, with one **critical missing piece**: 15s timeout for map block delivery.

Once the timeout is added, the client will:
- ✅ Handle complete auth flow
- ✅ Parse all necessary messages
- ✅ NOT send lqc/kqo (Godot-optimized)
- ⚠️ Will freeze indefinitely if server fails to send jru

**Recommendation**: Add the timeout **immediately** before production use.

---

*Generated after verifying implementation against `docs/GODOT_CLIENT_PROTOCOL.md`*