"""Saracen Town Center (3x3 -> 5.4 m).

Reference: art/buildings/saracens/town_center.png.
Read from the reference: sandstone palace-mosque, large GOLD dome on a teal-banded drum,
slender sandstone minarets with teal balconies and small teal domes, a tall pointed iwan
portal framed in teal, green crescent banners, a striped market tent, palms.
Difference to the Ottomans: gold (not lead) dome, sandstone (not cream plaster), teal tile
accents, minarets with domed (not pencil-cone) tops, desert props.
"""
import math
import pe_kit, parts
from pe_kit import Builder

CIV = "saracens"
ASSET = "town_center"


def palm(b, base, h=1.7):
    x, y, z = base
    b.cylinder_between((x, y, z), (x + 0.12, y, z + h), 0.07, "PE_WoodLight", segs=5, smooth=False)
    for k in range(6):
        a = 2 * math.pi * k / 6
        tip = (x + 0.12 + math.cos(a) * 0.62, y + math.sin(a) * 0.62, z + h - 0.25)
        mid = (x + 0.12 + math.cos(a) * 0.3, y + math.sin(a) * 0.3, z + h + 0.08)
        b.cylinder_between((x + 0.12, y, z + h), mid, 0.06, "PE_Foliage", segs=3, smooth=False)
        b.cylinder_between(mid, tip, 0.05, "PE_Foliage", segs=3, smooth=False)


def build():
    pe_kit.reset_scene()
    b = Builder("saracens_town_center")
    pe_kit.ground_pad(b, 2.7, 2.7, seed=121)
    z0 = 0.08
    b.box((0, 0.25, z0 + 0.12), (4.2, 3.9, 0.24), "PE_Sandstone")
    zf = z0 + 0.24
    HW, HD, HH = 2.9, 2.6, 1.6
    yc = 0.45
    b.box((0, yc, zf + HH / 2), (HW, HD, HH), "PE_Sandstone")
    b.box((0, yc, zf + HH + 0.05), (HW + 0.12, HD + 0.12, 0.1), "PE_TileTeal")
    top = zf + HH + 0.1
    parts.crenellations(b, -HW / 2, HW / 2, yc - HD / 2 + 0.05, top, depth=0.1, merlon_w=0.12, gap=0.1, h=0.12, mat="PE_Sandstone")
    for side in (-1, 1):
        for yy in (-0.6, 0.6):
            b.arch_opening((side * HW / 2, yc + yy, zf + 0.5), (side, 0, 0), 0.32, 0.65, "PE_Window", "PE_TileTeal", pointed=True, segs=4)
    # iwan portal
    PW, PD, PH = 1.35, 0.35, 2.2
    py = yc - HD / 2 - PD / 2
    b.box((0, py, zf + PH / 2), (PW, PD, PH), "PE_Sandstone")
    b.arch_opening((0, py - PD / 2, zf), (0, -1, 0), 0.82, 1.65, "PE_Window", "PE_TileTeal", depth=0.05, frame=0.1, pointed=True)
    b.box((0, py - PD / 2 - 0.012, zf + PH - 0.2), (PW - 0.2, 0.03, 0.12), "TEAM_Trim")
    for x in (-1.1, 1.1):
        b.banner((x, yc - HD / 2, zf + HH - 0.1), (0, -1, 0), 0.3, 0.6, CIV)
    # drum + GOLD dome
    DR = 0.95
    b.cylinder((0, yc, top), DR, 0.42, "PE_Sandstone", segs=16, smooth=False)
    b.cylinder((0, yc, top + 0.3), DR + 0.02, 0.12, "PE_TileTeal", segs=16, cap=False)
    for i in range(12):
        a = 2 * math.pi * (i + 0.5) / 12
        b.arch_opening((math.cos(a) * DR * 0.99, yc + math.sin(a) * DR * 0.99, top + 0.06), (math.cos(a), math.sin(a), 0), 0.14, 0.22, "PE_Window", None, segs=3)
    db = top + 0.42
    b.dome((0, yc, db), DR + 0.05, "PE_Gold", segs=18, rings=7, height=1.15)
    b.cylinder((0, yc, db + 1.12), 0.025, 0.35, "PE_Gold", segs=4)
    b.cylinder_between((-0.08, yc, db + 1.42), (0.08, yc, db + 1.42), 0.035, "PE_Gold", segs=5)
    # small teal corner domes
    for sx in (-1, 1):
        for sy in (-1, 1):
            cx, cy = sx * (HW / 2 - 0.3), yc + sy * (HD / 2 - 0.3)
            b.cylinder((cx, cy, top), 0.22, 0.22, "PE_Sandstone", segs=8, cap=False)
            b.dome((cx, cy, top + 0.22), 0.24, "PE_TileTeal", segs=8, rings=3, height=0.3)
    # minarets (front corners) and tent + palms
    for sx in (-1, 1):
        parts.saracen_minaret(b, (sx * 1.95, -1.25, zf), height=4.2)
    tx, ty = -1.75, -2.05
    b.cylinder((tx, ty, z0), 0.42, 0.55, "PE_PlasterWhite", segs=8, cap=False)
    b.cone((tx, ty, z0 + 0.55), 0.55, 0.45, "PE_ClothRed", segs=8, smooth=False)
    palm(b, (2.25, 2.1, z0), 1.7)
    palm(b, (-2.2, 2.05, z0), 1.5)
    b.flag((1.0, yc + 0.8, top), 1.9, CIV, size=(0.6, 0.4))
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [3, 3], "footprint_m": 5.4, "reference": "res://art/buildings/saracens/town_center.png"})
    return ob, pe_kit.mesh_stats(ob)
