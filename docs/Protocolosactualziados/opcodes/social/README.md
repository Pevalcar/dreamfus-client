# Opcodes Sociales — Cliente Godot Mono C#

Documenta los opcodes de chat, amigos, gremios, contactos y títulos/ornamentos.

## Tabla de opcodes

| Opcode | Dir | Qué hace | Handler | Campos | Respuesta | Tiempo |
|--------|-----|----------|---------|--------|-----------|--------|
| `ktm` | C→S | Una línea que el jugador escribió. | `GameNodeProxy` | `f2: text, f3: channel` | `kti` | Inmediata |
| `kti` | S→C | La línea que vuelve. Con un jugador en el servidor no hay nadie más a quien reenviarla, que es también lo que hace el servidor real con tus propias líneas — y lo que hace que aparezcan en la ventana. Canales, de la captura que recorre todos: 0 general (omitido, siendo cero), 1 equipo, 2 hermandad, 3 alianza, 4 grupo, 5 comercio, 6 reclutamiento, y 9, 11, 16, 18, 19 para el resto. | `BuildChatLine` | `f3: timestamp, f4: who, f5: character, f6: account, f7: text, f8: {}, f9: channel` | — | — |
| `ktb` | C→S | Mensaje privado. Lleva su destinatario. No implementado. | — | — | — | — |
| `kqg` | S→C | La lista de contactos. | — | — | — | — |
| `jhe` | S→C | La hermandad. | — | — | — | — |
| `jgu` | S→C | El cónyuge, con su aspecto. | — | — | — | — |
| `hol` | S→C | Cónyuge y hermandad. | — | — | — | — |
| `koj` | S→C | Veinte cuentas de Ankama con ID, apodo y tag: `f2 { f2: account id, f4 { f1: nickname, f2: tag }, f5: 3 }`. Nada que ver con bolso del havre. | — | `f2 { f2: account id, f4 { f1: nickname, f2: tag }, f5: 3 }` | — | — |
| `ife` | S→C | Alianzas, por nombre y tag. | — | — | — | — |
| `jjs` | S→C | Un puesto de jugador en el mapa, con la cuenta detrás. | — | — | — | — |
| `jaa` | S→C | Lo mismo, en su propio mensaje. | — | — | — | — |

## Ejemplo byte a byte: `ktm` (chat)

```
Hex: 0A <text len> <text bytes> 10 <channel varint>
```

| Bytes | Campo | Descripción |
|-------|-------|-------------|
| `0A <text>` | Campo 2 (`f2`) | texto del mensaje |
| `10 <channel>` | Campo 3 (`f3`) | canal (0 general, 1 equipo, 2 hermandad, etc.) |

## Advertencias

- Un mensaje privado es `ktb`, distinto de `ktm`, y no está implementado.
- `jhe`, `jhh`, `jhk` se dejaron de enviar porque el cliente lanza `NullReferenceException` sin `jhe` (el mensaje de la hermandad).
