# Opcodes de Apariencia — Cliente Godot Mono C#

Documenta los opcodes de la ventana de apariencia, que funciona sobre un **borrador**. Mientras el jugador ajusta, el servidor envía **solo** `lxc`, que es la previsualización del panel y nadie más lo ve. `jsn` — el mensaje que redibuja al personaje en el mapa — no sale hasta Guardar. Verificado en las catorce capturas que terminan en un guardado.

## Tabla de opcodes

| Opcode | Dir | Qué hace | Handler | Campos | Respuesta | Tiempo |
|--------|-----|----------|---------|--------|-----------|--------|
| `lyk` | C→S | Abrir la ventana. Sin respuesta propia. | `AppearanceHandler.OpenAsync` | vacío | — | — |
| `lyy` | C→S | Pedir el estado de la ventana. | `AppearanceHandler.SendStateAsync` | `f1: character uuid` | `lxo` | — |
| `lxo` | S→C (f3) | El estado de la ventana. `f7` es el mismo uuid de la previsualización `lxc` y `f12` su mismo look — así sabe el panel que la respuesta es suya. | `BuildAppearanceState` | `f1: 1, f3 { f3: when, f5: breed, f7: preview uuid, f8: 3, f10: title, f11: level, f12: look, f15: -1, f16: ornament, f17 (rep) { f1: slot, f2 { f2: garment } } }` | — | — |
| `lys` | C→S | Ponerse una prenda y deja que el servidor elija el slot. Acepta una variante, que es lo que usan los objetos vivos para imitar una prenda u otra. | `AppearanceHandler.WearAsync` | `f1: item, f2: variant` | `lwz` | Inmediata |
| `lwz` | S→C (f3) | El slot que el servidor eligió. | `AppearanceHandler` | `f1: 1, f3: slot` | — | — |
| `lyf` | C→S | Poner o limpiar un slot con nombre. Sin variante. Sin ítem, vacía el slot. | `AppearanceHandler.AssignAsync` | `f2: item, f3: slot` | `lyj` | Inmediata |
| `lyj` | S→C (f3) | Acuse de recibo. | `AppearanceHandler` | `f3: 1` | — | — |
| `lxg` | C→S | Mostrar u ocultar lo que hay en un slot. Con `f3` puesto, la piel de ese slot desaparece del siguiente `lxc`; sin él, regresa. La prenda no se quita, deja de dibujarse. | `AppearanceHandler.ToggleAsync` | `f1: slot, f3: 1` para ocultar | `lxk` | Inmediata |
| `lxk` | S→C (f3) | Acuse de recibo. | `AppearanceHandler` | `f1: 1` | — | — |
| `lxw` | C→S | El aura. | `AppearanceHandler.AuraAsync` | `f2: aura` | `lwx` | Inmediata |
| `lwx` | S→C (f3) | Acuse de recibo. | `AppearanceHandler` | `f1: 1` | — | — |
| `lxc` | S→C | "Tu aspecto cambió" — la previsualización. `f1` es un uuid, idéntico en una sesión y distinto por personaje. | `BuildLookChanged` | `f1: uuid, f2: the new look` | — | — |
| `jsn` | S→C | "Este actor cambió" — el bloque completo del actor, con celda, ID y el nuevo aspecto. Esto es lo que el cliente realmente redibuja; `lxc` solo actualizó el muñeco del inventario y dejó a la figura en el mapa con la montura vieja. | `BuildActorRefreshed` | `f1 { the actor block }` | — | — |
| `lxs` | C→S | **Guardar.** Aquí el borrador se convierte en lo que se lleva, y donde el aspecto llega al resto del mapa. | `WardrobeHandler.SaveAsync` | vacío | `lyu` | — |
| `lyu` | S→C (f3) | Guardar reconocido. | `WardrobeHandler` | `f1: 1` | — | — |
| `lze` | C→S | Elegir un título. Toca solo el borrador. | `WardrobeHandler.ChooseTitleAsync` | `f1: title`, o vacío para ninguno | `lxa` | Inmediata |
| `lxa` | S→C (f3) | Acuse de recibo. | `WardrobeHandler` | `f2: 1` | — | — |
| `lwm` | C→S | Elegir un adorno. | `WardrobeHandler.ChooseOrnamentAsync` | `f2: ornament`, o vacío para ninguno | `lyv` | Inmediata |
| `lyv` | S→C (f3) | Acuse de recibo. | `WardrobeHandler` | `f1: 1` | — | — |
| `hid` | S→C | El título que se lleva ahora. **Vacío** significa ninguno — no un cero dentro. | `BuildTitleUpdated` | `f1: title`, o vacío | — | — |
| `hif` | S→C | El adorno que se lleva ahora, misma regla. | `BuildOrnamentUpdated` | `f1: ornament`, o vacío | — | — |
| `hhy` | S→C | Lo que la cuenta **posee**. El cliente ya lleva todo el catálogo; cualquier cosa no en esta lista se dibuja gris. Se envía una vez, en la entrada al mundo. Un personaje recién creado llega `hhy` con cero bytes. | `BuildTitlesOwned` | `f1: packed titles, f2: packed ornaments` | — | — |
| `lyt` | S→C | Los trajes guardados del guardarropa. **Obligatorio**: sin él la ventana de cosméticos reproduce su sonido y nunca dibuja, muriendo en `CosmeticUi.DisplayOutfit` con una referencia nula porque no tiene un traje que mostrar. | `BuildOutfits` | `f1 (rep): cada traje guardado, f2: el que se lleva` | — | — |

## Advertencias

- Los campos no se alinean: el título viaja en `f1` de `lze`, el adorno en `f2` de `lwm`. Ambos aceptan un **mensaje vacío**, que es cómo se expresa "ninguno" — no un cero dentro.
- `lxs` (Save) es donde el borrador se confirma. Sin `lyt` después del save, la ventana de cosméticos nunca dibuja.
