#!/usr/bin/env python3
"""Points the game's 2D-sprite manifests at the Aseprite pixel-art set.

Reads build/px_meta/{units,buildings}/<civ>/<id>.json (written by run.lua) and replaces the matching entries in
sample_project/data/art/unit_sprite_manifest.json and sprite_manifest.json. Entries without new meta keep the
Blender-rendered sprites, so a partial run (one civ, one unit) is safe. The previous manifests stay in git.

    python3 art_source/aseprite/update_manifest.py [--civ franks] [--dry-run]
"""
import argparse
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
META = os.path.join(ROOT, "build", "px_meta")
DATA = os.path.join(ROOT, "sample_project", "data", "art")


def load(p):
    with open(p) as f:
        return json.load(f)


def save(p, d):
    with open(p, "w") as f:
        json.dump(d, f, indent=1, sort_keys=True)
        f.write("\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--civ", action="append", help="only these civs (repeatable)")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    changed = []
    units_path = os.path.join(DATA, "unit_sprite_manifest.json")
    bld_path = os.path.join(DATA, "sprite_manifest.json")
    units, blds = load(units_path), load(bld_path)

    for kind, manifest in (("units", units["units"]), ("buildings", blds["buildings"])):
        base = os.path.join(META, kind)
        if not os.path.isdir(base):
            continue
        for civ in sorted(os.listdir(base)):
            if a.civ and civ not in a.civ:
                continue
            # "<id>.json" = the base (Age II) look; "<id>@a<N>.json" = another age, stored under entry["ages"]["N"].
            # sorted(): "x.json" < "x@a1.json", so the base entry is written before its ages are attached.
            for fn in sorted(os.listdir(os.path.join(base, civ))):
                key = fn[:-5]
                meta = load(os.path.join(base, civ, fn))
                meta.pop("source", None)
                if "@a" in key:
                    key, age = key.split("@a")
                    entry = manifest.setdefault(civ, {}).get(key)
                    if entry is None:
                        continue
                    entry.setdefault("ages", {})[age] = meta
                    changed.append("%s/%s/%s@a%s" % (kind, civ, key, age))
                    continue
                manifest.setdefault(civ, {})[key] = meta
                changed.append("%s/%s/%s" % (kind, civ, key))

    # environment props, fields and upgrade kits: build/px_meta/<section>/<key with / as __>.json
    for section in ("environment", "fields", "upgrade_kits"):
        base = os.path.join(META, section)
        if not os.path.isdir(base) or a.civ:
            continue
        sec = blds.setdefault(section, {})
        for fn in sorted(os.listdir(base)):
            key = fn[:-5].replace("__", "/")
            meta = load(os.path.join(base, fn))
            meta.pop("source", None)
            if section == "upgrade_kits":
                civ, half = key.split("/")
                sec.setdefault(civ, {})[half] = meta
            else:
                sec[key] = meta
            changed.append("%s/%s" % (section, key))

    if not a.dry_run:
        save(units_path, units)
        save(bld_path, blds)
    print("%d entries %s" % (len(changed), "would change" if a.dry_run else "updated"))
    for c in changed:
        print("  " + c)


if __name__ == "__main__":
    main()
