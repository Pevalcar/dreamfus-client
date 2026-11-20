---
name: sdd-implement
description: "Implementa tareas atómicas de specs/NNN-<slug>/tasks.md siguiendo TDD estricto (RED → GREEN → REFACTOR → VERIFY → COMMIT), auditoría de blast radius y control de gates en .sdd-state.json."
version: 1.0.0
disable-model-invocation: true
---

## Contexto compartido
- **Consume:** `approved_phases` incluye `tasks`, `active_spec_dir`, tarea específica `Tn` con `RF cubiertos`
- **Produce:** código + tests, marca `[x] Tn` en `tasks.md`, actualiza `.sdd-state.json` al completar `T-FINAL`
- **Desbloquea:** `/sdd-validate`

# Implementador SDD — TDD Estrícto & Ejecución Incremental

Ejecuta las tareas aprobadas en `specs/NNN-<slug>/tasks.md` una a la vez mediante desarrollo guiado por pruebas (**RED → GREEN → REFACTOR**), respetando el alcance de archivos (`≤ 3 archivos/tarea`) y los principios innegociables de `docs/constitution.md`.

## 🛡️ ASSUMPTIONS & HARD RULES

1. **Pre-condiciones estrictas:** Existen `AGENTS.md`, `docs/constitution.md`, `specs/NNN-<slug>/spec.md`, `specs/NNN-<slug>/plan.md`, `specs/NNN-<slug>/tasks.md` y `.sdd-state.json` con `"tasks"` en `approved_phases`.
2. **TDD No Negociable (RED primero):** Prohibido escribir código de producción antes de escribir el test que cubre el `RF` de la tarea y verificar que falla (`RED`).
3. **Aislamiento de Blast Radius:** Solo se permite crear o modificar los archivos declarados explícitamente en `Archivos objetivo (≤ 3)` de la tarea actual `Tn`.
4. **Prohibición de "Verification by Claim":** Ninguna tarea puede marcarse `[x]` sin ejecutar el comando real de pruebas/linter y mostrar su salida con exit code `0`.
5. **Circuit Breaker (3 intentos):** Si tras **3 intentos** consecutivos `Tn` no logra pasar a `GREEN` o falla el linter/compilación, **detén la ejecución inmediatamente** (incluso en `/build auto`) y escala al humano.
6. **Control de avance (`human-gated` vs `/build auto`):** En modo `human-gated`, **detente al finalizar `Tn`** y pide confirmación humana antes de continuar con `T(n+1)`.

## When to Use

- `specs/NNN-<slug>/tasks.md` está aprobado en `.sdd-state.json` y existen tareas pendientes (`[ ]`).
- Se requiere implementar una tarea atómica `Tn` (o ejecutar el pipeline continuo si se activó `/build auto`).

## When NOT to Use

- `tasks.md` no existe o `"tasks"` no figura en `approved_phases` de `.sdd-state.json` (ejecutar `/sdd-tasks` primero).
- Las dependencias (`Depends on`) de la tarea `Tn` aún no están marcadas `[x]`.
- Se pretende implementar código fuera del plan aprobado o modificar múltiples tareas en un solo bloque sin pruebas intermedias.

## El Ciclo Incremental (RED → GREEN → REFACTOR → VERIFY → COMMIT)

```

┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  1. RED (Test falla) ──→ 2. GREEN (Código mínimo pasa) ──┐  │
│         ▲                                                │  │
│         │                                                ▼  │
│  5. COMMIT & GATE ◄── 4. VERIFY (Evidencia + Lint) ◄── 3. REFACTOR
│                                                             │
└─────────────────────────────────────────────────────────────┘

```

## Reglas de Disciplina de Código

### Rule 0: Simplicity First

Antes y después de escribir código, verifica:

- ¿Es esta la implementación más simple que satisface el test y los `RF` de `Tn`?
- ¿Estoy construyendo abstracciones especulativas no pedidas en `plan.md`? (Prohibido: _YAGNI_).

### Rule 0.5: Scope Discipline (Anti-Deriva)

Toca **únicamente** los archivos listados en `Archivos objetivo (≤ 3)` de `Tn`.

- **Prohibido:** Limpiar código adyacente no relacionado, refactorizar imports de otros módulos, alterar tests previos para forzar verde o añadir features fuera de `spec.md`.
- Si detectas deuda técnica fuera de alcance, repórtala sin tocar el archivo:

  ```text
  NOTICED BUT NOT TOUCHING:
  - <ruta_archivo>: <observación puntual>

  ```

---

## Proceso de Ejecución

### Fase 0: Pre-flight Check y Selección de Tarea (Obligatorio — Fail-Closed)

1. **Verificar estado SDD en `.sdd-state.json`:**

- Lee `.sdd-state.json` y obtén `active_spec_dir` (`specs/NNN-<slug>`) y `execution_mode` (`"human-gated"` o `"auto"`).
- Verifica que `"constitution"`, `"spec"`, `"clarify"`, `"plan"` y `"tasks"` estén en `approved_phases`.
- **Si falta alguno:** DETÉN la ejecución y muestra:
  > ⛔ **Bloqueo Pre-flight:** El plan de tareas no está aprobado en `.sdd-state.json`. Ejecuta `/sdd-tasks` primero.

2. **Cargar fuentes de verdad:**

- `specs/NNN-<slug>/tasks.md` (selecciona la primera tarea `[ ]` pendiente en orden topológico, o la `Tn` indicada por el usuario).
- `specs/NNN-<slug>/plan.md` (arquitectura, contratos de interfaz y modelo de datos).
- `specs/NNN-<slug>/spec.md` (criterios EARS de los `RF` asociados a `Tn`).
- `docs/constitution.md` (principios `P-001`…`P-0NN` y comandos de `Verificación:`).
- `./AGENTS.md` (comandos exactos de build, test y linter del proyecto).

3. **Validar dependencias y Working Tree:**

- Verifica que todas las tareas listadas en `Depends on:` de `Tn` tengan `[x]` en `tasks.md`. Si alguna no está completa, **bloquéate** y exige completar la dependencia primero.
- Ejecuta `git status --short` para asegurar que no haya cambios sucios sin commitear de tareas previas.

---

### Fase 1: Ejecución del Ciclo TDD sobre `Tn`

_(Si `Tn` es **`T-FINAL` (Checkpoint Constitucional)**, salta los pasos 1-3 de código y ejecuta directamente la auditoría global de todos los comandos `Verificación:` de `docs/constitution.md`)._

1. **Paso 1 — RED (Escribir prueba que falla):**

- Crea o actualiza **únicamente** el archivo de test indicado en `Tn` cubriendo los `RF` asignados y casos borde.
- Ejecuta el comando de test de `Tn` y verifica que **falla por la razón esperada** (funcionalidad aún no implementada).

2. **Paso 2 — GREEN (Implementación mínima):**

- Escribe el código mínimo necesario en los archivos de producción autorizados en `Tn` siguiendo el diseño de `plan.md`.
- Ejecuta el comando de test de `Tn` hasta obtener exit code `0` (`PASS`).
- _(Circuit Breaker: Si tras **3 intentos** de corrección el test sigue fallando o rompe compilación, DETÉN todo, reporta el error exacto y pide intervención humana)._

3. **Paso 3 — REFACTOR (Limpieza controlada):**

- Mejora legibilidad y elimina duplicación dentro de los archivos permitidos de `Tn` sin cambiar comportamiento.
- Re-ejecuta los tests para confirmar que siguen en `GREEN`.

4. **Paso 4 — VERIFY (Auditoría de Blast Radius + Evidencia Real):**

- Ejecuta `git status --short` y verifica que **solo** se crearon/modificaron los archivos autorizados en `Archivos objetivo (≤ 3)` de `Tn`.
- Ejecuta la suite relevante de tests, type-check y linter del proyecto (según `AGENTS.md`) con **cero warnings**.
- Conserva el output real para incluirlo en el reporte de cierre de la tarea.

5. **Paso 5 — COMMIT & ACTUALIZACIÓN DE `tasks.md`:**

- Marca `- [x] **Tn:** ...` en `specs/NNN-<slug>/tasks.md`.
- Realiza un commit atómico descriptivo incluyendo la referencia al requisito (ej. `feat(spec-NNN): implement Tn - <descripción> [RF-1]`).

---

### Fase 2: Gate de Continuidad (`human-gated` vs `/build auto`)

#### Caso A: Modo `human-gated` (Por defecto)

**DETÉN la ejecución inmediatamente** tras completar `Tn`. No inicies `T(n+1)`. Presenta el reporte de evidencia y solicita autorización:

## 🔒 Gate de Verificación Humana — Tarea `Tn` Completada

**Evidencia de ejecución:**

- **Tarea:** `Tn` — <Título>
- **RF cubiertos:** `RF-X`, `RF-Y`
- **Archivos tocados (Blast Radius):**
  - `src/<ruta>` (`CREATE`/`MODIFY`)
  - `tests/<ruta>` (`CREATE`/`MODIFY`)
- **Evidencia de Tests & Linter (Exit Code 0):**
  ```text
  <pegar resumen real del stdout de test y linter>
  ```

* **Commit registrado:** `<hash_corto> — <mensaje>`
* **Progreso:** X de Y tareas completadas en `specs/NNN-<slug>/tasks.md`.

**Siguiente tarea pendiente:** `T(n+1)` — <Título de la siguiente tarea>

¿Apruebas el resultado de `Tn` y autorizas continuar con `T(n+1)`?

- [ ] **Sí, continuar con `T(n+1)**` → Ejecutar siguiente tarea en modo TDD.
- [ ] **No, revisar/ajustar `Tn**` → Detener aquí para inspección o cambios.

#### Caso B: Modo `/build auto` (`"execution_mode": "auto"`)

- Si `Tn` pasó todas las verificaciones (`RED → GREEN → REFACTOR → VERIFY → COMMIT`) sin activar el _Circuit Breaker_ ni violar el _Blast Radius_, **continúa automáticamente** con `T(n+1)` hasta completar `T-FINAL`.
- Si ocurre cualquier fallo persistente (3 intentos) o desviación de alcance, **aborta el modo automático** y presenta el Gate de Intervención Humana.

---

## 🔒 Reglas de Bloqueo y Gobernanza

1. **Nunca avanzar con tests en rojo o linter con warnings:** Si el comando de verificación devuelve exit code distinto de `0`, `Tn` no puede marcarse `[x]` ni commitearse.
2. **Prohibido modificar `spec.md`, `plan.md` o `constitution.md` durante la implementación:** Si descubres que un requisito es imposible o ambiguo al programar, detente y vuelve a `/sdd-clarify` o `/sdd-plan`.
3. **Transición final hacia `/sdd-validate`:** Solo cuando la última tarea (**`T-FINAL`**) esté marcada `[x]`, se actualiza `.sdd-state.json` para desbloquear `/sdd-validate`.

---

## What Happens After All Tasks (`T-FINAL`) Are Completed

Cuando `T-FINAL` pasa todos los comandos de `Verificación:` de `docs/constitution.md`:

1. Se actualiza `.sdd-state.json`:

   ```json
   {
     "constitution_version": "1.0.0",
     "agents_md_checked": true,
     "execution_mode": "human-gated",
     "current_phase": "implement",
     "active_spec_dir": "specs/NNN-<slug>",
     "clarification": { "status": "PASS" },
     "approved_phases": [
       "constitution",
       "backlog",
       "spec",
       "clarify",
       "plan",
       "tasks",
       "implement"
     ],
     "next_allowed_phase": "sdd-validate",
     "gate_status": "approved"
   }
   ```

2. Se informa al usuario que todas las tareas están completadas y que debe ejecutar **`/sdd-validate`** para la auditoría final de cierre de ciclo.
