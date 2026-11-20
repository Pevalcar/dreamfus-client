# Spec 003 — Entrada al mapa

## Contexto y objetivo

**Propósito:** Permitir que un jugador vea y se mueva dentro de un mapa con su personaje y otros jugadores.  
**Historia:** H3 — Como jugador, quiero entrar al mapa con mi personaje visible y ver otros jugadores, para interactuar con el mundo.

## Usuarios / actores

- **Jugador:** Ve su personaje y otros jugadores en el mapa
- **Servidor DreamFus:** Proporciona datos del mapa, posición inicial y otros jugadores

## Historias de usuario

| ID | Historia |
|----|------------|
| **H3** | Como jugador, quiero entrar al mapa con mi personaje visible y ver otros jugadores, para interactuar con el mundo. |

---

## Contratos de frontera (Dominio)

### Entradas y validaciones

**Request map data:**
- Mensaje protobuf `hea.request` campo 2 (Any) con `type_url = "type.ankama.com/worldMap"`
- `uid`: -1 (sin correlación)

### Salidas y efectos observables

**Respuesta TCP (protobuf):**
- Mapa inicial con:
  - ID del mapa
  - Celda de spawn del jugador
  - Lista de otros jugadores con: ID, posición, look

### Invariantes

- **I1:** El jugador aparece en la celda correcta según el spawn
- **I2:** Otros jugadores que estén en el mapa se muestran
- **I3:** El look de cada jugador es consistente con su equipamiento

---

## Requisitos funcionales (EARS)

- **RF-11:** CUANDO el jugador entra al mapa, EL SISTEMA envía el layout del mapa y la posición de spawn.
- **RF-12:** MIENTRAS el jugador está en el mapa, EL SISTEMA mantiene actualizados los movimientos de otros jugadores.
- **RF-13:** SI el jugador cambia de mapa, EL SISTEMA envía los datos del nuevo mapa.

---

## Criterios de finalización

- ✅ Mapa cargado y renderizado
- ✅ Personaje en posición correcta
- ✅ Otros jugadores visibles