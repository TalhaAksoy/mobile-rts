"""Byzantines Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/byzantines/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: Brick-banded stone tower with a terracotta cone; domed granary (terracotta dome) and an amphora stack.
Sails are a separate object "Sails" so Godot can turn them (Building3D)."""
import pe_kit, parts

CIV = "byzantines"
ASSET = "mill"


def extras(b, z0):
    for (x, y) in ((1.35, 0.45), (1.5, 0.7), (1.25, 0.75)):
        b.cylinder((x, y, z0), 0.1, 0.3, "PE_RoofRed", segs=7, r_top=0.05)   # amphorae


def build():
    return parts.build_mill("byzantines_mill", CIV, {"tower_mat": "PE_StoneBrick", "base_mat": "PE_StoneWarm", "cap": "cone", "cap_mat": "PE_RoofRed",
            "annex": "dome", "annex_wall": "PE_StoneBrick", "annex_roof": "PE_RoofRed", "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/byzantines/mill.png"})
    return main, pe_kit.mesh_stats(main)
