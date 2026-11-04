# 05 — Monstruos y drops

El mundo de DreamFus tiene 15,360 mapas posibles, con 38,744 grupos de monstruos distintos. La mayoría de los mapas están vacíos; se genera contenido mediante procedimiento controlado.

---

## 1. Datos de monstruos

### 1.1 Mapeo de monstruos

Los monstruos aparecen en grupos dentro de `jss` (celda f3, tipo f7=4):

```
jss: f5 {                  // actor monstruo (f7 = 4)
    f4: {                   // grupo de monstruos
        f1: 1,              // flag siempre 1
        f2: 134,            // ID contextual del líder
        f3: 0,              // "bones" (interno, no usar)
        f4: {               // líder del grupo
            f1: 12345,      // ID del template del monstruo (ej: 12345 = "Drak")
            f2: 150,        // nivel
            f3: look,       // hex del look
            f4: 3,          // grado (1-5, ver abajo)
            f7: 1           // raza (interno)
        },
        f5: -1,             // siempre -1
        f6: ...,            // look del grupo
        f7: 3,              // grado más alto del grupo
    }
}
```

### 1.2 Los 5 grados

Cada monstruo tiene 5 grados posibles (1-5). Los grados determinan:
- Vida base
- Daño base
- Probabilidad de drop
- Recompensas

**Clamping de grado:** El servidor limita el grado a 1-5. Un monstruo nivel 200 puede ser grado 1 (fácil) o grado 5 (difícil).

### 1.3 Archimonstruo (boss)

Algunos monstruos son "archimonstruos":

```
f4: {
    f1: 1,
    f2: 134,
    f4: {
        f1: 12345,
        f4: 5,           // grado 5 = archimonstruo
        ...
    }
}
```

Los archimonstruos tienen drops mejores y apariciones más raras.

---

## 2. Tabla de XP para monstruos

La XP otorgada depende del nivel del monstruo. Tabla referencial:

| Nivel | XP base |
|-------|---------|
| 1 | 30 |
| 10 | 510 |
| 50 | 11,550 |
| 100 | 22,100 |
| 200 | 43,350 |

Los divisores de XP y la tabla exacta están en `ExperienceTable.cs`.

---

## 3. Generación de mazmorras vacías

Hay 2,453 mapas sin monstruos que se generan aleatoriamente. El algoritmo:

1. **Sub-area vacío:** Si el sub-area no tiene spawn, se elige aleatoriamente
2. **Thinning de archimonstruos:** Los archimonstruos tienen 25% de probabilidad de no aparecer
3. **Distribución por grado:** Los monstruos normales se distribuyen por grado según la tabla de spawn

---

## 4. Drops de monstruos

### 4.1 La fórmula general

Cuando un monstruo muere, el servidor calcula el botín en `FightHandler.RollLoot()`:

```csharp
// Paso 1: Jondo Coin (siempre)
int coins = 1 + (clamp(monster_level, 1, 225) - 1) / 25;  // mínimo 1, máximo 9

// Paso 2: Drop por grado de monstruo
foreach (item in monster.templates.drops_by_grade[grade]) {
    if (random() < item.chance) loot.Add(item);
}

// Paso 3: Drops globales (raids)
if (is_dungeon && random() < global_drop.chance) {
    loot.Add(global_drop);
}
```

### 4.2 Drop de Jondo Coin

**Siempre cae.** El ítem es `JondoCoin` con ID 20440.

```
iua: f1 {                   // entrega de recompensas
    f1: 20440,              // ID del Jondo Coin
    f2: qty                 // cantidad ganada
}
```

**Cantidad:** `1 + floor((level - 1) / 25)`, con techo de 9 monedas.

| Nivel | Monedas |
|-------|---------|
| 1-25 | 1 |
| 26-50 | 2 |
| 51-75 | 3 |
| 76-100 | 4 |
| 101-125 | 5 |
| 126-150 | 6 |
| 151-175 | 7 |
| 176-200 | 8 |
| 201-225 | 9 |
| 226+ | 9 (capped) |

### 4.3 Probabilidades de rareza

Los items se generan con estas probabilidades (del `RandomLoot` del servidor):

| Rareza | Probabilidad |
|--------|-------------|
| Perfecto | 0.05% |
| Épico | 0.5% |
| Legendario | 5% |
| Dofus | 10% |
| Creatura | 15% |
| Equipamiento | 25% |
| Consumible | 44.45% |

**Nota:** Estos son los rates del loot aleatorio (`RandomLoot.Roll`). Los drops específicos del monstruo tienen sus propias probabilidades.

### 4.4 Drop por grado

Cada monstruo tiene una tabla de drops por grado en `MonsterTemplates.drops`:

```
monster {
    id: 12345,
    drops: [
        {grade: 1, items: [{id: 1001, chance: 0.05}]},
        {grade: 2, items: [{id: 1001, chance: 0.10}]},
        ...
    ]
}
```

---

## 5. Entrega de drops

### 5.1 Al final de la pelea

Cuando la pelea termina, el servidor envía:

```
iua: f1 { f1: template_id, f2: qty }  // items
iua: f1 { f1: 20440, f2: qty }        // Jondo Coin
ivj: f1 { f1: uid, f2: qty }          // cambios de stack existente
itn: f1 { f1: uid }                    // notificación de item nuevo
```

### 5.2 Al mover items al inventario

```
ivx: (el inventario completo, con el nuevo item)
```

---

## 6. Mecánica de recolección (`iwo` → `iwf`/`iwm`/`iwn` → `iwi`)

Los recursos recolectables tienen su propio ciclo:

1. **Preparar herramienta:** El jugador tiene una herramienta de recolección
2. **Enviar petición:**
   ```
   iwo: f1 { f1: skill, f2: element, f3: dwelling }  // solicitud
   ```
3. **Servidor valida y responde:**
   - `iwf {}` (fracaso)
   - `iwm {}` (movimiento)
   - `iwn {}` (éxito)
4. **Recibir el item:**
   ```
   iwi: f1 { f1: template, f2: qty, f3: uid }  // + inventory push later
   ivj/itn: entrega del item
   ```

---

## 7. Moneda Jondo (Jondo Coin)

### 7.1 ¿Qué es?

Es una moneda de recompensa **no comerzable** que se obtiene:
- Por matar monstruos (por nivel)
- Por completar mazmorras
- Por logros

### 7.2 Propósito

- Compra en tiendas de aparatos
- Recompensas de logro
- Eventos de temporada

### 7.3 Sinónimos

- "Moneypiece" (terminología del servidor)
- "JondoCoin" (clase del servidor)
- "Jondo coin" (cliente)

---

## 8. Tabla de referencia de IDs notables

| ID | Nombre | Uso |
|----|--------|-----|
| 20440 | Jondo Coin | Drop universal |
| 1 | Golpe (hechizo) | Tutorial nivel 1 |
| 2 | Agujeta | Tutorial nivel 1 |
| 3 | Empuje | Tutorial nivel 1 |
| 12345678 | Astrub Zaap | Mapa inicial |

Para IDs completos de monstruos, items y hechizos, ver `datos/dofus3_mappings.json` (aunque solo 16 de 93 opcodes existentes están mapeados en 3.6.10.10).

---

## 9. Loot table específica de monstruos

Cada monstruo tiene drops definidos en la base de datos. Ejemplo de cómo se consulta:

```csharp
var drops = DatabaseManager.MonsterTemplates[monsterId].drops_by_grade[grade];
foreach (var drop in drops) {
    if (random.NextDouble() < drop.chance) {
        loot.Add(drop.item_id, drop.amount);
    }
}
```

Los drops pueden ser:
- **Consumibles:** pociones, cristales
- **Equipamiento:** armas, armaduras
- **Accesorios:** anillos, amuletos, dofus
- **Cosméticos:** trajes, colores
- **Especiales:** runas, fragmentos

---

## 10. Drops de mazmorras

Los grupos de mazmorras (`DungeonManager`) tienen drops especiales:

1. **Drop por grupo:** Cada grupo de monstruos tiene drop específico
2. **Drop global:** Algunas mazmorras tienen drops globales (Almanax)
3. **Recompensa de boss:** Al final de la mazmorra hay un boss con drop raro
4. **Bonus diarios:** Completar mazmorras da bonus extra de Jondo coin