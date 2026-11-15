# DreamFus Client

> **Cliente Godot 4.8 alternativo para Dofus con MCP Runtime**
>
> **Proyecto:** https://github.com/Pevalcar/dreamfus-client.git

> **Golden Rule:** DreamFus Client is a fan-made project that reimplements Dofus mechanics, visuals, animations, and interfaces from scratch using freely usable assets and temporary placeholders.

---

## 🎯 Purpose

Create an alternative client that:
- **Mechanics:** Reimplements the Jondo protocol from scratch
- **Visuals:** Uses the same visual style as the original game
- **Animations:** Implements custom animation systems in Dofus style
- **Interface:** Follows the DreamFus UI specification (documented in `dreamfus-ui/`)

---

## 📁 Project Structure

```
dreamfus-client/
├── godot-client/              # Godot 4.8 client (active)
│   ├── src/                   # GDScript game logic
│   ├── scenes/                # Godot scenes
│   └── docs/                  # Protocol documentation
│
├── addons/                    # Godot addons
│
├── docs/                      # Project documentation
│   ├── IMPLEMENTATION-ROADMAP.md
│   ├── SIMPLE-PROTOCOL-HOOKS.md
│   └── CONSTRIBUTING.md
│
└── .pi/                       # Pi configuration
```

---

## 📊 Implementation Status

### ✅ Complete

| Component | Location | Status |
|-----------|----------|--------|
| **WebSocket Client** | `godot-client/src/Network/SimpleProtocolClient.gd` | ✅ Complete |
| **TCP Game Client** | `godot-client/src/Network/GameClient.gd` | ✅ Complete |
| **Protobuf Utilities** | `godot-client/src/Network/Proto.gd` | ✅ Complete |
| **Game Manager** | `godot-client/src/Core/GameManager.gd` | ✅ Complete |
| **Character Select UI** | `godot-client/src/UI/CharacterSelectUI.gd` | ✅ Complete |

### 🚧 In Progress / Pending

| Component | Location | Status | Notes |
|-----------|----------|--------|-------|
| **World Rendering** | `godot-client/` | ⏳ Planned | World rendering, gameplay systems |
| **A2D Avatar Parsing** | `godot-client/src/A2D/` | ⏳ Planned | Avatar rendering system |

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `docs/SIMPLE-PROTOCOL-HOOKS.md` | WebSocket JSON protocol (port 5557) |
| `godot-client/docs/PROTOCOL.md` | TCP/Protobuf protocol documentation |
| `godot-client/docs/TCP_HANDBSHAKE.md` | Detailed TCP handshake implementation |
| `docs/CONTRIBUTING.md` | How to contribute |
| `docs/IMPLEMENTATION-ROADMAP.md` | Implementation roadmap |

---

## 🔌 Protocol Implementation

### SimpleProtocol (Port 5557) - WebSocket JSON
**Documentation:** `docs/SIMPLE-PROTOCOL-HOOKS.md`

### Game Protocol (Port 5555) - Protobuf
**Documentation:** `godot-client/docs/PROTOCOL.md`

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

### Godot 4.8

```powershell
# Verify project loads
& "C:\Users\pevalcar\Godot\Godot.exe" --headless --path "godot-client" --quit
```

### Build

Open the project in Godot 4.8 and build normally.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow `docs/CONTRIBUTING.md`
4. Submit a pull request

---

## 🚫 Asset Policy

- **DO NOT** redistribute any game assets
- **DO NOT** commit extracted assets to this repository
- Extracted assets are for local development only

---

*Version: 1.0*