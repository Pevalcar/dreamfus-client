# Sistema de Emblems de Raza (Breed Icons)

## Visión General

El sistema carga emblems de raza (breed icons) desde la instalación de Alea/DreamFus usando una estructura de archivos externa. Esto permite reutilizar los assets oficiales sin incluirlos en el repositorio.

## Arquitectura

### Ruta de Assets

**Desarrollo (temporal):**
```
C:/Users/pevalcar/AppData/Local/Alea/d3picto/hint/
```

**Producción (recomendado):**
```
<executable_dir>/../DreamFus/d3picto/hint/
```

### Estructura de Archivos

```
DreamFus/
├── d3picto/
│   └── hint/
│       ├── 10.png   → Feca (breed=1)
│       ├── 20.png   → Osamodas (breed=2)
│       ├── 30.png   → Enutrof (breed=3)
│       ├── 40.png   → Sacrieur (breed=4)
│       ├── 50.png   → Sadida (breed=5)
│       ├── 60.png   → Xelor (breed=6)
│       ├── 70.png   → Chafouis (breed=7)
│       ├── 80.png   → Iop (breed=8)
│       ├── 90.png   → Cra (breed=9)
│       ├── 100.png  → Sram (breed=10)
│       ├── 110.png  → Ecaflip (breed=11)
│       ├── 120.png  → Ouginak (breed=12)
│       ├── 130.png  → Tymador (breed=13)
│       ├── 140.png  → Rubbaduck (breed=14)
│       ├── 150.png  → Steamer (breed=15)
│       └── 160.png  → Eliotrope (breed=16)
```

## Mapeo de Breed

| breed | Archivo | Raza | Emoji Fallback |
|-------|---------|------|----------------|
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

## Implementación en GDScript

### CharacterSelectUI.gd

```gdscript
# Ruta a assets de emblems (razas) - Temporalmente desde Alea
# Cuando se crea la copia DreamFus, cambiar a: 
# OS.get_executable_path().get_base_dir().path_join("../DreamFus/d3picto/hint/")
const BREED_EMBLEM_PATH := "C:/Users/pevalcar/AppData/Local/Alea/d3picto/hint/"

# Nombres de raza completos y consistentes con el protocolo Dofus
const BREED_NAMES := {
    1: "Feca", 2: "Osamodas", 3: "Enutrof", 4: "Sacrieur",
    5: "Sadida", 6: "Xelor", 7: "Chafouis", 8: "Iop",
    9: "Cra", 10: "Sram", 11: "Ecaflip", 12: "Ouginak",
    13: "Tymador", 14: "Rubbaduck", 15: "Steamer", 16: "Eliotrope"
}

# Carga emblem correctamente numeraando el archivo
func _get_breed_emblem(breed: int) -> Texture2D:
    """
    Obtiene el emblem visual de raza desde los assets de Alea/Dofus
    Los emblems están numerados: breed=1 → 10.png, breed=2 → 20.png, etc.
    """
    if breed < 1 or breed > 16:
        return null
    
    # Convertir breed (1-16) a número de archivo (10, 20, 30...)
    var file_num = breed * 10
    var emblem_path = BREED_EMBLEM_PATH + "%d.png" % file_num
    
    if ResourceLoader.exists(emblem_path):
        return load(emblem_path)
    
    # Fallback: usar emblem genérico
    if ResourceLoader.exists(BREED_EMBLEM_PATH + "10.png"):
        return load(BREED_EMBLEM_PATH + "10.png")
    
    return null

# Fallback visual con emojis
func _get_breed_symbol(breed: int) -> String:
    """Devuelve símbolo Unicode para la raza"""
    match breed:
        1: return "🛡️"    # Feca
        2: return "🐢"    # Osamodas
        3: return "🪙"    # Enutrof
        4: return "💪"    # Sacrieur
        5: return "🐕"    # Sadida
        6: return "⏳"    # Xelor
        7: return "🐝"    # Chafouis
        8: return "⚔️"   # Iop
        9: return "🏹"    # Cra
        10: return "🐍"   # Sram
        11: return "🐱"   # Ecaflip
        12: return "🦄"   # Ouginak
        13: return "🎭"   # Tymador
        14: return "🦆"   # Rubbaduck
        15: return "⚙️"   # Steamer
        16: return "🐸"   # Eliotrope
        _: return "❓"
```

## Uso en CharacterSelectUI.gd

Los emblems se usan en la creación de slots de personaje:

```gdscript
# En _create_character_slots()
var breed_icon: TextureRect = TextureRect.new()
breed_icon.texture = _get_breed_emblem(char_data.breed)
```

## Integración con CharacterData

El campo `breed` en `CharacterData` viene del servidor con valores 1-16:

```json
{
  "id": 13825558,
  "name": "Test",
  "breed": 8,    // Iop
  "level": 200,
  "sex": 0
}
```

## Flujo de Carga

1. Servidor envía lista de personajes con campo `breed` (1-16)
2. CharacterSelectUI itera sobre personajes
3. `_get_breed_emblem(breed)` convierte breed → archivo (1→10.png)
4. Texture2D se carga desde ruta externa
5. Se muestra en UI del selector de personajes

## Actualización de Assets

Cuando necesites actualizar los emblems:

```powershell
# Verificar archivos existentes
Get-ChildItem "C:\Users\pevalcar\AppData\Local\Alea\d3picto\hint\*.png" | Select-Object Name

# Copiar a carpeta local para backup
Copy-Item "C:\Users\pevalcar\AppData\Local\Alea\d3picto\hint\*.png" -Destination "assets/icons/emblems/"
```

## Notas Importantes

- **No subir assets a GitHub**: Los emblems están fuera del repo por tamaño
- **Dependencia externa**: El cliente requiere la carpeta `Alea` o `DreamFus`
- **Fallback automático**: Si un emblem falta, usa 10.png (Feca)
- **Compatibilidad**: Los IDs 1-16 coinciden con el protocolo Dofus original