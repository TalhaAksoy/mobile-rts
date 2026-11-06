"""Japanese Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/japanese/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: Mizuguruma: a wooden water wheel feeding a white-plastered rice-pounding hut under a dark tile roof (windmills were not used).
The wheel is a separate object ("Sails" / "WheelH") so Godot can turn it (Building3D).
"""
import pe_kit, parts

CIV = "japanese"
ASSET = "mill"


def extras(b, z0):
    for (x, y) in ((1.05, -0.95), (1.4, -1.0)):
        b.cylinder((x, y, z0), 0.17, 0.32, "PE_Thatch", segs=8, smooth=False)     # rice-straw bales
    b.box((1.6, -0.5, z0 + 0.45), (0.06, 0.06, 0.9), "PE_LacquerRed")


def build():
    return parts.build_watermill("japanese_mill", CIV, {"wall": "PE_PlasterWhite", "base": "PE_RoofDark", "roof": "curved", "roof_mat": "PE_RoofDark", "lattice": True, "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/japanese/mill.png"})
    return main, pe_kit.mesh_stats(main)
