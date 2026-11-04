# 08 — Elementos interactivos

Los elementos interactivos son objetos clicables en un mapa: zaaps, puertas de casas, cofres, NPC, etc.

---

## 1. Declaración de interactivos

### 1.1 En el mapa (`jss`)

Los elementos se declaran dentro del mensaje `jss`, con dos campos:

```
jss: f5 { ... actor ... }, f11: { interactivos }, f15: { interactivos_estados }
```

**`f11` (declaración del interactivo):**
```
f11: { f1: 1,                        // flag "es interactivo"
       f4: { f1: uid, f2: skill },   // skill asociada
       f5: element,                  // ID visual del elemento
       f6: type                      // tipo de elemento
     }
```

**`f15` (estado del interactivo):**
```
f15: { f1: state,                    // estado (0=desactivado, 1=activado)
       f2: cell,                     // celda donde está
       f3: element                   // ID visual (mismo que f5 de f11)
     }
```

### 1.2 Tipos de elementos (`f6` en `f11`)

| `f6` | Tipo |
|------|------|
| 1 | Zaap |
| 2 | Portal de mazmorra |
| 3 | Puerta de casa |
| 4 | Cofre |
| 5 | Elemento de evento |
| 6-105 | Otros (NPCs, coleccionables, etc.) |
| 106 | Zaapi (teletransporte rápido) |
| 157 | Skill de zaapi |
| 359 | Anomalía temporal |

### 1.3 UID de skill

El UID de la skill es:

```
skill_uid = (element % 900000) + 10000
```

---

## 2. Zaaps

### 2.1 Estructura

- **1,851 entradas** (celdas) de tipo 1, 106, 359 en el servidor
- **74685** es el decor para zaaps desactivados (ancestral)
- **301199** es el decor para zaaps activados (común)

### 2.2 Interactuar con zaap (`iwo`)

```
iwo: f1 {                     // petición
    f1: skill_uid,           // skill del zaap
    f2: element,             // visual element (301199 o 74685)
    f3: dwelling_id          // opcional (solo para casas)
}
```

Respuesta del servidor:
```
iwn: f1 {                    // datos del zaap
    f1: map_id,              // mapa destino
    f2: cost,                // costo en kamas
    f3: entries,             // lista de entradas (ziaps)
    f4: anomaly_data         // solo para anomalías
}
```

### 2.3 Entradas de zaap (`iwn.f3`)

```
f3 (repetido) {
    f1: level_min,            // nivel mínimo (sin este campo = no tiene zaap)
    f2: cost,                 // costo en kamas
    f3: tab_type,             // 0=normal, 1=zaapi, 4=anomalía
    f5: map_id,               // mapa destino
    f6: subarea_id            // subárea destino
}
```

### 2.4 Costo del zaap

```
cost = clamp(10 * (|delta_x| + |delta_y|), 10, 1000)
```

Donde `delta_x, delta_y` es la distancia en celdas entre el mapa actual y el destino.

**Ejemplo:** De Astrub a la capital (distancia 50): 10 * 50 = 500 kamas.

### 2.5 Entrar al zaap (`hjj`)

```
hjj: f1 {                     // confirmar entrada
    f1: map_id               // mapa destino
}
```

### 2.6 Respuesta final

```
hjc: f3 {                     // entrada exitosa
    f3: map_id_destino
}
jsd, jru, lqu, hjk            // cargar nuevo mapa
ivf, kld                      // efectos de viaje
```

---

## 3. Zaapis (teletransporte rápido)

### 3.1 Características

- Tipo `f6 = 106`
- Skill ID `f4.f1 = 157`
- Precio fijo de **20 kamas**
- No tienen subáreas (son rápidos)

### 3.2 Interactuar

Mismo flujo que zaap normal (`iwo → iwn → hjj`), pero con type 106 y sin nivel requerido.

---

## 4. Anomalías temporales

### 4.1 Características

- Tipo `f6 = 359`
- Solo 2 en todo el mapa
- Usan el decor `74685` (ancestral)

### 4.2 Datos (`iwn.f4`)

```
f4: {
    f2: minutes_left,         // minutos restantes
    f3: 120                   // duración total en segundos
}
```

### 4.3 Entrar a la anomalía

```
hqa: f2 {                     // solicitar
    f2: 4                     // tipo 4 = anomalía
}
```

Respuesta:
```
hjc: f3: subarea_id
```

---

## 5. Casas

### 5.1 Entrar a una casa

```
iwo: f1 {
    f1: skill_id,             // skill de entrada
    f2: element_id,           // ID visual
    f3: dwelling_id           // número de la vivienda
}
iwn
jqw: f1 { f1: interior_map }  // mapa interior
```

### 5.2 Salir de una casa

```
iwo: f1 {
    f1: skill_id,
    f2: element_id
    // sin f3 (salir no necesita dwelling)
}
iwn
jru: f2 { f2: street_map }    // mapa exterior
lqu, hjk
```

**Nota:** La salida va en campo `f2` de `jru`, no en `f1`.

---

## 6. Merkasako (haven bag)

### 6.1 Estructura

El haven bag es un sistema especial de almacenamiento personal.

### 6.2 Opcodes relacionados

```
jbn: f2 { whose }              // ver inventario de alguien
jbl: f1 { theme }              // cambiar tema
jbv                            // verificar posesión
jbg                            // guardar cambio
jbu                            // confirmar guardado
jaz                            // cancelar
```

### 6.3 Detalles

- Cada jugador puede tener un haven bag (casa propia)
- Los temas son estéticos (decoración del espacio)
- El contenido es persistente por cuenta

---

## 7. Cofres

### 7.1 Interactuar con cofre (`iwo`)

```
iwo: f1: skill, f2: element, f3: dwelling  // dwelling es el cofre
iwn
kci: f1 { f1: 100, f3: 4 }           // abrir (100=tipo, 4=acción)
```

### 7.2 Resultado

```
kcr                          // confirmación de abrir
iua + itc + iun              // items dados
itd + ium + iun              // si falla
```

---

## 8. Lotería

### 8.1 Iniciar lotería

```
jbs: f2 { f2: uid }          // uid del sorteo
```

### 8.2 Rehusar oferta

```
jbs: f2 { f3: 1 }            // rechazo
```

---

## 9. NPCs

### 9.1 Spawn de NPCs

Solo hay **2 spawns de NPC** en el mapa de pruebas (Astrub). La mayoría de NPCs se crean dinámicamente.

### 9.2 Interactuar con NPC

```
iwo: f1: skill, f2: element
iwn: f1: contextual_id      // ID del NPC
```

---

## 10. Elementos especiales

### 10.1 Teletransportes de emergencia

Algunos mapas tienen teletransportes de seguridad (ej: salir de mazmorras). Estos son similares a zaaps pero con type diferente.

### 10.2 Eventos de zona

Zonas con eventos activos tienen elementos interactivos temporales (`type = 5`).

---

## 11. Verificación

### 11.1 Cómo verificar un interactivo

Usa el mapa de posiciones y verifica:

```bash
py tools/pcap.py <archivo> --mapa 191105026
```

### 11.2 IDs de elementos notables

| Mapa | Elemento | Uso |
|------|----------|-----|
| 191105026 | 157 | Zaap Astrub |
| 154010882 | 20440 | Cofre de recompensas |
| - | - | NPC (no hay muchos spawns) |

Para la lista completa de elementos, ver `datos/map_interactives.json`.