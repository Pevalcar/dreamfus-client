# Protocolo de Inventario — Cliente Godot Mono C#

Documenta los mensajes de protocolo para gestión de inventario que el cliente Godot Mono C# debe implementar para consultar, modificar y usar objetos con el servidor DreamFus.

## Mensajes de inventario disponibles

El servidor expone mensajes de protocolo basados en los handlers `InventoryHandler`, `ItemOnCharacterHandler`, `ItemUseHandler`, `StorageHandler`, `DestroyItemHandler`, `EquipmentHandler` e `ItemBarHandler`.

| Acción | Handler del servidor | Descripción |
|--------|---------------------|-------------|
| Consultar inventario | `InventoryHandler` | Lista de objetos, cantidades y ranuras ocupadas del personaje |
| Usar ítem | `ItemUseHandler` | Validar y aplicar efectos de un ítem del inventario |
| Mover entre ranuras | `InventoryHandler` | Cambiar posición de un objeto dentro del inventario |
| Equipar objeto | `EquipmentHandler` | Equipar un objeto (validar requisitos de nivel/clase) |
| Destruir objeto | `DestroyItemHandler` | Eliminar un objeto del inventario y liberar la ranura |
| Barra de objetos | `ItemBarHandler` | Gestionar la barra de acceso rápido del personaje |
| Objeto sobre personaje | `ItemOnCharacterHandler` | Consultar objetos equipados en el personaje |
| Almacenamiento | `StorageHandler` | Gestionar el baúl/banco de objetos compartido |

## Estructura de mensajes de inventario

Cada mensaje de inventario SHALL usar el sobre `hea.request` con `uid` y un `Any` cuyo `type_url` identifique el opcode de inventario correspondiente:

```
hea.request (campo 2)
  └─ 1: Any { 1: "type.ankama.com/<opcode>", 2: <payload inventario> }
  └─ 2: <uid int32 firmado>
```

## Reglas de comportamiento

- Un mensaje de inventario sin sobre `hea.request` es rechazado como `packet.unknown`.
- El equipamiento de un objeto valida que el personaje cumpla requisitos (nivel, clase, raza).
- El uso de un ítem valida que el objeto pertenezca al personaje y que esté en una ranura válida.
- La destrucción de un objeto es irreversible y libera la ranura correspondiente.
- El almacenamiento (baúl) es compartido por cuenta y accesible desde cualquier personaje.

## Referencia para Godot Mono C#

- Usar `Google.Protobuf` 3.35.1 para serializar/deserializar los payloads de inventario.
- Usar `System.Net.Sockets.TcpClient` para el canal 5555.
- Documentación oficial de Godot 4.x: https://docs.godotengine.org/es/4.x/
