# Skills SDD — Spec-Driven Development

Sistema completo de skills para desarrollo guiado por especificación.

## Skills disponibles

| Skill | Uso | Output |
|---|---|---|
| `/sdd-constitution` | Crear constitución del proyecto | `docs/constitution.md` |
| `/sdd-spec` | Generar especificación | `specs/001-xxx/spec.md` |
| `/sdd-clarify` | Revisión QA de spec | Notas agregadas a spec.md |
| `/sdd-plan` | Generar plan técnico | `specs/001-xxx/plan.md` |
| `/sdd-tasks` | Generar tareas | `specs/001-xxx/tasks.md` |
| `/sdd-implement Tn` | Implementar tarea (TDD) | Código + tests, marca Tn completada |
| `/sdd-validate` | Validar RF por RF | Tabla cobertura RF→Test |
| `/sdd-flow "idea"` | Wizard completo | Genera todo el flujo |

## Flujo SDD

```
constitution → spec → clarify → plan → tasks → implement → validate
```

## Estructura de carpetas

Cada skill es una carpeta autocontenida con:
```
.opencode/skills/sdd-xxx/
├── SKILL.md        # Instrucciones principales
├── README.md       # Ayuda y uso
└── <template>.md   # Plantilla de output (cuando aplica)
```

## Ejemplo de uso

```
/sdd-flow "funcionalidad: login Dofus"
→ Wizard pregunta por constitución
→ Genera spec.md
→ QA automático
→ Plan técnico
→ Tareas verificables
→ Implementa T1 con TDD
→ Valida RF por RF
```

## Plantillas incluidas

- `spec-template.md` - Formato de especificación con RF-EARS
- `plan-template.md` - Formato de plan con pseudocódigo
- `tasks-template.md` - Formato de tareas con checkboxes
- `clarify-template.md` - Formato de revisión QA

## Reglas SDD

1. **Especificación antes que código** - Ningún RF sin spec
2. **TDD obligatorio** - Test primero, código mínimo
3. **Una tarea a la vez** - Pausa después de cada implementación
4. **Verificables** - RF son verificables, no adjectivos
5. **FUERA de alcance** - Siempre definir lo que NO se implementa