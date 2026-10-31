#!/usr/bin/env python3
"""Regenerate sample_project/data/art/building_model_manifest.json from the per-asset
art_source/blender/<civ>/<asset>.meta.json files written by pe_kit.export_asset().

Keeps manually curated fields (enabled, status, notes) of existing entries.
Usage: python3 art_source/blender/update_manifest.py
"""
import json, os, glob

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
MANIFEST = os.path.join(REPO, "sample_project", "data", "art", "building_model_manifest.json")

with open(MANIFEST) as fh:
    manifest = json.load(fh)
blds = manifest.setdefault("buildings", {})

env = manifest.setdefault("environment", {})
kits = manifest.setdefault("upgrade_kits", {})
for meta_path in sorted(glob.glob(os.path.join(HERE, "*", "*.meta.json"))):
    meta = json.load(open(meta_path))
    if meta.get("kind") == "upgrade_kits":
        old = kits.get(meta["civ"], {})
        kits[meta["civ"]] = {"model": meta["glb"], "source": meta["blend"], "build_script": meta.get("build_script", ""),
                             "tris": meta["tris"], "materials": len(meta["materials"]),
                             "enabled": old.get("enabled", True), "status": old.get("status", "IMPORTED")}
        continue
    if meta.get("kind") == "environment":
        # temperate props keep their historical bare ids; biome variants are "<biome>/<asset>"
        key = meta["asset_id"] if meta["civ"] == "common" else "%s/%s" % (meta["civ"], meta["asset_id"])
        old = env.get(key, {})
        env[key] = {
            "model": meta["glb"], "source": meta["blend"],
            "build_script": meta.get("build_script", "art_source/blender/environment/common_%s.py" % meta["asset_id"]),
            "biome": meta.get("biome", "temperate"),
            "resource": meta.get("resource", ""), "tris": meta["tris"], "materials": len(meta["materials"]),
            "bounds_min": meta["bounds_min"], "bounds_max": meta["bounds_max"],
            "enabled": old.get("enabled", True), "status": old.get("status", "IMPORTED")}
        continue
    if meta.get("kind") != "buildings":
        continue
    civ, asset = meta["civ"], meta["asset_id"]
    old = blds.setdefault(civ, {}).get(asset, {})
    entry = {
        "model": meta["glb"],
        "source": meta["blend"],
        "build_script": "art_source/blender/buildings/%s_%s.py" % (civ, asset),
        "reference": meta.get("reference", ""),
        "tris": meta["tris"],
        "materials": len(meta["materials"]),
        "bounds_min": meta["bounds_min"],
        "bounds_max": meta["bounds_max"],
        "enabled": old.get("enabled", True),
        "status": old.get("status", "IMPORTED"),
    }
    if "notes" in old:
        entry["notes"] = old["notes"]
    blds[civ][asset] = entry

with open(MANIFEST, "w") as fh:
    json.dump(manifest, fh, indent=2)
    fh.write("\n")
print("manifest:", sum(len(v) for v in blds.values()), "building entries,", len(env), "environment entries,", len(kits), "upgrade kits")
for a, e in env.items():
    print("  %-10s %-24s %-9s tris=%-5s mats=%s" % ("env", a, e["status"], e["tris"], e["materials"]))
for civ, d in blds.items():
    for a, e in d.items():
        print("  %-10s %-14s %-9s tris=%-5s mats=%s" % (civ, a, e["status"], e["tris"], e["materials"]))
