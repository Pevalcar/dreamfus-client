# Custom Hooks Registry

## Overview / Visión General

This document registers all custom hooks available in the DreamFus Client project. Hooks are the primary mechanism for extending functionality without modifying core code.

Este documento registra todos los hooks personalizados disponibles en el proyecto DreamFus Client. Los hooks son el mecanismo principal para extender la funcionalidad sin modificar el código central.

---

## Client-Side Hooks (JavaScript/TypeScript)

All client-side hooks are registered and managed through the `EventBus` system in `frontend/src/EventBus.js`.

Todos los hooks del lado del cliente se registran y administran a través del sistema `EventBus` en `frontend/src/EventBus.js`.

### Server Message Handlers

Register handlers for server messages using `EventBus.onServerMessage()`:

```javascript
// Spanish/Ejemplo: Registrar handlers para mensajes del servidor
import { EventBus } from './EventBus.js';

// Register a handler for character list messages
EventBus.onServerMessage('charactersList', (message) => {
    const characters = message.payload?.characters || [];
    updateCharacterListUI(characters);
});

// Unregister when needed (e.g., when leaving a screen)
EventBus.offServerMessage('charactersList', handlerFunction);
```

### Global Event Handlers

Register for global events using `EventBus.on()`:

```javascript
// Subscribe to server messages
EventBus.on('server-message', (message) => {
    console.log('Received message:', message.opcode_str);
});

// Subscribe to specific opcodes (backward compatible)
EventBus.on('hello', (message) => {
    console.log('Server hello received');
});

// Subscribe to custom events from UI screens
EventBus.on('login-attempt', (credentials) => {
    // Handle login
});
```

### Registered Server Opcodes

| Opcode | Handler | Purpose / Propósito |
|--------|---------|---------------------|
| `hello` | Global listener | Initial server connection / Conexión inicial al servidor |
| `charactersList` | Screen handler | Character selection screen / Pantalla de selección de personajes |
| `ankamaFriendsList` | Friends screen | Friends list display / Lista de amigos |
| `krt` | Tauri backend | Connection greeting / Saludo de conexión |
| `kuf` | Tauri backend | Server hello response / Respuesta del saludo del servidor |
| `kvi` | Tauri backend | Character list protobuf / Lista de personajes |
| `kvw` | Tauri backend | Character selection / Selección de personaje |
| `kqz` | Tauri backend | Present ticket / Presentar ticket |
| `hpd` | Tauri backend | Position updates / Actualizaciones de posición |
| `ankamaMoods` | Tauri backend | Character mood information / Estado de ánimo del personaje |

### Hook Registration Pattern

#### Pattern for New Server Messages / Patrón Para Nuevos Mensajes del Servidor

1. Add opcode documentation to this file
2. Register handler in the appropriate UI screen:

```javascript
// Example: In a screen file
export class CharactersScreen {
    constructor(uiManager) {
        this.uiManager = uiManager;
        this.handler = this.handleCharactersList.bind(this);
    }
    
    initialize() {
        // Register the hook
        EventBus.onServerMessage('customOpcode', this.handler);
    }
    
    handleCharactersList(message) {
        // Process the message
        const data = message.payload;
        this.renderUI(data);
    }
    
    cleanup() {
        // Unregister when leaving the screen
        EventBus.offServerMessage('customOpcode', this.handler);
    }
}
```

---

## SimpleProtocol Hooks (Port 5557 - WebSocket)

### Authentication Flow Hooks

```javascript
// Hook: WebSocket connection established
EventBus.on('ws-connected', (info) => {
    console.log('WebSocket connected:', info);
});

// Hook: Authentication attempt sent
EventBus.on('auth-attempt', (credentials) => {
    // Handle auth request to port 5557
});

// Hook: Authentication response received
EventBus.on('auth-response', (serverList) => {
    // Update server selection UI
});

// Hook: Server selection sent
EventBus.on('server-selection', (serverId) => {
    // Handle server join
});

// Hook: Ticket received
EventBus.on('ticket-received', (ticket) => {
    // Connect to game server on port 5555
});
```

### WebSocket Message Format Hook Points

All WebSocket messages follow this format:

```
[4-byte big-endian length][UTF-8 JSON payload]
```

Example message flow:

```json
// Outgoing auth_request
{
  "type": "auth_request",
  "token": "user-token",
  "installId": "client-id",
  "lang": "en",
  "version": "3.6.10.10"
}

// Incoming auth_response
{
  "type": "auth_response",
  "servers": [
    {"id": 290, "name": "DreamFus", "status": "online"}
  ],
  "token": "session-token"
}
```

---

## Tauri Backend Commands

The Rust backend in `src/lib.rs` exposes these commands:

| Command | Description / Descripción |
|---------|---------------------------|
| `connect_server` | Connect to game server |
| `disconnect_server` | Disconnect from game server |
| `get_server_status` | Get current connection status |
| `send_message` | Send protocol message |
| `build_connection_greeting` | Build krt message |
| `build_server_selection` | Build kvz message |
| `build_kqz` | Build present ticket message |
| `build_kvw` | Build character selection message |
| `parse_auth_response` | Parse kuf response |
| `parse_ticket_response` | Parse ticket response |
| `parse_character_list` | Parse kvi response |
| `listen('server-message', ...)` | Listen for server messages |

---

## Adding New Hooks

### Adding a Server Message Handler

1. **Document in this file** - Add to the registered opcodes table
2. **Implement in the appropriate screen** - Follow the registration pattern
3. **Test in mock mode** - Ensure mock responses work
4. **Test with real server** - Verify protocol integration

### Hook Naming Convention

- **Events**: lowercase-hyphen-case (e.g., `login-attempt`, `character-selected`)
- **Server messages**: camelCase (e.g., `charactersList`, `ankamaFriendsList`)
- **Custom events**: domain-specific (e.g., `spellsCast`, `achievementUnlocked`)

---

## UI Screen Hooks

Each UI screen registers its own hooks:

| Screen | File | Hooks |
|--------|------|-------|
| Login | `ui/screens/login.js` | `login-attempt`, `auth-response` |
| Character Select | `ui/screens/characterSelect.js` | `charactersList`, `character-selected` |
| Main Menu | `ui/screens/mainMenu.js` | `friends-list`, `menu-action` |
| Friends | `ui/screens/friends.js` | `ankamaFriendsList`, `friend-request`, `friend-added` |

---

## Events Flow Diagram

```
[WebSocket] → [Protocol.js] → [EventBus] → [UI Screens]
                      ↓
              [Tauri Backend (desktop)]
                      ↓
              [Game Server (port 5555)]
```

---

## Testing Hooks

### Mock Mode Testing

In mock mode, the protocol automatically emits mock responses for testing:

```javascript
// Test that a handler is called
let handlerCalled = false;

const handler = (message) => {
    handlerCalled = true;
    assert(message.payload?.characters?.length > 0);
};

EventBus.onServerMessage('charactersList', handler);

// Trigger mock connection
await protocol.connectMock();

// Verify handler was called with mock data
```

### Integration Testing

```javascript
// Full connection flow test
describe('Connection Flow', () => {
    it('should complete authentication', async () => {
        // 1. Connect WebSocket
        const connectResult = await protocol.connectWebSocket('localhost', 5557);
        expect(connectResult.success).toBe(true);
        
        // 2. Send auth request
        const authResult = await protocol.sendMessage('auth_request', authPayload);
        expect(authResult.success).toBe(true);
        
        // 3. Receive auth response (mock or real)
        // Handler should be called via EventBus
    });
});
```

---

## Cleanup and Memory Management

Always cleanup event listeners when screens are destroyed:

```javascript
export class Screen {
    constructor() {
        this.boundHandlers = new Map();
    }
    
    initialize() {
        // Bind handlers and store reference
        const handler = this.handleMessage.bind(this);
        this.boundHandlers.set('message', handler);
        EventBus.onServerMessage('message', handler);
    }
    
    cleanup() {
        // Unsubscribe all handlers
        for (const [event, handler] of this.boundHandlers) {
            EventBus.offServerMessage(event, handler);
        }
        this.boundHandlers.clear();
    }
}
```

---

## References

- **Protocol Documentation**: `docs/SIMPLE-PROTOCOL-HOOKS.md`
- **Implementation Roadmap**: `docs/IMPLEMENTATION-ROADMAP.md`
- **Contributing Guide**: `docs/CONTRIBUTING.md`
- **UI Guidelines**: `docs/UI-CLIENTE.md`

---

*Last updated: November 2026*
*Version: 1.0*