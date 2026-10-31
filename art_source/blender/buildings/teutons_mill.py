"""Teutons Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/teutons/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: Dark grey stone tower, near-black slate cone, dark half-timbered granary on a stone plinth.
Sails are a separate object "Sails" so Godot can turn them (Building3D)."""
import pe_kit, parts

CIV = "teutons"
ASSET = "mill"


def extras(b, z0):
    parts.log_pile(b, (1.3, 0.75, z0), length=0.7, rows=2, r=0.08, axis="y")


def build():
    return parts.build_mill("teutons_mill", CIV, {"tower_mat": "PE_StoneGrey", "cap": "cone", "cap_mat": "PE_SlateDark",
            "annex": "timber", "annex_wall": "PE_PlasterWhite", "annex_roof": "PE_SlateDark", "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/teutons/mill.png"})
    return main, pe_kit.mesh_stats(main)
