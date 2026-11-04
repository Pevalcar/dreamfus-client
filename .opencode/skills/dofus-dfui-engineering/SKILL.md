---
name: dofus-dfui-engineering
description: Diseña y mantiene el motor DFUI de DreamFus: componentes declarativos, temas, estilos, ventanas, 9-slice, accesibilidad, estados de UI y previews sin depender de Alea.
---

# Skill: ingeniería DFUI

## Fuentes

- `frontend/src/dfui/index.js`
- `frontend/src/SliceManager.js`
- `docs/research/ALEA-DATA-GUIDE.md`
- `docs/research/ARCHITECTURE.md`

## Reglas

- DFUI es un formato propio; no prometer compatibilidad total con UXML/USS.
- Validar `t`, `a`, `s`, `c`, `k`, `w` y `h`.
- Escapar texto y atributos antes de escribir en DOM.
- Separar definición de componente, tema, layout y estado.
- Toda ventana declara foco, modalidad, z-index, cierre y listeners.
- Toda operación 9-slice tiene fixture sintético.
- Todo componente tiene estados normal, hover/focus, disabled, loading, empty y
  error cuando corresponda.
- No depender de una instalación externa durante `npm run build`.

## Accesibilidad y UX

- navegación de teclado;
- foco visible;
- etiquetas accesibles;
- contraste suficiente;
- no depender solo del color;
- cerrar modales con Escape cuando corresponda;
- impedir que eventos de una ventana lleguen al mapa.

## Entrega requerida

- schema o contrato;
- componente;
- estilo/tema;
- test;
- preview o verificación manual;
- documentación de lifecycle y jerarquía;
- lista de recursos propios utilizados.

