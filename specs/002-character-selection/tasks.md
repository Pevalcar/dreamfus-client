# Tareas de Implementación — Spec 002 (Selección de personajes)

- **Plan de referencia:** `specs/002-character-selection/plan.md`
- **Spec de referencia:** `specs/002-character-selection/spec.md`
- **Constitución:** `docs/constitution.md`

---

## Bloque 1: Fix del protocolo kvw (Work Item T6)

- [x] **T6.1:** Verificar código existente en GameClient.gd:281 (send_push → send_request)
  - **RF cubiertos:** RF-10
  - **Depends on:** none
  - **Archivos objetivo (≤3):**
    - `MODIFY` `godot-client/src/Network/GameClient.gd:281`
  - **Hecho cuando (TDD):** Verificar que `send_request("kvw", payload)` está implementado ✅
  - **Estado:** ✅ COMPLETADO

- [ ] **T6.2:** Test E2E del flujo completo de selección de personajes
  - **RF cubiertos:** RF-10
  - **Depends on:** T6.1
  - **Archivos objetivo (≤3):**
    - `CREATE` `godot-client/test/CharacterSelectionTest.gd`
  - **Hecho cuando (TDD):** Test de selección de personaje pasa ejecutando `godot --headless --path godot-client --run-gut-tests` (exit code 0)
  - **Pruebas necesarias:**
    1. Conectar al servidor local (`keka`/`test`, ID `188940901`)
    2. Verificar que el login y welcome burst funciona
    3. Seleccionar un personaje
    4. Verificar que el cliente entra al mundo sin error "UNHANDLED CLIENT PACKET"

---

## Bloque 2: Verificación de cobertura

- [ ] **T-VERIFY-1:** Verificar cobertura de tests para kvw
  - **Depends on:** T6.2
  - **Archivos a verificar:**
    - `godot-client/test/CharacterSelectionTest.gd`
  - **Criterio:** Tests cubren RF-10 (selección de personaje)

---

## Matriz de Trazabilidad (Auditoría de Cobertura)

| Requisito (`spec.md`) | Tareas asignadas | Archivo(s) de implementación | Tipo de verificación |
| --------------------- | ---------------- | ---------------------------- | -------------------- |
| **RF-8** | T6.2 | `GameClient.gd`, `CharacterSelectionTest.gd` | Unit + E2E |
| **RF-10** | T6.1, T6.2 | `GameClient.gd`, `CharacterSelectionTest.gd` | Unit + E2E |

---

## Estado de Implementación

### ✅ Completado

- **T6.1:** Fix del envelope kvw (send_push → send_request) - **COMPLETADO**

### ⏳ Pendiente

- **T6.2:** Test E2E del flujo de selección de personajes
- **T-VERIFY-1:** Verificación de cobertura de tests

---

## Archivos Creados/Editados

| Archivo | Acción | Propósito | Estado |
|---------|--------|-----------|--------|
| `godot-client/src/Network/GameClient.gd:281` | EDITADO | send_push → send_request | ✅ |
| `godot-client/docs/PROTOCOL.md:264` | EDITADO | Comentario kvw como REQUEST | ✅ |
| `godot-client/docs/TCP_HANDBSHAKE.md:100-106,354-368` | EDITADO | Documentación kvw como REQUEST | ✅ |
| `specs/002-character-selection/tasks.md` | CREADO | Tasks de implementación | ✅ |

---

## Próximos pasos

1. **T6.2:** Crear test E2E en `godot-client/test/CharacterSelectionTest.gd`
2. **Validación:** Verificar contra servidor local con credenciales `keka` / `test`
3. **Cierre:** Actualizar tasks.md con veredicto final