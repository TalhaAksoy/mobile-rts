"""Briton Town Center (3x3 -> 5.4 m).

Reference: art/buildings/britons/town_center.png.
Read from the reference: fortified stone manor-keep, steep blue-slate roofs, round corner
towers with conical slate caps, a half-timbered front gable over the arched door, red-cross
(St George) banners and flag, stone steps.
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "britons"
ASSET = "town_center"


def build():
    pe_kit.reset_scene()
    b = Builder("britons_town_center")
    pe_kit.ground_pad(b, 2.7, 2.7, seed=91)
    z0 = 0.08
    # main hall, ridge along X, steep slate
    HW, HD, HH = 3.3, 2.0, 1.8
    hy = 0.55
    b.box((0, hy, z0 + HH / 2), (HW, HD, HH), "PE_StoneGrey")
    b.gable_roof((0, hy, z0 + HH), HW, HD, 1.35, "PE_RoofSlate", overhang=0.15, ridge_axis="x")
    b.gable_end((0, hy, z0 + HH), HW, HD, 1.35, "PE_StoneGrey", ridge_axis="x")
    for x in (-1.15, 1.15):
        b.arch_opening((x, hy - HD / 2, z0 + 0.7), (0, -1, 0), 0.26, 0.55, "PE_Window", "PE_StoneWarm", pointed=True, segs=4)
    # chimney
    b.box((1.0, hy + 0.5, z0 + HH + 1.0), (0.3, 0.3, 1.0), "PE_StoneGrey")
    # front cross-wing: stone ground floor + half-timbered gable, ridge along Y
    WW, WD, WH = 1.4, 1.3, 2.05
    wy = hy - HD / 2 - WD / 2 + 0.25
    b.box((0, wy, z0 + WH / 2), (WW, WD, WH), "PE_StoneGrey")
    b.gable_roof((0, wy, z0 + WH), WW, WD, 1.15, "PE_RoofSlate", overhang=0.14, ridge_axis="y")
    wf = wy - WD / 2
    # half-timbered gable triangle on the front
    b.poly([(-WW / 2, wf - 0.01, z0 + WH), (WW / 2, wf - 0.01, z0 + WH), (0, wf - 0.01, z0 + WH + 1.15)], "PE_PlasterWhite")
    b.poly([(WW / 2, wy + WD / 2 + 0.01, z0 + WH), (-WW / 2, wy + WD / 2 + 0.01, z0 + WH), (0, wy + WD / 2 + 0.01, z0 + WH + 1.15)], "PE_StoneGrey")
    for x in (-0.35, 0.0, 0.35):
        h = 1.15 * (1 - abs(x) / (WW / 2))
        b.box((x, wf - 0.03, z0 + WH + h / 2), (0.06, 0.03, h), "PE_WoodDark")
    b.box((0, wf - 0.03, z0 + WH + 0.05), (WW, 0.04, 0.08), "PE_WoodDark")
    b.cylinder_between((-WW / 2 + 0.1, wf - 0.035, z0 + WH + 0.08), (0, wf - 0.035, z0 + WH + 1.05), 0.03, "PE_WoodDark", segs=4)
    b.cylinder_between((WW / 2 - 0.1, wf - 0.035, z0 + WH + 0.08), (0, wf - 0.035, z0 + WH + 1.05), 0.03, "PE_WoodDark", segs=4)
    b.arch_opening((0, wf, z0), (0, -1, 0), 0.72, 1.25, "PE_Window", "PE_StoneWarm", depth=0.05, frame=0.08, pointed=True)
    b.box((0, wf - 0.012, z0 + 1.42), (0.9, 0.03, 0.09), "TEAM_Trim")
    b.arch_opening((0, wf, z0 + 1.55), (0, -1, 0), 0.26, 0.38, "PE_Window", "PE_WoodDark", segs=3)
    b.stairs((0, wf, z0), 0.95, 2, 0.08, 0.16, "PE_StoneGrey")
    # round corner towers with conical slate caps
    for sx in (-1, 1):
        parts.round_tower(b, (sx * 1.9, -0.75, z0), 0.48, 2.5, cap_h=1.15, team_band=True)
        parts.round_tower(b, (sx * 1.85, 1.75, z0), 0.4, 2.15, cap_h=0.95)
        b.box((sx * 1.88, 0.5, z0 + 0.65), (0.25, 2.4, 1.3), "PE_StoneGrey")
        parts.crenellations(b, -0.35, 1.35, sx * 1.88, z0 + 1.3, depth=0.25, merlon_w=0.16, gap=0.12, h=0.14, mat="PE_StoneGrey", axis="y")
    for x in (-1.9, 1.9):
        b.banner((x, -0.75 - 0.48, z0 + 2.15), (0, -1, 0), 0.32, 0.75, CIV)
    b.flag((0.0, hy, z0 + HH + 1.3), 1.4, CIV, size=(0.62, 0.42))
    parts.round_tree(b, (-2.3, -2.05, z0), height=1.1, r=0.38)
    parts.cypress(b, (2.35, -2.1, z0), height=1.3, r=0.24)
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [3, 3], "footprint_m": 5.4, "reference": "res://art/buildings/britons/town_center.png"})
    return ob, pe_kit.mesh_stats(ob)
