"""Britons Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/britons/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: Whitewashed tower with a thatched cap; half-timbered granary under thatch; hay bale + fence.
Sails are a separate object "Sails" so Godot can turn them (Building3D)."""
import pe_kit, parts

CIV = "britons"
ASSET = "mill"


def extras(b, z0):
    b.cylinder_between((1.0, 0.75, z0 + 0.22), (1.5, 0.75, z0 + 0.22), 0.22, "PE_Thatch", segs=8, smooth=False)   # hay bale
    for x in (0.95, 1.25, 1.55):
        parts.timber_post(b, (x, 1.3, z0), 0.4, s=0.06)
    b.box((1.25, 1.3, z0 + 0.32), (0.66, 0.04, 0.05), "PE_WoodLight")


def build():
    return parts.build_mill("britons_mill", CIV, {"tower_mat": "PE_PlasterWhite", "base_mat": "PE_StoneGrey", "cap": "thatch", "cap_mat": "PE_Thatch",
            "annex": "timber", "annex_wall": "PE_PlasterCream", "annex_roof": "PE_Thatch", "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/britons/mill.png"})
    return main, pe_kit.mesh_stats(main)
