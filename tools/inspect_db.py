import sqlite3, json, glob

# 1. Check world.db for coords -> mapId mapping
try:
    db = sqlite3.connect(r"C:\Users\pevalcar\Proyectos\jondo-servidor\world.db")
    tables = db.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
    print("world.db tables:", [t[0] for t in tables])
    for t in tables:
        name = t[0]
        cols = db.execute(f"PRAGMA table_info({name})").fetchall()
        print(f"  {name}: {[c[1] for c in cols]}")
    db.close()
except Exception as e:
    print("world.db error:", e)

# 2. Search datos JSONs for coord->mapId patterns
print("\n--- datos files ---")
for f in sorted(glob.glob(r"C:\Users\pevalcar\Proyectos\jondo-servidor\datos\*.json")):
    data = json.load(open(f, encoding="utf-8"))
    s = json.dumps(data)
    if "-1" in s and ("mapId" in s or "posX" in s):
        print(f.split("\\")[-1], "has coords+mapId")