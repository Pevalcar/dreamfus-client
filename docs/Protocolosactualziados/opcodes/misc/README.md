# Opcodes Misceláneos — Cliente Godot Mono C#

Documenta los opcodes del corazón del juego y otros que no encajan en los dominios anteriores.

## Tabla de opcodes

| Opcode | Dir | Qué hace | Handler | Campos | Respuesta | Tiempo |
|--------|-----|----------|---------|--------|-----------|--------|
| `kqo` | C→S | El heartbeat, cada 5 segundos mientras el cliente está en el mundo. El mensaje de cliente más frecuente de todo el set de capturas y presente en 235 de los 242 archivos. | `GameNodeProxy` | — | `kqy` | 5 segundos |
| `kqy` | S→C | La respuesta, y nada más. Veinte y cuatro seguidos 5,000 ms de distancia en la captura del tutorial, cada uno seguido de exactamente un `kqy`. El frame sale byte a byte como el capturado: `1d 0a 1b 0a 19 0a 13 type.ankama.com/kqy 12 02 08 01`. Viaja en campo raíz 1, no en el de respuesta. | `BuildHeartbeatAnswer` | `f1: 1` | — | — |
| `kum` | C→S | Gastar puntos de característica. Un total que no quepa en el capital del personaje se rechaza entero, no parcialmente. | `CharacteristicsHandler.SpendAsync` | `f1..f6: puntos gastados en total en esa característica` | `iun`, `kub` | Inmediata |
| `kuh` | C→S | Reset de características. La captura no cobra por ello — los kamas son idénticos antes y después — así que no se toma tarifa aquí tampoco. | `CharacteristicsHandler.ResetAsync` | vacío | `iun`, `kub` | Inmediata |
| `hmt` | C→S | Cambiar un hechizo por su variante, desde el panel o desde la barra. | `SpellHandler.HandleVariantAsync` | `f1: wanted spell id` | `iuq`, `hng` | Inmediata |
| `iuq` | S→C | Uno por cada ranura de la barra que tenía la mitad antigua — una captura de intercambio produjo dos porque el hechizo estaba en dos ranuras, así que sabemos que es uno por ranura y no uno por intercambio. Se envía **antes** de `hng`. | `BuildShortcutChanged` | `f2 { f2: slot, f6 { f2: spell id } }, f3: bar` | — | — |
| `hng` | S→C | El nuevo hechizo y el grado que el nivel del personaje abre. | `BuildSpellSwapped` | `f2: spell id, f3: grade` | — | — |
| `itz` | C→S | Configurar una ranura de la barra de accesos directos (colocar desde el panel). También se escribe en la base de datos — si no, la barra se reconstruye idéntica cada sesión y cualquier cosa que el jugador coloque se pierde al salir. | `GameNodeProxy.RememberShortcut` | `f2 { f2: slot, f6 { f2: spell id } }, f3: bar` | `ivk` | — |
| `iul` | C→S | Quitar una ranura (clic derecho). Proto `ShortcutBarRemoveRequest`: bar entonces slot. | `GameNodeProxy.ClearShortcutAsync` | `f1: bar, f2: slot` | `ivr` | — |
| `iuv` | C→S | Intercambiar dos ranuras (arrastrar). | `GameNodeProxy.SwapShortcutsAsync` | `f1: first slot, f2: second slot, f3: bar` | `ivk` | — |
| `ivr` | S→C | ShortcutBarRemovedEvent — el único acuse que limpia el icono del cliente. `ivk` vacío deja un fantasma. | `BuildShortcutRemoved` | `f1: bar, f2: slot` | — | — |
| `ivk` | S→C | El eco de un set / intercambio de ranura lleno (`itz` / mitad de `iuv`). | `GameNodeProxy` | misma forma que `itz` | — | — |
| `iwo` | C→S | Hacer clic en un elemento interactivo. El zaap, el cofre y la lotería llegan aquí. | `ZaapTravelHandler.UseAsync` | `f1: skill instance uid, f2: element id` | `iwn`, `hjj` | Inmediata |
| `iwn` | S→C | "Ese elemento está en uso." `f2` es el **elemento**, no la instancia de habilidad: cruzar `iwo` y `iwn` en la misma captura muestra al cliente enviando ambos números y el servidor devolviendo el segundo. Enviar el primero marca un elemento que no existe como ocupado. | `BuildElementInUse` | `f1: 1, f2: element id, f4: skill, f5: who` | — | — |
| `hjj` | S→C | La lista de destinos. `f6` se comprobó contra `MapPositions` en todas las 25 entradas de la captura y coincide con cada una. El destino donde ya estás viaja sin `f2`, que en proto3 es cero: ir a donde ya estás no cuesta nada. | `BuildZaapList` | `f2: map of the open zaap, f3 (rep) { f1: area level, f2: cost, f5: map, f6: subarea }` | — | — |
| `hjc` | C→S | Destino elegido. | `ZaapTravelHandler.TravelAsync` | `f3: destination map` | `jsd`, `jru`, `lqu`, `hjk`, `ivf`, `kld` | — |
| `ivf` | S→C | Kamas restantes después de pagar. | `BuildKamas` | `f1: kamas` | — | — |
| `kld` | S→C | "Cerrar el diálogo." El cliente **no** cierra la ventana del zaap por sí solo. Aparece dos veces en las capturas con el mismo valor — a la llegada justo antes de `jss`, y como respuesta al `kla` vacío — así que `f1` es una razón fija y no algo que calcular. | `BuildDialogClosed` | `f1: 10` | — | — |
| `jbn` | C→S | El botón del bolso del havre, y la tecla H. Lleva un character porque puedes visitar el bolso de otro. | `MerkasakoHandler.EnterFromOutsideAsync` | `f2: whose bag` | `jbu` | — |
| `jbl` | C→S | Cambiar el tema de la habitación desde dentro. | `MerkasakoHandler.ChangeThemeAsync` | `f1: theme` | — | — |
| `jbv` | C→S | Abrir el modo de colocación de muebles. | `MerkasakoHandler.OpenEditorAsync` | vacío | `jbm` | — |
| `jbm` | S→C | Modo de colocación reconocido. | `MerkasakoHandler` | vacío | — | — |
| `jbg` | C→S | Un pedazo de la habitación. Llega **dividido** — tres seguidos en la captura — y cada pedazo lleva la **habitación completa**, no un diff. Guardar cada pedazo por separado haría que el primero borrara lo que los otros dos llevan, así que se recopilan y se escriben una vez al cerrar. | `MerkasakoHandler.CollectFurniture` | `f2 (rep) { f1: cell, f2: furniture, f3: orientation }` | — | — |
| `jbk`, `jav`, `jaw` | C→S | Cerrar el modo de colocación. Los tres llegan juntos al aceptar. | `MerkasakoHandler.CloseEditorAsync` | vacío | `jba` | — |
| `jba` | S→C | Modo de colocación cerrado. | `MerkasakoHandler` | vacío | — | — |
| `jbu` | S→C | Los muebles en la habitación, esperados detrás del mapa. Misma forma que `jbg` pero en `f1` en lugar de `f2`. | `BuildHavenBagFurniture` | `f1 (rep) { f1: cell, f2: furniture, f3: orientation }` | — | — |
| `jaz` | S→C | Se envía con los muebles, entre `jss` y `lva`. Significado no establecido. | `MerkasakoHandler` | vacío | — | — |
| `hov` | C→S | Emote. | — | — | — | — |
| `hoc` | S→C | Emote. | — | — | — | — |
| `hor` | C→S | Emote. | — | — | — | — |
| `hns` | S→C | Emote. | — | — | — | — |

## Ejemplo byte a byte: `kqo` (heartbeat)

```
Hex: 0A 19 0A 13 74 79 70 65 2E 61 6E 6B 61 6D 61 2E 63 6F 6D 2F 6B 71 6F 12 02 08 01
```

| Bytes | Campo | Descripción |
|-------|-------|-------------|
| `0A 19 "type.ankama.com/kqo"` | Campo 1 del Any (type_url) | Identifica el opcode heartbeat |
| `12 02 08 01` | Campo 2 del Any | payload: f1 = 1 |

## Advertencias

- `kqo` se envía cada 5 segundos. Responder `kqo` con el bloque de mapa hace que el cliente recargue el mundo en bucle: el bloque lleva `jru`, y `jru` significa "carga este mapa". El bloque sale solo en el primer `kqo` de una entrada (o en `lqc`, lo que llegue primero) y el heartbeat recibe su propia respuesta desde entonces.
- `kqy` viaja en campo raíz 1, no en el campo respuesta (3).
