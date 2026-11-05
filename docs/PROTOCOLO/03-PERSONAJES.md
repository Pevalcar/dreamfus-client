# 03 — Personajes (lista, selección, hoja, creación)

Los personajes viajan en varios opcodes: `kvi` (lista), `kvl` (lista borrada), `kvw` (selección), `kvd` (final), `hms` (hechizos), `ivx` (inventario), `kub` (hoja), `kvz` (creación), `kvb` (rechazo). Ver tabla de opcodes en `07-OPCODES.md`.

---

## 1. Lista de personajes (`kvi` y `kvl`)

### 1.1 Formato `kvi` (del servidor)

El servidor envía `kvi` cuando le pregunta el jugador o al iniciar. El formato es un mensaje push (`root 1`):

```
kvi: f1 (repetido) {
    f1: {                       // Detalles del personaje (BuildCharacterDetails)
        f2: "NombreDelPersonaje",
        f3: 150,                 // nivel
        f4: { f2: 0 } o { f2: 3, f3: 1 },  // sexo 0=hembra, 1= macho
        f6: hex...               // look (ver protocol.md)
        f7: 1                    // raza
    },
    f2: 12345678                // ID del personaje
}
```

**Campocampo protobuf:**
- `f1` = lista repetida (el `kvi` completo es `root 1 { f1: <bytes> }`)
- `f2` = ID del personaje (varint)
- Dentro de `f1`: `f2` = nombre, `f3` = nivel, `f4.f2` = sexo, `f6` = look, `f7` = raza

**Orden:** Los personajes llegan ordenados por ID ascendente. El más nuevo va al final.

### 1.2 Formato `kvl` (del servidor)

`kvl` es el complemento de `kvi`. Cuando el servidor quiere decir "ya acabó la lista":

```
kvl: vacío
```

**Importante:** Medido en capturas, `kvd` es el que el cliente recibe para saber que la lista terminó. `kvl` es el ACK de selección (cliente → servidor). Ver tabla de flujos.

### 1.3 Respuesta del cliente: `kvl`

El jugador selecciona un personaje enviando:

```
kvl: f2 {                     // respuesta del cliente
    f2: 12345678             // ID del personaje elegido
}
```

O bien:

```
kvl: f2 {                     // solicitud del cliente
    f1: 12345678             // ID del personaje que quiere seleccionar
}
```

**Distingue:** Un `kvl` con `f1` es petición; uno con `f2` es respuesta. El servidor espera petición (`f1`).

---

## 2. Selección de personaje (`kvw`)

### 2.1 Cliente → Servidor

Después de que el jugador elige en la lista, el cliente envía `kvw` como un push message con payload plano:

```
kvw: f1 {                      // petición del cliente
    f1: 12345678               // ID del personaje (varint plano, NO mensaje anidado)
}
```

**Importante:** El formato correcto es `{ f1: id }` donde `f1` es un varint con el ID del personaje. El bug anterior enviaba `{ f1: { f1: id } }` (mensaje anidado), lo que causaba que el servidor rechazara la selección por no encontrar el character_id.

### 2.2 Servidor → Cliente

Respuesta con identidad del personaje:

```
kva: f1 {                      // respuesta con detalles
    f1 {
        f1: 12345678           // ID
        f2: "Nombre"           // nombre
        f3: 150                // nivel
        f4 { f2: 0, f6: hex, f7: 1 }  // sexo, look, raza
    }
}
```

**Campo `f1` anidado:** El ID va en `f1.f1`, no en `f1.f2`. El nombre va en `f1.f2`.

---

## 3. Hoja de personaje (`kub`)

### 3.1 Formato `kub`

Enviado después de `kva`, con las características del personaje:

```
kub: f1 {                      // raíz
    f2: {                      // cuerpo de características
        // 6 características primarias (f11 anidado)
        f11 { f1: 60, f5: 0, ... }   // fuerza
        f11 { f1: 60, f5: 0, ... }   // vitalidad
        f11 { f1: 60, f5: 0, ... }   // sabiduría
        f11 { f1: 60, f5: 0, ... }   // suerte
        f11 { f1: 60, f5: 0, ... }   // agilidad
        f11 { f1: 60, f5: 0, ... }   // inteligencia
    }
}
```

**IDs de características (de `WorldEntry.CharacteristicIds`):**

| ID | Nombre | f11.f1 |
|----|--------|--------|
| 1 | Fuerza | base |
| 2 | Vitalidad | base |
| 3 | Sabiduría | base |
| 4 | Suerte | base |
| 5 | Agilidad | base |
| 6 | Inteligencia | base |

Los campos `f5` y anteriores contienen modifiers de equipo/alteraciones. Ver `BuildCharacteristics()` en `ConnectionProtocol.cs:606`.

**Valor base por raza (nivel 1):**
- Raza 0 (Héroe): 60 en todo
- Raza 1 (Iop): fuerza 80, vitalidad 40
- Raza 2 (Cra): agilidad 80, vitalidad 40
- Raza 3 (Eniripsig): sabiduría 80, vitalidad 40
- Raza 4 (Ecaflip): suerte 80, vitalidad 40
- Raza 5 (Osamodas): fuerza 60, vitalidad 60
- Raza 6 (Pandawa): agilidad 60, vitalidad 60
- Raza 7 (Rogue): inteligencia 80, vitalidad 40
- Raza 8 (Sram): agilidad 80, vitalidad 40
- Raza 9 (Xelor): sabiduría 80, vitalidad 40
- Raza 10 (Zobal): fuerza 60, vitalidad 60

---

## 4. Hechizos del personaje (`hms`)

### 4.1 Formato `hms`

 mensaje push que lleva los hechizos aprendidos:

```
hms: f2 {                      // wrapper
    f1: {                      // hechizo individual (repetido)
        f1: 3,                 // grado abierto
        f3: 1234,              // ID del hechizo
        f4: 1                  // origen (1 = por defecto, otros = mutaciones)
    }
}
```

**IDs hechizos notables (tutorial nivel 1):**
- `1` = Golpe (Grado 1)
- `2` = Agujeta
- `3` = Empuje

**Origen (`f4`):**
- `1` = aprendido por el nivel (por defecto)
- Otro = mutación/alteración

---

## 5. Inventario (`ivx`)

### 5.1 Formato `ivx`

```
ivx: f1: 150000,              // kamas (opcional, si hay)
     f3 (repetido) {          // ítem
        f1: slot,           // posición (ver tabla)
        f5 {                 // plantilla del ítem
            f1: 12345,      // ID de plantilla
            f2 (repetido) {  // efectos
                f11: valor, f14: tipo, ...
            },
            f3: qty,        // cantidad
            f4: uid         // ID único
        }
    }
```

### 5.2 Slots de inventario

| Rango | Contenido |
|-------|-----------|
| 0 | Amuleto (omitido en proto3, siempre está) |
| 1-15 | Equipado: arma, dos anillos, cinturón, botas, sombrero, capa, mascota, 6 dofus + escudo |
| 16-62 | Mochila (bag) |
| 63 | Mochila (etiqueta "Mochila") |

**Nota:** El slot 0 se omite porque protobuf3 ignora valores cero. El cliente sabe que el amuleto siempre está.

---

## 6. Crear personaje (`kvz` → `kvb`)

### 6.1 Cliente → Servidor (`kvz`)

```
kvz: f1 {                     // creación
    f1: {                    // datos del personaje
        f1: "Nombre",        // nombre
        f2: 0,               // cabeza (0-426)
        f3: [1, 2, 3, 4],   // colores (packed varints, -1 = color por defecto de raza)
        f6: 0,               // sexo (0=f, 1=m)
        f7: 1                // raza (0=Héroe, 1=Iop, etc.)
    }
}
```

### 6.2 Respuesta: `kvb`

**Éxito (vacío):**
```
kvb: vacío
```

**Error:**
```
kvb: f2: código
```

| Código | Significado |
|--------|------------|
| 1 | Nombre rechazado (palabras prohibidas) |
| 2 | Nombre ya existe |
| 3 | Límite de personajes alcanzado (máx 6) |
| vacío | Éxito |

### 6.3 Estado después de crear

Después de `kvb` exitoso, el servidor envía:

1. `kvi` con la lista actualizada
2. El nuevo personaje va **primero** en la lista (ID más alto = insertado al inicio)
3. Mapa inicial: `191105026` (Astrub zaap)
4. Kamas iniciales: `1.000.000`
5. Estadísticas iniciales: 101 en cada una
6. Equipo inicial: Conjunto de Aventurero (Adventurer set)

---

## 7. Borrar personaje

Protocolo no implementado. El cliente debe enviar `kvd` con `f2: id` al servidor para pedir borrado. El servidor responde con `kvn` o `kvd` según resultado.

---

## 8. Tabla de XP (1.889 niveles)

Los primeros 200 niveles siguen la tabla oficial de Dofus. Cada 200 niveles hay un salto. Los valores exactos están en `ExperienceTable.cs`:

```csharp
// Primeros 200 niveles
1: 0
2: 110        // el nuevo personaje empieza aquí
3: 220
...
200: 116798
201: 143404   // empieza tabla nueva
```

Ver `05-MONSTRUOS-Y-DROPS.md` §6 para cómo se guarda la experiencia.