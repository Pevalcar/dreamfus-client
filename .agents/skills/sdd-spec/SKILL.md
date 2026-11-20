---
name: sdd-spec
description: "Genera especificaciones funcionales verificables en notación EARS (specs/NNN-nombre.md) con contratos de frontera, matriz de estados y trazabilidad bidireccional, alineadas a docs/constitution.md y docs/backlog.md."
version: 1.0.0
disable-model-invocation: true
---

## Contexto compartido
- **Consume:** `approved_phases` incluye `backlog`, `spec`, `active_spec_dir`
- **Produce:** `spec.md`, actualiza `approved_phases` con `spec`, `next_allowed_phase = sdd-clarify`
- **Desbloquea:** `/sdd-clarify`

# Generador de Especificaciones SDD (RF-EARS & Domain Contracts)

Convierte una historia de usuario o requerimiento en una especificación funcional acordada (`specs/NNN-<slug>/spec.md`). **La spec es el contrato: lo que no está aquí, no se implementa.**

## 🛡️ ASSUMPTIONS & HARD RULES

1. **Pre-condición estricta:** `AGENTS.md` y `docs/constitution.md` existen y `"constitution"` está aprobada en `.sdd-state.json`.
2. **Solo QUÉ y POR QUÉ:** Prohibido incluir stack tecnológico, arquitectura, nombres de archivos, esquemas SQL/JSON concretos, algoritmos o firmas de funciones (eso pertenece a `sdd-plan`).
3. **Trazabilidad Bidireccional:** Toda historia de usuario (`H1`, `H2`…) debe mapearse a uno o más requisitos (`RF-1 [H1]`), y ningún `RF` puede quedar huérfano.
4. **Cero dudas abiertas al aprobar:** Ninguna spec puede aprobarse si contiene marcadores `[NECESITA ACLARACIÓN]`.
5. **Human-Gate por defecto:** No se escribe `specs/NNN-<slug>/spec.md` ni se desbloquea `sdd-plan` sin aprobación humana explícita, salvo en modo `/build auto`.

---

## When to Use

- Al iniciar la especificación formal de una funcionalidad o historia del backlog (`docs/backlog.md`).
- Cuando los requerimientos son ambiguos y necesitan aterrizarse en criterios verificables EARS, contratos de dominio y casos límite.

## When NOT to Use

- `docs/constitution.md` no existe o no está aprobada en `.sdd-state.json` (ejecutar `/sdd-constitution` primero).
- La spec ya existe y solo quieres resolver ambigüedades o ajustar un requisito puntual (usar `/sdd-clarify`).
- Quieres escribir código o diseñar tablas/endpoints (ir a `/sdd-plan` tras aprobar la spec).

---

## Proceso de Ejecución

### Fase 0: Pre-flight Check y Contexto (Obligatorio — Fail-Closed)

1. **Verificar estado SDD:**
   - Comprueba la existencia de `AGENTS.md`, `docs/constitution.md` y `.sdd-state.json`.
   - Verifica que `"constitution"` esté en `approved_phases` dentro de `.sdd-state.json`.
   - **Si falta alguno:** DETÉN la ejecución y muestra:
     > ⛔ **Bloqueo Pre-flight:** Se requiere `AGENTS.md` y una constitución aprobada en `docs/constitution.md` antes de crear especificaciones. Ejecuta `/sdd-constitution` primero.
2. **Cargar fuentes de verdad:**
   - Lee `docs/constitution.md` (para alinear RNF y restricciones `P-001`…`P-0NN`).
   - Lee `docs/backlog.md` si existe (para extraer la historia objetivo, actores y el `Out of Scope`).
   - Revisa `specs/` para obtener el siguiente número correlativo `NNN` (3 dígitos: `001`, `002`…) y evitar contradicciones con specs previas.

---

### Fase 1: Capability Map (Solo si hay múltiples módulos independientes)

Si el requerimiento agrupa varias capacidades independientes y testeables (ej. `identity`, `billing`, `notifications`), **propón primero un Capability Map** y pide confirmación antes de escribir la spec:

```markdown
# Capability Map: [Nombre de la Iniciativa]

| Module id | Responsabilidad          | Depende de |
| --------- | ------------------------ | ---------- |
| identity  | Cuentas, sesiones, roles | —          |
| billing   | Planes, facturas, pagos  | identity   |

Orden de construcción: identity → billing
```

- Module id en kebab-case, inmutable.

- Dependencias unidireccionales (si hay ciclo entre dos módulos, son un solo módulo).

- Cada módulo tendrá su propia spec independiente en orden de dependencia.

### Fase 2: Entrevista de Requisitos (Máximo 6 Preguntas, 1 a 1)

Actúa como un QA & Requirements Analyst. Realiza una entrevista enfocada exclusivamente en comportamiento observable, reglas de dominio, estados y casos límite:

- Una pregunta por turno: Formula solo 1 pregunta por mensaje y espera respuesta.

- Tope estricto de 6 preguntas: Descarta preguntas cuya respuesta ya esté en docs/backlog.md o docs/constitution.md.

- Enfoque:
  - Prioriza preguntas sobre: (1) entradas/salidas e invariantes de negocio, (2) estados de vida de entidades, (3) permisos/roles, (4) límites/concurrencia y (5) manejo de errores.

  - Si el usuario pregunta "¿cómo lo implementarías?", redirige inmediatamente del CÓMO técnico al QUÉ funcional.

  - Prohibido inventar requisitos: Cualquier vacío no resuelto durante la entrevista debe quedar visible como [NECESITA ACLARACIÓN: pregunta concreta].

### Fase 3: Redacción en Memoria (EARS + Contratos + Estados)

Redacta el borrador completo de la spec en memoria (sin guardar archivo aún) aplicando estas 4 reglas de rigor:

1. Notación EARS estricta (1 requisito = 1 frase):
   - Ubicuo: EL SISTEMA <hará>...
   - Dirigido por evento: CUANDO <disparador>, EL SISTEMA <hará>...
   - Estado: MIENTRAS <estado>, EL SISTEMA <hará>...
   - Opcional: DONDE <característica>, EL SISTEMA <hará>...

   - No deseado: SI <condición anómala>, ENTONCES EL SISTEMA <hará>...

   - Prohibido: Unir dos comportamientos con "y" o usar adjetivos subjetivos ("rápido", "intuitivo", "robusto").

2. Trazabilidad Bidireccional ([H#]): Cada requisito funcional lleva su origen entre corchetes (ej. RF-1 [H1]).

3. Contratos de Frontera (Sin Stack): Define entradas requeridas, reglas de validación, salidas observables e invariantes del dominio (reglas que nunca pueden romperse).

4. Matriz de Estados (si aplica): Si una entidad cambia de estado (ej. Borrador → Activo → Cancelado), documenta qué transiciones son válidas y qué transiciones están prohibidas (generando su correspondiente RF de tipo SI... ENTONCES...).

### Template

Obligatorio (specs/NNN-<slug>/spec.md):

```markdown
# Spec NNN — <Nombre de funcionalidad la>

## Contexto y objetivo

<Qué #N Máximo Referencia a aplica. de docs/backlog.md historia la merece pena. por problema párrafo. qué resuelve si un y>

## Usuarios / actores

- <Rol 1>: <alcance y permisos de negocio>

## Historias de usuario

- H1: Como <rol>, quiero <acción>, para <beneficio>.

## Contratos de frontera (Dominio)

- **Entradas y validaciones:** <datos de negocio requeridos, formatos y rangos válidos>
- **Salidas y efectos observables:** <qué obtiene el actor o qué evento de negocio se produce>
- **Invariantes (reglas inviolables):** <ej. "El saldo nunca puede ser menor a 0">

## Matriz de estados y transiciones (si aplica)

| Estado actual | Evento / Acción | Estado destino | ¿Permitido? | Regla / RF asociado |
| ------------- | --------------- | -------------- | ----------- | ------------------- |
| Borrador      | Confirmar       | Activo         | Sí          | RF-1                |
| Cancelado     | Confirmar       | Activo         | No          | RF-3                |

## Requisitos funcionales (criterios de aceptación en EARS)

- RF-1 [H1]: CUANDO <evento>, EL SISTEMA <respuesta observable> (resultado esperado).
- RF-2 [H1]: SI <condición no deseada>, ENTONCES EL SISTEMA <respuesta ante el error>.
- RF-3 [H1]: MIENTRAS <estado>, EL SISTEMA <respuesta>.
- RF-4 [H1]: EL SISTEMA <comportamiento permanente>.

## Requisitos no funcionales (RNF)

- RNF-1: <rendimiento, seguridad, idioma, validación — alineado con P-001…P-0NN>.

## Casos límite

- <Entradas concurrencia, conexión... de duplicados, límites numéricos, pérdida vacías,>

## Fuera de alcance

- <Lo NO en esta explícitamente implementa iteración. que se>

## Criterios de finalización

- Todos los RF (`RF-1`…`RF-N`) cubiertos por pruebas automatizadas en verde.
- Cumplimiento verificado contra `docs/constitution.md`.

## Dudas abiertas

- [NECESITA ACLARACIÓN] <pregunta concreta, o "Ninguna">
```

### Fase 4: Auditoría Interna de 6 Dimensiones (6-Dimension Spec Audit)

Antes de presentar el borrador al usuario, ejecuta esta auditoría silenciosa y corrige o señala vacíos:

1. Happy Path: ¿Está cubierto el flujo nominal de principio a fin?
2. Error & Validation Paths: ¿Cada entrada inválida tiene un RF con patrón SI... ENTONCES...?
3. Permissions & Roles: ¿Está claro qué pasa si un actor sin permisos intenta ejecutar la acción?

4. Concurrency & Idempotency: ¿Se define qué ocurre ante envíos duplicados o acciones simultáneas?

5. Observability / Audit: ¿Se especifica si las acciones críticas requieren confirmación visible o registro de auditoría?

### Fase 5: Gate de Aprobación Humana

1. Bloqueo automático por dudas: Si la sección ## Dudas abiertas contiene al menos un [NECESITA ACLARACIÓN], NO presentes el botón de aprobación final. Pide primero al usuario que resuelva esas dudas hasta dejar Dudas abiertas: Ninguna.

2. Presentación del Gate: Cuando Dudas abiertas sea Ninguna, muestra el borrador y solicita confirmación explícita:

## 🔒 Gate de Aprobación Humana (Especificación SDD)

**Resumen de auditoría:**

- Archivo destino: `specs/NNN-<slug>/spec.md`
- Alineado con `docs/constitution.md`: ✅ Sin conflictos
- Trazabilidad Historias ↔ RF: 100% cubierta (`H1`…`HX` → `RF-1`…`RF-Y`)
- Auditoría de 6 Dimensiones: ✅ Revisada
- Dudas abiertas pendientes: 0 ✅

¿Apruebas esta especificación para guardarla en `specs/NNN-<slug>/spec.md`?

- [ ] **Sí** → Guardar `specs/NNN-<slug>/spec.md`, actualizar `.sdd-state.json` y desbloquear `/sdd-clarify` (o `/sdd-plan`).
- [ ] **No** → Indicar qué requisitos ajustar (no se escribirá ningún archivo hasta nueva aprobación).

## Modo Revisión (Cuando se pide auditar una spec existente)

Si el usuario pide revisar una spec ya guardada en lugar de crear una nueva, **no la reescribas directamente**. Lista numeradamente los hallazgos en 4 bloques:

1. **Ambigüedades** (adjetivos no medibles o frases sin patrón EARS)
2. **Contradicciones entre requisitos o estados**
3. **Casos límite no cubiertos** (según las 6 dimensiones)
4. **Conflictos con `docs/constitution.md` o `docs/backlog.md`**

## 🔒 Reglas de Bloqueo y Gobernanza

1. **Cero escritura sin aprobación (modo `human-gated`):** En modo `human-gated`, no se crea `specs/NNN-<slug>/spec.md` ni se actualiza `.sdd-state.json` hasta recibir `"Sí"` explícito.
2. **Prohibido saltar al código o al plan:** Aprobar la spec desbloquea únicamente `/sdd-plan` (o `/sdd-clarify` si surgen cambios).
3. **Comportamiento en `/build auto`:** Si `.sdd-state.json` tiene `"execution_mode": "auto"`, la skill puede guardar `specs/NNN-<slug>/spec.md` automáticamente **solo si** `Dudas abiertas` es `Ninguna` y no hay conflictos con `docs/constitution.md`. Si existe al menos una duda abierta (`[NECESITA ACLARACIÓN]`), `/build auto` se detiene y exige intervención humana.

## What Happens After Approval

Cuando el usuario responde **"Sí"**:

1. Se escribe `specs/NNN-<slug>/spec.md` reemplazando `NNN` por el correlativo real.
2. Se actualiza `.sdd-state.json`:

```json
{
  "constitution_version": "1.0.0",
  "agents_md_checked": true,
  "execution_mode": "human-gated",
  "current_phase": "spec",
  "active_spec": "specs/NNN-<slug>/spec.md",
  "approved_phases": ["constitution", "backlog", "spec"],
  "next_allowed_phase": "sdd-plan",
  "gate_status": "approved"
}
```

3. Se informa al usuario que puede continuar con `/sdd-clarify` (o ejecutar `/sdd-plan` si desea refinar algún punto).
