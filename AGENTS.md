# AGENTS.md — DreamFus Client

**Proyecto:** https://github.com/Pevalcar/dreamfus-client.git
**Ruta local:** `C:\Users\pevalcar\Proyects\jondo-servidor\DofusClient`

Cliente alternativo de Dofus. En el repo conviven tres piezas independientes:

| Pieza | Ruta | Qué es |
|---|---|---|
| Backend Tauri (Rust) | `src/lib.rs` (+ `src-tauri/main.rs`, `build.rs`, `Cargo.toml`) | Comandos `connect_auth` / `connect_game` / `send_game_message` / `disconnect`. Framing VarInt + envelope, TCP 5555 |
| Frontend Vite (JS) | `frontend/` | Prototipo WebGL + DFUI donde se investigó el protocolo. **No** es el cliente final |
| Cliente Godot 4.8 | `godot-client/` | Cliente real, GDScript puro. `project.godot` → `run/main_scene="res://scenes/Main.tscn"` |

El **servidor no está en este repo**: vive en `..\jondo-servidor` (ahí está el endpoint
`/api/entrar` en `Jondo.Unity.Studio\ServerSettingsService.cs`). Si una duda es de protocolo,
la respuesta de verdad está en el servidor, no en la documentación de este repo.

---

## Regla nº1 — las escenas `.tscn` las crea y edita el programador, NUNCA el agente

Modificar una `.tscn` a mano tiene **alto peligro de corromperla**: el formato de Godot 4.8
lleva `unique_id=` por nodo, UIDs de recursos y orden de propiedades; un `edit` de texto deja la
escena rota y el editor ya no sabe abrirla igual. Ya pasó (commit `a3ba442`) y hubo que revertir
`Launcher.tscn` y `LauncherUI.gd` a `163dd7f`.

Por tanto:

- **Prohibido** crear, editar o "arreglar un poquito" cualquier `.tscn`, también `project.godot`
  y los `.uid`.
- **Sí** se escribe y edita el código `.gd` sin problema.
- Cuando una interfaz nueva necesite nodos, el agente **entrega el árbol** con nombres, tipos,
  padre y propiedades, y el programador lo monta en el editor de Godot.
- Antes de dar el árbol, decir explícitamente: "esto lo tienes que añadir tú en el editor".

### Formato obligatorio para pedir nodos

Siempre en árbol, con el tipo y el script, no en prosa ni volcando un `.tscn` entero:

```
Main (Node, script: Main.gd)
├── GameManager (Node, script: GameManager.gd)
├── WebSocketClient (Node, script: SimpleProtocolClient.gd)
├── LauncherContainer (CanvasLayer, layer=1)
├── CharacterSelectContainer (CanvasLayer, layer=2)
└── GameContainer (CanvasLayer, layer=3)
```

Debajo del árbol, la tabla de propiedades no obvias (`secret = true`, `placeholder_text`,
`max_value`, `visible = false`, `unique_id` no se toca) y **la ruta exacta que usará el script**
(`$VBoxContainer/UsernameEntry`). Esa ruta es el contrato: si el programador cambia un nombre,
el `@onready` deja de encontrarlo.

---

## Flujo de login (verificado contra servidor y contra `src/lib.rs`)

El launcher pide **usuario y contraseña**, no un token a mano:

1. `POST http://127.0.0.1:8888/api/entrar`, `Content-Type: application/json`
   ```json
   { "usuario": "keka", "clave": "test", "ip": "127.0.0.1" }
   ```
   El campo `ip` lo manda el servidor de referencia; el endpoint lo acepta.
2. Respuesta OK: `{"bien":true,"token":"...","cuenta":188940901,"apodo":"...","rol":0}`.
   Fallo: `{"bien":false,"motivo":"..."}` — el mensaje de error está en **`motivo`**, no en `error`.
3. WebSocket a `ws://127.0.0.1:5557` y enviar:
   ```json
   { "type": "auth_request", "token": "...", "installId": "...", "lang": "es", "version": "3.6.10.10" }
   ```
4. `auth_response` → `{ "success": true, "account_id": 188940901, "servers": [...] }`.
5. `server_selection_request` → `server_selection_response` con `ticket` → TCP 5555 con el ticket.

Detalles que se dan por sabidos y no lo son:

- El token de `/api/entrar` es **el mismo** que acepta el WS: ambos usan el registro
  `ClientLaunchRegistry`. No hay que convertir nada.
- El servidor **no exige `version`** (`SimpleProtocol\AuthHandlers.LoginAsync(token, installId)`),
  pero la referencia manda `3.6.10.10`; mandarla evita sorpresas.
- El servidor responde en frames WebSocket **binarios**, con prefijo de longitud de 4 bytes
  big-endian + JSON UTF-8. `SimpleProtocolClient.gd` ya lo hace.
- `src/lib.rs` **no** hace el login HTTP: `connect_auth` recibe un token ya obtenido. El HTTP es
  cosa del cliente (Godot o `frontend/`), no del backend Tauri.

### Qué falta en `Launcher.tscn` para ese login

Estado actual: la escena tiene `TokenEntry` (token manual) y `LauncherUI.gd` pide token. Para
pasarlo a usuario/contraseña, el programador añade dentro de `VBoxContainer` (en este orden,
entre `ConnectionProgress` y `ConnectButton`) y un `HTTPRequest` como hijo de `Launcher`:

```
Launcher (Control, script: LauncherUI.gd)
├── HTTPRequest (HTTPRequest)              ← nuevo, hijo directo de Launcher
└── VBoxContainer (VBoxContainer)
    ├── TitleLabel (Label)
    ├── VersionLabel (Label)
    ├── StatusLabel (Label)
    ├── ConnectionProgress (ProgressBar, visible=false)
    ├── UsernameLabel (Label, text="Usuario:")        ← nuevo
    ├── UsernameEntry (LineEdit, placeholder="Usuario") ← nuevo
    ├── PasswordLabel (Label, text="Contraseña:")     ← nuevo
    ├── PasswordEntry (LineEdit, secret=true, placeholder="Contraseña") ← nuevo
    ├── TokenEntry (LineEdit)              ← se puede quitar cuando el HTTP funcione
    ├── ConnectButton (Button, text="Conectar")
    ├── LangLabel (Label)
    ├── LangOption (OptionButton)          ← sin items; el script los añade
    ├── InstallIdLabel (Label)
    └── ServerConfig (VBoxContainer)
        ├── ServerHostLabel / ServerHostEntry
        └── ServerPortLabel / ServerPortSpin
```

---

## Estructura de escenas (estado actual, para no inventarse rutas)

```
Main.tscn
Main (Node, script: Main.gd)
├── GameManager (Node, script: GameManager.gd)
├── WebSocketClient (Node, script: SimpleProtocolClient.gd)
├── LauncherContainer (CanvasLayer, layer=1)
├── CharacterSelectContainer (CanvasLayer, layer=2)
└── GameContainer (CanvasLayer, layer=3)
```

`Main.gd` instancia `Launcher.tscn`, `CharacterSelect.tscn` y `Game.tscn` con `preload` y las
mete en su `CanvasLayer`. Ojo: las tres escenas existen **una sola vez** en la escena principal y
se muestran/ocultan con `visible`; no se recargan.

---

## Comandos

Godot (`C:\Users\pevalcar\Godot\Godot.exe`, v4.8.beta2.mono — build mono, pero el proyecto es
GDScript puro: si aparece `[dotnet]` en `project.godot`, es una regresión).

```powershell
$godot = "C:\Users\pevalcar\Godot\Godot.exe"
$project = "C:\Users\pevalcar\Proyects\jondo-servidor\DofusClient\godot-client"

# Arranque real: instancia Main.tscn y canta los errores de runtime. Esta es la verificación buena.
& $godot --headless --path $project --quit

# Parsear un solo script (--check-only NO sirve sin --script)
& $godot --headless --path $project --check-only --script res://src/Core/Main.gd
```

PowerShell: usar `& $godot ...` con variables; **`&&` no existe** en esta consola. Godot es un
ejecutable GUI, así que `$LASTEXITCODE` puede salir vacío y su stderr aparece como
`NativeCommandError`: lo que cuenta son las líneas `ERROR:` / `SCRIPT ERROR:` de la salida.

Frontend y Tauri:

```powershell
cd frontend; bun run dev      # bun.lock está versionado en local; también vale npm run dev
cd frontend; bun run build    # sale a ..\dist (gitignored)
cargo check                   # backend Tauri
```

### Verificación conocida (no es un fallo tuyo)

`& $godot --headless --path $project --quit` sale con error y esto:

```
ERROR: Index p_which = 1 is out of bounds (popup->get_item_count() = 0).
  at: LauncherUI.gd:32  (_setup_defaults -> lang_option.select(1))
```

`LangOption` no tiene items y `select(1)` revienta. Arreglarlo cuando se toque `LauncherUI.gd`
(añadir items en `_setup_defaults`). Además ese script emite `lang` como `int` aunque la señal
`auth_requested` lo declara `String`.

---

## Trampas del repo

- `.gitignore` ignora `docs/`, `src-tauri/`, `gen/`, `.agents/`, `Cargo.lock`, `dist/`.
  **Cualquier doc nueva en `docs/` (o `godot-client/docs/`) desaparece en silencio**: hay que
  `git add -f <archivo>`. `docs/research/` ya está trackeado y sí se ve en `git status`.
- `godot-client/docs/PROTOCOL.md` y `godot-client/docs/TCP_HANDBSHAKE.md` son la documentación
  del protocolo completo (WebSocket y TCP).
- `docs/IMPLEMENTATION-ROADMAP.md` y `docs/CONTRIBUTING.md` hablan de **.NET 10 y del servidor**
  (`dotnet build Jondo.Unity.Server/...`). Aquí no aplica: este repo no tiene solución .NET.
- Godot 4.8 beta2 no dispara de forma fiable las señales de `WebSocketPeer`: hay que sondear
  `get_ready_state()` desde `_process` (así está en `SimpleProtocolClient.gd`). No volver a
  conectar `connection_established` / `connection_closed`.
- No reintroducir addons de editor ni C# en `godot-client/` (el addon `godot_mcp` se eliminó).
- Cuenta de pruebas: `keka` / `test`, cuenta `188940901`, servidor `290`. Hace falta el servidor
  levantado en `127.0.0.1` con HTTP 8888 y WS 5557.
- Trabajo en rama por tarea; el repo tiene `main`, `feature/wire-protocol-implementation`
  (la que marca `origin/HEAD`), `feature/hito-a-b-connection-session` y `docs/client-research`.
  No commitear directo en `main`.
- Skills del proyecto en `.opencode/skills/dofus-*` (protocolo, combate, UI, assets): cargarlas
  con la herramienta `skill` antes de tocar esas áreas.
- Skill de reglas estrictas Godot: **`godot-strict-rules`** (cargar con `skill id=godot-strict-rules`)
  antes de escribir cualquier GDScript. Contiene:
  - Prohibido editar `.tscn` manualmente
  - Tipado estricto de arrays (`Array()` vs `[]`, `Array[Dictionary]`, etc.)
  - Verificación automática con `--check-only` después de cada cambio
  - Script de verificación global: `.\scripts\Verify-GodotProject.ps1`

## Skills globales de Godot (`.agents/skills/`) — Cargar según necesidad

Instaladas vía `npx skills add thedivergentai/gd-agentic-skills`. ~92 skills especializadas.

**Entry point obligatorio para arquitectura general:**
```bash
skill id=godot-master
```
Orquesta todos los domain skills. Usar **siempre** antes de decisiones de arquitectura, workflows o elegir qué skills cargar.

**Skills Godot comúnmente usadas en este proyecto:**

| Área | Skill | Cuándo cargar |
|------|-------|---------------|
| **Arquitectura base** | `godot-master` | Inicio de sesión, decisiones de arquitectura, flujo de trabajo |
| **Fundamentos proyecto** | `godot-project-foundations` | Nuevo proyecto, organización carpetas, .gitignore |
| **GDScript experto** | `godot-gdscript-mastery` | Revisión código, hot paths, estándares |
| **Composición (ECS)** | `godot-composition` | Entidades gameplay (Player, Enemy, Weapon) |
| **Autoloads/Singletons** | `godot-autoload-architecture` | GameManager, SignalBus, SaveManager |
| **Señales** | `godot-signal-architecture` | Desacoplamiento, event bus |
| **Estado máquinas** | `godot-state-machine-advanced` | AI compleja, comportamiento en capas |
| **Multiplayer** | `godot-multiplayer-networking` | Desync, rollback, servidores headless |
| **Servidor dedicado** | `godot-server-architecture` | Host autoritativo, ENet/DTLS |
| **Personaje 2D** | `godot-characterbody-2d` | Movimiento platformer, coyote time, jump buffer |
| **Física 2D** | `godot-2d-physics` | Colisiones, raycasting, Area2D triggers |
| **TileMap/Level** | `godot-tilemap-mastery` | Niveles grid-based, autotiling |
| **UI Contenedores** | `godot-ui-containers` | Layouts responsivos, HBox/VBox/Grid/Flow |
| **UI Temas** | `godot-ui-theming` | Temas consistentes, dark mode, fuentes |
| **RichText/BBCode** | `godot-ui-rich-text` | Diálogos, formato texto, enlaces |
| **Tweening/Juice** | `godot-tweening` | Animaciones UI, movimiento procedural |
| **Persistencia** | `godot-save-load-systems` | JSON/binario, versionado, migración |
| **Recursos/Datos** | `godot-resource-data-patterns` | Bases de datos items, stats, diálogos |
| **Stats RPG** | `godot-rpg-stats` | Atributos, nivelado, modificadores, daño |
| **Inventario** | `godot-inventory-system` | Slots, stacking, peso, equipamiento |
| **Combate** | `godot-combat-system` | Hitbox/hurtbox, daño, combos, cooldowns |
| **Habilidades** | `godot-ability-system` | Cooldowns, árboles skills, combos |
| **Misiones** | `godot-quest-system` | Objetivos, progreso, recompensas, cadenas |
| **Partículas/VFX** | `godot-particles` | GPUParticles, gradientes, sub-emisores |
| **Cámaras** | `godot-camera-systems` | Follow suave, shake, look-ahead, transiciones |
| **Animación** | `godot-animation-tree-mastery` | StateMachine, BlendSpace2D, root motion |
| **Audio** | `godot-audio-systems` | Buses, efectos, music crossfade, pooling |
| **Navegación/Pathfinding** | `godot-navigation-pathfinding` | NavigationAgent, avoidance, baking dinámico |
| **Raycasting** | `godot-raycasting-queries` | Proyectiles, LOS, mouse picking |
| **Optimización** | `godot-performance-optimization` | Profiling, object pooling, culling, draw calls |
| **Debug/Profiling** | `godot-debugging-profiling` | Leaks, GPU profiler, headless CI, orphan nodes |
| **Testing** | `godot-testing-patterns` | GdUnit4, unit/scene/CI, mock networks |
| **Export/Build** | `godot-export-builds` | Multi-plataforma, CI/CD, feature flags |
| **Plataforma Web** | `godot-platform-web` | HTML5/WebGL, JavaScriptBridge, localStorage |
| **Plataforma Mobile** | `godot-platform-mobile` | Touch, joystick virtual, safe areas, battery |
| **Plataforma Desktop** | `godot-platform-desktop` | Keybinds, settings, fullscreen, Steam |
| **Procedural** | `godot-procedural-generation` | Dungeons, terreno, loot, FastNoiseLite |
| **Versión/Migración** | `godot-version-migration` | Upgrade Godot 3→4, 4.x hops |
| **Shaders** | `godot-shaders-basics` | Hitflash, alpha-scissor, postFX, instance uniforms |

**Flujo recomendado:**
1. `skill id=godot-master` → Lee la "Decision Matrix" (Parte 2) → Identifica workflow
2. Carga la cadena de skills MANDATORIA del workflow (ej: Composition → State Machine → CharacterBody2D)
3. **NO cargues skills de género/plataforma innecesarios** — solo lo que toca el workflow actual

**Ejemplo para cliente Dofus (Action RPG 2D multiplayer):**
```bash
skill id=godot-master           # Arquitectura
skill id=godot-composition      # Entidades (Player, NPC, Monster)
skill id=godot-characterbody-2d # Movimiento
skill id=godot-multiplayer-networking # Red
skill id=godot-rpg-stats        # Stats, nivelado
skill id=godot-combat-system    # Combate hitbox
skill id=godot-inventory-system # Inventario
skill id=godot-ui-containers    # UI responsiva
```
