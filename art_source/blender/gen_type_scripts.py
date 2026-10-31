"""Writes the thin per-civ scripts buildings/<civ>_<asset>.py for kit-built building types
(run outside Blender: python3 art_source/blender/gen_type_scripts.py <asset> <grid> [civ ...]).
Existing files are never overwritten."""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = '''"""{title} {name} ({g}x{g} grid -> {fp} m footprint).

Layout: bldtypes.build_{asset}() (shared by every civ so the type reads the same at a glance).
Civ vocabulary: civstyle.STYLES["{civ}"] (ART_DIRECTION_BIBLE section 6).
"""
import pe_kit, bldtypes

CIV = "{civ}"
ASSET = "{asset}"


def build():
    return bldtypes.build_{asset}(CIV)


def run(export=True):
    if export:
        return bldtypes.run_type(CIV, ASSET, bldtypes.build_{asset}, {g})
    ob = build()
    return ob, pe_kit.mesh_stats(ob)
'''
ALL = ["ottomans", "byzantines", "britons", "franks", "mongols", "teutons", "japanese", "saracens", "vikings", "chinese"]
asset, grid = sys.argv[1], int(sys.argv[2])
civs = sys.argv[3:] or ALL
for civ in civs:
    path = os.path.join(HERE, "buildings", "%s_%s.py" % (civ, asset))
    if os.path.exists(path):
        print("keep", path)
        continue
    with open(path, "w") as f:
        f.write(TEMPLATE.format(title=civ.capitalize(), name=asset.replace("_", " ").title(), g=grid,
                                fp=round(grid * 1.8, 1), civ=civ, asset=asset))
    print("wrote", path)
