"""Byzantines Watch Tower (2x2 grid -> 3.6 m footprint).

Layout: bldtypes.build_watch_tower() (shared by every civ so the type reads the same at a glance).
Civ vocabulary: civstyle.STYLES["byzantines"] (ART_DIRECTION_BIBLE section 6).
"""
import pe_kit, bldtypes

CIV = "byzantines"
ASSET = "watch_tower"


def build():
    return bldtypes.build_watch_tower(CIV)


def run(export=True):
    if export:
        return bldtypes.run_type(CIV, ASSET, bldtypes.build_watch_tower, 2)
    ob = build()
    return ob, pe_kit.mesh_stats(ob)
