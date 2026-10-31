"""Ottomans Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/ottomans/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: Stone tower with whitewashed upper drum and red barrel-tile cone, plaster granary with red tiles; copper pot + cypress.
Sails are a separate object "Sails" so Godot can turn them (Building3D)."""
import pe_kit, parts

CIV = "ottomans"
ASSET = "mill"


def extras(b, z0):
    parts.cypress(b, (1.45, 1.35, z0), height=1.5, r=0.26)
    b.cylinder((1.1, 0.55, z0), 0.16, 0.2, "PE_Gold", segs=8, r_top=0.12)   # copper/brass grain measure


def build():
    return parts.build_mill("ottomans_mill", CIV, {"tower_mat": "PE_PlasterCream", "base_mat": "PE_StoneWarm", "cap": "cone", "cap_mat": "PE_RoofRed", "gold_finial": True,
            "annex": "gable", "annex_wall": "PE_PlasterCream", "annex_roof": "PE_RoofRed", "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/ottomans/mill.png"})
    return main, pe_kit.mesh_stats(main)
