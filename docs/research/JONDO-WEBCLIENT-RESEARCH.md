# Investigación de Jondo.Unity.WebClient

## Fuente revisada

- Repositorio: https://github.com/leonardo-spy/Jondo.Unity.WebClient
- Rama consultada: `master`
- Commit consultado: `357acb8444bfa4ba8fc4f7cd63b0691114c2c87f`
- Cliente indicado: 3.6.10.11
- Descripción: cliente Unity IL2CPP ejecutado en WebGL y conectado al emulador
  mediante WebSocket.

La consulta pública mostró un repositorio con `README.md`, `Decompiled/`,
`Generated/`, `LiveDofusDump/`, `Tools/`, `Scripts/`, `UnityProject/`,
`WebServer/` y documentación de automatización.

## Qué puede aportar al cliente Tauri

No es necesario portar el proyecto Unity completo. Sus partes más útiles como
referencia son:

### 1. Flujo de sesión

El README describe un flujo validado:

```text
Login
  -> ServerSelection
  -> CharacterSelection
  -> World Map
```

Esto sirve para comparar nuestro modelo de estados y decidir qué mensajes,
pantallas y cargas deben existir en DreamFus.

### 2. UI declarativa real

El proyecto documenta pantallas UXML reales y sus bindings. Para DreamFus esto
permite estudiar:

- composición de una pantalla;
- nombres de controles;
- relación entre texto, fuente y tema;
- interacción del botón principal;
- estados de carga y selección.

Debe usarse como observación. No copiar UXML, fuentes, texturas ni estilos
oficiales al cliente DreamFus.

### 3. Mapa

El README describe un mapa con:

```text
5.196 vértices
3 submeshes
3 materiales
560 celdas
320 caminables
```

Estos números son útiles como hipótesis de una versión concreta, no como
contrato universal. El cliente DreamFus debe obtener su geometría de datos
compatibles con su servidor y cubrirla con tests.

### 4. HUD y combate futuro

Se mencionan HUD, información de personaje, HP/AP/MP, barra de acciones y
spells/items. Esto refuerza el diseño de `GAME-SYSTEMS.md`:

```text
WorldLayer
  -> map
  -> entities
HudLayer
  -> character information
  -> action bar
CombatLayer
  -> cells
  -> targeting
  -> timeline
```

### 5. Audio

El README menciona FMOD y eventos de sonido de UI. Es una referencia útil para
definir categorías y buses propios:

```text
music
effects
ui
ambience
combat
```

No se deben copiar bancos FMOD, eventos o audio propietario.

### 6. Datos generados y decompilación

El repositorio organiza información en capas:

```text
dump.cs
decompiled_all.c
Cpp2IL DLLs
Generated/
transcribed/
```

La idea útil para DreamFus es la trazabilidad:

```text
fuente observada
  -> hallazgo
  -> contrato neutral
  -> implementación propia
  -> test
```

No se debe convertir una decompilación de código oficial en código fuente
redistribuido dentro de DreamFus.

## ¿Conviene usar un decompilador?

Sí, pero con un alcance controlado:

### Conviene usarlo para

- identificar nombres y relaciones de componentes;
- descubrir qué eventos visuales existen;
- comprender el ciclo de vida de una pantalla;
- catalogar bindings y estados;
- observar cómo se relacionan spell, effect, animation y sound;
- confirmar formatos y tamaños de estructuras;
- comparar comportamiento con una instalación autorizada;
- generar documentación neutral y tests propios.

### No conviene usarlo para

- copiar cuerpos de métodos propietarios;
- extraer y redistribuir clases oficiales;
- incluir DLLs, GameAssembly, bundles o assets en DreamFus;
- reconstruir un cliente oficial con branding y contenido original;
- interceptar cuentas o tráfico real;
- publicar dumps de usuarios.

## Herramientas y áreas del repositorio de referencia

| Área | Utilidad para DreamFus | Tratamiento |
|---|---|---|
| `Decompiled/` | entender estructuras y métodos | solo lectura e investigación |
| `Generated/` | ejemplos de índices y trazabilidad | no copiar datos propietarios |
| `Tools/ClientAnalyzer` | idea de análisis automático | implementar auditoría propia |
| `Tools/ExtractThemeColors` | extraer metadatos de tema | adaptar solo a fixtures propios |
| `Scripts/` | automatización de pipeline | revisar licencia y reescribir lo necesario |
| `UnityProject/` | entender capas de escena | no convertirlo en dependencia Tauri |
| `WebServer/` | proxy WebSocket y pruebas | estudiar contratos y errores |
| `Screenshots/` | validar flujo visual | no usar como assets del cliente |

## Puntos que deben verificarse antes de reutilizar

1. El listado público consultado no mostró un archivo `LICENSE` en la raíz.
2. La ausencia de una licencia explícita significa que no debemos copiar código
   automáticamente.
3. El proyecto mezcla código propio con datos y recursos de un cliente oficial.
4. Cada archivo necesita revisión de procedencia, licencia y finalidad.
5. La URL y el commit deben conservarse en la documentación de la investigación.

## Plan de uso recomendado

### Fase 1: comparar contratos

- comparar login;
- selección de servidor;
- selección de personaje;
- carga de mapa;
- carga de entidades;
- HUD;
- action bar.

### Fase 2: investigar efectos

- localizar relaciones entre hechizo, efecto y animación;
- registrar nombres neutrales;
- crear `SpellTimeline` propio;
- implementar un hechizo placeholder.

### Fase 3: investigar sonido

- clasificar eventos semánticos;
- crear buses de audio propios;
- usar sonidos originales DreamFus;
- probar cancelación al cambiar de escena.

### Fase 4: crear inspector

- inspeccionar schemas propios;
- visualizar timeline;
- reproducir replay;
- mostrar qué dato proviene del servidor y cuál es presentación.

## Conclusión

`Jondo.Unity.WebClient` puede acelerar mucho la investigación y la
verificación de flujos, sobre todo para UI, mapas, HUD, audio y la relación
entre subsistemas. No debe convertirse en una dependencia ni en una fuente de
código copiado. La arquitectura correcta es estudiar sus observaciones y
reimplementar el cliente DreamFus con Rust/Tauri, DFUI propio, assets propios y
contratos de protocolo documentados.

