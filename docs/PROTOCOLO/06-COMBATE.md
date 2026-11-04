# 06 — Combate

**⚠️ IMPORTANTE: El combate NO está implementado actualmente.** El servidor usa protocolo 3.6.4.3 pero el cliente Godot está en 3.6.10.10. Los opcodes requeridos para iniciar y manejar peleas no están conectados.

---

## 1. Estado actual

| Componente | Estado |
|------------|--------|
| Preparación de pelea | ✅ Medido (but no wired) |
| Inicio de pelea | ❌ No implementado |
| Turnos | ❌ No implementado |
| Hechizos | ❌ No implementado |
| Botín | ❌ No implementado |

---

## 2. Por qué no se puede empezar una pelea

### 2.1 Los opcodes de pelea usan 3.6.4.3

Ver `docs/fight.md` y `docs/protocol.md`. Los opcodes que inician combate (`hqa`, `jxg`, etc.) están implementados en el servidor pero no expuestos al cliente Godot.

### 2.2 El handshake de pelea

En el servidor, para empezar una pelea:

```
1. Cliente: jwe { f1: cell, f2: element, f3: contextual_id }  // solicitar pelea
2. Servidor: jwe { ... }  // confirmación (si puede)
3. Cliente: jxa { f1: actor, f2: spell_bar }  // confirmar participación
4. Servidor: hoy { ... }  // datos de oponente
5. Servidor: jwe { ... }  // colocar oponentes
6. ...
```

**Ninguno de estos está implementado en el cliente Godot.**

---

## 3. Preparación de pelea (lo que sí está medido)

### 3.1 Solicitar pelea (`jwe`)

```
jwe: f1 {                // solicitar pelea
    f1: 123,              // celda del NPC/monstruo
    f2: 1,                // elemento (1=normal, 2=anomalous, etc.)
    f3: 456789           // ID contextual
}
```

Respuesta del servidor:
- `jwe` con éxito → pelea iniciada
- `jwe` con error → no se puede pelear
- Nada → NPC solo saluda

### 3.2 Confirmar participación (`jxa`)

```
jxa: f1 {                // confirmar
    f1: actor,           // ID del jugador
    f2: spell_bar        // hechizos disponibles
}
```

---

## 4. Datos del oponente (`hoy`)

Una pelea iniciada:

```
hoy: f1 {                // oponente
    f1: actor_id,
    f2: "Nombre",
    f3: look,
    f4: { f2: level, f6: look, f7: breed },
    f5: { ... }          // efectos
}
```

---

## 5. Datos de pelea (`jwe` - fight entity)

### 5.1 Colocación de fighter

```
jwe: f1 {                // fighter
    f1: actor_id,
    f2: team,            // 0=propio, 1=oponente
    f3: cell,            // celda de posición
    f4: stats           // vida, PA, PM, etc.
}
```

### 5.2 Colocación de equipo (`jxg`)

```
jxg: f1 {                // datos del jugador
    f1: actor_id,
    f2: equipo,          // slots 0-15 ocupados
    f3: estadísticas
}
```

---

## 6. Barra de hechizos (`kba`)

```
kba: f1 {                // spell bar
    f1: [spell_id_1, spell_id_2, ...]  // lista de hechizos
}
```

El cliente envía su barra al servidor al unirse a la pelea.

---

## 7. Estado de turno (`jzu`)

```
jzu: f1 {                // estado del turno
    f1: actor_id,        
    f2: turn_phase,      // 1=iniciar, 2=lanzar hechizo, 3=fin
    f3: pa_remaining,    // puntos de acción restantes
    f4: pm_remaining     // puntos de movimiento restantes
}
```

---

## 8. Lanzar hechizo (`jwq`, `jrk`, `jyg`, `jyx`)

### 8.1 Pedir lanzar hechizo

```
jwq: f1 {                // pedir
    f1: spell_id,
    f2: [cell1, cell2, ...]  // celdas objetivo
}
```

### 8.2 Confirmar lanzamiento

```
jrk: f1 { f1: spell_id, f2: cell, f3: cell, ... }
```

### 8.3 Efectos

```
jyg: f1 {                // efecto
    f1: effect_type,
    f2: value,
    f3: cell,
    f4: actor
}
```

### 8.4 Resultado

```
jyx: f1 {                // resultado
    f1: spell_id,
    f2: pa_gastados,
    f3: PM_gastados,
    f4: efectos_applied
}
```

---

## 9. Fin de pelea

### 9.1 Fin de turno

```
jya: {}  // fin de turno
```

### 9.2 Fin de combate

```
jyj: f1 {                // fin
    f1: winner_team,
    f2: experience,
    f3: kamas_ganadas
}
```

---

## 10. Botín de pelea

### 10.1 Datos de loot

```
jxc: f1 { f1: item_id, f2: qty, f3: uid }
```

### 10.2 Entrega de items

Al final de la pelea, el servidor manda:

```
iua: f1 { f1: item_template, f2: quantity }
itn: f1: item_uid
```

---

## 11. Checklist de implementación

### Qué falta implementar:

- [ ] `jwe` (solicitar/validar pelea)
- [ ] `jxa` (confirmar participación)
- [ ] `jxg` (datos del jugador)
- [ ] `hoy` (datos del oponente)
- [ ] `kba` (barra de hechizos)
- [ ] `jzu` (estado de turno)
- [ ] `jwq` (pedir lanzar)
- [ ] `jrk` (lanzar hechizo)
- [ ] `jyg` (efectos)
- [ ] `jyx` (resultado)
- [ ] `jya` (fin de turno)
- [ ] `jyc` (fin de pelea)
- [ ] `jxc`/`iua`/`itn` (drops)

### Puntos críticos no implementados:

1. **No hay sistema de turnos** - No hay contador de PA/PM visible
2. **No hay celdas de combate** - Los `jba` (fight cells) no se renderizan
3. **No hay barra de hechizos** - Los `hms` se ignoran durante la pelea
4. **No hay botín** - Los `RollLoot` del servidor no se procesan

---

## 12. Referencias

- Ver `docs/fight.md` para detalles de captura de peleas reales
- Ver `docs/opcodes.md` tabla 7 para opcodes de pelea
- Ver `Handlers/FightHandler.cs` en el servidor para lógica de botín