# Reporte de Auditoría QA — Spec 004 (Movimiento entre mapas)

**Spec auditada:** `specs/004-map-movement/spec.md`  
**Constitución de referencia:** `docs/constitution.md`  
**Veredicto QA:** **PASS** (0 conflictos constitucionales, 0 🔴 críticos, 2 🟡 altos)

---

## Resumen Ejecutivo

| Métrica                          | Conteo | Umbral para PASS | Estado  |
| -------------------------------- | ------ | ---------------- | ------- |
| Conflictos con `constitution.md` | 0      | `0`              | ✅      |
| Hallazgos 🔴 Crítico             | 0      | `0`              | ✅      |
| Hallazgos 🟡 Alto                | 2      | `≤ 2`            | ✅      |
| Hallazgos 🟢 Medio               | 1      | Informativo      | ℹ️      |

> ✅ **Veredicto PASS** – El spec puede avanzar a `/sdd-plan`.

---

## Hallazgos Detallados por Severidad

### 🔴 Crítico

- **Ninguno ✅**

### 🟡 Alto

- **Q-01 [Manejo de bordes sin portal] — RF-14:** No especifica el comportamiento cuando no hay mapa conectado. **Sugerencia:** Agregar transición explícita: "SI no hay mapa conectado, EL SISTEMA ignora el toque del borde".

- **Q-02 [Formato de movimiento] — RF-14:** No especifica el mensaje protobuf de movimiento. **Sugerencia:** Agregar `type_url = "type.ankama.com/movement"` y payload requerido.

### 🟢 Medio

- **Q-03 [Feedback visual] — RF-15:** El jugador no recibe feedback cuando su movimiento es bloqueado. **Sugerencia:** Considerar un sonido o efecto visual breve.

---

## Próximos pasos

✅ Spec aprobada. Puede continuar con `/sdd-plan`.