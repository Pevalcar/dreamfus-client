# sdd-clarify — Revisión QA de especificaciones

Skill para revisar specs y detectar ambigüedades, contradicciones y huecos.

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

Invoca directamente: `/sdd-clarify`

Lee spec.md y constitution.md, genera notas QA agregadas al final del archivo.

## Estructura

```
.opencode/skills/sdd-clarify/
├── SKILL.md        # Instrucciones principales
├── README.md       # Esta ayuda
└── clarify-template.md # Plantilla del output
```