"""Rebuild every building asset + the shared material library (run INSIDE Blender, e.g. via MCP):

    import runpy; runpy.run_path("/abs/path/art_source/blender/build_all.py")

Each building module in buildings/ exposes build()/run(). This script:
  1. bakes the material library into sample_project/assets/3d/materials (+ pinned .import files)
  2. builds, saves .blend, exports .glb, writes .meta.json for every building
  3. renders an RTS-angle preview per building to docs/art/previews/<civ>_<asset>.png
Afterwards run `python3 art_source/blender/update_manifest.py` (outside Blender).
"""
import sys, os, importlib, glob
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (HERE, os.path.join(HERE, "buildings")):
    if p not in sys.path:
        sys.path.insert(0, p)
import pe_kit, parts, civstyle, castles, bldtypes
for _m in (pe_kit, parts, civstyle, castles, bldtypes):
    importlib.reload(_m)

ONLY = globals().get("ONLY")  # optional list of module names to restrict the build
pe_kit.export_material_library()
results = []
for path in sorted(glob.glob(os.path.join(HERE, "buildings", "*.py"))):
    name = os.path.splitext(os.path.basename(path))[0]
    if ONLY and name not in ONLY:
        continue
    mod = importlib.import_module(name)
    importlib.reload(mod)
    ob, meta = mod.run(export=True)
    prev = os.path.join(pe_kit.REPO_ROOT, "docs", "art", "previews", "%s_%s.png" % (meta["civ"], meta["asset_id"]))
    pe_kit.render_preview(ob, prev)
    results.append((name, meta["tris"], len(meta["materials"]), meta["glb_bytes"]))
for r in results:
    print("%-28s tris=%-5d mats=%-3d glb=%d B" % r)
