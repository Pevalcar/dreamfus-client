---
name: sdd-constitution
description: Genera docs/constitution.md con principios cortos y verificables.
disable-model-invocation: true
---

# Generador de Constitución SDD

Define los principios innegociables del proyecto.

## Pasos

1. **Recibe requisitos** sobre: stack, qualidad, tests, límites
2. **Genera `docs/constitution.md`** con máximo 15 líneas

## Plantilla

```markdown
# Constitución — <Nombre Proyecto>

1. **Stack mínimo.** <lenguaje> + <máx N dependencias>. <restricción>.
2. **Spec antes que código.** <cómo se valida>.
3. **Separación lógica.** <qué capas existen y su responsabilidad>.
4. **Tests obligatorios.** <quién escribe, cobertura mínima>.
5. **Persistencia controlada.** <qué se guarda, cómo, cuándo>.
6. **Idioma.** <qué idioma, convenciones>.
```

**Reglas:**
- Cada principio < 40 palabras
- Verificables: "máximo", "obligatorio", "debe", "no"
- Espera aprobación antes de escribir