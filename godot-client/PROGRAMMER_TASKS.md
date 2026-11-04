# Tareas para el Programador - DreamFus Client

## ⚠️ IMPORTANTE - Reglas del Proyecto

**NO editar archivos `.tscn` manualmente** bajo ninguna circunstancia. El formato de Godot 4.8
puede corromperse al editar texto y el editor pierde la capacidad de abrir la escena correctamente.

---

## 🛠️ Tarea 1: Agregar BreedLabel al HUD del juego

### Ubicación
- **Archivo**: `godot-client/scenes/Game.tscn`
- **Padre**: `HUDContainer` (línea 14)

### Estado actual del HUDContainer
```
HUDContainer (HBoxContainer)
├── CharacterLabel (Label) - línea 28
├── LevelLabel (Label) - línea 33
├── HealthLabel (Label) - línea 38
├── HealthBar (ProgressBar) - línea 43
├── XPBar (ProgressBar) - línea 47
├── XPLabel (Label) - línea 51
└── BackToSelect (Button) - línea 56
```

### Acción requerida
El programador debe **añadir el nodo BreedLabel** usando el editor de Godot:

1. Abrir `godot-client/scenes/Game.tscn` en el editor de Godot
2. Seleccionar el nodo `HUDContainer`
3. Crear un nuevo **Label** como hijo de `HUDContainer`
4. Configurar las siguientes propiedades:
   - **Name**: `BreedLabel`
   - **Theme Override Font Sizes / Font Size**: `12` (para coincidir con XPLabel y HealthLabel)
   - **Theme Override Font Sizes / Bold**: `true` (opcional, para destacar)
   - **Autowrap**: `true` (opcional, para longitudes de raza)

5. **Posición**: Debe ir **después de BackToSelect** (al final del HBoxContainer)
   - El orden visual será: CharacterLabel → LevelLabel → HealthLabel → HealthBar → XPBar → XPLabel → BackToSelect → **BreedLabel**

6. **Guardar la escena**

### Código preparado
El archivo `GameUI.gd` ya está preparado para usar el BreedLabel:

```gdscript
# GameUI.gd (líneas 18-19)
var breed_label: Label = null
var _breed_label_path := "HUDContainer/BreedLabel"

# En _ready() (líneas 28-31)
breed_label = get_node_or_null(_breed_label_path)
if breed_label == null:
    print("[GameUI] BreedLabel no encontrada en ruta: %s" % _breed_label_path)
```

### Verificación
1. Compilar el proyecto: `& "C:\Users\pevalcar\Godot\Godot.exe" --headless --path godot-client --quit`
2. Verificar que no hay errores críticos
3. Probar en el juego mostrando un personaje con raza

---

## 🧪 Tarea 2: Verificar estructura CharacterSelect.tscn

### Ubicación
- **Archivo**: `godot-client/scenes/CharacterSelect.tscn`

### Estado actual (funcional)
```
CharacterSelect (Control)
├── VBoxContainer
│   ├── TitleLabel (Label)
│   ├── ServerLabel (Label)
│   └── ScrollContainer
│       └── CharacterList (VBoxContainer) ← botones dinámicos
└── BottomPanel (HBoxContainer)
    ├── CreateButton (Button)
    └── BackButton (Button)
```

### Acción requerida
Verificar que la estructura permite:
1. **Crear botones de personaje** dinámicamente (ya implementado en CharacterSelectUI.gd)
2. **Mostrar nombre, raza, nivel y tooltip** correctamente (ya implementado)

### Nombres de raza implementados (1-16)
```gdscript
1: "Feca"
2: "Osamodas"
3: "Enutrof"
4: "Sacrieur"
5: "Sadida"
6: "Xelor"
7: "Chafouis"
8: "Iop"
9: "Cra"
10: "Sram"
11: "Xelor"  # Xelor-11 (especial)
12: "Ecaflip"
13: "Opr"    # Ogre-like
14: "Rubbaduck"
15: "Panda"
16: "Foggba"
```

### Referencias de UI Dofus original
- **Archivo de referencia**: `C:\Users\pevalcar\AppData\Local\Alea\ui_analysis.json`
- Contiene 382 elementos UI de la versión original de Dofus
- Para investigación futura de UI, usar este archivo como referencia

---

## 🔍 Tarea 3: Investigación estructura selección Alea - COMPLETADA

### ✅ Investigación finalizada - Documentación creada

#### Archivo de investigación creado:
`godot-client/docs/ui_analysis/CharacterSelectionStructure.md`

#### Elementos clave identificados en Alea:

**Ventana principal**: `win_characterSelection`
- `sv_character` - ScrollView para lista derrollable
- `ctr_characterSelection` - Contenedor principal
- `ctr_characterSlot` - Cada slot de personaje

**Sistema de raza (breed)**:
- `ctr_breeds` - Contenedor de razas
- `tch_breed` - ToggleButton de selección
- `tx_breedSymbol` - Símbolo de raza

**Creación de personaje**:
- `ctr_newCharacter` - Panel de creación
- `CreateNewPopup` - Diálogo de creación

### Diferencias identificadas:

| Característica | Alea (original) | DreamFus (actual) |
|----------------|-----------------|-------------------|
| Lista scrollable | ScrollView (`sv_character`) | ScrollContainer simple |
| Visualización avatar | Sí (`ctr_characterVisual`) | No implementado |
| Estadísticas | Sí detalladas | Solo en tooltip |
| Selección raza visual | Sí con toggle | No (backend asigna) |

### Estado actual de CharacterSelect.tscn

La estructura actual es funcional y permite:
1. ✅ Crear botones de personaje dinámicamente
2. ✅ Mostrar nombre, raza, nivel y tooltip correctamente
3. ✅ Manejo de señales de selección y creación

**NO necesita modificación** - está funcionando correctamente con la cuenta de prueba `keka/test`.

---

## 🔍 Tarea 3: Investigación estructura selección Alea (Futuro)

### Directorios de referencia
| Ubicación | Propósito |
|-----------|-----------|
| `C:\Users\pevalcar\AppData\Local\Alea` | Cliente oficial Dofus - UI original |
| `C:\Users\pevalcar\AppData\Local\DreamFus\Cliente` | Cliente DreamFus con IA |

### Archivo de referencia clave
`C:\Users\pevalcar\AppData\Local\Alea\ui_analysis.json` - 382 elementos UI identificados

### Próximos pasos
1. Analizar la estructura de CharacterCreate/CharacterSelect en Alea
2. Comparar con la estructura actual de DreamFus
3. Documentar diferencias para mejoras futuras

---

## ✅ Estado de implementación actual

| Componente | Estado | Archivo |
|------------|--------|---------|
| BreedLabel en HUD | ⏳ **Pendiente** (programador debe añadir en Game.tscn) | `scenes/Game.tscn` |
| GameUI.gd con BreedLabel | ✅ Completado | `src/UI/GameUI.gd` |
| Nombres de raza (1-16) | ✅ Completado | `src/UI/GameUI.gd`, `src/UI/CharacterSelectUI.gd` |
| Timeout TCP 10s | ✅ Completado | `src/Core/GameManager.gd` |
| Timeout welcome burst 15s | ✅ Completado | `src/Core/GameManager.gd` |
| Timers dinámicos | ✅ Completado | `src/Core/GameManager.gd` |
| Señal disconnected | ✅ Completado | `src/Core/GameManager.gd`, `src/Network/GameClient.gd` |
| UI Analysis Alea | ✅ Disponible | `C:\Users\pevalcar\AppData\Local\Alea\ui_analysis.json` |
| Inves. CharacterSelect | ✅ Completado | `docs/ui_analysis/CharacterSelectionStructure.md` |
| Estructura CharacterSelect.tscn | ✅ Funcional | `scenes/CharacterSelect.tscn` |

---

## 📞 Pruebas

### Cuenta de prueba
- **Usuario**: `keka`
- **Contraseña**: `test`
- **Account ID**: `188940901`
- **Servidor**: `290`
- **HTTP**: `127.0.0.1:8888`
- **WebSocket**: `127.0.0.1:5557`
- **TCP**: `127.0.0.1:5555`

---