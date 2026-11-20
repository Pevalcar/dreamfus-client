# sdd-review

Skill para revisión profunda de especificaciones y planes técnicos usando **doubt-driven development**.

## Qué hace

- **Detecta suposiciones** en specifications y plans
- **Genera preguntas de crítica** tipo "¿qué pasa si...?"
- **Propone alternativas técnicas** factibles
- **Produce reporte estructurado** en markdown

## Uso

```
/sdd-review
```

## Input

- `specs/001-xxx/spec.md` - Requisitos y suposiciones
- `specs/001-xxx/plan.md` - Decisiones técnicas (opcional)
- `docs/constitution.md` - Principios del proyecto (opcional)

## Output

- `specs/001-xxx/review.md` - Reporte de revisión completo

## Cuándo usar

✅ Usa `/sdd-review` cuando:
- Estás ante una decisión técnica compleja
- Sospechas que hay suposiciones no validadas
- Necesitas validar que la solución elegida es la mejor
- Quieres documentar el "por qué" de decisiones

❌ No uses cuando:
- Solo necesitas QA básico (usa `/sdd-clarify`)
- El scope es muy pequeño (un fix rápido)
- Solo necesitas validar tests (usa `/sdd-validate`)

## Ejemplo de output

```markdown
# SDD Review Report

## Summary
- Total assumptions detected: 8
- Total doubt questions: 24
- Alternatives explored: 3

## Assumptions Detected
| # | Texto | Severidad | Categoría | Línea |

## Recommendations
⚠️ **Prioridad alta:** 2 suposiciones de severidad alta requieren revisión inmediata.
```

## Ver también

- `/sdd-clarify` - Revisión QA automática
- `/sdd-constitution` - Verificar principios
- `doubt-driven-development` - Patrón de revisión adversarial