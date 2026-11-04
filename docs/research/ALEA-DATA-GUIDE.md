# Guía de datos de Alea para DreamFus

## 1. Propósito

El cliente actual usa una instalación local de Alea como fuente temporal de
referencias visuales y estructurales. Esta guía describe qué conviene
catalogar, qué se puede aprender rápidamente y qué no se debe copiar ni
redistribuir.

La instalación de Alea no forma parte del repositorio. El repositorio debe
contener únicamente:

- código propio;
- schemas propios;
- metadatos generados sin contenido propietario;
- capturas o fixtures creados por nosotros;
- documentación de observaciones;
- assets originales o con licencia compatible.

## 2. Qué puede contener una instalación de un cliente moderno

La estructura exacta depende de la versión y del instalador. No asumir que
todos los nombres existen. Auditar el directorio real y registrar versión,
hashes y fecha.

| Grupo | Ejemplos de datos | Uso para DreamFus |
|---|---|---|
| UI declarativa | UXML, JSON, `uxml`, documentos de árbol | descubrir jerarquía, componentes y estados |
| Estilos | USS, CSS, DFSS | tokens, escalas, estados, layout y temas |
| Manifests | `manifest.json`, `d3ui` | ids, rutas, tamaños, 9-slice, dependencias |
| Imágenes | PNG, atlas, spritesheets, iconos | estudiar categorías y contratos del renderer |
| Fuentes | TTF, OTF, WOFF | métricas tipográficas y fallback |
| Animación | clips, timelines, atlas, JSON | fases, nombres y sincronización |
| Audio | música, efectos, bancos | categorías y eventos de sonido |
| Localización | JSON, CSV, tablas | ids de texto, pluralización y fallback |
| Datos de juego | mapas, entidades, efectos, hechizos | modelar schemas; no redistribuir dumps propietarios |
| Configuración | endpoints, flags, versiones | matriz de compatibilidad; eliminar secretos |
| Binarios | assemblies, bundles, ejecutables | solo identificar versión/hash; no copiar al repo |

## 3. Datos UI que ya contempla DreamFus

### 3.1. Componentes tipo UXML

`frontend/src/dfui/index.js` ya tiene un registro inspirado en componentes de
UI Toolkit:

```text
WindowFigma
DofusVisualElement
VisualElement
DofusLabel
Label
TextInput
DofusButtonCustom
DofusTab
DofusTabButton
SlotGrid
Slot
ListView
ListItem
```

El objetivo de esta lista no es fingir compatibilidad con Alea. Cada componente
debe tener una implementación propia y documentar:

```text
tipo externo observado
tipo DFUI propio
elemento HTML generado
atributos admitidos
eventos
estados
accesibilidad
```

### 3.2. Atributos de documentos

El renderer actual usa conceptos como:

```text
t   tipo de componente
a   atributos
s   estilo inline
c   clases
k   hijos
w   ancho
h   alto
```

Un schema propio debe validar estos campos antes de renderizar. No enviar
atributos desconocidos directamente al DOM sin sanitización.

### 3.3. Estilos y temas

DFUI carga:

```text
/dfui/components.dfui
/dfui/theme.dfss
```

La separación recomendada es:

```text
component definitions
    estructura y estilos locales

theme
    colores, fuentes, escalas y tokens

screen
    composición de componentes

state
    datos y estados de interacción
```

Crear temas propios:

```text
themes/dreamfus-default
themes/dreamfus-dark
themes/dreamfus-high-contrast
```

## 4. 9-slice y ventanas escalables

`frontend/src/SliceManager.js` ya contiene un adaptador conceptual para
definiciones de 9-slice:

```text
[top, right, bottom, left]
```

Lo que conviene extraer de un manifest local, sin copiar imágenes:

```text
asset id
source path relativo
slice top/right/bottom/left
modo de repetición
modo de relleno
anchura mínima
altura mínima
componentes que lo usan
```

El resultado permitido en el repositorio puede ser un schema o fixture
sintético:

```json
{
  "id": "window.dialog",
  "slice": [8, 8, 8, 8],
  "repeat": "stretch",
  "asset": "original-placeholder"
}
```

No añadir la imagen extraída ni reconstruir un atlas propietario.

## 5. Qué auditar para avanzar rápido

La auditoría local debe responder:

### UI

- ¿Cuántas pantallas hay?
- ¿Qué componentes se repiten?
- ¿Qué ventanas son modales?
- ¿Qué elementos son arrastrables?
- ¿Qué estados tienen botones, tabs y listas?
- ¿Qué dimensiones y escalas se usan?
- ¿Qué reglas de foco y teclado aparecen?

### Assets

- ¿Qué ids se usan en la UI?
- ¿Qué assets son fondos, bordes, iconos, estados o cursores?
- ¿Qué imágenes son atlas?
- ¿Qué metadatos de recorte existen?
- ¿Qué recursos tienen variantes por tema, resolución o idioma?

### Texto

- ¿Qué ids de localización usa cada pantalla?
- ¿Cómo se resuelven textos faltantes?
- ¿Hay pluralización o género?
- ¿Qué longitud máxima debe soportar cada control?

### Animación y audio

- ¿Qué eventos semánticos disparan cada animación?
- ¿Qué animaciones pueden interrumpirse?
- ¿Qué efectos son UI y cuáles son mundo/combate?
- ¿Qué sonidos tienen volumen o bus independiente?

### Datos de juego

- ¿Qué formato tienen mapas y celdas?
- ¿Qué ids relacionan entidades con visuales?
- ¿Qué datos son solo de presentación?
- ¿Qué datos deben venir obligatoriamente del servidor?

## 6. Inventario seguro

Crear un inventario fuera del repositorio o en un archivo sin contenido
propietario con este formato:

```text
version:
install_root: [ruta local, nunca una ruta de usuario real publicada]
date:
file_count:
total_size:
categories:
manifest_names:
ui_document_count:
style_document_count:
font_count:
audio_count:
animation_count:
localization_count:
notes:
```

Para cada archivo se puede registrar únicamente:

```text
relative category
extension
size
sha256
dimensions si es una imagen
referencias desde manifests
```

No registrar en GitHub:

- nombres de usuario;
- rutas absolutas personales;
- tokens;
- cuentas;
- payloads de red;
- binarios;
- contenido completo de assets.

## 7. Pipeline recomendado

```text
instalación Alea local
    -> auditoría read-only
    -> inventario de metadatos
    -> schemas sintéticos
    -> componentes DreamFus propios
    -> placeholders propios
    -> tests de render
```

La auditoría nunca debe ser un paso de build del cliente. El build debe poder
funcionar en una máquina sin Alea.

## 8. Prioridad de implementación

### P0

1. Validar documentos DFUI.
2. Separar tema, componentes y pantallas.
3. Implementar Window, Label, Button, Tab, SlotGrid y ListView.
4. Corregir 9-slice con fixtures sintéticos.
5. Añadir estados de loading, empty, error y disabled.

### P1

1. Inspector de documentos.
2. Preview de pantalla.
3. Exportación de inventario de metadatos.
4. Localización.
5. fuentes con fallback y escalado.
6. sistema de iconos y atlas propio.

### P2

1. renderer de mapa;
2. entidades;
3. animaciones semánticas;
4. audio buses;
5. temas;
6. actualización de assets propios.

## 9. Qué más puede aportar Alea como referencia

Aunque no usemos sus assets, una instalación puede ayudar a descubrir:

- convenciones de nombres;
- separación de pantallas;
- estados visuales;
- escalas y densidad;
- composición de ventanas;
- orden de capas;
- relación entre ids de UI y recursos;
- organización de localización;
- ciclo de vida de escenas;
- puntos de entrada del cliente;
- categorías de mensajes visibles;
- qué debe precargarse y qué puede cargarse bajo demanda.

Estas observaciones deben transformarse en contratos propios, no en
dependencias del cliente instalado.

