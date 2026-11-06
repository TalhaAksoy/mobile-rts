"""Civ blacksmiths, lumber camps and mining camps (2x2 grid, pad +-1.8 m), one per civ from
docs/art/culture/<civ>.md (blacksmith, lumber_camp, mining_camp) and the 2D layouts, instead of the shared
hall + canopy layouts with civ materials. Every smithy keeps an anvil and a forge, every lumber camp logs,
every mining camp ore, so the type still reads. The Mongol ger camps stay in bldtypes.
Budget: smiths were 500-740, lumber 500-620, mining 700-820 triangles; keep each under ~750.
Coordinates: Blender Z up, front (camera side) = -Y, z0 = ground-pad top.
"""
import math
import parts
import civstyle as cs
from yards import _shed


# ---------------------------------------------------------------- shared pieces
def chimney(b, x, y, z, h, mat, w=0.36):
    b.box((x, y, z + h / 2), (w, w, h), mat)
    b.box((x, y, z + h + 0.04), (w + 0.08, w + 0.08, 0.08), mat)


def forge(b, x, y, z, mat, w=0.7):
    b.box((x, y, z + 0.32), (w, 0.55, 0.64), mat)
    b.box((x, y - 0.28, z + 0.45), (w * 0.5, 0.03, 0.2), "PE_Gold")                # glowing hearth mouth
    b.box((x, y - 0.29, z + 0.36), (w * 0.4, 0.03, 0.06), "PE_ClothRed")


def bellows(b, x, y, z):
    b.box((x, y, z + 0.2), (0.45, 0.3, 0.3), "PE_WoodLight")
    b.cylinder_between((x - 0.3, y, z + 0.25), (x - 0.22, y, z + 0.25), 0.04, "PE_WoodDark", segs=4)


def headframe(b, x, y, z, h=1.9):
    for sx in (-1, 1):
        b.cylinder_between((x + sx * 0.5, y, z), (x + sx * 0.12, y, z + h), 0.05, "PE_WoodDark", segs=4)
    b.box((x, y, z + h * 0.5), (0.75, 0.06, 0.06), "PE_WoodLight")
    b.cylinder_between((x, y - 0.06, z + h), (x, y + 0.06, z + h), 0.22, "PE_WoodDark", segs=10, cap=True)
    b.cylinder((x, y, z + 0.05), 0.012, h - 0.25, "PE_Felt", segs=3, cap=False)
    shaft(b, x, y, z)


def shaft(b, x, y, z, s=0.6):
    b.box((x, y, z + 0.03), (s, s, 0.06), "PE_Window")
    for sy in (-1, 1):
        b.box((x, y + sy * s / 2, z + 0.06), (s + 0.12, 0.08, 0.12), "PE_WoodLight")
    for sx in (-1, 1):
        b.box((x + sx * s / 2, y, z + 0.06), (0.08, s, 0.12), "PE_WoodLight")


def windlass(b, x, y, z):
    shaft(b, x, y, z, s=0.5)
    for sx in (-1, 1):
        b.box((x + sx * 0.32, y, z + 0.4), (0.07, 0.07, 0.8), "PE_WoodDark")
    b.cylinder_between((x - 0.32, y, z + 0.72), (x + 0.32, y, z + 0.72), 0.07, "PE_WoodLight", segs=6)
    b.cylinder_between((x + 0.36, y, z + 0.72), (x + 0.36, y - 0.18, z + 0.6), 0.015, "PE_Iron", segs=3)


def treadwheel(b, x, y, z, r=0.85):
    n = 12
    for i in range(n):                                                             # rim as a ring of struts
        a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
        p0 = (x + r * math.cos(a0), y, z + r + 0.1 + r * math.sin(a0))
        p1 = (x + r * math.cos(a1), y, z + r + 0.1 + r * math.sin(a1))
        b.cylinder_between(p0, p1, 0.04, "PE_WoodDark", segs=4)
    for i in range(4):
        a = math.pi * i / 4
        b.cylinder_between((x - r * math.cos(a), y, z + r + 0.1 - r * math.sin(a)),
                           (x + r * math.cos(a), y, z + r + 0.1 + r * math.sin(a)), 0.025, "PE_WoodLight", segs=4)
    for sx in (-1, 1):
        b.cylinder_between((x + sx * 0.5, y, z), (x, y, z + r + 0.1), 0.04, "PE_WoodDark", segs=4)


def basket(b, x, y, z, load="PE_Gold"):
    b.cylinder((x, y, z), 0.16, 0.24, "PE_Thatch", segs=6, cap=False, smooth=False, r_top=0.2)
    b.dome((x, y, z + 0.22), 0.17, load, segs=6, rings=2, height=0.1, smooth=False)


def donkey(b, x, y, z):
    c = "PE_StoneGrey"
    b.box((x, y, z + 0.45), (0.55, 0.2, 0.22), c)
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.box((x + sx * 0.2, y + sy * 0.07, z + 0.18), (0.05, 0.05, 0.36), c)
    b.cylinder_between((x + 0.24, y, z + 0.5), (x + 0.36, y, z + 0.72), 0.06, c, segs=4)
    b.box((x + 0.43, y, z + 0.72), (0.18, 0.09, 0.09), c)
    for sy in (-1, 1):
        b.box((x + 0.36, y + sy * 0.03, z + 0.86), (0.03, 0.03, 0.16), c)            # long ears
        b.box((x, y + sy * 0.15, z + 0.45), (0.22, 0.08, 0.2), "PE_Thatch")            # panniers


def furnace(b, x, y, z, h=1.0):
    b.cylinder((x, y, z), 0.32, h, "PE_Dirt", segs=8, smooth=False, r_top=0.18)
    b.box((x, y - 0.3, z + 0.15), (0.14, 0.04, 0.1), "PE_Gold")


def quarry(b, x, y, z, w, mat):
    for k in range(3):
        b.box((x, y + k * 0.35, z + 0.25 + k * 0.45), (w - k * 0.3, 0.4, 0.5 + k * 0.9), mat)


def adit(b, x, y, z, bank="PE_Dirt"):
    b.frustum((x, y + 0.4, z), 2.2, 1.4, 1.4, 0.6, 1.2, bank, top_mat="PE_Grass")
    b.box((x, y - 0.32, z + 0.4), (0.6, 0.05, 0.8), "PE_Window")
    for sx in (-1, 1):
        b.box((x + sx * 0.36, y - 0.36, z + 0.45), (0.1, 0.1, 0.9), "PE_WoodDark")
    b.box((x, y - 0.36, z + 0.95), (0.95, 0.12, 0.12), "PE_WoodLight")


def logs(b, x, y, z, length=1.2, rows=3, axis="x", r=0.1, mat=None):
    parts.log_pile(b, (x, y, z), length=length, rows=rows, r=r, axis=axis)


def sawhorse(b, x, y, z):
    for xx in (x - 0.3, x + 0.3):
        b.cylinder_between((xx, y - 0.15, z), (xx, y, z + 0.45), 0.03, "PE_WoodDark", segs=4)
        b.cylinder_between((xx, y + 0.15, z), (xx, y, z + 0.45), 0.03, "PE_WoodDark", segs=4)
    b.cylinder_between((x - 0.5, y, z + 0.5), (x + 0.5, y, z + 0.5), 0.09, "PE_Beam", segs=6, smooth=False)


def sawpit(b, x, y, z):
    b.box((x, y, z + 0.02), (1.3, 0.5, 0.04), "PE_Window")
    for xx in (x - 0.5, x + 0.5):
        b.box((xx, y, z + 0.2), (0.08, 0.6, 0.06), "PE_WoodDark")
    b.cylinder_between((x - 0.75, y, z + 0.32), (x + 0.75, y, z + 0.32), 0.12, "PE_Beam", segs=6, smooth=False)
    b.box((x + 0.1, y, z + 0.7), (0.03, 0.03, 0.75), "PE_Iron")                   # pit saw
    b.box((x + 0.1, y, z + 1.06), (0.2, 0.04, 0.04), "PE_WoodDark")


def flag(b, civ, x, y, z0, h=1.6):
    cs.flagpole(b, civ, x, y, z0, h=h, size=(0.45, 0.3))


# ---------------------------------------------------------------- blacksmiths
def smith_ottomans(b, z0):
    b.box((-0.7, 0.7, z0 + 0.6), (1.5, 1.2, 1.2), "PE_StoneWarm")
    b.arch_opening((-0.95, 0.1, z0), (0, -1, 0), 0.45, 0.8, "PE_WoodDark", "PE_StoneBrick", segs=4)
    b.hip_roof((-0.7, 0.7, z0 + 1.2), 1.5, 1.2, 0.5, "PE_RoofRed", overhang=0.15)
    chimney(b, -1.1, 0.95, z0, 2.3, "PE_StoneBrick")
    _shed(b, (0.85, 0.4, z0), 1.2, 1.0, 1.15, "PE_RoofRed", bays=2)
    forge(b, 0.85, 0.6, z0, "PE_StoneBrick", w=0.6)
    cs.anvil(b, 0.6, -0.6, z0)
    b.box((-0.4, -0.8, z0 + 0.15), (0.7, 0.25, 0.3), "PE_StoneWarm")               # quench trough
    b.box((-0.4, -0.8, z0 + 0.31), (0.6, 0.15, 0.02), "PE_Window")
    flag(b, "ottomans", -1.45, -1.3, z0)


def smith_byzantines(b, z0):
    b.box((-0.1, 0.65, z0 + 0.7), (2.6, 1.2, 1.4), "PE_StoneBrick")
    for i in range(3):
        b.arch_opening((-1.0 + i * 0.9, 0.05, z0), (0, -1, 0), 0.55, 0.9, "PE_Window", "PE_StoneWarm", segs=4)
    b.gable_roof((-0.1, 0.65, z0 + 1.4), 2.6, 1.2, 0.45, "PE_RoofRed", overhang=0.12, ridge_axis="x", end_mat="PE_StoneBrick")
    b.box((-0.1, 0.04, z0 + 1.25), (0.8, 0.03, 0.08), "TEAM_Trim")
    forge(b, -0.1, 0.45, z0, "PE_StoneWarm", w=0.5)
    chimney(b, 0.8, 0.95, z0, 2.3, "PE_StoneBrick")
    cs.anvil(b, -0.3, -0.7, z0)
    cs.weapon_rack(b, 0.9, -0.8, z0, n=4)
    flag(b, "byzantines", -1.45, -1.3, z0)


def smith_britons(b, z0):
    b.box((-0.45, 0.7, z0 + 0.55), (2.0, 1.2, 1.1), "PE_StoneGrey")
    b.box((-0.9, 0.09, z0 + 0.4), (0.45, 0.04, 0.8), "PE_WoodDark")
    for i in range(4):                                                             # horseshoes on the wall
        b.box((-0.4 + i * 0.18, 0.08, z0 + 0.85), (0.1, 0.03, 0.1), "PE_Iron")
    b.gable_roof((-0.45, 0.7, z0 + 1.1), 2.0, 1.2, 0.85, "PE_Thatch", overhang=0.28, ridge_axis="x", end_mat="PE_StoneGrey")
    b.gable_end((-0.45, 0.7, z0 + 1.1), 2.0, 1.2, 0.85, "PE_StoneGrey", ridge_axis="x")
    forge(b, 1.0, 0.2, z0, "PE_StoneGrey", w=0.6)                                  # open forge with a hood
    b.frustum((1.0, 0.2, z0 + 0.95), 0.7, 0.55, 0.3, 0.3, 0.5, "PE_StoneGrey")
    chimney(b, 1.0, 0.2, z0 + 1.45, 0.8, "PE_StoneGrey", w=0.3)
    cs.anvil(b, 0.5, -0.7, z0)
    parts.barrel(b, (-0.9, -0.8, z0), r=0.15, h=0.36)
    flag(b, "britons", -1.45, -1.3, z0)


def smith_franks(b, z0):
    b.box((-0.3, 0.7, z0 + 0.7), (2.2, 1.2, 1.4), "PE_StoneWarm")
    b.arch_opening((-0.3, 0.1, z0), (0, -1, 0), 0.8, 0.95, "PE_Window", "PE_StoneGrey", segs=4, pointed=True)
    b.box((-0.3, 0.06, z0 + 0.25), (0.5, 0.03, 0.2), "PE_Gold")
    b.hip_roof((-0.3, 0.7, z0 + 1.4), 2.2, 1.2, 0.85, "PE_RoofSlate", overhang=0.12)
    chimney(b, 0.55, 0.9, z0, 2.7, "PE_StoneBrick")
    b.box((-0.3, 0.06, z0 + 1.2), (0.7, 0.03, 0.08), "TEAM_Trim")
    cs.anvil(b, 0.5, -0.6, z0)
    b.cylinder((1.2, -0.8, z0), 0.2, 0.3, "PE_WoodLight", segs=8)                  # quench tub
    b.cylinder((1.2, -0.8, z0 + 0.29), 0.17, 0.02, "PE_Window", segs=8)
    cs.weapon_rack(b, -1.0, -0.8, z0, n=3)
    flag(b, "franks", -1.45, -1.3, z0)


def smith_teutons(b, z0):
    b.box((-0.3, 0.7, z0 + 0.7), (1.9, 1.3, 1.4), "PE_BrickRed")
    b.gable_roof((-0.3, 0.7, z0 + 1.4), 1.9, 1.3, 1.0, "PE_RoofRed", overhang=0.1, ridge_axis="y", end_mat="PE_BrickRed")
    cs._stepped_gables(b, -0.3, 0.7, z0 + 1.4, 1.9, 1.3, 1.0, "y", "PE_BrickRed", steps=4)
    b.arch_opening((-0.3, 0.05, z0), (0, -1, 0), 0.75, 0.95, "PE_Window", "PE_StoneGrey", segs=4, pointed=True)
    b.box((-0.3, 0.02, z0 + 0.25), (0.45, 0.03, 0.2), "PE_Gold")
    b.box((-0.3, 0.02, z0 + 1.2), (0.6, 0.03, 0.08), "TEAM_Trim")
    chimney(b, 1.0, 0.9, z0, 3.0, "PE_BrickRed", w=0.45)
    cs.anvil(b, 0.5, -0.6, z0)
    parts.barrel(b, (-1.0, -0.8, z0), r=0.15, h=0.36)
    flag(b, "teutons", -1.45, -1.3, z0)


def smith_japanese(b, z0):
    _shed(b, (0, 0.55, z0), 2.8, 1.4, 1.3, "PE_RoofDark", wall_mat="PE_WoodDark", pent=False, curve=0.1, bays=3)
    furnace(b, -0.6, 0.6, z0, h=0.8)
    bellows(b, 0.3, 0.7, z0)
    b.cylinder_between((-1.3, -0.15, z0 + 1.15), (1.3, -0.15, z0 + 1.15), 0.04, "PE_Thatch", segs=5)   # shimenawa
    for x in (-0.7, 0.0, 0.7):
        b.box((x, -0.16, z0 + 0.98), (0.05, 0.02, 0.28), "PE_PlasterWhite")          # shide papers
    cs.anvil(b, 0.5, -0.7, z0)
    b.cylinder((-1.0, -0.8, z0), 0.17, 0.3, "PE_WoodLight", segs=8)


def smith_saracens(b, z0):
    b.box((0, 0.6, z0 + 0.8), (2.6, 1.4, 1.6), "PE_Sandstone")
    b.cylinder_between((-1.3, 0.6, z0 + 1.6), (1.3, 0.6, z0 + 1.6), 0.5, "PE_Sandstone", segs=8, smooth=False)   # barrel vault
    b.arch_opening((-0.3, -0.1, z0), (0, -1, 0), 1.0, 1.15, "PE_Window", "PE_TileTeal", segs=5, pointed=True)
    forge(b, -0.3, 0.4, z0, "PE_Sandstone", w=0.55)
    for i in range(4):                                                              # swords hung on the wall
        b.box((0.65 + i * 0.15, -0.11, z0 + 0.95), (0.03, 0.03, 0.5), "PE_Iron")
        b.box((0.65 + i * 0.15, -0.11, z0 + 1.12), (0.1, 0.03, 0.03), "PE_Gold")
    b.box((-0.3, -0.12, z0 + 1.3), (0.8, 0.03, 0.08), "TEAM_Trim")
    cs.anvil(b, 0.5, -0.8, z0)
    bellows(b, -1.0, -0.8, z0)


def smith_vikings(b, z0):
    _shed(b, (-0.2, 0.5, z0), 2.4, 1.3, 1.1, "PE_Grass", pent=False, bays=2, back=False)
    furnace(b, -0.7, 0.6, z0, h=0.75)
    bellows(b, 0.2, 0.7, z0)
    b.cylinder((0.5, -0.7, z0), 0.2, 0.35, "PE_WoodLight", segs=8)                  # anvil on a log
    cs.anvil(b, 0.5, -0.7, z0 + 0.32)
    b.box((-1.0, -0.8, z0 + 0.4), (0.3, 0.15, 0.8), "PE_StoneGrey")                 # rune stone
    flag(b, "vikings", 1.45, -1.3, z0)


def smith_chinese(b, z0):
    b.box((0, 0.6, z0 + 0.1), (2.9, 1.5, 0.2), "PE_StoneGrey")
    _shed(b, (0, 0.6, z0 + 0.2), 2.7, 1.3, 1.3, "PE_RoofDark", wall_mat="PE_StoneGrey", post="PE_LacquerRed", pent=False,
          curve=0.16, under="PE_LacquerRed", bays=3)
    forge(b, -0.6, 0.75, z0 + 0.2, "PE_StoneGrey", w=0.6)
    b.box((0.35, 0.75, z0 + 0.45), (0.6, 0.35, 0.5), "PE_WoodLight")               # double-acting box bellows
    b.cylinder_between((0.7, 0.75, z0 + 0.55), (0.95, 0.75, z0 + 0.55), 0.03, "PE_WoodDark", segs=4)
    chimney(b, -0.6, 1.1, z0 + 0.2, 2.0, "PE_StoneGrey", w=0.3)
    cs.anvil(b, 0.4, -0.7, z0)
    cs.weapon_rack(b, -0.9, -0.8, z0, n=3)


# ---------------------------------------------------------------- lumber camps
def lumber_ottomans(b, z0):
    _shed(b, (-0.3, 0.6, z0), 2.4, 1.2, 1.2, "PE_RoofRed", pent=False, bays=3)
    logs(b, -0.3, 0.7, z0, length=1.8, rows=3)
    sawhorse(b, 0.6, -0.7, z0)
    logs(b, -0.9, -0.8, z0, length=1.0, rows=2, axis="y")
    parts.cypress(b, (1.4, 0.9, z0), height=1.4)
    flag(b, "ottomans", 1.45, -1.3, z0)


def lumber_byzantines(b, z0):
    b.box((-0.2, 0.6, z0 + 0.12), (2.5, 1.3, 0.24), "PE_StoneWarm")               # stone footings
    _shed(b, (-0.2, 0.6, z0 + 0.24), 2.4, 1.2, 1.1, "PE_RoofRed", pent=False, bays=3)
    logs(b, -0.2, 0.7, z0 + 0.24, length=1.8, rows=3)
    logs(b, 0.6, -0.8, z0, length=1.2, rows=3)
    sawhorse(b, -0.8, -0.7, z0)
    flag(b, "byzantines", 1.45, -1.3, z0)


def lumber_britons(b, z0):
    _shed(b, (-0.8, 0.7, z0), 1.6, 1.0, 1.0, "PE_Thatch", bays=2)
    sawpit(b, 0.5, -0.3, z0)
    logs(b, -0.8, -0.8, z0, length=1.1, rows=3, r=0.12)
    logs(b, 1.0, 1.0, z0, length=0.9, rows=2, axis="y")
    flag(b, "britons", 1.45, -1.3, z0)


def lumber_franks(b, z0):
    _shed(b, (-0.5, 0.65, z0), 2.0, 1.1, 1.2, "PE_RoofSlate", bays=2)
    sawpit(b, 0.4, -0.6, z0)
    logs(b, -0.5, 0.7, z0, length=1.5, rows=3, r=0.11)
    logs(b, 1.1, 0.6, z0, length=0.9, rows=2, axis="y")
    flag(b, "franks", -1.45, -1.3, z0)


def lumber_teutons(b, z0):
    b.box((-0.6, 0.75, z0 + 0.6), (1.6, 1.0, 1.2), "PE_PlasterWhite")
    for i in range(5):
        b.box((-1.4 + i * 0.4, 0.24, z0 + 0.6), (0.07, 0.03, 1.2), "PE_Beam")
    b.cylinder_between((-1.4, 0.23, z0 + 0.1), (-0.6, 0.23, z0 + 1.1), 0.03, "PE_Beam", segs=4)
    b.box((-0.4, 0.23, z0 + 0.45), (0.5, 0.03, 0.9), "PE_WoodDark")
    b.gable_roof((-0.6, 0.75, z0 + 1.2), 1.6, 1.0, 0.7, "PE_RoofRed", overhang=0.12, ridge_axis="x", end_mat="PE_PlasterWhite")
    b.gable_end((-0.6, 0.75, z0 + 1.2), 1.6, 1.0, 0.7, "PE_PlasterWhite", ridge_axis="x")
    logs(b, 0.9, 0.6, z0, length=1.0, rows=3, axis="y")
    sawhorse(b, 0.3, -0.7, z0)
    logs(b, -0.9, -0.8, z0, length=1.0, rows=2)
    flag(b, "teutons", 1.45, -1.3, z0)


def lumber_japanese(b, z0):
    _shed(b, (-0.8, 0.7, z0), 1.6, 1.0, 1.1, "PE_Thatch", pent=False, bays=2)
    for k in range(3):                                                             # long cedar logs
        b.cylinder_between((-0.6, -0.3 - k * 0.22, z0 + 0.12), (1.4, -0.3 - k * 0.22, z0 + 0.12), 0.11, "PE_Beam",
                           segs=6, smooth=False, cap=True)
    b.cylinder_between((-0.4, -0.41, z0 + 0.32), (1.2, -0.41, z0 + 0.32), 0.1, "PE_Beam", segs=6, smooth=False, cap=True)
    for i in range(8):                                                             # bamboo fence at the back
        b.cylinder((0.5 + i * 0.16, 1.4, z0), 0.035, 0.9, "PE_CropGreen", segs=4, cap=False)
    b.box((1.06, 1.4, z0 + 0.65), (1.2, 0.04, 0.04), "PE_WoodLight")
    sawhorse(b, -1.0, -0.9, z0)


def lumber_saracens(b, z0):
    for sx in (-1, 1):                                                             # palm-trunk posts
        for sy in (-1, 1):
            b.cylinder((-0.4 + sx * 0.9, 0.6 + sy * 0.45, z0), 0.07, 1.2, "PE_WoodLight", segs=5, cap=False)
    b.box((-0.4, 0.6, z0 + 1.22), (2.0, 1.1, 0.06), "PE_Thatch")                   # reed roof
    for k in range(3):
        b.cylinder_between((-1.0, -0.4 - k * 0.22, z0 + 0.1), (0.8, -0.4 - k * 0.22, z0 + 0.1), 0.1, "PE_WoodLight",
                           segs=6, smooth=False, cap=True)
    logs(b, -0.4, 0.6, z0, length=1.4, rows=2)
    parts.round_tree(b, (1.3, 1.0, z0), height=1.6, r=0.4)
    flag(b, "saracens", 1.45, -1.3, z0)


def lumber_vikings(b, z0):
    for i in range(7):                                                             # half-built boat: keel + strakes
        t = (i - 3) / 3.0
        x = t * 1.1
        zz = z0 + 0.35 + 0.25 * t * t
        b.box((x, 0.4, zz), (0.34, 0.08, 0.06), "PE_WoodDark")
        b.box((x, 0.4 - 0.22 - 0.05 * (1 - t * t), zz + 0.15), (0.34, 0.04, 0.16), "PE_WoodLight")
        b.box((x, 0.4 + 0.22 + 0.05 * (1 - t * t), zz + 0.15), (0.34, 0.04, 0.16), "PE_WoodLight")
    for sx in (-1, 1):
        b.cylinder_between((sx * 1.1, 0.4, z0 + 0.6), (sx * 1.35, 0.4, z0 + 1.05), 0.05, "PE_WoodDark", segs=4)
        b.box((sx * 0.7, 0.4, z0 + 0.15), (0.1, 0.5, 0.3), "PE_WoodDark")          # trestles
    logs(b, -0.7, -0.8, z0, length=1.1, rows=3)
    b.box((0.7, -0.8, z0 + 0.25), (0.6, 0.25, 0.08), "PE_WoodLight")              # adze bench
    for sx in (-1, 1):
        b.box((0.7 + sx * 0.22, -0.8, z0 + 0.1), (0.06, 0.2, 0.2), "PE_WoodDark")
    flag(b, "vikings", 1.45, -1.3, z0)


def lumber_chinese(b, z0):
    b.box((-0.3, 0.6, z0 + 0.08), (2.5, 1.3, 0.16), "PE_StoneGrey")
    _shed(b, (-0.3, 0.6, z0 + 0.16), 2.3, 1.1, 1.1, "PE_RoofDark", post="PE_CropGreen", pent=False, curve=0.16, bays=3)
    logs(b, -0.3, 0.7, z0 + 0.16, length=1.6, rows=2)
    logs(b, -0.8, -0.8, z0, length=1.1, rows=3)
    for sx in (-1, 1):                                                             # two-man frame saw
        b.box((0.7 + sx * 0.4, -0.7, z0 + 0.45), (0.05, 0.05, 0.9), "PE_WoodDark")
    b.box((0.7, -0.7, z0 + 0.88), (0.85, 0.04, 0.04), "PE_WoodDark")
    b.box((0.7, -0.7, z0 + 0.15), (0.85, 0.02, 0.06), "PE_Iron")


# ---------------------------------------------------------------- mining camps
def mine_ottomans(b, z0):
    b.box((-0.9, 0.9, z0 + 0.5), (1.2, 0.9, 1.0), "PE_StoneWarm")
    b.hip_roof((-0.9, 0.9, z0 + 1.0), 1.2, 0.9, 0.4, "PE_RoofRed", overhang=0.12)
    headframe(b, 0.6, 0.6, z0)
    basket(b, -0.9, -0.4, z0, "PE_Gold")
    basket(b, -0.5, -0.7, z0, "PE_StoneGrey")
    donkey(b, 0.6, -0.8, z0)
    cs.rock_pile(b, 1.3, -0.2, z0, mat="PE_Gold", n=3, s=0.16)
    flag(b, "ottomans", -1.45, -1.3, z0)


def mine_byzantines(b, z0):
    quarry(b, -0.6, 1.0, z0, 2.2, "PE_PlasterWhite")                               # marble quarry face
    headframe(b, 0.9, 0.2, z0, h=1.6)
    for k, (x, y) in enumerate(((-0.9, -0.5), (-0.4, -0.8), (-0.7, -0.95))):        # cut marble blocks
        b.box((x, y, z0 + 0.15 + (k == 2) * 0.3), (0.45, 0.3, 0.3), "PE_PlasterWhite")
    cs.cart(b, 0.6, -0.9, z0, load="PE_StoneGrey", load2="PE_Gold")
    flag(b, "byzantines", -1.45, -1.3, z0)


def mine_britons(b, z0):
    b.box((-0.9, 0.9, z0 + 0.45), (1.1, 0.8, 0.9), "PE_StoneGrey")
    b.gable_roof((-0.9, 0.9, z0 + 0.9), 1.1, 0.8, 0.5, "PE_RoofSlate", overhang=0.1, ridge_axis="x")
    b.gable_end((-0.9, 0.9, z0 + 0.9), 1.1, 0.8, 0.5, "PE_StoneGrey", ridge_axis="x")
    windlass(b, 0.6, 0.5, z0)
    for x in (-0.6, 0.6):                                                          # ore barrows
        b.box((x, -0.8, z0 + 0.25), (0.45, 0.3, 0.2), "PE_WoodLight")
        b.dome((x, -0.8, z0 + 0.35), 0.18, "PE_StoneGrey", segs=6, rings=2, height=0.1, smooth=False)
        b.cylinder_between((x - 0.25, -0.8, z0 + 0.1), (x - 0.25, -0.75, z0 + 0.1), 0.1, "PE_WoodDark", segs=6, cap=True)
    cs.rock_pile(b, 1.3, -0.4, z0, mat="PE_StoneGrey", n=3, s=0.18)
    flag(b, "britons", -1.45, -1.3, z0)


def mine_franks(b, z0):
    headframe(b, -0.5, 0.7, z0, h=2.0)
    windlass(b, 0.9, 0.6, z0)
    cs.cart(b, 0.2, -0.8, z0, load="PE_StoneGrey", load2="PE_Gold")
    cs.rock_pile(b, -1.1, -0.6, z0, mat="PE_StoneGrey", n=4, s=0.2)
    flag(b, "franks", -1.45, -1.3, z0)


def mine_teutons(b, z0):
    headframe(b, 0.6, 0.7, z0, h=2.0)
    treadwheel(b, -0.7, 0.8, z0)
    cs.cart(b, 0.6, -0.8, z0, load="PE_StoneGrey", load2="PE_Gold")
    parts.barrel(b, (-1.1, -0.8, z0), r=0.15, h=0.36)
    flag(b, "teutons", -1.45, -1.3, z0)


def mine_japanese(b, z0):
    _shed(b, (-0.9, 0.8, z0), 1.4, 0.9, 1.0, "PE_Thatch", pent=False, bays=2)
    shaft(b, 0.6, 0.5, z0, s=0.7)
    for sx in (-1, 1):                                                             # timber frame over the shaft
        b.box((0.6 + sx * 0.42, 0.5, z0 + 0.55), (0.1, 0.1, 1.1), "PE_WoodDark")
    b.box((0.6, 0.5, z0 + 1.15), (1.1, 0.12, 0.1), "PE_WoodLight")
    b.box((0.6, 0.5, z0 + 0.95), (0.85, 0.08, 0.06), "PE_WoodDark")
    for x in (-0.9, -0.5):
        basket(b, x, -0.7, z0, "PE_Gold" if x < -0.7 else "PE_StoneGrey")
    cs.rock_pile(b, 0.9, -0.8, z0, mat="PE_StoneGrey", n=4, s=0.2)


def mine_saracens(b, z0):
    quarry(b, -0.2, 1.0, z0, 3.0, "PE_Sandstone")
    headframe(b, 1.0, 0.0, z0, h=1.5)
    for k, (x, y) in enumerate(((-0.3, -0.7), (0.15, -0.95))):
        b.box((x, y, z0 + 0.15), (0.45, 0.3, 0.3), "PE_Sandstone")
    basket(b, -1.1, -0.5, z0, "PE_Gold")
    donkey(b, -0.8, -0.9, z0)
    flag(b, "saracens", 1.45, -1.3, z0)


def mine_vikings(b, z0):
    b.box((-0.5, 0.5, z0 + 0.01), (1.6, 1.1, 0.02), "PE_Soil")                     # bog-iron pit
    b.box((-0.5, 0.5, z0 + 0.02), (1.2, 0.8, 0.02), "PE_Window")
    furnace(b, 0.9, 0.6, z0, h=1.1)
    cs.rock_pile(b, 0.9, -0.6, z0, mat="PE_Iron", n=4, s=0.18)                      # slag heaps
    cs.rock_pile(b, -0.9, -0.8, z0, mat="PE_Soil", n=3, s=0.16)
    basket(b, 0.0, -0.6, z0, "PE_Soil")
    flag(b, "vikings", -1.45, -1.3, z0)


def mine_chinese(b, z0):
    adit(b, -0.3, 0.8, z0)
    for x in (-1.1, -0.6):                                                         # baskets on a carrying pole
        basket(b, x, -0.6, z0, "PE_Gold")
    b.cylinder_between((-1.2, -0.6, z0 + 0.45), (-0.5, -0.6, z0 + 0.45), 0.02, "PE_WoodLight", segs=4)
    b.box((0.9, -0.6, z0 + 0.1), (0.6, 0.4, 0.2), "PE_StoneGrey")                  # trip-hammer ore crusher
    b.cylinder_between((0.4, -0.6, z0 + 0.6), (1.1, -0.6, z0 + 0.35), 0.04, "PE_WoodDark", segs=4)
    b.box((1.05, -0.6, z0 + 0.3), (0.14, 0.14, 0.2), "PE_WoodLight")
    b.box((0.55, -0.6, z0 + 0.3), (0.06, 0.06, 0.6), "PE_WoodDark")
    cs.rock_pile(b, 1.2, 0.3, z0, mat="PE_StoneGrey", n=3, s=0.18)
    flag(b, "chinese", -1.45, -1.3, z0)


SMITHS = {c: globals()["smith_" + c] for c in ("ottomans", "byzantines", "britons", "franks", "teutons", "japanese",
                                               "saracens", "vikings", "chinese")}
LUMBER = {c: globals()["lumber_" + c] for c in SMITHS}
MINES = {c: globals()["mine_" + c] for c in SMITHS}
