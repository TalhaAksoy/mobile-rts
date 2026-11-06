"""Teutons Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/teutons/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: Teutonic Order watermill: a Brick Gothic mill house with a stepped gable on a canal, big undershot wheel (the dominant mill of the Order's Prussia).
The wheel is a separate object ("Sails" / "WheelH") so Godot can turn it (Building3D).
"""
import pe_kit, parts

CIV = "teutons"
ASSET = "mill"


def extras(b, z0):
    parts.log_pile(b, (1.25, -0.95, z0), length=0.7, rows=2, r=0.08, axis="x")


def build():
    return parts.build_watermill("teutons_mill", CIV, {"wall": "PE_BrickRed", "base": "PE_StoneGrey", "roof": "gable", "roof_mat": "PE_RoofRed", "stepped": True, "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/teutons/mill.png"})
    return main, pe_kit.mesh_stats(main)
