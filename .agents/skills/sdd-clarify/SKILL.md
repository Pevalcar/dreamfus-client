---
name: sdd-clarify
description: "Audita specs/NNN-<slug>/spec.md como QA Senior mediante Test Oracle Check, validación de invariantes/estados y cruce con constitution.md y backlog.md. Emite veredicto PASS/FAIL en .sdd-state.json."
version: 1.0.0
disable-model-invocation: true
---

## Contexto compartido
- **Consume:** `approved_phases` incluye `spec`, `active_spec_dir`
- **Produce:** actualiza `clarification.status` (`PASS`/`FAIL`), `clarification.report_path`, `next_allowed_phase = sdd-plan`
- **Desbloquea:** `/sdd-plan` (solo si `clarification.status == PASS`)

# Clarificador SDD — Auditoría QA & Gate de Especificaciones

Realiza una revisión formal de ingeniería de requisitos sobre `specs/NNN-<slug>/spec.md` antes de permitir el diseño técnico (`/sdd-plan`). Detecta ambigüedades, requisitos no falsables, contradicciones de estado y violaciones a `docs/constitution.md`.

## 🛡️ ASSUMPTIONS & HARD RULES

1. **Pre-condiciones estrictas:** Existen `AGENTS.md`, `docs/constitution.md`, `.sdd-state.json` y la especificación objetivo `specs/NNN-<slug>/spec.md`.
2. **Separación de Diagnóstico vs. Remediación:** En la pasada inicial, la skill **solo audita y diagnostica** sin alterar `spec.md`. Solo si el usuario lo aprueba, abre el ciclo de remediación guiada.
3. **Veredicto Determinista (Sin vacíos):** Todo análisis termina estrictamente en `PASS` o `FAIL`. Si el veredicto es `FAIL`, `/sdd-plan` permanece bloqueado.
4. **Reporte aislado:** La auditoría se guarda en `specs/NNN-<slug>/clarify-report.md` para no contaminar `spec.md` con anotaciones temporales.
5. **Human-Gate por defecto:** No se marca `clarification.status = "PASS"` ni se desbloquea `/sdd-plan` sin confirmación humana explícita, salvo en modo `/build auto`.

## When to Use

- Inmediatamente después de redactar `specs/NNN-<slug>/spec.md` y antes de ejecutar `/sdd-plan`.
- Cada vez que se modifique un requisito funcional (`RF`), contrato de frontera o matriz de estados en `spec.md`.

## When NOT to Use

- `specs/NNN-<slug>/spec.md` aún no existe (ejecutar `/sdd-spec` primero).
- Ya existe un `clarify-report.md` con estado `PASS` y `spec.md` no ha sufrido cambios desde esa auditoría.

## Proceso de Ejecución

### Fase 0: Pre-flight Check y Carga de Verdad (Obligatorio — Fail-Closed)

1. **Verificar estado en `.sdd-state.json`:**
   - Lee `.sdd-state.json` y obtén `active_spec_dir` (formato `specs/NNN-<slug>`).
   - Comprueba que existan `AGENTS.md`, `docs/constitution.md` y `specs/NNN-<slug>/spec.md`.
   - **Si falta alguno:** DETÉN la ejecución y muestra:
     > ⛔ **Bloqueo Pre-flight:** No se encontró una especificación activa válida en `specs/NNN-<slug>/spec.md` o falta `docs/constitution.md`. Ejecuta `/sdd-spec` primero.
2. **Cargar fuentes de verdad:**
   - `specs/NNN-<slug>/spec.md` (completa).
   - `docs/constitution.md` (principios `P-001`…`P-0NN`).
   - `docs/backlog.md` (si existe, para auditar la sección `Out of Scope` contra _scope creep_).
   - `AGENTS.md` (convenciones generales del proyecto).

### Fase 1: Auditoría QA Profunda (4 Dimensiones + Test Oracle Check)

Actúa como un **QA Architect & Requirements Auditor**. Evalúa cada requisito (`RF-1`…`RF-N`), cada contrato de frontera y la matriz de estados contra estas 4 dimensiones:

1. **Ambigüedades y Test Oracle Check (Falsabilidad):**
   - ¿Cada `RF` usa un patrón **EARS** válido (`CUANDO`, `SI... ENTONCES`, `MIENTRAS`, `DONDE`, `EL SISTEMA`)?
   - **Test Oracle Check:** ¿Puede un QA escribir una aserción booleana (`assert`) exacta sin adivinar valores, tiempos, formatos o mensajes? Todo adjetivo subjetivo (_"rápido"_, _"fácil"_, _"adecuado"_) o salida vaga (_"notificará al usuario"_ sin canal/contenido) es un hallazgo.
2. **Contradicciones y Máquina de Estados:**
   - ¿Existen `RF` que se contradicen entre sí o dependencias circulares?
   - Si existe Matriz de Estados: ¿Todas las transiciones marcadas como _"No permitidas"_ tienen su `RF` explícito de rechazo? ¿Hay estados huérfanos sin salida?
3. **Casos Límite y Dimensiones Faltantes:**
   - Audita vacíos en: entradas nulas/vacías, duplicados, límites numéricos, permisos/roles no autorizados, concurrencia/idempotencia y fallos de red/persistencia.
4. **Conflictos Constitucionales y Scope Creep:**
   - ¿Algún `RF` o `RNF` viola un principio `P-001`…`P-0NN` de `docs/constitution.md`?
   - ¿Algún `RF` invade lo declarado en `Out of Scope` de `docs/backlog.md` o `spec.md`?

#### Clasificación Obligatoria por Severidad

Asigna a cada hallazgo un ID único (`Q-01`, `Q-02`…) y su severidad:

- **🔴 Crítico:** Violación constitucional (`P-00X`), contradicción directa, requisito imposible de testear (falla _Test Oracle Check_), o transición ilegal sin manejo.
- **🟡 Alto:** Caso límite importante no cubierto (ej. timeout, concurrencia, entrada vacía) o ambigüedad menor que admite dos interpretaciones válidas.
- **🟢 Medio:** Mejora de redacción EARS, oportunidad de dividir un `RF` compuesto en dos, o aclaración cosmética.

### Fase 2: Veredicto Matemático Determinista (`PASS` vs `FAIL`)

Evalúa los conteos de hallazgos aplicando esta regla exacta (sin zonas grises):

- ✅ **`PASS`:** Se cumplen **TODAS** estas condiciones:
  - `0` conflictos con `docs/constitution.md`
  - `0` hallazgos **🔴 Crítico**
  - `≤ 2` hallazgos **🟡 Alto** (documentados como riesgos menores aceptables)
- ❌ **`FAIL`:** Se cumple **CUALQUIERA** de estas condiciones:
  - `≥ 1` conflicto con `docs/constitution.md`
  - `≥ 1` hallazgo **🔴 Crítico**
  - `≥ 3` hallazgos **🟡 Alto**

_(Si no se detecta ningún problema, el reporte declara explícitamente: `"✅ Veredicto PASS: 0 conflictos constitucionales, 0 hallazgos críticos y 0 hallazgos altos."`)_

### Fase 3: Gate de Aprobación Humana y Ciclo de Remediación

Genera el borrador de `specs/NNN-<slug>/clarify-report.md` **en memoria** usando `template-clarify.md` y actúa según el veredicto:

#### Caso A: Veredicto `FAIL` (Bloqueo de `/sdd-plan`)

1. Muestra el reporte completo con los ítems `Q-01`…`Q-0N`.
2. Solicita guardar el reporte de auditoría y ofrece **remediación guiada 1 a 1**:

## 🛑 Gate QA: Veredicto FAIL — Planificación Bloqueada

**Resumen de auditoría (`specs/NNN-<slug>/spec.md`):**

- Conflictos constitucionales: X
- Hallazgos 🔴 Crítico: Y | 🟡 Alto: Z | 🟢 Medio: W
- Estado para `/sdd-plan`: **BLOQUEADO**

**¿Cómo deseas continuar?**

- [ ] **Remediación guiada (Recomendado)** → Resolveremos cada hallazgo 🔴 y 🟡 uno por uno, actualizaré `specs/NNN-<slug>/spec.md` y volveré a auditar hasta lograr `PASS`.
- [ ] **Solo guardar reporte** → Guardar `specs/NNN-<slug>/clarify-report.md` con estado `FAIL` en `.sdd-state.json` y detener.

#### Caso B: Veredicto `PASS` (Desbloqueo de `/sdd-plan`)

Presenta el reporte limpio y solicita confirmación humana (en modo `human-gated`):

## 🔒 Gate de Aprobación Humana (Veredicto QA: PASS)

**Resumen de auditoría (`specs/NNN-<slug>/spec.md`):**

- Archivo destino: `specs/NNN-<slug>/clarify-report.md`
- Conflictos constitucionales: 0 ✅
- Hallazgos 🔴 Crítico: 0 ✅ | 🟡 Alto: X (≤ 2) | 🟢 Medio: Y
- Veredicto QA: **PASS**

¿Apruebas guardar este reporte QA y desbloquear `/sdd-plan`?

- [ ] **Sí** → Guardar `specs/NNN-<slug>/clarify-report.md`, registrar `clarification.status = "PASS"` en `.sdd-state.json` y desbloquear `/sdd-plan`.
- [ ] **No** → Indicar ajustes adicionales antes de pasar al diseño técnico.

## 🔒 Reglas de Bloqueo y Gobernanza

1. **Cero mutación silenciosa de `spec.md`:** Nunca edites `spec.md` durante la auditoría inicial. Solo actualiza `spec.md` si el usuario elige **Remediación guiada** y aprueba cada cambio.
2. **Bloqueo estricto de `/sdd-plan`:** Mientras `clarification.status` en `.sdd-state.json` no sea `"PASS"`, `/sdd-plan` tiene prohibido ejecutarse.
3. **Comportamiento en `/build auto`:**

- Si el veredicto es **`PASS`**, en modo `/build auto` la skill guarda `specs/NNN-<slug>/clarify-report.md`, actualiza `.sdd-state.json` con `"status": "PASS"` y avanza automáticamente a `/sdd-plan`.
- Si el veredicto es **`FAIL`**, **incluso en modo `/build auto**`, la ejecución **se detiene obligatoriamente** y devuelve el control al humano para resolver los hallazgos 🔴/🟡.

## What Happens After Approval (`PASS`)

Cuando el veredicto es `PASS` y el usuario aprueba (o `/build auto` lo valida):

1. Se escribe `specs/NNN-<slug>/clarify-report.md`.
2. Se actualiza `.sdd-state.json`:

```json
{
  "constitution_version": "1.0.0",
  "agents_md_checked": true,
  "execution_mode": "human-gated",
  "current_phase": "clarify",
  "active_spec_dir": "specs/NNN-<slug>",
  "clarification": {
    "status": "PASS",
    "critical_count": 0,
    "high_count": 0,
    "report_path": "specs/NNN-<slug>/clarify-report.md"
  },
  "approved_phases": ["constitution", "backlog", "spec", "clarify"],
  "next_allowed_phase": "sdd-plan",
  "gate_status": "approved"
}
```

3. Se indica al usuario que puede continuar con `/sdd-plan`.

### 2. Archivo `template-clarify.md` (Unificado por Severidad y Categoría)

# Reporte de Auditoría QA — Spec NNN (<Nombre>)

- **Spec auditada:** `specs/NNN-<slug>/spec.md`
- **Constitución de referencia:** `docs/constitution.md`
- **Veredicto QA:** `[PASS | FAIL]`

## Resumen Ejecutivo

| Métrica                          | Conteo | Umbral para PASS | Estado  |
| -------------------------------- | ------ | ---------------- | ------- |
| Conflictos con `constitution.md` | 0      | `0`              | ✅ / ❌ |
| Hallazgos 🔴 Crítico             | 0      | `0`              | ✅ / ❌ |
| Hallazgos 🟡 Alto                | 0      | `≤ 2`            | ✅ / ❌ |
| Hallazgos 🟢 Medio               | 0      | Informativo      | ℹ️      |

## Hallazgos Detallados por Severidad

### 🔴 Crítico (Bloqueantes — Deben resolverse antes de `/sdd-plan`)

- **Q-01 [Ambigüedad / Test Oracle] — `RF-X`:** <Descripción exacta de por qué no es falsable o qué término carece de métrica>.
- **Q-02 [Conflicto Constitucional] — `RF-Y` vs `P-00X`:** <Descripción de la contradicción con `docs/constitution.md`>.
  _(Si no hay: `Ninguno ✅`)_

### 🟡 Alto (Riesgos de diseño o casos límite faltantes)

- **Q-03 [Caso Límite / Estado] — `RF-Z`:** <Descripción del escenario no cubierto: concurrencia, timeout, transición ilegal, etc.>.
  _(Si no hay: `Ninguno ✅`)_

### 🟢 Medio (Mejoras de claridad EARS)

- **Q-04 [Redacción EARS] — `RF-W`:** <Sugerencia de dividir frase compuesta o precisar actor>.
  _(Si no hay: `Ninguno ✅`)_

---

## Matriz de Trazabilidad QA

- **RF con hallazgos bloqueantes (`🔴`):** `[RF-X, RF-Y]` o `Ninguno`
- **RF con observaciones (`🟡` / `🟢`):** `[RF-Z, RF-W]` o `Ninguno`
- **Invariantes y Matriz de Estados:** `[Verificados sin contradicciones | Con observaciones en Q-XX]`
- **Alineación con `Out of Scope`:** `[Sin scope creep detectado | Invasión detectada en RF-XX]`
