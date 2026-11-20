---
name: sdd-variants
description: "Genera múltiples variantes de implementación, las evalúa y produce una shortlist ranqueada. Scoring: RF Coverage 30%, Constitution 25%, Simplicity 20%, Tests 15%, Maintainability 10%."
version: 1.0.0
disable-model-invocation: true
---

## Contexto compartido
- **Consume:** `approved_phases` incluye `validate`, `spec`, `plan`, `active_spec_dir`
- **Produce:** `variants-ranking.md`, actualiza `.sdd-state.json` con la variante elegida
- **Desbloquea:** ningún skill (fase final del ciclo)

# Generador de Variantes SDD

Crea y evalúa múltiples enfoques de implementación para una funcionalidad, produciendo una shortlist ranqueada.

## 🛡️ ASSUMPTIONS I'M MAKING:

1. La spec existe en `specs/NNN-xxx/spec.md`
2. El usuario quiere explorar alternativas de implementación
3. La constitución está disponible en `docs/constitution.md`
4. Hay tiempo suficiente para crear y evaluar N variantes
→ Correct me now or I'll proceed.

## When to Use

- Quieres explorar alternativas de implementación
- Decisiones de diseño técnicas no están claras
- Quieres validar que la solución elegida es la mejor
- Post-implementación: comparar enfoques alternativos

## When NOT to Use

- Ya tienes una solución implementada y validada
- El tiempo es limitado (usar DoD en su lugar)
- La spec no está clara (volver a clarify primero)

## Process

### Paso 1: Definir N Variantes

Genera N variantes de implementación (recomendado: N=3)

Cada variante debe incluir:
- Enfoque técnico diferente
- Arquitectura alternativa
- Trade-offs explicados

### Paso 2: Implementar en aislamiento

Para cada variante:
1. Crear rama/worktree separada
2. Implementar solo lo necesario para validar
3. Escribir tests relevantes
4. Documentar limitaciones

### Paso 3: Evaluar contra criterios

Para cada variante evaluar:
- **RF Coverage (30%):** % de RF con implementation
- **Constitution (25%):** ¿Cumple los principios innegociables?
- **Simplicity (20%):** LOC +Complejidad ciclomática
- **Tests (15%):** Cobertura + calidad de tests
- **Maintainability (10%):** Nombrado + claridad

### Paso 4: Rankear y producir shortlist

Ordenar variantes por puntuación y producir:

```markdown
# Rankings de Variantes — 001-xxx

## Scoring

| Variant | RF Coverage | Constitution | Simplicity | Tests | Total |
|---------|-------------|--------------|------------|-------|-------|
| Var-A   | 90%         | ✅           | 45 LOC     | 80%   | 215   |
| Var-B   | 85%         | ✅           | 30 LOC     | 90%   | 225   |
| Var-C   | 95%         | ⚠️           | 50 LOC     | 75%   | 190   |

## Shortlist

### 1. Variante B (puntaje: 225) - RECOMENDADA
**Razón:** Mejor equilibrio simplicidad/tests. Cumple constitutional.
**Limitaciones:** Algunos edge cases no cubiertos.

### 2. Variante C (puntaje: 190)
**Razón:** Cubre más RF pero viola principio de simplicidad.
**Limitaciones:** Mayor complejidad, constitutional en riesgo.

### 3. Variante A (puntaje: 215)
**Razón:** Muy buena, pero más código que Var-B.
**Limitaciones:** No es la más simple posible.

## Recommendation

Adoptar **Variante B** como implementación final.
Migrar insights de Var-C (edge cases) si son críticos.
Descartar Var-A como sobre-engineered.
```

## Output Format

`specs/001-xxx/variants-ranking.md`

```markdown
# Rankings de Variantes — 001-xxx

## Variante 1: <nombre>
- **Enfoque:** <descripción breve>
- **Implementado en:** branch `variant-1-<nombre>`
- **RF Coverage:** X%
- **Test Coverage:** Y%
- **LOC:** Z
- **Complejidad:** <ciclomática promedio>
- **Constitution Score:** ✅/⚠️/❌

## Variante 2: <nombre>
- ...

## Shortlist Ranqueada
1. <mejor variante> (justificación)
2. <segunda mejor> (justificación)
3. <tercera mejor> (justificación)

## Decisión
**Adoptar:** <variante elegida>
**Razones:** <bullet points>
```

## Evaluation Criteria

| Criterio | Peso | Cómo evaluar | Umbral |
|----------|------|--------------|--------|
| RF Coverage | 30% | % de RF con implementation | ≥ 90% |
| Constitution | 25% | ¿Cumple los 6 principios? | ✅ |
| Simplicity | 20% | LOC +Complejidad | < 100 LOC promedio |
| Tests | 15% | Cobertura + calidad de tests | ≥ 80% |
| Maintainability | 10% | Naming + claridad | ✅ |

**Reglas de evaluación:**
- Si Constitution Score es ❌ → Eliminación automática
- Si RF Coverage < 90% → ⚠️ o ❌ según criticalidad
- Puntuación = Σ (score_i × weight_i) / 100

## Rationalizations

| Excusa | Realidad | Regla |
|--------|----------|-------|
| *"Ya encontré una solución, no necesito variants"* | La mejor solución local no es necesariamente la mejor global | Siempre explorar 3 opciones en decisiones importantes |
| *"Mejorar variantes es un gasto de tiempo"* | La inversión en explore-evalsave hours of rework | 2-4hrs explore → 20hrs saved rework |
| *"Solo una solución necesaria"* | Solo cuando el scope es trivial o deadline crítico | Para features importantes, siempre generar 3 variantes |

## Verification

- [ ] Se generaron N variantes (recomendado: 3)
- [ ] Cada variante tiene implementación en aislamiento
- [ ] Cada variante tiene tests para RF clave
- [ ] Scoring calculado para cada variante con fórmula explícita
- [ ] Shortlist ranqueada con justificación clara
- [ ] Decisión documentada con razones
- [ ] .sdd-state.json actualizado con la variante elegida
- [ ] Gate de aprobación humana: "¿Se aprueba la variante recomendada? Sí / No"

## See Also

- `sdd-validate` - Validación post-implementación
- `definition-of-done.md` - Criterios de calidad universal