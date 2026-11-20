---
name: sdd-plan
description: "Genera specs/NNN-<slug>/plan.md con arquitectura de módulos, File Impact Map, modelo de datos, ADRs con trade-offs y cobertura estratificada de RF, alineado con AGENTS.md, constitution.md y spec.md."
version: 1.0.0
disable-model-invocation: true
---

## Contexto compartido
- **Consume:** `approved_phases` incluye `clarify`, `spec`, `active_spec_dir`
- **Produce:** `spec.md`, `plan.md`, actualiza `approved_phases` con `plan`
- **Desbloquea:** `/sdd-review`, `/sdd-tasks`

# Planificador Técnico SDD — Arquitectura & Diseño sin Código

Convierte una especificación aprobada (`specs/NNN-<slug>/spec.md`) en un diseño técnico determinista (`specs/NNN-<slug>/plan.md`) listo para descomponerse en tareas atómicas (`/sdd-tasks`), **sin escribir código de producción todavía**.

## 🛡️ ASSUMPTIONS & HARD RULES

1. **Pre-condiciones estrictas:** Existen `AGENTS.md`, `docs/constitution.md`, `specs/NNN-<slug>/spec.md` aprobada y `.sdd-state.json` con `clarification.status == "PASS"` (o `spec` aprobada sin dudas abiertas).
2. **Cero código de producción:** Este documento contiene arquitectura, contratos de interfaz, esquemas de datos, pseudocódigo y rutas de archivos; **nunca** archivos fuente `.ts`, `.py`, `.cs`, `.gd`, etc.
3. **100% Cobertura de RF:** Cada requisito funcional (`RF-1`…`RF-N`) e invariante de `spec.md` debe mapearse explícitamente a un módulo, archivo y prueba verificable.
4. **Obediencia Constitucional:** Ninguna decisión técnica puede violar los principios `P-001`…`P-0NN` de `docs/constitution.md` ni las restricciones de `AGENTS.md`.
5. **Human-Gate por defecto:** No se escribe `specs/NNN-<slug>/plan.md` ni se desbloquea `/sdd-tasks` sin aprobación humana explícita, salvo en modo `/build auto`.

---

## When to Use

- La especificación `specs/NNN-<slug>/spec.md` está aprobada y `clarification.status == "PASS"` en `.sdd-state.json`.
- Se requiere diseñar la arquitectura, el impacto en archivos, el modelo de datos y la estrategia de pruebas antes de crear tareas o codificar.

## When NOT to Use

- `spec.md` no existe, tiene `[NECESITA ACLARACIÓN]`, o `clarification.status` no es `"PASS"` (ejecutar `/sdd-clarify` primero).
- Se intenta escribir código directamente sin plan aprobado (bloqueado).

---

## Proceso de Ejecución

### Fase 0: Pre-flight Check y Carga de Verdad (Obligatorio — Fail-Closed)

1. **Verificar estado y gates en `.sdd-state.json`:**
   - Lee `.sdd-state.json` y obtén `active_spec_dir` (formato `specs/NNN-<slug>`).
   - Verifica que `"constitution"` y `"spec"` estén en `approved_phases`, y que `clarification.status == "PASS"`.
   - **Si falla alguna condición:** DETÉN la ejecución y muestra:
     > ⛔ **Bloqueo Pre-flight:** No se puede generar el plan técnico. Verifica que `docs/constitution.md` y `specs/NNN-<slug>/spec.md` estén aprobadas y que `/sdd-clarify` tenga estado `PASS` en `.sdd-state.json`.

2. **Verificar existencia previa de `specs/NNN-<slug>/plan.md`:**
   - Si ya existe `specs/NNN-<slug>/plan.md` sin completar o de una iteración previa, detente y pregunta:
     > ⚠️ **Plan existente detectado en `specs/NNN-<slug>/plan.md`:** ¿Deseas **reemplazarlo desde cero** tras aprobación o **cancelar**?

3. **Leer fuentes de verdad:**
   - `./AGENTS.md` (estructura de carpetas, stack, comandos de build/test y límites del agente).
   - `docs/constitution.md` (principios innegociables `P-001`…`P-0NN` y reglas de verificación).
   - `specs/NNN-<slug>/spec.md` (todos los `RF`, `RNF`, contratos de frontera, matriz de estados y `Fuera de alcance`).
   - `docs/backlog.md` (si existe, para revisar `Expensive decisions`).

---

### Fase 1: Clarificación Técnica Puntual (Máximo 3 Preguntas, 1 a 1)

Actúa como un **Principal Software Architect**. Solo si `AGENTS.md` y `docs/constitution.md` dejan abierta una decisión técnica crítica (ej. elegir estrategia de persistencia, librería específica o protocolo de comunicación):

- Haz **máximo 3 preguntas técnicas**, de **1 en 1**.
- Incluye siempre tu **💡 Recomendación de Arquitectura** justificando cuál opción cumple mejor con los principios `P-001`…`P-0NN` y minimiza deuda técnica.
- Si el stack y patrones ya están totalmente definidos en `AGENTS.md` y `docs/constitution.md`, **salta directo a la Fase 2**.

---

### Fase 2: Diseño Técnico en Memoria (`template-plan.md`)

Genera el borrador completo de `specs/NNN-<slug>/plan.md` **en memoria** (sin guardar archivo todavía), asegurándote de incluir:

1. **Arquitectura de Módulos y Flujo de Dependencias:** Cómo se dividen las responsabilidades respetando la separación de capas.
2. **File Impact Map (Mapa de Archivos):** Lista exacta de archivos a **crear**, **modificar** y zonas **prohibidas de tocar** (aislamiento de alcance).
3. **Modelo de Datos y Contratos de Frontera:** Esquemas concretos (entidades, tipos, validaciones) alineados con los invariantes de `spec.md`.
4. **Contratos de Interfaz (Adaptable):** Según el tipo de sistema, define la tabla de **Endpoints API**, **Comandos CLI**, **Eventos/WebSockets** o **Firmas de Servicios Públicos**, incluyendo entradas, salidas y códigos de error.
5. **Algoritmo Principal y Manejo de Fallos:** Pseudocódigo agnóstico del flujo crítico + estrategia de degradación/rollback ante cada `RF` de tipo `SI <error>, ENTONCES...`.
6. **ADRs Ligeros (Architecture Decision Records):** Decisiones clave, justificación, alternativa descartada y **Trade-off asumido**.
7. **Matriz de Cumplimiento Constitucional (`P-001`…`P-0NN`):** Cómo el diseño satisface cada regla de `docs/constitution.md`.
8. **Matriz de Cobertura de RF y Estrategia de Pruebas:** Mapeo 100% de cada `RF-1`…`RF-N` hacia su módulo, archivo y nivel de test (`Unit`, `Integration`, `E2E`).

---

### Fase 3: Gate de Aprobación Humana

Presenta el borrador completo junto con el resumen de auditoría técnica:

## 🔒 Gate de Aprobación Humana (Plan Técnico SDD)

**Resumen de auditoría técnica:**

- Archivo destino: `specs/NNN-<slug>/plan.md`
- Cumplimiento constitucional (`P-001`…`P-0NN`): ✅ 100% verificado
- Cobertura de requisitos (`RF-1`…`RF-N`): ✅ 100% mapeados a módulos y tests
- Archivos nuevos / modificados: X nuevos, Y modificados

¿Apruebas este plan técnico para guardarlo en `specs/NNN-<slug>/plan.md`?

- [ ] **Sí** → Guardar `specs/NNN-<slug>/plan.md`, actualizar `.sdd-state.json` y desbloquear `/sdd-tasks`.
- [ ] **No** → Indicar ajustes de arquitectura, modelo de datos o archivos (no se escribirá nada hasta nueva aprobación).

---

## 🔒 Reglas de Bloqueo y Gobernanza

1. **Cero escritura sin "Sí" explícito (modo `human-gated`):** En modo `human-gated`, no se crea `specs/NNN-<slug>/plan.md` ni se modifica `.sdd-state.json` hasta recibir aprobación humana explícita.
2. **Aislamiento de fase:** Aprobar el plan desbloquea **únicamente `/sdd-tasks**`, nunca `/sdd-implement`.
3. **Comportamiento en `/build auto`:** Si `.sdd-state.json` tiene `"execution_mode": "auto"`, la skill puede guardar `specs/NNN-<slug>/plan.md` automáticamente **solo si** el 100% de los `RF` tienen cobertura y no existe ningún conflicto con `docs/constitution.md`. Ante cualquier conflicto arquitectónico, `/build auto` se detiene y exige intervención humana.

---

## What Happens After Approval

Cuando el usuario responde **"Sí"**:

1. Se escribe `specs/NNN-<slug>/plan.md`.
2. Se actualiza `.sdd-state.json`:

```json
{
  "constitution_version": "1.0.0",
  "agents_md_checked": true,
  "execution_mode": "human-gated",
  "current_phase": "plan",
  "active_spec_dir": "specs/NNN-<slug>",
  "clarification": { "status": "PASS" },
  "approved_phases": ["constitution", "backlog", "spec", "clarify", "plan"],
  "next_allowed_phase": "sdd-tasks",
  "gate_status": "approved"
}
```

3. Se indica al usuario que puede continuar con `/sdd-tasks` para descomponer el plan en tareas atómicas.

- **Reglas de persistencia e índices:** <restricciones de unicidad, transacciones atómicas>

## 4. Contrato de interfaz (<API / CLI / Eventos / Servicios>)

| Operación / Comando | Entrada        | Salida exitosa | Errores / Códigos      | RF asociado    |
| ------------------- | -------------- | -------------- | ---------------------- | -------------- |
| `<operacion-1>`     | `<parámetros>` | `<respuesta>`  | `<código / excepción>` | `RF-1`, `RF-2` |

## 5. Algoritmo principal y manejo de fallos (pseudocódigo)

```text
FUNCION procesar_accion(entrada):
  VALIDAR invariantes de entrada -> SI falla: LANZAR ErrorValidacion (RF-2)
  INICIAR transaccion
    EJECUTAR cambio de estado segun Matriz de Estados
    REGISTRAR auditoria / evento observable
  CONFIRMAR transaccion
  DEVOLVER resultado (RF-1)

```

## 6. Decisiones técnicas (ADRs ligeros)

- **ADR-001 — <Título de la decisión>:**
- **Decisión:** <Qué se eligió>
- **Justificación:** <Por qué cumple mejor con spec.md y constitution.md>
- **Alternativa descartada:** <Qué se evitó y por qué>
- **Trade-off asumido:** <Complejidad o limitación aceptada>

## 7. Cumplimiento constitucional

| Principio | Regla de `docs/constitution.md` | Cómo lo garantiza este plan       |
| --------- | ------------------------------- | --------------------------------- |
| `P-001`   |                                 | <Mecanismo concreto en el diseño> |

## 8. Cobertura de RF y estrategia de pruebas

| RF     | Módulo      | Archivo destino | Tipo de test  | Caso de prueba clave            |
| ------ | ----------- | --------------- | ------------- | ------------------------------- |
| `RF-1` | `<MóduloA>` | `src/...`       | `Integration` | `test_flujo_nominal_exitoso`    |
| `RF-2` | `<MóduloA>` | `src/...`       | `Unit`        | `test_rechaza_entrada_invalida` |
