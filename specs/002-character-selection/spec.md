# Spec 002 — Selección de personajes

## Contexto y objetivo

**Propósito:** Permitir que un jugador vea y seleccione un personaje de su cuenta para jugar.  
**Historia:** H2 — Como jugador, quiero ver mi lista de personajes y seleccionar uno, para jugar con mi avatare.

## Usuarios / actores

- **Jugador:** Con una cuenta conectada, ve sus personajes
- **Servidor DreamFus:** Proporciona la lista de personajes

## Historias de usuario

| ID | Historia |
|----|------------|
| **H2** | Como jugador, quiero ver mi lista de personajes y seleccionar uno, para jugar con mi avatare. |

---

## Contratos de frontera (Dominio)

### Entradas y validaciones

**Request personajes:**
- Endpoint (HAAPI): `POST /api/personajes` con `{ "token": string }`
- `token`: token de sesión válido

### Salidas y efectos observables

**Respuesta HTTP:**
```json
{
  "bien": true,
  "personajes": [
    { "id": long, "nombre": string, "nivel": int, "raza": int, "sexo": int, "aspecto": string }
  ]
}
```

- `id`: ID único del personaje
- `nombre`: nombre visible del personaje (3-20 caracteres)
- `nivel`: 1-200 niveles
- `raza`: 0-11 (clases)
- `sexo`: 0 o 1
- `aspecto`: string base64 o referencia que el cliente puede renderizar

### Invariantes

- **I1:** Los personajes mostrados pertenecen exclusivamente a la cuenta del token
- **I2:** Un jugador nunca ve personajes de otras cuentas
- **I3:** El orden es: personaje jugado última vez primero

---

## Requisitos funcionales (EARS)

- **RF-8:** CUANDO el jugador está autenticado, EL SISTEMA devuelve la lista de personajes de su cuenta con sus propiedades observables.
- **RF-9:** SI el token es inválido, EL SISTEMA responde `{ "bien": false }`.
- **RF-10:** CUANDO el jugador selecciona un personaje, EL SISTEMA inicia el mapa con ese personaje visible.

---

## Criterios de finalización

- ✅ Lista de personajes cargada y mostrada
- ✅ Selección de personaje inicia el mapa
- ✅ Personaje muestra su aspecto correcto (look string)