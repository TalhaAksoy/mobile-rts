"""Byzantines House (2x2 grid -> 3.6 m footprint).

Reference: art/buildings/byzantines/house.png (stone house, terracotta roofs).
Civ reading: L-shaped house in banded stone-and-brick (the Byzantine opus mixtum), low-pitch
terracotta gable roofs, round-arch windows, a small arcaded loggia on white columns, a vine
pergola and amphorae. No minaret, no lead dome (that is Ottoman). Team: loggia awning + pennant.
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "byzantines"
ASSET = "house"


def build():
    pe_kit.reset_scene()
    b = Builder("byzantines_house")
    pe_kit.ground_pad(b, 1.8, 1.8, seed=29)
    z0 = 0.08
    # main block (back), ridge along X, two storeys
    mx, my = 0.0, 0.55
    MW, MD, MH = 2.6, 1.2, 1.75
    b.box((mx, my, z0 + MH / 2), (MW, MD, MH), "PE_StoneWarm")
    for z in (0.45, 0.95, 1.45):                     # brick bands
        b.box((mx, my, z0 + z), (MW + 0.03, MD + 0.03, 0.09), "PE_StoneBrick")
    fy = my - MD / 2
    for x in (-0.85, 0.0, 0.85):
        b.arch_opening((mx + x, fy, z0 + 1.05), (0, -1, 0), 0.26, 0.42, "PE_Window", "PE_StoneBrick", depth=0.03, frame=0.05, segs=4)
    b.gable_roof((mx, my, z0 + MH), MW, MD, 0.5, "PE_RoofRed", overhang=0.16, ridge_axis="x", ridge_mat="PE_RoofRed")
    b.gable_end((mx, my, z0 + MH), MW, MD, 0.5, "PE_StoneWarm", ridge_axis="x")
    # front wing (left), single storey, ridge along Y
    wx, wy = -0.75, -0.4
    WW, WD, WH = 1.1, 1.0, 1.05
    b.box((wx, wy, z0 + WH / 2), (WW, WD, WH), "PE_StoneWarm")
    b.box((wx, wy, z0 + 0.5), (WW + 0.03, WD + 0.03, 0.09), "PE_StoneBrick")
    b.arch_opening((wx, wy - WD / 2, z0), (0, -1, 0), 0.4, 0.75, "PE_WoodDark", "PE_StoneBrick", depth=0.04, frame=0.06, segs=5)
    b.arch_opening((wx - WW / 2, wy, z0 + 0.5), (-1, 0, 0), 0.24, 0.36, "PE_Window", "PE_StoneBrick", depth=0.03, frame=0.05, segs=4)
    b.gable_roof((wx, wy, z0 + WH), WW, WD, 0.42, "PE_RoofRed", overhang=0.14, ridge_axis="y", ridge_mat="PE_RoofRed")
    b.gable_end((wx, wy, z0 + WH), WW, WD, 0.42, "PE_StoneWarm", ridge_axis="y")
    # loggia (front-right): 3 round arches on white columns under a team-coloured awning
    lx0, lx1 = 0.0, 1.2
    ly = fy - 0.55
    for x in (lx0, (lx0 + lx1) / 2, lx1):
        b.cylinder((x, ly, z0), 0.06, 0.9, "PE_PlasterWhite", segs=6, smooth=False)
        b.box((x, ly, z0 + 0.93), (0.15, 0.15, 0.06), "PE_PlasterWhite")
    b.box(((lx0 + lx1) / 2, ly, z0 + 1.0), (lx1 - lx0 + 0.2, 0.15, 0.1), "PE_StoneBrick")
    b.quad((lx0 - 0.1, ly - 0.08, z0 + 1.05), (lx1 + 0.1, ly - 0.08, z0 + 1.05),
           (lx1 + 0.1, fy - 0.01, z0 + 1.3), (lx0 - 0.1, fy - 0.01, z0 + 1.3), "TEAM_Trim")
    b.quad((lx1 + 0.1, ly - 0.08, z0 + 1.05), (lx0 - 0.1, ly - 0.08, z0 + 1.05),
           (lx0 - 0.1, fy - 0.01, z0 + 1.3), (lx1 + 0.1, fy - 0.01, z0 + 1.3), "TEAM_Trim")
    # vine pergola (right) + amphorae
    for y in (-1.25, -0.55):
        parts.timber_post(b, (1.45, y, z0), 0.95, s=0.06)
    b.box((1.45, -0.9, z0 + 0.98), (0.3, 0.85, 0.05), "PE_WoodDark")
    b.box((1.45, -0.9, z0 + 1.04), (0.42, 0.9, 0.08), "PE_Foliage")
    for (ax, ay) in ((0.25, -1.35), (0.5, -1.45)):
        b.cylinder((ax, ay, z0), 0.07, 0.06, "PE_StoneBrick", segs=6, r_top=0.13, cap=False, smooth=False)
        b.cylinder((ax, ay, z0 + 0.06), 0.13, 0.22, "PE_StoneBrick", segs=6, r_top=0.06, smooth=False)
    parts.pennant(b, (mx + MW / 2 - 0.1, my, z0 + MH + 0.3), h=0.7, length=0.38)
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                                    "reference": "res://art/buildings/%s/house.png" % CIV})
    return ob, pe_kit.mesh_stats(ob)
