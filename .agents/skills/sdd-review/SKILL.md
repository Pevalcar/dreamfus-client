---
name: sdd-review
description: "Review profundo de specs y planes usando doubt-driven development. Genera preguntas de crítica y alternativas técnicas."
version: 1.0.0
disable-model-invocation: true
---

## Contexto compartido
- **Consume:** `approved_phases` incluye `plan`, `spec`, `active_spec_dir`
- **Produce:** `review.md`, actualiza `approved_phases` con `review`
- **Desbloquea:** `/sdd-tasks`

# Generador de Revisiones SDD - Doubt-driven review

Proporciona una revisión profunda de especificaciones y planes técnicos mediante el patrón doubt-driven-development. Detecta ambigüedades en suposiciones, genera preguntas de crítica adversariales, y propone alternativas técnicas viables.

## 🛡️ ASSUMPTIONS I'M MAKING:

1. El spec existe en `specs/NNN-xxx/spec.md` con una sección de suposiciones explícitas
2. El usuario quiere validar decisiones técnicas antes de implementar
3. El doc de constitución existe para validar suposiciones contra principios
4. El skill se usa como revisión posterior a sdd-clarify y sdd-plan
→ Correct me now or I'll proceed.

## When to Use

- Quieres cross-examinar decisiones técnicas importantes
- Sospechas que hay suposiciones no validadas
- Necesitas validar que la solución elegida es la mejor
- Quieres documentar el "por qué" detrás de decisiones técnicas

## When NOT to Use

- Ya hiciste una revisión completa con sdd-clarify
- El scope es muy pequeño (un fix rápido)
- No tienes tiempo para una revisión profunda
- Solo necesitas validar que los tests pasan (usar sdd-validate)

## Process

### Paso 1: Preparación

Lee los archivos necesarios:
- `specs/001-xxx/spec.md` - Requisitos y suposiciones
- `specs/001-xxx/plan.md` - Decisiones técnicas (si existe)
- `docs/constitution.md` - Principios del proyecto

Verifica que existen y están actualizados.

### Paso 2: Análisis de suposiciones

Extrae todas las suposiciones explícitas del spec:

```markdown
## ASUMPTIONS I'M MAKING:

1. [suposición sobre el contexto del proyecto]
2. [suposición sobre el stack/tecnología]
3. [suposición sobre el estado previo del proyecto]
```

Para cada suposición:
- Clasifica por severidad (high/medium/low)
- Asigna categoría (tech/scope/data/integration)

### Paso 3: Generar preguntas de duda

Para cada suposición, genera preguntas adversariales:

```markdown
### Suposición N: <texto>

**Preguntas para cross-examining:**

1. ¿Qué pasa si... [escenario adversarial]
2. ¿Qué evidencia respalda esta suposición
3. ¿Hay alternativas factibles...
```

### Paso 4: Explorar alternativas

Para decisiones técnicas clave, genera alternativas:

```markdown
## Alternativas

**Decisión:** <descripción>

### Opción A: <nombre>
- **Approach:** <descripción>
- **Pros:** <lista>
- **Cons:** <lista>

### Opción B: <nombre>
- **Approach:** <descripción>
- **Pros:** <lista>
- **Cons:** <lista>

**Recomendación:** <opción elegida>
```

### Paso 5: Generar reporte

Produce `specs/001-xxx/review.md` con estructura:

```markdown
# SDD Review Report

## Summary
- Total assumptions detected: N
- Total doubt questions: M
- Alternatives explored: K

## Assumptions Detected
| # | Texto | Severidad | Categoría | Línea |

## Questions for Cross-Examining

## Alternative Approaches

## Recommendations

## Action Items

## Next Steps
```

## Output Format

`specs/001-xxx/review.md`

## Evaluation Criteria

| Criterio | Peso | Cómo evaluar |
|----------|------|--------------|
| Assumption Detection | 30% | Número de suposiciones detectadas vs esperadas |
| Question Quality | 25% | Preguntas son adversariales y accionables |
| Alternatives | 20% | Realistas y factibles |
| Constitution Check | 15% | Las suposiciones respetan los principios |
| Actionability | 10% | El reporte genera acciones concretas |

## Rationalizations

| Excusa | Realidad | Regla |
|--------|----------|-------|
| *"Ya revisé con sdd-clarify, no necesito sdd-review"* | sdd-clarify hace QA básico, sdd-review hace cross-examining adversarial | Usar sdd-review para decisiones técnicas no triviales |
| *"Es rápido, no necesito revisión profunda"* | Decisiones técnicas mal pensadas cuestan horas de re-trabajo | Invertir 10-15min en review → ganar horas de implementación |
| *"No tengo tiempo para alternativas"* | Elegir sin alternativas = arriesgar decisiones | Mínimo explorar 2 alternativas para decisiones importantes |
| *"Ya tengo la solución, no vale la pena"* | La mejor solución local ≈ mejor global (no siempre) | Siempre generar 3 opciones para decisiones de arquitectura |

## Verification

- [ ] Se detectaron suposiciones en el spec
- [ ] Se generaron preguntas de duda para cada suposición
- [ ] Se exploraron alternativas para decisiones técnicas
- [ ] El reporte está en `specs/001-xxx/review.md`
- [ ] Se verificó que suposiciones respetan constitution

## See Also

- `sdd-clarify` - Revisión QA automática de specs
- `sdd-constitution` - Verificar principios del proyecto
- `references/anti-rationalizations.md` - Excusas comunes vs realidad
- `references/definition-of-done.md` - Criterios de calidad universal