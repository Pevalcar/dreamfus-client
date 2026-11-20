# Protocolo de Economía — Cliente Godot Mono C#

Documenta los mensajes de protocolo para compras y mercados que el cliente Godot Mono C# debe implementar para comerciar objetos y kamas con el servidor DreamFus.

## Mensajes de economía disponibles

El servidor expone mensajes de protocolo basados en los handlers `MarketplaceHandler`, `TradeHandler`, `BankHandler`, `CraftHandler`, `GatheringHandler`, `NpcBarterHandler` y handlers de tiendas de objetos.

| Acción | Handler del servidor | Descripción |
|--------|---------------------|-------------|
| Lista de tienda | `MarketplaceHandler` | Consultar objetos en venta con precios y cantidades |
| Comprar objeto | `MarketplaceHandler` | Comprar objeto de una tienda (validar kamas y stock) |
| Vender objeto | `MarketplaceHandler` | Vender objeto a una tienda (validar posesión del objeto) |
| Trueque entre jugadores | `TradeHandler` | Intercambio de objetos y kamas entre dos personajes |
| Banco | `BankHandler` | Gestionar depósitos y retiradas de kamas/objetos en el banco |
| Fabricación | `CraftHandler` | Fabricar objetos mediante profesiones de artesanía |
| Recolección | `GatheringHandler` | Recoger recursos del entorno (minerales, plantas, etc.) |
| Trueque NPC | `NpcBarterHandler` | Comprar/vender con NPCs de la tienda |

## Estructura de mensajes de economía

Cada mensaje de economía SHALL usar el sobre `hea.request` con `uid` y un `Any` cuyo `type_url` identifique el opcode de economía correspondiente:

```
hea.request (campo 2)
  └─ 1: Any { 1: "type.ankama.com/<opcode>", 2: <payload economía> }
  └─ 2: <uid int32 firmado>
```

## Reglas de comportamiento

- Comprar un objeto sin stock o sin kamas suficientes es rechazado.
- Vender un objeto valida que el personaje lo posea en su inventario.
- El trueque entre jugadores valida que ambos estén cerca y estén de acuerdo con el intercambio.
- El banco permite almacenar kamas y objetos de forma segura por cuenta.
- La fabricación requiere los materiales y el nivel de profesión correspondiente.

## Referencia para Godot Mono C#

- Usar `Google.Protobuf` 3.35.1 para serializar/deserializar los payloads de economía.
- Usar `System.Net.Sockets.TcpClient` para el canal 5555.
- Documentación oficial de Godot 4.x: https://docs.godotengine.org/es/4.x/
