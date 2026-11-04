# 07 — Opcodes

Listado de opcodes del protocolo 3.6.10.10 (SimpleProtocol), con estado y descripción.

---

## 1. Opcodes implementados en el servidor

### 1.1 Login y autenticación

| Opcode | Dirección | Descripción | Estado |
|--------|-----------|-------------|--------|
| `kqz` | C→S | Presentar ticket al servidor | ✅ |
| `krt` | C→S | Confirmar presentación (vacío) | ✅ |
| `kvz` | C→S | Crear personaje | ✅ |
| `kvc` | C→S | Ver personajes (sin parámetros) | ✅ |
| `kvw` | C→S | Seleccionar personaje | ✅ |
| `kvl` | C→S | Seleccionar con ID alternativo | ✅ |
| `kvd` | S→C | Fin de lista de personajes | ✅ |

### 1.2 Mapa y movimiento

| Opcode | Dirección | Descripción | Estado |
|--------|-----------|-------------|--------|
| `jru` | S→C | Cargar mapa indicado | ✅ (push) |
| `jrh` | S→C | Notificar llegada a mapa | ✅ (push) |
| `hjk` | S→C | Mapa con celdas ocupadas | ✅ (push) |
| `jss` | S→C | Lista de actores en el mapa | ✅ (push) |
| `lva` | S→C | Fin de lista de actores | ✅ (push) |
| `jrw` | C→S | Mover a celda (packed) | ✅ |
| `jsj` | S→C | Posición del jugador | ✅ (push) |
| `jqi` | C→S | Llegó a borde del mapa | ✅ |
| `jsq` | S→C | Permiso para cambiar de mapa | ✅ (push) |
| `jqk` | C→S | Cambiar de mapa confirmado | ✅ |
| `jsd` | S→C | Cargar datos del mapa vecino | ✅ (push) |

### 1.3 Personajes e inventario

| Opcode | Dirección | Descripción | Estado |
|--------|-----------|-------------|--------|
| `kvi` | S→C | Lista de personajes | ✅ |
| `kva` | S→C | Identidad del personaje seleccionado | ✅ |
| `kub` | S→C | Hoja de características | ✅ |
| `hms` | S→C | Hechizos del personaje | ✅ |
| `ivx` | S→C | Inventario completo | ✅ |
| `iuk` | C→S | Mover/colocar item | ✅ |
| `ivq` | S→C | Item movido con éxito | ✅ |
| `iun` | S→C | Pod actualizado | ✅ |

### 1.4 Sistema de combate

| Opcode | Dirección | Descripción | Estado |
|--------|-----------|-------------|--------|
| `hqa` | C→S | Iniciar pelea con NPC/monstruo | ⚠️ (partially) |
| `jxg` | S→C | Datos del fighter | ⚠️ (no wired) |
| `kba` | S→C | Barra de hechizos | ⚠️ (no wired) |
| `jzu` | S→C | Estado de turno | ⚠️ (no wired) |
| `jwq` | C→S | Pedir lanzar hechizo | ⚠️ (no wired) |
| `jrk` | C→S | Confirmar lanzamiento | ⚠️ (no wired) |
| `jyg` | S→C | Efecto lanzado | ⚠️ (no wired) |
| `jyx` | S→C | Resultado de hechizo | ⚠️ (no wired) |
| `jya` | C→S | Fin de turno | ⚠️ (no wired) |
| `jyj` | S→C | Fin de pelea | ⚠️ (no wired) |

### 1.5 Interactivos

| Opcode | Dirección | Descripción | Estado |
|--------|-----------|-------------|--------|
| `iwo` | C→S | Solicitar interacción | ✅ (basico) |
| `iwn` | S→C | Confirmación de interacción | ✅ (basico) |
| `hjj` | S→C | Entrada de zaap (resultado) | ✅ (basic) |
| `iwb` | S→C | Resultado interactivo | ✅ (basic) |

### 1.6 Eventos y mensajes

| Opcode | Dirección | Descripción | Estado |
|--------|-----------|-------------|--------|
| `kqo` | C→S | Heartbeat cada 5s | ✅ |
| `kqy` | S→C | Respuesta de heartbeat | ✅ |
| `lqc` | C→S | Confirmar recepción catálogo | ✅ |

### 1.7 Drops y recompensas

| Opcode | Dirección | Descripción | Estado |
|--------|-----------|-------------|--------|
| `iua` | S→C | Entrega de item (drop) | ✅ |
| `ivj` | S→C | Ajuste de stack | ✅ |
| `itn` | S→C | Nuevo item (notificación) | ✅ |

---

## 2. Opcodes muertos (no implementados o no usados)

Estos opcodes aparecen en el código pero NO se usan en 3.6.10.10:

| Opcode | Dirección | Descripción | Razón |
|--------|-----------|-------------|-------|
| `lys` | - | - | No existe en 3.6.10.10 |
| `kqt` | - | - | Antiguo formato de ticket |
| `kqu` | - | - | Obsoleto |
| `lxy` | - | - | Sistema antiguo de inventario |
| `kqq` | - | - | Sistema antiguo de sesiones |

---

## 3. Opcodes ausentes (feature gap)

Estas áreas del juego NO tienen opcodes implementados actualmente:

### 3.1 Guild (gremio) - 71 opcodes

Los gremios son el sistema más grande sin implementar. Ver `07-OPCODES.md` de docs/gamelogic.md.

### 3.2 Trading (intercambio)

```
ket 5S, keq 4S, kfz 3S
```

### 3.3 Parties (grupos)

```
ime 2C, imy 1C
```

### 3.4 Chat channels (chats)

```
mgb, mfx, mfp, mfo, mff, mfe
```

### 3.5 Emotes (gestos)

```
hov 19C, hoc 7S, hor 2C, hns 2S
```

---

## 4. Verificación de opcodes

### 4.1 Cómo verificar un opcode

Usa `py tools/pcap.py` para analizar capturas:

```bash
py tools/pcap.py <archivo.pcapng> --opcode kvi
```

O filtra por dirección:

```bash
py tools/pcap.py <archivo.pcapng> --direction CS  # client to server
py tools/pcap.py <archivo.pcapng> --direction SC  # server to client
```

### 4.2 Campos importantes

Los opcodes tienen estructura de campos protobuf. Para verificar:

```bash
py tools/cliente_falso.py --opcode kvi
```

---

## 5. Advertencia: datos/dofus3_mappings.json

El archivo `datos/dofus3_mappings.json` **NO es confiable** para el cliente Godot:

- Solo **16 de 93** opcodes listados existen en 3.6.10.10
- Los nombres pueden estar cambiados de dirección (`CS` vs `SC`)
- Muchos opcodes fueron renombrados entre versiones

**Verifica siempre contra el código del servidor o contra una captura real**, nunca contra `dofus3_mappings.json`.

---

## 6. Tabla resumen

| Área | Opcodes existentes | Opcodes implementados | Prioridad |
|------|-------------------|----------------------|-----------|
| Login/Auth | 10 | 10 | ✅ (completo) |
| World/Movement | 45 | 18 | 🔴 (crítico) |
| Combat | 200+ | 0 | 🔴 (bloqueado) |
| Characters | 20 | 12 | ✅ (parcial) |
| Inventory | 15 | 8 | 🟡 (medio) |
| Interactive | 25 | 5 | 🟡 (medio) |
| Guild | 71 | 0 | 🔴 (no hay) |
| Chat | 6 | 0 | 🟢 (bajo) |

**Prioridad actual:** Solo se necesita el flujo de login + world movement para que el cliente funcione. Combate es el bloque principal.