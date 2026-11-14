# sdd-flow — Wizard SDD completo

Skill que orquesta todo el flujo Spec-Driven Development como un asistente interactivo.

## Uso

Invoca con una idea:
```
/sdd-flow "funcionalidad: login Dofus"
/sdd-flow "CLI para hábitos: add, done, list"
/sdd-flow --skip-constitution "login básico"
```

## Estructura

```
.opencode/skills/sdd-flow/
└── SKILL.md
```

## Pasos del wizard

1. Constitution (opcional)
2. Spec → generate spec.md
3. Clarify → QA notes
4. Plan → generate plan.md
5. Tasks → generate tasks.md
6. Implement → TDD iterative
7. Validate → final QA

## Estado

Usa `.sdd-state.json` para guardar progreso.

## Control

- `resume` - continuar desde último paso
- `skip <step>` - saltar paso
- `reset` - reiniciar flujo
- `show` - mostrar estado actual