# Reporte de Clarificación — SDD-CI-003: Visualización de mapa y entorno del jugador

**Fecha de auditoría:** 23 Nov 2026  
**Especialista:** QA Requisitos (Agente Subordinado)  
**Especificación:** `specs/003-map-world-entry/spec.md`  
**Constitución:** `docs/constitution.md`

---

## 🎯 Resumen Ejecutivo

| Métrica                          | Conteo | Umbral para PASS | Estado  |
| -------------------------------- | ------ | ---------------- | ------- |
| Conflictos con `constitution.md` | 1      | `0`              | ❌      |
| Hallazgos 🔴 Crítico             | 3      | `0`              | ❌      |
| Hallazgos 🟡 Alto                | 3      | `≤ 2`            | ❌      |
| Hallazgos 🟢 Medio               | 1      | Informativo      | ℹ️      |

> **Veredicto FAIL** — La especificación tiene ambigüedades críticas y conflictos constitucionales que deben resolverse antes de `/sdd-plan`.

---

## 🔴 Hallazgos Críticos (Bloqueantes)

### Q-01 [Ambigüedad / Test Oracle] — `RF-4`
**Ubicación:** p.56  
**Problema:** El RF-4 menciona que `kva` incluye posición, pero según los logs, `kva` solo se recibe después de `ivx` y NO contiene coordenadas. La posición real del avatar viene probablemente de un mensaje posterior o se deriva del map ID. **Este RF es incorrecto o no testeable.**

### Q-02 [Caso Límite / Timeout] — `RF-5`
**Ubicación:** p.57  
**Problema:** El RF menciona un fallback de map ID, pero NO especifica qué ocurre con el avatar si el map ID es inválido. ¿Dónde spawnea? ¿Se muestra error visual al jugador?

### Q-03 [Conflicto Constitucional P-005]
**Ubicación:** RNF-4, p.66  
**Problema:** La RNF-4 indica que los assets se cargan desde cache local (`user://cache/tiles/`) y nunca deben almacenarse credenciales. Sin embargo, los assets de Alea pueden contener metadata sensible o referencias que no deben cachearse.

---

## 🟡 Hallazgos Altos (Riesgos)

### Q-04 [Caso Límite no cubierto] — `RF-1`
**Ubicación:** p.53  
**Problema:** Cuando el jugador está en movimiento y se recibe un nuevo map ID por el servidor, ¿qué ocurre con el avatar? ¿Se despega del mapa viejo o se transiciona suavemente?

### Q-05 [Ambigüedad EARS] — `RF-3`
**Ubicación:** p.55  
**Problema:** "EL SISTEMA rechaza el movimiento" - pero ¿qué feedback visual/sonoro se da al jugador? El RFC es vago.

### Q-06 [Transición de Estado faltante]
**Ubicación:** p.40-48  
**Problema:** La matriz de estados no cubre el caso: "Mapa cargado → jru vacío recibido → Renderizar fallback". Existe una transición implícita no documentada.

---

## 🟢 Hallazgos Medios (Mejoras)

### Q-07 [Redacción EARS] — `RF-2`
**Ubicación:** p.54  
**Sugerencia:** "EL SISTEMA mueve la vista del TileMap isométrico" - podría especificarse más: "EL SISTEMA desplaza el nodo de cámara 5px verticalmente hacia abajo cada 0.1s" para ser más testeable.

---

## 🔍 Auditoría de 6 Dimensiones

### 1. Ambigüedades y Test Oracle Check
- **RF-4:** ❌ El mensaje `kva` no tiene posición - es incorrecto
- **RF-1:** ❌ "timer expira" sin valor concreto definido
- **RF-4:** ❌ Sin contrato de datos para `kva`/`ivx`/`itg`

### 2. Contradicciones y Máquina de Estados
- **RF-2 vs RF-3:** ❌ Conflicto input cámara vs colisión avatar
- **Matriz de estados:** ❌ Transiciones faltantes críticas

### 3. Casos Límite y Dimensiones Faltantes
- Map ID = 0 o negativo: ❌ No cubierto
- Race condition timer vs jru válido: ❌ No cubierto
- CellID fuera de rango: ❌ No cubierto
- Tile ID desconocido > 3: ❌ No cubierto
- Cache saturada: ❌ No cubierto

### 4. Conflictos Constitucionales
- **P-001:** ❌ Necesidad de parser `.d2p` sin especificar dependencias
- **P-003:** ❌ Riesgo de exceder 500 líneas con renderer complejo

### 5. Scope Creep
- Cache de assets: ❌ Fuera de scope según backlog original
- Pipeline de conversión PNG→AtlasTexture: ❌ No especificado como fuera de alcance

---

## ❓ Dudas CríticasPendientes

1. **[NECESITA ACLARACIÓN] ¿Cómo se obtiene el mapa visual exacto desde los archivos `.d2p`?**
   - Los archivos `.d2p` son un formato propietario de Ankama que requiere parsing especializado
   - El constitution P-001 prohíbe dependencias externas sin aprobación explícita
   - NO existe parser `.d2p` en GDScript estándar de Godot 4.8

2. **[NECESITA ACLARACIÓN] ¿Cuál es el valor del timer de fallback para `jru`?**
   - El RFC sugiere timing sin valor concreto

3. **[NECESITA ACLARACIÓN] ¿Qué define un "map ID inválido"?**
   - Sin criterios explícitos de validez, el RFC no es falsable

---

## 📋 Correcciones Propuestas

### RF-1 (CORREGIDO)
> CUANDO el servidor envía `jru` válido, EL SISTEMA renderiza el mapa en un TileMap isométrico con el avatar del jugador centrado.  
> SI el `jru` es vacío o el timer de 30 segundos expira, EL SISTEMA usa el map ID `191105026` y SPAWN al jugador.

### RF-3 (AGREGADO)
> SI el jugador intenta moverse a una celda con muro, ENTONCES EL SISTEMA reproduce un sonido de colisión y MANTIENE la posición del avatar.

### RF-4 (REESCRITO)
> CUANDO el servidor envía un mensaje con `cell_id` y `entity_id`, EL SISTEMA posiciona el avatar en esa celda usando transformación isométrica.

### RNF-1 (ACTUALIZADO)
> Solo Node2D + TileMap de Godot 4.8 + GDScript pura. **Parser .d2p requiere aprobación explícita** según P-001.

---

## ✅ Próximos Pasos

1. **Resolver dudas abiertas** (preguntas 1-3 arriba)
2. **Actualizar spec.md** con correcciones propuestas
3. **Re-audit** la especificación corregida
4. **Aprobar** para pasar a `/sdd-plan`

---

**Especialista:** QA Requisitos  
**Estado:** `clarification.status = FAIL`  
**Razón:** Dudas abiertas críticas no resueltas (especialmente el parsing de `.d2p`)