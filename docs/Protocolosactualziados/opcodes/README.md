# Catálogo de Opcodes — Cliente Godot Mono C#

Índice de todos los opcodes de 3 letras del protocolo Game del servidor DreamFus (versión 3.6.10.10).
Cada opcode es el único nombre que tiene un mensaje: `type.ankama.com/<opcode>`. El cliente no lleva
schema, ni registro, ni strings que digan qué significa `lys` o `jru`. Este catálogo es el contrato
que el cliente Godot debe usar para decidir qué enviar y cómo interpretar lo que recibe.

## Carpetas por dominio de protocolo

| Carpeta | Dominio | Opcodes destacados |
|---------|---------|-------------------|
| `connection/` | Conexión y bienvenida | `kqz`, `kra`, `lqu`, `hoy`, `kqu`, `kvi`, `kqr` |
| `inventory/` | Inventario y equipamiento | `ivx`, `iuk`, `ivq`, `ium`, `iua`, `itd`, `itc`, `iun`, `iuw` |
| `movement/` | Movimiento dentro del mapa | `jrw`, `jsj`, `jqi`, `jsq`, `jqk`, `jsd` |
| `maps/` | Cambio de mapa y carga de zona | `jru`, `lqc`, `hjk`, `jrh`, `jss`, `lva`, `lqn`, `kmv` |
| `combat/` | Combate | `jtn`, `jwi`, `jxm`, `jti`, `jxc`, `jzc`, `jxh`, `jwz`, `jyt`, `jwh`, `kmk` |
| `npcs/` | Interacción con NPCs | `lxh`, `lxj`, `ilr`, `kjl` |
| `economy/` | Tiendas, trueque, cofres | `kci`, `iwb`, `kcr`, `kla`, `khd`, `jbs` |
| `social/` | Chat, amigos, gremios, contactos | `ktm`, `kti`, `kqg`, `jhe`, `jgu`, `hol`, `koj` |
| `guilds/` | Gremios | `jii`, `jml`, `jci`, `jmf`, `jlx` |
| `professions/` | Oficios y recolección | `isv`, `kdb`, `kcj`, `irl` |
| `appearance/` | Apariencia, cosméticos, títulos | `lys`, `lyf`, `lxg`, `lxw`, `lxc`, `jsn`, `lxs`, `hhy`, `lyt` |
| `misc/` | Misceláneo y corazón del juego | `kqo`, `kqy`, `kum`, `kuh`, `hmt`, `iwo`, `iwn`, `jbn` |
| `unknown.md` | Sin significado conocido | 79 "Unidentified" + 541 solo-capturas |

## Cómo leer cada entrada de opcode

Cada opcode documenta:

- **Nombre**: las 3 letras del opcode (ej. `kqz`).
- **Dirección**: `C→S` (cliente a servidor), `S→C` (servidor a cliente), o `S→C (f3)` si viaja en el campo respuesta.
- **Qué hace**: descripción del comportamiento del servidor.
- **Campos**: números de campo, tipo y nombre semántico cuando se conocen.
- **Ejemplo hex**: trama real byte a byte para comparar la salida del cliente Godot.
- **Respuesta esperada**: qué opcode responde el servidor y en qué campo raíz viaja.
- **Tiempo de respuesta**: inmediato, 5 segundos (heartbeat), o "sin timeout propio".
- **Advertencias**: trampas conocidas (ej. posición 0 = amuleto en `iuk`).

## Reglas clave para el cliente Godot Mono C#

1. **Un frame = un mensaje**: prefijo varint de longitud, luego el payload Protobuf. Un mensaje nunca ocupa varios frames.
2. **Campo raíz**: 1 = evento (push del servidor), 2 = petición del cliente, 3 = respuesta del servidor.
3. **`uid` obligatorio en peticiones**: int32 firmado, `-1` si no se espera correlación.
4. **`type_url`**: `type.ankama.com/<opcode>` en el campo 1 del `Any`.
5. **Ticket**: 32 caracteres hexadecimales en minúsculas, de un solo uso.
6. **No usar opcodes desconocidos**: los listados en `unknown.md` no tienen implementación en el servidor.

## Referencias

- Documentación oficial de Godot 4.x: https://docs.godotengine.org/es/4.x/
- `Google.Protobuf` 3.35.1 para serialización Protobuf.
- `System.Net.Sockets.TcpClient` para el canal 5555.
- Especificación de comportamiento: `openspec/changes/catalogar-opcodes-godot/specs/godot-opcode-catalogue/spec.md`
