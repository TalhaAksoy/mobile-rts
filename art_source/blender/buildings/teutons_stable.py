"""Teutons Stable (3x3 grid -> 5.4 m footprint).

Layout: bldtypes.build_stable() (shared by every civ so the type reads the same at a glance).
Civ vocabulary: civstyle.STYLES["teutons"] (ART_DIRECTION_BIBLE section 6).
"""
import pe_kit, bldtypes

CIV = "teutons"
ASSET = "stable"


def build():
    return bldtypes.build_stable(CIV)


def run(export=True):
    if export:
        return bldtypes.run_type(CIV, ASSET, bldtypes.build_stable, 3)
    ob = build()
    return ob, pe_kit.mesh_stats(ob)
