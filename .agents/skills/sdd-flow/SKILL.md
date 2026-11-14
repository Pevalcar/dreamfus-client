---
name: sdd-flow
description: "Orquesta todo el flujo SDD: constitution → spec → clarify → plan → tasks → implement → validate. Un wizard interactivo."
disable-model-invocation: true
---

# Wizard SDD — Desarrollo guiado por especificación

Orquesta todo el flujo Spec-Driven Development como un asistente interactivo.

## Uso

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
  "step": "spec|clarify|plan|tasks|implement|validate",
  "spec_path": "specs/001-xxx/spec.md",
  "current_task": "T1|T2|..."
}
```

## Pasos del wizard

### 🚀 Paso 1: Constitución (opcional)
**Pregunta:** "¿Crear docs/constitution.md desde cero?"
- Sí: `/sdd-constitution` → constitution.md
- No: saltar a spec

### ✍️ Paso 2: Especificación
**Invoca:** `/sdd-spec`
- Entrevista secuencial (máx 6 preguntas)
- Genera `specs/001-xxx/spec.md`
- Paused: "Spec lista. ¿Continuar a clarify?"

### 🔍 Paso 3: Clarificación QA
**Invoca:** `/sdd-clarify`
- Lee spec + constitution
- Detecta: ambigüedades, contradicciones, casos faltantes
- QA automático
- Agrega sección `Revisión QA` al spec
- Paused: "Spec validada. ¿Continuar a plan?"

### 📐 Paso 4: Planificación
**Invoca:** `/sdd-plan`
- Lee spec + constitution
- Genera `specs/001-xxx/plan.md`:
  - Módulos y dependencias
  - Modelo de datos con ejemplo JSON
  - Algoritmo principal (pseudocódigo)
  - Contrato CLI
  - Decisiones técnicas + alternativas descartadas
  - Cobertura RF por módulo
- Paused: "Plan listo. ¿Continuar a tasks?"

### ✅ Paso 5: Tareas
**Invoca:** `/sdd-tasks`
- Genera `specs/001-xxx/tasks.md`
- Tareas ≤ 30 min cada una
- Orden por dependencia
- Checkbox con "Hecho cuando:" verificable
- Paused: "Tareas listas. ¿Implementar T1?"

### 💻 Paso 6: Implementación (TDD)
**Por iteración:**
1. Lee Tn, plan, spec
2. Escribe test primero (falla → rojo)
3. Escribe código mínimo (pasa → verde)
4. Ejecuta test suite
5. Marca `[x] Tn` en tasks.md
6. Paused: "Tarea Tn completada. ¿Continuar con T(n+1)?"

### ✅ Paso 7: Validación final
**Invoca:** `/sdd-validate`
- Recorrido RF por RF
- Qué test cubre cada uno
- Estado: ✅ PASA / ❌ FALLA / ⚠️ SIN TEST
- Veredicto: "✅ Spec cumplida" o lista pendientes

## Control del wizard

| Comando | Acción |
|---|---|
| `/sdd-flow resume` | Reanuda desde último step |
| `/sdd-flow skip <step>` | Salta un paso |
| `/sdd-flow reset` | Reinicia el flujo |
| `/sdd-flow show` | Muestra estado actual |

## Reglas del wizard

- **Un paso a la vez.** Pausa después de cada output
- **Aprobación explícita.** No avanza sin el usuario
- **Tests primero.** TDD obligatorio
- **Verificables.** "Hecho cuando" debe poder automatizarse

## Output esperado

Al finalizar, tendrás:
- `docs/constitution.md` (si se creó)
- `specs/001-xxx/spec.md`
- `specs/001-xxx/plan.md`
- `specs/001-xxx/tasks.md`
- Tests pasando 100%
- Código mínimo que cumple spec
- `specs/001-xxx/VALIDATION.md` (opcional)