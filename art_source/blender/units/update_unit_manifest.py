"""Collects art_source/blender/units/meta/*.json into sample_project/data/art/unit_model_manifest.json
(run with system python after build_units.py):  python3 art_source/blender/units/update_unit_manifest.py"""
import json, os, glob

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(REPO, "sample_project", "data", "art", "unit_model_manifest.json")

units = {}
# "<civ>_<role>.json" = Age II (base); "<civ>_<role>@a<N>.json" = another age look -> entry["ages"]["N"]
metas = [json.load(open(p)) for p in sorted(glob.glob(os.path.join(HERE, "meta", "*.json")))]
for m in sorted(metas, key=lambda m: m.get("age", 2) != 2):
    e = {"model": m["model"], "enabled": True, "tris": m["tris"], "height": m["height"],
         "attack": m["attack"], "props": m.get("props", []), "actions": m["actions"], "mount": m.get("mount", "")}
    if m.get("age", 2) != 2:
        base = units.get(m["civ"], {}).get(m["role"])
        if base is not None:
            base.setdefault("ages", {})[str(m["age"])] = {"model": e["model"], "tris": e["tris"], "height": e["height"]}
        continue
    units.setdefault(m["civ"], {})[m["role"]] = e
os.makedirs(os.path.dirname(OUT), exist_ok=True)
json.dump({"version": 1, "units": units}, open(OUT, "w"), indent=1, sort_keys=True)
print("wrote", OUT, sum(len(v) for v in units.values()), "units")
