# Godot Client Authentication Protocol

## 📋 Overview

The Godot client uses a different authentication flow than the standard Dofus client. This document describes the complete protocol, the hooks available on the server, and how the server handles the differences.

---

## 🔌 Connection Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         STANDARD Dofus Client                              │
└─────────────────────────────────────────────────────────────────────────────┘
┌─────────────────────┐                ┌─────────────────────┐
│  WebSocket (5557)   │──auth──────────▶│  TCP (5555) Game    │
│  Account Selection  │                  │  Connection         │
└─────────┬───────────┘                  └─────────────────────┘
          │                                     │
          ▼                                     ▼
  Server sends:                        Server sends:
  - Server list                        - Character list
  - Ticket for TCP                     - World entry blocks
                                        (Map block sent after 5s)

- Client sends: lqc (load complete confirmation) after first block
- Server waits for lqc before sending map block (jru)
- Client then sends kqo (heartbeat)

┌─────────────────────────────────────────────────────────────────────────────┐
│                          GODOT CLIENT                                       │
└─────────────────────────────────────────────────────────────────────────────┘
┌─────────────────────┐                ┌─────────────────────┐
│  WebSocket (5557)   │──auth──────────▶│  TCP (5555) Game    │
│  Account Selection  │                  │  Connection         │
└─────────┬───────────┘                  └─────────────────────┘
          │                                     │
          ▼                                     ▼
  Server sends:                        Server sends:
  - Server list                        - Character list
  - Ticket for TCP                     - World entry blocks
                                        - Map block (jru) after 5s

- Client does NOT send: lqc, kqo, lqc, or kqo
- Server sends map block (jru) via timeout timer (5 seconds)
- No load confirmation needed

```

---

## 🎯 Key Differences

### 1. **No lqc/kqo messages**

Standard Dofus clients send:
- `lqc` (load complete confirmation) after loading the first data block
- `kqo` (heartbeat) periodically during gameplay

Godot clients send **neither** `lqc` nor `kqo`, which causes the server to use a different mechanism for delivering the map block.

### 2. **Authentication Endpoint**

WebSocket authentication goes through `/api/obtener-ticket` on port 8888, which establishes session state (ticket) before the TCP game connection.

### 3. **Map Block Delivery Timing**

- **Standard Client**: Sends `lqc` → Server immediately sends map block
- **Godot Client**: Never sends `lqc` → Server waits 5 seconds then sends map block

---

## 🏛️ Server Architecture & Detection

### Custom Hooks System

The server uses a custom hooks system to distinguish Godot clients from standard Dofus clients.

#### GameSession Extensions

The `GameSession` class includes Godot-specific members:

```csharp
public sealed class GameSession
{
    // Determine if this session belongs to a Godot client
    public bool IsGodotClient { get; private set; }

    // Mark this session as Godot client (after WebSocket auth)
    public void MarkAsGodotClient()
    {
        IsGodotClient = true;
    }

    // Atomically claim the right to send map block (jru)
    // Returns true if claim acquired, false if already claimed
    public bool TryClaimMapSend()
    {
        // Lock-free atomic claim using Interlocked.Exchange
    }

    // Release map block send claim
    public void ReleaseMapSend()
    {
        // Release claim after lqc from other clients
    }
}
```

#### Hook Events

**`SessionBound` Event**
- **Signature**: `Action<GameSession, long>`
- **Called**: After `BindAccount` in `GameNodeProxy.HandleTicketPresentation`
- **Purpose**: Notify custom modules that a session has been bound to an account
- **Implementation**:
  ```csharp
  Extensions.CustomHooks.SessionBound += (session, accountId) =>
      GodotClientEntry.OnSessionBound(session, accountId);
  ```
- **Handler**: `GodotClientEntry.OnSessionBound` marks the session as a Godot client if the account was authenticated via WebSocket

**`WorldEntered` Event**
- **Signature**: `Action<GameSession>`
- **Called**: End of `EnterWorldAsync`, after world entry blocks are sent
- **Purpose**: Notify custom modules that the player has entered the world
- **Implementation**:
  ```csharp
  Extensions.CustomHooks.WorldEntered += GodotClientEntry.OnWorldEntered;
  ```
- **Handler**: `GodotClientEntry.OnWorldEntered` starts a 5-second timer to send the map block to Godot clients

---

## 🔐 API Endpoints

### 1. **GET /api/obtener-ticket (Port 8888)**

**Purpose**: Get an authentication ticket for WebSocket login

**Method**: `GET` or `POST`

**Request Parameters**:

| Parameter | Type | Description |
|-----------|------|-------------|
| `token` | string | Authentication token (from Cognito/Amplify) |
| `serverId` | int | Target server ID (default: 1, e.g., 1=Academy, 2=Adventure) |
| `language` | string | Language code (default: "es") |

**Response (Success - 200)**:
```json
{
  "success": true,
  "ticket": "<base64-encoded-ticket>",
  "host": "127.0.0.1",
  "ports": [5555, 5557]
}
```

**Response (Error - 400/401/403)**:
```json
{
  "success": false,
  "error": "sesion-caducada",
  "error_code": "expired"
}
```

**Common Error Codes (Spanish)**:

| Code | Message | Description |
|------|---------|-------------|
| `sesion-caducada` | "Session expired" | The authentication session has expired |
| `cuenta-ya-abierta` | "Account already open" | The account is already connected from another session |
| `tope-de-clientes` | "Client limit reached" | Server has reached maximum client connections |
| `credenciales-invalidas` | "Invalid credentials" | Authentication token is invalid |

---

## 🔗 WebSocket Protocol (Port 5557)

### Authentication Request
The client sends a message to establish its identity:

```json
{
  "type": "auth",
  "token": "<auth-token>",
  "serverId": 1,
  "language": "es"
}
```

**Where**:
- `type`: Always "auth" for Godot client
- `token`: JWT from Cognito user pool
- `serverId`: Target server ID (default: 1)
- `language`: Language code (default: "es")

### Server Selection Response
After authentication, the server responds with connection details:

```json
{
  "success": true,
  "accountId": 12345,
  "servers": [
    {"id": 1, "name": "Academy", "population": 42, "is_full": false},
    {"id": 2, "name": "Adventure", "population": 128, "is_full": true}
  ]
}
```

### Ticket Response
Then after server selection:

```json
{
  "success": true,
  "ticket": "<ticket-for-tcp>",
  "host": "127.0.0.1",
  "ports": [5555, 5557]
}
```

---

## 🌐 TCP Game Connection (Port 5555)

After receiving the ticket, the Godot client opens a TCP connection to the game node.

### Complete Connection Flow

1. **Connect TCP**: Open socket to game server port 5555
2. **Send kqz**: Message with ticket containing authentication details
   ```protobuf
   message Packet {
     message InnerMessage {
       message Any {
         string type_url = 1;
         bytes value = 2;
       }
       Any message = 1;
       string request_id = 2;
     }
     InnerMessage inner = 2;
   }
   ```
3. **Server Response**: Validates ticket and binds session to account
4. **Receive Welcome Burst**:
   - Character list (ksq)
   - World entry blocks (multiple messages)
5. **Receive Map Block** (jru): Delivered after 5-second timeout (without lqc)
6. **Handle World**:
   - Map actors list (jss) after map block
   - Game logic starts

### Critical Message Types

| Message | Purpose | Godot Client |
|---------|---------|--------------|
| `kqz` | Present ticket | ✓ Send immediately |
| `ksq` | Character list | ✓ Receive immediately |
| `jru` | Current map block | ✓ Receive after 5s |
| `jss` | Map actors | ✓ Receive after jru |
| `lqc` | Load complete | ✗ **DO NOT SEND** |
| `kqo` | Heartbeat | ✗ **DO NOT SEND** |

---

## 🗺️ Map Block Delivery Mechanism

### Standard Client Behavior
```
Client connects → User presses enter server → Server sends initial burst
  → Server sends map block (jru) immediately
  → Client sends lqc (load complete) to confirm
  → Server sends actors (jss)
```

### Godot Client Behavior
```
Client connects → User presses enter server → Server sends initial burst
  → Server sends jru after 5-second timeout (no lqc received)
  → Server sends actors (jss) automatically
```

### Claim Mechanism

Due to the different timing, the server uses an atomic claim mechanism:

```csharp
// Only one path can claim the right to send map block
if (!session.TryClaimMapSend())
{
    // Already claimed by standard client (via lqc)
    return;
}

// Send map block
await SendMapBlock(account, map);

// Release claim
session.ReleaseMapSend();
```

### Why This Matters

- **Never send lqc**: Will cause the server to think the map block is still pending and reload it automatically
- **Never send kqo**: Causes unwanted heartbeat spam
- **Wait for jru**: This is the trigger for loading the map visualization

---

## 📝 Key Messages Breakdown

### 1. kqz (Authentication Ticket)

**Purpose**: Present authentication ticket for single-use redemption

**Format**:
```protobuf
message Packet {
  message InnerMessage {
    message Any {
      string type_url = 1;
      bytes value = 2;
    }
    Any message = 1;
    string request_id = 2;
  }
  InnerMessage inner = 2;
}
```

**Godot Client Implementation**:
```gdscript
# In DofusClient.gd
func send_kqz_message(ticket: String) -> void:
    # Build inner kqz message with ticket in field 2
    var inner_kqz = Pb.New()
       .Str(2, ticket)  // ticket value
    # Don't include Str(3, language) - omitted for Godot

    # Build Any envelope: type_url in field 1, inner in field 2
    var any_msg = Pb.New()
       .Str(1, "type.ankama.com/kqz")
       .Bytes(2, inner_kqz.Build())
       # No request_id in Any - send as root level

    # Build full packet: { f2: any_msg }
    var packet = Pb.New()
       .Msg(2, any_msg)
       .Build()

    # Add varint framing before sending
    tcp_stream.put_data(packet)
```

### 2. ksq (Character List)

**Purpose**: Send character selection list

**Received Immediately After**:

```protobuf
message CharacterListMessage {
  repeated CharacterInfo characters = 1;
  repeated ServerInfo servers = 2;
  repeated string serverStates = 3;
}
```

### 3. jru (Current Map)

**Purpose**: Send current map data (CRITICAL for Godot)

**Timing**: Delivered after 5 seconds if no `lqc` is received

**Format**:
```protobuf
message CurrentMap {
  int32 mapId = 1;
  // Other map properties...
}
```

**Godot Processing**:
```gdscript
func _handle_message(message_type: String, payload: Dictionary) -> void:
    if message_type == "CurrentMapMessage":
        var map_data = _parse_current_map(payload)

        # CRITICAL: Immediate map load
        _load_map_visualization(map_data.map_id)

        # Do NOT send lqc at this point
        # Map block was already delivered

func _load_map_visualization(map_id: int) -> void:
    print("Loading map:", map_id)
    # Load collision map, cell data, actors, etc.
    # Notify render system to draw
```

### 4. jss (Map Actors)

**Purpose**: Send actors on current map with spawn cell info

**Timing**: Sent after receiving `jru` (map block)

**⚠️ CRITICAL LIMITATION - Godot 4.8 TCP 64KB Cap**

Godot 4.8's `StreamPeerTCP.get_available_bytes()` has a hard limit of 64KB per read operation. If the jss (MapActorsListMessage) exceeds this size, the message will be truncated and cannot be fully parsed.

**Symptoms of oversized jss:**
```
[GameClient] Buffer insuficiente: need 101962, have 65536
```

**Root Cause:**
- The server sends ALL players currently on the map in `f5[rep]` array
- Each player adds ~500-1000+ bytes
- With 2-3 other players, jss easily exceeds 64KB

**Server Fix Required:**
- In `BuildMapActors()`: Only include the local player in `f5[0]`
- Do NOT include other online players on the same map
- Target jss size: < 64KB

**Spawn Cell Location:**
- Extracted from `f5[0].f1.f1` (first player's cell position)
- Expected: 352 for keka on map 88212759

---

## ⚠️ Common Errors & Gotchas

### ❌ What NOT to do

1. **Send lqc after receiving jru**
   - This causes the server to think the map block is still pending
   - Results in automatic map reload
   - **Never send lqc for Godot client**

2. **Wait for map block before loading**
   - Map block (jru) is already delivered after 5s
   - Timeout is 15-20s max
   - Use the timeout wisely

3. **Forget to handle map block timing**
   - Standard client sends lqc → map block immediately (sub-second)
   - Godot misses lqc → map block after 5s
   - **Design UI to handle 5-second delay**

4. **Send kqo to keep connection alive**
   - Godot client does not use kqo
   - Server manages heartbeat automatically
   - **Don't spam with kqo**

### ✅ What TO do

1. **Verify jru reception with timeout**
   ```gdscript
   var map_timer = Timer.new()
   map_timer.autostart = true
   map_timer.wait_time = 15.0  # generous timeout
   map_timer.timeout.connect(_handle_map_timeout)
   add_child(map_timer)
   ```

2. **Parse character list from ksq immediately**
   ```gdscript
   if message_type == "ksq":
       var characters = _parse_character_list(payload)
       _populate_character_selection(characters)
   ```

3. **Load map visualization on jru reception**
   ```gdscript
   if message_type == "jru":
       _load_map_visualization(map_data.map_id)
       # Start rendering loop
   ```

4. **Handle authentication flow correctly**
   ```gdscript
   # Step 1: Get ticket via HTTP
   var ticket_response = await _get_ticket()

   # Step 2: Connect WebSocket
   await _connect_websocket(ticket_response.accountId)

   # Step 3: Select server
   var server_response = await _select_server()

   # Step 4: Connect TCP game
   await _connect_game_tcp(server_response.ticket)

   # Step 5: Receive and process messages
   while connected:
       await read_next_message()
   ```

---

## 🔧 Implementation Checklist

### Client-Side (Godot)

- [ ] WebSocket client for port 5557
- [ ] TCP client for port 5555
- [ ] HTTP client for `/api/obtener-ticket`
- [ ] Protobuf helper functions:
  - [ ] `put_string()` - encode strings
  - [ ] `put_bytes()` - encode byte arrays
  - [ ] Message construction helpers
- [ ] Message parsing for:
  - [ ] Character list (ksq)
  - [ ] Current map (jru)
  - [ ] Actors (jss)
- [ ] Map visualization system
- [ ] Timeout handlers (5s for map block)
- [ ] Session management:
  - [ ] Wait for ticket before TCP connection
  - [ ] Store character IDs
  - [ ] Handle server selection

### Server-Side (Verification)

- [ ] Custom hooks system installed
- [ ] `GameSession.IsGodotClient` property
- [ ] `GameSession.MarkAsGodotClient()` method
- [ ] `GameSession.TryClaimMapSend()` method
- [ ] `SessionBound` hook implemented
- [ ] `WorldEntered` hook implemented
- [ ] 5-second timer for map block delivery
- [ ] Map block claim/release mechanism

---

## 🧪 Testing

### Test Credentials

```
Username: keka
Password: test
AccountId: 188940901
ServerId: 290
```

### Integration Test Flow

```bash
# 1. Start server
cd jondo-servidor
dotnet run

# 2. Start Godot client
cd DofusClient/godot-client
godot --headless --path . --quit

# 3. Monitor server logs for:
#    [Server] WebSocket auth: keka authenticated
#    [Server] Client confirmed as Godot via WebSocket
#    [Server] Server selection requested: server 290
#    [Server] Ticket issued and registered: b198be...
#    [Server] Connecting TCP from 127.0.0.1
#    [Server] kqz presented
#    [Server] Ticket redeemed successfully (session bound)
#    [Server] Welcome burst sent (ksq)
#    [Server] World entry blocks sent
#    [Server] Map block (jru) queued for 5s (no lqc)
#    [Server] Map block (jru) delivered via timer
#    [Server] Actors (jss) sent
```

### Expected Behavior

1. **WebSocket connection**: Successful authentication
2. **Ticket retrieval**: `/api/obtener-ticket` returns valid ticket
3. **TCP connection**: Successful connection to port 5555
4. **kqz message**: Sent correctly with ticket in field 2
5. **Character list**: Received immediately after kqz
6. **Map block**: Received after 5 seconds (no lqc)
7. **Actors**: Received immediately after map block
8. **No lqc/kqo**: Client should NOT send them
9. **Map load**: Should complete successfully with 15s timeout

---

## 📚 Additional Documentation

- `docs/CUSTOM-HOOKS.md` - Server-side custom hooks system details
- `docs/UPSTREAM-SYNC.md` - Keeping server code synchronized with upstream
- `src/Network/DofusClient.gd` - Client implementation
- `src/Network/MapManager.gd` - Map visualization handler
- `src/Network/DofusProtocol.gd` - Protocol serialization helpers

---

## 📞 Support & Debugging

### Server Logs to Monitor

```
[Server] WebSocket auth: userauthenticated
[Server] BindAccount succeeded: accountId=188940901
[Server] Session marked as Godot client
[Server] Ticket presented via kqz
[Server] Ticket redeemed successfully
[Server] Map send claimed (Godot - no lqc)
[Server] Map block (jru) queueing for 5s
[Server] Map block (jru) delivered
[Server] Actors (jss) sent
```

### Common Issues

**Issue**: Map never loads
```
Cause: jru not received × 5s timeout
Fix: Check server logs for "Map block queued"
```

**Issue**: Client disconnects immediately
```
Cause: Ticket not redeemed or invalid
Fix: Verify ticket validity in SessionRegistry
```

**Issue**: Multiple map blocks sent
```
Cause: lqc sent by standard client
Fix: Ensure Godot NEVER sends lqc
```

---

**Last Updated**: 2026-11-10
**Protocol Version**: Current (3.6.10.10)
**Server Status**: Tested and working
**Client Status**: Integration pending