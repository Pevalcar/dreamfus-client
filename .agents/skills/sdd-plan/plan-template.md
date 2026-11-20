# Plan NNN — <Nombre de la Funcionalidad>

- **Spec de referencia:** `specs/NNN-<slug>/spec.md`
- **Constitución:** `docs/constitution.md` (vX.Y.Z)

## 1. Arquitectura de módulos

<Diagrama ASCII o lista jerárquica mostrando módulos, responsabilidades y dirección de dependencias>

## 2. File Impact Map (Alcance de archivos)

| Acción   | Ruta de archivo                    | Responsabilidad única     |
| -------- | ---------------------------------- | ------------------------- |
| `CREATE` | `src/<modulo>/<archivo_nuevo>`     | <Qué hace>                |
| `MODIFY` | `src/<modulo>/<archivo_existente>` | <Qué se ajusta y por qué> |

**Archivos / directorios fuera de alcance (prohibido tocar):**

- `<ruta_protegida>` — <motivo>

## 3. Modelo de datos e invariantes

```json
{
  "entidad": {
    "id": "string (UUID, requerido, único)",
    "estado": "enum [BORRADOR | ACTIVO | CANCELADO]",
    "valor": "number (>= 0, invariante de dominio)"
  }
}
```
