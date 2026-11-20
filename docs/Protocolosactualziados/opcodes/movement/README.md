# Opcodes de Movimiento — Cliente Godot Mono C#

Documenta los opcodes para solicitar desplazamientos del personaje y recibir confirmación de movimiento.

## Tabla de opcodes

| Opcode | Dir | Qué hace | Handler | Campos | Respuesta | Tiempo |
|--------|-----|----------|---------|--------|-----------|--------|
| `jrw` | C→S | Caminar a un camino de celdas. Cada paso empaqueta el facing en los bits por encima de la celda. El map id se comprueba contra la sesión; un desajuste se ignora. | `WorldMoveHandler.ConfirmMovementAsync` | `f1: map id, f2: packed path, cada entrada (facing << 12) \| cell` | `jsj` | Inmediata |
| `jsj` | S→C | Movimiento confirmado. Saltarlo deja al actor con facing cero, por lo que un personaje que sale por el borde izquierdo gira a mirar a la derecha al desvanecerse la pantalla. | `BuildActorMoved` | `f1: packed cells, f2: facing, f5: contextual id` | — | — |
| `jqi` | C→S | "Estoy en el borde, ¿puedo salir?" | `WorldMoveHandler.AllowMapExitAsync` | vacío | `jsq` | Inmediata |
| `jsq` | S→C (f3) | Adelante. No lleva nada más que el ID de petición eco, en campo raíz 3. Sin él el cliente nunca envía `jqk` y el personaje se queda en la frontera para siempre. | `ConnectionProtocol.Answer` | vacío, id eco | — | Inmediata |
| `jqk` | C→S | El mapa al que quiere ir. La celda de aterrizaje y el facing se calculan desde el lado de salida: un mapa tiene 14 celdas de ancho como un diamante, así que salir por los lados mueve la celda 13 y verticalmente 532 — todo medido en capturas. | `WorldMoveHandler.ChangeMapAsync` | `f2: map id` | `jsd`, `jru`, `lqu`, `hjk` | Inmediata |
| `jsd` | S→C | Quitar un actor del mapa. Su propio movimiento a otro mapa también cuenta. | `BuildActorLeft` | `f2: contextual id` | — | — |

## Ejemplo byte a byte: `jrw` (caminar)

```
Hex: 08 <map id varint> 12 <packed path varint len> <packed path bytes>
```

El packed path tiene cada entrada como `(facing << 12) \| cell`.

## Advertencias

- El `map id` en `jrw` se comprueba contra la sesión. Confiar en él permitiría mover el personaje a cualquier mapa con un mensaje aislado.
