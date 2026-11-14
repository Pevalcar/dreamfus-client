import json

# Check what fields the walkable/fight JSONs actually contain
walk = json.load(open(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\map_walkable_cells.json", encoding="utf-8"))
fight = json.load(open(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\map_fight_cells.json", encoding="utf-8"))

# Inspect one entry
k = list(walk.keys())[0]
print("walkable entry:", k, type(walk[k]))
print("  ->", walk[k] if not isinstance(walk[k], list) else f"list of {len(walk[k])} ints")

k2 = list(fight.keys())[0]
print("fight entry:", k2, type(fight[k2]))
print("  ->", fight[k2])

# Check for subMap / coords fields in breeding (has mapId + coords)
breed = json.load(open(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\breeding_3.6.10.11.json", encoding="utf-8"))
print("\nfirst breeding entry keys:", list(breed[0].keys()) if isinstance(breed, list) else "not a list")
print("first entry:", json.dumps(breed[0], ensure_ascii=False)[:300])

# quests
quests = json.load(open(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\quests_3.6.10.10.json", encoding="utf-8"))
print("\nquests type:", type(quests).__name__)
if isinstance(quests, list):
    print("first entry keys:", list(quests[0].keys()))
    print("first entry:", json.dumps(quests[0], ensure_ascii=False)[:300])
elif isinstance(quests, dict):
    k = list(quests.keys())[0]
    print("first key:", k)
    print("first value:", json.dumps(quests[k], ensure_ascii=False)[:300])