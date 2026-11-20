---
name: sdd-backlog
description: "Destila una idea o funcionalidad en un backlog corto de historias de usuario verticales (1 línea), alineado con docs/constitution.md, con mapeo de decisiones costosas y límites de alcance (Out of Scope)."
version: 1.0.0
disable-model-invocation: true
---

## Contexto compartido
- **Consume:** `approved_phases` incluye `constitution`, `active_spec_dir`
- **Produce:** actualiza `approved_phases` con `backlog`, `current_phase = backlog`, `next_allowed_phase = sdd-spec`
- **Desbloquea:** `/sdd-spec`

# Generador de Backlog SDD — Vertical Slicing & Scope Control

Convierte una idea o necesidad de negocio en un backlog corto de historias de usuario verticales (una línea cada una, sin detalles técnicos ni criterios de aceptación extensos), garantizando que cada ítem entregue valor real y respete los principios innegociables de `docs/constitution.md`.

## 🛡️ ASSUMPTIONS & HARD RULES

1. **Pre-condición estricta:** `AGENTS.md` y `docs/constitution.md` existen y la fase `constitution` está aprobada en `.sdd-state.json`.
2. **Cero historias técnicas:** El actor nunca es el desarrollador, el agente ni el sistema. La infraestructura se construye dentro de la primera historia funcional que la necesite (_Walking Skeleton_).
3. **Respeto constitucional:** Ninguna historia puede contradecir los principios `P-001`…`P-0NN` de `docs/constitution.md`.
4. **Control de alcance (`Out of Scope`):** Todo backlog debe declarar explícitamente qué queda fuera de este ciclo para evitar _scope creep_ en fases posteriores.
5. **Human-Gate por defecto:** No se escribe `docs/backlog.md` ni se desbloquea la siguiente fase sin aprobación humana explícita, salvo que el proyecto esté en modo `/build auto`.

---

## When to Use

- Inicio de un proyecto o una nueva funcionalidad (_feature_) tras aprobar `docs/constitution.md`.
- Cuando tienes una idea general y necesitas dividirla en cortes verticales (_vertical slices_) ordenados por valor.
- Antes de ejecutar `/sdd-story` (refinamiento individual) o `/sdd-spec` (especificación formal).

## When NOT to Use

- `docs/constitution.md` no existe o no está aprobada en `.sdd-state.json` (ejecutar `/sdd-constitution` primero).
- Ya existe un `docs/backlog.md` aprobado y solo necesitas detallar una historia específica (usar `/sdd-story`).
- Quieres escribir código directamente (bloqueado hasta completar el ciclo SDD).

---

## Proceso de Ejecución

### Fase 0: Pre-flight Check (Obligatorio — Fail-Closed)

Antes de iniciar la entrevista, ejecuta estas 3 verificaciones en orden:

1. **Verificar estado SDD y Constitución:**
   - Comprueba la existencia de `AGENTS.md`, `docs/constitution.md` y `.sdd-state.json`.
   - Verifica que `.sdd-state.json` incluya `"constitution"` en `approved_phases`.
   - **Si falta alguno o no está aprobado:** DETÉN la ejecución y muestra:
     > ⛔ **Bloqueo Pre-flight:** No se puede generar el backlog sin `AGENTS.md` y una constitución aprobada en `docs/constitution.md`. Ejecuta `/sdd-constitution` primero.
   - **Si existen:** Lee `AGENTS.md` y `docs/constitution.md` completos para conocer el stack permitido, los límites del sistema y los principios `P-001`…`P-0NN`.

2. **Verificar existencia previa de `docs/backlog.md`:**
   - Comprueba si `docs/backlog.md` ya existe.
   - **Si SÍ existe:** DETÉN el flujo y pregunta:
     > ⚠️ **Backlog existente detectado:** Ya existe `docs/backlog.md`. ¿Qué deseas hacer?
     >
     > 1. **Añadir nuevas historias** (mantener IDs existentes y agregar nuevas al final).
     > 2. **Reemplazar desde cero** (sobrescribir tras aprobación).
     > 3. **Cancelar**.
   - No avances hasta recibir respuesta explícita.

---

### Fase 1: Entrevista de Descubrimiento (Máximo 5 Preguntas, 1 a 1)

Actúa como un **Product & QA Strategist**. Tu objetivo es entender el flujo de usuario sin discutir implementación ni arquitectura.

- **Una pregunta por turno:** Formula **solo 1 pregunta por mensaje** y espera la respuesta antes de continuar.
- **Tope estricto de 5 preguntas:** Omite cualquier pregunta cuya respuesta ya sea evidente por el prompt inicial del usuario o por `AGENTS.md`.
- **Dimensiones a cubrir:**
  1. **Q1 — Problema y Actores reales:** ¿Quiénes son los usuarios finales concretos (roles) y qué dolor específico resuelve esta funcionalidad?
  2. **Q2 — Walking Skeleton (MVP mínimo):** ¿Cuál es el flujo feliz más pequeño de extremo a extremo que ya le daría valor real a un usuario en producción?
  3. **Q3 — Flujos secundarios y casos borde de negocio:** ¿Qué otras acciones clave necesita completar el usuario (editar, cancelar, filtrar, exportar) y qué pasa ante errores de negocio?
  4. **Q4 — Decisiones costosas de revertir:** ¿Hay alguna regla de negocio, modelo de datos o integración externa que sería muy costoso cambiar después? (Solo identificarla, sin diseñarla).
  5. **Q5 — Anti-goals (`Out of Scope`):** ¿Qué funcionalidades relacionadas **NO** vamos a construir en este ciclo para mantener el alcance controlado?

---

### Fase 2: Auditoría Silenciosa (INVEST + Constitución)

Antes de mostrar el borrador al usuario, valida internamente cada historia contra estas reglas:

1. **Chequeo Constitucional:** ¿Alguna historia viola un principio `P-00X` de `docs/constitution.md`? Si es así, adviértelo y sugiere cómo ajustarla.
2. **Filtro INVEST de 1 línea:**
   - **Verticalidad:** ¿Corta por todas las capas (UI/API/datos) entregando valor observable? Si es una tarea técnica disfrazada, elimínala o intégrala en la historia de usuario correspondiente.
   - **Verbos concretos:** Sustituye verbos vagos (_"gestionar"_, _"manejar"_) por acciones observables (_"crear"_, _"consultar"_, _"anular"_).
   - **No inventar requisitos:** Si detectas un hueco en lo que dijo el usuario, márcalo como pregunta abierta en lugar de inventar una historia.

---

### Fase 3: Borrador y Gate de Aprobación Humana

Genera el borrador **en memoria** (sin escribir archivos todavía) usando exactamente esta estructura:

```markdown
## Context

- **Propósito:** <1-2 líneas: qué resuelve y para quién>
- **Actores:** <lista de roles reales identificados>
- **Expensive decisions:** <decisiones difíciles de revertir, o "none">
- **Out of Scope (Este ciclo):**
  - <funcionalidad excluida 1>
  - <funcionalidad excluida 2>

## Backlog (Vertical Slices)

1. As a <actor>, I want <walking skeleton: acción mínima de extremo a extremo>, so that <beneficio inmediato>.
2. As a <actor>, I want <acción concreta>, so that <beneficio>. Requires: #1
3. As a <actor>, I want <acción concreta>, so that <beneficio>.
```

_(Reglas del listado: máximo 12-15 historias; IDs secuenciales `#1`..`#N` inmutables; `Requires: #N` solo cuando exista dependencia funcional estricta)._

## 🔒 Gate de Aprobación Humana (Backlog SDD)

**Resumen de auditoría:**

- Alineado con `docs/constitution.md` (`P-001`…`P-0NN`): ✅ Sin conflictos
- Total de historias verticales: X (Historia #1 = _Walking Skeleton_)
- Historias técnicas detectadas: 0
- Exclusiones (`Out of Scope`) documentadas: Y

¿Apruebas este backlog para guardarlo en `docs/backlog.md`?

- [ ] **Sí** → Guardar `docs/backlog.md`, actualizar `.sdd-state.json` y desbloquear la siguiente fase (`/sdd-story` o `/sdd-spec`).
- [ ] **No** → Indicar qué historias ajustar, dividir o eliminar (no se escribirá nada hasta nueva aprobación).

## 🔒 Reglas de Bloqueo y Gobernanza

1. **Cero escritura sin "Sí" explícito (en modo `human-gated`):** Si `.sdd-state.json` tiene `"execution_mode": "human-gated"`, no se crea ni modifica `docs/backlog.md` hasta que el usuario responda afirmativamente.
2. **Inmutabilidad de `AGENTS.md`:** Esta skill **nunca** modifica `AGENTS.md`. Toda la persistencia del backlog vive exclusivamente en `docs/backlog.md` y su estado en `.sdd-state.json`.
3. **Comportamiento en `/build auto`:** Si `.sdd-state.json` tiene `"execution_mode": "auto"`, la skill aún debe ejecutar la entrevista de descubrimiento (si la idea inicial tiene vacíos críticos) y validar que no existan conflictos con `docs/constitution.md`, pero puede guardar `docs/backlog.md` automáticamente tras superar la Auditoría Silenciosa de Fase 2 sin pausa manual.

## What Happens After Approval

Una vez aprobado el backlog:

1. Se escribe o actualiza `docs/backlog.md` con metadatos de versión y fecha.
2. Se actualiza `.sdd-state.json` manteniendo intacto `execution_mode`:

```json
{
  "constitution_version": "1.0.0",
  "agents_md_checked": true,
  "execution_mode": "human-gated",
  "current_phase": "backlog",
  "approved_phases": ["constitution", "backlog"],
  "next_allowed_phase": "sdd-story",
  "gate_status": "approved"
}



3. **Ningún código ni especificación técnica se escribe todavía.** Se indica al usuario que puede continuar con `/sdd-story` (para refinar una historia con criterios de aceptación) o `/sdd-spec`.
```
