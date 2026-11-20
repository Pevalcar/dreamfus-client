# Opcodes de Economía — Cliente Godot Mono C#

Documenta los opcodes para tiendas, compra/venta, trueque y cofres.

## Tabla de opcodes

| Opcode | Dir | Qué hace | Handler | Campos | Respuesta | Tiempo |
|--------|-----|----------|---------|--------|-----------|--------|
| `kci` | S→C | Un almacén se abre. `f3` es cuál: 4 cofre de casa, 17 bote, 19 cofre del bolso del havre, 16 banco; `f1` parece el recuento de slots (100, o int.MaxValue para el bolso del havre y el banco). | `StorageProtocol.BuildOpened` | `f1: 100, f3: 4` | — | — |
| `iwb` | S→C | Qué hay dentro. Misma forma que el inventario, con la bolsa como posición de todo — nada está equipado dentro de un cofre. | `BuildStorageContent` | `f1 (rep) { f1: 63, f5 { ... } }` | — | — |
| `kcr` | C→S | Mover un ítem. `f1` es un **contador con signo**: positivo mete esa cantidad, negativo saca esa cantidad — la captura del bote toma un stack de cuatro una unidad por `-1`. Un stack movido recibe un nuevo uid al otro lado. | `StorageHandler.MoveAsync`, `ChestHandler.MoveAsync` | `f1: quantity, f2: uid` | — | Inmediata |
| `kla` | C→S | Botón de cerrar del diálogo. Vacío, y el cliente espera: la ventana no se cierra hasta que el servidor lo dice. | `GameNodeProxy` → cofre o zaap | vacío | `khd` | — |
| `khd` | S→C | El cofre se cerró. | `BuildStorageClosed` | `f3: 11` | — | — |
| `jbs` | S→C | La respuesta de la máquina de lotería. De dos capturas: una con un premio en `f2`, una rechazada con `f3: 1`. | `BuildLotteryResult` | `f2: prize uid` o `f3: reason` | — | — |
| `ket` | S→C | — | — | — | — | — |
| `keq` | S→C | — | — | — | — | — |
| `kfz` | S→C | — | — | — | — | — |

## Ejemplo byte a byte: `kcr` (mover ítem en almacén)

```
Hex: 0E <signed quantity varint> 10 <uid varint>
```

| Bytes | Campo | Descripción |
|-------|-------|-------------|
| `0E <qty>` | Campo 1 (`f1`) | cantidad firmada (positivo = meter, negativo = sacar) |
| `10 <uid>` | Campo 2 (`f2`) | uid del ítem |

## Advertencias

- `kcr` con cantidad negativa saca del almacén; con cantidad positiva mete al almacén.
- El cliente espera respuesta del servidor antes de cerrar la ventana del cofre (`kla` → `khd`).
