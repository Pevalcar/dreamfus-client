# Proposal

## Why

The project contains duplicate implementations of the DreamFus client protocol - one in Rust/Tauri and one in pure GDScript/Godot. The Tauri code provides WebSocket authentication (port 5557) and TCP game connection (port 5555) functionality that duplicates what should be the single source of truth: the Godot client. This creates maintenance burden, confusion, and risks divergence between implementations. The Godot client is the intended final product for the MCP Runtime integration.

## What Changes

- Audit all Tauri code (src/, src-tauri/, frontend/, Cargo.toml, tauri.conf.json) to identify implemented protocols
- Verify each protocol implementation exists and is complete in the Godot client
- Delete all Tauri-specific files and directories
- Delete all frontend/WebSocket-related Tauri code
- Delete Rust build files (build.rs, Cargo.toml)
- Update project documentation to reflect the simplified structure
- Verify Godot client implements:
  - WebSocket authentication flow (auth_request → auth_response → server_selection → server_selection_response)
  - TCP protocol with kqz ticket authentication
  - VarInt framing for protobuf messages

## Capabilities

### New Capabilities
- **project-cleanup**: Complete removal of Tauri/Rust/Frontend codebase leaving only the Godot client and essential documentation

### Modified Capabilities
None (this is a cleanup operation, not a feature change)

## Impact

**Files to be removed:**
- `src/` (Rust backend - connection management, protocol handling)
- `src-tauri/` (Tauri entry point)
- `frontend/` (Vue.js frontend UI)
- `Cargo.toml` (Rust package manifest)
- `build.rs` (Rust build script)
- `tauri.conf.json` (Tauri configuration)

**Files to preserve:**
- `godot-client/` - The main Godot 4.8 client with MCP Runtime
- `docs/` - Project documentation
- `README.md`, `README_ES.md` - Documentation
- `.agents/`, `AGENTS.md` - Agent configuration
- `.gitignore` - Git ignore rules
- `project.godot`, `.godot/`, `scenes/`, `src/` (Godot client structure)

**Verification required:**
The Godot client currently has two protocol implementations:
1. `SimpleProtocolClient.gd` - WebSocket client (port 5557) for auth/server selection
2. `GameClient.gd` - TCP client (port 5555) for game protocol with kqz authentication

Both need to be verified complete before Tauri removal.