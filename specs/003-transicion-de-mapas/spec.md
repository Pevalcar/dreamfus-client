# 003 — DreamFus Client MVP: transición entre mapas

## 1. Contexto y objetivo

Cuando el personaje camina hacia un borde de mapa, el servidor controla la transición:
- El cliente detecta que la ruta lleva a una celda de borde.
- Pide permiso de salida (`jqi` → `jsq` → `jqk`).
- El servidor ordena el mapa destino (`jsd` + `jru`).
- El cliente carga el nuevo mapa y sitúa al jugador en la celda de llegada.

**Escala:** 001 — Login y selección, 002 — Mapa y movimiento, 004 — Combate.

## 2. Protocolo de transición

### 2.1 Detección de borde

Límites del mapa (celdas 0-254 en rejilla 15x17):

| Dirección | Condición | Cell delta | Facing esperado |
|-----------|-----------|------------|-----------------|
| Izquierda | Cell % 15 == 0 | +13 | 3 (Oeste) |
| Derecha | (Cell + 1) % 15 == 0 | -13 | 1 (Este) |
| Arriba | Cell < 15 | +532 | 6 (Norte) |
| Abajo | Cell >= 240 | -532 | 2 (Sur) |

El cliente detecta borde al recibir `jrw` con destino fuera del mapa actual.

### 2.2 Secuencia del servidor

```
jqi {}                       →  el jugador llega a un borde
jsq {}                       ←  permiso del servidor (root 3)
jqk { f2: mapa_vecino }      →  el cliente propondría el mapa
jsd { f2: mapa }             ←  el servidor confirma el mapa
jru { f2: mapa }             →  CARGA EL NUEVO MAPA
lqu                           →  sincronización de reloj (opcional)
hjk                           →  ACTORES DEL NUEVO MAPA
lva                           →  fin de actores
jrh                           →  notificación de llegada
jss                           →  lista de actores
kmv                           →  posición del jugador
```

### 2.3 Celda de llegada

El `kmv` contiene la celda exacta donde el jugador aparece en el nuevo mapa.

## 3. Requisitos funcionales

**RF-13 — Indicación de transición.** El cliente deberá informar visualmente que hay una transición.
- *Estado:* Mientras el servidor procesa, el cliente deberá mostrar un estado espera (spinner o mensaje).

**RF-14 — Posición inicial del nuevo mapa.** El cliente deberá ubicar al jugador en la celda correcta del mapa nuevo.
- *Evento:* Tras recibir `jru` con el nuevo mapa, el cliente deberá esperar `kmv` para colocar al jugador.
- *Ubicuo:* Si no se recibe `kmv` en 3s, el jugador aparece en celda 0 (esquina superior izquierda).
- *Condicional:* Si el mapa no tiene assets locales, el cliente mostrará error y no quedará en pantalla vacía.

**RF-15 — Actualización de HUD tras transición.** El cliente deberá refrescar estadísticas del jugador al cargar un nuevo mapa.
- *Evento:* Cuando el servidor envíe `jrs` (stat update) después de `jru`, el cliente deberá actualizar barra de vida, PA y PM.
- *Condicional:* Si no se recibe `jrs` en 2s, el HUD mantiene valores del mapa anterior.

**RF-16 — Limpieza de actores del mapa anterior.** El cliente deberá eliminar actores del mapa anterior al cargar uno nuevo.
- *Evento:* Antes de procesar `hjk` del nuevo mapa, el cliente deberá limpiar todos los actores del mapa anterior.
- *Ubicuo:* Los sprites de NPCs, monstruos y otros jugadores desaparecen al iniciar la carga del nuevo mapa.

**RF-17 — Salida y transición de mapa.** El cliente deberá cruzar a mapas vecinos con permiso del servidor.
- *Evento:* Cuando la caminata termine en una celda de borde, el cliente deberá pedir permiso de salida (`jqi`).
- *Evento:* Cuando el servidor lo conceda (`jsq`), el cliente deberá proponerle el mapa vecino (`jqk`) y esperar su orden.
- *Evento:* Cuando el servidor ordene cargar un mapa (`jsd`+`jru`), el cliente deberá pintarlo, pedir sus actores y situar al personaje en la celda de llegada indicada.
- *Condicional:* Si el servidor no concede la salida o no hay mapa al otro lado, entonces el personaje deberá quedarse en el mapa actual.

**RF-18 — Manejo de bordes sin mapa vecino.** El cliente deberá informar cuando un borde no conduce a otro mapa.
- *Evento:* Si el servidor no responde (`jsq` missing): timeout 5s, el jugador se queda en el borde.
- *Condicional:* Si `jqk` enviado pero `jsd` no llega: se descarta el mapa propuesto.

## 4. Requisitos no funcionales

- **RNF-3 — Transición sin huecos.** El cambio de mapa no deberá dejar la pantalla vacía más de 1 segundo.
- **RNF-9 — Posición de mapa.** El mapa mostrado es siempre el que ordena el servidor; el cliente nunca lo sustituye.
- **RNF-10 — Assets disponibles.** Si el mapa destino no tiene assets locales, el cliente mostrará error y no quedará en pantalla vacía.

## 5. Casos límite

- Salida concedida hacia un mapa sin assets locales: mensaje y vuelta al mapa actual.
- El servidor no responde (`jsq` missing): timeout 5s, el jugador se queda en el borde.
- `jqk` enviado pero `jsd` no llega: se descarta el mapa propuesto.
- Múltiples bordes intentados seguidos: el primero procesa, los siguientes se ignoran hasta nueva confirmación.
- Cierre de ventana durante transición: sin efectos al reabrir.
- Timeout de movimiento (>3s): el personaje se detiene y muestra error.

## 6. Fuera de alcance

- Movimiento continuo durante transición.
- Animaciones de aparición del nuevo mapa.
- Combate (ver spec 004).
- HUD con estadísticas del jugador en el nuevo mapa.

## 7. Criterios de finalización

1. Al caminar hacia un borde con mapa vecino, el cliente recibe confirmación y carga el nuevo mapa.
2. El jugador aparece en la celda correcta según `kmv`.
3. Todos los RF quedan verificados contra sus criterios, a mano o con prueba automatizada.
4. No aparece ni un texto en inglés en la interfaz.

## 8. Dudas abiertas

1. **[NECESITA ACLARACIÓN]** ¿Cuál es la ruta de mapas de prueba para validar transiciones (Astrub → vecino → otro)?