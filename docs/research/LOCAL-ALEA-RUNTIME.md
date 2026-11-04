# Runtime local basado en una instalación de Alea

## Propósito

DreamFus se puede ejecutar junto a una instalación local autorizada de Alea y
usar sus recursos en tiempo de ejecución. Esto permite desarrollar y probar
rápidamente sin subir al repositorio los recursos grandes.

El objetivo de distribución es:

```text
instalación local autorizada/
├── d3audio/
├── d3fx/
├── d3items/
├── d3maps/
├── d3pack/
├── d3picto/
├── d3spells/
├── d3ui/
├── d3world/
├── d3worldmap/
├── dofus-base/
├── uitk/
├── client-patched/
├── servidor de prueba/
└── DreamFusLauncher.exe
```

El launcher de DreamFus debe poder colocarse en esa carpeta y recibir una ruta
explícita a la instalación. No se debe reemplazar ni modificar el ejecutable
original automáticamente: el launcher propio debe tener su nombre, su
configuración y su proceso de actualización.

## Estado actual

La implementación actual **todavía no hace este descubrimiento**. Hoy:

| Superficie | Estado actual | Consecuencia |
|---|---|---|
| 9-slice | `SliceManager` genera URLs `/assets/ui/...` | no lee todavía `d3ui` |
| DFUI | carga desde `frontend/public/dfui` | funciona sin Alea |
| pantallas | carga `/ui/*.dfui` del bundle | no carga UXML/JSON externo |
| audio | no hay proveedor runtime de Alea | no reproduce `d3audio` |
| mapas | no hay cargador externo | no lee `d3maps` |
| hechizos/efectos | no hay catálogo runtime | no lee `d3spells`/`d3fx` |
| fuentes | no hay registro externo | no lee `uitk` |
| bundles/binarios | no se cargan | no se deben exponer al WebView |
| launcher | no descubre ni inicia servidor | requiere implementación separada |

Por tanto, el objetivo descrito aquí es un contrato de implementación, no una
afirmación de que ya esté conectado.

## Modos de ejecución

### 1. Desarrollo sin instalación externa

Usa fixtures y placeholders versionados:

```text
frontend/public/dfui/
frontend/public/ui/
frontend/public/assets/  (solo placeholders permitidos)
```

Este modo debe funcionar en CI y para colaboradores que no tienen Alea.

### 2. Desarrollo con instalación local

El launcher o la aplicación recibe:

```text
DREAMFUS_ALEA_ROOT=C:\ruta\de\la\instalacion
DREAMFUS_SERVER_ROOT=C:\ruta\del\servidor-de-pruebas
```

Como alternativa, el launcher puede leer un archivo local ignorado por Git:

```json
{
  "assetRoot": "C:\\ruta\\de\\la\\instalacion",
  "serverRoot": "C:\\ruta\\del\\servidor-de-pruebas",
  "mode": "local-reference"
}
```

El archivo real nunca se versiona. El repositorio solo puede incluir un
ejemplo sin rutas personales.

### 3. Distribución colaborativa

La aplicación se distribuye sin recursos de Alea cuando esos recursos no
puedan redistribuirse legalmente. El primer arranque debe mostrar un error
explícito si falta la instalación autorizada:

```text
No se encontró la instalación local autorizada.
Configura assetRoot o instala los recursos permitidos.
```

No se debe activar silenciosamente el modo mock como si los recursos fueran
válidos.

## Resolución de carpetas

La resolución debe seguir este orden:

1. ruta indicada por configuración explícita;
2. `DREAMFUS_ALEA_ROOT`;
3. carpeta donde está el launcher, si contiene los marcadores esperados;
4. modo sin instalación externa, solo para desarrollo.

Nunca se debe buscar recursivamente todo el disco. Una instalación válida debe
comprobar al menos:

```text
d3ui
d3audio
d3maps
d3spells
uitk
.alea-content.json
```

El resultado debe ser un manifiesto de runtime:

```json
{
  "root": "local-only",
  "version": "0.1.0+4a8328d5",
  "complete": true,
  "folders": {
    "ui": "d3ui",
    "audio": "d3audio",
    "maps": "d3maps",
    "spells": "d3spells",
    "effects": "d3fx",
    "items": "d3items",
    "world": "d3world",
    "worldMap": "d3worldmap",
    "toolkit": "uitk",
    "packages": "d3pack"
  }
}
```

La aplicación no debe mostrar la ruta absoluta en telemetría ni incluirla en
logs públicos.

## Mapa de proveedores

El renderer no debe construir rutas de Alea por toda la aplicación. Debe usar
un proveedor único:

```text
AssetCatalog
  resolve(kind, id)
  openImage(kind, id)
  openAudio(kind, id)
  openFont(id)
  openMap(id)
  openBundle(id)
```

| Categoría | Carpeta de referencia | Consumidor DreamFus |
|---|---|---|
| UI y estilos | `d3ui`, `uitk` | DFUI/theme |
| audio | `d3audio` | `AudioService` |
| efectos | `d3fx` | `EffectCatalog` |
| hechizos | `d3spells` | `SpellPresentation` |
| objetos | `d3items` | `ItemIconProvider` |
| mapas | `d3maps` | `MapRenderer` |
| mundo | `d3world` | `EntityRenderer` |
| mapa global | `d3worldmap` | `WorldMapRenderer` |
| iconografía | `d3picto` | `IconProvider` |
| paquetes | `d3pack` | importador controlado |
| base empaquetada | `dofus-base` | solo si el permiso lo cubre |
| cliente parcheado | `client-patched` | no exponer directamente al WebView |

El código de gameplay recibe IDs y datos del servidor; no recibe rutas
absolutas ni nombres de archivos de Alea.

## Seguridad del acceso desde Tauri

El WebView no debe recibir acceso ilimitado al disco. El diseño correcto es:

```text
Tauri/Rust
  -> valida root y path relativo
  -> rechaza `..`, rutas absolutas y enlaces fuera del root
  -> expone solo una URL/proveedor de asset permitido
WebView
  -> solicita un recurso por id
```

No se debe permitir que una pantalla DFUI convierta un atributo arbitrario en
una ruta local. Los bundles, ejecutables, DLLs y archivos del servidor nunca
deben ser entregados como contenido directo al DOM.

## Arranque del servidor local

El launcher puede iniciar un servidor de pruebas solo si:

1. `serverRoot` está configurado explícitamente;
2. el ejecutable coincide con una lista permitida;
3. el proceso se inicia con argumentos documentados;
4. la base de pruebas está aislada;
5. los logs se guardan fuera del repositorio;
6. el usuario puede detenerlo;
7. no se toca una instalación con jugadores conectados.

No se debe ejecutar automáticamente cualquier `.exe` encontrado en la carpeta
de Alea. La ruta de servidor y el nombre del ejecutable deben estar declarados
en la configuración local.

Ejemplo conceptual:

```json
{
  "serverRoot": "C:\\ruta\\servidor-pruebas",
  "serverExecutable": "Jondo.Unity.Server.exe",
  "serverArguments": [],
  "serverPort": 5555,
  "database": "C:\\ruta\\servidor-pruebas\\bases\\world-test.db"
}
```

La base de pruebas nunca se comparte mediante GitHub ni se sustituye por una
base con progreso real.

## Flujo de lanzamiento deseado

```text
DreamFusLauncher.exe
  -> lee configuración local
  -> valida instalación y permisos
  -> genera runtime-manifest efímero
  -> inicia servidor de prueba si está habilitado
  -> inicia DreamFusClient.exe
  -> entrega solo el endpoint y el catálogo de assets
  -> espera conexión y muestra estado
```

Al cerrar:

```text
cliente
  -> cierra conexión
  -> guarda preferencias locales
launcher
  -> detiene únicamente el proceso que inició
  -> conserva logs locales
```

## AI handoff: reglas para futuras IAs

Antes de modificar una pantalla o renderer:

1. leer este documento;
2. comprobar si el cambio funciona sin Alea;
3. localizar el proveedor `AssetCatalog`, no crear una ruta directa;
4. registrar carpeta, versión e ID observado;
5. separar dato servidor/presentación;
6. comprobar derechos del recurso;
7. añadir fixture o placeholder;
8. probar missing asset, invalid asset y asset válido;
9. verificar que el WebView no obtiene acceso arbitrario al disco;
10. documentar la prueba local sin publicar la ruta personal.

Una futura IA no debe:

- asumir que `/assets` ya representa Alea;
- copiar una instalación completa;
- incluir binarios, bundles o bases en un commit;
- iniciar ejecutables no declarados;
- convertir nombres de archivo en protocolo;
- ocultar errores de recursos con mock;
- sustituir la configuración local de otro colaborador.

## Criterios de aceptación

El runtime se puede considerar listo cuando:

- una instalación externa válida se detecta por sus marcadores;
- cada categoría usa `AssetCatalog`;
- una pantalla puede renderizar UI, fuente, icono, audio y animación desde el
  catálogo;
- el modo sin Alea sigue funcionando con fixtures;
- una ruta inválida falla con un mensaje claro;
- el WebView no puede leer fuera del root permitido;
- el launcher no inicia procesos no declarados;
- el servidor de pruebas usa una base aislada;
- el paquete colaborativo no incluye recursos no redistribuibles;
- existe una prueba de arranque y otra de ausencia de recursos.

