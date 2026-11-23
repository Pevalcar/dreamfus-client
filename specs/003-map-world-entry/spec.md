# Spec 003 — Visualización de mapa y entorno del jugador

## Contexto y objetivo

Esta especificación define el sistema de visualización del mapa tras la selección del personaje (historia #3 del backlog). Corrige el bug del servidor donde `jru` nunca llega después de `kvw`. Permite al jugador ver su avatar sobre el terreno, manejar assets de mapa y renderizar NPCs/personajes usando datos de la base de datos y assets externos de Alea.

**Problema resuelto:** El cliente no puede mostrar el mundo porque el servidor no envía `jru`. Esta spec define un sistema de renderizado que funciona incluso cuando el `jru` falla, usando el map ID esperado (`191105026`) y assets recuperados de la instalación de Alea.

**Nota técnica:** El parser `.d2p` será desarrollado internamente en GDScript puro o adaptado de herramientas open-source existentes con licencia compatible (P-001).

## Usuarios / actores

- **Jugador casual:** Conecta desde escritorio, ve su avatar en el mapa, mueve la cámara, interactúa con NPCs visuales.

## Historias de usuario

- H1: Como jugador, quiero ver mi avatar en el mapa tras la carga, para interactuar con el mundo.
- H2: Como jugador, quiero ver otros jugadores y NPCs en el mapa, para ver qué hay cerca.

---

## Contratos de frontera (Dominio)

### Entradas y validaciones
- **Map ID:** Entero positivo (ej. `191105026` para Astrub Zaap). Map IDs inválidos (≤ 0 o no documentados) activan fallback.
- **Datos de avatar:** JSON con `cell_id`, `entity_id`, `kind`, `look` (proviene de mensajes `kva`/`ivx`/`itg`).
- **Assets de mapa:** Tilesets recuperados de `Alea/d3maps/*.d2p` y `Alea/d3gfx_2x_*.d2p`. El parser `.d2p` genera AtlasTexture compatible.
- **Tile IDs de terreno:** Enteros que representan tipo de celda (0=vacío, 1=tierra, 2=agua, 3=muro, 4-255=extensión).

### Salidas y efectos observables
- Screen renders un mapa isométrico con el avatar del jugador en el centro.
- Avatar se mueve con offset isométrico, respetando colisiones de muro.
- NPCs aparecen con sprites obtenidos de DB usando `npc_template_id`.

### Invariantes (reglas inviolables)
- **I1:** El jugador nunca puede moverse a una celda con tile ID de muro (colisión).
- **I2:** El avatar siempre se ve dentro de los límites del mapa.
- **I3:** Si el map ID es inválido, se usa el mapa por defecto `191105026` (Astrub Zaap).

---

## Matriz de estados y transiciones

| Estado actual | Evento / Acción | Estado destino | ¿Permitido? | Regla / RF asociado |
|---------------|-----------------|------------------| ----------- | ------------------- |
| Esperando jru | jru vacío recibido | Renderizar fallback | Sí | RF-1.1 |
| Esperando jru | jru válido recibido | Renderizar mapa | Sí | RF-1 |
| Cargando assets | Parser .d2p fallido | Error visual gris | Sí | RF-6 |
| Mapa cargado | Avatar spawneado | Jugando | Sí | RF-1 |
| Jugando | Moverse en celdas válidas | Jugando | Sí | RF-2 |
| Jugando | Moverse a muro | Jugando | No | RF-3 |
| Jugando | Desconexión TCP | Conectando | Sí | - |
| Jugando | Timer fallback expirado | Error timeout | Sí | RF-1.1 |

---

## Requisitos funcionales (criterios de aceptación en EARS)

- **RF-1 [H1]:** CUANDO el servidor envía `jru` válido, EL SISTEMA renderiza el mapa en un TileMap isométrico con el avatar del jugador centrado. (Resultado: pantalla muestra mapa con jugador visible).
- **RF-1.1 [H1]:** CUANDO el servidor envía `jru` vacío o el timer de 30 segundos expira, EL SISTEMA usa el map ID `191105026` como fallback. (Resultado: pantalla muestra Astrub Zaap con jugador spawneado).
- **RF-2 [H1]:** CUANDO el jugador desplaza el ratón por los bordes de pantalla, EL SISTEMA mueve la vista del TileMap isométrico 5px vertical/horizontal cada 0.05s. (Resultado: cámara se desplaza suavemente).
- **RF-3 [H1]:** CUANDO el jugador intenta moverse a una celda con muro, ENTONCES EL SISTEMA reproduce un sonido de colisión y MANTIENE la posición del avatar. (Resultado: avatar no se mueve, se oye un "boop" breve).
- **RF-4 [H2]:** CUANDO el servidor envía un mensaje con `cell_id` y `entity_id`, EL SISTEMA posiciona el avatar/NPC en esa celda usando transformación isométrica de CellID. (Resultado: entidades aparecen en coordenadas correctas).
- **RF-5 [H2]:** SI el map ID es ≤ 0 o no está en la lista blanca de mapas conocidos, ENTONCES EL SISTEMA usa `191105026` como mapa por defecto. (Resultado: siempre hay un mapa renderizable).
- **RF-6 [H1]:** CUANDO el parser `.d2p` carga un tileset, EL SISTEMA genera un AtlasTexture compatible con Godot 4.8 TileMap. (Resultado: tileset listo para renderizar).

---

## Requisitos no funcionales (RNF)

- **RNF-1 [P-001]:** El sistema usa Node2D + TileMap de Godot 4.8 + GDScript pura. El parser `.d2p` será implementado en GDScript puro o integrado mediante herramientas open-source con licencia compatible.
- **RNF-2 [P-002]:** Tiempo de renderizado inicial < 500ms desde que el map ID es válido.
- **RNF-3 [P-003]:** Máximo 500 líneas por archivo `.gd` (MapRenderer.gd, TileParser.gd, D2PParser.gd, etc.).
- **RNF-4 [P-005]:** Los assets se cargan desde cache local (`user://cache/tiles/`) y nunca se almacenan credenciales en ellos.

---

## Casos límite

- **Map ID desconocido:** Usar `191105026` como fallback, loggear advertencia.
- **Map ID = 0 o negativo:** Activar fallback inmediatamente.
- **Assets corruptos:** Mostrar tiles vacíos grisáceos en vez de crashear.
- **Parser .d2p fallido:** Mostrar pantalla de error "Fallo al cargar mapa" con botón de reintentar.
- **Múltiples entidades en misma celda:** Renderizar segunda entidad ligeramente desplazada o con fade.
- **Race condition timer vs jru válido:** Priorizar el `jru` válido sobre el timer expirado.
- **Tile ID desconocido (> 255):** Mostrar como "vacío" (tile ID 0).
- **Cache saturada:** Evictar tiles menos usados mediante LRU (máx. 500MB).

---

## Fuera de alcance

- Chat entre jugadores (permanente fuera de scope según backlog)
- Tienda/compra de items
- Sistema de amigos
- Gráficos 3D avanzados (solo sprite 2D isométrico)
- Sistema de inventario (permanente fuera de scope según backlog)
- Animaciones de movimiento complejas (solo desplazamiento estático entre celdas)

---

## Criterios de finalización

- ✅ Todos los RF cubiertos por pruebas unitarias y visuales
- ✅ Cumplimiento verificado contra `docs/constitution.md` (P-001 a P-005)
- ✅ Mapa `191105026` renderido correctamente con avatar del jugador
- ✅ Parser `.d2p` funcional y documentado

---

## Dudas abiertas

- Ninguna ✅