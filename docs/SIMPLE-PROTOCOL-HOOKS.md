# SimpleProtocol Hooks Documentation

## Overview

The SimpleProtocol (port 5557) is a WebSocket-based authentication protocol that provides a simpler alternative to the complex protobuf protocol on port 5555. It is primarily intended for development and testing purposes, and for custom client contributions.

**Port 5557 Protocol Details:**
- WebSocket connection (ws://127.0.0.1:5557)
- 4-byte big-endian length prefix for each message
- UTF-8 JSON payload
- Message type field required for routing

**Important:** In production, clients should use port 5555 with the protobuf protocol. Port 5557 is for development and community contributions.

---

## Hook System Architecture

The SimpleProtocol uses the same hook architecture as the main server. All custom hooks are declared in `CustomHooks.cs` and registered via `CustomBootstrapper.cs`.

### Core Files for SimpleProtocol

| File | Purpose |
|------|---------|
| `Custom/Core/CustomHooks.cs` | DTO definitions and event declarations |
| `Custom/Core/SimpleProtocolHandler.cs` | WebSocket server implementation |
| `Custom/SimpleProtocol/AuthHandlers.cs` | Authentication logic |
| `Custom/Bootstrap/CustomBootstrapper.cs` | Hook registration |

---

## Available Hooks

### 1. SimpleAuthRequestEvent

**Purpose:** Handle authentication requests from the WebSocket client.

**File Location:** `Jondo.Unity.Server/Custom/Core/CustomHooks.cs:102`

**Event Handler Signature:**
```csharp
public static event Func<SimpleAuthRequest, Task<SimpleAuthResponse?>>? SimpleAuthRequestEvent;
```

**Usage in SimpleProtocolHandler.cs:**
- Line 159-228: `HandleAuthRequestAsync` deserializes the request, invokes the handler, and sends the response.

---

### 2. SimpleServerSelectionEvent

**Purpose:** Handle server selection requests and provide connection details.

**File Location:** `Jondo.Unity.Server/Custom/Core/CustomHooks.cs:103`

**Event Handler Signature:**
```csharp
public static event Func<SimpleServerSelectionRequest, Task<SimpleServerSelectionResponse?>>? SimpleServerSelectionEvent;
```

**Usage in SimpleProtocolHandler.cs:**
- Line 231-273: `HandleServerSelectionAsync` validates the session, invokes the handler, and sends the response.

---

## DTO Definitions

### SimpleAuthRequest

**File:** `Custom/Core/CustomHooks.cs:116-132`

```csharp
public sealed class SimpleAuthRequest
{
    [JsonPropertyName("lang")]
    public string Lang { get; init; } = "es";
    
    [JsonPropertyName("token")]
    public string Token { get; init; } = "";
    
    [JsonPropertyName("installId")]
    public string InstallId { get; init; } = "";
    
    [JsonPropertyName("version")]
    public string Version { get; init; } = "3.6.10.10";
    
    [JsonPropertyName("ticketId")]
    public string TicketId { get; init; } = "";
}
```

---

### SimpleAuthResponse

**File:** `Custom/Core/CustomHooks.cs:135-148`

```csharp
public sealed class SimpleAuthResponse
{
    [JsonPropertyName("success")]
    public bool Success { get; init; }
    
    [JsonPropertyName("error")]
    public string Error { get; init; } = "";
    
    [JsonPropertyName("account_id")]
    public long AccountId { get; init; }
    
    [JsonPropertyName("servers")]
    public IReadOnlyList<SimpleServerInfo> Servers { get; init; } = Array.Empty<SimpleServerInfo>();
}
```

---

### SimpleServerInfo

**File:** `Custom/Core/CustomHooks.cs:151-164`

```csharp
public sealed class SimpleServerInfo
{
    [JsonPropertyName("id")]
    public int Id { get; init; }
    
    [JsonPropertyName("name")]
    public string Name { get; init; } = "";
    
    [JsonPropertyName("population")]
    public int Population { get; init; }
    
    [JsonPropertyName("is_full")]
    public bool IsFull { get; init; }
}
```

---

### SimpleServerSelectionRequest

**File:** `Custom/Core/CustomHooks.cs:167-177`

```csharp
public sealed class SimpleServerSelectionRequest
{
    [JsonPropertyName("lang")]
    public string Lang { get; init; } = "es";
    
    [JsonPropertyName("server_id")]
    public int ServerId { get; init; }
    
    [JsonPropertyName("account_id")]
    public long AccountId { get; init; }
}
```

---

### SimpleServerSelectionResponse

**File:** `Custom/Core/CustomHooks.cs:180-196`

```csharp
public sealed class SimpleServerSelectionResponse
{
    [JsonPropertyName("success")]
    public bool Success { get; init; }
    
    [JsonPropertyName("error")]
    public string Error { get; init; } = "";
    
    [JsonPropertyName("ticket")]
    public string Ticket { get; init; } = "";
    
    [JsonPropertyName("host")]
    public string Host { get; init; } = "127.0.0.1";
    
    [JsonPropertyName("ports")]
    public int[] Ports { get; init; } = { 5555, 5555 };
}
```

---

## Message Flow

### Authentication Flow

```
Client (port 5557)                    Server
    │                                     │
    │  WebSocket Connect                  │
    │────────────────────────────────────→│
    │                                     │
    │  {                                    │
    │    "type": "auth_request",           │
    │    "token": "...",                   │
    │    "installId": "...",               │
    │    "lang": "en",                     │
    │    "version": "3.6.10.10"            │
    │  }                                   │
    │────────────────────────────────────→│
    │       (Invokes SimpleAuthRequestEvent)│
    │                                     │
    │  {                                    │
    │    "type": "auth_response",          │
    │    "success": true,                  │
    │    "account_id": 123456789,          │
    │    "servers": [...]                  │
    │  }                                   │
    │←────────────────────────────────────│
    │                                     │
```

### Server Selection Flow

```
Client (port 5557)                    Server
    │                                     │
    │  {                                    │
    │    "type": "server_selection",       │
    │    "account_id": 123456789,          │
    │    "server_id": 290,                 │
    │    "lang": "en"                      │
    │  }                                   │
    │────────────────────────────────────→│
    │       (Invokes SimpleServerSelectionEvent)│
    │                                     │
    │  {                                    │
    │    "type": "server_selection_response",│
    │    "success": true,                  │
    │    "ticket": "abc123...",            │
    │    "host": "127.0.0.1",              │
    │    "ports": [5555, 5555]              │
    │  }                                   │
    │←────────────────────────────────────│
    │                                     │
    │  (Player will connect to port 5555   │
    │   with the ticket)                  │
    │                                     │
```

### Ping/Pong

```
Client                                    Server
    │                                     │
    │  { "type": "ping" }                 │
    │────────────────────────────────────→│
    │                                     │
    │  { "type": "pong",                  │
    │    "timestamp": 1234567890 }         │
    │←────────────────────────────────────│
    │                                     │
```

---

## Frame Protocol

### Encoding Format

Each WebSocket message is framed as:
```
[4-byte big-endian length][UTF-8 JSON payload]
```

**Example:**
- JSON payload: `{"type":"ping"}` (16 bytes)
- Frame: `[0x00 0x00 0x00 0x10] + {"type":"ping"}`

### Sending from Server

See `SimpleProtocolHandler.cs:275-286`:
```csharp
private async Task SendJsonAsync(WebSocket ws, object obj)
{
    string json = JsonSerializer.Serialize(obj, JsonOptions.Default);
    byte[] payload = Encoding.UTF8.GetBytes(json);

    var frame = new byte[4 + payload.Length];
    BinaryPrimitives.WriteInt32BigEndian(frame, payload.Length);
    Buffer.BlockCopy(payload, 0, frame, 4, payload.Length);

    await ws.SendAsync(frame, WebSocketMessageType.Binary, true, CancellationToken.None);
}
```

---

## Integration Guide for Community Contributors

### Step 1: Understand the Hook System

All custom logic lives in the `Jondo.Unity.Server/Custom/` directory. The core server code must NOT reference any `Custom` namespace - hooks are the only integration point.

### Step 2: Register Your Hooks

Edit `Jondo.Unity.Server/Custom/Bootstrap/CustomBootstrapper.cs` in the `Initialize()` method:

```csharp
internal static void Initialize()
{
    if (_initialized) return;
    _initialized = true;
    
    // ... existing hooks ...
    
    // Add your hook subscription here
    Extensions.CustomHooks.SimpleAuthRequestEvent += YourNamespace.YourAuthHandler;
    Extensions.CustomHooks.SimpleServerSelectionEvent += YourNamespace.YourSelectionHandler;
}
```

### Step 3: Implement Your Handler

Create your handler in a new file within `Jondo.Unity.Server/Custom/YourModule/`:

```csharp
using Jondo.Unity.Server.Extensions;

namespace Jondo.Unity.Server.Custom.YourModule
{
    public static class AuthHandler
    {
        public static async Task<CustomHooks.SimpleAuthResponse> OnAuthRequestAsync(CustomHooks.SimpleAuthRequest req)
        {
            // Your authentication logic here
            // Return SimpleAuthResponse with Success = true/false
        }
    }
}
```

### Step 4: Token Resolution

The SimpleProtocol uses `ClientLaunchRegistry` for token-to-account resolution (same as the main HAAPI):

```csharp
// Resolve token to account ID
long accountId = ClientLaunchRegistry.ResolveToken(req.Token);

// Register a token (for testing)
ClientLaunchRegistry.RegisterToken(accountId, "token");

// Clear all tokens (development only)
ClientLaunchRegistry.ForgetEverything();
```

### Step 5: Server Selection

For server selection, use `SessionRegistry` to generate tickets:

```csharp
// Generate a ticket
var ticket = SessionRegistry.Issue(accountId, serverId, language);
string ticketValue = ticket.Value;

// The ticket format is a 32-character hex string
```

---

## Existing Implementation Reference

### Default Auth Handlers (`AuthHandlers.cs`)

The default handlers are in `Jondo.Unity.Server/Custom/SimpleProtocol/AuthHandlers.cs`:

```csharp
public static class Handlers
{
    public static Task<CustomHooks.SimpleAuthResponse> OnAuthRequestAsync(CustomHooks.SimpleAuthRequest req)
    {
        // 1. Resolve token to account ID
        long accountId = ClientLaunchRegistry.ResolveToken(req.Token);
        
        // 2. Verify account exists
        var account = DatabaseManager.GetAccountById(accountId);
        if (account == null)
        {
            return Task.FromResult(new CustomHooks.SimpleAuthResponse
            {
                Success = false,
                Error = "Account not found"
            });
        }

        // 3. Return server list
        var servers = new List<CustomHooks.SimpleServerInfo>
        {
            new CustomHooks.SimpleServerInfo
            {
                Id = 290,
                Name = "DreamFus",
                Population = 0,
                IsFull = false
            }
        };

        return Task.FromResult(new CustomHooks.SimpleAuthResponse
        {
            Success = true,
            AccountId = accountId,
            Servers = servers
        });
    }

    public static Task<CustomHooks.SimpleServerSelectionResponse> OnServerSelectionAsync(CustomHooks.SimpleServerSelectionRequest req)
    {
        // Validate server access
        if (req.ServerId != 290) // Only DreamFus
        {
            return Task.FromResult(new CustomHooks.SimpleServerSelectionResponse
            {
                Success = false,
                Error = "Server not available"
            });
        }

        // Generate ticket
        var ticket = SessionRegistry.Issue(req.AccountId, req.ServerId, req.Lang);
        
        return Task.FromResult(new CustomHooks.SimpleServerSelectionResponse
        {
            Success = true,
            Ticket = ticket.Value,
            Host = "127.0.0.1",
            Ports = new[] { 5555, 5555 }
        });
    }
}
```

---

## Client-Side Usage Examples

### Unity/C# Client Example

```csharp
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Threading;

// Connect
var ws = new ClientWebSocket();
await ws.ConnectAsync(new Uri("ws://127.0.0.1:5557"), CancellationToken.None);

// Send auth request
var authRequest = new
{
    type = "auth_request",
    token = "your-token-here",
    installId = "your-install-id",
    lang = "en",
    version = "3.6.10.10"
};
await SendMessage(ws, authRequest);

// Read first 4 bytes for length, then read payload
// Parse JSON response...
```

### JavaScript/TypeScript Client Example

```javascript
const ws = new WebSocket('ws://127.0.0.1:5557');

ws.onopen = () => {
    const authRequest = {
        type: 'auth_request',
        token: 'your-token-here',
        installId: 'your-install-id',
        lang: 'en',
        version: '3.6.10.10'
    };
    ws.send(JSON.stringify(authRequest));
};

ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    if (data.type === 'auth_response') {
        if (data.success) {
            // Proceed to server selection
            const serverSelection = {
                type: 'server_selection',
                account_id: data.account_id,
                server_id: 290,
                lang: 'en'
            };
            ws.send(JSON.stringify(serverSelection));
        }
    }
};
```

---

## Session Management

The SimpleProtocol handles:
- **Single session per account**: If a user logs in twice, the previous session is kicked
- **Session-to-account mapping**: Tracked internally in `_sessionIdToAccountId`
- **Rate limiting**: 10 requests/second per IP with burst capacity of 20

---

## Testing

### Test Account

- **Username:** `keka`
- **Password:** `test`
- **Account ID:** `188940901`
- **Server ID:** `290` (DreamFus)

### Run Tests

```bash
dotnet test Jondo.Unity.Tests/Jondo.Unity.Tests.csproj --filter FullyQualifiedName~WebSocketAuth
```

### Test Constants

See `WebSocketAuthTests.cs` for test constants:
```csharp
public static class TestConstants
{
    public const long TestAccountId = 188940901L;
    public const string TestUsername = "keka";
    public const string TestPassword = "test";
    public const int TestServerId = 290;
    public const string TestInstallId = "test-mod-client";
    public const string TestLanguage = "en";
    public const string TestVersion = "3.6.10.10";
}
```

---

## File Locations Summary

For quick reference, here are all the files you need to work with:

| File | Purpose |
|------|---------|
| `Jondo.Unity.Server/Custom/Core/CustomHooks.cs` | DTO classes and event declarations |
| `Jondo.Unity.Server/Custom/Core/SimpleProtocolHandler.cs` | WebSocket server implementation |
| `Jondo.Unity.Server/Custom/SimpleProtocol/AuthHandlers.cs` | Default auth/selection handlers |
| `Jondo.Unity.Server/Custom/Bootstrap/CustomBootstrapper.cs` | Hook registration |
| `Jondo.Unity.Tests/Network/WebSocketAuthTests.cs` | Test implementations |
| `ClientMods/src/TestMod/LoginInterface.cs` | Unity client login implementation |
| `docs/CUSTOM-HOOKS.md` | Full hook registry documentation |
| `docs/AUTH-MIGRATION-NOTES.md` | Detailed auth migration notes |

---

## Contributing

When contributing to the SimpleProtocol:

1. **Follow the hook architecture**: Add new hooks in `CustomHooks.cs`, implement in new files under `Custom/`
2. **Update `CustomBootstrapper.cs`**: Register your hooks in `Initialize()`
3. **Update this documentation**: Add new hooks, request/response formats, or implementation details
4. **Test thoroughly**: Add unit tests following the existing patterns
5. **Keep core clean**: The server core (`upstream`) should not be modified for custom features

---

## See Also

- `docs/CUSTOM-HOOKS.md` - Full registry of all custom hooks
- `docs/AUTH-MIGRATION-NOTES.md` - Detailed authentication migration documentation
- `docs/protocol.md` - Complete wire protocol documentation
- `docs/dreamfus-phases.md` - Implementation phases and roadmap