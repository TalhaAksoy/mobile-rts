"""Byzantines Castle (4x4 grid -> 7.2 m footprint).

Layout: bldtypes.build_castle() (shared by every civ so the type reads the same at a glance).
Civ vocabulary: civstyle.STYLES["byzantines"] (ART_DIRECTION_BIBLE section 6).
"""
import pe_kit, bldtypes

CIV = "byzantines"
ASSET = "castle"


def build():
    return bldtypes.build_castle(CIV)


def run(export=True):
    if export:
        return bldtypes.run_type(CIV, ASSET, bldtypes.build_castle, 4)
    ob = build()
    return ob, pe_kit.mesh_stats(ob)
