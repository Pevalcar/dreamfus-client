# AGENTS.md — DreamFus Client

**Proyecto:** https://github.com/Pevalcar/dreamfus-client.git

**Estado actual:** Cliente Godot 4.8 exclusivo con MCP Runtime.

---

## Core Structure

| Piece | Path | Purpose |
|-------|------|---------|
| **Cliente Godot** | `godot-client/` | Cliente real en GDScript puro con MCP Runtime |
| **Documentación** | `docs/` | Documentación del proyecto |

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
| `docs/SIMPLE-PROTOCOL-HOOKS.md` | WebSocket JSON protocol (port 5557) |
| `godot-client/docs/PROTOCOL.md` | TCP/Protobuf protocol documentation |
| `godot-client/docs/TCP_HANDBSHAKE.md` | Detailed TCP handshake implementation |
| `docs/CONTRIBUTING.md` | How to contribute |
| `docs/IMPLEMENTATION-ROADMAP.md` | Implementation roadmap |
| `godot-client/src/Network/Proto.gd` | Protobuf serialization helpers |
| `godot-client/src/Network/GameClient.gd` | TCP game client implementation |
| `godot-client/src/Network/SimpleProtocolClient.gd` | WebSocket client |
| `godot-client/src/Core/GameManager.gd` | Game state & session management |

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
4. Cuando necesicies UI nueva, **entrega el árbol** con nombres, tipos, padres y propiedades.

---

## codebase-memory-mcp Rules (CRITICAL)

**Regla de oro**: NUNCA editar sin consultar el grafo primero.

### Antes de tocar cualquier archivo:
1. **Buscar símbolos**: `search_graph(name_pattern=".*NombreClase.*")` o `search_graph(name_pattern=".*NombreMetodo.*")`
2. **Rastrear relaciones**: `trace_path(function_name="NombreMetodo", direction="inbound")` para ver quién llama
3. **Obtener código fuente**: `get_code_snippet(qualified_name="ruta.al.símbolo")` para ver el código
4. **Verificar cobertura**: `check_index_coverage` con las rutas candidatas
5. **Consultar arquitectura**: `get_architecture` para resumen general

---

## Login Flow (verificado contra servidor)

1. `POST http://127.0.0.1:8888/api/entrar` con `{ "usuario": "...", "clave": "...", "ip": "127.0.0.1" }`
2. Respuesta OK: `{"bien":true,"token":"...","cuenta":12345,"apodo":"...","rol":0}`
3. WebSocket a `ws://127.0.0.1:5557` con `{ "type": "auth_request", "token": "...", "installId": "...", "lang": "es", "version": "3.6.10.10" }`
4. `auth_response` → `server_selection_request` → `server_selection_response` con ticket → TCP 5555

---

## Godot 4.8 Commands

```powershell
# Verify project loads
& "C:\Users\pevalcar\Godot\Godot.exe" --headless --path "godot-client" --quit
```

---

## Gotchas & Traps

- **MCP no está instalado** → No hay plugin Godot MCP. Verificar antes de instalar.
- **Cuenta de pruebas**: `keka` / `test`, ID `188940901`, servidor `290`
- Requiere servidor en `127.0.0.1:8888` (HTTP) + `127.0.0.1:5557` (WebSocket)
- Trabaja en ramas: `main`, `feature/wire-protocol-implementation`, `feature/hito-a-b-connection-session`
- **NO commitear directo en `main`**

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
| `openspec-propose` | Propose new changes with planning artifacts |
| `openspec-apply-change` | Apply accepted changes |

---

## Commands
- `npx skills use ponytail` - Activate lazy mode
- `npx skills use ponytail-review` - Review last change
- `npx skills use openspec-propose` - Propose new changes
- `npx skills use openspec-apply-change` - Apply accepted changes