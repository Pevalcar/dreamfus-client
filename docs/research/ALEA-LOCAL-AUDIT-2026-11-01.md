# Auditoría local de Alea — 2026-11-01

## Alcance

Se inspeccionó en modo solo lectura:

```text
C:\Users\pevalcar\AppData\Local\Alea
```

No se copiaron archivos, assets, binarios ni datos de usuario al repositorio
DreamFus. Esta auditoría registra conteos y nombres de carpetas para decidir
qué sistemas investigar y cómo construir sustitutos propios.

## Versión y metadatos observados

El archivo local `.alea-content.json` informa:

```text
version: 0.1.0+4a8328d5
complete: true
sequence: 1793506611
```

La versión es de Alea, no una versión de compatibilidad garantizada para
DreamFus. Debe guardarse como evidencia de esta auditoría, no como dependencia
del cliente.

## Inventario por carpeta

Los tamaños son aproximados y pertenecen a la instalación local:

| Carpeta | Archivos | Tamaño aproximado | Prioridad |
|---|---:|---:|---|
| `client-patched` | 120 | 8,21 GB | alta, revisar cambios/parches sin copiar |
| `d3audio` | 30.460 | 1,28 GB | muy alta para audio |
| `d3fx` | 1 | mínima | muy alta para efectos |
| `d3items` | 12.778 | 0,10 GB | alta para iconos/objetos |
| `d3maps` | 62 | 2,74 GB | muy alta para mapas |
| `d3pack` | 23.062 | 6,61 GB | alta, contenedores y dependencias |
| `d3picto` | 5.035 | 0,08 GB | alta para iconografía |
| `d3spells` | 3.129 | 0,03 GB | muy alta para hechizos |
| `d3ui` | 787 | pequeño | muy alta para UI |
| `d3world` | 632 | pequeño | alta para mundo/entidades |
| `d3worldmap` | 1.217 | 0,12 GB | alta para navegación y mapa global |
| `dofus-base` | 344 | 3,40 GB | media, base empaquetada |
| `uitk` | 6.438 | 0,11 GB | muy alta para UI declarativa |

## Extensiones observadas

| Extensión | Cantidad | Interpretación inicial |
|---|---:|---|
| `.ogg` | 30.458 | audio y efectos |
| `.png` | 14.988 | iconos, texturas, atlas o UI |
| `.a2d` | 14.473 | formato específico que requiere investigación |
| `.webp` | 12.777 | imágenes/recursos optimizados |
| `.json` | 9.302 | manifests, metadatos o schemas |
| `.jpg` | 1.217 | imágenes |
| `.css` | 384 | estilos y UI |
| `.d2p` | 220 | paquetes de contenido |
| `.d2o` | 194 | datos binarios |
| `.xml` | 25 | configuración o datos |
| `.ttf` | 15 | fuentes |
| `.d2i` | 7 | índices o datos |

La extensión `.a2d` debe investigarse primero con inventario de cabecera,
tamaño, hash y referencias, sin publicar su contenido. No asumir que es un
formato documentado.

## UI analizada

`ui_analysis.json` contiene, según la auditoría local:

```text
element_types: 104
element_names: 6921
class_selectors: 555
data_uss_names: 348
```

Esto confirma que la UI puede estudiarse como un sistema de:

```text
tipo de elemento
  -> nombre/ID
  -> clase/selectores
  -> estilo
  -> pantalla o composición
```

La prioridad no es copiar 6.921 nombres, sino clasificar:

1. componentes base;
2. ventanas;
3. controles;
4. listas y grids;
5. tooltips;
6. HUD;
7. combate;
8. mapa;
9. accesibilidad y estados;
10. clases de tema.

## Audio y animaciones de hechizos

La presencia de `d3audio`, `d3fx` y `d3spells` confirma que hay que separar
tres problemas:

```text
identidad del hechizo
  -> evento semántico
  -> timeline visual
  -> cue de audio
```

No basta con asociar un icono a un hechizo. Para avanzar rápido hay que
catalogar, sin extraer recursos:

```text
spell_id
class/breed
cast event
impact event
affected cells
animation duration
projectile or area
sound cue category
cancel/interruption rules
```

Primera implementación propia recomendada:

```json
{
  "spellId": "placeholder.fire",
  "events": [
    { "type": "cast-start", "animation": "cast-basic" },
    { "type": "projectile", "animation": "projectile-basic" },
    { "type": "impact", "animation": "impact-basic", "sound": "impact-basic" }
  ]
}
```

Este JSON es un contrato DreamFus, no una copia del formato de Alea.

## Datos de mapa y mundo

`d3maps`, `d3world` y `d3worldmap` justifican crear tres capas separadas:

```text
MapGeometry
  celdas, alturas, caminabilidad, visibilidad

MapPresentation
  capas visuales, texturas, decoraciones, interactivos

WorldNavigation
  vecinos, conexiones inter-mapa, puntos de entrada y salida
```

No usar el nombre de una carpeta como prueba del schema. Cada formato debe
tener fixtures sintéticos y tests de lectura propios.

## Metadatos de contenido

`.alea-content.json` contiene hashes y tamaños de contenido local. Es útil para:

- detectar cambios de versión;
- identificar qué grupo cambió;
- invalidar una caché;
- comparar dos instalaciones;
- saber si una auditoría está completa.

No se deben publicar rutas personales, hashes de cuentas, tokens ni listados
que revelen contenido redistribuible.

## Próximas auditorías seguras

### A. UI

- contar documentos JSON por subcarpeta;
- detectar campos `type`, `children`, `style`, `class`, `name`;
- generar solo un catálogo de schemas y conteos;
- mapear componentes a DFUI propio.

### B. Hechizos

- listar nombres de archivos y tamaños;
- identificar si existen manifests;
- agrupar por clase o categoría;
- buscar referencias a `spell`, `effect`, `timeline`, `animation`;
- no convertir imágenes o audio en parte del repo.

### C. Audio

- agrupar OGG por carpeta y prefijo;
- registrar duración y sample rate solo como metadatos;
- clasificar UI, ambiente, música y combate;
- diseñar buses propios.

### D. Efectos

- identificar manifest o índices;
- clasificar partículas, proyectiles, impactos y estados;
- crear placeholders y timelines propios.

### E. Fuentes

- registrar familia, peso y estilo;
- comprobar fallback y legibilidad;
- no redistribuir TTF/OTF sin permiso.

## Resultado

La instalación local sí contiene información suficiente para avanzar en:

1. arquitectura de UI;
2. catálogo de componentes;
3. 9-slice y layout;
4. inventario visual;
5. contratos de hechizos;
6. timelines de efectos;
7. buses de audio;
8. mapas y mundo;
9. localización y fuentes;
10. estrategia de carga y caché.

La forma segura de usarla es como fuente de observaciones y metadatos, mientras
DreamFus implementa sus propios componentes, formatos y assets.

