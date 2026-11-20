# Spec 004 — Movimiento entre mapas

## Contexto y objetivo

**Propósito:** Permitir que un jugador se mueva entre mapas tocando los bordes de la pantalla.  
**Historia:** H4 — Como jugador, quiero moverme entre mapas tocando los bordes de la pantalla, para explorar sin complicaciones.

## Usuarios / actores

- **Jugador:** Mueve su personaje tocando bordes de pantalla
- **Servidor DreamFus:** Procesa el movimiento y notifica transiciones de mapa

## Historias de usuario

| ID | Historia |
|----|------------|
| **H4** | Como jugador, quiero moverme entre mapas tocando los bordes de la pantalla, para explorar sin complicaciones. |

---

## Contratos de frontera (Dominio)

### Entradas y validaciones

**Request movimiento:**
- Mensaje protobuf `hea.request` campo 2 (Any) con `type_url = "type.ankama.com/movement"`
- Payload con dirección (north, south, east, west) o coordenadas

### Salidas y efectos observables

- El jugador se mueve en el mapa actual
- Al tocar un borde con portal, se transita al mapa conectado
- El cliente muestra el nuevo mapa

### Invariantes

- **I1:** El movimiento es instantáneo en el mapa actual
- **I2:** La transición de mapa preserva la posición del jugador
- **I3:** Sólo se permite movimiento válido (celdas walkable)

---

## Requisitos funcionales (EARS)

- **RF-14:** CUANDO el jugador toca el borde derecho de la pantalla, EL SISTEMA intenta teletransportar al mapa conectado.
- **RF-15:** CUANDO el jugador toca un borde sin portal, EL SISTEMA ignora el movimiento.
- **RF-16:** LA TRANSICIÓN completa el mapa sin necesidad de interacción adicional.

---

## Criterios de finalización

- ✅ Touch detector en bordes de pantalla
- ✅ Teletransporte funcional a mapas conectados
- ✅ Transición fluida sin retraso visible