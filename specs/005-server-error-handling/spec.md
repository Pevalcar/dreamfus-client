# Spec 005 — Manejo de errores del servidor

## Contexto y objetivo

**Propósito:** Mostrar un popup cuando el servidor está caído o inaccesible.  
**Historia:** H5 — Como jugador, quiero ver un popup cuando el servidor está caído, para entender el problema y reintentar.

## Usuarios / actores

- **Jugador:** Recibe feedback visible cuando hay problemas de conexión
- **Cliente Godot:** Detecta y muestra el error

## Historias de usuario

| ID | Historia |
|----|------------|
| **H5** | Como jugador, quiero ver un popup cuando el servidor está caído, para entender el problema y reintentar. |

---

## Contratos de frontera (Dominio)

### Entradas y validaciones

**Detección de error:**
- WebSocket falla al conectar → timeout 2 segundos
- TCP falla al conectar → timeout 2 segundos
- Ping/Pong fallido → conexión caída

### Salidas y efectos observables

- **Popup modal** con mensaje: "Servidor sin responder"
- Botón "Volver a intentar" que reinicia el flujo
- Botón "Cancelar" que vuelve al login

### Invariantes

- **I1:** El popup es visible inmediatamente al detectar error
- **I2:** El jugador puede reintentar sin recargar la aplicación
- **I3:** El mensaje es claro y accionable

---

## Requisitos funcionales (EARS)

- **RF-17:** CUANDO el WebSocket no responde en 2 segundos, EL SISTEMA muestra un popup con "Servidor sin responder".
- **RF-18:** CUANDO el TCP no se conecta, EL SISTEMA muestra el mismo popup.
- **RF-19:** SI el jugador pulsa "Volver a intentar", EL SISTEMA reinicia el flujo de login.

---

## Criterios de finalización

- ✅ Popup visible en menos de 3 segundos
- ✅ Botón de reintento funcional
- ✅ Botón de cancelar vuelve al login