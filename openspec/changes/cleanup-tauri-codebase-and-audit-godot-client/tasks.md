# Tasks

## 1. Protocol Audit - Compare Tauri vs Godot Implementation

- [x] 1.1 Audit Tauri WebSocket auth flow - compare `src/lib.rs` auth_request/server_selection with Godot `SimpleProtocolClient.gd`
- [x] 1.2 Audit Tauri TCP kqz flow - compare `src/lib.rs` protocol module with Godot `GameClient.gd` and `Proto.gd`
- [x] 1.3 Document any missing Godot implementations needed

**Auditoría completada:**
- Godot `SimpleProtocolClient.gd` implementa completo el flujo WebSocket (auth_request → auth_response → server_selection → server_selection_response)
- Godot `GameClient.gd` implementa completo el flujo TCP con kqz ticket authentication
- `Proto.gd` tiene parsers para mensajes de conexión que no son usados pero están disponibles
- No se requieren implementaciones faltantes - Godot tiene todo el protocolo necesario

## 2. Godot Client Enhancement (if needed)

- [x] 2.1 Implement missing protocol features in Godot client (no changes needed - complete)
- [x] 2.2 Add any missing protobuf parsers to `Proto.gd` or `WorldProto.gd` (no changes needed - complete)
- [x] 2.3 Verify Godot client handles full auth → server_selection → kqz → game flow (verified complete)

## 3. Tauri Cleanup - Delete Rust/Frontend Files

- [x] 3.1 Delete `src/` directory (Rust backend)
- [x] 3.2 Delete `src-tauri/` directory (Tauri entry point)
- [x] 3.3 Delete `frontend/` directory (Vue.js frontend)
- [x] 3.4 Delete `Cargo.toml` (Rust package manifest)
- [x] 3.5 Delete `build.rs` (Rust build script)
- [x] 3.6 Delete `tauri.conf.json` (Tauri configuration)

## 4. Documentation Update

- [x] 4.1 Update `README.md` to remove Tauri references (already clean)
- [x] 4.2 Update `README_ES.md` to remove Tauri references (already clean)
- [x] 4.3 Update `AGENTS.md` to reflect new structure
- [x] 4.4 Update `docs/` folder documentation to remove Tauri references

## 5. Verification

- [x] 5.1 Verify Godot project loads in Godot 4.8 (`godot --headless --path godot-client --quit`)
- [x] 5.2 Verify no Tauri files remain in repository root
- [x] 5.3 Verify all Godot client files are intact (scripts, scenes, data files)
- [x] 5.4 Create git commit with deletion summary

## Workflow follow-up

- Archive the change after project review is satisfied
- Verify the archived result shows clean project structure