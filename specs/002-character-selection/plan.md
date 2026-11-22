# Plan de Implementación — Spec 002 (Selección de personajes)

**Estado:** ✅ **LISTO PARA SDD-IMPLEMENT**

---

## Resumen del Cambio

| Elemento | Estado |
|----------|--------|
| **Spec aprobado** | ✅ (clarify-report.md: PASS) |
| **Documentación del spec** | ✅ Actualizada con kvw como REQUEST |
| **Documentación cliente** | ✅ Actualizada (PROTOCOL.md, TCP_HANDBSHAKE.md) |
| **Código a cambiar** | 1 línea en GameClient.gd:281 |

---

## Work Item — T6: Fix kvw envelope type

### Título
Fix send_push → send_request en character selection (kvw)

### Prioridad
**Alta** — Causa error "UNHANDLED CLIENT PACKET DETECTED: type.ankama.com/kvw"

### Descripción
El cliente Godot usa `send_push("kvw", payload)` en lugar de `send_request("kvw", payload)`, causando que el servidor rechace el envelope porque espera field 2 (request style) y recibe field 1 (push style).

### Archivo a modificar
- `godot-client/src/Network/GameClient.gd:281`

### Cambio requerido
```gdscript
# ANTES (INCORRECTO):
send_push("kvw", payload)

# DESPUÉS (CORRECTO):
send_request("kvw", payload)
```

### Justificación técnica
- `send_push()` crea envelope con `{ f1: Any }` (server→client style)
- `send_request()` crea envelope con `{ f2: inner }` (client→server style)
- El servidor espera `f2` para requests según spec 002 y docs/PROTOCOLO/01-TRANSPORTE.md

### Pruebas
1. Conectar al servidor local (`keka`/`test`, ID `188940901`)
2. Verificar que el login y welcome burst funciona
3. Seleccionar un personaje
4. Verificar que el cliente entra al mundo sin error "UNHANDLED CLIENT PACKET"

---

## Tareas

| ID | Tarea | Estado |
|----|-------|--------|
| T6.1 | Verificar código existente en GameClient.gd:281 | ✅ |
| T6.2 | Cambiar send_push por send_request | ✅ COMPLETADO |
| T6.3 | Verificar que build_character_selection() ya existe | ✅ |
| T6.4 | Test manual con servidor local | ⏳ PENDIENTE |

---

## Código relevante (ya implementado)

### build_character_selection()
```gdscript
func build_character_selection(character_id: int) -> PackedByteArray:
    # Ya implementado, devuelve el payload correcto
```

### Envío correcto
```gdscript
func send_character_selection(character_id: int) -> void:
    var payload := build_character_selection(character_id)
    if payload.is_empty():
        return
    send_request("kvw", payload)  # FIX APLICADO ✅
```

---

## Definición de terminación

- [x] Código actualizado en GameClient.gd
- [x] Documentación actualizada en PROTOCOL.md
- [x] Documentación actualizada en TCP_HANDBSHAKE.md
- [ ] Test E2E funciona con servidor local
- [ ] No hay errores "UNHANDLED CLIENT PACKET"

---

## Referencias

- Spec 002: `specs/002-character-selection/spec.md`
- Clarify report: `specs/002-character-selection/clarify-report.md`
- Protocolo: `docs/PROTOCOLO/01-TRANSPORTE.md:87-94`
- Proto.gd: `godot-client/src/Network/Proto.gd:201-233`