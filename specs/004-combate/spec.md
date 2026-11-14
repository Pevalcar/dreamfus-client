# 004 — DreamFus Client MVP: combate

## 1. Contexto y objetivo

El combate es un sistema por turnos con:
- Iniciativa basada en DIST.
- Puntos de Acción (PA) y Puntos de Movimiento (PM).
- Hechizos con efectos (daño, curación, buffs).
- Interfaz de combate 5x4 celdas.

**Escala:** 001 — Login y selección, 002 — Mapa y movimiento, 003 — Transición entre mapas.

## 2. Inicio de combate

### 2.1 Solicitar pelea

El jugador hace clic en un monstruo/NPC con flag de pelea activo:

```
jwe: f1 {                // solicitar pelea
    f1: 123,              // celda del NPC/monstruo
    f2: 1,                // elemento (1=normal, 2=anomalous)
    f3: 456789           // ID contextual
}
```

Respuesta del servidor:
- `jwe` con éxito → combate iniciado.
- `jwe` con error → no se puede pelear.
- Nada → NPC solo saluda.

### 2.2 Confirmar participación

```
jxa: f1 {                // confirmar
    f1: actor,           // ID del jugador
    f2: spell_bar        // hechizos disponibles (IDs)
}
```

### 2.3 Datos del oponente

```
hoy: f1 {                // oponente
    f1: actor_id,
    f2: "Nombre",
    f3: look,
    f4: { f2: level, f6: look, f7: breed },
    f5: { ... }          // efectos
}
```

## 3. Estado de combate

### 3.1 Colocación de fighters

```
jwe: f1 {                // fighter
    f1: actor_id,
    f2: team,            // 0=propio, 1=oponente
    f3: cell,            // celda de posición en grid 5x4
    f4: stats           // vida, PA, PM, grado, etc.
}
```

Grid de combate: 5 celdas de ancho x 4 de alto (celdas 0-19).

### 3.2 Estado de turno

```
jzu: f1 {                // estado del turno
    f1: actor_id,
    f2: turn_phase,      // 1=iniciar, 2=lanzar, 3=fin
    f3: pa_remaining,    // PA restantes
    f4: pm_remaining     // PM restantes
}
```

## 4. Lanzamiento de hechizos

### 4.1 Pedir lanzar

```
jwq: f1 {                // pedir
    f1: spell_id,
    f2: [cell1, cell2, ...]  // celdas objetivo
}
```

### 4.2 Confirmar lanzamiento

```
jrk: f1 { f1: spell_id, f2: cell, f3: cell, ... }
```

### 4.3 Efectos

```
jyg: f1 {                // efecto
    f1: effect_type,
    f2: value,
    f3: cell,
    f4: actor
}
```

### 4.4 Resultado

```
jyx: f1 {                // resultado
    f1: spell_id,
    f2: pa_gastados,
    f3: pm_gastados,
    f4: efectos_aplicados
}
```

## 5. Fin de turno y combate

### 5.1 Fin de turno

```
jya: {}  // fin de turno
```

### 5.2 Fin de combate

```
jyj: f1 {                // fin
    f1: winner_team,
    f2: experience,
    f3: kamas_ganadas
}
```

### 5.3 Botín

```
jxc: f1 { f1: item_id, f2: qty, f3: uid }
iua: f1 { f1: item_template, f2: quantity }
itn: f1: item_uid
```

## 6. Requisitos funcionales

**RF-19 — Solicitar pelea.** El cliente deberá poder iniciar un combate con un NPC/monstruo.
- *Evento:* Cuando el jugador haga clic en un objetivo con pelea disponible, el cliente deberá enviar `jwe`.
- *Condicional:* Si el servidor rechaza, el cliente deberá mostrar el motivo y continuar en el mapa.

**RF-20 — Confirmar turno.** El cliente deberá manejar el estado de turno.
- *Ubicuo:* El cliente deberá mostrar PA/PM restantes y actualizarlos tras cada acción.

**RF-21 — Lanzamiento de hechizos.** El cliente deberá ejecutar hechizos con confirmación del servidor.
- *Evento:* Cuando el jugador seleccione un hechizo, el cliente deberá enviar `jwq` con celdas objetivo.
- *Evento:* Cuando el servidor confirme (`jyx`), el cliente deberá aplicar efectos visuales.

**RF-22 — Interfaz de combate.** El cliente deberá renderizar el grid de combate 5x4.
- *Evento:* Cuando el servidor envíe `jwe` (colocación), el cliente deberá mostrar el grid con fighters en sus celdas.
- *Ubicuo:* Las celdas de combate se distinguen con color (propio/oponente).

**RF-23 — Estado de combate.** El cliente deberá mostrar vida, PA, PM de todos los fighters.
- *Ubicuo:* El HUD de combate mostrará barras de vida y valores numéricos.

**RF-24 — Fin de combate.** El cliente deberá manejar el final del combate y mostrar recompensas.
- *Evento:* Cuando el servidor envíe `jyj`, el cliente deberá mostrar quién ganó, experiencia y kamas obtenidas.
- *Evento:* Al cerrar, el cliente deberá volver al mapa anterior.

## 7. Requisitos no funcionales

- **RNF-11 — Turnos visibles.** El jugador debe poder ver quién tiene el turno.
- **RNF-12 — Reacción fluida.** Lanzar un hechzu debe tener feedback visual < 500ms.
- **RNF-13 — Sin desincronización.** El cliente nunca asume el resultado de un hechizo; espera confirmación.

## 8. Casos límite

- Click en celda no válida: sin acción, oscurecer celda.
- Hechizo sin PA/PM: mensaje "No hay puntos".
- Servidor rechaza lanzamiento: revertir animación, mensaje.
- Conexión perdida durante combate: volver al mapa.
- Timeout de confirmación (>3s): reintentar una vez, luego abortar.

## 9. Fuera de alcance

- Gráficos especiales de hechizos (efectos básicos por ahora).
- Sistema de botín persistente.
- Efectos de grado (grados de monstruos).
- Misiones/compras durante combate.

## 10. Criterios de finalización

1. Al hacer clic en monstruo con zona de pelea, se inicia combate.
2. El grid 5x4 se muestra con fighters y sus estadísticas.
3. Lanzar un hechizo actualiza PA y aplica efectos recibidos.
4. Al ganar/perder, se muestra recompensa y vuelve al mapa.

## 11. Dudas abiertas

1. **[NECESITA ACLARACIÓN]** ¿Se muestra la vida actual del jugador en el HUD de combate, o es un marcador estático?