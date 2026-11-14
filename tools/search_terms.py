import json, glob

for f in sorted(glob.glob(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\*.json")):
    try:
        data = json.load(open(f, encoding="utf-8"))
        s = json.dumps(data)
        for term in ["subArea", "subarea", "worldMap", "worldmap", "worldId", "world_id", "mapWorld", "subMap", "sub_map", "variant", "instancia"]:
            if term in s:
                print(f"{f.split('\\')[-1]} contains '{term}'")
    except Exception as e:
        print(f"error reading {f}: {e}")