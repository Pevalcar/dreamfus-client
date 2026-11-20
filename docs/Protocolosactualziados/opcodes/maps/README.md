# Opcodes de Mapas — Cliente Godot Mono C#

Documenta los opcodes para cambio de mapas, carga de bloque de mapa y navegación entre zonas.

## Tabla de opcodes

| Opcode | Dir | Qué hace | Handler | Campos | Respuesta | Tiempo |
|--------|-----|----------|---------|--------|-----------|--------|
| `lqc` | C→S | "Bloque 1 digerido." El servidor real espera esto antes de enviar el bloque 2. | `GameNodeProxy` | vacío | `jru` (bloque 2) | — |
| `jru` | S→C | "Carga este mapa." Enviarlo dos veces hace que el cliente recargue el mundo en bucle. | `BuildLoadMap`, `WorldEntry.SendMapAsync` | `f2: map id` | — | — |
| `hjk` | S→C | Viaja con `jru` en cada cambio de mapa. | `BuildMapDiscovered` | `f1: packed [map id]` | — | — |
| `jrh` | C→S | "¿Quién está en este mapa?" Sin respuesta, el mapa se dibuja vacío: sin avatar, sin NPCs, sin monstruos. | `GameNodeProxy` | vacío | `jss`, `lva` | Inmediata |
| `jss` | S→C | Los actores. `f6` no es decoración: con un subarea cero el cliente lanza dentro de `MapInfoUI.SetInfoFromSubarea` y pierde el nombre del mapa, las coordenadas y el marcador del minimapa. El tipo de actor viene de qué campo aparece dentro de `f2.f1`: `f5` jugador, `f7` NPC, `f4` grupo de monstruos; NPCs y grupos usan IDs contextuales negativos. | `BuildMapActors` | `f2: map id, f6: subarea id, f5 (rep) { f1 { f1: cell, f2: facing }, f2 {...}, f3: contextual id }` | — | — |
| `lva` | S→C | "Ese es cada actor." Vacío, inmediatamente detrás de `jss`. Sin él el cliente nunca cuenta el mapa como cargado: espera unos dos segundos, pregunta de nuevo con `knm`, `kno`, `kny`, y empieza de nuevo. | `BuildActorsComplete` | vacío | — | — |
| `lqn` | S→C | Va entre `lqu` y `hjk` en cada cambio de mapa. Su único campo es 197 al entrar al mundo, 24 al cambiar de mapa y 470 tras un reset de características, y ninguna lectura de esos tres números se ha sostenido. Deliberadamente no se envía. | — | `f1: 197 / 24 / 470` | — | — |
| `kmv` | C→S | Llega con `jrh` en cada carga de mapa y no espera nada. El emulador ya lo ignora en silencio. | `GameNodeProxy` | — | — | — |
| `iom` | S→C | Declarado en `OpcodeRegistry` como `MapInformationsRequest`, pero las capturas muestran al **servidor** enviándolo. El nombre es un supuesto sobrante. | — | — | — | — |

## Ejemplo byte a byte: `jru` (cargar mapa)

```
Hex: 08 <map id varint>
```

| Bytes | Campo | Descripción |
|-------|-------|-------------|
| `08 <map id>` | Campo 2 (`f2`) | ID del mapa a cargar |

## Advertencias

- Para clientes Godot, si no se envía `lqc`/`kqo` (handshake de mapa estándar de Dofus), el servidor inicia un temporizador de 5 segundos para enviar el bloque de mapa (`Custom/Godot/GodotClientEntry.cs:56-69`).
- Enviar `jru` dos veces hace que el cliente recargue el mundo en bucle.
