"""Collects art_source/blender/units/meta/*.json into sample_project/data/art/unit_model_manifest.json
(run with system python after build_units.py):  python3 art_source/blender/units/update_unit_manifest.py"""
import json, os, glob

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(REPO, "sample_project", "data", "art", "unit_model_manifest.json")

units = {}
for p in sorted(glob.glob(os.path.join(HERE, "meta", "*.json"))):
    m = json.load(open(p))
    units.setdefault(m["civ"], {})[m["role"]] = {
        "model": m["model"], "enabled": True, "tris": m["tris"], "height": m["height"],
        "attack": m["attack"], "props": m.get("props", []), "actions": m["actions"],
        "mount": m.get("mount", "")}
os.makedirs(os.path.dirname(OUT), exist_ok=True)
json.dump({"version": 1, "units": units}, open(OUT, "w"), indent=1, sort_keys=True)
print("wrote", OUT, sum(len(v) for v in units.values()), "units")
