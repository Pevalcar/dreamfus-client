# Estructura de UI - Character Selection Screen

## 1. Archivos UXML Involucrados

### 1.1 characterSelection.json
- **Ubicación:** `C:\Users\pevalcar\AppData\Local\Alea\uitk\uxml\characterSelection.json`
- **Tamaño:** Define la pantalla completa de selección de personaje

#### Estructura principal:
```
ctr_characterSelection (DofusVisualElement)
├──VisualElement (ancho: 1920px, alto: 1080px)
│  ├──leftPart (DofusVisualElement)
│  │  ├──window_shadow
│  │  └──win_characterSelection (DofusVisualElement)
│  │     ├──ctr_header
│  │     │  ├──ctr_headerText
│  │     │  │  ├──lbl_title ("personnage sur le serveur")
│  │     │  │  └──lbl_serverName
│  │     │  └──...
│  │     └──...
│  └──...
```

### 1.2 CharacterSlot.json
- **Ubicación:** `C:\Users\pevalcar\AppData\Local\Alea\uitk\uxml\CharacterSlot.json`
- **Tamaño:** Define el template de cada slot de personaje

#### Estructura del Slot:
```json
{
  "t": "DofusVisualElement",
  "n": "ctr_characterSlot",
  "s": "width: 33px; height: 33px; overflow: hidden;",
  "k": [
    {
      "t": "DofusVisualElement",
      "n": "ctr_background",
      "a": {"picking-mode": "Ignore"},
      "s": "flex-grow: 1; overflow: hidden;",
      "k": [
        {
          "t": "DofusIcon",
          "n": "tx_icon",
          "a": {"icon": "weapon"},
          "s": "width: 24px; height: 24px;"
        },
        {
          "t": "DofusVisualElement",
          "n": "breed",
          "s": "position: absolute;"
        },
        {
          "t": "DofusVisualElement",
          "n": "perco",
          "a": {"picking-mode": "Ignore"},
          "s": "--u-img: url(\"@uitk/img/taxCollectorSilhouette.png\");"
        }
      ]
    }
  ]
}
```

## 2. Elementos UI Clave

### 2.1 AnimatedDisplayerComponent (ed_main)

**Identificador:** `ed_main`
**Tipo:** AnimatedDisplayerComponent
**Ubicación:** Dentro de cada slot de personaje

**Estilos críticos:**
```css
position: absolute;
bottom: -15px;
width: 725px;
height: 725px;
```

**Características:**
- Dimensiones: 725x725px
- Posición: absolute, bottom: -15px
- Fondo por defecto: `@uitk/img/socle_1~2.png` (1024x1024)
- Renderizado WebGL2

### 2.2 Contenedores Principales

| ID | Tipo | Uso |
|----|------|-----|
| `ctr_characterSelection` | DofusVisualElement | Contenedor principal |
| `CTR_entity` | VisualElement | Área de renderizado de entidad/avatar |
| `ctr_infoMain` | VisualElement | Información del personaje |
| `ctr_header` | DofusVisualElement | Header con título y nombre servidor |

### 2.3 Elementos de Información

| ID | Tipo | Descripción |
|----|------|-------------|
| `lbl_title` | DofusLabel | Texto "personnage sur le serveur" |
| `lbl_serverName` | DofusLabel | Nombre del servidor |
| `lbl_nameMain` | DofusLabel | Nombre del personaje (34px) |
| `tx_icon` | DofusIcon | Icono de arma/ropa |

## 3. Assets Implicados

### 3.1 Imágenes de Avatar
- **@uitk/img/socle_1~2.png** - Fondo del avatar (1024x1024)
- **@uitk/img/character_slot-D-veDKSK.png** - Slot de personaje
- **@uitk/img/omegaBack~2.png** - Fondo premium

### 3.2 Archivos .a2d (Bones/Skins)
- **d3pack/bones/** - 8,876 archivos de huesos/animaciones
- **d3pack/skins/** - 5,597 archivos de skins/equipamiento

### 3.3 Archivos .d2o
- **Breeds.d2o** - Datos de razas de personajes
- **SkinMappings.d2o** - Mapeo de skins

## 4. Estructura CSS

### 4.1 characterSelection.css
```css
/* Título */
#lbl_title:where([data-uss~="characterSelection"]*) {
  font-weight: bold;
  font-size: variable;
}

/* Nombre del personaje */
#lbl_nameMain:where([data-uss~="characterSelection"]*) {
  color: var(--white_white100);
  font-family: "Lexend-Bold";
  font-size: 34px;
}

/* Ventana principal */
#win_characterSelection:where([data-uss~="characterSelection"]*) {
  width: 640px;
  height: 710px;
  border-radius: 12px;
}
```

### 4.2 CharacterSlot.css
```css
/* Estado por defecto */
#ctr_characterSlot:where([data-uss~="CharacterSlot"]*) {
  width: 33px;
  height: 33px;
  border: 1px solid var(--black_black35);
}

/* Estado filled (personaje seleccionado) */
.filled #ctr_background:where([data-uss~="CharacterSlot"]*) {
  background-color: var(--background_medium90);
}

/* Estado isPlayer.isFilled */
.isPlayer.isFilled#ctr_characterSlot:where([data-uss~="CharacterSlot"]*) {
  border-color: var(--white_white80);
}

/* Icono oculto para filled states */
#ed_look:where([data-uss~="CharacterSlot"]*) {
  display: none;
}
.filled #ed_look:where([data-uss~="CharacterSlot"]*) {
  display: flex;
}
```

## 5. Implementación en DofusClient

### 5.1 Frontend (characterSelect.js)

```javascript
// Estructura de datos esperada
const character = {
  name: "Croquette",
  level: 1920,
  breed: 1,          // ID de raza
  sex: 0,            // 0=hombre, 1=mujer
  look: "Maged624608...", // String look format
  icon: "item_icon.webp"
};

// Renderizado del slot
function populateSlot(slot, character) {
  slot.dataset.character = character.name;
  slot.dataset.look = character.look;
  slot.innerHTML = `
    <div class="avatar-container">
      <div id="ed_main" class="AnimatedDisplayerComponent" 
           style="background-image: url('@uitk/img/socle_1~2.png');"></div>
    </div>
    <span class="dfui-label">${character.name}</span>
    <span class="dfui-label" style="font-size:10px">${character.level}</span>
  `;
}
```

### 5.2 Backend (Tauri Commands)

```rust
// Necesario: comando para obtener datos de personaje
#[tauri::command]
fn get_character_avatar(character_id: i32) -> Result<CharacterAvatar, String> {
    // Parsear .a2d de d3pack/bones/{id}.a2d
    // Parsear .d2o de Breeds.d2o para datos de raza
    // Parsear SkinMappings.d2o para equipamiento
}
```

## 6. Mapeo de Componentes Godot Equivalentes

| Componente Dofus | Godot Equivalente | Notas |
|------------------|-------------------|-------|
| AnimatedDisplayerComponent | Sprite2D + AnimationPlayer | Renderizado personalizado |
| DofusIcon | TextureRect | Con tint y estados |
| DofusLabel | Label | Con fuente y sombra |
| VisualElement | Container/Control | Con Theme |

## 7. Referencias de Navegación (Estructura Exacta del JSON)

```
characterSelection.json
├── ctr_characterSelection (root) [gap-value: 100]
│   ├── VisualElement (1920x1080)
│   │   ├── leftPart
│   │   │   ├── window_shadow
│   │   │   └── win_characterSelection (640x710)
│   │   │       ├── ctr_header
│   │   │       ├── ctr_content (ScrollView - Scrollable)
│   │   │       ├── gd_character (ScrollView)
│   │   │       ├── btn_createCharacter
│   │   │       └── ctr_footer
│   │   └── VisualElement (1) [ctr_display]
│   │       └── ctr_center
│   │           ├── ctr_entity
│   │           │   └── ed_main (AnimatedDisplayerComponent) <-- AVATAR DISPLAY
│   │           │       Path: /[0]/ctr_characterSelection[0]/VisualElement[1]/ctr_display[0]/[0]/VisualElement[0]/VisualElement[0]/[1]/ctr_center[0]/ctr_entity[0]
│   │           │       Style: position: absolute; bottom: -15px; width: 725px; height: 725px;
│   │           └── ctr_infoMain
│   │               ├── ctr_class
│   │               ├── ctr_info
│   │               ├── txt_xpMain
│   │               └── ctr_death
```

### 7.1 Estructura Exacta de ed_main

**Elemento Clave: AnimatedDisplayerComponent**

```json
{
  "t": "AnimatedDisplayerComponent",
  "n": "ed_main",
  "s": "position: absolute; bottom: -15px; width: 725px; height: 725px;"
}
```

**Ubicación jerárquica:**
- Parent: `ctr_entity` (DofusVisualElement)
- Grandparent: `ctr_center` (DofusVisualElement)
- Configuration: `flex-direction: column-reverse`

**Parent ctr_entity:**
```json
{
  "t": "DofusVisualElement",
  "n": "ctr_entity",
  "s": "width: 100%; align-items: center; justify-content: flex-end; height: 605px;",
  "k": [
    {
      "t": "AnimatedDisplayerComponent",
      "n": "ed_main",
      "s": "position: absolute; bottom: -15px; width: 725px; height: 725px;"
    }
  ]
}
```

**Parent ctr_center:**
```json
{
  "t": "DofusVisualElement",
  "n": "ctr_center",
  "s": "align-items: center; flex-direction: column-reverse; opacity: 1;",
  "k": [
    { "n": "ctr_entity", ... },
    { "n": "ctr_infoMain", ... }
  ]
}
```

## 8. Consideraciones Técnicas

1. **Escala:** 0.9 en resolución base 1920x1080
2. **Formato de texturas:** WebP con transparencia
3. **Sistema de look:** String codificado que define pieles, equipamiento, raza
4. **Renderizado:** WebGL2 con Three.js o raw WebGL2
5. **Assets críticos:** socle_1~2.png (fondo avatar), character_slot.png, iconos de raza