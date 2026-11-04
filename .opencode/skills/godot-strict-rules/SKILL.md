---
name: godot-strict-rules
description: Reglas estrictas para desarrollo en Godot 4.8 con GDScript. Garantiza código válido, tipado y libre de alucinaciones de nodos antes de cada entrega.
---

# Skill: Reglas Estrictas Godot 4.8

## Obligatorio antes de cualquier entrega

1. **NUNCA editar archivos `.tscn` o `.tres` directamente.**
   - Los `.tscn` se modifican solo desde el editor de Godot.
   - Si necesitas un nodo nuevo, describir el árbol en formato texto y dejar que el programador lo monte.
   - Para instanciar dinámicamente: `var node = SomeClass.new(); add_child(node)`.

2. **Tipado estricto obligatorio en todo GDScript.**
   - Cada variable, argumento y retorno debe tener tipo explícito.
   - No usar `var x` sin tipo a menos que sea estrictamente necesario.
   - Usar `var name: String = ""`, `var count: int = 0`, `var speed: float = 5.0`.

3. **Referencias seguras a nodos.**
   - Usar `@onready var nombre_nodo: Tipo = $Ruta/Como/Está` solo cuando la ruta sea confirmada.
   - NUNCA asumir rutas de nodos que no se han verificado.
   - Si hay duda, preguntar al desarrollador la jerarquía exacta del nodo.

4. **Clases globales con `class_name`.**
   - Todo script reutilizable debe tener `class_name NombreUnico`.
   - Esto permite referenciarlo sin `load()` o rutas relativas.
   - Ejemplo: `class_name GameManager extends Node`.

5. **Validación de buffers y red.**
   - Antes de hacer `slice()`, `get_string_from_utf8()`, o acceder a índices, validar tamaño.
   - Nunca asumir que un `PackedByteArray` tiene datos; siempre verificar `.size() > 0`.
   - Verificar limites antes de leer varints o campos repetidos.

## Flujo de trabajo

### Paso 1: Código primero, UI después

- Crear lógica pura en scripts `Node` o `RefCounted` sin depender de la escena.
- La UI se instancia después, conectando señales.

### Paso 2: Verificación con Godot CLI

Después de escribir cada archivo `.gd`, ejecutar:

```powershell
$godot = "C:\Users\pevalcar\Godot\Godot.exe"
$project = "C:\Users\pevalcar\Proyects\jondo-servidor\DofusClient\godot-client"
& $godot --headless --path $project --check-only --script res://ruta/al/script.gd
```

- Si hay error, copiar el mensaje exacto y corregirlo inmediatamente.
- No asumir que el código funciona sin haber pasado el check.

### Paso 3: Retroalimentación de errores

Si el comando falla:
1. Copiar el error completo.
2. Corregirlo en el archivo.
3. Volver a ejecutar hasta que pase sin errores.

## Reglas de tipado de Arrays

| Tipo | Cuándo usar | Ejemplo |
|------|-------------|---------|
| `Array` | Arrays heterogéneos o mixtos (Dictionary + objetos) | `_characters_list: Array = Array()` |
| `Array[int]` | Solo enteros | `var ids: Array[int] = Array()` |
| `Array[Dictionary]` | Solo diccionarios | `var fields: Array[Dictionary] = Array()` |
| `Array[TipoClase]` | Solo instancias de una clase | `var chars: Array[CharacterData] = Array()` |

**Prohibido:**
- `var x: Array[CharacterData] = some_array_of_dictionaries` ← Error de tipos
- Mezclar `Dictionary` y objetos en un array fuertemente tipado

**Solución:** Si el array contendrá tipos mixtos, usar `Array` sin parámetro genérico.

## Flujo de trabajo obligatorio

### Paso 1: Escribir código

### Paso 2: Verificar lint INMEDIATAMENTE

Después de CADA cambio en un archivo `.gd`, ejecutar:

```powershell
$godot = "C:\Users\pevalcar\Godot\Godot.exe"
$project = "C:\Users\pevalcar\Proyects\jondo-servidor\DofusClient\godot-client"
& $godot --headless --path $project --check-only --script res://ruta/al/script.gd
```

### Paso 3: Si hay error, corregir y repetir Paso 2

No continuar hasta que pase la verificación.

### Paso 4: Verificación global (obligatoria antes de entrega)

```powershell
# Usando el script automatizado:
.\scripts\Verify-GodotProject.ps1

# O manual:
Get-ChildItem -Path "$project/src" -Recurse -Filter "*.gd" | ForEach-Object {
    $relativePath = $_.FullName.Substring($project.Length + 1).Replace("\", "/")
    & $godot --headless --path $project --check-only --script "res://$relativePath"
}
```

## Patrones prohibidos

| Mal | Bien |
|-----|------|
| `var x` | `var x: int = 0` |
| `@onready var btn = $ VBoxContainer/Button` (con espacios) | `@onready var btn: Button = $VBoxContainer/Button` |
| Editar `.tscn` manualmente | Describir el árbol y pedir que se montes desde el editor |
| `to_byte_array()` en un int | `to_utf8_buffer()` o construir manualmente con `PackedByteArray` |
| Asumir señales inexistentes | Verificar que la señal existe en el script antes de conectar |
| Usar `disconnect()` sobre un `Node` | Renombrar a `disconnect_tcp()` para evitar colisión con `Object.disconnect()` |
| Usar `is_connected()` en un `Node` | Renombrar a `is_tcp_connected()` para evitar colisión con `Object.is_connected(StringName, Callable)` |
| `var x: Array = []` | `var x: Array = Array()` |
| `var x: Array = [{...}]` | Declarar explícitamente `Array[Dictionary]` y crear el diccionario primero |
| `fields.append({"n": n})` sin tipo | `var fields: Array[Dictionary] = Array()` y luego `fields.append({...})` |
| `var x := algo()` sin tipo | `var x: Tipo = algo()` |
| `Array[TipoA]` asignado desde `Array[TipoB]` | Usar `Array` sin genérico o convertir explícitamente |

## Checklist antes de entregar código

- [ ] Todos los tipos están declarados explícitamente
- [ ] No hay variables sin tipo
- [ ] No se editó ningún `.tscn` a mano
- [ ] Las referencias a nodos usan rutas correctas y existen
- [ ] **Se ejecutó `--check-only` después de CADA cambio**
- [ ] Las señales conectadas existen en ambos scripts
- [ ] Los buffers TCP/WS validan tamaños antes de acceder
- [ ] No se usa `= []` ni `= {}` (usar `Array()` o `Dictionary()`)
- [ ] Los diccionarios anónimos tienen tipo `Dictionary` explícito cuando se añaden a arrays tipados
- [ ] No se sobrescriben métodos de `Object` como `disconnect()`, `is_connected()`, etc.
- [ ] Los arrays heterogéneos usan `Array` sin parámetro genérico
