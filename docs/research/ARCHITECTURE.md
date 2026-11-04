# Arquitectura del cliente

## 1. Diagnóstico de la base actual

La base actual tiene una separación razonable:

```text
src/lib.rs
    conexión TCP, framing, envelope y comandos Tauri

frontend/src/protocol.js
    puente entre la interfaz y los comandos/eventos Tauri

frontend/src/EventBus.js
    distribución de eventos de servidor y de UI

frontend/src/dfui/index.js
    renderizado de UI basada en documentos

frontend/src/ui/UIManager.js
frontend/src/ui/screens/
    pantallas y transición entre pantallas
```

Puntos fuertes:

1. Tauri permite colocar las operaciones nativas y la red en Rust.
2. DFUI permite cambiar estructura y estilo de la interfaz sin acoplar cada
   pantalla al transporte.
3. `EventBus` evita que cada pantalla conozca directamente la implementación
   TCP.
4. El modo mock permite desarrollar pantallas sin servidor.

Puntos que deben resolverse antes de ampliar el cliente:

1. El lector TCP no debe mantener un `Mutex` bloqueado mientras espera datos.
2. Lectura y escritura deben tener ownership y cancelación independientes.
3. El parser de envelope debe tener tests de bytes, no solo pruebas manuales.
4. El modo mock no debe ocultar un fallo de conexión real.
5. El estado debe distinguir `Connecting`, `Authenticating`, `InWorld`,
   `InFight`, `Reconnecting` y `Failed`.
6. El frontend debe recibir mensajes decodificados y validados, no bytes
   arbitrarios sin un contrato.

## 2. Estructura objetivo

```text
src/
├── commands/
│   └── mod.rs
├── connection/
│   ├── manager.rs
│   ├── reader.rs
│   ├── writer.rs
│   └── state.rs
├── protocol/
│   ├── framing.rs
│   ├── envelope.rs
│   ├── opcodes.rs
│   ├── encoder.rs
│   ├── decoder.rs
│   └── messages/
├── domain/
│   ├── account.rs
│   ├── character.rs
│   ├── map.rs
│   ├── entity.rs
│   ├── inventory.rs
│   └── fight.rs
├── persistence/
│   ├── settings.rs
│   ├── profiles.rs
│   └── credentials.rs
└── lib.rs

frontend/src/
├── app/
│   ├── AppState.js
│   ├── ConnectionState.js
│   └── commands.js
├── protocol/
│   ├── client.js
│   ├── messageSchemas.js
│   └── replay.js
├── state/
│   ├── store.js
│   ├── reducers/
│   └── selectors/
├── renderer/
│   ├── world/
│   ├── entities/
│   ├── combat/
│   └── animation/
├── dfui/
├── ui/
│   ├── components/
│   ├── layouts/
│   ├── screens/
│   └── themes/
└── main.js
```

La estructura no debe implementarse toda de golpe. Es un mapa de destino para
evitar volver a concentrar toda la aplicación en `lib.rs`, `protocol.js` o
`main.js`.

## 3. Conexión TCP

### Diseño recomendado

```text
connect()
    └── ConnectionManager
          ├── TcpStream::split()
          ├── reader task -> inbound channel -> decoder -> Tauri events
          └── writer task <- outbound channel <- Tauri command
```

El lector nunca debe conservar el lock del estado mientras hace una operación
bloqueante. El escritor debe recibir mensajes por un canal. El estado de
conexión debe estar separado del socket para que `disconnect` pueda cancelar
la lectura.

### Estados

```text
Disconnected
Connecting
Connected
Authenticating
Authenticated
LoadingCharacters
SelectingCharacter
LoadingWorld
InWorld
InFight
Reconnecting
Disconnecting
Failed
```

Cada transición debe tener:

- estado anterior;
- evento que la provoca;
- condición de entrada;
- acción de salida;
- error visible si no puede realizarse.

### Modos de ejecución

El cliente debe distinguir expresamente:

```text
real       conexión TCP real
mock       mensajes sintéticos para desarrollo
replay     sesión previamente grabada
```

El modo real nunca debe cambiar silenciosamente a mock. Si se usa un fallback
en desarrollo, la pantalla debe mostrar una marca inequívoca `MOCK`.

## 4. Contrato de mensajes

Cada mensaje debe tener, como mínimo:

```text
opcode
direction
protocol_version
request_id o correlation_id, si aplica
payload
```

Se recomienda un catálogo versionado:

```text
protocol/
├── v1/
│   ├── opcodes.json
│   └── messages/
└── v2/
```

Para cada opcode documentar:

| Campo | Descripción |
|---|---|
| Nombre | Identificador del mensaje |
| Dirección | Cliente → servidor, servidor → cliente o respuesta |
| Momento | Estado en el que puede aparecer |
| Payload | Campos, tipos, rangos y opcionalidad |
| Efecto | Qué cambia en el modelo del cliente |
| Respuesta | Mensaje esperado o error |
| Compatibilidad | Versiones soportadas |

## 5. Estado de dominio y UI

Las pantallas no deben ser la fuente de verdad del juego. El flujo debe ser:

```text
bytes
  -> frame decoder
  -> message decoder
  -> domain reducer
  -> selectors
  -> UI
```

Y para una acción:

```text
click / teclado
  -> UI action
  -> command validation
  -> encoder
  -> writer
```

Esto permite reconstruir la interfaz desde un replay y probar el modelo sin
abrir una ventana.

## 6. Seguridad de Tauri

La WebView y Rust son fronteras de confianza distintas. Las capacidades Tauri
deben exponer solo los comandos necesarios. No se debe conceder shell o
filesystem amplio para resolver rápidamente una función de UI.

Referencias oficiales:

- Arquitectura: https://v2.tauri.app/concept/architecture/
- Seguridad e IPC: https://v2.tauri.app/security/
- Plugins: https://v2.tauri.app/plugin/

Plugins que pueden ser útiles más adelante:

- Store para preferencias no secretas.
- Stronghold o almacenamiento equivalente para credenciales.
- Logging para logs rotativos.
- Updater para actualizaciones.
- Window State para posición y tamaño.
- Single Instance para evitar dos clientes simultáneos.
- SQL solo si la persistencia local realmente lo necesita.

## 7. Pruebas mínimas

### Unitarias

- round-trip de varints;
- frame vacío;
- frame truncado;
- frame mayor que el límite;
- payload binario;
- envelope con opcode;
- opcode desconocido;
- encoder/decoder simétricos;
- transición inválida de estado;
- selección de celda no caminable;
- reducción de una respuesta de personajes;
- reducción de una actualización de entidad.

### Integración

- servidor TCP falso;
- conexión, autenticación y desconexión;
- dos mensajes consecutivos;
- error de red durante una respuesta;
- reconexión;
- replay completo de login → personajes → mapa.

### Interfaz

- cada pantalla se monta una vez;
- desmontar una pantalla elimina sus listeners;
- el teclado no llega a la pantalla equivocada;
- el modo mock está visible;
- el mundo no recibe clic cuando una ventana modal está abierta;
- las animaciones se cancelan al salir del mapa o combate.

