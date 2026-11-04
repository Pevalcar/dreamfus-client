---
name: dofus-client-protocol
description: Diseña, implementa y revisa el transporte TCP, framing, envelopes, opcodes, serialización, estados de conexión y replay del cliente DreamFus en Tauri. Úsala antes de cambiar Rust, protocol.js o contratos de mensajes.
---

# Skill: protocolo del cliente DreamFus

## Obligatorio antes de editar

1. Leer `docs/research/ARCHITECTURE.md`.
2. Leer `docs/research/MOVEMENT-NETWORK-RESEARCH.md` si afecta a mapas o rutas.
3. Revisar `src/lib.rs`, `frontend/src/protocol.js` y `frontend/src/EventBus.js`.
4. Fijar el commit y versión del protocolo en la tarea.
5. Comprobar si existe un test de bytes para el mensaje que se va a tocar.

## Reglas

- Separar reader y writer.
- No mantener un lock mientras se bloquea leyendo el socket.
- No ocultar fallos reales activando mock automáticamente.
- Validar longitudes, varints, opcodes y payloads.
- Usar errores explícitos; no devolver éxito con un fallback silencioso.
- Mantener el servidor como autoridad.
- No imprimir credenciales, tokens ni payloads sensibles.
- Mantener el modo `real`, `mock` y `replay` visible y separado.

## Entrega requerida

- contrato de entrada/salida;
- tests de framing y decoder;
- estados válidos e inválidos;
- estrategia de cancelación/desconexión;
- compatibilidad de versión;
- resultado de las pruebas ejecutadas;
- actualización de `docs/research/`.

