# 04 — Mundo, mapas y movimiento

El mundo de juego es un conjunto de mapas (posiciones X/Y) conectados por bordes. El servidor envía información de mapa, actores y permite mover al personaje.

---

## 1. Entrada al mundo

### 1.1 Flujo de bienvenida

Después de presentar el ticket (`kqz`), el servidor envía una ráfaga de mensajes:

```
kqc                     →  confirmación de bloqueo 1
krv                     →  confirmación de bloqueo 2  
kvi                     →  lista de personajes (si no se ha visto)
kvd                     →  fin de lista
kvw                     →  datos del personaje seleccionado
lqc                     →  catálogos 1 (equipamiento, hechizos, etc.)
jru                     →  MAPA INICIAL (191105026 - Astrub zaap)
```

**Regla:** Si el cliente manda `jru` antes de recibir el primero, el servidor lo tira. Ver `jsj` (mapa completo) y `lva` (actores) debajo.

### 1.2 Bloque 1: Mapa, hoja, misiones

```
kvw {f1: id_personaje}    →  datos del personaje
lqc                     →  catálogos (loot tables, efectos, skills)
```

### 1.3 Bloque 2: Catálogos

`lqc` es la confirmación. Los datos reales vienen en varios mensajes push (equipamiento, hechizos, monturas, etc.).

### 1.4 Bloque 3: Mensaje del mapa

```
kqo {}                  →  heartbeat (se responde kqy {f1: 1} cada 5s)
kmr {}                  →  (desconocido, posiblemente "map ready")
jru {f2: 154010882}   →  CARGA EL MAPA indicado
```

---

## 2. Cargar un mapa (`jru`, `jrw`, `jqi`, `jsd`)

### 2.1 Recibir el mapa (`jru`)

```
jru: f2 {                  // mapa a cargar
    f2: 191105026         // ID del mapa (Astrub zaap)
}
```

Cuando el cliente recibe esto, debe:
1. Cargar los datos del mapa desde `map_cells.json` y `map_walkable.json`
2. Mostrar el mapa
3. Recibir `hjk` con los actores del mapa

### 2.2 Enviar movimiento (`jrw`)

Cuando el personaje camina a una celda:

```
jrw: f1 {                    // petición de movimiento
    f1: 191105026,           // ID del mapa actual
    f2: (facing << 12) | cell // celda destino (packed)
}
```

**Cálculo de `f2`:**
- `cell` = número de celda (0-289 para mapa 15x17)
- `facing` = dirección del personaje (0=norte, 1=Este, 2=sur, 3=Este)
- Fórmula: `(facing << 12) + cell`

**Ejemplo:** celda 100, mirando sur (2): `(2 << 12) + 100 = 8192 + 100 = 8292`

### 2.3 Al llegar a borde (`jqi`)

```
jqi: vacío                 // el personaje llega a un borde
```

Respuesta del cliente:

```
jqk: f2 {                  // indique el mapa destino
    f2: 191105027          // ID del mapa vecino
}
```

O bien con el mapa completo:

```
jsd: f2 {                  // detalles del mapa vecino
    f2: 191105027         // ID
}
```

Luego el servidor envía:
```
jru {f2: 191105027}   →  CARGA NUEVO MAPA
lqu                   →  (desconocido)
hjk                   →  ACTORES DEL NUEVO MAPA
lva                   →  fin de actores
```

---

## 3. Actores en el mapa (`hjk`, `jss`, `lva`)

### 3.1 Formato `hjk` (celdas ocupadas)

```
hjk: f1 {                  // mapa ocupado
    f1: datos_packed      // array de bytes con celdas que tienen contenido
}
```

### 3.2 Formato `jss` (actores del mapa)

```
jss: f2 {                  // lista de actores
    f6: subarea_id,        // subárea (para zonas grandes)
    f5 (repetido) {        // actor individual
        f1: cell,            // celda ocupada
        f2: facing,          // dirección
        f3: contextual_id,   // ID contextual (jugador/NPC/monstruo)
        f4: {                // grupo de monstruos (solo si tipo=monstruo)
            f1: 1,           // siempre 1 (flag de grupo)
            f2: nivel,       // nivel del grupo
            f3: bones,       // valor interno
            f4: {            // líder
                f1: id,      // ID del monstruo
                f2: nivel,
                f4: grado
            },
            f5: -1,          // siempre -1
            f6: look,
            f7: grado_lider
        }
        f7: tipo_actor,    // 4 = monstruo, 7 = NPC, 1 = jugador
        f11: interactivo,   // elementos interactivos en la celda
        f12: pelea,         // celda de lucha
    }
    f11: interactivos,     // IDs de elementos que colisionan
    f12: peleas,           // IDs de celdas de lucha
}
```

### 3.3 Tipos de actores (`f7`)

| `f7` | Tipo |
|------|------|
| 1 | Jugador |
| 4 | Monstruo (grupo) |
| 7 | NPC |

### 3.4 Celda de llegada (`jrh`)

Cuando el jugador llega a un mapa, el servidor envía:

```
jrh: vacío                 // notificación de llegada
```

El cliente debe hacer scroll al jugador y refrescar UI.

### 3.5 Fin de lista (`lva`)

```
lva: vacío                 // fin de la lista de actores
```

Importante: `lva` es el que confirma que se recibió toda la lista `jss`. Sin `lva`, el cliente no debe procesar los actores.

---

## 4. Bordes del mapa

Los bordes se detectan por fila/columna en el mapa de celdas (15x17 = 255 celdas, numeradas 0-254):

| Dirección | Condición | Cell delta | Facing esperado |
|-----------|-----------|------------|-----------------|
| Izquierda | Cell % 15 == 0 | +13 (o -13 según coordenadas) | 3 (Oeste) |
| Derecha | (Cell + 1) % 15 == 0 | -13 | 1 (Este) |
| Arriba | Cell < 15 | +532 | 6 (Norte) |
| Abajo | Cell >= 240 | -532 | 2 (Sur) |

**Cell delta a coordenadas:**
- Cell 0 = (0, 0)
- Cell 15 = (1, 0)
- Cell 1 = (0, 1)
- Cell 255 = fuera de rango

**Delta de llegada (medido):**
- Derecha: -13 / facing 0
- Izquierda: +13 / facing 4
- Arriba: +532 / facing 6
- Abajo: -532 / facing 2

---

## 5. Coordenadas reales

El mapa tiene celdas numeradas de 0 a 254. Para convertir a coordenadas (x, y):

```gdscript
func cell_to_coords(cell: int) -> Vector2:
    return Vector2(cell % 15, cell / 15)

func coords_to_cell(x: int, y: int) -> int:
    return y * 15 + x
```

**Límites del mapa (celdas ocupables):**
- x: 0-14
- y: 0-16
- Total: 255 celdas (0-254)

---

## 6. Neighbor resolution (mapas vecinos)

Los mapas vecinos se resuelven por el servidor en `WorldMoveHandler.cs`. La lógica:

1. **Guess del cliente:** El cliente adivina el mapa vecino basándose en la dirección del movimiento
2. **MapScrolls:** Si el guess falla, el servidor manda `hjk` con el mapa real y el cliente debe corregir
3. **Coordenadas:** El servidor calcula el mapa vecino usando la tabla `MapPositions`

---

## 7. Autómata de movimiento

El cliente no implementa autopilot. El movimiento es:

1. Input del jugador (WASD o click)
2. Verificar celda válida (walkable + dentro de límites)
3. Enviar `jrw`
4. Recibir `hjk` con el mapa actualizado
5. Recibir `lva` (opcionalmente `jrh`)

---

## 8. Estados del mapa

Un mapa puede estar en estados diferentes:

| Estado | Símbolo | Comentario |
|--------|---------|------------|
| Zona segura | `safe` | No hay enemigos, se puede aflojar |
| Zona peligrosa | `danger` | Monstruos presentes |
| Zona de combate | `fight` | En medio de una pelea |
| Zona de interacción | `interactive` | Hay elementos clicables |

Los estados se determinan por la presencia de monstruos (`f4`) y elementos interactivos (`f11`, `f15`).

---

## 9. Ejemplos de comandos de movimiento

### 9.1 Moverse al este (cell 100 -> 101)

```gdscript
# Cell 101 = (101 % 15, 101 / 15) = (6, 6)
# Facing = 0 (norte) o 1 (este) según dirección
var packed = (0 << 12) + 101
send_opcode("jrw", [
    {"f1": map_id},
    {"f2": packed}
])
```

### 9.2 Moverse al norte (cell 100 -> 532 + 100 = 632)

```gdscript
var packed = (6 << 12) + (100 - 15)  # norte quita 1 de fila
# O más directo:
var new_cell = 100 - 15  # arriba
var packed = (6 << 12) + new_cell
```

### 9.3 Cambiar de mapa (de Astrub a vecino)

```gdscript
# Recibir jru {f2: 191105026} cuando el jugador está en 191105027
# En realidad, el servidor envía jru cuando el jugador CAMINA a un borde
```