# Análisis REA del Cliente Alea - Documentation

## Resumen Ejecutivo

Este documento contiene el análisis exhaustivo del cliente **Alea** (Dofus client) realizado utilizando técnicas de reverse engineering. El análisis se centra en el sistema de launcher/login, el UI Toolkit (uitk) y cómo replicar las interfaces en Godot 4.8.

**Archivo analizado:** `C:\Users\pevalcar\AppData\Local\Alea\alea-client.exe` (67.3 MB, 67,361,280 bytes)

---

## 1. Estructura del Ejecutable (PE Analysis)

### 1.1 Información del Archivo Ejecutable

| Propiedad | Valor |
|-----------|-------|
| **Ruta** | `C:\Users\pevalcar\AppData\Local\Alea\alea-client.exe` |
| **Tamaño** | 67,361,280 bytes (67.3 MB) |
| **Tipo de Máquina** | x86-64 (0x8664) |
| **Formato** | PE32+ (Portable Executable) |
| **Timestamp** | 1793899685 (Nov 5, 2026) |
| **Indicadores Unity** | mono (indicador de .NET/mono runtime) |

### 1.2 Secciones PE

| Sección | Tamaño Virtual | Tamaño Raw | RVA (Hex) | Propósito |
|---------|---------------|------------|-----------|-----------|
| `.text` | 10,662,304 bytes | 10,662,400 | 0x1000 | Código ejecutable |
| `.rdata` | 55,914,576 bytes | 55,915,008 | 0xA2D000 | Datos de solo lectura |
| `.data` | 17,256 bytes | 6,144 | 0x3F81000 | Datos de lectura/escritura |
| `.pdata` | 612,132 bytes | 612,352 | 0x3F86000 | Información de excepciones |
| `.rsrc` | 132,912 bytes | 133,120 | 0x401C000 | Recursos PE |
| `.reloc` | 30,764 bytes | 31,232 | 0x403D000 | Tabla de reubicación |

### 1.3 Notas Técnicas

- El cliente es **IL2CPP** (Unity's Intermediate Language to C++), lo que significa que el código está compilado a C++ nativo
- La presencia de "mono" como indicador sugiere que el runtime puede tener referencias a mono, pero el binario final usa IL2CPP
- Las referencias a scripts y lógica están en las secciones `.text` y `.rdata`

---

## 2. UI Toolkit Architecture (uitk)

### 2.1 Estructura de Archivos

| Tipo | Ubicación | Cantidad |
|------|-----------|----------|
| **UXML/JSON** | `uitk/uxml/` | 698 archivos |
| **USS** | `uitk/uss/` | 367 sheets |
| **Assets** | `d3ui/` | 111 imágenes, 5 fuentes, 4 sets |

### 2.2 Componentes UI Principales

#### Elementos por Frecuencia

Los siguientes son los tipos de elementos UI más comunes:

| Tipo | Frecuencia | Uso |
|------|------------|-----|
| `VisualElement` | 4,670 | Contenedor base genérico |
| `DofusLabel` | 2,039 | Texto con estilo Dofus |
| `DofusVisualElement` | 1,729 | Contenedor con estilo Dofus |
| `DofusIcon` | 674 | Iconos personalizados |
| `DofusButtonCustom` | 671 | Botones con estilo Dofus |
| `Label` | 417 | Texto estándar |
| `TableColumnHeader` | 250 | Cabeceras de tabla |
| `Slot` | 206 | Slots de inventario/equipo |
| `WindowFigma` | 196 | Ventanas con estilo Figma |

### 2.3 Acciones/Properties UI (343 únicas)

Propiedades más utilizadas:

| Property | Uso | Descripción |
|----------|-----|-------------|
| `text` | 2,903 | Texto del elemento |
| `picking-mode` | 2,573 | Control de eventos de clique |
| `icon` | 1,171 | Nombre del icono |
| `gap-value` | 1,074 | Espaciado entre elementos |
| `tabindex` | 954 | Orden de tabulación |
| `main-style` | 624 | Estilo principal (primary/secondary) |
| `focusable` | 541 | Si el elemento recibe foco |
| `is-single-line` | 477 | Texto en una sola línea |

### 2.4 Componentes de Estilo (555 únicos)

Componentes de estilo más comunes:

- `textColor_white_white100` - Texto blanco
- `textShort_large` - Texto grande breve
- `backgroundColor_black_black50` - Fondo negro semitransparente
- `Footer` - Componente de footer
- `Window` - Componente de ventana

---

## 3. Archivos del Launcher

Los archivos de UI del launcher son:

| Archivo | Propósito | Elementos |
|---------|-----------|-----------|
| `login.json` | Pantalla de bienvenida/inicio | 11 elementos |
| `mainMenu.json` | Menú principal en juego | 19 elementos |
| `characterSelection.json` | Selección de personaje | 40 elementos |
| `ServerSelection.json` | Selección de servidor | 86 elementos |
| `LoadingScreen.json` | Pantalla de carga | 10 elementos |
| `gameMenu.json` | Menú del juego (pausa) | 9 elementos |
| `passwordMenu.json` | Menú de contraseña/pin | 24 elementos |
| `preGameMainMenu.json` | Menú pre-juego | 16 elementos |
| `bannerMenu.json` | Menú de banners | 5 elementos |

---

## 4. Estructura Detallada del Launcher

### 4.1 login.json - Pantalla de Inicio

**Estructura principal:**

```
login (VisualElement)
├── ctr_gradient (VisualElement)
│   ├── tx_dofusLogo (DofusVisualElement)
│   │   @uitk/img/logoDofus.png (511x470)
│   ├── ctr_error (VisualElement, visible=false)
│   │   └── ctr_message -> lbl_message (DofusLabel)
│   ├── ctr_login (VisualElement)
│   │   └── VisualElement -> btn_play (PlayButton)
│   └── ctr_portSelection (VisualElement)
│       └── dd_host (Dropdown)
```

**Elementos clave:**

| Elemento | Tipo | Acciones | Imagen |
|----------|------|----------|--------|
| `tx_dofusLogo` | DofusVisualElement | - | logoDofus.png |
| `btn_play` | PlayButton | `text: "JOUER"` | - |
| `dd_host` | Dropdown | `icon: "world"`, `focusable: "true"` | - |
| `lbl_message` | DofusLabel | `text` (mensaje error) | - |

**Estilos aplicados:**
- Gradiente de fondo con `gradientWhiteVerticalRectangle.png`
- Fondo negro semitransparente para mensajes de error

---

### 4.2 mainMenu.json - Menú Principal

**Estructura:**

```
PauseMenu (WindowFigma)
├── ctr_content (DofusVisualElement)
    ├── ctr_mainPart (gap: 24)
    │   ├── ctr_changePart (gap: 16)
    │   │   ├── dpd_changeCharacter (button-text: "[changer de personnage]")
    │   │   └── dpd_changeServer (button-text: "[changer de serveur]")
    │   ├── Divider
    │   ├── ctr_options
    │   │   ├── btn_options (icon: "cog", text: "[options]")
    │   │   └── btn_quit (icon: "Leave", text: "[quitter dofus]")
    │   ├── Divider
    │   └── ctr_subPart
    │       └── ctr_sub_txt
    │           └── lbl_sub_text (Abonné jusqu'au 31/12/2024)
    └── ctr_footer
        ├── btn_sub (text: "[abonnement]", icon: "StarFilled")
        ├── btn_close (text: "[revenir au jeu]")
        └── lbl_buildNumber (text: "[Build version : xx.xx.xx]")
```

**Características:**
- Modal, no movable, estilo secundario
- 3 secciones principales: Cambiar personaje/servidor, Opciones, Suscripción

---

### 4.3 characterSelection.json - Selección de Personaje

**Estructura principal:**

```
ctr_characterSelection (DofusVisualElement, gap: 100)
└── VisualElement (left sidebar / content area)
    └── win_characterSelection
        ├── ctr_header
        │   └── ctr_headerText
        │       ├── lbl_title: "personnage sur le serveur"
        │       └── lbl_serverName
        ├── ctr_button
        │   └── dd_servers (button-text: "Changer serveur")
        └── ctr_content (gap: 8)
            ├── ctr_columnHeader
            │   ├── head_name: "Nom"
            │   ├── head_class: "Classe"
            │   └── head_level: "Niveau"
            └── gd_character (ScrollView)
```

**Características:**
- Tabla con columnas: Nombre, Clase, Nivel
- ScrollView para lista de personajes
- Dropdown para cambiar de servidor
- Botón "JOUER" para iniciar juego

---

### 4.4 ServerSelection.json - Selección de Servidor

**Estructura principal:**

```
ctr_serverSelection (DofusVisualElement)
├── ctr_header
│   └── ctr_background
│       └── m_tabs (DofusTabGroup)
│           ├── tab_pioneer: "PIONNIER (x/5)"
│           ├── tab_pioneer_mono: "PIONNIER MONOCOMPTE (x/5)"
│           ├── tab_classic: "CLASSIQUE (x/5)"
│           ├── tab_classic_mono: "CLASSIQUE MONOCOMPTE (x/5)"
│           ├── tab_epic: "ÉPIQUE (x/5)"
│           ├── tab_tournament: "TOURNOIS (x/5)"
│           └── tab_temporis: "TEMPORIS (x/5)"
├── lbl_title: "[CHOIX DU SERVEUR DE JEU]"
├── txt_account: Información de cuenta
└── ctr_servers (ListView)
    └── serverCard (Individual server card)
        ├── btn_play: "JOUER"
        ├── lbl_name: Nombre del servidor
        └── lbl_population: Population info
```

---

## 5. Assets Catalog

### 5.1 Fuentes (Manifest Fonts)

| Fuente | Archivo | Uso |
|--------|---------|-----|
| `Lexend-Bold` | fonts/Lexend-Bold.ttf | Texto negrita |
| `Lexend-Medium` | fonts/Lexend-Medium.ttf | Texto medio |
| `Lexend-Regular` | fonts/Lexend-Regular.ttf | Texto regular |
| `Lexend-SemiBold` | fonts/Lexend-SemiBold.ttf | Texto semi-negrita |
| `Rowdies-Regular` | fonts/Rowdies-Regular.ttf | Fuente decorativa |

### 5.2 Imágenes (111 total)

#### Imágenes 9-Slice (8)

Para estiramiento suave sin deformación:

| Imagen | Dimensiones | Slice | Uso |
|--------|-------------|-------|-----|
| `dialogBackground` | 574x134 | [66, 0, 67, 0] | Fondos de diálogo |
| `dialogBorder` | 574x134 | [66, 0, 67, 0] | Bordes de diálogo |
| `dialogHeader` | 145x73 | [22, 72, 22, 72] | Cabeceras |
| `playButtonBackground` | 280x104 | [0, 60, 0, 60] | Botón JUGAR |
| `timelineTile` | 128x128 | [8, 8, 8, 8] | Tiles de timeline |
| `windowInnerShadow` | 600x600 | [70, 70, 70, 70] | Sombra de ventana |
| `windowShadow` | 92x92 | [45, 45, 45, 45] | Sombra general |

#### Imágenes Clave para Launcher

| Imagen | Dimensiones | Uso |
|--------|-------------|-----|
| `logoDofus` | 511x470 | Logo principal |
| `loginBackground` | 1920x1080 | Fondo de login |
| `gradientWhiteVerticalRectangle` | ? | Gradiente sobre logo |
| `socle` | 912x617 | Fondo del juego |

### 5.3 Iconos UI

Iconos principales usados en el launcher:

| Icono | Uso |
|-------|-----|
| `world` | Selector de servidor |
| `cog` | Opciones |
| `Leave` | Salir/salir del juego |
| `StarFilled` | Suscripción |

---

## 6. Flujo de Autenticación

Basado en la análisis del UI y la documentación del servidor:

### 6.1 Flujo HTTP (API)

```
POST http://{host}:8888/api/entrar
Content-Type: application/json

Body:
{
  "usuario": "username",
  "clave": "password",
  "ip": "127.0.0.1"
}

Response (Éxito):
{
  "bien": true,
  "token": "auth_token_string",
  "cuenta": 188940901,
  "apodo": "player_name",
  "rol": 0
}

Response (Error):
{
  "bien": false,
  "motivo": "mensaje de error"
}
```

### 6.2 Flujo WebSocket (Puerto 5557)

```
1. Conectar a ws://{host}:5557
2. Enviar auth_request:
   {
     "type": "auth_request",
     "token": "token_obtenido",
     "installId": "id_unico",
     "lang": "es",
     "version": "3.6.10.10"
   }
3. Recibir auth_response:
   {
     "success": true,
     "account_id": 188940901,
     "servers": [lista de servidores]
   }
4. Enviar server_selection_request
5. Recibir server_selection_response con ticket
6. Conectar por TCP al puerto 5555 con el ticket
```

### 4.5 serverCard.json - Tarjeta de Servidor

**Estructura detallada:**

```
ctr_serverCard (VisualElement, picking-mode: Ignore)
├── ctr_cardClickableArea (VisualZoneinteractivo)
├── ctr_cardBackground (VisualElement)
│   ├── serverCard (backing)
│   ├── img (background image)
│   └── shadow (shadow image)
├── ctr_serverTitle (VisualElement)
│   ├── ctr_background (title background)
│   │   ├── title_bg, title_bg2 (tiled backgrounds)
│   │   └── gemStone (gem effect)
│   ├── lbl_name (DofusLabel): "[DRACONIROS]"
│   ├── tag (Tag): "[classique monocompte]" - main-style: outlineFilled
│   ├── tag_recommended (Tag): "[recommended]" - status: positive
│   └── tag_restricted (Tag): "[restricted]" - status: warning
├── ctr_infoServer (Información del servidor)
│   ├── icon_status (DofusIcon): "circle" with shadow
│   ├── lbl_characters (DofusLabel): "[Personnages (32)]"
│   ├── ctr_friends (Friends count)
│   │   ├── icon_friends: "party"
│   │   └── lbl_friends: "255"
│   └── New character info with plus icon
└── ctr_character (Character carousel horizontal)
    ├── btn_left (DofusButtonCustom): icon="chevronLeft", main-style="tertiary"
    ├── sv_character (ScrollView horizontal)
    │   └── ctr_characterContent (scroll content)
    └── btn_right (DofusButtonCustom): icon="chevronRight", main-style="tertiary"
```

**Iconos de estado del servidor:**

| Icono | Uso |
|-------|-----|
| `circle` | Estado del servidor (con shadow) |
| `party` | Número de amigos en el servidor |
| `chevronLeft` | Scroll izquierdo |
| `chevronRight` | Scroll derecho |
| `plus` | Crear nuevo personaje |

---

## 5. Assets Catalog

### 7.1 Estructura de Escenas Recomendada

Basado en el análisis, la estructura del launcher actual en Godot podría ser:

```
Launcher (Control)
├── CanvasLayer (layer=1) - Fondo con logo
│   ├── TextureRect (logoDofus.png)
│   └── ColorRect (gradiente)
├── VBoxContainer
│   ├── Label (title)
│   ├── Label (version)
│   ├── Label (status)
│   ├── ProgressBar (connection progress)
│   ├── Button (Connect)
│   ├── LineEdit (UsernameEntry)
│   ├── LineEdit (PasswordEntry, secret=true)
│   ├── OptionButton (Language)
│   ├── LineEdit (ServerHost, default: 127.0.0.1)
│   └── SpinBox (ServerPort, default: 5557)
└── HTTPRequest (hijo de Launcher)
```

### 7.2 Componentes UI a Implementar

#### Elementos de la UI Toolkit

| Componente Unity | Equivalente Godot | Notas |
|------------------|-------------------|-------|
| `WindowFigma` | `WindowDialog` | Ventanas con estilo Figma |
| `DofusButtonCustom` | `Button` + script | Botones con iconos |
| `DofusLabel` | `Label` con tema | Texto con estilo Dofus |
| `Dropdown` | `OptionButton` | Selector de opciones |
| `PlayButton` | `Button` con estilo | Botón JUGAR principal |

#### Scripts necesarios

1. **LauncherUI.gd** - Ya existente, pero necesita actualización para:
   - Usar usuario/contraseña en lugar de token manual
   - Agregar HTTPRequest como hijo de Launcher
   - Manejar el flujo completo de autenticación

2. **CharacterSelect.gd** - Nuevo script para:
   - Mostrar lista de personajes
   - Manejar selección de personaje
   - Dropdown de servidores

3. **ServerSelect.gd** - Nuevo script para:
   - Mostrar cards de servidores
   - Mostrar información de población
   - Seleccionar tipo de servidor (Pionero, Clásico, Épico, etc.)

---

## 8. Consideraciones Técnicas

### 8.1 Assets

**Rutas de assets en Unity:** `@uitk/img/`
**En Godot equivalente:** `res://assets/ui/`

### 8.2 Estilos/CSS

Los estilos en Unity UI Toolkit usan propiedades CSS-like. En Godot, se deben replicar usando:
- Theme resources
- StyleBoxFlat/Textured
- Custom scripts de estilo

### 8.3 Localization

Los textos están en localización (ej: `[JOUER]`, `[changer de personnage]`). Para Godot:
- Usar `Object.get_signal_list()` para verificar
- Crear diccionario de traducción
- Usar `tr()` para localización

### 8.4 Tipos de Servidores (Server Types)

Basado en el análisis de `ServerSelection.json`, los tipos de servidores son:

| Variable Sheet | Nombre | Cantidad de ítems |
|---------------|--------|------------------|
| `emblem-back` | Emblemas traseros | 34 |
| `emblem-outline` | Emblemas con contorno | 34 |
| `emblem-up` | Emblemas horizontales | 488 |
| `guildrank` | Rangos de gremio | 114 |

**Tipos de servidor identificados:**

1. **PIONNIER (x/5)** - Servidor pionero con límite
2. **PIONNIER MONOCOMPTE (x/5)** - Pionero 1 cuenta
3. **CLASSIQUE (x/5)** - Clásico con límite
4. **CLASSIQUE MONOCOMPTE (x/5)** - Clásico 1 cuenta
5. **ÉPIQUE (x/5)** - Épico con límite
6. **TOURNOIS (x/5)** - Torneo con límite
7. **TEMPORIS (x/5)** - Temporis con límite

Los `[x/5]` indican que hay un máximo de 5 servidores de cada tipo que pueden estar activos simultáneamente (probablemente para balancing de población).

---

## 9. Estructura Recomendada para Godot

### 9.1 Organización de Assets

```
res://assets/
├── ui/
│   ├── fonts/                 # Fuentes del launcher
│   │   ├── Lexend-Bold.ttf
│   │   ├── Lexend-Medium.ttf
│   │   ├── Lexend-Regular.ttf
│   │   ├── Lexend-SemiBold.ttf
│   │   └── Rowdies-Regular.ttf
│   ├── launcher/             # Assets específicos del launcher
│   │   ├── logoDofus.png
│   │   ├── loginBackground.png
│   │   └── gradientWhiteVerticalRectangle.png
│   └── icons/               # Iconos UI (36 items identificados)
├── scenes/
│   ├── Launcher.tscn        # Pantalla principal
│   ├── CharacterSelect.tscn # Selección de personaje
│   ├── ServerSelect.tscn     # Selección de servidor
│   └── LoadingScreen.tscn    # Pantalla de carga
└── scripts/
    ├── UI/
    │   ├── LauncherUI.gd
    │   ├── CharacterSelect.gd
    │   ├── ServerSelect.gd
    │   └── LoadingScreen.gd
    └── Network/
        ├── AuthClient.gd
        └── WebSocketClient.gd
```

### 9.5 Componentes Godot Específicos

#### ServerCard (recomendado para Godot)

```
ServerCard (TextureRect, script: ServerCard.gd)
├── Panel ( StyleBoxTexture con 9-slice )
│   └── VBoxContainer
│       ├── Label (server_name)
│       ├── HBoxContainer (status_row)
│       │   ├── TextureButton (status_icon)
│       │   └── Label (characters_count)
│       ├── HBoxContainer (friends_row)
│       │   ├── TextureButton (friend_icon)
│       │   └── Label (friends_count)
│       └── HBoxContainer (character_carousel)
│           ├── TextureButton (prev_btn)
│           ├── ScrollContainer (horizontal)
│           │   └── HBoxContainer (characters)
│           └── TextureButton (next_btn)
└── Tag (recommended indicator)
```

---

## 10. Iconos UI Disponibles

Los siguientes iconos están disponibles en `uitk/img/` y pueden usarse en Godot:

### Iconos de Estado y Navegación

| Icono | Uso | Dimensiones |
|-------|-----|-------------|
| `icon-circle` | Estado del servidor | 24x24 |
| `icon-party` | Amigos | 26x20 |
| `chevronLeft` / `chevronRight` | Navegación (carousel) | 22x14 |
| `icon-plus` | Crear nuevo | 22x22 |

### Iconos de Acción

| Icono | Uso | Dimensiones |
|-------|-----|-------------|
| `icon-cog` | Opciones | 28x28 |
| `icon-world` | Selector servidor | 28x30 |
| `icon-leave` | Salir | Variable |
| `icon-tick` | Confirmación | 27x23 |
| `icon-cross` | Cancelar | 38x38 |

### Iconos de Juego

| Icono | Uso | Dimensiones |
|-------|-----|-------------|
| `icon-heart` | Salud/vida | 26x22 |
| `icon-kamas` | Moneda | 18x16 |
| `icon-weapon` | Armas | 28x28 |
| `icon-helmet` | Armadura | 28x25 |
| `icon-amulet` | Amuleto | 28x31 |
| `icon-belt` | Cinturón | 28x16 |
| `icon-cape` | Capa | 24x28 |
| `icon-flask` | Poción | 25x29 |
| `icon-spell` | Hechizo | 22x26 |
| `icon-item` | Objeto | 22x26 |

### Iconos de UI

| Icono | Uso | Dimensiones |
|-------|-----|-------------|
| `icon-chat` | Chat | 24x28 |
| `icon-envelope` | Mensaje | 24x20 |
| `icon-magnifier` | Búsqueda | 24x24 |
| `icon-pin` | Fijar | 22x26 |
| `icon-player` | Perfil | 26x25 |
| `icon-skull` | PvP/Muertes | 24x24 |
| `icon-trophy` | Victoria | 19x30 |
| `icon-turn` | Turno | 24x27 |

### Menús y Navegación

| Icono | Uso | Dimensiones |
|-------|-----|-------------|
| `menu-characteristic` | Estadísticas | 32x32 |
| `menu-dungeon` | Mazmorra | 32x22 |
| `menu-guild` | Gremio | 30x32 |
| `menu-inventory` | Inventario | 31x32 |
| `menu-kolizeum` | Kolizeum | 32x31 |
| `menu-map` | Mapa | 32x31 |
| `menu-shop` | Tienda | 30x32 |
| `menu-social` | Social | 32x28 |
| `menu-spells` | Hechizos | 28x32 |

---

## 11. Archivos Clave Analizados

| Archivo | Tamaño | Propósito |
|---------|--------|-----------|
| `alea-client.exe` | 67.3 MB | Cliente principal (IL2CPP) |
| `uitk/uxml/login.json` | ~5 KB | UI de login |
| `uitk/uxml/mainMenu.json` | ~4 KB | Menú principal |
| `uitk/uxml/characterSelection.json` | ~15 KB | Selección personajes |
| `uitk/uxml/ServerSelection.json` | ~12 KB | Selección servidores |
| `uitk/uxml/LoadingScreen.json` | ~4 KB | Pantalla de carga |
| `d3ui/manifest.json` | ~8 KB | Catálogo de assets |

---

## 12. Referencias

- **Protocolo WebSocket:** 4-byte big-endian length prefix + JSON UTF-8
- **Formato UI Toolkit:** JSON con propiedades UXML/USS
- **Fuente de verdad:** Servidor en `..\jondo-servidor` (endpoint `/api/entrar`)

---

*Documento generado por análisis REA del ejecutable Alea. Para preguntas sobre el protocolo de red, referirse al servidor en `..\jondo-servidor`.*