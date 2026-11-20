# Opcodes de Combate — Cliente Godot Mono C#

Documenta los opcodes de combate. **Advertencia importante: los combates no están implementados contra el cliente 3.6.10.10.** El `FightHandler` existente es código de 3.6.4.3 que habla `joi`, `jos`, `jpp`, `jud`, `juc`, `jvm`, `joo` — ninguno de los cuales aparece en las 242 capturas.

## Tabla de opcodes (observados en capturas, sin handler en el servidor)

| Opcode | Dir | Wire | Archivos de captura | Qué se sabe |
|--------|-----|------|---------------------|-------------|
| `jtn` | S→C | 14,728 | 23 | El opcode más frecuente de todo el set de capturas. Aparece solo en grabaciones que contienen una pelea. |
| `jwi` | S→C | 7,324 | 23 | Solo en capturas con pelea. |
| `jxm` | S→C | 6,556 | 23 | Solo en capturas con pelea. |
| `jti` | C→S | 1,275 | 22 | Solo en capturas con pelea. |
| `jxc` | S→C | 739 | 23 | Solo en capturas con pelea. |
| `jzc` | S→C | 538 | 23 | Solo en capturas con pelea. |
| `jxh` | S→C | 514 | 23 | Solo en capturas con pelea. |
| `jwz` | C→S | 513 | 23 | Solo en capturas con pelea. |
| `jyt` | S→C | 503 | 20 | Solo en capturas con pelea. |
| `jwh` | C→S | 431 | 19 | Solo en capturas con pelea. |
| `kmk` | S→C | 264 | 22 | Solo en capturas con pelea. |
| `hpu` | S→C | 6 | — | Captura `Combate`. |
| `lux` | S→C | 5 | — | Captura `Combate`. |
| `ltd` | S→C | 5 | — | Captura `Combate`. |
| `kwb` | S→C | 5 | — | Captura `Combate`. |

## Advertencias

- **100 opcodes no implementados aparecen en esas 23 grabaciones y en ninguna de las otras 219.** Una pelea vale por sí sola esa cantidad de mensajes.
- El cliente Godot **no debe** intentar lógica de combate contra este servidor: no hay handler que responda a estos opcodes.
- Los 22 opcodes en sección 3 de `docs/opcodes.md` están en una rama de código muerta (3.6.4.3): `jto`, `jwe`, `jxw`, `jya`, `jyj`, `jyg`, `krp`, `joq`, `jwm`, `hnk`, `ilc`, `isf`, `hhf`, `kku`, `luy`, `kdx`, `izh`, `izu`, `koj`, `itn`, `ilr`, `kjl`.
