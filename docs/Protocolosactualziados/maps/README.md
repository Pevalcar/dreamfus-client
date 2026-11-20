# Protocolo de Mapas — Cliente Godot Mono C#

Documenta los mensajes de protocolo para cambio de mapas que el cliente Godot Mono C# debe implementar para transitar entre zonas, usar portales, zaaps y teletransportes con el servidor DreamFus.

## Mensajes de cambio de mapas disponibles

El servidor expone mensajes de protocolo basados en los handlers `MapChangeHandler`, `MapLoadHandler`, `TeleportHandler`, `ZaapTravelHandler`, `ZaapiTravelHandler` y `TransportTravelHandler`.

| Acción | Handler del servidor | Descripción |
|--------|---------------------|-------------|
| Cambio por portal | `MapChangeHandler` | Transferir al personaje al atravesar un portal de mapa |
| Viaje por zaap | `ZaapTravelHandler` | Viajar a un zaap desbloqueado |
| Viaje por zaapi | `ZaapiTravelHandler` | Viajar por zaapi (red de transporte) |
| Transporte | `TransportTravelHandler` | Gestionar transportes entre zonas |
| Teletransporte | `TeleportHandler` | Teletransporte por hechizo o objeto |
| Carga de mapa | `MapLoadHandler` | Enviar bloque de mapa al entrar a una zona |

## Estructura de mensajes de mapas

Cada mensaje de cambio de mapas SHALL usar el sobre `hea.request` con `uid` y un `Any` cuyo `type_url` identifique el opcode de mapa correspondiente:

```
hea.request (campo 2)
  └─ 1: Any { 1: "type.ankama.com/<opcode>", 2: <payload mapa> }
  └─ 2: <uid int32 firmado>
```

## Reglas de comportamiento

- Un cambio a un mapa que no existe o no es accesible es rechazado; el personaje permanece en el mapa actual.
- El viaje por zaap valida que el zaap esté desbloqueado previamente.
- Al entrar al mundo tras la selección de personaje, el servidor envía el bloque de mapa (`jru` mediante `MapLoadHandler`).
- Para clientes Godot, si no se envía `lqc`/`kqo` (handshake de mapa estándar de Dofus), el servidor inicia un temporizador de 5 segundos para enviar el bloque de mapa.

## Referencia para Godot Mono C#

- Usar `Google.Protobuf` 3.35.1 para serializar/deserializar los payloads de mapas.
- Usar `System.Net.Sockets.TcpClient` para el canal 5555.
- Documentación oficial de Godot 4.x: https://docs.godotengine.org/es/4.x/
