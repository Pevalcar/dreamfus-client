# Asset Strategy

## ⚠️ Legal Notice / Aviso Legal

**This document describes how to extract assets for development.** The extracted assets are NOT distributed in the repository.

**Este documento describe cómo extraer assets para desarrollo.** Los assets extraídos NO se distribuyen en el repositorio.

DreamFus Client is a fan-made project that uses placeholders and assets extracted only for development.

DreamFus Client es un proyecto fan-made que usa placeholders y assets extraídos únicamente para desarrollo.

---

## 📁 Asset Locations / Ubicaciones de Assets

### ALDA (Reference) / ALDA (Referencia)
```
C:\Users\pevalcar\AppData\Local\Alea\
```

| Type / Tipo | Location / Ubicación | Usage / Uso |
|-------------|---------------------|-------------|
| UI Templates | `uitk/uxml/*.json` | UI Structure / Estructura UI |
| Style Sheets | `uitk/uss/*.css` | CSS Styles / Hojas de estilos |
| UI Images | `uitk/img/` | UI Sprites / Sprites UI |
| Fonts | `uitk/fonts/*.ttf` | Typography / Tipografía |
| Character Sprites | `d3pack/bones/`, `d3pack/skins/` | Character Data / Data de personajes |

### DreamFusion Client (Extractable) / Cliente DreamFusion (Extraíble)
```
C:\Users\pevalcar\AppData\Local\DreamFus\Cliente\
```

| File / Archivo | Content / Contenido |
|----------------|---------------------|
| `Datos/icons/map.json` | gid → iconId mapping of items / Mapeo gid → iconId de items |
| `MelonLoader/Il2CppAssemblies/` | Extraction tools / Herramientas de extracción |

---

## 🛠️ How to Extract Assets / Cómo Extraer Assets

### UI Templates (DFUI)

Los archivos `.dfui` deben convertirse de los JSON de ALDA:

```javascript
// Ejemplo de conversión básica / Basic conversion example
const uxml = JSON.parse(fs.readFileSync('uitk/uxml/characterSelect.json'));
const dfui = {
    // Mapear nodos ALDA a componentes DFUI
    // Map ALDA nodes to DFUI components
    // Ver dreamfus-ui/ para especificaciones
    // See dreamfus-ui/ for specifications
};
```

### Character Sprites / Sprites Personajes

Los sprites de personajes están en:

- `d3pack/bones/` - Esqueleto (animaciones)
- `d3pack/skins/` - Skins por raza/sexo

Formato: `gfx/{breed}_{sex}_{color}.png`

---

## 📂 Project Organization / Organización del Proyecto

```
DofusClient/
├── frontend/
│   ├── public/
│   │   └── ui/              # DFUI templates (.dfui)
│   └── src/
│       └── dfui/            # DFUI renderer
├── docs/
│   ├── ASSET-STRATEGY.md    # This guide / Esta guía
│   └── UI-CLIENTE.md        # Client UI documentation
├── assets/                  # LOCAL ONLY - no commit / LOCAL SOLO - no commit
│   └── extracted/
└── .gitignore               # Ensure assets/extracted is ignored
```

---

## ⚡ Integration with Client / Integración con el Cliente

### Asset Catalog (Future) / Catálogo de Assets (Futuro)

```rust
// En src/lib.rs
#[tauri::command]
pub fn resolve_asset(path: String) -> Result<String, String> {
    // Resolver path ALDA ↔ DreamFus Client
    // Resolve ALDA ↔ DreamFus Client path
    // Retornar URL o contenido / Return URL or content
    todo!()
}
```

### Usage in Frontend / Uso en Frontend

```javascript
import { assetCatalog } from './assets/catalog.js';

const spriteUrl = assetCatalog.resolve(`gfx/breed_${breed}.png`);
```

---

## 🚫 What NOT to Do / Qué NO se debe hacer

1. **NO distribute** any ALDA or DreamFusion assets
   **NO distribuir** ningún asset de ALDA o DreamFusion

2. **NO upload** extracted assets to the repository
   **NO subir** assets extraídos al repositorio

3. **NO copy** user credentials or account data
   **NO copiar** credenciales o datos de usuarios

---

## 🔧 Useful Tools / Herramientas Útiles

### For Extracting ALDA Assets

Para extraer assets de ALDA

1. **F10/F9 Inspector** - View UI structure in real-time
   **Inspector F10/F9** - Ver estructura UI en tiempo real

2. **dump.cs** - If you have access to exact version
   **dump.cs** - Si tienes acceso a versión exacta

3. **AssetStudio** - For extracting Unity bundles
   **AssetStudio** - Para extraer bundles Unity

### For Local Development

Para desarrollo local

Use placeholders until assets are ready:

```css
.dfui-image {
    background: linear-gradient(45deg, #666, #333);
    border: 2px dashed #888;
}
```

---

## 📚 Related Resources / Recursos Relacionados

- `docs/UI-CLIENTE.md` - Client UI guide
- `docs/research/` - Additional research
- `/docs/client-protocol/` - Protocol documentation

---

## 🎯 Development Process / Proceso de Desarrollo

### 1. Prototype Phase / Fase de Prototipo

Use placeholder assets and solid logic:

```css
/* Placeholder styling */
.dfui-button {
    background: #4a90e2;
    color: white;
    border: none;
    padding: 8px 16px;
}
```

### 2. Asset Integration / Integración de Assets

Replace placeholders with real assets:

```javascript
// Asset resolution with fallback
const assetPath = assetCatalog.resolve(path, {
    fallback: '/assets/placeholder.png'
});
```

### 3. Testing / Pruebas

Always test with both:
- Placeholder assets (to verify logic)
- Real assets (to verify appearance)

---

## 🏗️ Asset Pipeline / Pipeline de Assets

### Future Pipeline Goals / Objetivos del Pipeline

```
ALDA Assets → Extraction Script → Conversion Tool → DFUI Integration → Tauri Bundle
```

1. **Extract** from ALDA/DreamFusion client
   **Extraer** de ALDA/DreamFusion client

2. **Convert** to standard formats
   **Convertir** a formatos estándar

3. **Integrate** into Tauri frontend
   **Integrar** en frontend Tauri

4. **Bundle** with Tauri build
   **Empaquetar** con build Tauri

---

## 📄 Summary / Resumen

| Stage / Etapa | Action / Acción | Tool / Herramienta |
|---------------|-----------------|---------------------|
| Development | Use placeholders | CSS/DFUI |
| Extraction | Get ALDA assets | F10 Inspector, AssetStudio |
| Conversion | Convert to DFUI | Custom scripts |
| Integration | Add to frontend | Tauri/Vite |
| Distribution | Bundle with release | `cargo tauri build` |

---

*Last updated: November 2026*
*Versión: 2.0*