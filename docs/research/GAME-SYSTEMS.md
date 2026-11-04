# Diseño de sistemas del cliente

Este documento separa lo que hay que observar en referencias externas de lo que
se recomienda implementar en DreamFus. Las referencias sirven para descubrir
contratos y patrones; no son una autorización para copiar recursos propietarios.

## 1. Combate

### Modelo conceptual

El combate debe tratarse como una máquina de estados determinista:

```text
NoFight
FightStarting
Placement
TurnStarting
AwaitingPlayerAction
ActionSubmitted
ActionResolving
TurnEnding
FightEnding
FightFinished
```

El cliente no decide el resultado. Solo:

1. muestra el estado recibido;
2. valida localmente acciones imposibles para dar feedback rápido;
3. envía la intención del jugador;
4. espera la confirmación del servidor;
5. reproduce eventos y efectos en el orden recibido.

### Datos necesarios

```text
FightState
├── fight_id
├── map_id
├── phase
├── active_entity_id
├── turn_number
├── remaining_time
├── teams
├── entities
├── cells
├── obstacles
├── available_actions
├── pending_effects
└── result
```

Cada entidad debería tener:

```text
entity_id
team
cell
orientation
hit_points
action_points
movement_points
states
initiative
alive
```

### Flujo de acción

```text
seleccionar hechizo
  -> mostrar rango y coste
  -> seleccionar objetivo/celda
  -> validar cliente
  -> enviar intención
  -> recibir aceptación o rechazo
  -> recibir eventos de movimiento/efecto
  -> animar en orden
  -> actualizar estado
```

La selección de objetivos no debe modificar permanentemente el estado. Debe ser
una previsualización hasta que el servidor confirme.

### Orden de eventos

Un evento de combate debe tener un orden reproducible:

```text
ActionStarted
MovementStarted
MovementStep
MovementFinished
SpellStarted
EffectApplied
DamageNumber
EntityStateChanged
ActionFinished
```

No se deben disparar animaciones desde varios listeners sin una cola; eso
produce efectos superpuestos o estados visuales imposibles de reproducir.

### Inspiración

Para estudiar servidores y modelos de combate:

- https://github.com/Neyzv/Rollback
- https://github.com/scalexm/desperion
- https://github.com/hussein-aitlahcen/codebreak
- https://github.com/scalexm/holomorph

Estas referencias son principalmente de servidor. Son útiles para entender los
eventos y estados que un cliente debe representar, no para copiar una UI.

## 2. Animaciones y sonido

### Separar lógica y presentación

El protocolo debe producir eventos semánticos:

```text
EntityMoved
SpellCastStarted
EffectApplied
DamageReceived
EntityDied
TurnChanged
```

El sistema visual decide cómo representarlos:

```text
evento semántico
  -> animation timeline
  -> sprite/model animation
  -> sound cue
  -> completion callback
```

Nunca se debe hacer depender la lógica de combate de que un sonido haya
terminado.

### Cola de animación

Cada mapa y combate necesita una cola cancelable:

```text
AnimationQueue
├── enqueue(animation)
├── pause()
├── resume()
├── cancel()
└── drain()
```

Al cambiar de mapa, cerrar combate o desconectar:

1. cancelar animaciones;
2. liberar listeners;
3. detener sonidos asociados;
4. descartar callbacks pendientes;
5. montar la nueva escena.

### Formato de assets propio

Cada recurso debe tener una entrada en un manifiesto:

```json
{
  "id": "spell.fire.impact",
  "kind": "animation",
  "file": "effects/spell-fire-impact.json",
  "sound": "sounds/spell-fire-impact.ogg",
  "license": "original",
  "version": 1
}
```

No añadir al repositorio assets extraídos del cliente oficial. Crear
placeholders propios o usar recursos con licencia compatible y conservar la
atribución.

### Sonido

Separar buses:

```text
master
├── music
├── effects
├── ui
└── ambience
```

Configuraciones necesarias:

- volumen independiente;
- silenciar;
- dispositivo de salida;
- no iniciar sonido antes de la interacción cuando el sistema lo impida;
- liberar recursos al cerrar una escena.

## 3. Movimiento

### Datos de mapa

El modelo de mapa debe distinguir:

```text
MapState
├── map_id
├── width
├── height
├── cells
├── walkable
├── line_of_sight
├── movement_cost
├── interactive_elements
├── visual_layers
└── neighbours
```

La UI no debe calcular una ruta distinta de la que acepta el servidor. Puede
mostrar una previsualización, pero el servidor es la autoridad.

### Flujo de movimiento

```text
clic en celda
  -> verificar que la celda está cargada
  -> previsualizar ruta
  -> enviar destino o ruta según contrato
  -> recibir confirmación
  -> reproducir pasos recibidos
  -> actualizar celda final
```

Casos que deben cubrirse:

- mapa todavía cargando;
- celda no caminable;
- entidad que bloquea;
- cambio de mapa durante la ruta;
- cancelación por combate;
- desconexión;
- doble clic;
- dos actualizaciones de posición seguidas.

## 4. Chat

### Canales

```text
global
local
grupo
gremio
privado
combate
sistema
```

El modelo debe mantener mensajes como datos, no como HTML sin validar:

```text
ChatMessage
├── id
├── channel
├── sender_id
├── sender_name
├── timestamp
├── text
├── formatted_segments
└── moderation_flags
```

La vista debe escapar texto y permitir una política clara para enlaces,
emotes y formato. No ejecutar HTML recibido del servidor.

## 5. Inventario

### Modelo

```text
InventoryState
├── items
├── equipment_slots
├── currencies
├── weight
├── weight_limit
├── selected_item
└── pending_operation
```

Cada item debe tener una identidad estable:

```text
item_uid
template_id
quantity
position
stats
effects
linked
durability
```

El cliente muestra operaciones posibles, pero no confirma una venta,
equipamiento, destrucción o intercambio sin respuesta del servidor.

Funciones visuales recomendadas:

- grid virtualizado;
- tooltip;
- filtros;
- ordenación;
- comparación de equipamiento;
- icono de cantidad;
- indicador de peso;
- estado pendiente mientras llega la respuesta;
- rollback visual si la operación falla.

## 6. Ventanas del mundo

El cliente debería tener una jerarquía explícita:

```text
AppRoot
├── Background
├── WorldLayer
│   ├── MapRenderer
│   ├── EntityLayer
│   └── WorldEffects
├── HudLayer
├── ChatLayer
├── ModalLayer
└── DebugLayer
```

Una ventana modal debe:

- capturar el foco;
- impedir que el clic llegue al mapa;
- poder cerrarse de forma determinista;
- retirar sus listeners;
- conservar tamaño/posición si corresponde;
- declarar su z-index o capa;
- ser accesible por teclado.

La documentación de cada ventana debe registrar:

```text
id
parent layer
componentes
márgenes
espaciado
colores
tema
escala
estados
eventos de entrada
eventos de salida
pruebas manuales
```

## 7. Personajes y entidades

### Entidad base

```text
Entity
├── id
├── kind
├── name
├── position
├── orientation
├── appearance
├── animation_state
├── visibility
└── metadata
```

El renderer debe ser capaz de:

- crear una entidad;
- actualizarla parcialmente;
- cambiar su celda;
- cambiar orientación;
- reproducir entrada/salida;
- ocultarla temporalmente;
- destruirla;
- ignorar mensajes duplicados o antiguos.

El estado de red y la instancia visual no deben ser la misma estructura. Una
entidad puede existir en el modelo mientras su sprite se está cargando.

## 8. Selección de personaje y carga del mundo

### Flujo completo

```text
Disconnected
  -> Connecting
  -> Authenticated
  -> CharacterListRequested
  -> CharacterListReady
  -> CharacterSelected
  -> MapRequested
  -> MapMetadataReady
  -> MapVisualsReady
  -> EntitiesRequested/Received
  -> WorldReady
```

### Selección de personaje

La pantalla debe:

- mostrar solo personajes recibidos;
- distinguir carga, vacío y error;
- no usar datos ficticios en modo real;
- bloquear doble selección;
- mostrar la versión/protocolo compatible;
- cancelar listeners al abandonar la pantalla.

### Carga de mapa

Separar:

1. metadatos;
2. celdas y reglas de movimiento;
3. capas visuales;
4. interactivos;
5. entidades;
6. efectos de entrada.

Esto permite mostrar una pantalla de carga sin inventar entidades antes de
recibirlas.

### Carga de entidades

Usar un reconciliador:

```text
mensaje recibido
  -> validar entity_id
  -> comparar versión/timestamp
  -> crear, actualizar o eliminar
  -> notificar al renderer
```

No hacer `clear()` global del mapa cada vez que llega una actualización parcial.

## 9. Replay e inspector

Estas dos herramientas deben construirse pronto porque reducen el coste de
desarrollar todos los sistemas:

```text
Inspector
  frame -> opcode -> payload -> reducer -> UI

Replay
  archivo de eventos -> reloj controlable -> mismo reducer -> UI
```

Un replay de referencia debería cubrir:

```text
login
character list
character selection
map loading
entity spawn
movement
chat
inventory update
fight start
spell action
fight end
disconnect/reconnect
```

