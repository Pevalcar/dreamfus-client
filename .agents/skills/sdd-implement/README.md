# sdd-implement — Implementación TDD por tareas

Skill para implementar tareas SDD usando TDD.

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

Invoca con número de tarea:
```
/sdd-implement T1
/sdd-implement T2
```

## Ejecutar tests

- **Godot:** `Godot_console.exe --headless --path godot-client -s addons/gut/gut_cmdln.gd -gdir=res://test -gexit`
- **Python:** `pytest -q tests/`
- **JavaScript:** `npm test -- --testNamePattern="Tn"`

## Estructura

```
.opencode/skills/sdd-implement/
└── SKILL.md
```