# Opcodes de Conexión y Bienvenida — Cliente Godot Mono C#

Documenta los opcodes del handshake, el ticket de juego, la rafaga de bienvenida y la selección de personajes.

## Tabla de opcodes

| Opcode | Dir | Qué hace | Handler | Campos | Respuesta | Tiempo |
|--------|-----|----------|---------|--------|-----------|--------|
| `kqz` | C→S | Presenta el ticket de juego. Vincula la sesión TCP a una cuenta y servidor. Ticket desconocido cierra la conexión. | `GameNodeProxy.HandleTicketPresentation` | `f2: ticket` (string, 32 hex) | — | Inmediata |
| `kra` | S→C | Abre la rafaga de bienvenida. | `ConnectionProtocol.BuildWelcomeBurst` | vacío | — | — |
| `lqu` | S→C | Sincronización del reloj. También se envía en cada cambio de mapa. | `BuildWelcomeBurst`, `BuildMapClock` | `f1: 120` (sync rate), `f2: server clock unix ms` | — | — |
| `hoy` | S→C | Game-server hello. `f5` ausente en las capturas. | `BuildHoy` | `f1: 30, f2: 1, f3: 1, f6: language, f7: 200` | — | — |
| `kqu` | S→C | Features habilitadas en el servidor, como IDs opacos copiados de captura. | `BuildWelcomeBurst` | `f1: packed [3, 7, 13, 20, 23, 105, 124, 125, 126, 136, 143, 145, 150]` | — | — |
| `kvi` | S→C | Lista de personajes de la cuenta en el servidor elegido. | `BuildCharactersList` | `f1 (rep) { f1 { f2: name, f3: level, f4 { f2 { f3: sex } }, f6: look, f7: breed }, f2: characterId }` | — | — |
| `kvd` | S→C | Cierra la lista de personajes. Vacío, inmediatamente detrás de `kvi`. | `BuildWelcomeBurst` | vacío | — | — |
| `kqr` | S→C | Respuesta a `kqq`. El cliente cierra la conexión y rehace el handshake. | `GameNodeProxy.BuildKqrPayload` | `f1: session guid, f4: 1` | — | — |
| `kvz` | C→S | Crear un personaje. | `CharacterCreationHandler.CreateAsync` | lee name, breed, sex, look | `kvb` | Inmediata |
| `kvb` | S→C | Resultado de la creación. Vacío en éxito; `f2` lleva la razón de rechazo. | `CharacterCreationHandler` | vacío, o `f2: reason` | — | — |
| `kvk` | S→C | Nombre sugerido de personaje (botón de dados). | `CharacterCreationHandler.SuggestNameAsync` | `f1: name` | — | — |
| `kvw` | C→S | Seleccionar un personaje. El ID se comprueba contra la cuenta de la sesión. | `CharacterSelectionHandler` | lee character id | `kva` | Inmediata |
| `kvl` | C→S | Selección justo tras creación exitosa; entra al mundo sin pasar por la lista. | `CharacterSelectionHandler` | lee character id | `kva` | Inmediata |
| `kva` | S→C | "Ya estás jugando este personaje." Sin él el cliente se queda con el reloj de arena. | `BuildCharacterSelectedSuccess` | `f1 { f1 { f1: details, f2: characterId } }` | — | — |
| `kpa` | C→S | Solicitud de lista de personajes. Despachada, vista 1 vez en 242 capturas. | `CharacterSelectionHandler.HandleCharacterListRequest` | — | `kvi` | Inmediata |

## Ejemplo byte a byte: `kqz` (ticket de juego)

```
Hex: 12-3D-0A-13-74-79-70-65-2E-61-6E-6B-61-6D-61-2E-63-6F-6D-2F-6B-71-7A-12-26-12-20-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-78-1A-02-65-73-10-2D
```

| Bytes | Campo | Descripción |
|-------|-------|-------------|
| `12 3D` | Campo 2 de la raíz (request/hdy) | 61 bytes |
| `0A 13 "type.ankama.com/kqz"` | Campo 1 del Any (type_url) | Identifica el opcode |
| `12 26` | Campo 2 del Any | 38 bytes de payload `kqz` |
| `12 20 <ticket 32 x's>` | Campo 2 del kqz (`fytk`) | TicketKey: ticket de 32 hex |
| `1A 02 "es"` | Campo 3 del kqz (`fytl`) | LanguageCode: idioma |
| `10 2D` | Campo 2 del sobre `hea` (uid) | -1 como varint (sin correlación) |

## Advertencias

- `kqz` sin sobre `hea` ni `uid` es rechazado como `packet.unknown` con `opcode=kqz` y `kind=Unhandled`.
- El ticket debe ir en minúsculas.
- `kqu` **no** es una solicitud de lista de personajes: el servidor lo empuja en la rafaga y el cliente nunca lo envía.
