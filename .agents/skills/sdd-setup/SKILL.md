---
name: sdd-setup
description: "Detecta ausencia de AGENTS.md y docs/constitution.md, genera plantilla mínima siguiendo tu template SDD."
version: 1.0.0
disable-model-invocation: true
---

## Contexto compartido
- **Consume:** estado del proyecto (existencia de AGENTS.md y docs/constitution.md)
- **Produce:** inicializa `.sdd-state.json` con fase `setup`, `approved_phases = [setup]`
- **Desbloquea:** `/sdd-constitution`

# Generador de Setup SDD

Crea el entorno inicial necesario para un flujo SDD:

1. AGENTS.md siguiendo tu template
2. docs/constitution.md con principios 6 innegociables

## 🛡️ ASSUMPTIONS I'M MAKING:

1. El proyecto no tiene AGENTS.md o docs/constitution.md (primer setup)
2. El usuario quiere crear un flujo SDD nuevo o continuar uno existente
3. La template a seguir es genérica para cualquier proyecto
4. La constitución debe tener máximo 15 líneas de 6 principios verificables
   → Correct me now or I'll proceed.

## When to Use

- Starting a new project with no AGENTS.md
- Constitution doesn't exist
- Need to set up the SDD foundation

## When NOT to Use

- AGENTS.md already exists
- Constitution already created
- Just need to modify existing setup

## Process

### Paso 1: Detectar ausencia

Verifica que no exista:

- `AGENTS.md` (raíz del proyecto)
- `CLAUDE.md` (raíz del proyecto, referencia a AGENTS.md)
- `docs/constitution.md` (directorio docs)

### Paso 2: Preguntar por información básica

Usar tu template para preguntar:

```markdown
# Proyecto: <nombre-proyecto>

## Proyecto

<Qué es, en 2-3 frases. Arquitectura, tecnologías..>

## Comandos

- Ejecutar: `<comando>`
- Tests: `<comando>`
- Lint/formato: `<comando>`

## Estilo y convenciones

<Versión del lenguaje, convenciones de nombres, idioma del código y mensajes.>

## Reglas

- Lee docs/constitution.md y la spec activa antes de tocar código.
- <Límites: qué no tocar, qué no añadir sin preguntar.>
```

### Paso 3: Generar Constitution

Crear `docs/constitution.md` con 6 principios innegociables:

```markdown
# Constitución — <Nombre Proyecto>

1. **Stack mínimo.** <lenguaje> + <máx N dependencias>. <restricción>.
2. **Spec antes que código.** <cómo se valida>.
3. **Separación lógica.** <qué capas existen y su responsabilidad>.
4. **Tests obligatorios.** <quién escribe, cobertura mínima>.
5. **Persistencia controlada.** <qué se guarda, cómo, cuándo>.
6. **Idioma.** <qué idioma, convenciones>.
```

### Paso 4: Crear AGENTS.md

Usar el template proporcionado:

```markdown
# AGENTS.md — <proyecto>

## Proyecto

<Qué es, en 2-3 frases. Arquitectura, tecnologías..>

## Comandos

- Ejecutar: `<comando>`
- Tests: `<comando>`
- Lint/formato: `<comando>`

## Estilo y convenciones

<Versión del lenguaje, convenciones de nombres, idioma del código y mensajes.>

## Reglas

- Lee docs/constitution.md y la spec activa antes de tocar código.
- <Límites: qué no tocar, qué no añadir sin preguntar.>

## Al terminar cualquier tarea

- <Verificación obligatoria, p. ej. ejecutar los tests.>
```

## Output Format

### docs/constitution.md

```markdown
# Constitución — <Nombre Proyecto>

1. **Stack mínimo.** <lenguaje> + <máx N dependencias>. <restricción>.
2. **Spec antes que código.** <cómo se valida>.
3. **Separación lógica.** <qué capas existen y su responsabilidad>.
4. **Tests obligatorios.** <quién escribe, cobertura mínima>.
5. **Persistencia controlada.** <qué se guarda, cómo, cuándo>.
6. **Idioma.** <idioma, convenciones>.
```

### AGENTS.md

```markdown
# AGENTS.md — <proyecto>

## Proyecto

<Qué es, en 2-3 frases. Arquitectura, tecnologías..>

## Comandos

- Ejecutar: `<comando>`
- Tests: `<comando>`
- Lint/formato: `<comando>`

## Estilo y convenciones

<Versión del lenguaje, convenciones de nombres, idioma del código y mensajes.>

## Reglas

- Lee docs/constitution.md y la spec activa antes de tocar código.
- <Límites: qué no tocar, qué no añadir sin preguntar.>

## Al terminar cualquier tarea

- <Verificación obligatoria, p. ej. ejecutar los tests.>
```

## Verification

- [ ] Verificar que AGENTS.md no existía
- [ ] Verificar que docs/constitution.md no existía
- [ ] Constitution escrita con 6 principios máximo
- [ ] AGENTS.md creado siguiendo template
- [ ] User aprobó el contenido

## See Also

- `sdd-constitution` - Verifica constitution específica
- `sdd-spec` - Siguiente skill del flujo
- `references/skill-template.md` - Plantilla base
