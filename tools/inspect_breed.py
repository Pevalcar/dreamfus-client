import json, glob

# Check breeding structure properly
breed = json.load(open(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\breeding_3.6.10.11.json", encoding="utf-8"))
print("breeding type:", type(breed).__name__)
if isinstance(breed, dict):
    for k, v in list(breed.items())[:3]:
        print(f"  key={k} type={type(v).__name__}")
        if isinstance(v, dict):
            print(f"    subkeys: {list(v.keys())[:10]}")
        elif isinstance(v, list) and v:
            print(f"    first: {json.dumps(v[0], ensure_ascii=False)[:200]}")

# quests
quests = json.load(open(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\quests_3.6.10.10.json", encoding="utf-8"))
print("\nquests type:", type(quests).__name__)
if isinstance(quests, dict):
    for k, v in list(quests.items())[:3]:
        print(f"  key={k} type={type(v).__name__}")
        if isinstance(v, dict):
            print(f"    subkeys: {list(v.keys())[:10]}")
        elif isinstance(v, list) and v:
            print(f"    first: {json.dumps(v[0], ensure_ascii=False)[:200]}")