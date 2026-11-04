# Contributing to DreamFus Client

## 🌐 Project Architecture

This project (DreamFus Client) is an **alternative Dofus 3 client built with Godot 4.8** (GDScript only).

This project works with two external components:

| Component | Repository | Website / Download |
|-----------|------------|-------------------|
| **Server** (JondoEmu) | https://github.com/Keka-Bron/JondoEmu | - |
| **Alea Client** | - | https://aleaonline.com/download |
| **Game Assets** | Local installation | `C:/Users/<tu-usuario>/AppData/Local/Alea/` |

### Prerequisites

**Alea Client Requirements:**
- Download Alea client from: https://aleaonline.com/download (version 3.6.10.10 or 3.6.10.11)
- Assets are loaded from local Alea installation, NOT stored in project folder
- Breed emblems: `C:/Users/<tu-usuario>/AppData/Local/Alea/d3picto/hint/{10,20,...,160}.png`

**Godot Requirements:**
- Godot Engine 4.8+ (GDScript project)
- No C#/Tauri/TypeScript in this repository - those belong to separate projects

---

## 📋 Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Develop

**Client-side (GDScript for Godot 4.8):**
- Project root: `godot-client/`
- Main scene: `godot-client/scenes/Main.tscn`
- Scripts: `godot-client/src/`
  - `Core/Main.gd` - Entry point
  - `Core/GameManager.gd` - Game state management
  - `Network/SimpleProtocolClient.gd` - WebSocket client
  - `UI/LauncherUI.gd` - Login interface

### 3. Test

```bash
# Run Godot in headless mode (Godot 4.8 required)
"C:\Users\<tu-usuario>\Godot\Godot.exe" --headless --path godot-client --quit
```

### 4. Commit and Push

```bash
git add .
git commit -m "feat: clear description of what was added"
git push origin feature/your-feature-name
```

### 5. Pull Request

Create a Pull Request to `origin/main` with:
- Clear description in plain language
- Screenshots if UI-related
- Verification steps
- Technical details
- Test results

---

## 🏗️ Project Architecture

### Client Architecture (Godot 4.8 / GDScript)

```
godot-client/
├── project.godot           # Godot project file
├── scenes/
│   ├── Main.tscn         # Main scene (entry point)
│   ├── Launcher.tscn     # Login screen
│   ├── CharacterSelect.tscn  # Character selection
│   └── Game.tscn         # In-game scene
├── src/
│   ├── Core/
│   │   ├── Main.gd       # Main node
│   │   ├── GameManager.gd  # Game state
│   │   └── SceneManager.gd # Scene transitions
│   ├── Network/
│   │   ├── SimpleProtocolClient.gd  # WebSocket client
│   │   └── GameClient.gd   # Game protocol handler
│   └── UI/
│       ├── LauncherUI.gd
│       ├── CharacterSelectUI.gd
│       └── GameUI.gd
└── assets/               # Game assets (loaded from Alea)
```

---

## 🔌 Protocol Guide

### SimpleProtocol (Port 5557) - WebSocket JSON

**Documentation:** `docs/SIMPLE-PROTOCOL-HOOKS.md`

**Authentication Flow:**
1. Connect WebSocket to `ws://localhost:5557`
2. Send `auth_request` with token
3. Receive `auth_response` with server list
4. Send `server_selection` with server_id
5. Receive `server_selection_response` with ticket
6. Connect to port 5555 with ticket

**Message Format:**
```
[4-byte big-endian length][UTF-8 JSON payload]
```

**Example Auth Request:**
```json
{
  "type": "auth_request",
  "token": "your-token",
  "installId": "client-id",
  "lang": "en",
  "version": "3.6.10.10"
}
```

### Game Protocol (Port 5555) - Protobuf

Key messages:
- `krt` - Hello (initial connection)
- `kuf` - Server hello (response)
- `kvi` - Character list
- `kvw` - Select character
- `kqz` - Present ticket
- `hpd` - Position updates

---

## 🧪 Testing

### Test Account

**Development credentials:**
```
Username: keka
Password: test
Account ID: 188940901
Server ID: 290 (DreamFus)
```

### Running Godot Tests

```bash
# Run Godot in headless mode
"C:\Users\<tu-usuario>\Godot\Godot.exe" --headless --path godot-client --quit

# Check script syntax
"C:\Users\<tu-usuario>\Godot\Godot.exe" --headless --path godot-client --check-only --script res://src/Core/Main.gd
```

---

## 🧩 Adding New Features

### Client-Side UI Pattern

Follow the DFUI (Dofus UI Framework) pattern:

```gdscript
# 1. Use existing DFUI templates in godot-client/ui/
# 2. Create script in godot-client/src/
# 3. Register UI events through UIManager singleton
```

### Protocol Extensions

Client protocol handlers are in `godot-client/src/Network/`. Use the hook pattern:

```gdscript
# Example: Adding a new server message handler
func _init():
    EventBus.register_message_handler("customMessage", _handle_custom_message)

func _handle_custom_message(message: Dictionary) -> void:
    # Process message and update UI
    pass
```

### Custom Server Hooks (Server-side)

The server (JondoEmu) supports custom hooks for extending functionality. See:
- Server repository: https://github.com/Keka-Bron/JondoEmu
- Server custom hooks: `Jondo.Unity.Server/Custom/`

---

## 🎨 UI Development Guidelines

### Adding a New Screen

1. Create scene in `godot-client/scenes/`
2. Create script in `godot-client/src/`
3. Register with SceneManager
4. Test in actual game client

### UI Components

- Use `CanvasLayer` for UI overlays
- Use `Control` nodes with proper anchors
- Handle input events with `gui_input(event)`
- Follow DFUI patterns for Dofus-style interfaces

---

## 📝 Coding Standards

1. **Naming Conventions**
   - Files: `snake_case.gd`
   - Classes: `PascalCase`
   - Variables: `snake_case` or `camelCase`
   - Constants: `SCREAMING_SNAKE_CASE`

2. **Code Organization**
   - All scripts in `godot-client/src/`
   - Separate by `Core/`, `Network/`, `UI/`, `Data/`
   - Use autoloads for global managers

3. **Documentation**
   - GDScript comments with `#`
   - Update this file when adding new patterns

4. **Testing**
   - Run Godot headless after changes
   - Verify UI appears correctly
   - Test click events propagate correctly

---

## 🚨 What NOT to Do

1. ❌ **Never modify server code** (that's in JondoEmu repo)
2. ❌ **Never edit .tscn files manually** - use Godot editor
3. ❌ **Never hardcode asset paths** - use `ProjectSettings` or `ResourceLoader`
4. ❌ **Never skip testing** - verify in actual game client
5. ❌ **Never break existing functionality** without documentation

---

## 🔍 Testing in Game

### Verification Checklist

Before submitting a PR, ensure:

- [ ] Code runs without errors in Godot 4.8
- [ ] Scene loads correctly
- [ ] UI appears correctly (no overlap with map)
- [ ] Click events don't propagate to map
- [ ] UI is draggable/movable
- [ ] Feature only shows during gameplay
- [ ] No console errors in debug mode
- [ ] Tested with live server connection

---

## 📖 Resources

- Protocol Documentation: `docs/SIMPLE-PROTOCOL-HOOKS.md`
- UI Guidelines: `docs/UI-CLIENTE.md`
- Server (JondoEmu): https://github.com/Keka-Bron/JondoEmu
- Alea Client Download: https://aleaonline.com/download

---

## 🤝 Contributing to the Server

The server uses custom hooks for extensions. See:
- Server repository: https://github.com/Keka-Bron/JondoEmu
- Server custom hooks: `Jondo.Unity.Server/Custom/Core/CustomHooks.cs`

To add server-side hooks:
1. Declare event in `CustomHooks.cs`
2. Inject hook call (1-2 lines max) in server core
3. Register handler in `CustomBootstrapper.cs`
4. Implement handler in `Custom/TuModulo/`
5. Document in server's `docs/CUSTOM-HOOKS.md`

---

## 📬 Contact

- **GitHub Issues**: For bugs and feature requests
- **Discord**: Team DreamFus channel
- **Pull Requests**: Submit to `origin/main`

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the project's license terms.

---

*Last updated: November 2026*
*Version: 2.0*