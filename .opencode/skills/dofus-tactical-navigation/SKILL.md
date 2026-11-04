---
name: dofus-tactical-navigation
description: Implementa y revisa rejilla isométrica, CellID, vecinos, A*, Dijkstra, línea de visión, ocupación, costes y sincronización de movimiento del cliente DreamFus.
---

# Skill: navegación táctica isométrica

## Fuentes obligatorias

- `docs/research/MOVEMENT-NETWORK-RESEARCH.md`
- `docs/research/GAME-SYSTEMS.md`
- datos y formato real del protocolo de DreamFus

## Reglas

- No fijar una fórmula CellID por memoria o por una versión distinta.
- Crear tests de round-trip `CellID <-> coordenadas`.
- Separar pathfinding de línea de visión.
- Separar previsualización local de confirmación autoritativa.
- Representar explícitamente `Unreachable`, `Invalid` y `Cancelled`.
- No enviar rutas comprimidas sin evidencia de bytes compatibles.
- Comparar actualizaciones de posición por secuencia o versión cuando exista.
- Cancelar animaciones al cambiar de mapa, combate o conexión.

## Casos que siempre deben probarse

- celdas fuera del mapa;
- obstáculos;
- entidades ocupando celdas;
- PM insuficientes;
- ruta sin solución;
- doble clic;
- actualización durante animación;
- rechazo del servidor;
- cambio de mapa;
- reconexión.

