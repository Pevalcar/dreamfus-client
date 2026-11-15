# Design

## Context

El proyecto ha evolucionado de un cliente multi-tecnología (Tauri/Rust + frontend Vite + Godot) a un cliente Godot 4.8 exclusivo. El código Tauri/Rust ha sido eliminado pero los archivos README.md y README_ES.md aún mantienen referencias obsoletas.

Referencias actuales que necesitan actualización:
- README.md línea 3: "backend Tauri, frontend Vite"
- README.md línea 21: Referencia a ALDA como "Tauri/WebGL2 client"
- README.md líneas 48-54: Estructura del proyecto con src/ y src-tauri/
- README.md líneas 116, 130: Referencias a `src/lib.rs` con estado Tauri
- README.md líneas 249-256: Sección completa sobre Tauri/Rust build
- README_ES.md: Mismos problemas en español
- AGENTS.md: Necesita simplificación y actualización de referencias

Además, el AGENTS.md tiene secciones innecesarias y referencias a `docs/GODOT_CLIENT_PROTOCOL.md` que debe verificarse.

## Goals / Non-Goals

**Goals:**
- Actualizar README.md y README_ES.md para reflejar proyecto Godot 4.8 como único cliente
- Eliminar referencias obsoletas a Tauri/Rust del roadmap y estructura del proyecto
- Simplificar AGENTS.md eliminando duplicados y referencias obsoletas
- Actualizar documentación para apuntar a docs/ existentes

**Non-Goals:**
- Modificar el contenido técnico de docs/ (solo referencias)
- Cambiar nombres de archivos existentes
- Modificar código fuente del proyecto

## Decisions

### 1. Eliminar sección Tauri/Rust del README

**Decisión:** Eliminar completamente las referencias a Tauri/Rust en lugar de moverlas a "histórico"

**Razón:** El código ya no existe en el repositorio. Mantener referencias crea confusión. La sección de desarrollo se enfocará solo en Godot y frontend Vite (que podría estar en modo mock/investigativo).

### 2. Actualizar estructura del proyecto

**Decisión:** Reemplazar la estructura mostrada con una que refleje el estado actual (solo Godot)

**Razón:** La estructura actual muestra carpetas que ya no son relevantes o están vacías.

### 3. Simplificar AGENTS.md

**Decisión:** Reescribir AGENTS.md con secciones esenciales solo

**Razón:** El archivo actual es muy largo y tiene referencias duplicadas o obsoletas. Se centrará en lo que es útil para contribuyentes actuales.

### 4. Verificar documentación en docs/

**Decisión:** Verificar que docs/GODOT_CLIENT_PROTOCOL.md exista o crear un redirect

**Razón:** El AGENTS.md menciona docs/GODOT_CLIENT_PROTOCOL.md pero el archivo listado existe como docs/PROTOCOL.md en godot-client/

## Risks / Trade-offs

- **Risk:** Usuarios pueden no encontrar documentación de referencia histórica
- **Mitigation:** Mantener referencias a ALDA en comentarios contextuales si es críítico

- **Risk:** Cambios en README pueden afectar búsquedas externas
- **Mitigation:** Mantener keywords clave de Dofus/Fan project

## Archivos a modificar

1. **README.md** - Reescribir para:
   - Cambiar descripción inicial a "Cliente Godot 4.8 para Dofus"
   - Actualizar tabla de estado para mostrar Godot como principal
   - Eliminar estructura que muestra src/ y src-tauri/
   - Eliminar sección de desarrollo Tauri
   - Actualizar referencias a protocolo

2. **README_ES.md** - Mismos cambios en español

3. **AGENTS.md** - Simplificar para:
   - Referencias MCP actualizadas
   - Eliminar duplicados
   - Limpiar referencias obsoletas

## Open Questions

- ¿Quieres mantener alguna referencia histórica a Tauri en un archivo separado (por ejemplo, docs/Tauri-Reference.md o HISTORY.md)?
- ¿El frontend Vite debe mantenerse como referencia o se considera deprecated/obsoleto?