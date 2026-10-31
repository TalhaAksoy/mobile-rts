"""Rebuild every environment prop (trees, mines, food) for every map biome. Run INSIDE Blender:

    import runpy; runpy.run_path("/abs/path/art_source/blender/build_environment.py")

Each module in environment/ (except helpers) exposes VARIANTS = [(output_folder, biome), ...] and
run(export, civ, biome). Writes .blend/.glb/.meta.json per variant, the shared material library
(including one nature atlas per biome) and an RTS-angle preview per variant to
docs/art/previews/env_<folder>_<asset>.png. Afterwards (outside Blender):
    python3 art_source/blender/update_manifest.py
Optional global ONLY = ["desert_date_palm", ...] restricts the modules built.
"""
import sys, os, importlib, glob
HERE = os.path.dirname(os.path.abspath(__file__))
ENV = os.path.join(HERE, "environment")
for p in (HERE, ENV):
    if p not in sys.path:
        sys.path.insert(0, p)
import pe_kit
importlib.reload(pe_kit)
import env_parts
importlib.reload(env_parts)

ONLY = globals().get("ONLY")
pe_kit.export_material_library()
pe_kit.bake_scatter_atlas()
results = []
for path in sorted(glob.glob(os.path.join(ENV, "*.py"))):
    name = os.path.splitext(os.path.basename(path))[0]
    if name == "env_parts" or (ONLY and name not in ONLY):
        continue
    mod = importlib.import_module(name)
    importlib.reload(mod)
    for civ, biome in mod.VARIANTS:
        ob, meta = mod.run(export=True, civ=civ, biome=biome)
        prev = os.path.join(pe_kit.REPO_ROOT, "docs", "art", "previews", "env_%s_%s.png" % (civ, meta["asset_id"]))
        pe_kit.render_preview(ob, prev, size=256)
        results.append(("%s/%s" % (civ, meta["asset_id"]), meta["tris"], len(meta["materials"]), meta["glb_bytes"]))
for r in results:
    print("%-28s tris=%-5d mats=%-3d glb=%d B" % r)
