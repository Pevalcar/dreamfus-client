---
name: sdd-validate
description: Recorrido RF por RF verificando tests y completitud.
disable-model-invocation: true
---

# Validador SDD — Trazabilidad RF→Test

Comprueba que cada requisito funcional está cubierto y pasa sus tests.

## Pasos

1. **Lee la spec.** `specs/001-xxx/spec.md`
2. **Lee los tests.** directorio `tests/` o `test/`
3. **Genera reporte de validación:**

## Formato output

```markdown
# Validación — 001-xxx

## Recorrido RF por RF

| RF | Test | Resultado | Comentario |
|---|---|---|---|
| RF-1 | test_xxxx | ✅ PASA | ... |
| RF-2 | test_yyyy | ❌ FALLA | ... |

## Cobertura
- RF cubiertos: X/Y
- Tests sin RF: [...]
- RF sin test: [...]

## Veredicto

**Elegir uno:** [ ] ✅ Spec cumplida | [ ] ⚠️ Incompleta | [ ] ❌ Rechazada

**Razón:** <explicación breve>
```

**Reglas:**
- Ejecuta los tests relevantes
- Si RF no tiene test: marcar como ❌
- Veredicto requiere 2/3 criterios de finalización