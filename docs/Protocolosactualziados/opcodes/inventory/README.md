# Opcodes de Inventario y Equipamiento — Cliente Godot Mono C#

Documenta los opcodes para gestionar objetos, equipamiento, uso de ítems y movimiento entre ranuras.

## Tabla de opcodes

| Opcode | Dir | Qué hace | Handler | Campos | Respuesta | Tiempo |
|--------|-----|----------|---------|--------|-----------|--------|
| `ivx` | S→C | Inventario del personaje, construido desde la base de datos. Slot omitido cuando es cero (zero = amuleto). | `BuildInventory` | `f3 (rep) { f1: slot, f5 { f1: template, f2 (rep) {...}, f3: quantity, f4: uid } }` | — | — |
| `iuk` | C→S | Mover un ítem a una ranura o devolverlo a la bolsa. | `EquipmentHandler.MoveAsync` | `f1: quantity, f2: uid, f3: position` | `ivq`, luego `lym`, `hie`, `hii`, `iun`, `jsn`, `lxc`, `kub` | Inmediata |
| `ivq` | S→C | Dónde terminó un ítem. Una ranura tiene un ítem: lo que había se evacúa a la bolsa con su propio `ivq` primero. | `EquipmentHandler` | `f1: uid, f2: position` | — | — |
| `ium` | S→C | Un ítem sale de la bolsa. | `BuildItemGone` | `f1: uid` | — | — |
| `iua` | S→C | Un ítem llega a la bolsa, con todo: template, efectos, cantidad. | `BuildItemArrived` (field 3) | `f3 { f1: bag, f5 { f1: template, f2 (rep): effects, f3: quantity, f4: uid } }` | — | — |
| `itd` | S→C | Un ítem llega al cofre. | `BuildItemArrived` (field 1) | `f1 { f1: bag, f5 { ... } }` | — | — |
| `itc` | S→C | Un ítem sale del cofre. | `BuildItemGone` | `f1: uid` | — | — |
| `iun` | S→C | Pods (capacidad de carga). Cinco puntos de fuerza movieron `f3` exactamente 25; cinco pods por punto de fuerza es la regla del juego. | `BuildPods` | `f1: carried, f3: capacity` | — | — |
| `iuw` | C→S | Destruir un ítem. El cliente no elimina nada por sí solo; sin respuesta, el ítem queda. Observado en el log de tráfico del emulador contra el cliente real, no en las capturas pcapng. | `DestroyItemHandler.DestroyAsync` | `f2 { f2: uid, f3: quantity }` | — | Inmediata |
| `lym` | S→C | Lleva el aura en el flujo de apariencia (`f1: aura id`, vacío para ninguna). En cada captura de equipar/des-equipar lleva la constante 206; su significado no está establecido. | `EquipmentHandler`, `AppearanceHandler.AuraAsync` | `f1: 206` al equipar; `f1: aura id` o vacío para el aura | — | — |
| `hie` | S→C | Sin significado establecido. Constante en cada captura de equipar/des-equipar. | `EquipmentHandler` | `f1: 2` | — | — |
| `hii` | S→C | Sin significado establecido. Igual que `hie`. | `EquipmentHandler` | `f1: 2` | — | — |

## Ejemplo byte a byte: `iuk` (mover ítem)

```
Hex: 08 01 10 <uid varint> 18 06
```

| Bytes | Campo | Descripción |
|-------|-------|-------------|
| `08 01` | Campo 1 (`f1`) | quantity = 1 |
| `10 <uid>` | Campo 2 (`f2`) | uid del ítem (varint) |
| `18 06` | Campo 3 (`f3`) | position = 6 (sombrero) |

## Advertencias

- **Posición 0 es el amuleto, no la bolsa.** Proto3 omite el campo cuando es cero, así que un amuleto llega como solo un uid. Decodificar "0 ausente = bolsa" es por lo que el amuleto nunca podía equiparse.
- Las cuatro mensajes de transferencia están pareados desde la captura del cofre de la casa: `iua, itc, iun` y `itd, ium, iun`. Cada grupo es un movimiento; la llegada y la salida de un grupo son los dos extremos del mismo viaje. Se cruzaron un tiempo: el ítem desaparecía de donde salía y no aparecía donde llegaba hasta cerrar y reabrir el cofre.
