# Tareas de Implementación — Spec 001 (Flujo de Login)

- **Plan de referencia:** `specs/001-login-flow/plan.md`
- **Spec de referencia:** `specs/001-login-flow/spec.md`
- **Constitución:** `docs/constitution.md`

---

## Bloque 1: Dominio, Modelos e Invariantes (Unit Tests)

- [x] **T1:** Implementar HttpClient con validación de credenciales (RF-1, RF-2, RF-10)
  - **RF cubiertos:** RF-1, RF-2, RF-10
  - **Depends on:** none
  - **Archivos objetivo (≤3):**
    - `CREATE` `godot-client/src/Core/HttpClient.gd`
    - `CREATE` `godot-client/test/HttpClientTest.gd`
  - **Hecho cuando (TDD):** Test de login HTTP exitoso y fallido pasa ejecutando `godot --headless --path godot-client --run-gut-tests` (exit code 0).
  - **Fecha de finalización:** 2026-11-20
  - **Blast radius verificado:** 2 archivos modificados ✅

- [x] **T2:** Implementar validación ticket kqz con regex `^[0-9a-f]{32}$` (RF-6.2, RNF-4)
  - **RF cubiertos:** RF-6.2, RNF-4
  - **Depends on:** T1
  - **Archivos objetivo (≤3):**
    - `MODIFY` `godot-client/src/Network/Proto.gd` (add ticket validation helper)
    - `CREATE` `godot-client/test/TicketValidationTest.gd`
  - **Hecho cuando (TDD):** Test de validación ticket con caracteres inválidos pasa ejecutando `godot --headless --path godot-client --run-gut-tests` (exit code 0).
  - **Fecha de finalización:** 2026-11-20
  - **Blast radius verificado:** 2 archivos modificados ✅
  - **Implementación:** `validate_ticket()` y `build_kqz_message()` agregados a Proto.gd

- [ ] **T3:** Implementar estructura de errores auth (RFC para RF-9)
  - **RF cubiertos:** RF-9
  - **Depends on:** T1
  - **Archivos objetivo (≤3):**
    - `CREATE` `godot-client/src/Data/AuthError.gd` (enum-based error types)
    - `CREATE` `godot-client/test/AuthErrorTest.gd`
  - **Hecho cuando (TDD):** Test de estructura AuthError con los 3 valores de error pasa ejecutando `godot --headless --path godot-client --run-gut-tests` (exit code 0).

---

## Bloque 2: Persistencia, Adaptadores e Integración

- [ ] **T4:** Implementar WebSocket client con auth_request (RF-3, RF-4)
  - **RF cubiertos:** RF-3, RF-4
  - **Depends on:** T1, T3
  - **Archivos objetivo (≤3):**
    - `MODIFY` `godot-client/src/Network/SimpleProtocolClient.gd` (validación token, estados)
    - `CREATE` `godot-client/test/WebSocketClientTest.gd`
  - **Hecho cuando (TDD):** Test de conexión WebSocket y envío auth_request pasa ejecutando `godot --headless --path godot-client --run-gut-tests` (exit code 0).

- [ ] **T5:** Implementar server_selection_response con schema de servidores (RF-5)
  - **RF cubiertos:** RF-5
  - **Depends on:** T4
  - **Archivos objetivo (≤3):**
    - `MODIFY` `godot-client/src/Network/SimpleProtocolClient.gd` (procesar servers array)
    - `CREATE` `godot-client/test/ServerSelectionTest.gd`
  - **Hecho cuando (TDD):** Test de deserialización servers con id, name, population, is_full pasa ejecutando `godot --headless --path godot-client --run-gut-tests` (exit code 0).

- [ ] **T6:** Implementar send_ticket() con GameMessage directo para kqz (RF-6, RF-6.1, RF-6.3)
  - **RF cubiertos:** RF-6, RF-6.1, RF-6.3
  - **Depends on:** T2
  - **Archivos objetivo (≤3):**
    - `MODIFY` `godot-client/src/Network/GameClient.gd` (send_ticket() con framing correcto)
    - `CREATE` `godot-client/test/TcpKqzTest.gd`
  - **Hecho cuando (TDD):** Test de envío kqz con GameMessage directo (sin Any wrapper) pasa ejecutando `godot --headless --path godot-client --run-gut-tests` (exit code 0).

- [ ] **T7:** Procesar Welcome Burst (kra → kvi → jtg) (RF-8)
  - **RF cubiertos:** RF-8
  - **Depends on:** T6
  - **Archivos objetivo (≤3):**
    - `MODIFY` `godot-client/src/Network/GameClient.gd` (procesar opcodes en orden)
    - `CREATE` `godot-client/test/BurstProcessingTest.gd`
  - **Hecho cuando (TDD):** Test de procesamiento secuencial kra/kvi/jtg pasa ejecutando `godot --headless --path godot-client --run-gut-tests` (exit code 0).

---

## Bloque 3: Interfaz Pública y Walking Skeleton

- [ ] **T8:** Walking Skeleton: login → server_selection → TCP ticket → welcome burst
  - **RF cubiertos:** RF-1, RF-2, RF-5, RF-6, RF-7
  - **Depends on:** T5, T7
  - **Archivos objetivo (≤3):**
    - `CREATE` `godot-client/test/WalkingSkeletonTest.gd`
    - `MODIFY` `godot-client/src/Core/AuthManager.gd` (integración completa)
  - **Hecho cuando (TDD):** Test E2E del flujo completo pasa ejecutando `godot --headless --path godot-client --run-gut-tests` (exit code 0).

- [ ] **T9:** Implementar manejo de errores con popup "Servidor sin responder" (RF-7)
  - **RF cubiertos:** RF-7
  - **Depends on:** T4, T6
  - **Archivos objetivo (≤3):**
    - `CREATE` `godot-client/src/Core/AuthErrorManager.gd`
    - `CREATE` `godot-client/test/ErrorHandlingTest.gd`
  - **Hecho cuando (TDD):** Test de popup error en timeout WebSocket/TCP pasa ejecutando `godot --headless --path godot-client --run-gut-tests` (exit code 0).

- [ ] **T10:** Implementar rechazo de token inválido (RF-9)
  - **RF cubiertos:** RF-9
  - **Depends on:** T4
  - **Archivos objetivo (≤3):**
    - `MODIFY` `godot-client/src/Network/SimpleProtocolClient.gd` (handle auth_response error)
    - `CREATE` `godot-client/test/InvalidTokenTest.gd`
  - **Hecho cuando (TDD):** Test de rechazo con token expirado pasa ejecutando `godot --headless --path godot-client --run-gut-tests` (exit code 0).

---

## Bloque 4: Checkpoint Constitucional (Gate Obligatorio)

- [ ] **T-FINAL:** Auditoría de cumplimiento constitucional (P-001…P-006)
  - **RF cubiertos:** Todos los RF + RNF + principios constitucionales
  - **Depends on:** T1, T2, T3, T4, T5, T6, T7, T8, T9, T10
  - **Archivos objetivo:** N/A (verificación global)
  - **Hecho cuando:** Todos los comandos de `Verificación:` de `docs/constitution.md` devuelven exit code 0:
    - P-001: `grep` sin matches en package.json (Stack Estricto Godot 4.8)
    - P-002: `godot --headless --path godot-client --run-gut-tests` con coverage ≥ 80%
    - P-003: `find . -name "*.gd" -exec wc -l {} \; | awk '$1 > 500'` sin outputs
    - P-004: `gdlint godot-client/src/ --exit-with-zero-on-warning` sin warnings
    - P-005: `grep -rnE "(password|token|secret|credential)" --include="*.gd" godot-client/src/` solo parámetros
    - P-006: Comentarios en español, naming consistente, structure sigue AGENTS.md

---

## Matriz de Trazabilidad (Auditoría de Cobertura)

| Requisito (`spec.md`) | Tareas asignadas | Archivo(s) de implementación | Tipo de verificación |
| --------------------- | ---------------- | ---------------------------- | -------------------- |
| **RF-1** | T1, T8 | `HttpClient.gd` | Unit + E2E |
| **RF-2** | T1, T8 | `HttpClient.gd` | Unit + E2E |
| **RF-3** | T4 | `SimpleProtocolClient.gd` | Integration |
| **RF-4** | T4 | `SimpleProtocolClient.gd` | Unit |
| **RF-5** | T5, T8 | `SimpleProtocolClient.gd`, `AuthManager.gd` | Integration + E2E |
| **RF-6** | T6, T8 | `GameClient.gd` | Integration + E2E |
| **RF-6.1** | T6 | `GameClient.gd` | Unit |
| **RF-6.2** | T2, T6 | `Proto.gd`, `GameClient.gd` | Unit + Integration |
| **RF-6.3** | T6 | `GameClient.gd` | Unit |
| **RF-7** | T8, T9 | `AuthManager.gd`, `GameClient.gd` | E2E |
| **RF-8** | T7, T8 | `GameClient.gd` | Integration + E2E |
| **RF-9** | T4, T10 | `SimpleProtocolClient.gd` | Integration |
| **RF-10** | T1 | `HttpClient.gd` | Unit |
| **RNF-4** | T2 | `Proto.gd` | Unit |
| **RNF-7** | T9 | `AuthErrorManager.gd` | Unit |
| **RNF-8** | T8 | `GameClient.gd` | E2E |
| **RNF-9** | T8 | `AuthErrorManager.gd` | Integration |

---

## Resumen de Auditoría

| Métrica | Valor |
|---------|-------|
| Total de tareas atómicas | 11 (T1-T10 + T-FINAL) |
| Blast radius máximo por tarea | ≤ 3 archivos ✅ |
| Cobertura de RF (RF-1…RF-10) | 100% mapeado ✅ |
| Cobertura de archivos del File Impact Map | 100% asignado ✅ |
| Sin dependencias circulares | ✅ |
| Orden topológico respetado | ✅ |

---

## Próximo Paso

Ejecutar `/sdd-implement T1` para comenzar la implementación incremental.