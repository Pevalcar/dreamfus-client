# Investigación y diseño del cliente DreamFus

Este directorio es la memoria técnica del cliente Dofus de DreamFus. Su objetivo
es que otra persona o IA pueda continuar el trabajo sin depender de una
conversación anterior.

## Alcance

El cliente se implementa como una aplicación Tauri 2:

```text
frontend (WebView)
    ├── UI, pantallas, input, animaciones visuales
    └── estado de presentación
             │ IPC tipado
             ▼
Rust (backend Tauri)
    ├── conexión TCP
    ├── framing y protocolo
    ├── serialización/deserialización
    ├── almacenamiento local
    └── actualizaciones, logs y permisos
             │
             ▼
Servidor Jondo/DreamFus
```

El servidor ya existe y no es el objetivo de este directorio. El cliente debe
depender de contratos de protocolo documentados, no de clases internas del
servidor.

## Documentos

| Documento | Contenido |
|---|---|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Estructura recomendada, límites entre módulos, estado y transporte |
| [GAME-SYSTEMS.md](./GAME-SYSTEMS.md) | Diseño de combate, movimiento, chat, inventario, mundo, personajes, mapas y entidades |
| [REFERENCES.md](./REFERENCES.md) | Proyectos públicos, enlaces, licencias, utilidad y reglas para reutilizar código |
| [MOVEMENT-NETWORK-RESEARCH.md](./MOVEMENT-NETWORK-RESEARCH.md) | Navegación isométrica, celdas, rutas, línea de visión y sincronización |
| [COMBAT-RESEARCH.md](./COMBAT-RESEARCH.md) | Combate táctico, simulación, efectos, turnos y autoridad del servidor |
| [RESEARCH-METHOD.md](./RESEARCH-METHOD.md) | Cómo verificar afirmaciones, commits, licencias y referencias externas |
| [ALEA-DATA-GUIDE.md](./ALEA-DATA-GUIDE.md) | Qué catalogar de una instalación local de Alea y cómo convertirlo en componentes propios |
| [ALEA-AUDIT-OUTPUT.md](./ALEA-AUDIT-OUTPUT.md) | Formato de salida para una auditoría de UI y assets |
| [ALEA-LOCAL-AUDIT-2026-11-01.md](./ALEA-LOCAL-AUDIT-2026-11-01.md) | Auditoría real de la instalación local: UI, audio, hechizos, efectos, mapas y mundo |
| [JONDO-WEBCLIENT-RESEARCH.md](./JONDO-WEBCLIENT-RESEARCH.md) | Qué puede aportar el WebClient decompilado y límites de reutilización |
| [AI-HANDOFF.md](./AI-HANDOFF.md) | Procedimiento para que otra IA continúe la investigación y la implementación |

## Estado de esta investigación

- El cliente se ha descargado localmente como submódulo en el repositorio del
  servidor, pero todavía no se ha publicado ningún cambio.
- La rama local de este repositorio es `docs/client-research`.
- El punto de partida revisado es la rama
  `feature/wire-protocol-implementation`, commit
  `26ed3573bac4052d674837a738aec78881efdeb7`.
- El README histórico contiene rutas que ya no coinciden exactamente con esta
  rama (por ejemplo, menciona `src-tauri` y algunos archivos directamente bajo
  `frontend/`). La fuente de verdad para esta revisión es el árbol real del
  commit: `src/lib.rs` y `frontend/src/`.
- Los proyectos externos son referencias de lectura. No se ha copiado código,
  assets, mapas, sonidos, fuentes, sprites ni datos de cuentas.
- Las afirmaciones sobre proyectos externos deben verificarse en el commit
  concreto que se vaya a estudiar. Un repositorio puede cambiar de licencia,
  rama o contenido.
- El documento adjunto usado como investigación inicial mezcla observaciones,
  nombres de proyectos y afirmaciones históricas que todavía no tienen todas
  una fuente primaria fijada. Se conserva como hipótesis de investigación,
  no como especificación del protocolo.
- La instalación de Alea se usa solo como referencia local. El build de
  DreamFus debe funcionar sin ella y no se versionan sus imágenes, fuentes,
  sonidos, bundles, mapas ni binarios.

## Regla de reutilización

Una idea, protocolo público o patrón arquitectónico puede inspirar una
implementación propia. Copiar código requiere comprobar la licencia de ese
repositorio y de cada asset. Copiar archivos de un cliente oficial, extraer
recursos propietarios o redistribuirlos no queda autorizado por el hecho de
que estén disponibles en Internet.
