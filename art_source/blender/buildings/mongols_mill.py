"""Mongols Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/mongols/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: Felt-wrapped tower with a felt tent cap, a ger storehouse and a two-wheeled cart: nomadic, no stone or tile.
Sails are a separate object "Sails" so Godot can turn them (Building3D)."""
import pe_kit, parts

CIV = "mongols"
ASSET = "mill"


def extras(b, z0):
    # two-wheeled cart
    b.box((1.25, 0.6, z0 + 0.35), (0.7, 0.45, 0.12), "PE_WoodLight")
    for y in (0.35, 0.85):
        b.cylinder_between((1.25, y, z0 + 0.25), (1.25, y + (0.04 if y > 0.5 else -0.04), z0 + 0.25), 0.25, "PE_WoodDark", segs=8, smooth=False)
    b.cylinder_between((0.9, 0.6, z0 + 0.35), (0.45, 0.6, z0 + 0.2), 0.025, "PE_WoodDark", segs=4)


def build():
    return parts.build_mill("mongols_mill", CIV, {"tower_mat": "PE_Felt", "base_mat": "PE_WoodDark", "cap": "tent", "cap_mat": "PE_FeltBlue", "rim_mat": "PE_FeltBlue",
            "annex": "ger", "annex_wall": "PE_Felt", "annex_roof": "PE_Felt", "sails": "lattice", "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/mongols/mill.png"})
    return main, pe_kit.mesh_stats(main)
