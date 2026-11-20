---
name: sdd-tasks
description: "Descompone specs/NNN-<slug>/plan.md en tareas atómicas y verificables (specs/NNN-<slug>/tasks.md), ordenadas topológicamente con control de blast radius (≤3 archivos/tarea) y criterios TDD."
version: 1.0.0
disable-model-invocation: true
---

## Contexto compartido
- **Consume:** `approved_phases` incluye `plan`, `spec`, `active_spec_dir`
- **Produce:** `tasks.md`, actualiza `approved_phases` con `tasks`, `next_allowed_phase = sdd-implement`
- **Desbloquea:** `/sdd-implement T1`

# Generador de Tareas SDD — Atomicity & TDD Blueprint

Transforma un plan técnico aprobado (`specs/NNN-<slug>/plan.md`) en una lista ordenada de tareas atómicas (`specs/NNN-<slug>/tasks.md`) listas para ejecutarse de forma incremental en `/sdd-implement`, **sin escribir código de producción ni tests todavía**.

## 🛡️ ASSUMPTIONS & HARD RULES

1. **Pre-condiciones estrictas:** Existen `AGENTS.md`, `docs/constitution.md`, `specs/NNN-<slug>/spec.md`, `specs/NNN-<slug>/plan.md` y `.sdd-state.json` con `"plan"` en `approved_phases`.
2. **Control de Blast Radius (`≤ 3 archivos` por tarea):** Ninguna tarea puede crear o modificar más de **3 archivos** (incluyendo su archivo de test). Si una tarea supera ese límite, debe dividirse en tareas más pequeñas (`T1`, `T2`).
3. **Granularidad Atómica (`≤ 30 min`):** Cada tarea representa una unidad lógica indivisible que deja el repositorio compilando y con sus tests en verde.
4. **Cero tareas huérfanas y 100% cobertura:** Todo `RF-1`…`RF-N` de `spec.md` y todo archivo del _File Impact Map_ de `plan.md` debe estar asignado al menos a una tarea.
5. **Human-Gate por defecto:** No se escribe `specs/NNN-<slug>/tasks.md` ni se desbloquea `/sdd-implement` sin aprobación humana explícita, salvo en modo `/build auto`.

## When to Use

- Inmediatamente después de aprobar `specs/NNN-<slug>/plan.md`.
- Cuando necesitas dividir una feature compleja en incrementos seguros, ordenados por dependencia y verificables por comandos.

## When NOT to Use

- `specs/NNN-<slug>/plan.md` no existe o no está aprobado en `.sdd-state.json` (ejecutar `/sdd-plan` primero).
- Ya existe un `specs/NNN-<slug>/tasks.md` en progreso con tareas marcadas `[x]` (no sobrescribir sin confirmación explícita).
- Se intenta escribir código directamente dentro de esta skill (bloqueado).

## Proceso de Ejecución

### Fase 0: Pre-flight Check y Carga de Verdad (Obligatorio — Fail-Closed)

1. **Verificar estado y gates en `.sdd-state.json`:**
   - Lee `.sdd-state.json` y obtén `active_spec_dir` (formato `specs/NNN-<slug>`).
   - Verifica que `"constitution"`, `"spec"`, `"clarify"` y `"plan"` estén en `approved_phases`.
   - **Si falla alguna condición:** DETÉN la ejecución y muestra:
     > ⛔ **Bloqueo Pre-flight:** No se pueden generar tareas sin un plan técnico aprobado. Ejecuta `/sdd-plan` primero y verifica `.sdd-state.json`.

2. **Verificar existencia previa de `specs/NNN-<slug>/tasks.md`:**
   - Comprueba si ya existe `specs/NNN-<slug>/tasks.md`.
   - **Si SÍ existe:** Revisa si tiene tareas marcadas `[x]` (en progreso) o todas `[ ]` y detente preguntando:
     > ⚠️ **Lista de tareas existente detectada en `specs/NNN-<slug>/tasks.md`:** (X completadas de Y). ¿Deseas **reemplazarla desde cero** tras aprobación o **cancelar**?

3. **Leer fuentes de verdad:**
   - `specs/NNN-<slug>/plan.md` (Arquitectura, _File Impact Map_, Modelo de datos, Contratos de interfaz y Matriz de cobertura de RF).
   - `specs/NNN-<slug>/spec.md` (todos los `RF-1`…`RF-N` y casos límite).
   - `docs/constitution.md` (principios `P-001`…`P-0NN` y sus comandos exactos en el campo `Verificación:`).
   - `./AGENTS.md` (comandos exactos del proyecto para ejecutar tests, linters y compilación).

### Fase 1: Descomposición Topológica y Auditoría Silenciosa

Genera el borrador de `specs/NNN-<slug>/tasks.md` **en memoria** aplicando estas 4 reglas de ingeniería:

1. **Orden Topológico por Capas de Dependencia:**
   - **Bloque 1 — Dominio, Modelos e Invariantes Puros:** Entidades, validaciones y reglas de estado sin dependencias externas (`Unit tests`).
   - **Bloque 2 — Persistencia, Adaptadores e Integración:** Repositorios, clientes externos y cumplimiento de contratos de frontera (`Integration tests`).
   - **Bloque 3 — Interfaz Pública (API / CLI / UI) y Walking Skeleton:** Exposición de endpoints/comandos y flujo completo de extremo a extremo (`E2E / Contract tests`).
   - **Bloque 4 — Checkpoint Constitucional (`T-FINAL`):** Tarea obligatoria de cierre que ejecuta todos los comandos de `Verificación:` definidos en `docs/constitution.md` (linters, cobertura mínima, límites de dependencias).

2. **Ficha Determinista por Tarea (`T1`…`TN`):**
   Cada tarea debe especificar exactamente:
   - **ID y Título accionable** (verbo + componente, `≤ 30 min`).
   - **`RF cubiertos:`** IDs exactos de `spec.md` (o `Infra/Contrato` si es un bloque base requerido por un RF).
   - **`Depends on:`** `none` o IDs de tareas previas (`T1`, `T2`).
   - **`Archivos objetivo (máx. 3):`** Rutas exactas tomadas del _File Impact Map_ de `plan.md` + ruta del archivo de test.
   - **`Hecho cuando (TDD):`** Nombre de la prueba automatizada que debe pasar + **comando ejecutable exacto** (extraído de `AGENTS.md`) que devuelve exit code `0`.

3. **Auditoría Silenciosa de Cobertura y Blast Radius:**
   - Verifica que ninguna tarea supere los **3 archivos**. Si lo hace, divídela.
   - Verifica que no haya dependencias circulares (`T1` depende de `T2` y `T2` de `T1`).
   - Construye la **Matriz de Trazabilidad `RF → Tarea`** al final del documento para demostrar que el 100% de los `RF` y archivos de `plan.md` están cubiertos.

### Fase 2: Gate de Aprobación Humana

Presenta el borrador completo de `specs/NNN-<slug>/tasks.md` junto con el resumen de auditoría:

```markdown
## 🔒 Gate de Aprobación Humana (Plan de Tareas SDD)

**Resumen de auditoría de ejecución:**

- Archivo destino: `specs/NNN-<slug>/tasks.md`
- Total de tareas atómicas: X (`T1` a `TX` + Checkpoint Constitucional)
- Blast radius máximo por tarea: ≤ 3 archivos ✅
- Cobertura de requisitos (`RF-1`…`RF-N`): 100% mapeados ✅
- Cobertura de _File Impact Map_: 100% de archivos asignados ✅

¿Apruebas este plan de tareas para guardarlo en `specs/NNN-<slug>/tasks.md` y desbloquear `/sdd-implement`?

- [ ] **Sí** → Guardar `specs/NNN-<slug>/tasks.md`, actualizar `.sdd-state.json` y desbloquear `/sdd-implement`.
- [ ] **No** → Indicar qué tareas dividir, reordenar o ajustar (no se escribirá nada hasta nueva aprobación).
```

## 🔒 Reglas de Bloqueo y Gobernanza

1. **Cero escritura sin "Sí" explícito (modo `human-gated`):** En modo `human-gated`, no se crea `specs/NNN-<slug>/tasks.md` ni se actualiza `.sdd-state.json` hasta recibir aprobación humana explícita.
2. **Prohibido codificar aquí:** Esta skill nunca crea archivos de código fuente ni tests; su único entregable es `specs/NNN-<slug>/tasks.md`.
3. **Comportamiento en `/build auto`:** Si `.sdd-state.json` tiene `"execution_mode": "auto"`, la skill puede guardar `specs/NNN-<slug>/tasks.md` automáticamente **solo si** el 100% de los `RF` y archivos del _File Impact Map_ están cubiertos y ninguna tarea viola el límite de `≤ 3 archivos`. Si detecta un `RF` sin cobertura o un archivo fuera del plan, `/build auto` se detiene y pide revisión humana.

## What Happens After Approval

Cuando el usuario responde **"Sí"**:

1. Se escribe `specs/NNN-<slug>/tasks.md`.
2. Se actualiza `.sdd-state.json`:

```json
{
  "constitution_version": "1.0.0",
  "agents_md_checked": true,
  "execution_mode": "human-gated",
  "current_phase": "tasks",
  "active_spec_dir": "specs/NNN-<slug>",
  "clarification": { "status": "PASS" },
  "approved_phases": [
    "constitution",
    "backlog",
    "spec",
    "clarify",
    "plan",
    "tasks"
  ],
  "next_allowed_phase": "sdd-implement",
  "gate_status": "approved"
}
```

3. Se indica al usuario que puede iniciar la ejecución incremental con `/sdd-implement`.

### 2. Archivo `template-tasks.md`

# Tareas de Implementación — NNN-<slug>

- **Plan de referencia:** `specs/NNN-<slug>/plan.md`
- **Spec de referencia:** `specs/NNN-<slug>/spec.md`
- **Constitución:** `docs/constitution.md`

## Bloque 1: Dominio, Modelos e Invariantes

- [ ] **T1:** <Acción concreta sobre entidad/validación (≤30 min)>
  - **RF cubiertos:** `RF-1`, `RF-2`
  - **Depends on:** `none`
  - **Archivos objetivo (≤3):**
    - `CREATE` `src/<modulo>/<archivo_dominio>`
    - `CREATE` `tests/<modulo>/<archivo_dominio>.test`
  - **Hecho cuando (TDD):** `<test_invariantes_y_validaciones>` pasa ejecutando `<comando_test_unitario>` (exit code 0).

## Bloque 2: Persistencia, Adaptadores e Integración

- [ ] **T2:** <Acción concreta sobre repositorio/servicio (≤30 min)>
  - **RF cubiertos:** `RF-1`, `RF-3`
  - **Depends on:** `T1`
  - **Archivos objetivo (≤3):**
    - `CREATE` `src/<modulo>/<archivo_servicio>`
    - `CREATE` `tests/<modulo>/<archivo_servicio>.integration.test`
  - **Hecho cuando (TDD):** `<test_contrato_frontera>` pasa ejecutando `<comando_test_integracion>` (exit code 0).

## Bloque 3: Interfaz Pública y Walking Skeleton

- [ ] **T3:** <Exponer endpoint / comando CLI / controlador y flujo E2E (≤30 min)>
  - **RF cubiertos:** `RF-1`, `RF-2`, `RF-4`
  - **Depends on:** `T2`
  - **Archivos objetivo (≤3):**
    - `MODIFY` `src/<interfaz>/<archivo_ruta_o_cli>`
    - `CREATE` `tests/e2e/<flujo_completo>.e2e.test`
  - **Hecho cuando (TDD):** `<test_walking_skeleton_e2e>` pasa ejecutando `<comando_test_e2e>` (exit code 0).

## Bloque 4: Checkpoint Constitucional (Gate Obligatorio)

- [ ] **T-FINAL:** Auditoría de cumplimiento constitucional (`P-001`…`P-0NN`)
  - **RF cubiertos:** `Todos (RNF y principios constitucionales)`
  - **Depends on:** `T1`…`T3`
  - **Archivos objetivo:** `N/A (verificación global)`
  - **Hecho cuando:** Todos los comandos de `Verificación:` de `docs/constitution.md` (linter, cobertura mínima, límites arquitectónicos) devuelven exit code `0`.

## Matriz de Trazabilidad (Auditoría de Cobertura)

| Requisito (`spec.md`) | Tareas asignadas | Archivo(s) de implementación | Tipo de verificación       |
| --------------------- | ---------------- | ---------------------------- | -------------------------- |
| `RF-1`                | `T1`, `T2`, `T3` | `src/<modulo>/<archivo>`     | `Unit + Integration + E2E` |
| `RF-2`                | `T1`, `T3`       | `src/<modulo>/<archivo>`     | `Unit + E2E`               |
