import json

# Check breeding structure (dict keyed by mapId?)
breed = json.load(open(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\breeding_3.6.10.11.json", encoding="utf-8"))
print("breeding type:", type(breed).__name__)
if isinstance(breed, dict):
    k = list(breed.keys())[0]
    print("first key:", k)
    print("first value:", json.dumps(breed[k], ensure_ascii=False)[:400])

# quests
quests = json.load(open(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\quests_3.6.10.10.json", encoding="utf-8"))
print("\nquests type:", type(quests).__name__)
if isinstance(quests, dict):
    k = list(quests.keys())[0]
    print("first key:", k)
    print("first value:", json.dumps(quests[k], ensure_ascii=False)[:400])
else:
    print("first entry:", json.dumps(quests[0], ensure_ascii=False)[:400])

# Search for any file with "subMap" or instance concept
import glob
print("\n--- searching for subMap/instance in datos ---")
for f in sorted(glob.glob(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\*.json")):
    data = json.load(open(f, encoding="utf-8"))
    s = json.dumps(data)
    if "subMap" in s or "submap" in s or "instance" in s.lower():
        print(f.split("\\")[-1], "contains subMap/instance")