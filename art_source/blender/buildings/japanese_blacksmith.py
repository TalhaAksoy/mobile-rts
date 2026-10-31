"""Japanese Blacksmith (2x2 grid -> 3.6 m footprint).

Layout: bldtypes.build_blacksmith() (shared by every civ so the type reads the same at a glance).
Civ vocabulary: civstyle.STYLES["japanese"] (ART_DIRECTION_BIBLE section 6).
"""
import pe_kit, bldtypes

CIV = "japanese"
ASSET = "blacksmith"


def build():
    return bldtypes.build_blacksmith(CIV)


def run(export=True):
    if export:
        return bldtypes.run_type(CIV, ASSET, bldtypes.build_blacksmith, 2)
    ob = build()
    return ob, pe_kit.mesh_stats(ob)
