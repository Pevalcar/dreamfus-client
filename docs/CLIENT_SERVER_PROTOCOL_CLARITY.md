# Protocol Clarity: Client vs Server Responsibilities

**Objective**: Define exactly what the Godot client must do vs. what the server must do. The server bugs belong to the server team; the client bugs belong to the client team.

---

## 🎯 Fundamental Rule

### **The client MUST be robust to server behavior.**
The server can:
- Send data correctly
- Send data slowly
- Send data incorrectly (bugs in server)
- Delay messages intentionally

**The client MUST handle ALL of these gracefully.**

### **The server DOES NOT need to break to fix bugs.**
If the server has bugs (like the kqz parsing issues), that's a server fix. The client should:
- Detect protocol errors
- Warn the user
- Retry differently
- NOT freeze forever

---

## 📋 Authentication Flow Responsibilities

### ✅ Server MUST provide:
1. WebSocket endpoint `ws://127.0.0.1:5557` with auth flow
2. `/api/obtener-ticket` endpoint returning valid ticket
3. Server selection response with ticket for TCP
4. Character list (kvi) in welcome burst
5. Map block (jru) via timeout or lqc detection
6. Server state and other game data

### ✅ Client MUST implement:
1. WebSocket client connecting to port 5557
2. HTTP client calling `/api/obtener-ticket`
3. Parse server list from WebSocket auth response
4. Send server selection to request ticket
5. Cache ticket securely
6. Connect to TCP game server (port 5555) within 500ms of server response

### 🔄 Both MUST agree on:
- kqz message format (server expects: `{ f2: { f1: type_url, f2: payload } }`)
- TCP framing (VarInt length prefix)
- Message ordering in burst (kvi first, jru second)

---

## 🚨 Critical Timing & Timeout Responsibilities

### ⚠️ CLIENT BUG: Missing 15s timeout for map block

**Problem**: Client waits indefinitely for jru message. If server delays due to bug or load, client freezes.

**Server CAN**: Send jru immediately, or delay it intentionally (Godot clients never send lqc).

**Client MUST**: Wait at most 15s before timing out.

**Client Code to ADD** (`GameManager.gd`):
```gdscript
var _map_block_received: bool = false
var _map_block_timeout: Timer

func create_map_block_timeout() -> void:
    """Create a timer that will trigger if map block is not received."""
    _map_block_timeout = Timer.new()
    _map_block_timeout.wait_time = 15.0
    _map_block_timeout.one_shot = true
    _map_block_timeout.auto_start = true
    _map_block_timeout.connect("timeout", _on_map_block_timeout)
    add_child(_map_block_timeout)

func _on_map_block_timeout() -> void:
    """Callback when map block timeout expires."""
    if not _map_block_received:
        printerr("[GameManager] ERROR: Map block (jru) not received after 15s!")
        printerr("Possible reasons:")
        printerr("  1. Server delay processing")
        printerr("  2. Server bug - not sending jru")
        printerr("  3. Network issue")
        # Disconnect safely
        if game_client and game_client.is_tcp_connected():
            game_client.disconnect()
        # Notify user
        error_received.emit("MAP_TIMEOUT", "Map block not received. Server may be unresponsive.")

func start_map_block_timer() -> void:
    """Start waiting for map block. Call this when ticket is sent."""
    _map_block_received = false
    _map_block_timeout = null
    create_map_block_timeout()

func on_map_block_received(map_id: int) -> void:
    """Callback when map block (jru) is received. Stop the timer."""
    _map_block_received = true
    if _map_block_timeout:
        _map_block_timeout.stop()
        _map_block_timeout.queue_free()
        _map_block_timeout = null
```

**When to call**:
- `start_map_block_timer()` called in `GameManager.select_character_from_id()` after sending kvw
- `on_map_block_received(map_id)` called in `GameManager.handle_tcp_message()` when opcode is "jru"

---

## 🔍 Server Bug Detection (Client Responsibility)

### ⚠️ Server Bug: kqz parsing issue in `ConnectionProtocol.ReadPayload()`

**Server Problem**: The server's `ReadPayload` method (line 3128) is looking for the wrong offset after finding the type_url string marker. This causes the server to not properly parse Godot's kqz messages.

**What this means for Godot client**:
- Server responds with INVALID or EXPIRED ticket error
- Client gets disconnected
- Client CANNOT handle this gracefully without server fix

**Client SHOULD do** (if protocol is correct):
- Detect invalid ticket via error codes
- Log detailed error
- Provide clear message to user ("Server rejected authentication")
- Suggest checking server logs or contacting admin

**Client CANNOT** (without server fix):
- Guess the correct format effectively (too much guesswork)
- Wait longer hoping server changes mind (ticket expires)

**Who fixes it?** ⭐⭐⭐**SERVER TEAM** down in `jondo-servidor` project.

**Client SHOULD send**: Make kqz message very clear with logging (already done in `GameClient.gd:416` hex_dump).

---

## 📊 Ping/Timeout Suite (Client Responsibilities)

The client should implement a complete suite of timeouts to handle different server behaviors:

| Timeout | Purpose | When to start | Duration | What to do on timeout |
|---------|---------|---------------|----------|----------------------|
| **Ticket validation** | Confirm server accepts ticket | After TCP connection | 5s | Log error, log hex ticket, disconnect |
| **Character list** | Confirm kvi received | After kqz sent | 5s | Log error, log remaining data |
| **Map block (jru)** | Confirm map loaded | After character selected | **15s** | **FREEZE PREVENTION** - disconnect safely |
| **Server heartbeat** | Keep detection alive | Every 30s | 10s | Reconnect if no in-game activity |

**Client MUST implement** all of these to be production-ready.

---

## 🎨 UI Responsiveness Responsibilities

### When server is slow or buggy, client UI should:
1. **Show loading spinner** when waiting for critical messages
2. **Show warning text** ("Server is taking longer than expected")
3. **Provide retry button** ("Retry connection")
4. **Allow user to cancel** ("Abort")
5. **Display detailed error** with log information for debugging

**Client SHOULD NOT**:
- Freez cyan screen entirely
- Never give user any feedback
- Exit silently without explanation

---

## 📝 Protocol Clarity Checklist

### Client Implementation Checklist (Project: DofusClient/godot-client)

- [ ] WebSocket client (port 5557)
- [ ] HTTP client for ticket (port 8888)
- [ ] TCP client (port 5555)
- [ ] kqz message construction (field 2 only, no language)
- [ ] VarInt framing for all TCP messages
- [ ] jru timeout timer (15 seconds) ⭐⭐⭐ CRITICAL
- [ ] kvi timeout timer (5 seconds)
- [ ] Connection timeout (5 seconds)
- [ ] UI feedback for all timeouts
- [ ] Error logging with detailed context
- [ ] Graceful disconnection on timeout
- [ ] No lqc/kqo messages (Godot-optimized)

### Server Implementation Checklist (Project: jondo-servidor)

- [ ] WebSocket auth on port 5557
- [ ] `/api/obtener-ticket` endpoint
- [ ] kqz ticket parsing logic
- [ ] Session Registry for ticket redemption
- [ ] Server selection with ticket response
- [ ] Character list (kvi) in welcome burst
- [ ] Map block (jru) delivery (with 5s timeout for Godot)
- [ ] Map block claim mechanism (prevent duplicates)
- [ ] Correct TypeURL parsing in ReadPayload
- [ ] Connection holding after server response

---

## 🔒 Security Boundaries

### What SHOULD be exposed to client:
- Ticket (after validation)
- Server info
- Character list
- Map data
- Game state

### What client SHOULD NOT manipulate:
- Server selection (must use server response)
- Authentication tokens (must use server-provided tickets)
- Core game logic (must send via protocol, not modify server state directly)

### What client MUST report to user:
1. Connection status (connected/disconnected)
2. Error messages (IF the server provides good error messages)
3. Timeout information
4. Latency issues (if any)

---

## 📊 Resolution Matrix

| Problem | Where to fix? | How client handles it? | How server fixes it? |
|---------|---------------|------------------------|---------------------|
| **Map not arriving** | ⭐⭐⭐ CLIENT BUG | 15s timeout → disconnect safely + retry button | Send jru within 5s of kvz |
| **Invalid ticket format** | ⭐⭐⭐ SERVER BUG | Log detailed context, alert user, disconnect | Fix kqz parsing in ReadPayload |
| **Server smashed / unresponsive** | SERVER ISSUE | Timeout → show error, allow retry | Restart server |
| **Network slowdown** | NETWORK ISSUE | Higher timeouts (15s) | N/A |
| **Client freeze waiting for jru** | ⭐⭐⭐ CLIENT BUG | 15s timeout + UI feedback | Send jru on time |

**Key Insight**: The "Map not arriving" problem could be a server bug OR a client bug. The resolution requires BOTH:
- Client: 15s timeout prevents freeze
- Server: Send jru within expected time

---

## 🎯 Action Items

### Immediate (Must fix client TLs):
1. ⭐⭐⭐ Add 15s timeout for map block in `GameManager.gd`
2. Add UI feedback when timeout occurs
3. Add retry button for disconnection timeouts

### Short-term (Nice to have client):
1. Add kvi timeout (5s)
2. Add connection timeout (5s)
3. Add ping/heartbeat to detect dead connections

### Server Team (NOT your current task):
1. Fix kqz parsing bug in `ConnectionProtocol.cs`
2. Verify timeout-based jru delivery works
3. Test with imaginary Godot client that doesn't send lqc

---

## 📞 Communication Guidelines

### When reporting issues:

**For CLIENT bugs** (like missing timeout):
- "Client freezes when server delays map block"
- Screenshot of UI freeze
- Server logs (does jru actually send?)
- Protocol capture (hex dump of kqz)

**For SERVER bugs** (like kqz parsing):
- "Server rejects perfectly good kqz message"
- Hex dump of kqz sent (verified correct)
- Server log of parsing error (exact line in Trace)
- Protocol reference from documentation

**For NETWORK issues**:
- Server system load (CPU, memory)
- Network latency measurement
- Packet loss and reordering

---

## ✅ Summary

### **Client Project (DofusClient):**
- Fix the client bugs: MISSING 15s timeout, missing UI feedback
- Document requirements clearly: "Server MUST send jru within X, Client MUST wait YY"
- Implement robust timeouts and error handling

### **Server Project (jondo-servidor):**
- Fix the server bugs: kqz parsing, jru delivery timing
- Verify protocol compliance with Godot client
- Improve error messages

### **Both teams MUST communicate via:**
- Shared documentation (like this file)
- Protocol captures for analysis
- Clear issue categories (client bug vs server bug)

---

**Last Updated**: 2026-11-10
**Status**: Protocol clarity document created to separate responsibilities
**Next Step**: Implement 15s timeout in client to prevent freeze