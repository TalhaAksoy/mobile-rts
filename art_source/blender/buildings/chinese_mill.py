"""Chinese Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/chinese/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: Song watermill: a vertical wooden wheel on a tile-roofed mill house over a stream (water-powered mills are well documented; windmills were rare and late).
The wheel is a separate object ("Sails" / "WheelH") so Godot can turn it (Building3D).
"""
import pe_kit, parts

CIV = "chinese"
ASSET = "mill"


def extras(b, z0):
    for (x, y) in ((1.05, -0.95), (1.4, -0.95)):
        b.cylinder((x, y, z0), 0.15, 0.3, "PE_WoodLight", segs=8, r_top=0.17)   # grain baskets
    b.box((1.55, -0.5, z0 + 0.4), (0.3, 0.05, 0.5), "PE_LacquerRed")             # red signboard


def build():
    return parts.build_watermill("chinese_mill", CIV, {"wall": "PE_PlasterCream", "base": "PE_StoneGrey", "roof": "curved", "roof_mat": "PE_RoofTeal", "posts": "PE_LacquerRed", "under": "PE_LacquerRed", "platform": True, "lattice": True, "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/chinese/mill.png"})
    return main, pe_kit.mesh_stats(main)
