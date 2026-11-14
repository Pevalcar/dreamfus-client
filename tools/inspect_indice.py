import json

idx = json.load(open(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\indice_3.6.10.10.json", encoding="utf-8"))
print("type:", type(idx).__name__)
if isinstance(idx, dict):
    k = list(idx.keys())[0]
    print("first key:", k)
    print("first value:", json.dumps(idx[k], ensure_ascii=False)[:500])
    print("\n--- search for map 88212759 ---")
    if "88212759" in idx:
        print(json.dumps(idx["88212759"], ensure_ascii=False)[:500])
    # search all keys for 88212759
    for kk, vv in idx.items():
        s = json.dumps(vv)
        if "88212759" in s:
            print(f"found in key {kk}:", s[:300])
            break
elif isinstance(idx, list):
    print("first entry:", json.dumps(idx[0], ensure_ascii=False)[:500])
    for e in idx:
        s = json.dumps(e)
        if "88212759" in s:
            print("found:", s[:400])
            break