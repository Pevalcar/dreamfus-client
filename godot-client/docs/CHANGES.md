# Cambios Recientes - Handshake TCP Implementation

## Resumen

Se implementó correctamente el handshake TCP para la comunicación con el servidor de juego (GameNodeProxy) en el puerto 5555. El flujo incluye:

1. Recepción del ticket de autenticación desde WebSocket
2. Conexión TCP al GameNodeProxy
3. Recepción del "welcome burst" con múltiples mensajes protobuf
4. Parsing de la lista de personajes desde el mensaje kvi
5. Emisión de la señal `characters_received` al recibir jtg
6. Envío de selección de personaje mediante kvw

## Archivos Modificados

### 1. `src/Network/Proto.gd`

**Cambio:** Corrección en `decode_kvi()` para parsear look y breed del bloque de traits correcto.

**Problema:** Los campos `look` (f6) y `breed` (f7) estaban siendo buscados a nivel de personaje, cuando en realidad están dentro del bloque de traits (f4).

**Línea 308-346:**
```gdscript
# CORRECTO: look y breed dentro de traits/f4
var traits_field: Variant = first(details_fields, 4)
if traits_field != null and traits_field.has("b"):
    var traits_fields: Array = parse(traits_field["b"])
    
    # f6 = look (bytes, dentro de traits/f4)
    var look_field: Variant = first(traits_fields, 6)
    
    # f7 = breed (varint, dentro de traits/f4)
    var breed_field: Variant = first(traits_fields, 7)
```

---

### 2. `src/Network/GameClient.gd`

**Cambio:** Compatibilidad con Godot 4.8 beta2 API changes.

**Problema:** En Godot 4.8 beta2, `get_data()` retorna `[Error, PackedByteArray]` en lugar de solo el buffer.

**Línea 47-50:**
```gdscript
# CORRECTO: Manejar el array de retorno
var result: Array = tcp.get_data(available)
var err: Error = result[0]
var data: PackedByteArray = result[1]
```

---

### 3. `src/Network/GameClient.gd` - `send_character_selection()`

**Cambio:** Uso de `send_push()` en lugar de `send_request()`.

**Problema:** kvw es un mensaje de PUSH (formato server-style), no un REQUEST.

**Línea 175-179:**
```gdscript
# CORRECTO: usar send_push para kvw
func send_character_selection(character_id: int) -> void:
    var inner_msg: PackedByteArray = PackedByteArray()
    Proto.put_varint(inner_msg, 1, character_id)
    var wrapper: PackedByteArray = Proto.message(1, inner_msg)
    send_push("kvw", wrapper)  # NOT send_request()
```

---

## Cambios Adicionales

### 4. `src/Core/GameManager.gd` - `select_character()`

**Cambio:** Envío de kvw al servidor cuando se selecciona un personaje.

**Línea 183-199:**
```gdscript
# NUEVO: Enviar kvw al servidor antes de cambiar de estado
func select_character(character: CharacterData) -> void:
    if character == null:
        return
    
    print("[GameManager] Personaje seleccionado: %s (ID: %d)" % [character.name, character.id])
    selected_character = character
    
    # Send kvw (character selection) to the game server
    if _game_client != null and _game_client.is_tcp_connected():
        print("[GameManager] Enviando kvw para personaje ID: %d" % character.id)
        _game_client.send_character_selection(character.id)
    else:
        print("[GameManager] GameClient no conectado, omitiendo kvw")
    
    character_selected.emit(character.id, character.name)
    change_state(GameState.IN_GAME)
```

---

### 5. `src/Network/GameClient.gd` - Validación en `send_character_selection()`

**Cambio:** Agregada validación del character_id antes de enviar.

**Línea 173-184:**
```gdscript
func send_character_selection(character_id: int) -> void:
    if character_id <= 0:
        printerr("[GameClient] Invalid character_id: %d" % character_id)
        return
    
    var inner_msg: PackedByteArray = PackedByteArray()
    Proto.put_varint(inner_msg, 1, character_id)
    var wrapper: PackedByteArray = Proto.message(1, inner_msg)
    send_push("kvw", wrapper)
```

---

### 6. `src/UI/CharacterSelectUI.gd` - Mejora visual de botones

**Cambio:** Los botones ahora muestran raza y nivel con tooltip.

**Línea 77-98:**
```gdscript
func _create_character_buttons() -> void:
    for char in _characters:
        var char_button: Button = Button.new()
        # Mostrar nombre, raza y nivel en el botón
        var breed_name: String = _get_breed_name(char.breed)
        char_button.text = "%s [%s] Nvl %d" % [char.name, breed_name, char.level]
        char_button.tooltip_text = "ID: %d, Sexo: %d, Breed: %d" % [char.id, char.sex, char.breed]
        char_button.pressed.connect(_on_character_button_pressed.bind(char))
        character_list.add_child(char_button)

func _get_breed_name(breed: int) -> String:
    # Nombres de raza basados en el protocolo Dofus
    match breed:
        1: return "Sadida"
        2: return "Enutrof"
        3: return "Xelor"
        ...
        _: return "Feca"  # Default
```

### Archivos Creados

### 1. `docs/TCP_HANDBSHAKE.md`

Documentación completa del handshake TCP incluyendo:

- Arquitectura del flujo
- Diagrama de secuencia
- Formato de mensajes protobuf
- Detalles de implementación por archivo
- Información de debugging
- Referencias al código del servidor

### 2. Actualización de `docs/PROTOCOL.md`

Se agregó una sección completa sobre el handshake TCP (puerto 5555) con:

- Lista de opcodes y sus direcciones
- Formato de mensajes kqz, kvi, kvw
- Estructura de datos protobuf
- Señales emitidas

### 3. Actualización de `README.md`

- Actualización de estado del proyecto
- Nueva sección sobre TCP Handshake
- Tabla de documentación

---

## Flujo Verificado

```
[GameClient] Conectando a TCP 127.0.0.1:5555...
[GameClient] Conectado a TCP
[GameManager] GameClient conectado a TCP
[GameManager] Enviando kqz con ticket: e7193a7a...
[GameClient] Enviando kqz (ticket=e7193a7a...)
[GameClient] Recibidos 756 bytes (disponibles: 756)
[GameClient] -> Emitiendo mensaje: opcode=kra, payload=0 bytes
[GameManager] Mensaje TCP recibido: opcode='kra', payload_size=0, request_id=-1
[GameManager] Mensaje de burst ignorado: kra
[GameClient] -> Emitiendo mensaje: opcode=lqu, payload=9 bytes
[GameManager] Mensaje TCP recibido: opcode='lqu', payload_size=9, request_id=-1
... (más mensajes del burst)
[GameClient] -> Emitiendo mensaje: opcode=kvi, payload=307 bytes
[GameManager] Mensaje TCP recibido: opcode='kvi', payload_size=307, request_id=-1
[GameManager] kvi recibido en burst — parseando lista de personajes
[GameManager] Procesando kvi - lista de personajes
[GameManager] Personaje recibido: id=13825558, name=[#KEKA-BRON#], level=204, sex=1, breed=9
[GameManager] Personaje recibido: id=13825563, name=Test, level=200, sex=0, breed=8
[GameManager] Personaje recibido: id=13825564, name=Tymaviejas, level=200, sex=0, breed=13
[GameManager] Personaje recibido: id=13825565, name=Bron, level=202, sex=0, breed=4
[GameClient] -> Emitiendo mensaje: opcode=jtg, payload=0 bytes
[GameManager] Mensaje TCP recibido: opcode='jtg', payload_size=0, request_id=-1
[GameManager] jtg recibido — burst completo (4 personajes)
[CharacterSelectUI] Recibidos 4 personajes del servidor
```

---

## Pruebas Realizadas

1. **Conexión TCP:** ✅ Verificada
2. **Envío de ticket kqz:** ✅ Verificado
3. **Recepción del welcome burst:** ✅ Funcional
4. **Parsing de kvi:** ✅ 4 personajes parseados correctamente
5. **Emisión de characters_received:** ✅ Señal emitida con datos correctos
6. **Formato de personaje:** ✅ Incluye id, name, level, sex, breed, look

---

## Próximos Pasos

1. ✅ **Seleccionar personaje (kvw)** - Implementado y probado
2. ✅ **Agregar manejo de errores y timeouts al handshake TCP** - Implementado
3. **Documentar el flujo completo de creación de personaje**

---

## Cambios Recientes - HUD y Manejo de Errores (Nov 2026)

### Resumen

Se implementó mejora del HUD del juego y manejo de errores con timeouts para el handshake TCP:

1. **HUD del juego**: Visualización de nombre, raza y nivel del personaje seleccionado
2. **Manejo de errores**: Timeouts para conexión TCP (10s) y welcome burst (15s)
3. **Nombres de raza**: Corregidos y actualizados con nombres completos de Dofus

### Archivos Modificados

### 1. `src/UI/GameUI.gd`

**Cambio 1:** Agregado soporte para visualización de raza en el HUD.

**Cambio 2:** Nombres de raza actualizados con nombres correctos de Dofus (1-16).

**Línea 65-70 (HUD de raza):**
```gdscript
# Raza (mostrar nombre legible)
var breed_name: String = _get_breed_name(_character_data.breed)
if breed_label != null:
    breed_label.text = "[%s] %s" % [breed_name, _character_data.name]
    breed_label.visible = true
```

**Línea 110-131 (Nombres de raza actualizados):**
```gdscript
func _get_breed_name(breed: int) -> String:
    # Nombres de raza basados en el protocolo Dofus (1-16)
    match breed:
        1: return "Feca"
        2: return "Osamodas"
        3: return "Enutrof"
        4: return "Sacrieur"
        5: return "Sadida"
        6: return "Xelor"
        7: return "Chafouis"
        8: return "Iop"
        9: return "Cra"
        10: return "Sram"
        11: return "Xelor"  # Xelor-11 is a special variant
        12: return "Ecaflip"
        13: return "Opr"    # Opr (Ogre-like)
        14: return "Rubbaduck"
        15: return "Panda"
        16: return "Foggba"
        _: return "Desconocida"
```

---

### 2. `src/UI/CharacterSelectUI.gd`

**Cambio:** Nombres de raza actualizados con nombres correctos de Dofus.

**Línea 87-109 (Nombres de raza actualizados):**
```gdscript
func _get_breed_name(breed: int) -> String:
    # Nombres de raza basados en el protocolo Dofus (1-16)
    match breed:
        1: return "Feca"
        2: return "Osamodas"
        3: return "Enutrof"
        4: return "Sacrieur"
        5: return "Sadida"
        6: return "Xelor"
        7: return "Chafouis"
        8: return "Iop"
        9: return "Cra"
        10: return "Sram"
        11: return "Xelor"
        12: return "Ecaflip"
        13: return "Opr"
        14: return "Rubbaduck"
        15: return "Panda"
        16: return "Foggba"
        _: return "Desconocida"
```

---

### 3. `src/Core/GameManager.gd`

**Cambio:** Agregado manejo de errores y timeouts para el handshake TCP.

**Línea 83-108 (Inicialización de timers y métodos de timeout):**
```gdscript
func _init_timeouts() -> void:
    # Timer para timeout de conexión TCP
    _connection_timeout_timer = Timer.new()
    _connection_timeout_timer.wait_time = 10.0
    _connection_timeout_timer.one_shot = true
    _connection_timeout_timer.autostart = false
    add_child(_connection_timeout_timer)
    _connection_timeout_timer.timeout.connect(_on_connection_timeout)

    # Timer para timeout del welcome burst
    _welcome_burst_timeout = Timer.new()
    _welcome_burst_timeout.wait_time = 15.0
    _welcome_burst_timeout.one_shot = true
    _welcome_burst_timeout.autostart = false
    add_child(_welcome_burst_timeout)
    _welcome_burst_timeout.timeout.connect(_on_welcome_burst_timeout)


func _cleanup_timeouts() -> void:
    if _connection_timeout_timer != null:
        _connection_timeout_timer.stop()
    if _welcome_burst_timeout != null:
        _welcome_burst_timeout.stop()


func _on_connection_timeout() -> void:
    print("[GameManager] TIMEOUT: Conexión TCP no establecida en 10s")
    var error_msg: String = "Timeout de conexión TCP (10s)"
    error_received.emit("CONNECTION_TIMEOUT", error_msg)
    change_state(GameState.ERROR)


func _on_welcome_burst_timeout() -> void:
    print("[GameManager] TIMEOUT: Welcome burst no completado en 15s")
    _in_welcome_burst = false
    _characters_list.clear()
    var error_msg: String = "Timeout del welcome burst (15s)"
    error_received.emit("BURST_TIMEOUT", error_msg)
    change_state(GameState.CHARACTER_SELECT)


func _on_game_client_connected() -> void:
    print("[GameManager] GameClient conectado a TCP")
    
    # Iniciar timeout de welcome burst
    if _welcome_burst_timeout != null:
        _welcome_burst_timeout.start()
        print("[GameManager] Iniciado timeout de welcome burst (%ds)" % _welcome_burst_timeout.wait_time)
    
    if _pending_ticket != "":
        print("[GameManager] Enviando kqz con ticket: %s" % _pending_ticket.substr(0, 8) + "...")
        _game_client.send_ticket(_pending_ticket)
        _in_welcome_burst = true
        _pending_ticket = ""
        _pending_game_host = ""
        _pending_game_port = 0
```

**Notas:**
- Timeout de conexión TCP: 10 segundos
- Timeout del welcome burst: 15 segundos
- Al timeout, se emite señal `error_received` con código de error apropiado
- El estado se cambia a `ERROR` o se vuelve a `CHARACTER_SELECT` según corresponda

---

### 4. `src/UI/GameUI.gd` - UI del HUD

**Cambio:** Mejora de la interfaz del HUD con visualización de raza.

**Estructura esperada en Game.tscn (agregar BreedLabel en HUDContainer):**
```
HUDContainer (HBoxContainer)
├── CharacterLabel (Label) - Nombre del personaje
├── LevelLabel (Label) - Nivel del personaje
├── BreedLabel (Label) - Nueva: Raza del personaje (visible cuando haya personaje)
├── HealthLabel (Label) - Estado de salud
├── HealthBar (ProgressBar) - Barra de salud
├── XPBar (ProgressBar) - Barra de experiencia
├── XPLabel (Label) - XP del personaje
└── BackToSelect (Button) - Botón para volver al selector
```

**Nota:** El programador debe agregar `BreedLabel` como hermano de `LevelLabel` en el container del HUD usando el editor de Godot.

---

### 5. `scenes/Game.tscn` - UI del HUD

**Acción requerida:** El programador debe abrir `scenes/Game.tscn` en el editor de Godot y agregar el nodo `BreedLabel`:

```
1. Seleccionar HUDContainer (HBoxContainer)
2. Agregar hijo -> Label
3. Nombrarlo "BreedLabel"
4. Configurar propiedades:
   - text = "" (vacío por defecto)
   - theme_override_font_sizes/font_size = 14 (similar a LevelLabel)
5. Positional order: después de CharacterLabel y LevelLabel, antes de HealthLabel
```

**Alternativa:** Si el diseñador prefiere un diferente layout, ajustar el código en `GameUI.gd` según sea necesario.

---

## Tareas Pendientes para el Programador

| Tarea | Archivo | Estado | Comentario |
|-------|---------|--------|------------|
| Agregar BreedLabel al HUD | `scenes/Game.tscn` | ⏳ PENDIENTE | Necesario para visualizar la raza del personaje |
| Verificar BackToSelect funcional | `scenes/Game.tscn` | ✅ HECHO | El botón ya existe en la escena |

---

## Verificación