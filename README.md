# DreamFus Client

**A Dofus 3 client re-engineered for DreamFus server.**

This client is built on **Tauri (Rust + WebView2)** and uses a **data-driven UI architecture**. All interfaces are defined in external JSON/CSS files (`.dfui` / `.dfss`), allowing hot-reload without recompiling the binary.

## Key Features

- **100% editable UI**: Edit `.dfui` and `.dfss` files, save, see changes instantly.
- **No IL2CPP / MelonLoader**: Native Rust bridge to the server's TCP protocol.
- **Protocol compatible**: Uses the same `Jondo.Unity.Server` wire format (VarInt-prefixed Protobuf).
- **Future-proof**: Works with any Dofus 3 server that speaks the DreamFus protocol.

## Development Status

| Phase | Description | Status |
|-------|-------------|--------|
| FASE 0 | TCP Socket Bridge & Asset Parser | ✅ In Progress |
| FASE 1 | Map Rendering (Native Cell-based) | ◯ Planned |
| FASE 2 | DreamFus UI Engine (JSON/CSS) | ◯ Planned |

## Build Requirements

```bash
cargo install tauri-cli
npm install
```

## License

MIT