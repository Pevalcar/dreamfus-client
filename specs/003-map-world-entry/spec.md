# Spec 003 — Visualización de mapa y entorno del jugador

## Contexto y objetivo

Esta especificación define el sistema de visualización del mapa tras la selección del personaje (historia #3 del backlog). Corrige el bug del servidor donde `jru` nunca llega después de `kvw`. Permite al jugador ver su avatar sobre el terreno, manejar assets de mapa y renderizar NPCs/personajes usando datos de la base de datos y assets externos de Alea.

**Problema resuelto:** El cliente no puede mostrar el mundo porque el servidor no envía `jru`. Esta spec define un sistema de renderizado que funciona incluso cuando el `jru` falla, usando el map ID esperado (`191105026`) y assets recuperados de la instalación de Alea.

## Usuarios / actores

- **Jugador casual:** Conecta desde escritorio, ve su avatar en el mapa, mueve la cámara, interactúa con NPCs visuales.

## Historias de usuario

- H1: Como jugador, quiero ver mi avatar en el mapa tras la carga, para interactuar con el mundo.
- H2: Como jugador, quiero ver otros jugadores y NPCs en el mapa, para ver qué hay cerca.

---

## Contratos de frontera (Dominio)

### Entradas y validaciones
- **Map ID:** Entero positivo (ej. `191105026` para Astrub Zaap). Se usa como fallback cuando `jru` es vacío.
- **Datos de avatar:** JSON con `cell_id`, `entity_id`, `kind`, `look` (proviene de mensajes `kva`/`ivx`/`itg`).
- **Assets de mapa:** Tilesets recuperados de `Alea/d3maps/*.d2p` y `Alea/d3gfx_2x_*.d2p`. Formato PNG transposable a AtlasTexture.
- **Tile IDs de terreno:** Enteros que representan tipo de celda (0=vacío, 1=tierra, 2=agua, 3=muro, etc.).

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
| ------------- | --------------- | -------------- | ----------- | ------------------- |
| Esperando jru | jru vacío recibido | Renderizar fallback | Sí | RF-4 |
| Esperando jru | jru válido recibido | Renderizar mapa | Sí | RF-1 |
| Mapa cargado | Avatar spawneado | Jugando | Sí | RF-1 |
| Jugando | Moverse en celdas válidas | Jugando | Sí | RF-2 |

---

## Requisitos funcionales (criterios de aceptación en EARS)

- **RF-1 [H1]:** CUANDO el servidor envía `jru` o el timer expira, EL SISTEMA renderiza el mapa en un TileMap de Godot con el avatar del jugador centrado. (Resultado: pantalla muestra mapa con jugador visible).
- **RF-2 [H1]:** CUANDO el jugador desplaza el ratón por los bordes de pantalla, EL SISTEMA mueve la vista del TileMap isométrico. (Resultado: cámara se desplaza suavemente siguiendo input del ratón).
- **RF-3 [H1]:** CUANDO el jugador intenta moverse a una celda con muro, EL SISTEMA rechaza el movimiento. (Resultado: avatar no se mueve, se reproduce error sonoro).
- **RF-4 [H2]:** CUANDO el servidor envía mensajes de entidad (`kva` con posición), EL SISTEMA posiciona el avatar/NPC en la celda especificada usando transformación isométrica de CellID. (Resultado: entidades aparecen en coordenadas correctas).
- **RF-5 [H2]:** SI el map ID es inválido, ENTONCES EL SISTEMA usa `191105026` (Astrub Zaap) como mapa por defecto. (Resultado: siempre hay un mapa renderizable).

---

## Requisitos no funcionales (RNF)

- **RNF-1 [P-001]:** El sistema usa Node2D + TileMap de Godot 4.8 + GDScript pura. Sin C#, C++ ni plugins externos.
- **RNF-2 [P-002]:** Tiempo de renderizado inicial < 500ms desde que el map ID es válido.
- **RNF-3 [P-003]:** Máximo 500 líneas por archivo `.gd` (MapRenderer.gd, TileCache.gd, etc.).
- **RNF-4 [P-005]:** Los assets se cargan desde cache local (`user://cache/tiles/`) y nunca se almacenan credenciales en ellos.

---

## Casos límite

- **Map ID desconocido:** Usar `191105026` como fallback, loggear advertencia.
- **Assets corruptos:** Mostrar tiles vacíos grisáceos en vez de crashear.
- **Múltiples entidades en misma celda:** Renderizar segunda entidad ligeramente desplazada o con fade.
- **Conexión caída durante render:** Limpiar TileMap y mostrar pantalla de conexión perdida.

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

- ✅ Todos los RF cubiertos por pruebas visuales y unitarias
- ✅ Cumplimiento verificado contra `docs/constitution.md` (P-001 a P-005)
- ✅ Mapa `191105026` renderizado correctamente con avatar del jugador

---

## Dudas abiertas

- [NECESITA ACLARACIÓN] ¿Cómo se obtiene el mapa visual exacto desde los archivos `.d2p`? ¿Se requiere herramienta de decompilación externa o Godot puede leerlos directamente?