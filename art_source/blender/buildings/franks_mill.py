"""Franks Mill (2x2 grid -> 3.6 m footprint) = farm centre + food drop-off.

Reference: art/buildings/franks/mill.png (tower windmill, shared by every civ in the gallery).
Civ reading: Tall pale-stone tower with a steep blue-slate cone and gilded finial; stone granary with slate roof.
Sails are a separate object "Sails" so Godot can turn them (Building3D)."""
import pe_kit, parts

CIV = "franks"
ASSET = "mill"


def extras(b, z0):
    parts.barrel(b, (1.35, 0.55, z0)); parts.barrel(b, (1.55, 0.8, z0))   # wine/grain barrels


def build():
    return parts.build_mill("franks_mill", CIV, {"tower_mat": "PE_StoneWarm", "cap": "cone", "cap_mat": "PE_RoofSlate", "gold_finial": True,
            "annex": "gable", "annex_wall": "PE_StoneWarm", "annex_roof": "PE_RoofSlate", "extras": extras})


def run(export=True):
    main, sails = build()
    if export:
        return main, pe_kit.export_asset(main, CIV, ASSET, extra_objects=(sails,),
                                         extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                     "reference": "res://art/buildings/franks/mill.png"})
    return main, pe_kit.mesh_stats(main)
