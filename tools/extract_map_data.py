"""Extract cell data for one map into a small JSON for the Godot client.

Reads the two server-side datos JSON files and writes a compact per-map
file with walkable / fight / blocked cell ids. Keeps the Godot project
self-contained (no absolute paths to another repo at runtime).
"""
import json
import sys
from pathlib import Path

MAP_ID = 88212759
DATOS = Path(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos")
OUT = Path(r"C:\Users\pevalcar\Proyectos\DofusClient\godot-client\assets\maps")

WALKABLE = "map_walkable_cells.json"
FIGHT = "map_fight_cells.json"


def main(map_id: int = MAP_ID):
    key = str(map_id)
    walk = json.load(open(DATOS / WALKABLE, encoding="utf-8"))
    fight = json.load(open(DATOS / FIGHT, encoding="utf-8"))

    if key not in walk or key not in fight:
        sys.exit(f"map {key} not found in datos JSON")

    walkable = walk[key]
    fight_ids = fight[key]["f"]
    blocked = fight[key]["b"]

    data = {
        "mapId": map_id,
        "cols": 14,
        "rows": 40,
        "walkable": sorted(walkable),
        "fight": sorted(fight_ids),
        "blocked": sorted(blocked),
    }
    OUT.mkdir(parents=True, exist_ok=True)
    target = OUT / f"map_{map_id}.json"
    target.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"{target} ({target.stat().st_size} bytes)")
    print(
        f"  walkable={len(walkable)} fight={len(fight_ids)} blocked={len(blocked)}"
    )


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else MAP_ID)
