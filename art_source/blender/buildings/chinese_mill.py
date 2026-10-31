"""Chinese Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/chinese/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: Grey stone tower with a teal double-eave pavilion cap on red posts; red-pillared granary pavilion with teal roof.
Sails are a separate object "Sails" so Godot can turn them (Building3D)."""
import pe_kit, parts

CIV = "chinese"
ASSET = "mill"


def extras(b, z0):
    for (x, y) in ((1.3, 0.6), (1.5, 0.85)):
        b.cylinder((x, y, z0), 0.15, 0.3, "PE_WoodLight", segs=8, r_top=0.17)   # grain baskets
    b.box((1.1, 1.35, z0 + 0.4), (0.3, 0.05, 0.5), "PE_LacquerRed")             # red signboard


def build():
    return parts.build_mill("chinese_mill", CIV, {"tower_mat": "PE_StoneGrey", "cap": "tiered", "cap_mat": "PE_RoofTeal", "cap_wall": "PE_LacquerRed",
            "annex": "pavilion", "annex_wall": "PE_PlasterCream", "annex_roof": "PE_RoofTeal", "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/chinese/mill.png"})
    return main, pe_kit.mesh_stats(main)
