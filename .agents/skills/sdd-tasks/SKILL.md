---
name: sdd-tasks
description: Genera tasks.md con tareas pequeñas, verificables y ordenadas por dependencia.
disable-model-invocation: true
---

# Generador de tareas SDD

Descompone el plan en tareas implementables paso a paso.

## Pasos

1. **Lee la spec.** `specs/001-xxx/spec.md`
2. **Lee el plan.** `specs/001-xxx/plan.md`
3. **Genera `tasks.md`** con formato:

## Formato output

```markdown
# Tareas — 001-xxx

- [ ] T1: <descripción (≤30 min)>
  - RF: RF-1, RF-3
  - Hecho cuando: <verificable, test pasa>

- [ ] T2: <descripción>
  - RF: RF-2, RF-4
  - Hecho cuando: <verificable>
```

**Reglas:**
- Cada tarea ≤ 30 minutos
- Orden por dependencia (T1 → T2 → T3)
- Cada RF cubierto al menos una vez
- "Hecho cuando" debe ser verificable automáticamente (test, output específico)