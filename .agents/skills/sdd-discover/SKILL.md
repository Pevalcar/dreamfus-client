---
name: sdd-discover
description: "Meta-skill que analiza el proyecto y rutea al skill apropiado según el dominio detectado y estado del flujo SDD."
version: 1.0.0
disable-model-invocation: true
---

## Contexto compartido
- **Consume:** `.sdd-state.json` (estado actual del flujo), detección de perfil tecnológico
- **Produce:** recomienda la siguiente skill válida, `current_phase`, `next_allowed_phase`
- **Desbloquea:** la siguiente skill del flujo según el estado actual

# Descubridor SDD — Enrutamiento cognitivo

Analiza el estado del proyecto, determina en qué fase del flujo SDD estás, y recomienda (o bloquea) la siguiente skill. **No ejecuta ninguna fase**: solo enruta y protege los gates.

## 🛡️ ASSUMPTIONS I'M MAKING:

1. El directorio de trabajo actual (`pwd`) es la raíz del proyecto.
2. El estado del flujo se persiste en `.sdd-state.json` (si existe).
3. Si `.sdd-state.json` no existe, se infiere el estado escaneando el filesystem.
4. El usuario puede pedir una skill concreta; si rompe el orden del flujo, el router la rechaza y redirige.
5. El router **no ejecuta** skills: solo recomienda o bloquea

→ Correct me now or I'll proceed.

## Lifecycle Sequence (SDD Flow)

For a complete SDD workflow, the typical skill sequence is:

```
1.  sdd-setup/sdd-constitution  → Create AGENTS.md and constitution
2.  sdd-backlog                 → Turn idea into user story backlog
3.  sdd-story                   → Refine one story with acceptance criteria
4.  sdd-spec                    → Define what we're building (RF-EARS)
5.  sdd-clarify                 → Review and refine spec (loop until clear)
6.  sdd-plan                    → Design technical implementation
7.  (optional) sdd-review      → Review assumptions and alternatives
8.  sdd-tasks                   → Break into verifiable tasks
9.  (optional) sdd-pair        → Pair programming TDD step by step
10. sdd-implement               → Build slice by slice (TDD)
11. sdd-validate                → Verify RF→Test coverage, DoD
12. (optional) sdd-variants     → Multi-variant exploration and ranking
```

Not every task needs every skill. A bug fix might only need:
`debugging-and-error-recovery` → `test-driven-development` → `code-review-and-quality`

### Your SDD Flow

```
discover → constitution → backlog → story → spec → clarify → plan → review → tasks → pair → implement → validate → variants
    ↓           ↓         ↓       ↓     ↓      ↓        ↓        ↓        ↓        ↓          ↓          ↓            ↓
[setup    [principios [backlog [story [RF-EARS [QA      [arquitectura [suposiciones [TDD       [pair      [TDD       [RF→Test
 detected]   inneg.]   historias[refinar] mapping] loop]    decisions]     review]     [tareas]   [implement] enforced]   coverage]
           ↓          ↓         ↓       ↓     ↓      ↓        ↓        ↓        ↓        ↓          ↓          ↓            ↓
        [human   [human   [human  [human [human   [human   [human   [human   [human   [human    [human      [human      [human
         approval] approval] approval] approval] approval] approval] approval] approval] approval] approval] approval] approval] approval]
```

## Skill Router Table

| Fase | When to Use | Skill to Invoke |
|------|-------------|-----------------|
| **Setup** | No AGENTS.md o constitution | `/sdd-setup` |
| **Constitution** | No constitution approved | `/sdd-constitution` |
| **Define** | Have a rough concept | `/sdd-backlog` |
| **Define** | Need to refine a story | `/sdd-story` |
| **Define** | Need specs | `sdd-spec` |
| **Define** | Need to clarify spec | `sdd-clarify` |
| **Plan** | Have a spec, need plan | `sdd-plan` |
| **Review** | Need to review assumptions | `sdd-review` |
| **Build** | Need tasks from plan | `sdd-tasks` |
| **Build** | Pair programming TDD | `sdd-pair` |
| **Build** | Need to implement | `incremental-implementation` |
| **Verify** | Implement complete | `sdd-validate` |
| **Review** | Explore alternatives | `sdd-variants` |

## Output Inicial

Muestra al usuario el estado actual del proyecto:

```
🔍 Estado del proyecto:
   AGENTS.md: ✅ existe
   docs/constitution.md: ✅ existe
   specs/: ✅ specs encontradas
   tests/: ❌ sin tests aún
   .sdd-state.json: ✅ existe
   clarification.status: [pending|PASS|FAIL]
   backlog.status: [pending|approved]
   pair.status: [idle|in_progress|completed]

📋 Skills disponibles:
   - /sdd-backlog → Crear backlog de historias de usuario
   - /sdd-story → Refinar una historia con acceptance criteria
   - /sdd-spec → Crear especificación
   - /sdd-clarify → Revisar espec (bloquea sdd-plan si FAIL)
   - /sdd-plan → Crear plan técnico (requiere clarification.status = PASS)
   - /sdd-pair → Pair programming TDD paso a paso
   - /sdd-review → Revisar suposiciones (opcional)
   - /sdd-tasks → Generar tareas
   - /sdd-implement → Implementar (TDD)
   - /sdd-validate → Validar implementación

💡 Skill recomendado: /sdd-backlog
   Razón: Tienes constitution pero sin backlog de historias aún.

🚫 Gates activos:
   - Si clarification.status = FAIL o pending: sdd-plan está BLOQUEADO.
   - Ejecutar /sdd-clarify primero y obtener PASS antes de continuar.
   - Si backlog.status = pending: sdd-spec está BLOQUEADO.
   - Ejecutar /sdd-backlog primero y obtener aprobación antes de continuar.
```

## Quick Reference

| Phase | Skill | One-Line Summary |
|-------|-------|-----------------|
| **Setup** | sdd-setup | Create AGENTS.md and constitution |
| **Constitution** | sdd-constitution | Define innegociable principles |
| **Define** | sdd-backlog | Turn idea into user story backlog |
| **Define** | sdd-story | Refine one story with acceptance criteria |
| **Define** | sdd-spec | Generate spec with RF-EARS |
| **Define** | sdd-clarify | Review and refine spec |
| **Plan** | sdd-plan | Design technical implementation |
| **Review** | sdd-review | Review assumptions and alternatives |
| **Build** | sdd-tasks | Break into verifiable tasks |
| **Build** | sdd-pair | Pair programming TDD step by step |
| **Build** | sdd-implement | Implement with TDD |
| **Verify** | sdd-validate | Verify RF→Test coverage |
| **Review** | sdd-variants | Multi-variant exploration |
| **Context** | source-driven-development | Verify against official docs |
| **Context** | incremental-implementation | Build slice by slice |
| **Context** | doubt-driven-development | Cross-examine decisions |
| **Context** | test-driven-development | Prove each slice works |
| **Review** | code-review-and-quality | Review before merge |
| **Remove** | code-simplification | Reduce unnecessary complexity |
| **Ship** | git-workflow-and-versioning | Clean commit history |
| **Ship** | ci-cd-and-automation | Automated quality gates |
| **Ship** | documentation-and-adrs | Document decisions |
| **Ship** | observability-and-instrumentation | Add logs/metrics |
| **Ship** | shipping-and-launch | Deploy safely |

## Verificación de Gates

Antes de recomendar cualquier skill, el router verifica `.sdd-state.json`:

| Gate | Condición | Acción si no se cumple |
|------|-----------|----------------------|
| Constitution | `docs/constitution.md` existe y aprobada | Redirigir a `/sdd-constitution` |
| Backlog | `backlog.status = approved` | Redirigir a `/sdd-backlog` |
| Story | Historia seleccionada y refinada | Redirigir a `/sdd-story` |
| Spec | `specs/NNN-xxx/spec.md` existe | Redirigir a `/sdd-spec` |
| Clarify | `clarification.status = PASS` | Redirigir a `/sdd-clarify` |
| Plan | `specs/NNN-xxx/plan.md` existe | Redirigir a `/sdd-plan` |
| Tasks | `specs/NNN-xxx/tasks.md` existe | Redirigir a `/sdd-tasks` |

Si `clarification.status` es `FAIL` o `pending`, **sdd-plan está bloqueado**. El usuario debe ejecutar `/sdd-clarify` hasta obtener PASS antes de continuar.

Si `backlog.status` es `pending`, **sdd-spec está bloqueado**. El usuario debe ejecutar `/sdd-backlog` primero y obtener aprobación antes de continuar.

## See Also

- `/sdd-flow` - Complete SDD wizard
- `spec-driven-development` - Full spec pattern from reference
- `incremental-implementation` - Incremental build cycle
- `test-driven-development` - Testing patterns
- `definition-of-done.md` - Universal quality bar