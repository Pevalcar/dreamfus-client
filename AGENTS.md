# AGENTS.md — DreamFus Client

**Proyecto:** https://github.com/Pevalcar/dreamfus-client.git  
**Ruta local:** `C:\Users\pevalcar\Proyectos\jondo-servidor\DofusClient`

**Estado actual**: El proyecto se ha separado en **Godot solo**. El código Tauri/Rust ha sido eliminado pero se mantiene como referencia.

## Core Structure

| Piece | Path | Purpose |
|-------|------|---------|
| **Backend Tauri (Rust Library)** | `src/lib.rs` | Lógica de núcleo: estado de conexión, protocolo VarInt, parsing A2D **(REFERENCIA)** |
| **Backend Tauri (Binary)** | `src-tauri/main.rs` | Comandos Tauri originales **(ELIMINADO)** |
| **Frontend Vite** | `frontend/` | Prototipo WebGL investigativo **(NO USADO)** |
| **Cliente Godot** | `godot-client/` | Cliente real en GDScript puro con MCP Runtime |

### A2D Parsing (Avatar Rendering)

**Arquitectura actual**:
- **Rust (referencia)**: `src/lib.rs`, `src/a2d/mod.rs` - Parser completo con soporte deflate/WebP
- **GDScript (activo)**: `godot-client/src/A2D/A2DParser.gd` - Parser parcial sin soporte deflate
- **Python (offline)**: `src/a2d/convert_a2d.py` - Script de pre-procesamiento para conversión A2D.Z → WebP

**Límite actual**: Godot 4.8 no tiene soporte nativo para raw deflate en GDScript. Ver `docs/DEFLATE_SOLUTION.md` para opciones.

---

## Testing & Debugging

### Credentials
- **Username**: `keka`
- **Password**: `test`
- **AccountId**: `188940901`
- **ServerId**: `290`

### Connection Requirements
- **HTTP**: `127.0.0.1:8888/api/entrar` (login)
- **WebSocket**: `127.0.0.1:5557` (auth, server selection)
- **TCP Game**: `127.0.0.1:5555` (game connection)

---

## Key Documents

| Document | Purpose |
|----------|---------|
| `docs/GODOT_CLIENT_PROTOCOL.md` | Complete authentication protocol reference |
| `docs/IMPLEMENTATION_VERIFICATION.md` | Implementation check & risks |
| `src/Network/Proto.gd` | Protobuf serialization helpers |
| `src/Network/GameClient.gd` | TCP game client implementation |
| `src/Network/SimpleProtocolClient.gd` | WebSocket client |
| `src/Network/WorldProto.gd` | Message decoders |
| `src/Core/GameManager.gd` | Game state & session management |

**⚠️ El servidor está en `..\jondo-servidor`** (endpoint `/api/entrar`). Para dudas de protocolo, ver allí primero.

---

## Godot Rules (CRITICAL)

1. **Puedes editar `.tscn`, `project.godot`, `.uid`** usando el MCP con herramientas de graph manipulation. El MCP puede manejar estructuras de escena de forma segura sin corrupción.
2. **Sí puedes editar** código `.gd` libremente.
3. **Usa el MCP para**:
   - Verificar relaciones entre símbolos (`search_graph`, `trace_path`)
   - Obtener snippets de código exactos (`get_code_snippet`)
   - Verificar cobertura de índice (`check_index_coverage`)
   - Consultar la arquitectura general (`get_architecture`)
   - Realizar consultas complejas en Cypher (`query_graph`)
4. Cuando necesitest UI nueva, **entrega el árbol** con nombres, tipos, padres y propiedades.

```
Main (Node, script: Main.gd)
├── GameManager (Node, script: GameManager.gd)
├── WebSocketClient (Node, script: SimpleProtocolClient.gd)
├── LauncherContainer (CanvasLayer, layer=1)
├── CharacterSelectContainer (CanvasLayer, layer=2)
└── GameContainer (CanvasLayer, layer=3)
```

---

## codebase-memory-mcp Rules (CRITICAL)

**Regla de oro**: NUNCA editar sin consultar el grafo primero.

### Antes de tocar cualquier archivo:
1. **Buscar símbolos**: `search_graph(name_pattern=".*NombreClase.*")` o `search_graph(name_pattern=".*NombreMetodo.*")`
2. **Rastrear relaciones**: `trace_path(function_name="NombreMetodo", direction="inbound")` para ver quién llama
3. **Obtener código fuente**: `get_code_snippet(qualified_name="ruta.al.símbolo")` para ver el código
4. **Verificar cobertura**: `check_index_coverage` con las rutas candidatas
5. **Consultar arquitectura**: `get_architecture` para resumen general

### Niveles de confianza:
| Nivel | Cuándo usar | Qué permite afirmar |
|-------|-------------|---------------------|
| **Scout** | Orientarse, encontrar lo que existe | Que algo existe y dónde está |
| **Verify** | Antes de editar, confirmar afirmaciones | Que el código coincide con el grafo |
| **Auditor** | Revisiones completas antes de merge | Todo el alcance, con límites declarados |

### Regla de oro (MCP):
Si una afirmación depende de que algo NO esté en el código, hay que comprobarlo con `check_index_coverage` y búsqueda de texto (`grep`), porque el grafo puede tener huecos.

### Herramientas MCP disponibles:
- `search_graph` - Buscar clases y métodos por nombre
- `trace_path` - Ver quien llama a un método y a qué llama  
- `get_code_snippet` - Leer código exacto de un símbolo
- `get_file_outline` - Ver esqueleto de un fichero
- `query_graph` - Preguntas libres en Cypher sobre el grafo
- `get_architecture` - Resumen del proyecto
- `search_code` - Buscar texto literal
- `check_index_coverage` - Verificar si el índice cubrió un fichero
- `compare_graphs` - Comparar dos versiones indexadas
- `index_status` - Estado del índice

---

## Login Flow (verificado contra servidor)

1. `POST http://127.0.0.1:8888/api/entrar` con `{ "usuario": "...", "clave": "...", "ip": "127.0.0.1" }`
2. Respuesta OK: `{"bien":true,"token":"...","cuenta":12345,"apodo":"...","rol":0}`
3. WebSocket a `ws://127.0.0.1:5557` con `{ "type": "auth_request", "token": "...", "installId": "...", "lang": "es", "version": "3.6.10.10" }`
4. `auth_response` → `server_selection_request` → `server_selection_response` con ticket → TCP 5555

---

## Key Commands

### Godot 4.8
```powershell
$godot = "C:\Users\pevalcar\Godot\Godot.exe"
$project = "C:\Users\pevalcar\Proyectos\jondo-servidor\DofusClient\godot-client"
& $godot --headless --path $project --quit  # Verify project loads
```

### Frontend (Vite)
```powershell
cd frontend
bun run dev   # o npm run dev
bun run build # salida a ../dist (gitignored)
```

### Tauri Backend
```powershell
cargo check   # Check compiles
cargo build   # Build
```

---

## Gotchas & Traps

- **MCP no está instalado** → No hay plugin Godot MCP. Verificar antes de instalar.
- `.gitignore` ignora `docs/`, `src-tauri/`, `gen/`, `.agents/`, `Cargo.lock`, `dist/`
- **Cuenta de pruebas**: `keka` / `test`, ID `188940901`, servidor `290`
- Requiere servidor en `127.0.0.1:8888` (HTTP) + `127.0.0.1:5557` (WebSocket)
- Trabaja en ramas: `main`, `feature/wire-protocol-implementation`, `feature/hito-a-b-connection-session`
- **NO commitear directo en `main`**

---

## Ponytail Rules (Lazy Senior Dev Mode)

Activa Ponytail para resolver tareas con el cambio más pequeño que funcione completamente. Reglas clave:

1. **El mejor código es el que nunca se escribe** - Usa helpers, componentes o patrones existentes
2. **Una línea que funciona = mejor que 100 líneas de "y ahora"** - Prioriza simplicidad
3. **No añadir dependencias por unas cuantas líneas** - Usa lo que ya tienes
4. **La estructura existente = estructura correcta** - No inventes capas nuevas sin requerimiento explícito
5. **Cada shortcut conocido recibe un comentario**: `shortcut: <límite>, <cuándo actualizar>`

### Niveles de Ponytail
- **lite**: Nombra la opción más pequeña y deja que el usuario elija
- **full** (default): Aplica todas las reglas de arriba
- **ultra**: Además, cuestiona si la tarea justifica cada parte pedida

### Aplicación en este proyecto
- Código Godot: Usa patrones de `GameClient.gd`, `Proto.gd`, `Main.gd` sin añadir abstracciones
- Protocolo: Usa estructuras de `GameMessage` proto existentes
- UI: Usa componentes dentro de `LauncherContainer`, `CharacterSelectContainer`, `GameContainer`

---

## Installed Skills

| Skill | Purpose |
|-------|---------|
| `ponytail` | Lazy senior dev mode - smallest change that works |
| `ponytail-audit` | Full repo audit for bugs, security, bloat |
| `ponytail-debt` | Track and list all `shortcut:` comments |
| `ponytail-gain` | Measure code/cost/speed savings |
| `ponytail-help` | Quick reference for Ponytail usage |
| `ponytail-review` | Quality review of changes |

## Commands
- `npx skills use ponytail` - Activate lazy mode
- `npx skills use ponytail-review` - Review last change
- etc.