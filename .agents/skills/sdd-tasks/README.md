# sdd-tasks — Generador de tareas SDD

Skill para generar tareas pequeñas y verificables.

## Flujo SDD completo

```
/sdd-constitution  →  docs/constitution.md          (principios)
        ↓
/sdd-spec            →  specs/001-xxx/spec.md      (requisitos)
        ↓
/sdd-clarify         →  spec.md con notas QA       (validación)
        ↓
/sdd-plan            →  specs/001-xxx/plan.md      (diseño)
        ↓
/sdd-tasks           →  specs/001-xxx/tasks.md     (tareas)
        ↓
/sdd-implement T1    →  código + tests + check     (implementación)
        ↓ (repetir)
/sdd-validate        →  RF por RF verificado       (QA final)
```

## Uso

Invoca directamente: `/sdd-tasks`

Lee spec.md y plan.md, genera tasks.md con tareas pequeñas.

## Estructura

```
.opencode/skills/sdd-tasks/
├── SKILL.md        # Instrucciones principales
├── README.md       # Esta ayuda
└── tasks-template.md # Plantilla del output
```