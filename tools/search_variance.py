import json, glob

found_variance = {}
for f in sorted(glob.glob(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\*.json")):
    try:
        data = json.load(open(f, encoding="utf-8"))
        s = json.dumps(data, ensure_ascii=False)
        if "variance" in s or "variant" in s:
            fname = f.split("\\")[-1]
            found_variance[fname] = True
    except Exception as e:
        pass

print("files with variance/variant:")
for f in found_variance:
    print(f"  - {f}")

# Sample deletion_events (near battlegrounds, may have variance/subMap)
try:
    del_events = json.load(open(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\deletion_events_3.6.10.10.json", encoding="utf-8"))
    s = json.dumps(del_events, ensure_ascii=False)[:2000]
    for term in ["subarea", "variance", "mapId"]:
        pos = s.find(term)
        if pos != -1:
            print(f"\ndel_ev: {term} at {pos}")
            print("  :", s[max(0, pos-30):pos+30])
except Exception as e:
    print(f"del_events error: {e}")