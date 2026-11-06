# Implementation Roadmap for Community Contribution

## Overview

This roadmap provides a structured approach for community members to contribute to the DreamFus server project. It covers everything from initial setup to advanced features.

---

## Phase 1: Foundation Setup

### 1.1 Development Environment

**Prerequisites:**
- Windows 10/11 (required for .NET 10)
- .NET 10 SDK
- Visual Studio 2022 or later (with .NET desktop development)
- Git 2.40+

**Setup Steps:**
```bash
git clone <repository-url>
cd DofusClient
git checkout -b feature/your-feature-name
dotnet restore
dotnet build
```

### 1.2 Skills Installation

**Required Skills:** `thedivergentai/Game-Dev-Agentic-Skills`

```bash
npx skills add thedivergentai/Game-Dev-Agentic-Skills
```

### 1.3 Project Structure

```
DofusClient/
├── Jondo.Unity.Server/          # Server code
│   └── Custom/                   # All custom code (hooks, modules)
│       ├── Core/                 # Hooks, protocol handlers
│       ├── SimpleProtocol/       # WebSocket authentication
│       ├── Items/                # Item system extensions
│       ├── Spells/               # Spell system
│       └── Bootstrap/            # Plugin registration
├── ClientMods/                   # Client modifications
│   └── src/TestMod/              # Main Unity mod
├── Jondo.Unity.Tests/            # Test suite
└── docs/                         # Documentation
```

---

## Phase 2: SimpleProtocol Integration

### 2.1 Authentication Flow

**Current State:** ✅ Implemented

**Flow:**
```
Client → WebSocket Connect (port 5557)
Client → Auth Request (JSON + 4-byte prefix)
Server → Auth Response (account_id, server list)
Client → Server Selection Request
Server → Server Selection Response (ticket)
Client → Connect to Game Server (port 5555)
```

### 2.2 Test Account

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

### 2.3 Running Tests

```bash
dotnet test Jondo.Unity.Tests/Jondo.Unity.Tests.csproj
```

---

## Phase 3: Core Systems Development

### 3.1 Item System Extension

**Files to modify:**
- `Custom/Items/ItemFactory.cs` - Create items
- `Custom/Items/ItemEffects.cs` - Apply item effects
- `Custom/Items/ItemHooks.cs` - Event integration

**Architecture Pattern:**
```csharp
// Example item decorator
public class SpecialItemDecorator : IItemDecorator
{
    public Item Apply(Item baseItem, ItemContext context)
    {
        // Modify item properties
        return new Item
        {
            Id = baseItem.Id,
            Name = $"[Special] {baseItem.Name}",
            Stats = ApplySpecialStats(baseItem.Stats)
        };
    }
}
```

### 3.2 Spell System Development

**Key Components:**
- `Custom/Spells/SpellDatabase.cs` - Spell definitions
- `Custom/Spells/SpellCastHandler.cs` - Casting logic
- `Custom/Spells/SpellEffects.cs` - Effect resolution

**Spell Hook Points:**
```csharp
public static event Action<SpellCastAttempt>? SpellCastAttemptEvent;
public static event Action<SpellCastComplete>? SpellCastCompleteEvent;
public static event Action<SpellEffectApplied>? SpellEffectAppliedEvent;
```

### 3.3 Dungeon System

**Architecture:**
- `Custom/Dungeons/DungeonManager.cs` - Instance management
- `Custom/Dungeons/DungeonSpawn.cs` - Monster/NPC spawning
- `Custom/Dungeons/DungeonLoot.cs` - Loot tables
- `Custom/Dungeons/DungeonHooks.cs` - Events

---

## Phase 4: Protocol Extensions

### 4.1 Adding New Protocol Messages

**Step 1: Add DTO to CustomHooks.cs**

```csharp
public sealed class CustomProtocolRequest
{
    [JsonPropertyName("message_type")]
    public string MessageType { get; init; } = "";
    
    [JsonPropertyName("payload")]
    public object Payload { get; init; } = new();
}
```

**Step 2: Add Event to CustomHooks.cs**

```csharp
public static event Func<CustomProtocolRequest, Task<CustomProtocolResponse?>>? CustomProtocolEvent;
```

**Step 3: Register in CustomBootstrapper.cs**

```csharp
public static void Initialize()
{
    // ...
    CustomHooks.CustomProtocolEvent += YourModule.ProtocolHandler;
}
```

**Step 4: Handle in SimpleProtocolHandler.cs**

Add routing in `HandleMessageAsync`:

```csharp
case "custom_message":
    await HandleCustomMessageAsync(context, request);
    break;
```

### 4.2 Frame Protocol Details

**Encoding:**
- 4-byte big-endian length prefix
- UTF-8 JSON payload
- Message type field required

**Example Message:**
```json
{
  "type": "custom_message",
  "action": "do_something",
  "data": {
    "parameter": "value"
  }
}
```

---

## Phase 5: Testing Strategy

### 5.1 Unit Tests

**File Convention:** `Jondo.Unity.Tests/ModuleName.Tests.cs`

**Example Test:**
```csharp
[TestClass]
public class CustomProtocolTests
{
    [TestMethod]
    public async Task CustomMessage_ValidRequest_ReturnsSuccess()
    {
        // Arrange
        var request = new CustomProtocolRequest
        {
            MessageType = "test",
            Payload = new { action = "ping" }
        };
        
        // Act
        var response = await YourHandler(request);
        
        // Assert
        Assert.IsNotNull(response);
        Assert.IsTrue(response.Success);
    }
}
```

### 5.2 Integration Tests

Use the WebSocket client for end-to-end tests:

```csharp
public class WebSocketIntegrationTests
{
    [TestMethod]
    public async Task FullAuthFlow_WorksCorrectly()
    {
        // Test complete authentication flow
        // Verify token resolution
        // Verify server selection
        // Verify ticket generation
    }
}
```

---

## Phase 6: Production Considerations

### 6.1 Code Quality Standards

- ✅ Follow C# naming conventions (PascalCase for public members)
- ✅ Use `record` for immutable data structures
- ✅ Prefer `async/await` over synchronous operations
- ✅ Implement proper error handling
- ✅ Use dependency injection where appropriate

### 6.2 Performance Guidelines

- Limit query complexity (N+1 queries)
- Cache frequently accessed data
- Use connection pooling for database operations
- Monitor memory usage in long-running operations

### 6.3 Security Considerations

- Validate all input from clients
- Implement rate limiting
- Use secure session tokens
- Log security-relevant events

---

## Phase 7: Documentation Requirements

When contributing new features, update:

1. **Code Comments:** Follow XML documentation style
2. **Hook Registry:** Add to `docs/CUSTOM-HOOKS.md`
3. **Protocol Docs:** Update wire format documentation
4. **README:** Add usage examples

---

## Contributing Workflow

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/amazing-feature
   ```

2. **Implement changes:**
   - Write tests first (TDD)
   - Implement feature
   - Run all tests

3. **Commit messages:**
   ```
   feat(spells): add new fireball spell
   
   - Implements Fireball spell with area damage
   - Adds visual effect trigger
   - Includes unit tests for damage calculation
   ```

4. **Push and create PR:**
   ```bash
   git push origin feature/amazing-feature
   # Create Pull Request
   ```

5. **PR Description Template:**
   - What changed
   - Why it's needed
   - How to test
   - Any breaking changes

---

## Common Pitfalls to Avoid

1. **❌ Modifying upstream core code** - Use hooks instead
2. **❌ Adding dependencies in core** - Keep Custom/ namespace separate
3. **❌ Hardcoding values** - Use configuration or constants
4. **❌ Skipping tests** - All changes need tests
5. **❌ Inconsistent naming** - Follow the established patterns

---

## Getting Help

- **Documentation:** `docs/` directory
- **Hook Examples:** `Custom/` source files
- **Test Examples:** `Jondo.Unity.Tests/`
- **Issues:** Open a GitHub issue with detailed information

---

## Next Steps

Choose a phase based on your expertise:

| Skill Level | Recommended Phase |
|-------------|---------------------|
| Beginner | Phase 2 (SimpleProtocol testing) |
| Intermediate | Phase 3 (Item/Spell system) |
| Advanced | Phase 4 (New protocol extensions) |
| Expert | Phase 7 (Architecture improvements) |

---

*Last updated: November 2026*
*Version: 1.0*