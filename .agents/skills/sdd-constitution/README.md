# sdd-constitution — Generador de constitución de proyecto

Skill para generar la constitución SDD del proyecto.

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

Invoca directamente: `/sdd-constitution`

Pregunta por principios del proyecto y genera la constitución.

## Estructura

```
.opencode/skills/sdd-constitution/
├── SKILL.md        # Instrucciones principales
└── README.md       # Esta ayuda
```

## Plantilla de output

```markdown
# Constitución — <Nombre Proyecto>

1. **Stack mínimo.** <lenguaje> + <max N dependencias>. <restricción>.
2. **Spec antes que código.** <como se valida>.
3. **Separación lógica.** <capas y responsabilidad>.
4. **Tests obligatorios.** <quién escribe, cobertura>.
5. **Persistencia controlada.** <qué se guarda, cómo>.
6. **Idioma.** <idioma, convenciones>.
```