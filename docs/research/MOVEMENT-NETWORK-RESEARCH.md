# Investigación: movimiento, rejilla isométrica y red

## 1. Objetivo

El movimiento del cliente combina cuatro problemas distintos:

1. representar una rejilla isométrica;
2. calcular una ruta local;
3. comprobar visibilidad y obstáculos;
4. sincronizar una intención con un servidor autoritativo.

No deben mezclarse en una única función. El renderer puede mostrar una
previsualización, pero el servidor decide si la ruta es válida.

## 2. Afirmaciones recibidas y nivel de confianza

El texto de investigación adjunto propone estos puntos:

- Dofus 1.29 usa históricamente mapas de 560 celdas;
- existen transformaciones entre CellID y coordenadas;
- A* y Dijkstra son algoritmos útiles para navegación;
- las rutas antiguas pueden comprimirse mediante cambios de dirección;
- Dofus 2.0 separa pathfinding de renderizado;
- la generación moderna usa esquemas binarios/Protocol Buffers.

Estos puntos son plausibles como orientación histórica, pero no se deben
convertir en código sin verificar:

- versión exacta;
- formato real de los mapas;
- convención de coordenadas;
- orden de vecinos;
- codificación de rutas;
- contrato del servidor Jondo;
- significado de cada flag de celda.

## 3. Modelo de celda

La representación recomendada para DreamFus es explícita:

```text
Cell
├── cell_id
├── x
├── y
├── height
├── walkable
├── line_of_sight
├── movement_cost
├── occupied
├── interactive
└── visual_layers
```

Separar `walkable` de `line_of_sight`: una celda puede ser caminable y bloquear
un hechizo, o ser inaccesible para caminar pero no bloquear una línea de
visión, dependiendo de las reglas del mapa.

## 4. Conversión CellID/coordenadas

No fijar una fórmula solo por una descripción de Internet. Crear primero un
test con celdas conocidas del formato que realmente consume el servidor:

```text
cell_id -> (x, y)
(x, y) -> cell_id
round_trip(cell_id) == cell_id
```

Casos requeridos:

- primera celda;
- última celda;
- celdas en los cambios de fila;
- mapas rectangulares;
- mapas con celdas fuera de uso;
- coordenadas negativas si el formato las permite.

La fórmula de una referencia histórica de 14 columnas y filas alternadas
puede conservarse en un documento de investigación, pero no debe implementarse
hasta que los tests usen datos de mapas de DreamFus.

## 5. Vecindad y costes

Definir un orden único de vecinos:

```text
up_right
down_right
down_left
up_left
```

La decisión debe quedar centralizada porque afecta a:

- A*;
- línea de visión;
- compresión de rutas;
- animación;
- desempate entre rutas equivalentes.

El coste debe poder extenderse:

```text
cost(cell, actor, context)
```

El contexto puede incluir:

- combate o mundo;
- entidad que se mueve;
- obstáculos temporales;
- PM disponibles;
- estados que alteren movimiento;
- reglas de terreno.

## 6. A* y Dijkstra

### A*

Usar A* cuando existe un destino y una heurística admisible:

```text
f(node) = g(node) + h(node)
```

El módulo debe devolver un resultado explícito:

```text
PathResult
├── Found(path, total_cost)
├── Unreachable
├── InvalidStart
├── InvalidDestination
└── Cancelled
```

No devolver una lista vacía para todos los errores; eso oculta la causa.

### Dijkstra

Usarlo para:

- alcance completo desde una celda;
- mostrar todas las celdas alcanzables con PM;
- mapas donde no se puede asumir una heurística;
- pruebas de comparación contra A*.

### Validación

La ruta local debe comprobar:

- origen válido;
- destino válido;
- celdas dentro del mapa;
- transitabilidad;
- ocupación;
- coste total;
- límite de PM;
- cambios de estado durante el cálculo.

## 7. Línea de visión

La línea de visión debe ser un módulo separado del pathfinding:

```text
has_line_of_sight(origin, target, map, rules) -> VisibilityResult
```

Documentar:

- qué celdas intermedias se examinan;
- cómo se tratan alturas;
- cómo se tratan entidades;
- si el origen y el destino bloquean;
- qué ocurre con diagonales;
- cómo se comportan las esquinas.

Tests mínimos:

- línea abierta;
- obstáculo central;
- obstáculo en esquina;
- objetivo fuera del mapa;
- altura diferente;
- entidad temporal;
- combate con obstáculo dinámico.

## 8. Compresión de rutas

El texto adjunto describe una posible compresión por nodos de inflexión. Eso
debe tratarse como una hipótesis hasta confirmar el protocolo.

La arquitectura permite dos formatos:

```text
FullCells(Vec<CellId>)
CompressedDirections(Vec<Segment>)
```

Donde un segmento puede ser:

```text
Segment
├── direction
└── length
```

Tests de round-trip:

```text
compress(decompress(path)) == canonical(path)
decompress(compress(path)) == path
```

Nunca enviar una ruta comprimida a producción hasta comparar bytes con una
sesión sintética válida del servidor.

## 9. Movimiento de red

Flujo recomendado:

```text
pointer input
  -> cell hit-test
  -> local preview
  -> command validation
  -> encode movement intent
  -> server
  -> accepted/rejected
  -> authoritative movement events
  -> animation
  -> model update
```

Si el servidor rechaza la ruta:

- cancelar la previsualización;
- conservar la posición autoritativa;
- mostrar un error contextual;
- no corregir silenciosamente con una ruta distinta.

Si llega una actualización mientras se anima:

- comparar versión o secuencia;
- cancelar o reconciliar la animación;
- aplicar la posición autoritativa;
- registrar el motivo en modo debug.

## 10. Referencias nuevas para verificar

- [Arakne/ArakneUtils](https://github.com/Arakne/ArakneUtils): utilidades Java
  para mapas, encoding, línea de visión y pathfinding; la búsqueda consultada
  declara LGPL-3.0.
- [HetwanDofus/dofusgodotclient](https://github.com/HetwanDofus/dofusgodotclient):
  cliente Godot/C#; estudiar renderer y separación de escena, verificando el
  commit y la licencia antes de extraer ideas concretas.
- [Alex-Dufour/bot-dodo](https://github.com/Alex-Dufour/bot-dodo): proxy y
  navegación; estudiar solo con datos sintéticos y sin interceptar cuentas.
- [LuaxY/dofus-unity-protocol-builder](https://github.com/LuaxY/dofus-unity-protocol-builder):
  generación/inspección de protocolo.

La búsqueda no confirmó todos los nombres citados en el texto adjunto, como
`D3BDofus`, `Dofus-Discovery` o `Dofus-like-game`. Deben permanecer como
referencias pendientes hasta localizar su URL y licencia exactas.

