---
name: sdd-flow
description: "Orquesta todo el flujo SDD: setup → constitution → backlog → spec → clarify → plan → review → tasks → implement → validate → variants. Un wizard interactivo que respeta verification gates."
version: 1.0.0
disable-model-invocation: true
---

## Contexto compartido
- **Consume:** `.sdd-state.json`, perfil detectado por `sdd-discover`
- **Produce:** actualiza `current_phase`, `approved_phases`, `gate_status` tras cada fase aprobada
- **Desbloquea:** cada skill del flujo según el gate superado

# Wizard SDD — Desarrollo guiado por especificación

Orquesta todo el flujo Spec-Driven Development como un asistente interactivo.

## 🛡️ ASSUMPTIONS I'M MAKING:

1. El repositorio tiene un directorio de trabajo válido
2. Usuario quiere iniciar nuevo flujo SDD o reanudar existente
3. `.sdd-state.json` puede existir con estado previo
4. Los 5 perfiles están instalados en `.agents/skills/profiles/`
5. El reference library de skills está disponible para routing
   → Correct me now or I'll proceed.

## When to Use

- Start nuevo proyecto desde cero (sin AGENTS.md)
- Reanudar flujo interrumpido (`/sdd-flow resume`)
- Ejecutar pipeline completo sin pasos manuales
- Need to discover which skill to use first

## When NOT to Use

- Ya estás en medio de un flujo manual
- Solo necesitas un skill específico (usar directamente)
- Proyecto no tiene specs iniciales

## Usage

Invoca con una idea:

```
/sdd-flow "funcionalidad: login Dofus"
/sdd-flow "CLI para hábitos: add, done, list"
/sdd-flow --skip-constitution "login básico"
```

## Estado del flujo

Guarda estado en: `.sdd-state.json`

```json
{
  "version": "2.1.0",
  "current_phase": "spec",
  "approved_phases": ["setup", "constitution"],
  "profiles_active": [],
  "specs_count": 1,
  "tasks_total": 0,
  "tasks_completed": 0,
  "last_checkpoint": null,
  "clarification": {
    "status": "pending",
    "verdict": null,
    "report_path": null
  },
  "backlog": {
    "status": "pending",
    "stories": []
  },
  "specs": {}
}
```

## El Flow Completo

### Phase 0: Setup

**Invoca:** `/sdd-setup` → `/sdd-constitution`

- Verificar si `AGENTS.md` existe
- Verificar si `docs/constitution.md` existe
- Crear ambos si no existen
- **PAUSED:** Espera aprobación humana

### Phase 1: Backlog (Historias de Usuario)

**Invoca:** `/sdd-backlog`

- Convierte una idea vaga en backlog corto de historias verticales
- Una línea por historia, sin acceptance criteria, sin detalles técnicos
- Primera historia: stack definition. Segunda: walking skeleton.
- Genera `specs/001-xxx/backlog.md`
- **PAUSED:** Espera aprobación humana del backlog

### Phase 2: Especificación (SPEC)

**Invoca:** `/sdd-spec`

- Entrevista secuencial (máx 6 preguntas)
- Genera `specs/001-xxx/spec.md` con:
  - Objetivo y contexto
  - Usuarios e historias de usuario
  - RF en notación EARS
  - Requisitos no funcionales
  - Casos límite
  - Fuera de alcance
  - Dudas abiertas [NECESITA ACLARACIÓN]
- **PAUSED:** Espera aprobación humana antes de continuar

### Phase 3: Clarificación QA (loop)

**Invoca:** `/sdd-clarify`

- Lee spec + constitution
- Detecta: ambigüedades, contradicciones, casos faltantes
- QA automático con severidad 🔴/🟡/🟢
- Veredicto PASS/FAIL
- **PAUSED:** Preguntar: "¿Spec clarificada? Sí / No (volver a clarify)"
- **LOOP:** Si no, volver a sdd-clarify hasta que esté claro

### Phase 4: Planificación

**Invoca:** `/sdd-plan`

- Lee spec + constitution
- Genera `specs/001-xxx/plan.md`:
  - Módulos y dependencias (diagrama)
  - Modelo de datos con ejemplo JSON
  - Algoritmo principal (pseudocódigo)
  - Contrato CLI
  - Decisiones técnicas + alternativas descartadas
  - Cobertura RF por módulo
- **PAUSED:** Espera aprobación humana antes de continuar

### Phase 5: Revisión de decisiones

**Invoca:** `/sdd-review`

- Análisis de suposiciones no cubiertas por sdd-clarify
- Preguntas de doubt-driven development
- Alternativas técnicas para decisiones clave
- Producir `specs/001-xxx/review.md`
- **PAUSED:** ¿Se aprueba el plan de implementación? Sí / No

### Phase 6: Tareas

**Invoca:** `/sdd-tasks`

- Genera `specs/001-xxx/tasks.md`
- Tareas ≤ 30 min cada una
- Orden por dependencia
- Checkbox con "Hecho cuando:" verificable
- **PAUSED:** Espera aprobación humana

### Phase 7: Implementación (TDD por tarea)

**Invoca:** `/sdd-implement`

Por iteración:

1. Lee Tn, plan, spec
2. Escribe test primero (falla → rojo)
3. Escribe código mínimo (pasa → verde)
4. Ejecuta test suite
5. Refactor si necesario
6. Commit cambios
7. Marca `[x] Tn` en tasks.md
8. **PAUSED:** "Tarea Tn completada. ¿Continuar con T(n+1)?"

### Phase 8: Validación final

**Invoca:** `/sdd-validate`

- Recorrido RF por RF
- Qué test cubre cada uno
- Estado: ✅ PASA / ❌ FALLA / ⚠️ SIN TEST
- Veredicto: "✅ Spec cumplida" o lista pendientes

### Phase 9: Variants

**Invoca:** `/sdd-variants`

- Generar N variantes de implementación
- Evaluar vs AC/constitución/simplicidad
- Producir `variants-ranking.md` con shortlist ranqueada
- **PAUSED:** ¿Se aprueba la variante recomendada? Sí / No
- Actualizar `.sdd-state.json` con la variante elegida

## Control del wizard

| Comando                 | Acción                                   |
| ----------------------- | ---------------------------------------- |
| `/sdd-flow resume`      | Reanuda desde último step                |
| `/sdd-flow skip <step>` | Salta un paso                            |
| `/sdd-flow reset`       | Reinicia el flujo                        |
| `/sdd-flow show`        | Muestra estado actual                    |
| `/sdd-discover`         | Ejecuta descubrimiento de perfil primero |

## Verification Gates

El wizard respeta los gates de verificación:

```
SETUP → CONSTITUTION → BACKLOG → SPEC → CLARIFY → PLAN → REVIEW → TASKS → IMPLEMENT → VALIDATE → VARIANTS
    │          │         │     │      │       │     │       │     │        │         │          │
    ▼          ▼         ▼     ▼      ▼       ▼     ▼       ▼     ▼        ▼         ▼          ▼
  HUMAN      HUMAN     HUMAN   HUMAN   HUMAN   HUMAN   HUMAN   HUMAN   HUMAN    HUMAN      HUMAN
  REVIEW     REVIEW    REVIEW   REVIEW  REVIEW  REVIEW  REVIEW  REVIEW   REVIEW   REVIEW     REVIEW
```

Cada fase tiene un checklist de verificación que debe pasarse:

- **sdd-setup:** AGENTS.md + constitution creados y aprobados
- **sdd-constitution:** Principios innegociables aprobados por el usuario
- **sdd-backlog:** Backlog de historias aprobado por el usuario
- **sdd-spec:** Spec con RF-EARS aprobada por el usuario
- **sdd-clarify:** QA automático pasado (PASS)
- **sdd-plan:** Arquitectura validada
- **sdd-review:** Decisiones críticas revisadas y aprobadas
- **sdd-tasks:** Tasks son accionables
- **sdd-implement:** Tests pasan, tarea marcada como completada
- **sdd-validate:** DoD checklist pasado + Constitution compliance
- **sdd-variants:** Gate de aprobación humana para variante recomendada

## Output esperado

Al finalizar, tendrás:

- `AGENTS.md` (raíz del proyecto)
- `CLAUDE.md` (raíz del proyecto, referencia a AGENTS.md)
- `docs/constitution.md`
- `specs/001-xxx/backlog.md`
- `specs/001-xxx/spec.md`
- `specs/001-xxx/plan.md`
- `specs/001-xxx/review.md`
- `specs/001-xxx/tasks.md`
- `specs/001-xxx/variants-ranking.md`
- Tests pasando 100%
- Código mínimo que cumple spec
- `specs/001-xxx/validation.md`

## Reglas del wizard

- **Un paso a la vez.** Pausa después de cada output
- **Aprobación explícita.** No avanza sin el usuario
- **Tests primero.** TDD obligatorio
- **Verificables.** "Hecho cuando" debe poder automatizarse
- **One assumption at a time.** Surface assumptions before each major step
- **Stop after spec.** Once spec is written, STOP until human approval
- **Clarify loop.** Keep asking until spec is crystal clear

## See Also

- `/sdd-discover` - Detect profile and current state
- `spec-driven-development` - Full spec pattern from reference
- `incremental-implementation` - Incremental build cycle
- `test-driven-development` - Testing patterns
- `definition-of-done.md` - Universal quality bar