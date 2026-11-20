# Protocolo de NPCs — Cliente Godot Mono C#

Documenta los mensajes de protocolo para interacción con NPCs que el cliente Godot Mono C# debe implementar para diálogos, trueques y misiones con el servidor DreamFus.

## Mensajes de interacción con NPCs disponibles

El servidor expone mensajes de protocolo basados en los handlers `NpcHandler`, `NpcBarterHandler` y `QuestHandler`.

| Acción | Handler del servidor | Descripción |
|--------|---------------------|-------------|
| Diálogo con NPC | `NpcHandler` | Iniciar diálogo y obtener opciones de respuesta |
| Trueque con NPC | `NpcBarterHandler` | Comprar/vender objetos con un NPC |
| Misiones | `QuestHandler` | Aceptar, completar y consultar estado de misiones |

## Estructura de mensajes de NPCs

Cada mensaje de interacción con NPCs SHALL usar el sobre `hea.request` con `uid` y un `Any` cuyo `type_url` identifique el opcode de NPC correspondiente:

```
hea.request (campo 2)
  └─ 1: Any { 1: "type.ankama.com/<opcode>", 2: <payload NPC> }
  └─ 2: <uid int32 firmado>
```

## Reglas de comportamiento

- Interactuar con un NPC que no existe en el mapa actual es rechazado.
- El trueque valida que el personaje tenga kamas suficientes para la compra.
- Las misiones validan requisitos (nivel, misiones previas) antes de aceptar o completar.
- Cada NPC tiene sus propias opciones de diálogo y objetos en venta.

## Referencia para Godot Mono C#

- Usar `Google.Protobuf` 3.35.1 para serializar/deserializar los payloads de NPCs.
- Usar `System.Net.Sockets.TcpClient` para el canal 5555.
- Documentación oficial de Godot 4.x: https://docs.godotengine.org/es/4.x/
