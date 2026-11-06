"""Byzantines Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/byzantines/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: Byzantine watermill: a banded brick mill house with a red-tile gable on a stream, vertical wooden wheel (docs: Byzantine watermills are well attested; no windmills).
The wheel is a separate object ("Sails" / "WheelH") so Godot can turn it (Building3D).
"""
import pe_kit, parts

CIV = "byzantines"
ASSET = "mill"


def extras(b, z0):
    for (x, y) in ((1.0, -0.95), (1.25, -0.9), (1.5, -1.0)):
        b.cylinder((x, y, z0), 0.1, 0.3, "PE_RoofRed", segs=7, r_top=0.05)   # amphorae


def build():
    return parts.build_watermill("byzantines_mill", CIV, {"wall": "PE_StoneBrick", "base": "PE_StoneWarm", "roof": "gable", "roof_mat": "PE_RoofRed", "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/byzantines/mill.png"})
    return main, pe_kit.mesh_stats(main)
