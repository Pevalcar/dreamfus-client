# DreamFus Godot Client

> **Launcher + Game Client en GDScript puro para Godot 4.8**
>
> **Proyecto:** https://github.com/Pevalcar/dreamfus-client.git
> **Ruta del proyecto:** `C:\Users\pevalcar\Proyects\jondo-servidor\DofusClient\godot-client`

## 📁 Estructura del Proyecto

```
godot-client/
├── project.godot           # Configuración del proyecto Godot 4.8
├── src/
│   ├── Core/               # GameManager, Main (orquestador)
│   ├── Network/            # SimpleProtocolClient (WebSocket), GameClient (TCP), Proto (protobuf)
│   ├── UI/                 # Pantallas: Launcher, CharacterSelect, Game
│   ├── Data/               # Modelos (ServerInfo, CharacterData)
│   └── Components/         # Componentes reutilizables
│       └── Character/      # CharacterSlot (botón de selección de personaje)
├── scenes/
│   ├── Main.tscn            # Escena principal (orquesta todo)
│   ├── Launcher.tscn        # Pantalla de inicio
│   ├── CharacterSelect.tscn # Selector de personajes
│   ├── Game.tscn            # Juego con HUD
│   └── Components/
│       └── Character/
│           └── CharacterSlot.tscn  # Botón de selección de personaje
├── assets/
│   ├── icons/
│   │   ├── emblems/        # .gitkeep (sin assets)
│   │   └── classes/        # .gitkeep (sin assets)
│   └── fonts/              # .gitkeep (sin assets)
└── docs/
    ├── PROTOCOL.md          # Protocolo general de comunicación
    └── TCP_HANDBSHAKE.md    # Detalles del handshake TCP/protobuf
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
| **CharacterSlot** | `src/Components/Character/CharacterSlot.gd` | Botón de selección de personaje con emblem de raza |

## 🔌 Protocolo de Comunicación

### WebSocket (Puerto 5557)

El cliente se comunica con el servidor usando el protocolo Simple:

1. **auth_request** → Enviar credenciales al servidor
2. **auth_response** ← Recibir lista de servidores  
3. **server_selection** → Seleccionar servidor
4. **server_selection_response** ← Recibir ticket y datos de conexión
5. **Conexión TCP (5555)** → Conectar al GameNodeProxy (protobuf)

Ver detalles en `docs/PROTOCOL.md` y `docs/TCP_HANDBSHAKE.md`.

### TCP Handshake (Puerto 5555) - Protobuf

El handshake TCP completo incluye:
- **kqz**: Envío del ticket de autenticación
- **kra**: Acknowledgment vacío
- **Welcome Burst**: Mensajes de estado del servidor (kqp, lqu, hoy, kqu, mgq, mgt, hpd, krs, mgz, kqp)
- **kvi**: Lista de personajes (307 bytes, parseado correctamente)
- **jtg**: Trigger para mostrar selector de personajes
- **kvw**: Envío de selección de personaje (usando formato PUSH)

Los detalles técnicos de implementación están en `docs/TCP_HANDBSHAKE.md`.

## 🧪 Test Account

| Campo | Valor |
|-------|-------|
| Usuario | keka |
| Contraseña | test |
| Account ID | 188940901 |
| Server ID | 290 |

## 🛠️ Desarrollo

### Requisitos

- **Godot 4.8 beta2** o superior (GDScript puro)
- **Servidor DreamFus** ejecutándose (puerto 5557)

### Instalar Godot MCP Toolkit (Recomendado)

Para una navegación de código mejorada, instale el Godot MCP Toolkit:

```bash
npm install -g @npgamedev/godot-mcp-server@1.1.2
```

Esto permite:
- Búsqueda de símbolos y trazado de código
- Consultas de arquitectura
- Verificación de cobertura

Ver `docs/README.md` en este directorio para más detalles.

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
| Protocolo WebSocket (5557) | ✅ Implementado y probado |
| Protocolo TCP/Protobuf (5555) | ✅ Handshake completo |
| GameManager | ✅ Implementado |
| Pantallas UI | ✅ Básicas |
| Autenticación | ✅ Funcional |
| selección de personajes | ✅ **Funcional** (kvw implementado) |
| Mundo de juego | ❌ Pendiente |

**Handshake TCP Verificado:**
- kqz → kra → kvi(4 chars) → jtg → kvw
- `characters_received` emitido correctamente
- Botones de selección con raza y nivel visibles

**Estado del MCP:**
- Símbolos exportados: A2DParser, A2D1Header, A2DZHeader, etc.
- Ver `.mcp.json` para configuración del servidor MCP
- Ver `docs/DEFLATE_SOLUTION.md` para opciones de parsing A2D.Z

## 🦾 Emblems de Raza (Breed Icons)

### Sistema de Mapeo

El cliente carga emblems de raza desde `d3picto/hint/` usando un mapeo simple:

**breed → archivo:**

| breed | Archivo | Raza | Emoji |
|-------|---------|------|-------|
| 1 | 10.png | Feca | 🛡️ |
| 2 | 20.png | Osamodas | 🐢 |
| 3 | 30.png | Enutrof | 🪙 |
| 4 | 40.png | Sacrieur | 💪 |
| 5 | 50.png | Sadida | 🐕 |
| 6 | 60.png | Xelor | ⏳ |
| 7 | 70.png | Chafouis | 🐝 |
| 8 | 80.png | Iop | ⚔️ |
| 9 | 90.png | Cra | 🏹 |
| 10 | 100.png | Sram | 🐍 |
| 11 | 110.png | Ecaflip | 🐱 |
| 12 | 120.png | Ouginak | 🦄 |
| 13 | 130.png | Tymador | 🎭 |
| 14 | 140.png | Rubbaduck | 🦆 |
| 15 | 150.png | Steamer | ⚙️ |
| 16 | 160.png | Eliotrope | 🐸 |

### Ubicación de Assets

**Desarrollo:**
```
C:/Users/pevalcar/AppData/Local/Alea/d3picto/hint/
```

**Producción:**
```
<ejecutable_dir>/DreamFus/d3picto/hint/
```

### Implementación en CharacterSlot.gd

```gdscript
# Ruta base - Cambiar solo esta línea para producción
const GAME_ASSETS_BASE_PATH := "C:/Users/pevalcar/AppData/Local/Alea/"

# Mapeo de nombres de raza
const BREED_NAMES := {
    1: "Feca", 2: "Osamodas", 3: "Enutrof", 4: "Sacrieur",
    5: "Sadida", 6: "Xelor", 7: "Chafouis", 8: "Iop",
    9: "Cra", 10: "Sram", 11: "Ecaflip", 12: "Ouginak",
    13: "Tymador", 14: "Rubbaduck", 15: "Steamer", 16: "Eliotrope"
}

# Carga emblem: breed (1-16) → archivo (10.png, 20.png...)
func _get_breed_emblem(breed: int) -> Texture2D:
    if breed < 1 or breed > 16:
        return null
    
    var file_num = breed * 10
    var emblem_path = GAME_ASSETS_BASE_PATH + "d3picto/hint/%d.png" % file_num
    
    if ResourceLoader.exists(emblem_path):
        return load(emblem_path)
    
    return null
```

### Para producción - Solo cambiar una línea

```gdscript
# En CharacterSlot.gd línea 20
const GAME_ASSETS_BASE_PATH := "../DreamFus/"  # Ruta relativa al ejecutable
```

**Estructura esperada en producción:**
```
ejecutable/
├── dreambus-client.exe
├── DreamFus/
│   ├── d3picto/
│   │   └── hint/
│   │       └── *.png
```