# DreamFus Client

> **Cliente alternativo de Dofus con backend Tauri, frontend Vite y cliente Godot 4.8**
>
> **Proyecto:** https://github.com/Pevalcar/dreamfus-client.git
> **Ruta local:** `C:\Users\pevalcar\Proyects\jondo-servidor\DofusClient`

> **Golden Rule:** DreamFus Client is a fan-made project that reimplements Dofus mechanics, visuals, animations, and interfaces from scratch using freely usable assets and temporary placeholders.

---

## 🎯 Purpose

Create an alternative client that:
- **Mechanics:** Reimplements the Jondo protocol from scratch
- **Visuals:** Uses the same visual style as the original game
- **Animations:** Implements custom animation systems in Dofus style
- **Interface:** Follows the DreamFus UI specification (documented in `dreamfus-ui/`)

**Main References:**
- **ALDA** (`C:\Users\pevalcar\AppData\Local\Alea\`) — Reference Tauri/WebGL2 client (DO NOT extract/distribute)
- **DreamFusion Client** (`C:\Users\pevalcar\AppData\Local\DreamFus\Cliente\`) — Extractable assets source

---

## 📋 Implementation Roadmap

| Phase | Objective | Status |
|-------|-----------|--------|
| **Phase 1** | Foundation & Build Setup | ✅ Complete |
| **Phase 2** | Protocol Implementation (WebSocket Auth + TCP Bridge) | 🚧 In Progress |
| **Phase 3** | UI Integration | 🚧 In Progress |

**See detailed roadmap:** `docs/IMPLEMENTATION-ROADMAP.md`

---

## 📁 Project Structure

```
DofusClient/
├── package.json           # Node.js/Vite project config
├── vite.config.ts         # Build configuration
├── README.md              # This file
├── README_ES.md           # Spanish version
├── .gitignore             # Large assets, node_modules, etc.
│
├── src/                   # Rust backend (Tauri commands)
│   └── lib.rs             # WebSocket/TCP bridge
│
├── src-tauri/             # Tauri configuration
│   ├── main.rs            # Entry point
│   └── tauri.conf.json    # Config
│
├── frontend/              # Vite frontend (TypeScript)
│   ├── index.html         # HTML entry point
│   ├── main.js            # Auto-connect + main flow
│   ├── protocol.js        # WebSocket wrapper + Mock mode
│   ├── EventBus.js        # Centralized event system
│   ├── dfui/              # DFUI (DreamFus UI) engine
│   │   └── index.js       # Renderer
│   │
│   └── ui/
│       ├── UIManager.js   # Screen manager
│       └── screens/
│           ├── login.js
│           ├── characterSelect.js
│           ├── mainMenu.js
│           └── friends.js
│
├── public/
│   └── ui/                 # Static DFUI documents
│       └── *.dfui
├── docs/
│   ├── IMPLEMENTATION-ROADMAP.md
│   ├── SIMPLE-PROTOCOL-HOOKS.md
│   ├── CUSTOM-HOOKS.md
│   ├── CONTRIBUTING.md
│   ├── ASSET-STRATEGY.md
│   └── dreamfus-phases.md
└── Cargo.toml
```

---

## 🚀 Auto-Connect

### Automatic Flow

```mermaid
sequenceDiagram
    participant M as main.js
    participant U as UIManager
    participant P as Protocol
    participant E as EventBus
    participant C as CharacterSelect

    M->>U: loadUI('characterSelect')
    U->>C: init()
    C->>E: registerMessageHandler('charactersList')
    M->>P: connect(localhost:5557)
    P-->>M: { success: true, mock: true }
    M->>E: sendMockLoginFlow()
    E->>C: handleCharacters()
    C->>C: renderCharacters()
```

---

## 📊 Implementation Status

### ✅ Complete

| Component | Location | Status |
|-----------|----------|--------|
| **WebSocket/TCP Protocol (Frontend)** | `src/lib.rs` | ✅ Complete - VarInt, envelope building |
| **Auto-connect** | `frontend/src/main.js` | ✅ Complete - Mock mode |
| **Centralized EventBus** | `frontend/src/EventBus.js` | ✅ Complete |
| **DFUI Renderer** | `frontend/src/dfui/index.js` | ✅ Complete - Basic components |
| **Character Select Screen** | `frontend/src/ui/screens/characterSelect.js` | ✅ Complete - Mock mode |
| **UI Manager** | `frontend/src/ui/UIManager.js` | ✅ Complete |
| **Server Messages (mock)** | `frontend/src/main.js` | ✅ Complete |
| **Login Screen** | `frontend/src/ui/screens/login.js` | ✅ Complete - Functional fallback |
| **TCP Handshake (Godot Client)** | `godot-client/` | ✅ Complete - Full protobuf implementation |

### 🚧 In Progress / Pending

| Component | Location | Status | Notes |
|-----------|----------|--------|-------|
| **Tauri Backend Integration** | `src/lib.rs` | 🚧 Partial | Needs real WebSocket to 5557 |
| **WebSocket 4-byte framing** | `protocol.js` | 🚧 Partial | Port 5557 (auth) vs 5555 (game) |
| **Main Menu** | `frontend/src/ui/screens/mainMenu.js` | ⚠️ Mock | Needs real handlers |
| **Friends Screen** | `frontend/src/ui/screens/friends.js` | ⚠️ Mock | Mock mode only |
| **Godot Game World** | `godot-client/` | ⏳ Planned | World rendering, gameplay systems |

### godot-client/ - Godot 4.8 Client (Independent Piece)

**Status:** ✅ **Handshake Complete**

The pure GDScript Godot 4.8 client is fully functional for authentication and character selection:

| Component | File | Status |
|-----------|------|--------|
| WebSocket Client | `src/Network/SimpleProtocolClient.gd` | ✅ Complete |
| TCP Game Client | `src/Network/GameClient.gd` | ✅ Complete |
| Protobuf Utilities | `src/Network/Proto.gd` | ✅ Complete |
| Game Manager | `src/Core/GameManager.gd` | ✅ Complete |
| Character Select UI | `src/UI/CharacterSelectUI.gd` | ✅ Complete |
| Character Data Model | `src/Data/CharacterData.gd` | ✅ Complete |

**TCP Handshake Flow:**
1. WebSocket auth → server_selection → ticket
2. TCP connection to GameNodeProxy (5555)
3. Send `kqz` (ticket)
4. Receive welcome burst: `kra` → `kqp` → `lqu` → `hoy` → `kqu` → `mgq/mgt/hpd` → `krs` → `mgz` → `kqp` → `kvi` → `jtg`
5. Parse `kvi` and emit `characters_received`
6. Send `kvw` when character selected

See `godot-client/docs/TCP_HANDBSHAKE.md` and `godot-client/docs/PROTOCOL.md` for full documentation.

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `docs/IMPLEMENTATION-ROADMAP.md` | Complete implementation roadmap |
| `docs/SIMPLE-PROTOCOL-HOOKS.md` | SimpleProtocol API (WebSocket, port 5557) |
| `docs/CUSTOM-HOOKS.md` | Client hooks and event system registry |
| `docs/CONTRIBUTING.md` | How to contribute |
| `docs/ASSET-STRATEGY.md` | Asset extraction strategy |
| `docs/dreamfus-phases.md` | Official phases and roadmap |
| `docs/research/` | Technical protocol research |
| `godot-client/README.md` | Godot client specific documentation |
| `godot-client/docs/PROTOCOL.md` | TCP/Protobuf protocol documentation |
| `godot-client/docs/TCP_HANDBSHAKE.md` | Detailed TCP handshake implementation |

---

## 🔌 Protocol Implementation

### SimpleProtocol (Port 5557) - WebSocket JSON

**Documentation:** `docs/SIMPLE-PROTOCOL-HOOKS.md`

**Authentication Flow:**
1. Connect WebSocket to `ws://localhost:5557`
2. Send `auth_request` with token
3. Receive `auth_response` with server list
4. Send `server_selection` with server_id
5. Receive `server_selection_response` with ticket
6. Connect to port 5555 with ticket

### Game Protocol (Port 5555) - Protobuf

**Documentation:** `godot-client/docs/TCP_HANDBSHAKE.md`

Key messages:
- `kqz` - Present ticket (client → server)
- `kra` - Acknowledgment (server → client)
- `kvi` - Character list (server → client) 
- `kvw` - Select character (client → server)
- `jtg` - End of welcome burst trigger (server → client)
- `+` lqu, hoy, kqu, mgq, mgt, hpd, krs, mgz, kqp - Welcome burst messages

**Character Data Fields (from kvi):**
- `id` (int64) - Character ID
- `name` (string) - Character name  
- `level` (int32) - Character level
- `sex` (int32) - Character sex (inside traits/f4)
- `breed` (int32) - Character breed (inside traits/f4)
- `look` (bytes) - Character appearance data (inside traits/f4)

**Important:** In the kvi protobuf structure, `look` (f6) and `breed` (f7) are nested inside the traits block (f4), not at the character level. The Godot client's `Proto.decode_kvi()` correctly handles this nesting.

---

## 🎯 Test Account

Use these credentials for testing:

```
Username: keka
Password: test
Account ID: 188940901
Server ID: 290 (DreamFus)
```

---

## 💻 Development

### Install Dependencies

```bash
cd frontend
npm install
```

### Development

```bash
# Frontend
cd frontend && npm run dev

# Build
cd frontend && npm run build

# Tauri (Rust backend)
cd .. && cargo build
```

### Run Tests

```bash
cargo test
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow `docs/CONTRIBUTING.md`
4. Submit a pull request

**Note:** This project is fan-made. No game assets are redistributed. Use placeholders or extract assets locally for development only.

---

## 🚫 Asset Policy

- **DO NOT** redistribute any ALDA or DreamFusion assets
- **DO NOT** commit extracted assets to this repository
- Extracted assets are for local development only

See `docs/ASSET-STRATEGY.md` for extraction guidelines.

---

## 📖 Additional Resources

- `docs/` - Full documentation
- `dreamfus-ui/` - UI specification
- `docs/research/` - Protocol research

---

*Last updated: November 2026*
*Version: 1.0*