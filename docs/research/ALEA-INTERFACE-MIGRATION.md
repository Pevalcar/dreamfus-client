# Plan de migración de interfaces de Alea a DreamFus

## Decisión de alcance

El propietario del proyecto ha indicado que dispone de permiso para utilizar
los recursos de Alea y, cuando sea necesario, del cliente WebClient. Esta
declaración permite planificar una migración completa, pero no sustituye la
identificación de la licencia o autorización concreta de cada recurso.

Antes de subir cualquier recurso al repositorio hay que conservar, fuera del
árbol publicado si contiene datos privados, una referencia verificable de:

```text
proveedor o titular
alcance del permiso
versiones cubiertas
recursos cubiertos
derecho de modificación
derecho de redistribución
fecha y persona que autoriza
restricciones de atribución
```

Los recursos sin esa trazabilidad se pueden usar localmente para comparar y
medir, pero no se incorporan al build ni se suben a GitHub.

## Objetivo

Recrear en DreamFus la experiencia de las interfaces de Alea con el renderer
Tauri/DFUI existente, conservando:

- jerarquía visual;
- proporciones y escalas;
- estados de interacción;
- ventanas modales y arrastrables;
- navegación por teclado;
- tooltips;
- grids y listas;
- composición del HUD;
- transiciones y sonidos;
- relación entre datos del servidor y presentación.

La migración no debe copiar a ciegas la arquitectura Unity. El resultado debe
seguir separado en:

```text
datos del servidor
  -> estado de dominio DreamFus
  -> modelo de presentación
  -> definición DFUI
  -> renderer Tauri
  -> input y accesibilidad
```

## Inventario que se debe construir

### Fundación visual

| Grupo | Resultado DreamFus |
|---|---|
| colores y tokens | `theme.dfss` propio y variantes |
| tipografías | registro de fuentes y fallback |
| escalas | tokens de resolución y densidad |
| bordes | definiciones 9-slice verificadas |
| sombras | tokens y reglas de composición |
| iconos | catálogo por función y estado |
| audio UI | eventos semánticos y buses |

### Componentes

| Componente observado | Componente DFUI |
|---|---|
| `WindowFigma` | `WindowFigma` |
| `DofusLabel` | `DofusLabel` |
| `DofusButtonCustom` | `DofusButtonCustom` |
| `DofusTab`/`DofusTabGroup` | `DofusTab`/`DofusTabGroup` |
| `SlotGrid` | `SlotGrid` |
| slot de objeto | `Slot` |
| lista virtualizada | `ListView` |
| fila | `ListItem` |
| tooltip | `Tooltip` |
| barra de acción | `ActionBar` |
| panel de mapa | `WorldMap` |
| celda táctica | `TacticalCell` |

Cada componente debe documentar:

```text
id estable
atributos
props de datos
estados
eventos
teclado
focus
montaje
desmontaje
capas
input que consume
fallback sin assets
```

## Orden de implementación

### Fase 0 — derechos e inventario

1. Registrar versión de Alea y del WebClient.
2. Guardar la evidencia de autorización fuera del repositorio público si es
   confidencial.
3. Generar conteos, hashes, dimensiones y relaciones sin copiar contenido.
4. Marcar cada recurso como `licensed`, `original`, `placeholder` o
   `unverified`.
5. Bloquear en el build cualquier categoría `unverified`.

### Fase 1 — fundación DFUI

1. Validar el schema `t/a/s/c/k/w/h`.
2. Separar tema, componentes, pantallas y estado.
3. Completar ventanas, botones, etiquetas, tabs, grids y listas.
4. Corregir carga explícita de `components.dfui` y `theme.dfss`.
5. Verificar estados `loading`, `empty`, `error`, `disabled`, `hover`,
   `pressed`, `focused` y `selected`.
6. Probar 9-slice con fixtures propios y, únicamente si está autorizado,
   con los recursos finales.

### Fase 2 — pantallas fuera de combate

1. Login.
2. Selección de servidor.
3. Selección de personaje.
4. Creación y eliminación de personaje.
5. Carga del mundo.
6. HUD y chat.
7. Inventario, equipamiento y tooltip.
8. Mapa global y navegación.

### Fase 3 — mundo y entidades

1. Capas de mapa.
2. Celdas caminables y bloqueadas.
3. Personajes, monstruos, NPC e interactivos.
4. Selección, hover y contexto.
5. Animaciones de aparición, movimiento y desaparición.
6. Carga progresiva y cancelación al abandonar el mapa.

### Fase 4 — combate

1. Estado de preparación.
2. Timeline de turnos.
3. Celdas tácticas.
4. Previsualización de movimiento.
5. Previsualización de hechizos.
6. Barra de acción.
7. Animación de lanzamiento, proyectil, impacto y efecto.
8. Sonidos, interrupciones y reconciliación con el servidor.

### Fase 5 — recursos finales

Solo después de que los contratos y tests funcionen:

1. sustituir placeholders por recursos autorizados;
2. importar atlas y recortes;
3. importar fuentes;
4. importar audio;
5. importar animaciones;
6. generar manifests de empaquetado;
7. verificar tamaño, caché y actualización.

## Cadena de una interfaz

Cada pantalla se documentará con esta ficha:

```yaml
screen: inventory
source:
  product: Alea
  version: 0.1.0+4a8328d5
  evidence: local-audit
rights: declared-by-owner
mount:
  layer: world-overlay
  parent: ui-root
  visible_states: [world, combat]
components:
  - id: inventory-window
    type: WindowFigma
    movable: true
  - id: inventory-grid
    type: SlotGrid
states: [loading, empty, ready, error]
events: [open, close, select-item, equip]
assets:
  status: pending-license-evidence
tests:
  - opens-without-map-click
  - closes-and-removes-listeners
  - survives-map-refresh
```

## Regla de importación

No usar una carpeta de Alea directamente como `/assets` del cliente. El
importador debe:

1. leer una ruta local explícita;
2. validar la autorización del recurso;
3. transformar a un formato DreamFus estable;
4. generar un manifest con origen, hash y licencia;
5. copiar solo los archivos autorizados;
6. producir un informe;
7. fallar explícitamente ante recursos sin clasificación.

El build debe funcionar también sin la instalación local de Alea. Los tests
usan fixtures pequeños y los assets finales se validan en una etapa separada.

## Qué no debe hacerse

- copiar `client-patched`, `d3pack` o `dofus-base` completos;
- poner bundles o binarios oficiales bajo `frontend/public`;
- mezclar datos de presentación con datos autoritativos del servidor;
- usar IDs de Alea como contrato sin comprobar versión;
- mantener listeners globales después de desmontar una pantalla;
- ocultar errores de carga con una interfaz que parece válida;
- afirmar que una interfaz está terminada solo porque coincide visualmente;
- publicar la evidencia privada de la autorización.

## Verificación por pantalla

Una pantalla se considera migrada cuando:

1. aparece en la capa correcta;
2. respeta la escala y el tema;
3. se puede abrir y cerrar repetidamente;
4. no deja listeners ni nodos huérfanos;
5. el clic y la rueda no llegan al mapa cuando la pantalla es propietaria;
6. el teclado y el foco tienen un comportamiento definido;
7. loading, empty, error y disabled son visibles;
8. el cambio de mapa o combate no la deja en estado inválido;
9. los datos son del jugador autenticado;
10. existe un fixture y una prueba automatizada;
11. la prueba visual en juego o preview está registrada;
12. cada recurso tiene origen y clasificación de derechos.

## Próximo entregable técnico

La primera implementación debe ser la fundación DFUI, no la copia masiva de
assets. Después se puede migrar la selección de personaje como pantalla
vertical completa, porque prueba:

- ventana;
- fondo y 9-slice;
- texto;
- botones;
- lista;
- selección;
- estados de carga y error;
- navegación hacia el mundo.

