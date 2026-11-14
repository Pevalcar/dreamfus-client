"""Export a map's cell data as a Godot .tres Resource file.

Reads cell data from server-side datos JSON and metadata from world.db,
then writes a complete MapData .tres under assets/maps/<bucket>/<id>.tres
plus a global _index.json mapping (PosX,PosY) -> list of variant mapIds.

Usage:
    python alea_to_godot.py <map_id>           # single map by ID (legacy)
    python alea_to_godot.py <posx> <posy>      # export ALL variants at coords
"""
import json
import sqlite3
import sys
from pathlib import Path

DEFAULT_MAP_ID = 88212759
DATOS = Path(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos")
WORLD_DB = Path(r"C:\Users\pevalcar\Proyectos\jondo-servidor\bases\world.db")
GODOT_MAPS = Path(r"C:\Users\pevalcar\Proyectos\DofusClient\godot-client\assets\maps")


def _load_db():
    return sqlite3.connect(str(WORLD_DB))


def _read_json(path):
    return json.load(open(path, encoding="utf-8"))


def _get_position(cur, map_id):
    cur.execute("SELECT PosX, PosY, SubAreaId, Outdoor, Name FROM MapPositions WHERE MapId=?", (map_id,))
    row = cur.fetchone()
    if not row:
        return None
    return {"pos_x": row[0], "pos_y": row[1], "sub_area_id": row[2], "outdoor": bool(row[3]), "name": (row[4] or "")}


def _get_template_data(cur, map_id):
    """Parse MapTemplates.Data JSON for flags, nameId, tacticalMode, worldMap."""
    cur.execute("SELECT Data FROM MapTemplates WHERE Id=?", (map_id,))
    row = cur.fetchone()
    if not row or not row[0]:
        return {}
    try:
        return json.loads(row[0]) if isinstance(row[0], str) else {}
    except Exception:
        return {}


def _get_scroll(cur, map_id):
    cur.execute("SELECT RightMapId, BottomMapId, LeftMapId, TopMapId FROM MapScrolls WHERE MapId=?", (map_id,))
    row = cur.fetchone()
    if not row:
        return {}
    return {"right": row[0], "bottom": row[1], "left": row[2], "top": row[3]}


def _get_npcs(cur, map_id):
    cur.execute("SELECT NpcId, CellId, Orientation, Look FROM NpcSpawns WHERE MapId=?", (map_id,))
    return [{"npc_id": r[0], "cell": r[1], "orientation": r[2], "look": (r[3] or "")} for r in cur.fetchall()]


def _get_mobs(cur, map_id):
    cur.execute("SELECT CellId, MembersJson FROM MapMobs WHERE MapId=?", (map_id,))
    return [{"cell": r[0], "members_json": (r[1] or "[]")} for r in cur.fetchall()]


def _pack_ints(arr):
    return ", ".join(str(c) for c in arr)


def _build_tres(map_id, pos, tpl, scroll, npcs, mobs, walkable, fight_ids, blocked):
    """Build the full .tres text for one map variant."""
    sub_area = pos["sub_area_id"]
    outdoor = pos["outdoor"]
    name_id = tpl.get("nameId", 0)
    flags = tpl.get("m_flags", 0)
    tactical = tpl.get("tacticalModeTemplateId", 0)
    world_map_val = tpl.get("worldMap", -1)
    # world_map_offset stored as String for GDScript Vector2i literal
    wm_x = world_map_val if world_map_val >= 0 else 0
    wm_y = 0

    npc_cells = [n["cell"] for n in npcs]
    # PackedStringArray requires quoted strings — escape inner quotes.
    mob_strings = ['"%s"' % m["members_json"].replace('"', '\\"') for m in mobs]
    mob_arr = ', '.join(mob_strings)

    lines = [
        '[gd_resource type="Resource" script_class="MapData" load_steps=2 format=3]',
        '',
        '[ext_resource type="Script" path="res://src/Data/MapData.gd" id="1_map_script"]',
        '',
        '[resource]',
        'script = ExtResource("1_map_script")',
        f'map_id = {map_id}',
        f'map_coordinades = Vector2i({pos["pos_x"]}, {pos["pos_y"]})',
        f'sub_area_id = {sub_area}',
        f'is_outdoor = {str(outdoor).lower()}',
        f'name_id = {name_id}',
        f'map_flags = {flags}',
        f'tactical_mode_id = {tactical}',
        f'neighbors = {json.dumps(scroll)}',
        f'walkable_cells = PackedInt32Array({_pack_ints(walkable)})',
        f'fight_cells = PackedInt32Array({_pack_ints(fight_ids)})',
        f'blocked_cells = PackedInt32Array({_pack_ints(blocked)})',
        f'npc_ids = PackedInt32Array({_pack_ints(npc_cells)})',
        f'mob_groups_json = PackedStringArray({mob_arr})',
    ]
    return "\n".join(lines) + "\n"


def _export_variant(conn, cur, map_id, pos):
    key = str(map_id)
    walk = _read_json(DATOS / "map_walkable_cells.json")
    fight = _read_json(DATOS / "map_fight_cells.json")
    if key not in walk or key not in fight:
        print(f"  SKIP {map_id}: not in datos JSON")
        return

    tpl = _get_template_data(cur, map_id)
    scroll = _get_scroll(cur, map_id)
    npcs = _get_npcs(cur, map_id)
    mobs = _get_mobs(cur, map_id)

    walkable = walk[key]
    fight_ids = fight[key]["f"]
    blocked = fight[key]["b"]

    bucket = key[:4]
    out_dir = GODOT_MAPS / bucket
    out_dir.mkdir(parents=True, exist_ok=True)

    tres = _build_tres(map_id, pos, tpl, scroll, npcs, mobs, walkable, fight_ids, blocked)
    target = out_dir / f"{map_id}.tres"
    target.write_text(tres, encoding="utf-8")
    tag = "OUT" if pos["outdoor"] else "INT"
    print(f"  {target.name} [{tag}] sub={pos['sub_area_id']} flags={tpl.get('m_flags', 0)}")


def _write_index(conn, cur):
    """Build/rebuild _index.json: {(PosX,PosY): [mapId, ...]}."""
    index_path = GODOT_MAPS / "_index.json"
    cur.execute("SELECT MapId, PosX, PosY FROM MapPositions")
    index = {}
    for mid, px, py in cur.fetchall():
        key = f"{px},{py}"
        index.setdefault(key, []).append(mid)
    index_path.write_text(json.dumps(index, indent=2), encoding="utf-8")
    print(f"  _index.json written ({len(index)} coordinate entries)")


def export_single(map_id):
    conn = _load_db()
    cur = conn.cursor()
    pos = _get_position(cur, map_id)
    if not pos:
        sys.exit(f"map {map_id} not found in MapPositions")
    _export_variant(conn, cur, map_id, pos)
    _write_index(conn, cur)
    conn.close()


def export_coords(pos_x, pos_y):
    conn = _load_db()
    cur = conn.cursor()
    cur.execute(
        "SELECT MapId, SubAreaId, Outdoor FROM MapPositions WHERE PosX=? AND PosY=?",
        (pos_x, pos_y),
    )
    rows = cur.fetchall()
    if not rows:
        print(f"[alea_to_godot] No maps found at ({pos_x}, {pos_y})")
        conn.close()
        return

    print(f"[alea_to_godot] Found {len(rows)} variant(s) at ({pos_x}, {pos_y}):")
    for (mid, _, _) in rows:
        pos = _get_position(cur, mid)
        if pos:
            _export_variant(conn, cur, mid, pos)
    _write_index(conn, cur)
    conn.close()


if __name__ == "__main__":
    if len(sys.argv) >= 3:
        export_coords(int(sys.argv[1]), int(sys.argv[2]))
    else:
        map_id = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_MAP_ID
        export_single(map_id)
