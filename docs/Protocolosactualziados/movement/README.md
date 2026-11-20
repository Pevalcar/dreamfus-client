# Protocolo de Movimiento — Cliente Godot Mono C#

Documenta los mensajes de protocolo para movimiento del personaje que el cliente Godot Mono C# debe implementar para solicitar desplazamientos y validar celdas de mapa con el servidor DreamFus.

## Mensajes de movimiento disponibles

El servidor expone mensajes de protocolo basados en los handlers `WorldMoveHandler`, `MapLoadHandler` y `MapChangeHandler`.

| Acción | Handler del servidor | Descripción |
|--------|---------------------|-------------|
| Desplazamiento | `WorldMoveHandler` | Mover el personaje a una celda del mapa actual |
| Carga de mapa | `MapLoadHandler` | Enviar bloque de mapa y elementos al entrar a un mapa |
| Cambio de mapa | `MapChangeHandler` | Transferir el personaje entre mapas (portal, zaap, etc.) |

## Estructura de mensajes de movimiento

Cada mensaje de movimiento SHALL usar el sobre `hea.request` con `uid` y un `Any` cuyo `type_url` identifique el opcode de movimiento correspondiente:

```
hea.request (campo 2)
  └─ 1: Any { 1: "type.ankama.com/<opcode>", 2: <payload movimiento> }
  └─ 2: <uid int32 firmado>
```

## Reglas de comportamiento

- Un movimiento a una celda bloqueada o fuera del mapa es rechazado; el personaje permanece en su posición actual.
- Al entrar a un nuevo mapa, el servidor envía el bloque de mapa y los elementos del mapa (`MapLoadHandler`).
- Para clientes Godot, el servidor inicia un temporizador de 5 segundos para enviar el bloque de mapa si no se reclamó por el camino estándar.
- El cambio de mapa valida que el destino exista y sea accesible.

## Referencia para Godot Mono C#

- Usar `Google.Protobuf` 3.35.1 para serializar/deserializar los payloads de movimiento.
- Usar `System.Net.Sockets.TcpClient` para el canal 5555.
- Documentación oficial de Godot 4.x: https://docs.godotengine.org/es/4.x/
