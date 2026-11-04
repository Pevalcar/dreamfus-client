# Manual de continuidad para futuras IAs

## 1. Primeros pasos

1. Leer `README.md`.
2. Leer este directorio completo.
3. Ejecutar:

```powershell
git status --short --branch
git submodule status
git log -1 --oneline
```

4. Comprobar la rama y el commit exacto del repositorio de referencia.
5. No tocar assets oficiales ni credenciales.
6. Revisar los cambios locales antes de editar.

## 2. Dónde buscar cada tema

| Tema | Documento local | Referencias externas |
|---|---|---|
| Tauri/IPC | `docs/research/ARCHITECTURE.md` | https://v2.tauri.app/concept/architecture/ |
| Transporte | `docs/research/ARCHITECTURE.md` | `src/lib.rs`, `frontend/src/protocol.js` |
| Combate | `docs/research/GAME-SYSTEMS.md` | Rollback, Desperion, CodeBreak |
| Movimiento/mapa | `docs/research/GAME-SYSTEMS.md` | Emudofus/Dofus y emuladores |
| UI | `docs/research/ARCHITECTURE.md` | `frontend/src/dfui`, `frontend/src/ui` |
| Licencias | `docs/research/REFERENCES.md` | LICENSE/NOTICE de cada repositorio |
| Más proyectos | `docs/research/REFERENCES.md` | búsquedas GitHub reproducibles |

## 3. Proceso para investigar un proyecto nuevo

```text
1. Encontrar el repositorio mediante GitHub.
2. Confirmar que no es un binario o un mirror sospechoso.
3. Clonar una rama/tag concreto.
4. Leer README, LICENSE y NOTICE.
5. Registrar lenguaje, fecha, commit y estado.
6. Identificar solo los módulos relevantes.
7. Anotar qué comportamiento explica.
8. Separar hechos de inferencias.
9. Diseñar una interfaz propia para DreamFus.
10. Añadir tests antes de copiar cualquier patrón de implementación.
```

Cada entrada nueva debe contener:

```text
URL
commit o tag
fecha de consulta
licencia
módulo examinado
hallazgos
qué no se puede reutilizar
idea aplicable
issue/tarea propuesta
```

## 4. Proceso para implementar un sistema

### Antes de editar

- definir el contrato de estado;
- definir mensajes de entrada y salida;
- definir errores;
- definir pruebas;
- comprobar si el sistema afecta al renderer, al protocolo o a ambos;
- decidir dónde vive el código.

### Durante la implementación

- mantener Rust independiente de la UI;
- mantener la UI independiente del socket;
- no usar datos ficticios en modo real;
- no ocultar errores con `catch` amplio;
- retirar listeners al desmontar pantallas;
- registrar la versión del protocolo;
- añadir replay si el flujo es difícil de probar.

### Después

- ejecutar tests unitarios;
- ejecutar tests de integración;
- probar desconexión;
- probar payload desconocido;
- revisar logs sin credenciales;
- documentar la verificación manual;
- dejar una entrada en el PR antes de subir cambios.

## 5. Primera hoja de ruta sugerida

### Hito A: conexión fiable

- separar reader/writer;
- corregir parser;
- tests de framing;
- estados de conexión;
- error visible en modo real.

### Hito B: sesión

- login;
- respuesta de personajes;
- selección;
- carga de mapa;
- entidades iniciales.

### Hito C: mundo

- renderer de mapa;
- movimiento;
- chat;
- ventanas;
- inventario.

### Hito D: combate

- placement;
- turnos;
- acciones;
- efectos;
- cola de animaciones.

### Hito E: distribución

- configuración;
- perfiles;
- logs;
- actualización;
- instalador;
- matriz de compatibilidad.

## 6. Evidencia y trazabilidad

No escribir frases como “el cliente original lo hace así” sin indicar la
fuente. Usar este formato:

```text
Observación:
Fuente:
Commit/tag:
Archivo o sección:
Confianza:
Decisión en DreamFus:
```

Niveles:

- **Alta:** se confirma en código fuente y tests.
- **Media:** se observa en código, pero falta un flujo completo.
- **Baja:** se infiere de documentación, capturas o comportamiento externo.

## 7. Regla para futuras consultas a IA

La IA debe preferir:

1. documentación local;
2. fuente del repositorio en el commit fijado;
3. tests;
4. documentación oficial de Tauri;
5. búsqueda externa reproducible.

No debe inventar nombres de mensajes, clases o archivos. Si un dato no está
confirmado, debe marcarlo como hipótesis y proponer cómo verificarlo.

