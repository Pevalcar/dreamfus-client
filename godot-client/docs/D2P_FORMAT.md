# D2P Format

## Overview

D2P (Deer2 Packed?) is Ankama's legacy archive format used for various game resources:
- Map assets (`mapsX.d2p`) containing ``.dlm`` map files
- World graphics (`gfxX.d2p`) containing ``.png`` and ``.d2p`` images
- The ``d3maps.d2p`` archive which stores all the per‑map ``mapsX.d2p`` files in one compressed bundle.

All D2P files follow a simple header‑+‑index structure:

```
+0x00 02 01 00 04          magic
+0x04 NUL‑terminated ASCII name (usually "link")
+...> repeated entries (index)
...+ data section (offsets relative to this point)
```

## Header

```
04 bytes: magic = 02 01 00 04  (this file is a D2P archive)
 pos+4  NUL‑terminated internal name
          ASCII, e.g. "link" or "maps1.d2p"
 ```
The internal name is not used for extraction but helps identify the archive.

## Index entries

The index is a sequential list of file‑like entries.  Each entry starts with the length of the name.

```
+pos   u8   nameLen
+pos+1 char  name[nameLen]      (ASCII, printable)
+pos+1+nameLen  u32  offset   (big‑endian, relative to the data section)
+pos+1+nameLen+4  u32  size     (big‑endian)
+pos+1+nameLen+8  u8   0x00              padding (may be missing after the very last entry)
```

### name examples

| Value               | Meaning                                    |
|---------------------|--------------------------------------------|
| ``link``            | internal pointer to another ``.d2p`` file  |
| ``maps1.d2p``       | link to the next per‑map archive           |
| ``png/54032.png``   | PNG image inside a ``gfxX.d2p`` archive      |
| ``0/0.dlm``         | map data (DLM) inside a ``mapsX.d2p`` archive|
| ``9/88212759.dlm``  | the exact map file we use for Incarnam (ID 88212759) |

### Link entries

If ``name`` ends with ``.d2p``, the entry **does not contain offset/size** and the parser treats it as a link.  The byte immediately after the name is a zero‑byte (same as other entries) and the parser skips to the next entry.  This matches the pattern we observed in ``maps0.d2p`` → ``maps1.d2p`` and ``d3maps.d2p`` → ``maps1.d2p``.

### offset+size layout

* ``offset`` and ``size`` are both **big‑endian** (not little‑endian as in most PKZIP‑style archives).
* ``offset`` is relative to the **data section**, which is the byte **after the last entry’s footer**.
* The **first entry** (`0/0.dlm`) typically has ``offset == 0`` – meaning it is stored directly after the index.
* Offsets may overlap or be sparse; they are not required to be sorted.

### Padding

Every entry except the **final one** ends with a single ``0x00`` byte.  The last entry omits this byte, signalling the end of the index and the start of the data section.

## Data section

The data section starts at ``dataStart`` = ``indexEnd``.  The parser tracks the overall file length and knows where the raw chunks begin.

All named entries are extracted exactly as ``data[dataStart + offset … dataStart + offset + size]``.

## Variants in the wild

* ``mapsX.d2p`` (e.g., ``maps2.d2p``) – contains only ``.dlm`` files and links between the ``mapsX.d2p`` files.
* ``gfxX.d2p`` (e.g., ``gfx13.d2p``) – contains ``.png`` images and a final link entry (``gfx14.d2p``).
* ``d3maps.d2p`` – **NOT** a D2P archive in the strict sense; its magic is ``02 01 78 da ed 7d`` which decompresses via **zlib** to a custom ``D3M2`` container that stores ``mapsX.d2p`` and ``gfxX.d2p`` archives.

For the purpose of learning the format **without extracting graphics**, the ``mapsX.d2p`` archives are the cleanest entry point because they are raw D2P without an extra compression layer.

## Python helper (`tools/d2p.py`)

A minimal, dependency‑free D2P reader was written to explore the archives.  It implements exactly the format described above and can list, extract and unpack archives.

```bash
# list entries in a D2P archive
python tools/d2p.py list "<archive.d2p>" [substring]

# extract one entry to a file
python tools/d2p.py extract "<archive.d2p>" "<entry-name>" "<out-file>"

# unpack the whole archive to a directory
python tools/d2p.py unpack "<archive.d2p>" "<out-dir>" [substring]
```

The implementation deliberately does **not** validate internal PNG or DLM integrity – it only extracts the raw bytes.  For a full parser of the graphics you would need to add PNG and DLM decoders, but those are out of scope for the "documentation‑only” requirement.

## Reconstructing the map (Incarnam – 88212759)

The project’s goal is to render the first Dofus map using **client‑side JSON** – i.e., we never touch the D2P archives at runtime.  The JSON files are extracted once (using ``tools/extract_map_data.py``) and stored under ``godot-client/assets/maps/map_88212759.json``.

To convert the ``.dlm`` data (which is still inside ``maps2.d2p``) into the JSON format you need:

1. **Use the D2P reader to extract** ``9/88212759.dlm`` from ``maps2.d2p``.
2. **Decompress** the ``.dlm`` content with ``zlib.decompress``.  It contains a binary DLM format – a mixture of chunk headers (``type(u16?), len(u16?), data``) and a run‑length encoded or raw cell table.  For rendering we only need the **560 cell table** that lives in the tail of the decompressed stream.
3. **Parse the tail** – 560 cells × 4 bytes = 2240 bytes – as little‑endian 32‑bit integers (RGBA‑packed).  The last 560 entries map directly to the 14×40 grid (row‑major, using cell id = row×14 + col).
4. **Map to terrain** – the cell values are not element‑type IDs; we need the separate walkable / fight / blocked JSONs to decide whether a cell is a wall, path, or ground.
5. **Export** – walk the grid, produce three parallel arrays (walkable IDs, fight IDs, blocked IDs) and write the compact ``map_88212759.json``.

The steps are captured in ``tools/extract_map_data.py`` – it reads the two large datos JSON files, picks only map 88212759 and writes the small, Godot‑friendly version.

## Limitations and considerations

* **No decompression in D2P reader** – ``d3maps.d2p`` needs an extra zlib layer; the ``mapsX.d2p`` archives are self‑contained.
* **Binary DLM parser** – the decompressed ``.dlm`` data is a custom chunk format; we never need to fully understand it for the map renderer because the cell IDs are already provided by the client‑side JSONs.
* **Grid assumption** – the rendering code assumes a 14×40 grid (hard‑coded).  For a generic map renderer you would read the ``xSize`` / ``ySize`` from the JSON.
* **Isometric tile size** – Godot’s ``TileMapLayer`` with ``TILE_SHAPE_ISOMETRIC`` and ``tile_size = Vector2(64,32)`` reproduces the exact pixel formula ``pixel = [(col - row) * 32, (col + row) * 16]`` required by the task.
* **Procedural tiles** – ``tools/generate_tiles.py`` creates PNG assets for the 8 ``ElementType`` values.  The ``MapManager.gd`` reads those PNGs at runtime, so the visual assets are generated **outside** Godot – fulfilling the requirement to document the procedural step.
* **Server data source** – the two JSON files are taken from the *server* ``datos/`` directory (a local copy of the live client’s metadata).  The Godot client never contacts the server – all data is baked in at build‑time.

## References

* ``tools/d2p.py`` – D2P archive reader.
* ``tools/extract_map_data.py`` – JSON extractor for map 88212759.
* ``tools/generate_tiles.py`` – procedural tile generator.
* ``godot-client/src/Core/MapManager.gd`` – runtime TileMap renderer.
* ``godot-client/scenes/MapDemo.tscn`` – demo scene that instantiates ``MapManager``.

## Verification

Running the demo scene confirms the map renders correctly:

```bash
godot --headless --path godot-client --scene "res://scenes/MapDemo.tscn" --quit
# [MapManager] Map 88212759: 523 cells placed (274 walkable, 19 blocked)
# [MapManager] Camera centered at (-416.0, 432.0) (grid 14x40)
```

The 8 procedural tiles each contain 1086 non‑transparent pixels inside a
64×32 isometric diamond – the TileSet is built at runtime from those PNGs,
so the map renders without any editor import step.

## Future extensions (for learning)

* Implement a full DLM parser to convert the binary ``.dlm`` files to the JSON format – this would let you work directly with the D2P archives instead of the server‑side JSON.
* Add support for other maps by running the extractor on different IDs – the same procedure works for any ``mapsX.d2p`` archive.
* Replace the hardcoded ``14×40`` grid with dynamic values from the JSON (adds flexibility).
* Swap the runtime image‑loading for actual ``.png`` assets imported into Godot (removes the need for ``Image.load_from_file``).

---

*Document created: 2025‑11‑11*  
*Purpose: learning and reference for the D2P format – no code that touches the archives at runtime.*
