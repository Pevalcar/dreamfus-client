# Reporte de Auditoría QA — Spec 005 (Manejo de errores del servidor)

**Spec auditada:** `specs/005-server-error-handling/spec.md`  
**Constitución de referencia:** `docs/constitution.md`  
**Veredicto QA:** **PASS** (0 conflictos constitucionales, 0 🔴 críticos, 3 🟡 altos)

---

## Resumen Ejecutivo

| Métrica                          | Conteo | Umbral para PASS | Estado  |
| -------------------------------- | ------ | ---------------- | ------- |
| Conflictos con `constitution.md` | 0      | `0`              | ✅      |
| Hallazgos 🔴 Crítico             | 0      | `0`              | ✅      |
| Hallazgos 🟡 Alto                | 3      | `≤ 2`            | ⚠️      |
| Hallazgos 🟢 Medio               | 0      | Informativo      | ℹ️      |

> ⚠️ **Veredicto con observaciones** – El spec tiene 3 hallazgos altos que deberían abordarse antes de avanzar.

---

## Hallazgos Detallados por Severidad

### 🔴 Crítico

- **Ninguno ✅**

### 🟡 Alto

- **Q-01 [Responsabilidad mezclada] — RF-17:** Define timeout de 2 segundos y popup de error. Esto es responsabilidad del cliente. El servidor solo decide si cae o no. **Sugerencia:** Reemplazar con "EL SISTEMA permite que el cliente detecte la conexión fallida".

- **Q-02 [Responsabilidad mezclada] — RF-18:** Similar a Q-01. El cliente decide el timeout TCP. **Sugerencia:** Unificar bajo RNF o eliminar specificity.

- **Q-03 [Reintento ambiguo] — RF-19:** "reinicia el flujo de login" es ambiguo. ¿Comienza desde el login HTTP o desde el último estado? **Sugerencia:** "vuelve a la pantalla de login mostrando el formulario vacío".

### 🟢 Medio

- **Ninguno ✅**

---

## Matriz de Trazabilidad QA

- **RF con hallazgos bloqueantes (`🔴`):** Ninguno
- **RF con observaciones (`🟡`):** `[Q-01, Q-02, Q-03]`

---

## Recomendación

Este spec mezcla responsabilidades del cliente con requisitos del servidor. Se recomienda:
1. Mover timeouts y UI a un documento de "Guías de implementación" o RNF
2. Especificar claramente qué hace el servidor vs. qué hace el cliente
3. Reespecificar el comportamiento de reintento

---

## Próximos pasos

1. **Ajustar spec** → Separar responsabilidades del cliente/servidor
2. **Re-audit** → Ejecutar `/sdd-clarify` nuevamente
3. **Proceder a `/sdd-plan`** → Solo cuando no haya hallazgos 🟡