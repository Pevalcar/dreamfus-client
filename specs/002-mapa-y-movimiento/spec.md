# 002 — DreamFus Client MVP: mapa y movimiento

## 1. Contexto y objetivo

Una vez el jugador elige personaje y el servidor confirma la entrada, el cliente debe:
- Pintar el mapa asignado con los assets reales (suelo, decorado, isométrico).
- Mostrar al jugador en su celda con su aspecto (sprite de color por ahora).
- Permitir moverse por clic con pathfinding y confirmación del servidor.
- Mostrar actores del mapa (jugadores, NPCs, monstruos) como sprites de color.

**Escala:** 001 — Login y selección, 003 — Transición entre mapas, 004 — Combate.

## 2. Pintado del mapa

El servidor envía `jru {f2: map_id}` con el ID del mapa. El cliente:
1. Carga `map_cells.json` y `map_walkable.json` del mapa.
2. Pinta suelo y decorado isométricamente con assets de Alea.
3. Las celdas no caminables se marcan visualmente.
4. La celda del jugador se resalta al recibir `jrh`.

## 3. Movimiento

El movimiento es solicitado por clic:
1. El cliente calcula la ruta más corto (A*) evitando celdas no caminables.
2. Envía `jrw` con la **ruta completa** al servidor.
3. El servidor devuelve la ruta aceptada (puede ser parcial).
4. El cliente anima el recorrido celda a celda.

**Nota:** El servidor decide si hay obstáculos y ajusta la ruta. El cliente nunca asume movimientos.

## 4. Representación de actores

El servidor envía los actores vía `jss` hasta `lva`:
- **Tipo 1 (jugador):** sprite de color único por nombre.
- **Tipo 4 (monstruo):** sprite de color por grupo.
- **Tipo 7 (NPC):** sprite de color estándar.

Sin `lva`, el cliente no procesa los actores.

## 5. Ráfaga de bienvenida

**Verificado contra código del servidor** (`ConnectionProtocol.cs:101-160`). La ráfaga de bienvenida tiene dos variantes:

### 5.1 Login normal (sin personaje conectado)

La ráfaga **termina en `jtg`** y luego continúa con los datos del personaje:

```
kra → lqu → hoy → kqu → mgq → mgt → hpd → krs → mgz → kqp → kqp → kqp → jtg → [kvw → kva → kub → lqc → jru]
```

- `kra`: abre la ráfaga (AuthenticationTicketAcceptedMessage)
- `lqu`: sincronización de reloj (BasicTimeMessage)
- `hoy`: datos de habilidad del servidor
- `kqu`: funcionalidades activas del servidor
- `mgq`, `mgt`, `hpd`: capacidades de cuenta
- `krs`: estado de suscripción
- `mgz`: versión del catálogo de contenido
- `kqp`×3: mensajes sin significado establecido
- `jtg` (GameActionItemListEvent): catálogo de regalos, puede venir vacío; **es el final del burst normal**

### 5.2 Confirmación de selección del personaje

Tras `jtg`, el flujo completo es:
```
kvw {f1: id_personaje} → kva {f1: detalles} → kub → lqc → jru {f2: mapa}
```

- `kvw` → `kva`: solicitud y confirmación de selección del personaje
- `kub`: hoja de características (CharacterCharacteristicsEvent)
- `lqc`: SequenceNumberRequest; el cliente lo envía para solicitar el bloque de mapa
- `jru`: MapCurrentEvent con el mapa inicial; el bloque incluye tiempo del servidor, hechizos y barras de atajos

**Nota:** `lqc` se envía **por el cliente después de recibir `kub`**, no por el servidor. El `kqo` (PingRequest) cada 5s es un fallback si no se envía `lqc`.

### 5.3 Reconexión a combate/koliseo

Cuando un personaje está en combate o koliseo (`resumable = true`), el burst se detiene en `mgz`. El cliente envía `kvc` (CharacterListRequest) y el servidor responde:

```
(mgz) → kvc → kvi + kvd → kwb
```

- `kvd` (CharacterForceSelectionEvent): "do not stop here"; solo aparece cuando hay combate reanudable.
- `kvd` detiene el burst; el cliente procede con `kwb` (CharacterForceSelectionReadyRequest) para reanudar el combate.
- `krv` (TokenValidationRequest) existe en el protocolo pero el servidor no lo usa en este flujo.

## 6. Requisitos funcionales

**RF-7 — Pintado del mapa.** El cliente deberá representar el mapa asignado por el servidor.
- *Evento:* Cuando reciba `jru`, el cliente deberá cargar y pintar el mapa con suelo, decorado y orientación isométrica usando los assets reales.
- *Condicional:* Si el mapa no está disponible localmente, el cliente deberá mostrar un mensaje de error y esperar.

**RF-8 — Retroalimentación de celda.** El cliente deberá señalar la celda bajo el puntero.
- *Estado:* Mientras el puntero esté sobre una celda, el cliente deberá resaltarla y distinguir si es caminable.

**RF-9 — Representación del personaje.** El cliente deberá mostrar al jugador en su celda.
- *Evento:* Cuando el personaje aparezca o cambie de celda, el cliente deberá dibujarlo como sprite de color en la celda y orientación confirmadas.

**RF-10 — Movimiento por clic.** El cliente deberá mover al personaje a la celda solicitada.
- *Evento:* Cuando el jugador haga clic en una celda caminable, el cliente deberá calcular la ruta más corto y enviarla completa al servidor.
- *Evento:* Cuando el servidor devuelva el recorrido, el cliente deberá animarlo celda a celda en el orden recibido.
- *Condicional:* Si no hay ruta o el servidor no devuelve el recorrido, el cliente deberá dejar al personaje donde estaba y dar una señal breve.

**RF-11 — Posición confirmada.** El cliente deberá mostrar al personaje solo donde el servidor lo confirma.
- *Ubicuo:* El cliente deberá colocar al personaje en la celda y orientación que indique el servidor, nunca en la que él supuso.
- *Condicional:* Si una petición de movimiento no se confirma, entonces el personaje no deberá moverse.

**RF-12 — Secuencia de bienvenida.** El cliente deberá procesar la ráfaga completa de mensajes tras seleccionar personaje.
- *Evento:* En login normal (sin personaje en lucha), el cliente deberá recibir: `kra`, `lqu`, `hoy`, `kqu`, `mgq`, `mgt`, `hpd`, `krs`, `mgz`, `kqp`×3, `kvi` (lista de personajes), `jtg` (catálogo regalos, puede estar vacío).
- *Evento:* En reconexión a combate (`resumable = true`), el burst se detiene en `mgz`. El cliente envía `kvc` → recibe `kvi` + `kvd` → envía `kwb` → el servidor inicia combate. El cliente **no** recibe `jtg`.
- *Evento:* Cuando el jugador seleccione un personaje, el cliente deberá recibir: `kvw`, `kva`, `kub`, `lqg` (sequence number), `jru` (mapa cargado).
- *Ubicuo:* El cliente deberá procesar los catálogos (`lqu`, `lqc` del cliente) antes de mostrar el mapa.

## 7. Requisitos no funcionales

- **RNF-5 — Fluidez.** El movimiento en un mapa estándar deberá mantenerse fluido en una ventana de 1080p.
- **RNF-6 — Tiempo de carga.** Desde recibir `jtu` hasta ver el mapa pintado debe ser < 3 s en red local.
- **RNF-8 — Actores sin lista.** Ningún actor se procesa hasta recibir el fin de lista (`lva`).
- **RNF-9 — Posición de mapa.** El mapa mostrado es siempre el que ordena el servidor; el cliente nunca lo sustituye por su suposición.

## 8. Casos límite

- Clic en celda no caminable: sin movimiento, con señal visual.
- Destino aislado: sin movimiento, con señal visual.
- Recorrido no devuelto: parada.
- Timeout de carga de mapa (>3 s): mensaje y vuelta al login.
- Lista de actores sin fin (`lva` faltante): timeout 5s, pantalla vacía, botón de reinicio mapa.
- Actor de tipo desconocido: se ignora visualmente.

## 9. Fuera de alcance

- Transición entre mapas (ver spec 003).
- Combate (ver spec 004).
- HUD con estadísticas, vida actual, barra de hechizos.
- Animaciones de caminar (sprite estático por ahora).
- Interacción con NPCs, monstruos o elementos.

## 10. Criterios de finalización

1. Un jugador ve el mapa pintado con assets reales y su personaje en la celda inicial.
2. Al hacer clic, se calcula ruta y el personaje avanza recibiendo confirmación.
3. Todos los RF quedan verificados contra sus criterios, a mano o con prueba automatizada.
4. No aparece ni un texto en inglés en la interfaz.

## 11. Dudas abiertas

1. **[NECESITA ACLARACIÓN]** ¿La animación de andar en varias direcciones entra en el MVP, o basta el sprite girando sin ciclo de caminar?
2. **[NECESITA ACLARACIÓN]** ¿Se muestra la vida actual del HUD en este spec, o queda para spec 004?