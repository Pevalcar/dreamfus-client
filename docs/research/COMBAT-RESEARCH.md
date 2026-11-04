# Investigación: combate táctico

## 1. Principio de autoridad

El servidor es autoritativo para:

- turnos;
- posiciones finales;
- costes;
- alcance efectivo;
- línea de visión;
- daños;
- efectos;
- muerte;
- recompensas;
- resultado del combate.

El cliente puede simular para previsualizar, pero nunca sustituir la
resolución recibida.

## 2. Capas del motor

```text
CombatProtocol
    decodifica eventos y codifica intenciones
CombatState
    mantiene el estado autoritativo conocido
CombatRulesPreview
    calcula alcance/objetivos visibles para feedback
CombatTimeline
    ordena eventos visuales
CombatRenderer
    representa celdas, entidades, hechizos y efectos
```

Separar estas capas permite cambiar el renderer sin cambiar el protocolo.

## 3. Máquina de estados

```text
Idle
Starting
Placement
Ready
TurnStarted
AwaitingAction
ActionPending
Resolving
TurnEnded
Finished
Aborted
```

Cada acción debe incluir un identificador o secuencia cuando el protocolo lo
permita. Así se puede asociar:

```text
intención -> aceptación/rechazo -> eventos -> finalización
```

## 4. Previsualización de hechizos

La previsualización debe ser una función pura:

```text
preview_spell(state, spell_id, target) -> Preview
```

Debe devolver:

```text
Preview
├── valid
├── invalid_reason
├── affected_cells
├── affected_entities
├── estimated_cost
├── line_of_sight
└── warnings
```

Nunca debe modificar `CombatState`.

## 5. Efectos y orden

Un evento de combate debe poder producir una timeline:

```text
ActionStarted
MovementStarted
MovementStep
MovementFinished
SpellStarted
EffectApplied
DamageApplied
StateAdded
StateRemoved
EntityDied
ActionFinished
```

La timeline debe ser:

- ordenada;
- cancelable;
- reproducible;
- independiente del framerate;
- segura ante eventos duplicados;
- descartable al cambiar de escena.

## 6. Placaje, zonas y posiciones

Si el protocolo expone estas reglas, el cliente debe mostrarlas como
previsualización, no como decisión final:

- ocupación de celdas;
- celdas bloqueadas;
- zona de placaje;
- PM restantes;
- línea de visión;
- alcance mínimo/máximo;
- objetivos válidos;
- estados que modifican una acción.

Los algoritmos de referencia como A* no deben codificar reglas de combate
directamente. Deben recibir un `MovementContext` o `CombatContext`.

## 7. Desincronización

Detectar y documentar:

```text
client entity position != server entity position
client turn != server turn
client AP/MP != server AP/MP
unknown effect
missing event sequence
duplicate event
```

Respuesta recomendada:

1. registrar contexto sin credenciales;
2. detener la predicción local afectada;
3. solicitar o esperar snapshot;
4. aplicar el estado autoritativo;
5. reanudar solo cuando el estado sea coherente.

## 8. Tests

### Unitarios

- transición de turno;
- acción válida;
- acción inválida;
- hechizo sin línea de visión;
- coste insuficiente;
- objetivo fuera de rango;
- evento duplicado;
- evento desconocido;
- muerte y limpieza;
- cancelación de timeline.

### Integración

- iniciar combate;
- placement;
- turno del jugador;
- rechazo del servidor;
- acción aceptada;
- secuencia de efectos;
- fin de combate;
- reconexión durante una timeline.

## 9. Fuentes de inspiración

- [AerafalDev/D3BDofus](https://github.com/AerafalDev/D3BDofus) aparece en el
  texto adjunto como motor de simulación táctica; la URL/licencia deben
  verificarse antes de tratarlo como fuente.
- [Rollback](https://github.com/Neyzv/Rollback) y
  [Desperion](https://github.com/scalexm/desperion) sirven para estudiar
  estados de servidor, no para copiar una implementación GPL en este cliente.
- [holomorph](https://github.com/scalexm/holomorph) sirve para comparar
  separación de red y dominio en Rust.

## 10. Decisiones que aún requieren evidencia

- formato final de acciones;
- catálogo real de hechizos;
- representación de efectos;
- identificación de secuencias;
- reglas exactas de placaje;
- snapshot de recuperación;
- si el servidor acepta ruta completa o comprimida;
- duración oficial de cada evento visual.

