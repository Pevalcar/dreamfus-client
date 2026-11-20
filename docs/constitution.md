# Constitution SDD — DreamFus Client v1.0

**Proyecto:** [dreamfus-client](https://github.com/Pevalcar/dreamfus-client)  
**Sincronizado con AGENTS.md:** ✅  
**Creado:** $(date)  
**Versión:** 1.0

---

## P-001 — Stack Estricto

Solo Godot 4.8 + GDScript pura. Cualquier dependencia externa (npm, Node, C++) requiere aprobación explícita del usuario.

**Verificación:**
```bash
# Chequear package.json no autorizadas
grep -E "(dependencies|devDependencies)" package.json | grep -v "godot\|mcp\|codebase-memory" && echo "APPROVAL REQUIRED"
```

---

## P-002 — Testing Obligatorio con GUT

Unit tests para lógica de negocio; integration tests para flow crítico (login → TCP); coverage ≥ 80%.

**Framework:** [GUT](https://gut.readthedocs.io/en/latest/Creating-Tests.html)

**Verificación:**
```bash
# Run GUT y verificar coverage
godot --headless --path . --run-gut-tests
# Coverage report debe mostrar lines >= 80%
```

---

## P-003 — Límites Arquitectónicos

- Máximo **500 líneas** por archivo `.gd`
- Un **SceneManager** por escena
- **Networking y UI desacoplados** obligatoriamente

**Verificación:**
```bash
# Detectar archivos > 500 líneas
find . -name "*.gd" -exec wc -l {} \; | awk '$1 > 500 {print "VIOLATION:", $0}'
```

---

## P-004 — Calidad de Código

- **Cero warnings** GDScript lint
- Naming: **PascalCase** para clases, **camelCase** para métodos/vars
- **Tipos explícitos** obligatorios

**Verificación:**
```bash
gdlint src/ --exit-with-zero-on-warning
```

---

## P-005 — Seguridad y Credenciales

- **Prohibido** hardcodear tokens/credentials en código
- Usar **variables de entorno** o archivos `.env`
- **Validación estricta** de inputs de red (nunca confiar ciegamente en datos del servidor)

**Verificación:**
```bash
# Detectar credenciales hardcodeadas en src/
grep -rnE "(password|token|secret|credential)" --include="*.gd" src/
# Resultado esperado: 0 matches
```

---

## P-006 — Convenciones de Desarrollo

- **Conventional Commits:** `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`, `style:`, `ci:`
- Código y documentación en **español**
- **Pull Requests requeridos** para cambios en `feature/*` → `main`

**Verificación:**
```bash
# Chequear formato de commits
git log --format='%s' | grep -vE '^(feat|fix|refactor|chore|docs|test|style|ci): [a-z].*[\.]?$'
```

---

## Tabla de Principios

| ID | Principio | Verificación |
|----|-----------|--------------|
| P-001 | Stack estricto Godot 4.8 + GDScript | A — grep package.json |
| P-002 | Testing GUT con coverage ≥ 80% | B — gut command line report |
| P-003 | Límite 500 líneas/archivo | A — find + wc |
| P-004 | Cero warnings lint | A — gdlint |
| P-005 | Sin hardcoded credentials | A — grep en src/ |
| P-006 | Conventional Commits | C — revisión manual PRs |

---

## Gates de SDD

Los siguientes flujos están **bloqueados** hasta aprobar su fase:

```
sdd-setup → sdd-constitution → sdd-backlog → sdd-story → sdd-spec → sdd-clarify → sdd-plan → sdd-tasks → sdd-implement → sdd-validate
```

- **sdd-plan** requiere `clarification.status = PASS`
- **sdd-spec** requiere `backlog.status = approved`
- **sdd-implement** requiere `tasks.md` y `plan.md` completados

---

## Modo por Defecto

Por defecto, **human-gated**: cada fase requiere aprobación explícita del usuario.  
Para ejecución automática sin pausas, ejecuta: **`/build auto`**