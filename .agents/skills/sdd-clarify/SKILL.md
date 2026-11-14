---
name: sdd-clarify
description: Revisa una spec como QA profesional para detectar ambigüedades, contradicciones y huecos antes de planificar.
disable-model-invocation: true
---

# Clarificador SDD — Revisión QA de especificaciones

Identifica problemas en una spec antes de pasar a planificación. Elimina dudas, conflictos y casos faltantes.

## Pasos

1. **Lee la spec.** `specs/001-xxx/spec.md` completa.
2. **Lee la constitución.** `docs/constitution.md` para validar principios.
3. **Actúa como QA.** Detecta sin resolver:

## Qué detectar (lista numerada)

| Categoría | Qué buscar |
|---|------------|
| **Ambigüedades** | Términos sin definir, comportamientos implícitos |
| **Contradicciones** | RF que se contradicen entre sí |
| **Casos límite faltantes** | Errores, límites, datos corruptos, null, vacío |
| **Conflictos con constitución** | Violaciones de principios innegociables |

## Output

Agrega sección al final de `spec.md`:

```markdown
## Revisión QA

### Ambigüedades restantes
1. [...]
2. [...]

### Contradicciones entre requisitos
1. [...]
2. [...]

### Casos límite no cubiertos
1. [...]
2. [...]

### Conflictos con constitución
1. [...]
2. [...]

### Resumen
- RF con ambigüedad: [lista]
- RF con contradicción: [lista]
- Casos límite faltantes: [lista]
```

**Reglas:**
- Solo detecta, no resuelve
- Usa formato de lista numerada
- Si todo está claro: "✅ No se detectan problemas críticos"