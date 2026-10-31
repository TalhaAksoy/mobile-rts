"""Vikings Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/vikings/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: Timber-planked tower with a shingle cap; storehouse raised on stone posts (stabbur) with a steep shingle roof; team shield.
Sails are a separate object "Sails" so Godot can turn them (Building3D)."""
import pe_kit, parts

CIV = "vikings"
ASSET = "mill"


def extras(b, z0):
    parts.round_shield(b, (0.85, -0.96, z0 + 0.62), (0, -1, 0), r=0.15)
    parts.log_pile(b, (1.35, 0.8, z0), length=0.7, rows=2, r=0.08, axis="y")


def build():
    return parts.build_mill("vikings_mill", CIV, {"tower_mat": "PE_WoodDark", "base_mat": "PE_StoneGrey", "cap": "cone", "cap_mat": "PE_Shingle",
            "annex": "stabbur", "annex_wall": "PE_WoodLight", "annex_roof": "PE_Shingle", "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/vikings/mill.png"})
    return main, pe_kit.mesh_stats(main)
