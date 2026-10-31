"""Byzantine Town Center (3x3 -> 5.4 m).

Reference: art/buildings/byzantines/town_center.png.
Read from the reference: cross-in-square church-palace in layered stone-and-brick (opus
mixtum), terracotta-tiled main dome on a windowed drum, smaller red domes, red-tile gabled
arms, round-arched portal and arcade, purple-and-gold banners, cypress greenery.
"""
import math
import pe_kit, parts
from pe_kit import Builder

CIV = "byzantines"
ASSET = "town_center"


def build():
    pe_kit.reset_scene()
    b = Builder("byzantines_town_center")
    pe_kit.ground_pad(b, 2.7, 2.7, seed=81)
    z0 = 0.08
    b.box((0, 0.2, z0 + 0.1), (4.4, 4.2, 0.2), "PE_StoneWarm")
    zf = z0 + 0.2
    yc = 0.35
    # core square
    CW, CH = 2.4, 1.75
    b.box((0, yc, zf + CH / 2), (CW, CW, CH), "PE_StoneBrick")
    b.box((0, yc, zf + CH + 0.05), (CW + 0.1, CW + 0.1, 0.1), "PE_StoneWarm")
    top = zf + CH + 0.1
    # four gabled arms (cross plan); the front arm carries the portal
    AW, AL, AH = 1.25, 0.75, 1.35
    for sx, sy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
        ax = sx * (CW / 2 + AL / 2); ay = yc + sy * (CW / 2 + AL / 2)
        if sx == 0:
            b.box((ax, ay, zf + AH / 2), (AW, AL + 0.05, AH), "PE_StoneBrick")
            b.gable_roof((ax, ay, zf + AH), AW, AL, 0.5, "PE_RoofRed", overhang=0.1, ridge_axis="y")
            b.gable_end((ax, ay, zf + AH), AW, AL, 0.5, "PE_StoneBrick", ridge_axis="y")
        else:
            b.box((ax, ay, zf + AH / 2), (AL + 0.05, AW, AH), "PE_StoneBrick")
            b.gable_roof((ax, ay, zf + AH), AL, AW, 0.5, "PE_RoofRed", overhang=0.1, ridge_axis="x")
            b.gable_end((ax, ay, zf + AH), AL, AW, 0.5, "PE_StoneBrick", ridge_axis="x")
    fy = yc - CW / 2 - AL
    b.arch_opening((0, fy, zf), (0, -1, 0), 0.7, 1.1, "PE_Window", "PE_StoneWarm", depth=0.05, frame=0.08)
    b.box((0, fy - 0.012, zf + 1.18), (0.9, 0.03, 0.08), "TEAM_Trim")
    for sx in (-1, 1):
        b.arch_opening((sx * (CW / 2 + AL), yc, zf + 0.45), (sx, 0, 0), 0.34, 0.6, "PE_Window", "PE_StoneWarm")
    for x in (-0.85, 0.85):
        b.arch_opening((x, yc - CW / 2, zf + 0.55), (0, -1, 0), 0.26, 0.5, "PE_Window", "PE_StoneWarm", segs=4)
    # corner domes
    for sx in (-1, 1):
        for sy in (-1, 1):
            cx, cy = sx * (CW / 2 - 0.32), yc + sy * (CW / 2 - 0.32)
            b.cylinder((cx, cy, top), 0.3, 0.28, "PE_StoneBrick", segs=10, cap=False)
            b.dome((cx, cy, top + 0.28), 0.32, "PE_RoofRed", segs=10, rings=3, height=0.28)
    # drum + terracotta main dome + gold cross
    DR = 0.88
    b.cylinder((0, yc, top), DR, 0.6, "PE_StoneBrick", segs=16, smooth=False)
    for i in range(12):
        a = 2 * math.pi * (i + 0.5) / 12
        b.arch_opening((math.cos(a) * DR * 0.99, yc + math.sin(a) * DR * 0.99, top + 0.14), (math.cos(a), math.sin(a), 0), 0.17, 0.34, "PE_Window", None, segs=3)
    b.cylinder((0, yc, top + 0.6), DR + 0.06, 0.07, "PE_StoneWarm", segs=16)
    db = top + 0.67
    b.dome((0, yc, db), DR + 0.04, "PE_RoofRed", segs=18, rings=6, height=0.82)
    tip = db + 0.82
    b.cylinder((0, yc, tip - 0.02), 0.03, 0.42, "PE_Gold", segs=4)
    b.cylinder_between((-0.12, yc, tip + 0.28), (0.12, yc, tip + 0.28), 0.028, "PE_Gold", segs=4)
    # front arcade (narthex porch) with lean-to roof
    for i in range(4):
        x = -1.35 + i * 0.9
        if abs(x) < 0.5:
            continue
        b.box((x, fy - 0.42, zf + 0.5), (0.14, 0.14, 1.0), "PE_StoneWarm")
    # banners + flag + cypresses
    for x in (-0.47, 0.47):
        b.banner((x, fy, zf + 1.3), (0, -1, 0), 0.22, 0.48, CIV)
    for sx in (-1, 1):
        b.banner((sx * (CW / 2 + AL), yc + 0.42, zf + 1.25), (sx, 0, 0), 0.24, 0.5, CIV)
    b.flag((0.9, yc + 0.9, top), 1.8, CIV, size=(0.62, 0.42))
    parts.cypress(b, (-2.2, -1.9, z0), height=1.5, r=0.24)
    parts.cypress(b, (2.25, -1.75, z0), height=1.3, r=0.22)
    parts.cypress(b, (2.25, 2.25, z0), height=1.6, r=0.25)
    parts.round_tree(b, (-2.15, 2.0, z0), height=1.1, r=0.4)
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [3, 3], "footprint_m": 5.4, "reference": "res://art/buildings/byzantines/town_center.png"})
    return ob, pe_kit.mesh_stats(ob)
