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
