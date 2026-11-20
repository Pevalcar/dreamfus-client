# Protocolo de Combate — Cliente Godot Mono C#

Documenta los mensajes de protocolo para combate que el cliente Godot Mono C# debe implementar para iniciar peleas, unirse a combates, ejecutar acciones de turno y recibir recompensas con el servidor DreamFus.

## Mensajes de combate disponibles

El servidor expone mensajes de protocolo basados en los handlers `FightHandler`, `FightJoin`, `FightDefeat`, `FightRewards`, `FightForgelance`, `FightIncarnation`, `FightMarkers`, `FightPlacementSwaps`, `FightPortals`, `FightSpectators`, `FightTackle`, `ChallengeDuelHandler` y `ChallengeHandler`.

| Acción | Handler del servidor | Descripción |
|--------|---------------------|-------------|
| Iniciar combate | `FightHandler` | Crear instancia de pelea contra un enemigo |
| Unirse a pelea | `FightJoin` | Validar y agregar al personaje como combatiente |
| Acción de turno | `FightHandler` | Ejecutar hechizo o acción durante el turno del personaje |
| Recompensas | `FightRewards` | Enviar XP, kamas y objetos al finalizar el combate |
| Derrota | `FightDefeat` | Notificar pérdida de vida y aplicar consecuencias |
| Marcadores de pelea | `FightMarkers` | Gestionar marcadores en el mapa de combate |
| Intercambio de posiciones | `FightPlacementSwaps` | Cambiar posición de combatientes en el mapa |
| Portales de pelea | `FightPortals` | Gestionar portales dentro del área de combate |
| Espectadores | `FightSpectators` | Permitir ver combates en curso |
| Agarrar (tackle) | `FightTackle` | Gestionar el tacklear a un enemigo en combate |
| Duelo de desafío | `ChallengeDuelHandler` | Gestionar duelos entre jugadores |
| Desafío | `ChallengeHandler` | Gestionar solicitudes de desafío |

## Estructura de mensajes de combate

Cada mensaje de combate SHALL usar el sobre `hea.request` con `uid` y un `Any` cuyo `type_url` identifique el opcode de combate correspondiente:

```
hea.request (campo 2)
  └─ 1: Any { 1: "type.ankama.com/<opcode>", 2: <payload combate> }
  └─ 2: <uid int32 firmado>
```

## Reglas de comportamiento

- Una acción de turno fuera del turno del personaje es rechazada por el servidor.
- Unirse a un combate requiere validación de `FightJoinAllowed`.
- Las recompensas se envían solo si el personaje ganó el combate.
- La derrota aplica consecuencias de muerte (pérdida de experiencia, objetos, etc.).
- Cada personaje tiene su propio turno en el combate; el servidor gestiona el orden de iniciativa.

## Referencia para Godot Mono C#

- Usar `Google.Protobuf` 3.35.1 para serializar/deserializar los payloads de combate.
- Usar `System.Net.Sockets.TcpClient` para el canal 5555.
- Documentación oficial de Godot 4.x: https://docs.godotengine.org/es/4.x/
