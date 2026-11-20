# Opcodes de NPCs — Cliente Godot Mono C#

Documenta los opcodes para interacción con NPCs: diálogos, trueques y misiones.

## Tabla de opcodes

| Opcode | Dir | Qué hace | Handler | Campos | Respuesta | Tiempo |
|--------|-----|----------|---------|--------|-----------|--------|
| `lxh` | C→S | Salir de un diálogo. Es el único mensaje NPC que el cliente 3.6.10.10 se observa enviar. | `NpcHandler.HandleLeaveDialogRequest` | vacío | `lxj` | Inmediata |
| `lxj` | S→C | Lo que el emulador responde a `lxh`. No verificado: este opcode no aparece en ninguna de las 242 capturas. | `NpcHandler` | `f1: 5` | — | — |
| `ilr` | S→C | Despachado como request de cliente por `NpcHandler`, pero las capturas lo muestran **servidor a cliente** solo (2 ocurrencias). Esa rama nunca dispara. | `NpcHandler` | — | — | — |
| `kjl` | S→C | Igual que `ilr`: despachado como request, solo visto servidor a cliente (1 ocurrencia). | `NpcHandler` | — | — | — |
| `iom` | S→C | Declarado como `NpcsMapQuestStatusUpdateEvent` en el mapping. Las capturas muestran al servidor enviándolo; puede ser un nombre erróneo. | — | — | — | — |

## Advertencias

- `ilr` y `kjl` se despachan como peticiones del cliente pero las capturas solo las muestran servidor a cliente. Esas ramas del código nunca se activan con este cliente.
