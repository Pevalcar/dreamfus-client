# Spec Delta

## Purpose

Completes the removal of all Tauri/Rust/Frontend codebase artifacts, leaving a clean project structure focused exclusively on the Godot 4.8 client with MCP Runtime integration.

## ADDED Requirements

### Requirement: Tauri codebase is removed
The system SHALL completely remove all Tauri-related directories and files, including but not limited to: `src/`, `src-tauri/`, `frontend/`, `Cargo.toml`, `build.rs`, and `tauri.conf.json`.

#### Scenario: Tauri files removed
- **WHEN** the cleanup is executed
- **THEN** no Tauri-specific files or directories exist in the project root

### Requirement: Godot client remains intact
The system SHALL preserve the complete Godot client structure under `godot-client/`, including all GDScript files, scenes, documentation, and project configuration.

#### Scenario: Godot files preserved
- **WHEN** the cleanup is executed
- **THEN** the `godot-client/` directory exists with all `.gd`, `.tscn`, and `.godot` files intact

### Requirement: Essential documentation preserved
The system SHALL preserve project-level documentation including `README.md`, `README_ES.md`, `AGENTS.md`, `.gitignore`, and the `docs/` directory.

#### Scenario: Documentation files preserved
- **WHEN** the cleanup is executed
- **THEN** all documentation files listed exist and contain their original content

### Requirement: Godot client protocol verification
The system SHALL verify that the Godot client's WebSocket client (`SimpleProtocolClient.gd`) and TCP client (`GameClient.gd`) implement the complete authentication and game connection protocol.

#### Scenario: WebSocket auth flow implemented
- **WHEN** the Godot client needs to authenticate
- **THEN** the client can send `auth_request` via WebSocket and receive `auth_response` with server list

#### Scenario: Server selection flow implemented
- **WHEN** authentication succeeds
- **THEN** the client can send `server_selection` request and receive `server_selection_response` with ticket

#### Scenario: TCP kqz authentication implemented
- **WHEN** connected to game server via TCP
- **THEN** the client sends kqz (ticket) message immediately and handles game protocol messages