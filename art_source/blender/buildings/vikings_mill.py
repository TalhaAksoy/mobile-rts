"""Vikings Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/vikings/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: Norse horizontal watermill: a tiny turf-roofed plank hut on posts over a stream, the paddle wheel turning under its floor (no windmills).
The wheel is a separate object ("Sails" / "WheelH") so Godot can turn it (Building3D).
"""
import pe_kit, parts

CIV = "vikings"
ASSET = "mill"


def extras(b, z0):
    parts.log_pile(b, (1.2, -0.95, z0), length=0.7, rows=2, r=0.08, axis="y")


def build():
    return parts.build_norse_mill("vikings_mill", CIV, {"roof_mat": "PE_Grass", "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/vikings/mill.png"})
    return main, pe_kit.mesh_stats(main)
