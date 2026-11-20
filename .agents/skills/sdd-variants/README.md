# sdd-variants

Skill para generar múltiples variantes de implementación, evaluarlas y producir una shortlist ranqueada.

## Qué hace

- Genera N variantes de implementación (recomendado: 3)
- Implementa cada variante en aislamiento (rama/worktree)
- Evalúa contra RF Coverage, Constitución, Simplicity, Tests
- Produce `variants-ranking.md` con shortlist ranqueada

## Uso

```
/sdd-variants
```

## Output

- `specs/001-xxx/variants-ranking.md` - Rankings de variantes

## Ver también

- `/sdd-validate` - Validación post-implementación
- `/sdd-implement` - Implementación TDD