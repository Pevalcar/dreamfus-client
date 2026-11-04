# Protocolo de DreamFus — índice

Referencia del protocolo que habla el **cliente Godot 4.8** de DreamFus contra el servidor de
`..\jondo-servidor`. Todo lo que hay aquí está sacado del servidor y de sus capturas, no de
suposiciones. Cuando algo no está medido, se dice.

Esta carpeta es para quien va a implementar el cliente. Se lee en orden la primera vez; después se
usa como diccionario.

---

## 1. Qué hay en cada archivo

| Archivo | Qué responde |
|---|---|
| [`01-TRANSPORTE.md`](01-TRANSPORTE.md) | Cómo viaja un byte: WebSocket 5557 (JSON), TCP 5555 (VarInt + protobuf), envelope, request id, límites. Con recetas GDScript. |
| [`02-LOGIN-Y-CUENTAS.md`](02-LOGIN-Y-CUENTAS.md) | Usuario/contraseña → token HTTP → auth por WebSocket → ticket → partida. Códigos de error y el árbol de nodos que hace falta. |
| [`03-PERSONAJES.md`](03-PERSONAJES.md) | Lista de personajes, selección, hoja, hechizos, inventario, creación y borrado. |
| [`04-MUNDO-MAPAS-MOVIMIENTO.md`](04-MUNDO-MAPAS-MOVIMIENTO.md) | Cargar mapa, actores, caminar, cambiar de mapa, celdas de llegada. |
| [`05-MONSTRUOS-Y-DROPS.md`](05-MONSTRUOS-Y-DROPS.md) | Grupos de monstruos, grados, archimonstruos, tablas de drop, botín aleatorio, moneda Jondo, recolección. |
| [`06-COMBATE.md`](06-COMBATE.md) | Por qué hoy no se puede empezar una pelea y qué manda el servidor cuando la prepara. |
| [`07-OPCODES.md`](07-OPCODES.md) | Tabla de opcodes vivos, muertos y ausentes; aviso sobre `datos/dofus3_mappings.json`. |
| [`08-INTERACTIVOS.md`](08-INTERACTIVOS.md) | Zaaps, zaapis, anomalías, casas, merkasako (haven bag), cofres, lotería, NPC. |
| [`09-CHECKLIST-CLIENTE.md`](09-CHECKLIST-CLIENTE.md) | Qué falta en el cliente Godot, en qué orden hacerlo, y los fallos que ya tiene el código actual. |

---

## 2. Estado real del cliente, en una frase

Hoy el cliente Godot **solo llega al WebSocket de login**. No abre el TCP 5555, no presenta el
ticket, no recibe la lista de personajes y no entra al mundo. `09-CHECKLIST-CLIENTE.md` tiene el
plan y los cuatro fallos concretos que lo impiden.

---

## 3. Los puertos

| Puerto | Transporte | Para qué |
|---|---|---|
| 8888 | HTTP | `/api/entrar`, `/api/crear-cuenta`, `/config/dofus3.json`, HAAPI. |
| 5557 | WebSocket + JSON con prefijo de 4 bytes | Login del cliente nuevo (`auth_request`, `server_selection`). |
| 5555 | TCP, VarInt + protobuf | **Dos protocolos**: servidor de conexión (primer frame sin `type.ankama.com`) y partida (con él). |
| 5556 | TCP | Listener muerto. Nunca se conecta nadie: el ticket devuelve `[5555, 5555]`. |
| 15881 | Thrift / HTTP / WebSocket | Servicio Zaap del launcher. |
| 6337 | TLS | Chat. |

Todo escucha en `127.0.0.1`. El servidor tiene que estar levantado antes de probar.

---

## 4. El viaje completo, de la contraseña al mapa

```
1. POST http://127.0.0.1:8888/api/entrar
   {usuario, clave, ip}                  -> {bien, token, cuenta, apodo, rol}

2. ws://127.0.0.1:5557
   {type:"auth_request", token, installId, lang, version}
                                          -> {type:"auth_response", success, account_id, servers[]}
   (si falla: {type:"error", code, message})

3. mismo WebSocket
   {type:"server_selection", server_id:290, account_id, lang}
                                          -> {type:"server_selection_response", success, ticket, host, ports}
   (el servidor cierra el WebSocket 100 ms después)

4. TCP 127.0.0.1:5555  (partida)
   kqz {f2: ticket}  +  krt          -> ráfaga de bienvenida
   kvc, krv                          -> kvi (lista de personajes) + kvd (fin de lista)
   kvw {f1: id}                      -> bloque 1 (personaje, hoja, quests...)  ~330 mensajes
   lqc                               -> bloque 2 (4 catálogos)
   kqo (heartbeat)                   -> kqy {f1:1}
   kmr                               -> jru {f2: mapa}  (bloque 3)
   jrh                               -> jss (actores) + lva (fin de lista)
```

Cada paso se explica con sus bytes en su archivo. El orden importa: el bloque 3 lleva `jru`, y
`jru` significa "carga este mapa". Si se manda antes de que el cliente lo pida, lo tira.

---

## 5. Glosario mínimo

- **Opcode**: tres letras (`jru`, `kvi`, `kqz`). Va dentro del type URL
  `type.ankama.com/<opcode>`. Tres letras exactas, ni dos ni cuatro: si te equivocas de longitud el
  cliente no da error, simplemente ignora el mensaje.
- **Frame**: un prefijo de longitud + un mensaje. Un frame = un mensaje, y un mensaje nunca ocupa
  dos frames.
- **Envelope**: el sobre protobuf con tres campos raíz. `1` = push del servidor, `2` = petición del
  cliente, `3` = respuesta del servidor con el id de la petición.
- **Any**: `{f1: "type.ankama.com/xxx", f2: bytes del payload}`.
- **Push**: mensaje que el servidor manda por su cuenta. El 94 % del tráfico.
- **Request id**: el cliente manda `-1` en el 98,9 % de las peticiones. Nunca contestes con `-1`
  fijo: lee el id y devuélvelo.
- **Continente**: campo `f2` de `bien` según convenga. En esta documentación `fN` = campo protobuf N.
- **Merkasako**: nombre del haven bag en el código del servidor.

---

## 6. Reglas que valen para todo

1. **No tocar `.tscn`.** Las escenas las monta el programador en el editor. El agente entrega el
   árbol de nodos y escribe `.gd`. Un `edit` de texto en una `.tscn` la corrompe.
2. **No fiarse de `datos/dofus3_mappings.json`.** Solo 16 de sus 93 opcodes existen en 3.6.10.10, y
   varios nombres están cambiados de dirección. Ver `07-OPCODES.md`.
3. **El id de petición se devuelve, no se inventa.**
4. **Un `jru` por entrada al mundo**, no dos: el cliente recarga el mundo en bucle.
5. **El cliente limita los mensajes a 128 KiB (131.072 bytes).** El envelope no fragmenta. Si un
   mensaje se pasa, el cliente lo tira dentro de su propia capa TCP y no avisa al servidor.
6. **Sondear `WebSocketPeer.get_ready_state()` desde `_process`**, no fiarse de las señales
   `connection_established` / `connection_closed`: en Godot 4.8 beta2 no disparan de forma fiable.
7. **La cuenta de pruebas** es `keka` / `test`, cuenta `188940901`, servidor `290`.

---

## 7. Cómo comprobar lo que leas aquí

Con el servidor levantado (HTTP 8888 + WS 5557 + TCP 5555):

```powershell
$godot = "C:\Users\pevalcar\Godot\Godot.exe"
$project = "C:\Users\pevalcar\Proyects\jondo-servidor\DofusClient\godot-client"

# Arranque real: canta los errores de runtime
& $godot --headless --path $project --quit

# Parsear un script suelto
& $godot --headless --path $project --check-only --script res://src/Core/Main.gd
```

En el servidor, las herramientas de captura están documentadas en
`..\..\docs\protocol.md` §10 (`py tools/pcap.py`, `py tools/cliente_falso.py`). `cliente_falso.py`
recorre todo este flujo sin abrir el juego y es la mejor prueba de que el servidor hace lo que dice
esta carpeta.

---

## 8. Qué está verificado y qué no

| Nivel | Significado |
|---|---|
| **Medido** | Leído en capturas reales o comprobado en el código del servidor. Aparece citado. |
| **Implementado** | El servidor lo manda y funciona, aunque quizá no se haya medido contra el cliente real. |
| **Sin medir** | Hay una forma deducida, pero no está confirmada. Se marca así. |
| **No existe** | El servidor no lo implementa. No lo inventes en el cliente. |

Lo que **no** existe hoy, y por tanto el cliente no debe esperar: otras personas en el mapa, NPC
con diálogo completo, combate jugable, mazmorras, subastas, casas comprables, y el 99 % de los
elementos interactivos.
