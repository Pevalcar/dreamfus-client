import json

for fname in ["casas_mundo_3.6.10.10.json", "casas_reales_3.6.10.10.json"]:
    print(f"=== {fname} ===")
    data = json.load(open(rf"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\{fname}", encoding="utf-8"))
    s = json.dumps(data, ensure_ascii=False)
    # Find snippet around 'instancia'
    pos = 0
    while True:
        pos = s.find("instancia", pos)
        if pos == -1:
            break
        print("  snippet:", s[max(0, pos-40):pos+60])
        pos += 9