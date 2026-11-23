# Tareas de Implementación — Spec 003: Visualización de mapa y entorno

**Generado:** 23 Nov 2026  
**Estado:** `clarification.status = PASS` ✅

---

## 📊 Matriz de Tareas

| Tarea | Estado | Estimación | Archivo | RF |
|-------|--------|------------|---------|-----|
| T1.1: Crear LRU Cache base (100MB) | 📋 Ready | 45 min | `src/Data/TileCache.gd` | RF-6 |
| T1.2: Parser header .d2p básico | 📋 Ready | 1.5h | `src/Network/D2PParser.gd` | RF-6 |
| T1.3: Tests unitarios TileCache | 📋 Ready | 30 min | `test/test_tile_cache.gd` | - |
| T2.1: MapManager con fallback ID | 📋 Ready | 30 min | `src/Core/MapManager.gd` | RF-1.1 |
| T2.2: MapRenderer (Node2D + TileMap) | 📋 Ready | 1.5h | `src/Systems/MapRenderer.gd` | RF-1 |
| T2.3: CellID → Coordenadas isométricas | 📋 Ready | 45 min | `MapRenderer.gd` | RF-4 |
| T2.4: Cachear tilesets cargados | 📋 Ready | 30 min | `MapRenderer.gd` | RF-1 |
| T3.1: CameraController base | 📋 Ready | 1h | `src/Systems/CameraController.gd` | RF-2 |
| T3.2: Edge-scrolling implementado | 📋 Ready | 45 min | `CameraController.gd` | RF-2 |
| T3.3: Smooth zoom/pan opcional | 📋 Ready | 15 min | `CameraController.gd` | RF-2 |
| T4.1: WorldViewport contenedor | 📋 Ready | 30 min | `src/UI/WorldViewport.gd` | RF-1 |
| T4.2: Integrar con GameManager | 📋 Ready | 45 min | `GameManager.gd` | RF-1 |
| T4.3: Fallback visual gris | 📋 Ready | 15 min | `MapRenderer.gd` | - |
| T4.4: Documentar API pública | 📋 Ready | 30 min | `*_gd` | - |
| T5.1: Test TileCache LRU | 📋 Ready | 20 min | `test/test_tile_cache.gd` | - |
| T5.2: Test isometría | 📋 Ready | 20 min | `test/test_map_renderer.gd` | - |
| T5.3: Test edge-scroll | 📋 Ready | 20 min | `test/test_camera.gd` | - |

**Total:** 17 tareas, 10.5 horas estimadas

---

## 🎯 Tareas por Fase

### Fase 1: Infraestructura de datos ⏱️ 2.5h

#### T1.1: Crear LRU Cache base (100MB)

**Objetivo:** Implementar cache de tiles con límite máximo de 100MB para prototipo.

**Reglas Escras:**
- [ ] Cache debe usar algoritmo LRU (evicción items menos usados)
- [ ] Límite máximo: 100MB (ajustable a 500MB en futuro)
- [ ] Método `get(key: String) -> Texture` retorna null si no está en cache
- [ ] Método `set(key: String, texture: Texture)` añade/actualiza entrada
- [ ] Método `clear()` elimina todas las entradas
- [ ] Thread-safe: uso de `Mutex` para acceso concurrente
- [ ] Loggear cuando se evicte un item (debug mode)
- [ ] Não usar memoria > 100MB total (verificar bytes)

**Criterios de aceptación:**
1. Insertar 100 elementos, limpiar al evitar el 101° elemento
2. GET de key inexistente retorna null
3. Thread-safe bajo 1000 operaciones concurrentes
4. Tamaño máximo verificado con `Performance.get_monitor`

**Archivos a crear:**
- `godot-client/src/Data/TileCache.gd` (≤ 500 líneas)

**RF asociado:** RF-6, RNF-4 (cache local)

---

#### T1.2: Parser header .d2p básico

**Objetivo:** Implementar parser mínimo para leer headers de archivos .d2p.

**Reglas Escras:**
- [ ] Parsear header básico: magic bytes, versión, offsets
- [ ] Soportar formato Ankama D2P v3.6.x
- [ ] Método `parse_file(path: String) -> D2PData`
- [ ] Método `get_tileset_data() -> Dictionary` retorna tiles raw
- [ ] Manejar errores: archivo no existe, formato inválido
- [ ] Cachear resultados parsing en memoria (evitar re-parsing)
- [ ] NO cargar imágenes completas en esta fase (solo headers)

**Criterios de aceptación:**
1. Leer header de `d3maps/maps_0.bundle` sin error
2. Extraer offsets correctamente
3. Retornar Dictionary con `tile_count`, `offset_begin`, `format`
4. Manejar archivo corrupto sin crashear

**Archivos a crear:**
- `godot-client/src/Network/D2PParser.gd` (≤ 500 líneas)

**RF asociado:** RF-6, RNF-1 (GDScript puro)

---

#### T1.3: Tests unitarios TileCache

**Objetivo:** Verificar el funcionamiento correcto del cache.

**Reglas Escras:**
- [ ] Test de inserción y recuperación simple
- [ ] Test de eviction LRU al exceder límite
- [ ] Test de thread-safety (usar `Thread` con 100+ operaciones)
- [ ] Test de clear() y reinicio
- [ ] Mocks para evitar I/O real

**Criterios de aceptación:**
1. Todos los tests pasan sin warnings
2. Cobertura ≥ 80% del código
3. Tiempo de ejecución < 1 segundo

**Archivos a crear:**
- `godot-client/test/test_tile_cache.gd` (≤ 500 líneas)

**RF asociado:** -

---

### Fase 2: Sistema de mapa ⏱️ 3h

#### T2.1: MapManager con fallback ID

**Objetivo:** Gestionar estado del mapa y manejar fallback cuando jru es vacío.

**Reglas Escras:**
- [ ] Propiedad `current_map_id: int` (default: -1)
- [ ] Propiedad `is_fallback_active: bool`
- [ ] Método `set_map_id(id: int) -> bool` (retorna false si inválido)
- [ ] Método `get_fallback_map_id() -> int` (retorna 191105026)
- [ ] Método `is_valid_map_id(id: int) -> bool` (id > 0)
- [ ] Signal `map_changed(new_id: int)` emitido al cambiar
- [ ] Loggear cuando se activa fallback (no crítico)

**Criterios de aceptación:**
1. `set_map_id(191105026)` retorna true
2. `set_map_id(0)` activa fallback y retorna false
3. `set_map_id(-1)` activa fallback y retorna false
4. Signal emitido correctamente

**Archivos a crear/modificar:**
- `godot-client/src/Core/MapManager.gd` (≤ 500 líneas)

**RF asociado:** RF-1.1, RF-5, I3

---

#### T2.2: MapRenderer (Node2D + TileMap)

**Objetivo:** Renderizar mapa isométrico usando TileMap de Godot.

**Reglas Escras:**
- [ ] Root node: `Node2D` con hijo `TileMap`
- [ ] TileMap configurado con `mode = TILE_MODE_ISOMETRIC`
- [ ] CellSize: `Vector2i(32, 16)`
- [ ] Método `render_map(map_data: Dictionary)`
- [ ] Método `set_tile(x: int, y: int, tile_id: int)`
- [ ] Método `clear()` remueve todos los tiles
- [ ] Soporte para múltiples layers (terreno, objetos, decoración)

**Criterios de aceptación:**
1. TileMap renderiza grid isométrico visible
2. `set_tile(0, 0, 1)` pinta tile ID 1 en posición (0,0)
3. `clear()` limpia todos los tiles sin error
4. CellSize verificado con `tile_map.cell_size`

**Archivos a crear:**
- `godot-client/src/Systems/MapRenderer.gd` (≤ 500 líneas)

**RF asociado:** RF-1, I2

---

#### T2.3: CellID → Coordenadas isométricas

**Objetivo:** Convertir CellID del protocolo a coordenadas 2D isométricas.

**Reglas Escras:**
- [ ] Fórmula: `cell_x = cell_id % map_width`, `cell_y = cell_id / map_width`
- [ ] Método `cell_to_iso(cell_id: int) -> Vector2i`
- [ ] Coordenadas isométricas: `x_iso = (cell_x - cell_y) * tile_width/2`, `y_iso = (cell_x + cell_y) * tile_height/2`
- [ ] Manejar bordes del mapa (no salir de rango)
- [ ] Cache resultados conversión (optimización)

**Criterios de aceptación:**
1. `cell_to_iso(0)` → `(0, 0)` para mapa de ancho 1
2. `cell_to_iso(1)` → `(offset_x, offset_y)` según fórmula
3. Coordenadas isométricas visibles en pantalla
4. Consistente con protocolo Dofus

**Archivos a modificar:**
- `godot-client/src/Systems/MapRenderer.gd` (agregar método)

**RF asociado:** RF-4, I2

---

#### T2.4: Cachear tilesets cargados

**Objetivo:** Usar TileCache para almacenar tilesets y evitar recargar.

**Reglas Escras:**
- [ ] Integrar con `TileCache` existente
- [ ] Método `get_tileset(map_id: int) -> TileSet`
- [ ] Si no está en cache, parsear .d2p y añadir
- [ ] Usar clave: `"tileset_{map_id}"`
- [ ] Manejar caso: map_id inválido → lanzar error

**Criterios de aceptación:**
1. Primera llamada parsea .d2p (no use cache)
2. Segunda llamada usa cache (más rápido)
3. Map ID inválido lanza error limpio
4. Debug log muestra hits/misses de cache

**Archivos a modificar:**
- `godot-client/src/Systems/MapRenderer.gd` ( agregar cache)

**RF asociado:** RF-1, RF-6, RNF-4

---

### Fase 3: Sistema de cámara ⏱️ 2h

#### T3.1: CameraController base

**Objetivo:** Controlar cámara del mapa con soporte para seguimiento.

**Reglas Escras:**
- [ ] Node2D con `Camera2D` como hijo
- [ ] Propiedad `target: Node2D` (avatar jugador)
- [ ] Método `set_target(target: Node2D)` cambia focus
- [ ] Propiedad `zoom_level: float` (default: 1.0)
- [ ] Método `move_to(position: Vector2)` mueve cámara suavemente
- [ ] InputEnabled para debugging

**Criterios de aceptación:**
1. `set_target(avatar)` sigue al avatar
2. `move_to(Vector2(100, 100))` mueve cámara
3. Zoom funciona: `zoom_level = 1.5` acerca
4. Sin flickering ni posición incorrecta

**Archivos a crear:**
- `godot-client/src/Systems/CameraController.gd` (≤ 500 líneas)

**RF asociado:** RF-2

---

#### T3.2: Edge-scrolling implementado

**Objetivo:** Mover cámara cuando el ratón está en bordes de pantalla.

**Reglas Escras:**
- [ ] Activar cuando ratón está a ≤ 20px del borde
- [ ] Mover 5px vertical/horizontal cada 0.05s
- [ ] Dirección: hacia donde está el ratón
- [ ] Método `set_scroll_speed(px_per_interval: float, interval: float)`
- [ ] InputMap: `ui_scroll_*` no usar, usar posición ratón directamente
- [ ] Desactivar scroll si target está en esa dirección

**Criterios de aceptación:**
1. Ratón en borde derecha → cámara se mueve a la derecha
2. Velocidad verificada: ~5px/0.05s = 100px/s
3. Parar cuando ratón sale del borde
4. Smooth motion sin saltos

**Archivos a modificar:**
- `godot-client/src/Systems/CameraController.gd` (agregar lógica)

**RF asociado:** RF-2

---

### Fase 4: Integración y UI ⏱️ 2h

#### T4.1: WorldViewport contenedor

**Objetivo:** Contenedor principal que integra MapRenderer y CameraController.

**Reglas Escras:**
- [ ] Root: `Control` o `Node2D`
- [ ] Hijos: `MapRenderer`, `CameraController`, overlay UI opcional
- [ ] Método `show_map(map_id: int)` muestra mapa
- [ ] Manejar casos: map_id inválido → fallback automático
- [ ] Signal `player_spawned()` emitido cuando avatar listo

**Criterios de aceptación:**
1. `show_map(191105026)` muestra Astrub Zaap
2. Muestra fallback sin error
3. Signal emitido al spawn del jugador
4. UI escalable (añadir HUD, chat, inventory después)

**Archivos a crear:**
- `godot-client/src/UI/WorldViewport.gd` (≤ 500 líneas)

**RF asociado:** RF-1, RF-3

---

#### T4.2: Integrar con GameManager

**Objetivo:** Conectar el flujo de juego con el nuevo sistema de mapa.

**Reglas Escras:**
- [ ] Modificar `GameManager.gd` para crear `WorldViewport` después de `kvw`
- [ ] Manejar timer fallback 30s
- [ ] On `jru` recibido → `WorldViewport.show_map(map_id)`
- [ ] On timer expirado → `WorldViewport.show_map(191105026)`
- [ ] Limpiar vista al desconectar

**Criterios de aceptación:**
1. Flujo completo: kvi → jtg → kvw → jru/timeline → WorldViewport
2. Fallback funcional cuando jru vacío
3. Timer 30s expira → renderiza fallback
4. Sin duplicación de render (priorizar jru sobre timer)

**Archivos a modificar:**
- `godot-client/src/Core/GameManager.gd` (agregar integración)

**RF asociado:** RF-1, RF-1.1, RF-5

---

#### T4.3: Fallback visual gris

**Objetivo:** Mostrar fallback cuando assets no se pueden cargar.

**Reglas Escras:**
- [ ] Si parser .d2p falla, mostrar tiles grisáceos
- [ ] Tile ID 0 = color gris claro (#808080)
- [ ] Mensaje visible: "Error al cargar mapa"
- [ ] Botón "Reintentar" o "Usar mapa por defecto"

**Criterios de aceptación:**
1. Sin crasheos con assets corruptos
2. Tile gris visible en posición correcta
3. Mensaje de error legible
4. Botón reintentar funciona

**Archivos a modificar:**
- `godot-client/src/Systems/MapRenderer.gd`

**RF asociado:** -

---

#### T4.4: Documentar API pública

**Objetivo:** Documentar el API de los nuevos sistemas.

**Reglas Escras:**
- [ ] Comentarios GDScript style (docstring)
- [ ] Métodos públicos documentados con `@param`, `@return`
- [ ] Diagrama de flujo en README o docs
- [ ] Uso de consts para valores mágicos

**Criterios de aceptación:**
1. Todos los métodos públicos tienen documentación
2. Diagrama de flujo actualizado
3. Sin valores mágicos sin constante

**Archivos a crear/modificar:**
- Comentarios en todos los archivos

**RF asociado:** P-006

---

### Fase 5: Testing ⏱️ 1h

#### T5.1: Test TileCache LRU

**Objetivo:** Verificar el algoritmo de remoción LRU.

**Reglas Escras:**
- [ ] Insertar 100 items
- [ ] Acceder a items 1-50
- [ ] Insertar items 101-150 → verificar que items 51-100 se eliminan
- [ ] Verificar que items 1-50 siguen en cache

**Criterios de aceptación:**
1. Items con menor acceso eliminados primero
2. Items 1-50 accesibles sin reparsing
3. Test no depende de timing

**Archivos a crear/modificar:**
- `godot-client/test/test_tile_cache.gd`

**RF asociado:** -

---

#### T5.2: Test isometría

**Objetivo:** Verificar la conversión CellID → isometría.

**Reglas Escras:**
- [ ] CellID 0 → (0, 0)
- [ ] CellID 1 → offset según fórmula
- [ ] Verificar que coordenadas son isométricas visibles
- [ ] Test de borde del mapa

**Criterios de aceptación:**
1. Todas las coordenadas dentro de límites
2. No hay posiciones negativas inesperadas
3. Grid isométrico consistente

**Archivos a crear/modificar:**
- `godot-client/test/test_map_renderer.gd`

**RF asociado:** RF-4

---

#### T5.3: Test edge-scroll

**Objetivo:** Verificar el edge-scrolling funcional.

**Reglas Escras:**
- [ ] Simular ratón en borde derecha
- [ ] Verificar cámara se mueve a la derecha
- [ ] Simular ratón en borde izquierdo → cámara a izquierda
- [ ] Verificar velocidad ~100px/s

**Criterios de aceptación:**
1. Cámara parada cuando ratón fuera de borde
2. Movimiento suave sin saltos
3. Velocidad verificada con timing

**Archivos a crear/modificar:**
- `godot-client/test/test_camera.gd`

**RF asociado:** RF-2

---

## ✅ Progreso

| Estado | Tareas |
|--------|--------|
| Ready | 17 |
| In Progress | 0 |
| Completed | 0 |

---

## 📚 Referencias

- Spec 003: `specs/003-map-world-entry/spec.md`
- Plan: `specs/003-map-world-entry/plan.md`
- Protocolo: `godot-client/docs/PROTOCOL.md`