# Estructura de Selección de Personajes - Análisis Dofus/Alea

## Referencia principal
- **Archivo**: `C:\Users\pevalcar\AppData\Local\Alea\ui_analysis.json`
- **Elementos identificados**: 382 elementos de UI
- **Ubicación instalación**: `C:\Users\pevalcar\AppData\Local\Alea` (Cliente Dofus oficial)

---

## 🎯 Ventana principal: win_characterSelection

### Elementos principales identificados

| Elemento | Tipo | Propósito |
|----------|------|-----------|
| `win_characterSelection` | Window | Ventana principal de selección |
| `sv_character` | ScrollView | Contenedor derrollable de personajes |
| `ctr_characterSelection` | Container | Panel de selección de personaje |
| `ctr_characterContent` | Container | Contenido dentro de selección |
| `ctr_characterLine` | Container | Línea individual de personaje |
| `ctr_characterSlot` | Slot | Cada botón/personaje en la lista |
| `ctr_character` | Container | Contenedor de información de personaje |
| `ctr_characterInfo` | Container | Información detallada |
| `ctr_characterInfos` | Container | Información secundaria |
| `ctr_characterVisual` | Container | Visualización/avatar del personaje |

### Sub-elementos de información

#### Información del personaje
| Elemento | Uso |
|----------|-----|
| `lbl_characterName` | Nombre del personaje |
| `lbl_character` | Texto general |
| `lbl_characters` | Título de lista |
| `tx_characterBase` | Texto base/infos |

#### Estadísticas y aspectos
| Elemento | Uso |
|----------|-----|
| `ctr_characterStatsDetailed` | Estadísticas detalladas |
| `ctr_characterVisual` | Visualización del avatar |
| `btn_characteristics` | Botón de características |

---

## 🧬 Creación de Personaje: ctr_newCharacter

### Elementos de creación

| Elemento | Tipo | Propósito |
|----------|------|-----------|
| `ctr_newCharacter` | Container | Panel de creación de personaje |
| `CreateNewPopup` | Popup | Diálogo de creación |

---

## 🏷️ Sistema de Raza (Breed)

### Elementos de raza/breed

| Elemento | Tipo | Propósito |
|----------|------|-----------|
| `ctr_breeds` | Container | Contenedor principal de razas |
| `ctr_breed` | Container | Contenedor individual de raza |
| `tch_breed` | ToggleButton | Botón de selección de raza |
| `tx_breed` | Text/Label | Texto de nombre de raza |
| `tx_breedSymbol` | Element | Símbolo/icono de raza |
| `lbl_breed` | Label | Texto de raza |
| `lbl_breedTitle` | Label | Título de sección raza |
| `lbl_breedInfo` | Label | Información adicional |

### Elementos relacionados de cría/egg

| Elemento | Tipo | Propósito |
|----------|------|-----------|
| `ctr_breedingLine` | Container | Línea de cría |
| `da_breeding` | Data | Información de cría |

---

## 🔧 Estructura actual DreamFus (Implementación actual)

```
CharacterSelect.tscn
├── VBoxContainer
│   ├── TitleLabel (Label)
│   ├── ServerLabel (Label)
│   └── ScrollContainer
│       └── CharacterList (VBoxContainer)  ← botones dinámicos
└── BottomPanel (HBoxContainer)
    ├── CreateButton (Button)
    └── BackButton (Button)
```

### Implementación en CharacterSelectUI.gd

#### Creación de botones de personaje
```gdscript
_create_character_buttons()
  → Button.new()
  → text = "Nombre [Raza] Nvl Nivel"
  → tooltip_text = "ID: X, Sexo: Y, Breed: Z"
  → pressed.connect(_on_character_button_pressed.bind(character))
```

#### Nombres de raza implementados (1-16)
```
1: Feca
2: Osamodas
3: Enutrof
4: Sacrieur
5: Sadida
6: Xelor
7: Chafouis
8: Iop
9: Cra
10: Sram
11: Xelor  (variante especial)
12: Ecaflip
13: Opr    (Ogre-like)
14: Rubbaduck
15: Panda
16: Foggba
```

---

## 📋 Diferencias entre Alea y DreamFus

### Características de Alea (Dofus original)

1. **Lista de personajes scrollable con scroll view**
   - `sv_character` (ScrollView) envuelve `ctr_characterSelection`

2. **Visualización rica de personajes**
   - Avatar visual (`ctr_characterVisual`)
   - Estadísticas detalladas (`ctr_characterStatsDetailed`)

3. **Sistema de raza visual**
   - `ctr_breeds` muestra todas las razas con símbolos
   - Toggle buttons para selección visual

### Características DreamFus actual (más simple)

1. **Lista simple con VBoxContainer**
   - Sin scroll view dedicado, usa el ScrollContainer padre

2. **Información básica solo**
   - Nombre, raza, nivel en tooltips
   - Sin avatar ni estadísticas visualizadas

3. **Sin selección de raza visual**
   - La raza ya está asignada (sistema backend)

---

## 🎨 Elementos de UI relacionados

### Ventanas de selección
- `win_characterSelection` - Ventana principal
- `CreateNewPopup` - Crear nuevo personaje
- `win_cloning` - Clonación de personaje

### Servidor/Conexión
- `ctr_serverSelection` - Selección de servidor
- `ctr_servers` - Lista de servidores
- `btn_select` - Botón de selección genérica

---

## 🔗 Referencias cruzadas

### Elementos de personaje en otros contextos
| Contexto | Elementos |
|----------|-----------|
| Información del jugador | `ctr_player`, `ctr_playerEquipment` |
| Perfil social | `win_playerInfoUi` |
| Presets | `ctr_characterPresets` |

---

## 📌 Próximos pasos recomendados

1. **Mejorar visualización de personajes**
   - Añadir avatar visual en cada slot de personaje
   - Mostrar estadísticas principales

2. **UI de creación de personaje**
   - Implementar `ctr_newCharacter` con selección de raza
   - Añadir personalización de aspecto

3. **Scroll view dedicado**
   - Considerar usar `sv_character` como patrón para futuras mejoras

---

## 📁 Archivos de referencia

| Archivo | Ubicación |
|---------|-----------|
| UI Analysis | `C:\Users\pevalcar\AppData\Local\Alea\ui_analysis.json` |
| Documentación cliente | `godot-client/README.md` |
| Script de selección | `src/UI/CharacterSelectUI.gd` |
| Escena actual | `scenes/CharacterSelect.tscn` |