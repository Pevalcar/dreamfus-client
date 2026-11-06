# DreamFus Client - Project Rules

## 📖 Overview

This project is a Dofus 3 client alternative built with **Godot 4.8** using GDScript only. 

**Architecture Principle**: Godot client connects directly to JondoEmu server via WebSocket (port 5557) and TCP (port 5555). No Tauri/backend bridge - pure Godot engine.

---

## ⚖️ Core Rules

### 1. Architecture Separation

- **Server code**: Maintained in [`Keka-Bron/JondoEmu`](https://github.com/Keka-Bron/JondoEmu)
- **Client code**: This repository (`DreamFusClient`)
- **Never mix**: Server-side changes belong in the server repository
- **Protocol handlers**: Implemented as hooks in server's `Jondo.Unity.Server/Custom/`

### 2. Codebase Integrity

- **No hardcoded credentials** in any file
- **No game data** (player accounts, session data, network logs) in commits
- **No asset files** (images, sprites, audio) - loaded from Alea installation at runtime
- **No compiled binaries** - only source code and configuration

### 3. Development Workflow

```
1. Create feature branch: `git checkout -b feature/name`
2. Make changes following coding standards
3. Test in Godot 4.8
4. Commit with clear message
5. Push and create PR to `main`
```

---

## 🧩 Adding New Features

### Client-Side (Godot/GDScript)

1. **UI Features**:
   - Use existing DFUI patterns from actual Dofus client
   - Create scenes in `godot-client/scenes/`
   - Scripts in `godot-client/src/UI/`
   - Test in actual game context

2. **Protocol Extensions**:
   - Server-side hooks go in `Jondo.Unity.Server/Custom/`
   - Declare hooks in `CustomHooks.cs`
   - Inject minimal hook calls (1-2 lines) in server core
   - Implement handlers in `Custom/` modules

3. **Data Files**:
   - New data goes in new tables (never modify upstream schema)
   - Persist by real UID/owner (no global state mixing players)

### File Organization

```
godot-client/
├── scenes/           # Scene files (.tscn)
├── src/
│   ├── Core/         # Entry point, state management
│   ├── Network/      # WebSockets, protocol handlers
│   ├── UI/           # Interface components
│   ├── Data/         # Data classes
│   └── A2D/          # Avatar parsing (future)
├── assets/           # Loaded from Alea at runtime
└── docs/             # Godot-specific documentation
```

---

## 📝 Code Standards

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | `snake_case` | `game_manager.gd` |
| Classes | `PascalCase` | `GameManager` |
| Variables | `snake_case` or `camelCase` | `player_name` or `playerName` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_CONNECTIONS` |
| Autoloads | `PascalCase` | `EventManager` |

### GDScript Guidelines

- Use **strict typing** for Godot 4.8 compatibility
- Prefer `class_name` for exported classes
- Use `@export` for exposed properties
- Document with `#` comments

```gdscript
# Good example
class_name DataManager
extends Node

const MAX_PLAYERS := 100

var players: Array[Player] = []

func add_player(player: Player) -> void:
	"""Add player to active players list."""
	players.append(player)
```

---

## 🧪 Testing Requirements

### Before Any PR Merge

- [ ] Godot project loads without errors
- [ ] Scripts compile with no warnings
- [ ] Scenes open correctly in editor
- [ ] UI appears correctly (not overlapping map)
- [ ] Click events don't propagate to game map
- [ ] Features only visible during gameplay
- [ ] No console errors in debug mode
- [ ] Tested with live server (credentials: `keka/test`)

### Verification Flow

```bash
# Check project loads
godot --headless --path godot-client --quit

# Verify syntax (optional)
godot --headless --path godot-client --check-only --script res://src/Core/Main.gd
```

---

## 🚨 Prohibited Actions

1. **Never** modify server core for new features
2. **Never** commit game assets or resources
3. **Never** hardcode asset paths (use `ProjectSettings` or `ResourceLoader`)
4. **Never** include player data in commits
5. **Never** break existing functionality without documentation

---

## 🔐 Security & Privacy

### Credential Management

- Test credentials belong in documentation only: `keka/test`
- No real player accounts or data in repository
- No session tokens or connection logs

### Data Protection

- Save files use real owner UID
- No global state shared between players
- Player progress persists per account

---

## 📚 Resources

- **Protocol**: `docs/SIMPLE-PROTOCOL-HOOKS.md`
- **UI Patterns**: `docs/UI-CLIENTE.md`
- **Contributing**: `docs/CONTRIBUTING.md`
- **MCP Tooling**: `npm install -g @npgamedev/godot-mcp-server@1.1.2`

---

*Rules last updated: November 2026*