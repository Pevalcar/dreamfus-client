# sdd-plan — Generador de planes técnicos SDD

Skill para generar planes de implementación sin escribir código.

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

Invoca directamente: `/sdd-plan`

Lee spec.md y constitution.md, genera plan.md con:
- Arquitectura de módulos
- Modelo de datos con ejemplo JSON
- Algoritmo principal (pseudocódigo)
- Contrato de la CLI
- Decisiones técnicas
- Cobertura de RF

## Estructura

```
.opencode/skills/sdd-plan/
├── SKILL.md        # Instrucciones principales
├── README.md       # Esta ayuda
└── plan-template.md # Plantilla del output
```