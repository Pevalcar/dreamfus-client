# Backlog SDD — DreamFus Client v1.0

**Propósito:** Cliente Godot 4.8 que permite a jugadores conectarse a servidores Dofus Unity  
**Creado:** $(date)  
**Versión:** 1.0  
**Execution mode:** human-gated  

---

## Context

- **Actores:** Jugador casual (conecta desde escritorio, sin instalar nada)
- **Expensive decisions:** Protocolo Protobuf/TCP y modelo de datos de personaje son inmutables — el servidor Unity es la autoridad total
- **Out of Scope (Este ciclo):**
  - Chat entre jugadores
  - Tienda/compra de items
  - Sistema de amigos
  - Gráficos 3D avanzados (solo sprite 2D)
  - Sistema de inventario

---

## Backlog (Vertical Slices)

| ID | Historia |
|----|------------|
| **#1** | As a jugador, I want iniciar sesión y conectarme al servidor, so that puedo acceder al juego desde el cliente. *(Walking Skeleton)* |
| **#2** | As a jugador, I want ver mi lista de personajes y seleccionar uno, so that puedo jugar con tu avatare. Requires: #1 |
| **#3** | As a jugador, I want entrar al mapa con mi personaje visible y ver otros jugadores, so that puedo interactuar con el mundo. Requires: #2 |
| **#4** | As a jugador, I want moverme entre mapas tocando los bordes de la pantalla, so that puedo explorar sin complicaciones. Requires: #3 |
| **#5** | As a jugador, I want ver un popup cuando el servidor está caído, so that entiendo el problema y puedo reintentar. |

---

## Resumen

- **Walking Skeleton:** #1 (#1 + #2 + #3)
- **Total historias:** 5
- **Historias técnicas:** 0
- **Exclusiones:** 5 (chat, tienda, amigos, gráficos, inventario)

---

##iguiente fase

**sdd-story** (refinar una historia con criteria de aceptación)