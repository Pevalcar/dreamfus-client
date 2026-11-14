# sdd-spec — Generador de especificaciones SDD

Skill para generar specs siguiendo el flujo **Spec-Driven Development**.

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

Invoca directamente: `/sdd-spec`

Te pide una pregunta a la vez, recibe respuestas, y genera `specs/001-xxx/spec.md`.

El output incluye plantilla completa con:
- Contexto y objetivo
- Usuarios / actores
- Historias de usuario
- RF-1, RF-2, ... en notación EARS
- RNF, casos límite, fuera de alcance
- Dudas abiertas

## Estructura

```
.opencode/skills/sdd-spec/
├── SKILL.md        # Instrucciones principales
├── README.md       # Esta ayuda
└── spec-template.md # Plantilla del output
```

## Instalación global

```bash
mkdir -p ~/.opencode/skills && cp -R .opencode/skills/sdd-spec ~/.opencode/skills/
```

## Mantenimiento

Edita solo `SKILL.md` como único archivo fuente.