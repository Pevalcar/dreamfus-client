# DreamFus Godot Client

> **Launcher + Game Client en GDScript puro para Godot 4.8**

## 📁 Estructura del Proyecto

```
godot-client/
├── project.godot           # Configuración del proyecto Godot 4.8
├── src/
│   ├── Core/               # GameManager, Main (orquestador)
│   ├── Network/            # SimpleProtocolClient (WebSocket)
│   ├── UI/                 # Pantallas: Launcher, CharacterSelect, Game
│   └── Data/               # Modelos (ServerInfo, CharacterData)
├── scenes/
│   ├── Main.tscn            # Escena principal (orquesta todo)
│   ├── Launcher.tscn        # Pantalla de inicio
│   ├── CharacterSelect.tscn # Selector de personajes
│   └── Game.tscn            # Juego con HUD
└── docs/
    └── PROTOCOL.md          # Documentación del protocolo
```

## 🎮 Arquitectura

### Flujo del Usuario

```
Launcher.tscn          CharacterSelect.tscn          Game.tscn
┌───────────────┐       ┌──────────────────┐        ┌──────────┐
│  DreamFus     │       │ Selecciona       │        │  HUD     │
│  Versión:     │─────► │ Personaje        │─────►│ World Map│
│  [Conectar]   │       │ [Crear Nuevo]    │        │ Player   │
│               │       │ [Volver]         │        │ Minimap  │
└───────────────┘       └──────────────────┘        └──────────┘
```

### Componentes Principales

| Componente | Script | Función |
|------------|--------|---------|
| **SimpleProtocolClient** | `src/Network/SimpleProtocolClient.gd` | Cliente WebSocket con protocolo JSON + 4-byte prefix |
| **GameManager** | `src/Core/GameManager.gd` | Singleton que gestiona estado global y transiciones |
| **Main** | `src/Core/Main.gd` | Nodo raíz que orquesta escenas y señales |
| **LauncherUI** | `src/UI/LauncherUI.gd` | Pantalla de inicio con botón de conexión |
| **CharacterSelectUI** | `src/UI/CharacterSelectUI.gd` | Selector de personajes |
| **GameUI** | `src/UI/GameUI.gd` | HUD del juego |

## 🔌 Protocolo de Comunicación

### WebSocket (Puerto 5557)

El cliente se comunica con el servidor usando el protocolo Simple:

1. **auth_request** → Enviar credenciales al servidor
2. **auth_response** ← Recibir lista de servidores  
3. **server_selection** → Seleccionar servidor
4. **server_selection_response** ← Recibir ticket y datos de conexión
5. **Conexión TCP (5555)** → Conectar al GameNodeProxy (protobuf)

📄 Ver `docs/PROTOCOL.md` para detalles completos.

## 🧪 Test Account

| Campo | Valor |
|-------|-------|
| Usuario | keka |
| Contraseña | test |
| Account ID | 188940901 |
| Server ID | 290 |

## 🛠️ Desarrollo

### Requisitos

- **Godot 4.8 beta2** o superior (GDScript)
- **Servidor DreamFus** ejecutándose (puerto 5557)

### Abrir en Godot Editor

1. Abrir Godot Editor (4.8 beta2+)
2. Project → Open Project
3. Navegar a `godot-client/project.godot`
4. El proyecto se cargará automáticamente (GDScript puro, sin C#)

### Ejecutar el cliente

```bash
# Desde la carpeta del proyecto
godot --path .
```

O simplemente abrir el proyecto en el editor de Godot y presionar F5.

## 🚀 Estado Actual

| Componente | Estado |
|------------|--------|
| Estructura proyecto | ✅ Completado (GDScript) |
| SimpleProtocolClient | ✅ Implementado |
| GameManager | ✅ Implementado |
| Pantallas UI | ✅ Básicas |
| Conexión WebSocket | ✅ Funcional |
| Protocolo JSON | ✅ Implementado |
| Mundo de juego | ❌ Pendiente |

> **Nota**: El Godot MCP addon requiere C#/Mono y no es compatible con proyectos GDScript puros. Se ha removido para evitar errores de carga.

## 📚 Referencias

- Protocolo: `docs/PROTOCOL.md`
- UI Design: `dreamfus-ui/schema/dfui.schema.json`
- Servidor: `Jondo.Unity.Server/Custom/`