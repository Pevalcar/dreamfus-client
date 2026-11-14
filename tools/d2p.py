"""Minimal D2P archive reader (Ankama .d2p), reverse-engineered empirically.

Format
------
header : 4 bytes magic 02 01 00 04
         then a NUL-terminated internal name ("link" on every file seen)
entries: repeated, in order:
         u8   nameLen
         char name[nameLen]        ASCII, e.g. "png/54032.png" or "0/0.dlm"
         u32  offset  (big endian) relative to dataStart
         u32  size    (big endian)
         u8   0x00                 padding (absent on the very last entry)
link entries (name ends in ".d2p") have no offset/size: just name + 0x00.
dataStart = byte after the last entry footer; entry 0 has offset 0.

Usage
-----
  python tools/d2p.py list    <archive.d2p> [substring]
  python tools/d2p.py extract <archive.d2p> <entry-name> <out-file>
  python tools/d2p.py unpack  <archive.d2p> <out-dir> [substring]
"""

import struct
import sys
from pathlib import Path

MAGIC = b"\x02\x01\x00\x04"


def read_index(path):
    """Return (links, entries, data_start).

    entries is a list of (name, offset, size); data_start is the absolute
    byte offset where entry data begins (offsets are relative to it).
    """
    data = Path(path).read_bytes()
    if data[:4] != MAGIC:
        raise ValueError(f"{path}: not a D2P archive (magic {data[:4].hex()})")

    pos = data.index(b"\x00", 4) + 1  # skip NUL-terminated internal name
    links, entries = [], []
    while pos < len(data):
        name_len = data[pos]
        name = data[pos + 1 : pos + 1 + name_len]
        if not name_len or not _is_name(name):
            break  # reached the data section
        name = name.decode("ascii")
        pos += 1 + name_len

        if name.lower().endswith(".d2p"):
            links.append(name)
            pos += 1
            continue

        offset, size = struct.unpack(">II", data[pos : pos + 8])
        entries.append((name, offset, size))
        pos += 8
        # padding byte, missing after the final entry
        if pos < len(data) and data[pos] == 0:
            probe = data[pos + 1]
            if probe and _is_name(data[pos + 2 : pos + 2 + probe]):
                pos += 1

    return links, entries, pos


def _is_name(raw):
    return bool(raw) and all(32 <= c < 127 for c in raw)


def read_entry(path, name):
    data = Path(path).read_bytes()
    _, entries, data_start = read_index(path)
    for entry_name, offset, size in entries:
        if entry_name == name:
            return data[data_start + offset : data_start + offset + size]
    raise KeyError(name)


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 1
    cmd, archive = argv[1], argv[2]

    if cmd == "list":
        needle = argv[3] if len(argv) > 3 else ""
        links, entries, data_start = read_index(archive)
        for name in links:
            print(f"link  {name}")
        for name, offset, size in entries:
            if needle in name:
                print(f"{size:>10}  {name}")
        print(f"-- {len(entries)} entries, data at {data_start}", file=sys.stderr)
        return 0

    if cmd == "extract":
        blob = read_entry(archive, argv[3])
        Path(argv[4]).write_bytes(blob)
        print(f"{len(blob)} bytes -> {argv[4]}")
        return 0

    if cmd == "unpack":
        out = Path(argv[3])
        needle = argv[4] if len(argv) > 4 else ""
        data = Path(archive).read_bytes()
        _, entries, data_start = read_index(archive)
        count = 0
        for name, offset, size in entries:
            if needle not in name:
                continue
            target = out / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data[data_start + offset : data_start + offset + size])
            count += 1
        print(f"{count} files -> {out}")
        return 0

    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
