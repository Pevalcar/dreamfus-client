---
name: sdd-constitution
description: "Genera docs/constitution.md tras auditar AGENTS.md y realizar una entrevista QA guiada de máximo 6 preguntas. Ancla los gates de sdd-clarify, sdd-validate y sdd-variants."
version: 1.0.0
disable-model-invocation: true
---

## Contexto compartido
- **Consume:** `AGENTS.md` existente, `approved_phases` incluye `setup`
- **Produce:** inicializa `.sdd-state.json`, `approved_phases` con `constitution`, `current_phase = constitution`, `next_allowed_phase = sdd-backlog`
- **Desbloquea:** `/sdd-backlog`

# Generador de Constitución SDD (QA-Gated)

Define los principios innegociables del proyecto. La constitución es el **contrato fundacional** que alimenta los gates automáticos de `sdd-clarify`, `sdd-validate` y `sdd-variants`.

Los principios son innegociables **durante un ciclo de proyecto**. Solo se modifican mediante versionado controlado al cierre de un ciclo o aprobación explícita.

## 🛡️ ASSUMPTIONS & HARD RULES

1. **Dependencia obligatoria de `AGENTS.md`:** La constitución no se redacta en el vacío; hereda y complementa las reglas definidas en `./AGENTS.md`.
2. **Verificabilidad estricta:** Cada principio tendrá un campo `Verificación:` ejecutable o parseable, o estará marcado explícitamente como `[NO VERIFICABLE — solo guía]`.
3. **Rol de QA Architect:** El agente actúa como un QA Senior que guía al usuario mediante preguntas secuenciales con recomendaciones prácticas antes de redactar reglas.
4. **Cero código sin autorización:** Ninguna skill escribe código, tests ni modificaciones de implementación hasta completar el flujo SDD aprobado.
5. **Human-Gate por defecto:** Todo ciclo requiere verificación y aprobación humana explícita en cada transición de fase, **a menos que** el usuario invoque explícitamente `/build auto`.

---

## When to Use

- Inicio de proyecto nuevo (con `AGENTS.md` ya instalado), antes de escribir cualquier `spec`.
- Cuando se requiere alinear estándares de arquitectura, calidad, cobertura o límites técnicos.
- Cuando se cierra un ciclo y se aprueba regenerar o actualizar a una nueva versión mayor de la constitución.

## When NOT to Use

- `./AGENTS.md` **no existe** en la raíz del proyecto (bloquear y pedir instalación primero).
- Timeboxed spikes o pruebas de concepto desechables donde no aplica SDD.
- **Proyecto pequeño o solo developer → NO es razón para saltarla.** Puede tener 2-3 principios verificables, pero sigue siendo obligatoria para anclar los gates.

## Relación con otras skills

| Skill                   | Cómo consume la constitución                                                        |
| ----------------------- | ----------------------------------------------------------------------------------- |
| `sdd-clarify`           | Cita principios por ID (`P-001`…) al detectar conflictos en especificaciones.       |
| `sdd-validate`          | Audita compliance ítem por ítem contra cada principio y su comando `Verificación:`. |
| `sdd-variants`          | Descarta automáticamente variantes arquitectónicas que violen un principio.         |
| `verification-gates.md` | Define la DoD universal; la constitución **la complementa, no la duplica**.         |

---

## Proceso de Ejecución

### Fase 0: Pre-flight Check (Obligatorio — Fail-Closed)

Antes de hacer cualquier pregunta al usuario, ejecuta estas dos verificaciones en orden:

1. **Verificar existencia de `AGENTS.md`:**
   - Comprueba si `./AGENTS.md` existe en la raíz del repositorio.
   - **Si NO existe:** DETÉN la ejecución inmediatamente. Muestra este mensaje y aborta:
     > ⛔ **Bloqueo Pre-flight:** No se encontró `AGENTS.md` en la raíz del proyecto. Instala o configura `AGENTS.md` primero para que la constitución pueda alinearse con las reglas base del agente.
   - **Si SÍ existe:** Léelo íntegramente. Extrae el stack, estructura de carpetas, comandos de build/test, convenciones de estilo y restricciones ya declaradas para usarlas como base en la entrevista.

2. **Verificar existencia previa de `docs/constitution.md`:**
   - Comprueba si `docs/constitution.md` ya existe.
   - **Si SÍ existe:** DETÉN el flujo y pregunta explícitamente antes de continuar:
     > ⚠️ **Constitución existente detectada:** Ya existe `docs/constitution.md`. ¿Cómo deseas proceder?
     >
     > 1. **Recrear desde cero** (sobrescribirá el archivo actual tras la entrevista y aprobación).
     > 2. **Cancelar** (mantener la constitución actual intacta).
   - No avances a la Fase 1 hasta recibir confirmación explícita.

---

### Fase 1: Entrevista de Descubrimiento (Máximo 6 Preguntas, 1 a 1)

Actúa como un **Experto en QA y Arquitectura de Software**. Realiza una entrevista interactiva siguiendo estrictamente estas reglas:

- **Una pregunta por turno:** Formula **solo 1 pregunta por mensaje** y espera la respuesta del usuario antes de pasar a la siguiente.
- **Tope estricto de 6 preguntas:** Cubre únicamente los vacíos que **no** estén ya resueltos de forma inequívoca en `AGENTS.md`. Si `AGENTS.md` ya define 2 áreas (ej. Stack e Idioma), haz solo las 4 preguntas restantes.
- **Formato obligatorio de cada pregunta:**
  1. **Hallazgo en `AGENTS.md`:** Indica brevemente qué dice `AGENTS.md` sobre ese tema (o si está omitido).
  2. **Pregunta puntual:** Sobre una de estas 6 dimensiones:
     - _Q1 — Stack y Dependencias:_ Límites de librerías externas o versiones estrictas.
     - _Q2 — Arquitectura y Límites:_ Tamaño máximo de archivos/módulos, acoplamiento o separación de capas.
     - _Q3 — Estrategia de Testing:_ Tipos de pruebas obligatorias (unit, integration, e2e) y qué se considera crítico.
     - _Q4 — Umbrales de Calidad:_ Cobertura mínima, linters estrictos o cero warnings permitidos.
     - _Q5 — Manejo de Errores y Seguridad:_ Validación de inputs, manejo de excepciones o secretos.
     - _Q6 — Convenciones y Trazabilidad:_ Idioma de código/commits/docs (si no está en `AGENTS.md`).
  3. **💡 Recomendación de QA:** Proporciona una recomendación concreta (incluyendo una opción _Pragmática_ y una _Estricta_) explicando qué bug o deuda técnica previene cada una.

---

### Fase 2: Detección y Clarificación de Conflictos

Una vez terminadas las preguntas (o si el usuario indica que ya tiene suficiente), **audita la coherencia** entre:

- Lo que dice `AGENTS.md`
- Las respuestas del usuario
- La viabilidad técnica de verificar cada regla automáticamente

**Si detectas cualquier conflicto, ambigüedad o parámetro problemático** (por ejemplo: exigir cobertura del 90% sin tener runner de tests configurado, pedir cero dependencias pero usar un framework pesado, o contradecir una regla de `AGENTS.md`):

- **NO generes el borrador todavía.**
- Presenta los puntos conflictivos numerados, explica por qué chocan o por qué molestarán en los gates de `sdd-validate`, y pide al usuario que elija cómo resolverlos antes de redactar.

---

### Fase 3: Generación de Borrador con IDs Estables y `Verificación:`

Cuando no existan conflictos pendientes, genera el borrador de `docs/constitution.md` **en memoria** (sin escribir en disco todavía) con:

1. **Metadatos de trazabilidad** al inicio del documento (`version`, `agents_md_synced: true`, `created_at`).
2. **Máximo 10 principios** con IDs estables `P-001`, `P-002`, …, `P-0NN`.
   - **Regla de inmutabilidad de IDs:** Los IDs nunca se reutilizan. Si en el futuro se elimina `P-003`, el siguiente será `P-004`.
3. **Campo `Verificación:` obligatorio en cada principio**, usando una de estas 3 formas:

| Forma                           | Cuándo usarla                            | Ejemplo                                                        |
| ------------------------------- | ---------------------------------------- | -------------------------------------------------------------- |
| **A — Comando ejecutable**      | Existe un CLI/script que valida la regla | `Verificación: npm run lint -- --max-warnings 0` (exit code 0) |
| **B — Regla de conteo/archivo** | Hay un reporte o archivo parseable       | `Verificación: coverage/lcov.info reporta lines >= 80%`        |
| **C — Juicio humano**           | No automatizable de forma fiable         | `Verificación: [NO VERIFICABLE — revisión humana en PR]`       |

**Regla dura (Fail-Closed):** Si algún principio carece de campo `Verificación:`, la skill tiene prohibido pasar al Gate de Aprobación.

---

### Fase 4: Gate de Aprobación Humana y Control de Modo

Presenta el borrador completo junto con el resumen de auditoría y solicita aprobación explícita:

```markdown
## 🔒 Gate de Aprobación Humana (Constitución SDD)

**Resumen del borrador:**

- Alineado con `AGENTS.md`: ✅ Verificado sin conflictos
- Total de principios: X (`P-001` a `P-00X`)
- Verificables automáticamente (Forma A/B): Y
- Solo guía humana (Forma C): Z

**Modo de ejecución para los siguientes ciclos:**

- Por defecto: **`human-gated`** (cada fase —`backlog`, `spec`, `plan`, `tasks`, `implement`, `validate`— se detendrá al finalizar para exigir tu revisión y aprobación manual).
- Alternativa: Si deseas ejecución continua sin pausas intermedias, indícalo explícitamente ejecutando **`/build auto`**.

¿Apruebas escribir `docs/constitution.md` con este contenido?

- [ ] **Sí** → Guardar `docs/constitution.md`, inicializar `.sdd-state.json` en modo `human-gated` y desbloquear únicamente `sdd-backlog`.
- [ ] **No** → Indicar ajustes (no se escribirá ningún archivo en disco) .

- [ ] **Cancelar** → No hacer nada.
```
