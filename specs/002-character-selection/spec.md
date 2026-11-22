# Spec 002 — Selección de personajes

## Contexto y objetivo

**Propósito:** Permitir que un jugador vea y seleccione un personaje de su cuenta para jugar.  
**Historia:** H2 — Como jugador, quiero ver mi lista de personajes y seleccionar uno, para jugar con mi avatare.

## Usuarios / actores

- **Jugador:** Con una cuenta conectada, ve sus personajes
- **Servidor DreamFus:** Proporciona la lista de personajes vía protocolo TCP protobuf

## Historias de usuario

| ID | Historia |
|----|------------|
| **H2** | Como jugador, quiero ver mi lista de personajes y seleccionar uno, para jugar con mi avatare. |

---

## Contratos de frontera (Dominio)

### Entradas y validaciones

**Request personajes (flujo TCP):**
- Los personajes se reciben automáticamente vía protobuf push `kvi` como parte del **welcome burst** tras autenticación:
  - `kra` (ticket ack) → `kvi` (character list push) → `jtg` (end of burst)
- El `GameClient` procesa `kvi` y emite `characters_received` al recibir `jtg`
- **No se requiere petición explícita** - es un push del servidor

**Request selección:**
- `kvw` REQUEST con envelope `{ f2: inner }` donde `inner = { f1: Any { f1: "type.ankama.com/kvw", f2: { f1: character_id } } }`
- El cliente debe usar `send_request()` (envelope campo raíz `f2`), NO `send_push()` (envelope campo raíz `f1`)
- Ver `docs/PROTOCOLO/01-TRANSPORTE.md:87-94` y `docs/Protocolosactualziados/opcodes/connection/README.md:20`

### Salidas y efectos observables

**Lista de personajes (kvi):**
```json
// Cada personaje en el array de kvi
{
  "id": long,              // f2: ID del personaje
  "nombre": string,        // f2: nombre (3-20 caracteres)
  "nivel": int,            // f3: nivel (1-200)
  "raza": int,             // f7: raza (0-11 clases)
  "sexo": int,             // f4.f2: sexo (0=f, 1=m)
  "aspecto": string        // f6: look/base64 encoded sprite data
}
```

**Respuesta de error (kvi vacío):**
- Si el jugador no tiene personajes: `kvi` con array vacío `[]`
- El cliente muestra UI con mensaje "No tienes personajes. Crea uno."

### Invariantes

- **I1:** Los personajes mostrados pertenecen exclusivamente a la cuenta del token
- **I2:** Un jugador nunca ve personajes de otras cuentas
- **I3:** El orden es: personaje jugado última vez primero (proporcionado por servidor)

---

## Requisitos funcionales (EARS)

- **RF-8:** CUANDO el jugador está autenticado y recibe el welcome burst, EL SISTEMA devuelve la lista de personajes de su cuenta con sus propiedades observables vía el protobuf push `kvi`. SI la lista está vacía, EL SISTEMA muestra mensaje "Sin personajes".

- **RF-9:** SI el token es inválido o expirado, EL SISTEMA no emite `kvi` y la conexión se cierra con error de autenticación.

- **RF-10:** CUANDO el jugador selecciona un personaje, EL SISTEMA:
  - Envía `kvw { f1: character_id }` como REQUEST al servidor (envelope campo raíz `f2`)
  - Envía `lqc` (character digest) para confirmar selección
  - Cambia el estado a IN_GAME
  - Inicia la descarga del bloque de mapa (`jru`)

---

## Protocolo Técnico

### Flujo de personajes (TCP protobuf)

```
1. WebSocket: auth_request → auth_response (con ticket)
2. WebSocket: server_selection → server_selection_response (ticket, host, ports)
3. TCP 5555: connect + kqz (ticket)
4. Welcome burst: kra → kvi → jtg
   - kvi contiene array de personajes (protobuf)
   - jtg dispara characters_received al UI
```

### Formato kvi (protobuf)

Ver `docs/PROTOCOLO/03-PERSONAJES.md` sección 1.1:
```
kvi: f1 (repetido) {
    f2: "Nombre",      // nombre
    f3: 150,           // nivel
    f4: { f2: 0 } o { f2: 1 },  // sexo
    f6: hex...,        // look
    f7: 1              // raza
}, f2: 12345678       // ID
```

---

## Criterios de finalización

- ✅ Lista de personajes cargada y mostrada desde kvi protocol
- ✅ Selección de personaje inicia el mapa con kvw/lqc
- ✅ Personaje muestra su aspecto correcto (look string)
- ✅ Manejo de lista vacía (sin personajes)

---

## Consideraciones Técnicas

### Arquitectura existente

El código `GameManager.gd:436-454` ya procesa `kvi` y maneja `characters_received`. No se requiere endpoint HTTP adicional.

### Casos límite

| Caso | Manejo |
|------|--------|
| Jugador sin personajes | `kvi` con array vacío → UI muestra "Crea un personaje" |
| Token inválido | Conexión TCP rechazada → error de autenticación |
| Personaje no existe | `kvw` rechazado por servidor → error de selección |