# Opcodes de Profesiones — Cliente Godot Mono C#

Documenta los opcodes de oficios y recolección. Entregan el mayor tráfico por opcode: `isv` (191 S→C), `kdb` (114 S→C) y `kcj` (114 C→S) suman 419 mensajes entre ellos, y cada uno vive en exactamente dos archivos de captura — un intercambio pequeño y bien acotado para decodificar.

## Tabla de opcodes

| Opcode | Dir | Qué hace | Handler | Campos | Respuesta | Tiempo |
|--------|-----|----------|---------|--------|-----------|--------|
| `isv` | S→C | 191 mensajes en 2 archivos. | — | — | — | — |
| `kdb` | S→C | 114 mensajes en 2 archivos. | — | — | — | — |
| `kcj` | C→S | 114 mensajes en 2 archivos. | — | — | — | — |
| `irl` | C→S | 30 mensajes. | — | — | — | — |

## Advertencias

- 19 opcodes exclusivos de oficios; 532 mensajes en total.
- Estos opcodes tienen estructura en el `.proto` pero **no hay significado establecido** ni handler en el servidor 3.6.10.10.
