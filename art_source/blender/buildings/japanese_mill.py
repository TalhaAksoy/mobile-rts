"""Japanese Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/japanese/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: White plaster tower on a battered stone base with a double-eave dark kawara cap; kura storehouse; rice-straw bales.
Sails are a separate object "Sails" so Godot can turn them (Building3D)."""
import pe_kit, parts

CIV = "japanese"
ASSET = "mill"


def extras(b, z0):
    for (x, y) in ((1.3, 0.55), (1.5, 0.8)):
        b.cylinder((x, y, z0), 0.17, 0.32, "PE_Thatch", segs=8, smooth=False)     # rice-straw bales
    b.box((1.1, 1.35, z0 + 0.45), (0.06, 0.06, 0.9), "PE_LacquerRed")


def build():
    return parts.build_mill("japanese_mill", CIV, {"tower_mat": "PE_PlasterWhite", "base_mat": "PE_StoneGrey", "cap": "tiered", "cap_mat": "PE_RoofDark", "cap_wall": "PE_PlasterWhite",
            "annex": "kura", "annex_wall": "PE_PlasterWhite", "annex_roof": "PE_RoofDark", "sail_mat": "PE_SailCloth", "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/japanese/mill.png"})
    return main, pe_kit.mesh_stats(main)
