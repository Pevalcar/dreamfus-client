# AGENTS.md — DreamFus Client

## Proyecto
Cliente de Dofus reimplementado en Godot 4.8+ (GDScript) contra el servidor de `../jondo-servidor`.
`godot-client/` es el proyecto real: `src/Core` (sesión), `src/Network` (protocolo), `src/Data` (mapas),
`src/UI` (pantallas). UI y assets se inspiran en el cliente Alea.

## Fuentes externas (solo lectura, nunca modificar)
- `../jondo-servidor` — protocolo y lógica del servidor.
- `C:\Users\pevalcar\AppData\Local\Alea` — assets, mapas e interfaz de referencia.

## Comandos
Godot: `C:\Users\pevalcar\Godot\Godot_console.exe`
- Cargar proyecto: `Godot_console.exe --headless --path godot-client --quit`
- Tests: `Godot_console.exe --headless --path godot-client -s addons/gut/gut_cmdln.gd -gdir=res://test -gexit`
- Assets: `python tools/alea_to_godot.py -1 0` genera los `.tres` de un mapa.

## Estilo
- Godot 4.8+, GDScript tipado. Sin C#, sin dependencias nuevas sin aprobación.
- Identificadores y comentarios en inglés; docs, commits y texto de jugador en español.
- Escenas y `project.godot` se editan con el MCP de Godot, nunca a mano.

## Reglas
- Lee `docs/constitution.md` y la spec de `docs/` antes de tocar protocolo, mapas o sesión.
- Trabaja en ramas `feature/*`; nunca commit directo en `main`.
- Los assets generados (`.tres` de mapas, extracciones de Alea) no se commitean.
- No toques `godot-client/addons/`.
- Crea test nuevos que cumplan los requisitos de GUT "revisar : https://gut.readthedocs.io/en/latest/Creating-Tests.html" Para tener idea de como se crean 

## Entorno de pruebas
Cuenta `keka`/`test` (ID `188940901`); servidor en `../jondo-servidor`: HTTP `:8888`, WS `:5557`, TCP `:5555`.

## Al terminar cualquier tarea
Ejecuta los tests y di en tu respuesta si pasan o por qué no se pudieron correr.