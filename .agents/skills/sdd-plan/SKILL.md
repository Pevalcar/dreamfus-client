---
name: sdd-plan
description: Genera plan.md con módulos, modelo de datos, pseudocódigo, contrato CLI y decisiones técnicas.
disable-model-invocation: true
---

# Planificador SDD — Diseño técnico

Convierte una spec en un plan de implementación sin escribir código.

## Pasos

1. **Lee la spec.** `specs/001-xxx/spec.md` completa.
2. **Lee la constitución.** `docs/constitution.md` para principios.
3. **Genera `plan.md`** con estas secciones obligatorias:

## Plantilla de output

```markdown
# Plan NNN - <Nombre>

## Arquitectura de módulos
[Diagrama o lista con dependencias]

## Modelo de datos
```json
{ejemplo JSON con campo clave y descripción}
```

## Algoritmo principal (pseudocódigo)
[pseudocódigo claro, sin sintaxis del lenguaje]

## Contrato de la CLI
| Comando | Entrada | Salida | Código error |
|---|---|---|---|
| habits add | <args> | <output> | <código> |

## Decisiones técnicas
- **Decisión 1**: <justificación>
  - Alternativa descartada: <por qué>

## Cobertura de RF
| RF | Módulo | Test asociado |
|---|---|---|
| RF-1 | MóduloA | test_xxxx |
```

**Reglas:**
- Nada de código
- Cada RF debe tener coBERTURA explícita
- Justifica decisiones técnicas
- Respetar constitución