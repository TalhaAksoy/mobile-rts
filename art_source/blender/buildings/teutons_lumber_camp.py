"""Teutons Lumber Camp (2x2 grid -> 3.6 m footprint).

Layout: bldtypes.build_lumber_camp() (shared by every civ so the type reads the same at a glance).
Civ vocabulary: civstyle.STYLES["teutons"] (ART_DIRECTION_BIBLE section 6).
"""
import pe_kit, bldtypes

CIV = "teutons"
ASSET = "lumber_camp"


def build():
    return bldtypes.build_lumber_camp(CIV)


def run(export=True):
    if export:
        return bldtypes.run_type(CIV, ASSET, bldtypes.build_lumber_camp, 2)
    ob = build()
    return ob, pe_kit.mesh_stats(ob)
