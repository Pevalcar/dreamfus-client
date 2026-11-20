---
name: sdd-validate
description: "Auditoría forense final RF→Test→Código, cumplimiento constitucional (P-001…P-0NN), detección de Scope Drift y Test Integrity Check. Veredicto binario fail-closed: APPROVED o REJECTED."
version: 1.0.0
disable-model-invocation: true
---

## Contexto compartido
- **Consume:** `approved_phases` incluye `implement`, `spec`, `plan`, `active_spec_dir`
- **Produce:** `validation-report.md`, actualiza `approved_phases` con `validate`, `cycle_status = SHIPPED` o `REJECTED`
- **Desbloquea:** ningún skill (cierre del ciclo)

# Validador SDD — Auditoría Forense & Gate de Cierre (Fail-Closed)

Verifica mediante evidencia empírica ejecutada que la implementación cumple al 100% con `specs/NNN-<slug>/spec.md`, `specs/NNN-<slug>/plan.md` y `docs/constitution.md` antes de dar una funcionalidad por terminada (`SHIPPED`).

## 🛡️ ASSUMPTIONS & HARD RULES

1. **Pre-condiciones estrictas:** Existen `AGENTS.md`, `docs/constitution.md`, `specs/NNN-<slug>/spec.md`, `specs/NNN-<slug>/plan.md`, `specs/NNN-<slug>/tasks.md` (con todas las tareas `[x]`) y `.sdd-state.json` con `"implement"` en `approved_phases`.
2. **Fail-Closed Binario:** El veredicto solo puede ser **`APPROVED`** o **`REJECTED`**. No existen estados intermedios (_"parcial"_, _"incompleta pero aceptable"_). Si falla un solo `RF`, un test o un principio constitucional, el veredicto es **`REJECTED`**.
3. **Evidence-Before-Completion:** Prohibido afirmar que _"los tests pasan"_ o _"el linter está limpio"_ sin ejecutar los comandos en vivo y registrar su salida real y exit code `0` en `validate-report.md`.
4. **Cero Edición de Código Aquí:** `sdd-validate` es una skill exclusivamente de auditoría y verificación. Si encuentra fallos, rechaza y devuelve el control a `/sdd-implement` (o `/sdd-clarify`).
5. **Human-Gate por defecto:** En modo `human-gated`, no se marca el ciclo como `SHIPPED` en `.sdd-state.json` sin confirmación humana explícita tras revisar `specs/NNN-<slug>/validate-report.md`.

## When to Use

- Todas las tareas de `specs/NNN-<slug>/tasks.md` (incluida `T-FINAL`) están marcadas `[x]`.
- Antes de hacer merge a la rama principal o declarar una feature como entregada.

## When NOT to Use

- Aún quedan tareas pendientes (`[ ]`) en `specs/NNN-<slug>/tasks.md` (ejecutar `/sdd-implement` primero).
- No existe `spec.md`, `plan.md` o `docs/constitution.md`.

## Proceso de Ejecución

### Fase 0: Pre-flight Check y Carga de Verdad (Obligatorio — Fail-Closed)

1. **Verificar estado SDD en `.sdd-state.json`:**
   - Lee `.sdd-state.json` y obtén `active_spec_dir` (`specs/NNN-<slug>`) y `execution_mode`.
   - Verifica que `"constitution"`, `"spec"`, `"clarify"`, `"plan"`, `"tasks"` e `"implement"` estén en `approved_phases`.
   - **Si falta alguno:** DETÉN la ejecución y muestra:
     > ⛔ **Bloqueo Pre-flight:** La implementación no ha finalizado todas las fases previas en `.sdd-state.json`. Completa `/sdd-implement` antes de validar.

2. **Verificar completitud de `specs/NNN-<slug>/tasks.md`:**
   - Revisa que **el 100% de las tareas** (`T1`…`T-FINAL`) tengan `[x]`. Si hay al menos un `[ ]`, detente y devuelve al usuario a `/sdd-implement`.

3. **Cargar fuentes de verdad:**
   - `specs/NNN-<slug>/spec.md` (todos los `RF-1`…`RF-N`, `RNF`, Contratos de frontera, Matriz de estados, Casos límite y `Fuera de alcance`).
   - `specs/NNN-<slug>/plan.md` (_File Impact Map_, Modelo de datos y Matriz de cobertura).
   - `docs/constitution.md` (todos los principios `P-001`…`P-0NN` y sus comandos literales en `Verificación:`).
   - `./AGENTS.md` (comandos globales de test, build, type-check y linter).

### Fase 1: Auditoría Forense en 5 Capas

Ejecuta estas 5 auditorías en orden y recopila evidencia verificable:

#### Capa 1: Trazabilidad Completa (`RF-1`…`RF-N` → Test → Código)

- Para cada `RF` de `spec.md`, localiza:
  1. El archivo y función/método exacto en producción (`ruta/archivo:línea`).
  2. El archivo y caso de prueba exacto en `tests/` (`ruta/test::nombre_test`).
- Si un `RF` carece de código o de test automatizado → **Fallo inmediato (`❌`)**.

#### Capa 2: Test Integrity Check (Anti-Fake Tests)

- Inspecciona el código fuente de los tests asociados a la feature para confirmar que:
  1. Contienen aserciones reales (`assert`, `expect`, etc.) sobre comportamiento observable y no son tests vacíos.
  2. No contienen marcadores de omisión (`.skip`, `xit`, `@Ignore`, `pytest.mark.skip`).
  3. No mockean la propia lógica de negocio que dicen estar verificando.

#### Capa 3: Ejecución Empírica (Suite de Tests + Constitución `P-001`…`P-0NN`)

- Ejecuta la **suite completa de tests del proyecto** (sin filtros que oculten regresiones), el build/type-check y el linter definidos en `AGENTS.md`.
- Ejecuta uno por uno los comandos literales de `Verificación:` de cada principio `P-001`…`P-0NN` en `docs/constitution.md`.
- Captura el **exit code** y el resumen numérico real de salida de cada comando.

#### Capa 4: Scope Drift Audit (`Git Diff` vs `File Impact Map` y `Out of Scope`)

- Ejecuta `git status --short` y revisa los commits/archivos modificados de la feature contra la tabla **File Impact Map** de `specs/NNN-<slug>/plan.md`.
- Verifica que **ningún archivo prohibido** haya sido alterado y que no se haya implementado funcionalidad listada en **Fuera de alcance** de `spec.md`.

#### Capa 5: Cobertura de Estados, Casos Límite y Definition of Done

- Verifica que todas las transiciones prohibidas de la **Matriz de Estados**, los **Invariantes de Dominio** y los **Casos Límite** de `spec.md` estén cubiertos por código y tests.
- Verifica ausencia de credenciales/secretos hardcodeados, logs de depuración (`console.log`, `print` temporales) y código muerto.

### Fase 2: Veredicto Binario y Gate de Aprobación Humana

Redacta `specs/NNN-<slug>/validate-report.md` **en memoria** usando `template-validate.md` y determina el veredicto:

#### Caso A: Veredicto `REJECTED` (Cualquier fallo en Capas 1 a 5)

1. Guarda el reporte de rechazo en `specs/NNN-<slug>/validate-report.md` para dejar evidencia de auditoría.
2. Actualiza `.sdd-state.json` manteniendo `"gate_status": "rejected"` y señalando la fase de retorno (`sdd-implement` o `sdd-clarify`).
3. **Detén el flujo** (incluso en `/build auto`) y muestra:

## ❌ Veredicto Final: REJECTED — Feature No Aprobada

**Causas de rechazo detectadas:**

- <Detalle Drift P-00X RF Scope del exacto fallido, faltante, o test violación>

**Acción requerida:**

- Regresar a **`/sdd-implement`** (o **`/sdd-clarify`** si hay vacío en la spec) para corregir los puntos listados y volver a ejecutar `/sdd-validate`.

#### Caso B: Veredicto `APPROVED` (100% de Capas 1 a 5 en verde)

Presenta el reporte completo con la evidencia empírica y solicita confirmación humana (en modo `human-gated`):

## 🔒 Gate de Cierre Final — Veredicto: APPROVED ✅

**Resumen de auditoría forense (`specs/NNN-<slug>`):**

- Archivo de reporte: `specs/NNN-<slug>/validate-report.md`
- Trazabilidad `RF → Test → Código`: X/X (100% cubierta) ✅
- Test Integrity Check: ✅ Sin tests vacíos ni `.skip`
- Cumplimiento Constitucional (`P-001`…`P-0NN`): ✅ Todos los comandos con exit code 0
- Scope Drift Audit: ✅ Sin archivos fuera del _File Impact Map_

¿Apruebas el cierre oficial de esta especificación (`SHIPPED`)?

- [ ] **Sí, aprobar y cerrar ciclo** → Guardar `specs/NNN-<slug>/validate-report.md` y marcar la feature como `SHIPPED` en `.sdd-state.json`.
- [ ] **No, solicitar ajustes** → Mantener abierta la fase para revisión adicional.

## 🔒 Reglas de Bloqueo y Gobernanza

1. **Veredicto innegociable:** Está estrictamente prohibido emitir `APPROVED` si existe al menos un `RF` sin test/código, un warning de linter no permitido, o una violación a `docs/constitution.md`.
2. **Comportamiento en `/build auto`:**

- Si todas las auditorías dan **`APPROVED`**, `/build auto` guarda `specs/NNN-<slug>/validate-report.md`, actualiza `.sdd-state.json` a `"SHIPPED"` y finaliza el pipeline con éxito.
- Si cualquier auditoría da **`REJECTED`**, `/build auto` **aborta inmediatamente** y devuelve el control al humano con el detalle exacto de los fallos.

## What Happens After Approval (`APPROVED`)

Cuando el veredicto es `APPROVED` y el usuario confirma (o `/build auto` valida):

1. Se escribe `specs/NNN-<slug>/validate-report.md`.
2. Se actualiza `.sdd-state.json`:

```json
{
  "constitution_version": "1.0.0",
  "agents_md_checked": true,
  "execution_mode": "human-gated",
  "current_phase": "validate",
  "active_spec_dir": "specs/NNN-<slug>",
  "clarification": { "status": "PASS" },
  "approved_phases": [
    "constitution",
    "backlog",
    "spec",
    "clarify",
    "plan",
    "tasks",
    "implement",
    "validate"
  ],
  "next_allowed_phase": "none",
  "gate_status": "approved",
  "cycle_status": "SHIPPED"
}
```

3. Se confirma el cierre del ciclo SDD y se indica que el repositorio está listo para iniciar una nueva funcionalidad (`/sdd-backlog` o `/sdd-spec`).

### 2. Archivo `template-validate.md`

# Reporte de Validación Forense SDD — NNN-<slug>

- **Spec auditada:** `specs/NNN-<slug>/spec.md`
- **Plan técnico:** `specs/NNN-<slug>/plan.md`
- **Tareas:** `specs/NNN-<slug>/tasks.md`
- **Constitución:** `docs/constitution.md`
- **Veredicto Final:** `[APPROVED | REJECTED]`

---

## 1. Matriz de Trazabilidad Forense (`RF → Test → Código`)

| RF (`spec.md`) | Test Automatizado (`archivo::test`) | Implementación (`archivo:línea`) | Test Integrity       | Estado  |
| -------------- | ----------------------------------- | -------------------------------- | -------------------- | ------- |
| `RF-1`         | `tests/<ruta>::<test_rf_1>`         | `src/<ruta>:<línea>`             | ✅ Aserciones reales | ✅ PASA |
| `RF-2`         | `tests/<ruta>::<test_rf_2>`         | `src/<ruta>:<línea>`             | ✅ Aserciones reales | ✅ PASA |

---

## 2. Cumplimiento Constitucional (`docs/constitution.md`)

| Principio | Regla verificada        | Comando ejecutado        | Exit Code | Estado    |
| --------- | ----------------------- | ------------------------ | --------- | --------- |
| `P-001`   | <Resumen del principio> | `<comando_verificacion>` | `0`       | ✅ CUMPLE |
| `P-002`   | <Resumen del principio> | `<comando_verificacion>` | `0`       | ✅ CUMPLE |

---

## 3. Evidencia Empírica de Ejecución (Logs Reales)

```text
# Suite completa de tests
$ <comando_tests_completo>
<pegar resumen real: ej. 24 passed, 0 failed in 1.42s (exit code 0)>

# Build / Type-check / Linter
$ <comando_lint_y_build>
<pegar resumen real: ej. 0 errors, 0 warnings (exit code 0)>

```

## 4. Auditoría de Alcance (`Scope Drift` vs `plan.md`)

- **Archivos creados/modificados coincidentes con _File Impact Map_:** `X/X` ✅
- **Archivos tocados fuera de alcance:** `Ninguno` (o lista exacta si hubo desviación)
- **Invasión de `Fuera de alcance` (`spec.md`):** `Ninguna` ✅

## 5. Checklist de Calidad y Definition of Done

- [ ] **Cobertura de RF:** 100% de `RF-1`…`RF-N` implementados y con test en verde
- [ ] **Test Integrity:** Cero tests vacíos, sin `.skip` ni mocks sobre la unidad bajo prueba
- [ ] **Estados e Invariantes:** Todas las transiciones prohibidas y casos límite de `spec.md` verificados
- [ ] **Regresiones:** Suite completa del repositorio pasa al 100%
- [ ] **Higiene de código:** Sin secretos hardcodeados, sin logs de depuración ni código muerto
- [ ] **Constitución:** 100% de principios `P-001`…`P-0NN` verificados con exit code `0`

## 6. Veredicto Oficial (Fail-Closed)

- [ ] **✅ APPROVED (Spec cumplida y lista para entrega)**
- [ ] **❌ REJECTED (Bloqueada — requiere correcciones antes de cerrar)**

**Justificación técnica:** <Explicación objetiva respaldada por la evidencia de las secciones 1 a 5.>
