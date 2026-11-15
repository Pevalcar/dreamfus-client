# Design

## Context

The project contains duplicate implementations of the DreamFus client protocol:
- **Tauri/Rust** (`src/lib.rs`, `src-tauri/main.rs`): WebSocket + TCP implementation
- **Godot/GDScript** (`godot-client/src/Network/*.gd`): Separate WebSocket client + TCP client

Both implementations exist in the same repository, creating maintenance overhead and risk of divergence. The Godot client is the intended final product for MCP Runtime integration.

**Tauri protocol implementation** (from `src/lib.rs`):
- WebSocket client on port 5557 for `auth_request` → `auth_response` → `server_selection` → `server_selection_response`
- TCP client on port 5555 with VarInt framing and protobuf messages
- kqz ticket authentication flow

**Godot protocol implementation** (from `SimpleProtocolClient.gd` and `GameClient.gd`):
- WebSocket client (`SimpleProtocolClient.gd`) for auth flow
- TCP client (`GameClient.gd`) for game protocol with kqz authentication
- VarInt framing in `Proto.gd`

## Goals / Non-Goals

**Goals:**
- Remove all Tauri/Rust/Frontend artifacts while preserving Godot client
- Verify Godot client implements complete protocol
- Create a clean project structure focused on Godot with MCP Runtime

**Non-Goals:**
- Modify Godot client implementation (only verify, don't change behavior)
- Update any Tauri implementation (will be deleted)
- Migrate any Tauri-specific features to Godot

## Decisions

### Decision 1: Two-phase approach (audit then delete)
**Why:** Must verify Godot implementation is complete before deleting Tauri code. Deleting without verification risks losing functionality.

**Alternatives:**
- Delete first → Risk of missing functionality
- Migrate features → Adds scope not requested by user

### Decision 2: Preserve project-level files
**Why:** Files like `.gitignore`, `README.md`, `AGENTS.md` are project infrastructure, not application code.

**Files to preserve:**
- `README.md`, `README_ES.md` - Documentation
- `AGENTS.md` - Agent instructions
- `.gitignore` - Git configuration
- `docs/` - Project documentation
- `project.godot`, `.godot/`, `scenes/`, `src/` (Godot client structure)

## Risks / Trade-offs

- **Risk:** Godot client may be missing protocol implementations → Mitigation: Audit Tauri code first and add any missing functionality to Godot
- **Risk:** Deleted Tauri code needed for reference → Mitigation: Commit changes before deletion, or archive as backup
- **Risk:** Documentation references Tauri URLs → Mitigation: Update docs to remove Tauri references

## Migration Plan

1. Audit Tauri `src/lib.rs` for protocol completeness
2. Compare with Godot `SimpleProtocolClient.gd` and `GameClient.gd`
3. List any missing implementations in Godot client
4. If missing: Implement in Godot client
5. Delete Tauri directories and files
6. Update documentation to remove Tauri references
7. Verify Godot project loads in Godot 4.8

## Open Questions

None - this is a straightforward cleanup operation with a well-defined scope.