---
name: dofus-combat-client
description: Diseña el modelo de combate, turnos, previsualización de hechizos, efectos, timeline, desincronización y renderer táctico del cliente DreamFus sin sustituir la autoridad del servidor.
---

# Skill: combate táctico del cliente

## Fuentes obligatorias

- `docs/research/COMBAT-RESEARCH.md`
- `docs/research/GAME-SYSTEMS.md`
- contrato de mensajes confirmado del servidor

## Reglas

- El servidor decide turnos, costes, daños, efectos y resultado.
- La previsualización debe ser pura y no mutar el estado autoritativo.
- Separar protocolo, estado, reglas de preview, timeline y renderer.
- Encolar eventos para que las animaciones sean reproducibles.
- Ignorar o registrar duplicados; no aplicarlos dos veces.
- Tratar eventos desconocidos de forma explícita.
- Detener la predicción al detectar desincronización.

## Entrega requerida

- máquina de estados;
- eventos y secuencias;
- reglas de validación local;
- comportamiento ante rechazo;
- estrategia de recuperación;
- tests unitarios e integración;
- comprobación visual separada de la compilación.

