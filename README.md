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
| FASE 0 | TCP Socket Bridge & Asset Parser | ✅ Complete |
| FASE 1 | Map Rendering (Native Cell-based) | ◯ Planned |
| FASE 2 | DreamFus UI Engine (JSON/CSS) | ◯ Planned |

## Wire Protocol

The protocol uses VarInt-prefixed Protobuf messages with the following structure:

```
[VarInt Length][Frame]
  where Frame = { RootField: 1|2|3, InnerAny: { field1: "type.ankama.com/OPCODE", field2: payload } }
```

- **Root field 1**: Server push (unsolicited messages from server)
- **Root field 2**: Client request (messages sent by client)
- **Root field 3**: Server reply (answers to client requests)

The inner Any message contains:
- Field 1: Type URL (`type.ankama.com/` + opcode)
- Field 2: Payload bytes

## Build Requirements

```bash
cargo install tauri-cli
cd dreamfus-client
cargo build
```

## Testing Connection

### Prerequisites

1. Start the Jondo server:
   ```powershell
   cd C:\Users\pevalcar\Proyects\jondo-servidor
   dotnet run --project Jondo.Unity.Server/Jondo.Unity.Server.csproj
   ```

2. The server listens on:
   - **5555**: Game server (TCP, binary protocol)
   - **6337**: Chat server (TCP)
   - **8888**: HAAPI/Launcher API (HTTP)
   - **15881**: Zaap (TCP/HTTP/WebSocket)

### Testing the Client

Build and run the client:
```bash
cd dreamfus-client
cargo tauri dev
```

Then:
1. Connect to `localhost:5555` (game server)
2. Send test opcodes like `hello` or `knx`
3. View received messages in the log panel

### Testing with a Real Message

Try sending a Hello message to get the server greeting:
- Opcode: `kuf` (CharacterExperienceGainEvent example)
- Or try `knx` for server list

## Project Structure

```
dreamfus-client/
├── Cargo.toml          # Rust dependencies (tauri 2.x, hex)
├── build.rs            # Tauri build script
├── tauri.conf.json     # Tauri configuration
├── src/
│   └── lib.rs          # Main Rust code (TCP bridge, protocol)
└── dist/
    └── index.html      # Test UI with connection controls
```

## Architecture

### Rust/Tauri Layer
- TCP socket bridge to Jondo server
- VarInt/PB frame encoding/decoding
- Tauri commands: `connect_server`, `disconnect_server`, `send_message`, `get_server_status`
- Event emission: `server-message` for received frames

### Future UI Layer (FASE 2)
- JSON/CSS driven UI (like Alea's DreamFus client)
- `.dfui` files for interface definitions
- `.dfss` files for stylesheet definitions

## License

MIT

## Related Projects

- [Jondo Server](../) - The Rust-compatible C# server
- [DreamFus Client GitHub](https://github.com/Pevalcar/dreamfus-client) - Public repository for this client