# sdd-validate — Validación final RF por RF

Skill para validar que todos los requisitos funcionales están cubiertos.

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

Invoca directamente: `/sdd-validate`

Lee spec.md y tests/, genera reporte de cobertura.

## Estructura

```
.opencode/skills/sdd-validate/
└── SKILL.md
```

## Output

Genera tabla de trazabilidad RF→Test con:
- Qué test cubre cada RF
- Resultado: ✅ PASA / ❌ FALLA / ⚠️ SIN TEST
- Veredicto final: "✅ Spec cumplida" o lista pendientes