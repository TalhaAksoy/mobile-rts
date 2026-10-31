"""Saracens Archery Range (3x3 grid -> 5.4 m footprint).

Layout: bldtypes.build_archery_range() (shared by every civ so the type reads the same at a glance).
Civ vocabulary: civstyle.STYLES["saracens"] (ART_DIRECTION_BIBLE section 6).
"""
import pe_kit, bldtypes

CIV = "saracens"
ASSET = "archery_range"


def build():
    return bldtypes.build_archery_range(CIV)


def run(export=True):
    if export:
        return bldtypes.run_type(CIV, ASSET, bldtypes.build_archery_range, 3)
    ob = build()
    return ob, pe_kit.mesh_stats(ob)
