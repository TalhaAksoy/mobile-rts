"""Saracens Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/saracens/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: Sandstone tower with a teal-tiled dome cap and gold finial; domed sandstone granary; date palm.
Sails are a separate object "Sails" so Godot can turn them (Building3D)."""
import pe_kit, parts

CIV = "saracens"
ASSET = "mill"


def extras(b, z0):
    b.cylinder_between((1.45, 1.25, z0), (1.5, 1.2, z0 + 1.4), 0.07, "PE_WoodLight", segs=6, smooth=False)
    import math
    for k in range(6):                       # palm crown: six drooping fronds as flat cones
        a = k * math.pi / 3
        b.cylinder_between((1.5, 1.2, z0 + 1.4), (1.5 + 0.5 * math.cos(a), 1.2 + 0.5 * math.sin(a), z0 + 1.2), 0.06, "PE_Foliage", segs=4, smooth=False)


def build():
    return parts.build_mill("saracens_mill", CIV, {"tower_mat": "PE_Sandstone", "cap": "dome", "cap_mat": "PE_TileTeal", "rim_mat": "PE_TileTeal",
            "annex": "dome", "annex_wall": "PE_Sandstone", "annex_roof": "PE_TileTeal", "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/saracens/mill.png"})
    return main, pe_kit.mesh_stats(main)
