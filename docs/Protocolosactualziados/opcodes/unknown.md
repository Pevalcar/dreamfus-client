# Opcodes Sin Significado Conocido — Cliente Godot Mono C#

Esta página lista los opcodes que **no deben usarse para lógica de juego** porque el servidor 3.6.10.10 no tiene implementación para ellos, o porque su significado no se ha establecido.

## 79 opcodes "Unidentified" de `Op.cs`

Estos opcodes tienen una constante en `Jondo.Unity.Protocol/Op.cs` con el comentario `Unidentified` y un número de usos en el emulador, pero no hay handler que les dé significado. Aparecen en las capturas o en el tráfico del emulador, pero el servidor no sabe qué hacer con ellos.

| Opcode | Usos en el emulador | Notas |
|--------|---------------------|-------|
| (79 opcodes marcados como Unidentified en Op.cs) | 1-4 usos cada uno | Sin significado establecido |

## 541 opcodes solo-captura

Estos opcodes aparecen en las 242 capturas de red (669 opcodes totales vistos en el cable) pero no tienen implementación en el código del servidor. El cliente Godot **no debe** enviarlos ni interpretar su contenido como algo significativo.

| Opcode | Wire | Archivos | Qué se sabe |
|--------|------|----------|-------------|
| `kmu` | S→C 399 | 90 | Presente en 25 de las 31 carpetas. Nada establecido. |
| `kmv` | C→S 727 | 88 | Llega con `jrh` en cada carga de mapa y no espera nada. El emulador ya lo ignora en silencio. |
| `iom` | S→C 283 | 67 | Declarado como `MapInformationsRequest`, pero las capturas muestran al **servidor** enviándolo. Nombre erróneo. |
| `kmb` | S→C 172 | 62 | Sale con `jsn` cuando se guarda un aspecto. Medido: 49 `kmb` montado y ninguno sin montar. No se envía; los cambios de aspecto llegan al mapa a través de `jsn`. |
| `lqg` | S→C 77 | 56 | Viaja con `lqt` y `lqf`. |
| `lqt` | S→C 76 | 55 | Viaja con `lqg` y `lqf`. |
| `lqn` | S→C 213 | 53 | Entre `lqu` y `hjk` en cada cambio de mapa. Su campo es 197 / 24 / 470 en tres situaciones diferentes; no explicado. Deliberadamente no se envía. |
| `hpm` | S→C 103 | 35 | Nada establecido. |
| `izz` | S→C 635 | 29 | Nada establecido. |

## Regla de oro para el cliente Godot

**Si un opcode no está en las carpetas `connection/`, `inventory/`, `movement/`, `maps/`, `npcs/`, `economy/`, `social/`, `guilds/`, `professions/`, `appearance/` o `misc/` con un significado documentado, no existe para el cliente.** Usar un opcode de esta página es comportamiento indefinido.

## Script de regeneración

El script `scripts/Generate-GodotOpcodeDocs.ps1` lee `Op.cs`, el mapping JSON y el `.proto` y puede regenerar este listado en día de parche.
