# DreamFus Client

> **Cliente Godot 4.8 alternativo para Dofus con MCP Runtime**
>
> **Proyecto:** https://github.com/Pevalcar/dreamfus-client.git

> **Golden Rule:** DreamFus Client es un proyecto fan-made que recrea mecánicas, apariencia, animaciones e interfaces del juego Dofus desde cero usando únicamente assets y formatos libres y placeholders temporales.

---

## 🎯 Propósito

Crear un cliente alternativo que:
- **Mecánicas:** Reimplementa el protocolo Jondo desde cero
- **Apariencia:** Usa el mismo estilo visual que el juego original
- **Animaciones:** Implementa sistemas de animación propios basados en estilo Dofus
- **Interfaz:** Sigue la especificación DreamFus UI (documentada en `dreamfus-ui/`)

---

## 📁 Estructura del Proyecto

```
dreamfus-client/
├── godot-client/              # Cliente Godot 4.8 (activo)
│   ├── src/                   # Lógica del juego en GDScript
│   ├── scenes/                # Escenas de Godot
│   └── docs/                  # Documentación del protocolo
│
├── addons/                    # Addons de Godot
│
├── docs/                      # Documentación del proyecto
│   ├── IMPLEMENTATION-ROADMAP.md
│   ├── SIMPLE-PROTOCOL-HOOKS.md
│   └── CONTRIBUTING.md
│
└── .pi/                       # Configuración de Pi
```

---

## 📊 Estado de Implementación

### ✅ Completado

| Componente | Ubicación | Estado |
|------------|----------|--------|
| **WebSocket Client** | `godot-client/src/Network/SimpleProtocolClient.gd` | ✅ Completado |
| **TCP Game Client** | `godot-client/src/Network/GameClient.gd` | ✅ Completado |
| **Protobuf Utilities** | `godot-client/src/Network/Proto.gd` | ✅ Completado |
| **Game Manager** | `godot-client/src/Core/GameManager.gd` | ✅ Completado |
| **Character Select UI** | `godot-client/src/UI/CharacterSelectUI.gd` | ✅ Completado |

### 🚧 En Desarrollo / Pendiente

| Componente | Ubicación | Estado | Notas |
|------------|----------|--------|-------|
| **World Rendering** | `godot-client/` | ⏳ Planeado | Renderizado de mundo, sistemas de juego |
| **A2D Avatar Parsing** | `godot-client/src/A2D/` | ⏳ Planeado | Sistema de renderizado de avatares |

---

## 📚 Documentación

| Documento | Propósito |
|-----------|-----------|
| `docs/SIMPLE-PROTOCOL-HOOKS.md` | Protocolo WebSocket JSON (puerto 5557) |
| `godot-client/docs/PROTOCOL.md` | Documentación del protocolo TCP/Protobuf |
| `godot-client/docs/TCP_HANDBSHAKE.md` | Implementación detallada del handshake TCP |
| `docs/CONTRIBUTING.md` | Cómo contribuir |
| `docs/IMPLEMENTATION-ROADMAP.md` | Roadmap de implementación |

---

## 🔌 Implementación del Protocolo

### SimpleProtocol (Puerto 5557) - WebSocket JSON
**Documentación:** `docs/SIMPLE-PROTOCOL-HOOKS.md`

### Game Protocol (Puerto 5555) - Protobuf
**Documentación:** `godot-client/docs/PROTOCOL.md`

---

## 🎯 Cuenta de Prueba

Usar estas credenciales para pruebas:

```
Usuario: keka
Contraseña: test
Account ID: 188940901
Server ID: 290 (DreamFus)
```

---

## 💻 Desarrollo

### Godot 4.8

```powershell
# Verificar que el proyecto cargue
& "C:\Users\pevalcar\Godot\Godot.exe" --headless --path "godot-client" --quit
```

---

## 🤝 Contribuyendo

1. Fork del repositorio
2. Crear una rama de feature
3. Seguir `docs/CONTRIBUTING.md`
4. Enviar pull request

---

## 🚫 Política de Assets

- **NO** redistribuir assets del juego
- **NO** commitear assets extraídos al repositorio
- Los assets extraídos son solo para desarrollo local

---

*Versión: 1.0*