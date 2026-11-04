---
name: dofus-client-decompiler-research
description: Usa repositorios públicos de análisis/decompilación y una instalación autorizada en modo lectura para documentar UI, mapas, hechizos, efectos, animaciones y audio, transformando hallazgos en contratos propios sin copiar código ni assets propietarios.
---

# Skill: investigación con decompilación

## Fuentes obligatorias

- `docs/research/JONDO-WEBCLIENT-RESEARCH.md`
- `docs/research/ALEA-LOCAL-AUDIT-2026-11-01.md`
- `docs/research/ALEA-DATA-GUIDE.md`
- `docs/research/RESEARCH-METHOD.md`

## Alcance permitido

Usar decompilación y análisis estático para:

- comprender estructuras;
- localizar relaciones entre subsistemas;
- identificar eventos;
- documentar ciclo de vida;
- medir tamaños y formatos;
- crear hipótesis verificables;
- diseñar interfaces propias;
- crear tests con datos sintéticos.

## Límites

- no copiar cuerpos de métodos propietarios al proyecto;
- no incluir DLLs, GameAssembly, bundles ni assets;
- no publicar dumps de tráfico o cuentas;
- no modificar instalaciones de jugadores;
- no automatizar acceso a cuentas de terceros;
- no tratar nombres obfuscados como API estable;
- no afirmar que un hallazgo es válido para todas las versiones.

## Proceso

```text
fuente y commit
  -> símbolo o archivo observado
  -> comportamiento neutral
  -> nivel de confianza
  -> contrato DreamFus
  -> fixture sintético
  -> test
  -> implementación propia
```

## Hechizos y efectos

Para cada hechizo investigado registrar:

```text
spell_id observado
evento de inicio
proyectil o área
impacto
efectos
duración visual
audio asociado
interrupciones
evidencia
```

El resultado debe alimentar un `SpellTimeline` propio. Nunca insertar un
método decompilado como implementación.

## Artefactos aceptables

- tablas de nombres neutrales;
- conteos;
- hashes;
- schemas propios;
- fixtures sintéticos;
- diagramas;
- documentación;
- tests;
- herramientas que no copien contenido propietario.

## Verificación

Cada hallazgo debe indicar:

- versión del cliente;
- commit de la fuente;
- ruta observada;
- confianza;
- limitaciones;
- qué se reimplementará;
- qué queda prohibido copiar;
- cómo se verificará en DreamFus.

