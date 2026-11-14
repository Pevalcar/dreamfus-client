# 001 — DreamFus Client MVP: login y selección de personaje

## 1. Contexto y objetivo

El cliente de Dofus necesita un módulo de conexión que permita:
- **login**: recibir credenciales, autenticar contra el servidor y obtener sesión.
- **selección**: mostrar personajes y permitir elegir uno o volver al login.

El objetivo es que la persona pueda **autenticarse y entrar en el mundo** con un personaje existente. El cliente no pinta mapas ni procesa movimientos en esta fase.

**Escala:** 002 — Mapa y movimiento, 003 — Transición entre mapas, 004 — Combate.

## 2. Login

Formulario con usuario y contraseña. Al enviarlo, el cliente:
1. Llama `POST http://127.0.0.1:8888/api/entrar` con `{usuario, clave}`.
2. Si `bien: true`, recibe `token`, `cuenta`, `apodo`, `rol`.
3. Si falla, muestra error en español y conserva el usuario.

El cliente **no persiste** el token en disco.

## 3. Selección de personaje

### 3.1 Flujo normal (login)

El cliente solo envía `kqz` (ticket). El servidor contesta la ráfaga que termina en `jtg`:
```
kqz → kra → lqu → hoy → kqu → mgq → mgt → hpd → krs → mgz → kqp×3 → kvi → jtg
```
- `kvi` (CharacterListEvent) trae la lista; `jtg` (GameActionItemListEvent) es el catálogo de regalos, puede venir vacío.
- El cliente muestra la lista de personajes recibida.

### 3.2 Reconexión a combate/koliseo

Si algún personaje de la cuenta sigue en un combate reanudable, el servidor corta la ráfaga en `mgz`: no manda `kqp×3`, `kvi` ni `jtg`. Al pedir la lista (`kvc`) responde:
```
(mgz) → [cliente: kvc] → kvi → kvd → [cliente: kwb]
```
- `kvd` (CharacterForceSelectionEvent): "do not stop here"; solo aparece cuando hay combate reanudable.
- `kwb` (CharacterForceSelectionReadyRequest, sin campos) no nombra personaje: el servidor reanuda el combate del único personaje reanudable de la cuenta.
- `krv` (TokenValidationRequest) existe en el protocolo pero el servidor no lo atiende.

### 3.3 Post-selección

- Elegir un personaje envía `kvw {f1: id_personaje}`. El servidor responde `kva` (CharacterSelectionEvent caso éxito con el personaje) + estado inicial (`kub`, `haapi`, `jtg`, `lqg`).
- El cliente envía `lqc` (SequenceNumberRequest vacío) inmediatamente después de `kub`. El servidor responde con el bloque de mapa que incluye `jru` (MapCurrentEvent) y sigue con tiempo del servidor, hechizos y barras de atajos.
- Si el cliente no envía `lqc`, el primer `kqo` (heartbeat cada 5s) manda el bloque de mapa. No hay temporizador activo en el servidor: los 5s son el intervalo del heartbeat.
- Ir atrás envía `kqq` → el servidor responde `kqr {f1: guid}`, saca al personaje del mapa y el cliente cierra y reconecta usando ese guid como identidad.

## 4. Requisitos funcionales

**RF-1 — Autenticación HTTP.** El cliente debe autenticar al jugador con usuario y contraseña.
- *Evento:* Cuando el jugador envíe credenciales válidas, el cliente deberá mostrar la pantalla de selección de personaje.
- *Condicional:* Si las credenciales son rechazadas, el cliente deberá mostrar un mensaje en español y mantener el formulario con el usuario introducido.

**RF-2 — Validación del formulario.** El cliente debe impedir el envío con campos vacíos o inválidos.
- *Estado:* Mientras algún campo esté vacío o no cumpla el patrón `^[a-zA-Z0-9_@.-]{3,32}$`, el cliente deberá mantener deshabilitada la acción de entrar.
- *Condicional:* Si el servidor responde `motivo` con error, el cliente debe mostrar el mensaje traducido al español.

**RF-3 — Handshake de sesión.** El cliente debe establecer la sesión sin persistir tokens.
- *Evento:* Tras el login HTTP exitoso, el cliente abre WebSocket `/auth_request` (C→S) recibiendo `auth_response` (S→C) con `server_id`, `account_id`, `success`. Luego envía `/server_selection` (C→S) que devuelve `server_selection_response` (S→C) con el `ticket`. Finalmente, por TCP 5555, el cliente presenta el ticket con `kqz`/`krt`.
- *Condicional:* El token se mantiene solo en memoria; no se escribe en `user://` ni en variables de entorno.

**RF-4 — Listado de personajes.** El cliente debe mostrar los personajes de la cuenta autenticada.
- *Evento (login normal):* El servidor entrega la lista completa en el burst: `kqp×3 → kvi → jtg`. El cliente muestra los personajes y el catálogo de regalos (`jtg`, puede estar vacío).
- *Evento (reconexión a combate):* Si el burst se detiene en `mgz`, el cliente envía `kvc` (CharacterListRequest). El servidor responde `kvi` (lista) `kvd` (CharacterForceSelectionEvent, "do not stop here"). El cliente envía `kwb` (CharacterForceSelectionReadyRequest) para reanudar el combate.
- *Condicional:* Si la cuenta no tiene personajes, el cliente debe mostrar un aviso y la opción de volver al login.
- *Nota:* `kvd` solo aparece en reconexiones a combate directo/koliseo; detiene el burst y el cliente procede directamente a reanudar.

**RF-5 — Entrada al mundo.** El cliente debe solicitar la entrada al personaje elegido y esperar confirmación.
- *Evento:* Cuando el jugador seleccione un personaje disponible, el cliente envía `kvw {f1: id_varint32}` y el servidor responde:
  - `kva` (CharacterSelectionEvent caso éxito con el personaje)
  - Estado inicial: `kub` (características) + `haapi` (sesión Haapi) + `jtg` (catálogo regalos)
  - `lqg` (SequenceNumberEvent)
- *Evento:* Tras recibir `kub`, el cliente envía `lqc` (SequenceNumberRequest vacío). El servidor responde `jru` (MapCurrentEvent) con el mapa a cargar.
- *Condicional:* Si el servidor rechaza (personaje ya conectado u otro error), el servidor cierra el socket. El cliente detecta este cierre y muestra error.
- *Ubicuo:* La entrada al mundo es exitosa cuando el cliente recibe `jru` después de `kub`.

**RF-6 — Volver a selección o logout.** El cliente debe permitir volver al login o cerrar sesión.
- *Evento:* Cuando el jugador elija volver, el cliente debe enviar `kqq`, recibir `kqr {f1: guid}`, cerrar conexiones y reconectarse con el token para volver al formulario.
- *Evento:* Alternativamente, el cliente puede cerrar sesión completamente sin reconectar.

## 5. Requisitos no funcionales

- **RNF-5 — Tiempo de respuesta.** Login y selección deben completarse en < 5 s por fase en red local.
- **RNF-6 — Idioma del jugador.** Todo texto visible debe estar en español, traducido de los mensajes del servidor.
- **RNF-7 — Tokens seguros.** El token no se guarda en disco ni en variables de entorno.
- **RNF-8 — Timeout de conexión.** Si no hay respuesta en 5 s, se muestra error y vuelve al login.
- **RNF-9 — No logging de credenciales.** El cliente no debe registrar credenciales ni tokens en logs ni en archivos de depuración.
- **RNF-10 — Heartbeat como trigger de mapa.** El cliente usa `kqo` (PingRequest) cada 5s como mecanismo de fallback: si no se ha enviado `lqc` después de `kub`, el primer `kqo` desencadena el envío del bloque de mapa que termina en `jru`.

## 6. Casos límite

- Credenciales incorrectas: mensaje traducido al español, usuario conservado, contraseña borrada.
- Servidor caído: mensaje "Servidor no disponible", sin reintentos automáticos.
- Conexión perdida durante proceso: vuelve al login.
- Cuenta sin personajes: aviso y botón de volver.
- Personaje ya conectado: el nuevo cliente gana; el expulsado ve aviso; socket cerrado silenciosamente.
- Timeout de autenticación (>5 s por fase): mensaje y vuelve al login.
- Ticket expirado (>5 min): reconexión fallida, vuelve al login.
- Límite de clientes (500): socket cerrado silenciosamente.
- Throttle 5 intentos fallidos/ventana 60s: mensaje "[Anti-DDoS] Access temporarily locked" traducido, IP bloqueada.
- Error JSON inválido o versión desconocida: mensaje error y vuelve al login.

## 7. Fuera de alcance

- Pintado de mapas, movimiento, transición de mapas (ver spec 002 y 003).
- Combate (ver spec 004).
- Actores del mapa, chats, inventario, stats, NPCs, grupos, amigos, etc.

## 8. Criterios de finalización

1. Una persona entra, ve sus personajes, elige uno y el servidor confirma la entrada.
2. Todos los RF quedan verificados, a mano o con prueba automatizada (`test_login_ui_e2e.gd`).
3. No aparece ni un texto en inglés en la interfaz.
4. Revisión final contra la constitución: sin estado persistido, sin lógica de juego en esta fase.

## 9. Dudas abiertas

1. **[NECESITA ACLARACIÓN]** ¿La animación de transición entre mapas es visual o incluye fade? (Fuera de alcance MVP)