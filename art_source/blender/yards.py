"""Civ archery ranges and stables (3x3 grid, pad +-2.7 m), one per civ from docs/art/culture/<civ>.md
(archery_range, stable) and the 2D layouts, instead of the shared hall + shed / hall + paddock with civ materials.
Every range keeps straw butts and every stable keeps horses, a trough and hay, so the type still reads at a glance.
The Mongol steppe range and horse line stay in bldtypes.
Budget: ranges were 1080-1330 and stables 900-1180 triangles; keep each under ~1200.
Coordinates: Blender Z up, front (camera side) = -Y, z0 = ground-pad top.
"""
import math
import parts
import civstyle as cs
from castles import wall


# ---------------------------------------------------------------- shared pieces
def _shed(b, c, w, d, h, roof_mat, wall_mat="PE_WoodDark", post="PE_WoodDark", pent=True, curve=0.0,
          under="PE_WoodDark", bays=3, back=True):
    """Open-fronted shed: posts in front, back wall, a pent (lean-to) or hip roof."""
    cx, cy, z = c
    for i in range(bays + 1):
        parts.timber_post(b, (cx - w / 2 + i * w / bays, cy - d / 2, z), h, s=0.09, mat=post)
    if back:
        b.box((cx, cy + d / 2, z + h / 2), (w, 0.08, h), wall_mat)
    b.box((cx, cy - d / 2, z + h - 0.05), (w + 0.1, 0.1, 0.1), post)
    if pent:
        q = [(cx - w / 2 - 0.15, cy - d / 2 - 0.2, z + h), (cx + w / 2 + 0.15, cy - d / 2 - 0.2, z + h),
             (cx + w / 2 + 0.15, cy + d / 2 + 0.1, z + h + 0.45), (cx - w / 2 - 0.15, cy + d / 2 + 0.1, z + h + 0.45)]
        b.quad(*q, roof_mat)
        b.quad(q[1], q[0], q[3], q[2], under)
        b.box((cx, cy - d / 2 - 0.2, z + h - 0.04), (w * 0.4, 0.03, 0.08), "TEAM_Trim")
        return z + h + 0.45
    b.hip_roof((cx, cy, z + h), w, d, 0.5, roof_mat, overhang=0.25, curve=curve, under_mat=under)
    b.box((cx, cy - d / 2 - 0.02, z + h - 0.15), (w * 0.4, 0.03, 0.08), "TEAM_Trim")
    return z + h + 0.5


def _butts(b, xs, y, z0, r=0.36):
    for i, x in enumerate(xs):
        cs.target(b, x, y + (i % 2) * 0.25, z0, r=r)


def _paddock(b, civ, z0, coats=("PE_WoodDark", "PE_Beam"), fence=True):
    if fence:
        cs.fence(b, civ, -2.45, 0.9, -2.35, z0)
    cs.horse(b, -1.5, -1.0, z0, facing=1, coat=coats[0])
    cs.horse(b, -0.2, -1.65, z0, facing=-1, coat=coats[1])
    b.box((1.3, -1.6, z0 + 0.18), (0.8, 0.26, 0.2), "PE_WoodDark")             # trough
    b.box((1.3, -1.6, z0 + 0.27), (0.7, 0.18, 0.03), "PE_Window")
    cs.hay(b, 1.9, -0.9, z0)
    cs.hay(b, 2.2, -1.4, z0)


def _stall_doors(b, x0, x1, fy, z0, n, w=0.5, h=0.75, arch=None, frame="PE_StoneGrey", pointed=False):
    for i in range(n):
        x = x0 + (i + 0.5) * (x1 - x0) / n
        if arch:
            b.arch_opening((x, fy, z0), (0, -1, 0), w, h, "PE_WoodDark", frame, depth=0.05, frame=0.07, segs=4,
                           pointed=pointed)
        else:
            b.box((x, fy - 0.03, z0 + h / 2), (w, 0.05, h), "PE_WoodDark")
            b.box((x, fy - 0.05, z0 + h / 2), (w + 0.02, 0.03, 0.06), "PE_WoodLight")


# ---------------------------------------------------------------- archery ranges
def range_ottomans(b, z0):
    """Open walled yard with white marble nisan tasi marker pillars, straw targets and a small tiled shelter."""
    wall(b, (-2.6, 2.4), (2.6, 2.4), z0, 0.9, 0.3, "PE_StoneWarm", cren=False)
    _shed(b, (-1.5, 1.6, z0), 1.8, 1.1, 1.3, "PE_RoofRed", wall_mat="PE_StoneWarm", pent=False, bays=2)
    for i, x in enumerate((0.2, 0.9, 1.6, 2.3)):                                # nisan tasi: slim pillars, ball top
        b.cylinder((x, 1.2 - i * 0.25, z0), 0.09, 1.1 + i * 0.1, "PE_PlasterWhite", segs=6, smooth=False)
        b.dome((x, 1.2 - i * 0.25, z0 + 1.1 + i * 0.1), 0.11, "PE_PlasterWhite", segs=6, rings=2, smooth=False)
    _butts(b, (-1.6, -0.5, 0.6), -1.4, z0)
    parts.cypress(b, (-2.4, -0.6, z0), height=1.6)
    cs.flagpole(b, "ottomans", 2.3, -2.2, z0, h=2.2)


def range_byzantines(b, z0):
    """Walled courtyard with straw butts and a covered round-arched arcade at the back."""
    W = "PE_StoneWarm"
    b.box((0, 1.9, z0 + 0.8), (5.0, 1.0, 1.6), W)
    for zz in (0.55, 1.1):
        b.box((0, 1.9, z0 + zz), (5.03, 1.03, 0.08), "PE_StoneBrick")
    for i in range(5):
        b.arch_opening((-2.0 + i, 1.4, z0), (0, -1, 0), 0.6, 1.0, "PE_Window", "PE_StoneBrick", depth=0.06, frame=0.07, segs=4)
    b.gable_roof((0, 1.9, z0 + 1.6), 5.0, 1.0, 0.45, "PE_RoofRed", overhang=0.15, ridge_axis="x", end_mat=W)
    b.box((0, 1.39, z0 + 1.4), (1.6, 0.03, 0.1), "TEAM_Trim")
    _butts(b, (-1.8, -0.6, 0.6, 1.8), 0.3, z0)
    wall(b, (-2.6, -2.3), (-0.7, -2.3), z0, 0.7, 0.3, W, cren=False)
    wall(b, (0.7, -2.3), (2.6, -2.3), z0, 0.7, 0.3, W, cren=False)
    cs.weapon_rack(b, -2.0, -1.4, z0, n=4)
    cs.flagpole(b, "byzantines", 2.3, -1.6, z0, h=2.4)


def range_britons(b, z0):
    """Meadow with turf-mound butts and round straw targets, a bow rack and a thatched timber shelter."""
    _shed(b, (-1.7, 1.7, z0), 1.8, 1.2, 1.2, "PE_Thatch", bays=2)
    for i, x in enumerate((-0.2, 1.0, 2.1)):                                    # turf mounds behind the targets
        b.dome((x, 1.4 + (i % 2) * 0.2, z0), 0.6, "PE_Grass", segs=8, rings=2, height=0.55, smooth=False)
        cs.target(b, x, 0.9 + (i % 2) * 0.2, z0, r=0.34)
    _butts(b, (-2.0, -1.0), -0.6, z0)
    cs.weapon_rack(b, 1.3, -1.6, z0, n=5, tip="PE_WoodLight")
    cs.fence(b, "britons", -2.5, 2.5, -2.4, z0)
    cs.flagpole(b, "britons", -2.3, -2.0, z0, h=2.2)


def range_franks(b, z0):
    """Timber shed with a slate pentice roof, a row of straw butts and a crossbow rack."""
    _shed(b, (-1.3, 1.5, z0), 2.6, 1.3, 1.4, "PE_RoofSlate", bays=3)
    _butts(b, (0.9, 1.7, 2.4), 1.3, z0)
    _butts(b, (-2.0, -0.9), -0.5, z0)
    cs.weapon_rack(b, 1.2, -1.4, z0, n=4)
    parts.barrel(b, (2.2, -1.2, z0))
    cs.fence(b, "franks", -2.5, 2.5, -2.4, z0)
    cs.flagpole(b, "franks", -2.3, -2.0, z0, h=2.4)


def range_teutons(b, z0):
    """Brick-walled yard with a timber shooting shed under a tile pent roof and crossbow targets."""
    W = "PE_BrickRed"
    wall(b, (-2.6, 2.4), (2.6, 2.4), z0, 1.3, 0.35, W)
    for sx in (-1, 1):
        wall(b, (sx * 2.6, 2.4), (sx * 2.6, -0.4), z0, 1.0, 0.3, W)
    _shed(b, (-1.4, 1.1, z0), 2.0, 1.2, 1.4, "PE_RoofRed", bays=2)
    _butts(b, (0.5, 1.4, 2.1), 1.5, z0)
    wall(b, (-2.6, -2.3), (-0.7, -2.3), z0, 0.8, 0.3, W, cren=False)
    wall(b, (0.7, -2.3), (2.6, -2.3), z0, 0.8, 0.3, W, cren=False)
    cs.weapon_rack(b, 1.5, -1.3, z0, n=4)
    cs.flagpole(b, "teutons", -2.0, -1.5, z0, h=2.4)


def range_japanese(b, z0):
    """Kyudo-jo: the covered shooting shed (iba) in front, round mato targets set in an earth bank (azuchi) under
    a small roof at the back."""
    b.frustum((0, 2.0, z0), 5.0, 1.0, 4.8, 0.5, 0.8, "PE_Dirt")                  # azuchi bank
    b.gable_roof((0, 2.15, z0 + 1.2), 5.0, 0.7, 0.3, "PE_RoofDark", overhang=0.1, ridge_axis="x")
    for x in (-2.3, 2.3):
        b.box((x, 2.15, z0 + 0.6), (0.08, 0.08, 1.2), "PE_WoodDark")
    for x in (-1.5, -0.5, 0.5, 1.5):                                             # mato: white disc, black rings
        b.cylinder_between((x, 1.62, z0 + 0.5), (x, 1.58, z0 + 0.5), 0.2, "PE_PlasterWhite", segs=10, cap=True)
        b.cylinder_between((x, 1.57, z0 + 0.5), (x, 1.56, z0 + 0.5), 0.13, "PE_RoofDark", segs=10, cap=True)
        b.cylinder_between((x, 1.555, z0 + 0.5), (x, 1.55, z0 + 0.5), 0.07, "PE_PlasterWhite", segs=8, cap=True)
    _shed(b, (0, -1.4, z0), 4.6, 1.3, 1.5, "PE_RoofDark", post="PE_WoodDark", pent=False, curve=0.1, bays=4, back=False)
    b.box((0, -1.4, z0 + 0.06), (4.6, 1.3, 0.12), "PE_WoodLight")                  # board floor
    for x in (-2.4, 2.4):
        b.cylinder((x, 0.3, z0), 0.025, 2.0, "PE_WoodDark", segs=4, cap=False)
        b.box((x + 0.12, 0.3, z0 + 1.45), (0.22, 0.02, 0.9), "PE_Banner_japanese")


def range_saracens(b, z0):
    """Open maydan: a tall target pole topped by the gourd (qabaq), straw butts, a cloth-shaded stone bench."""
    b.cylinder((0.6, 1.0, z0), 0.06, 3.2, "PE_WoodLight", segs=5, cap=False)
    b.dome((0.6, 1.0, z0 + 3.15), 0.18, "PE_Gold", segs=8, rings=3, height=0.3, smooth=False)
    b.cylinder((0.6, 1.0, z0 + 3.4), 0.015, 0.2, "PE_Gold", segs=4)
    for k in range(4):                                                            # guy ropes
        a = k * 1.5708 + 0.6
        b.cylinder_between((0.6, 1.0, z0 + 2.8), (0.6 + 0.9 * math.cos(a), 1.0 + 0.9 * math.sin(a), z0),
                           0.012, "PE_WoodDark", segs=3)
    _butts(b, (-1.9, -0.8, 1.9), -0.3, z0)
    b.box((-1.6, 1.8, z0 + 0.25), (1.6, 0.5, 0.5), "PE_Sandstone")                 # stone bench
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.cylinder((-1.6 + sx * 0.85, 1.8 + sy * 0.4, z0), 0.04, 1.6, "PE_WoodDark", segs=4, cap=False)
    b.quad((-2.55, 1.3, z0 + 1.55), (-0.65, 1.3, z0 + 1.55), (-0.65, 2.3, z0 + 1.7), (-2.55, 2.3, z0 + 1.7), "PE_ClothRed")
    b.quad((-0.65, 1.3, z0 + 1.55), (-2.55, 1.3, z0 + 1.55), (-2.55, 2.3, z0 + 1.7), (-0.65, 2.3, z0 + 1.7), "PE_ClothRed")
    b.box((-1.6, 1.29, z0 + 1.48), (1.9, 0.03, 0.12), "TEAM_Trim")
    b.flag((2.3, -2.0, z0), 2.6, "saracens", size=(0.55, 0.4))
    b.box((2.3, -2.0, z0 + 0.3), (0.12, 0.12, 0.1), "TEAM_Trim")


def range_vikings(b, z0):
    """Cleared yard: straw and hide targets on posts, a turf-roofed lean-to, a rune stone."""
    _shed(b, (-1.6, 1.6, z0), 2.0, 1.2, 1.2, "PE_Grass", bays=2)
    for i, x in enumerate((0.3, 1.2, 2.1)):
        y = 1.4 + (i % 2) * 0.3
        cs.target(b, x, y, z0, r=0.33)
        b.quad((x - 0.32, y + 0.35, z0 + 1.35), (x + 0.32, y + 0.35, z0 + 1.35), (x + 0.32, y + 0.35, z0 + 1.95),
               (x - 0.32, y + 0.35, z0 + 1.95), "PE_Felt")                         # hide stretched on a frame
        for sx in (-1, 1):
            b.cylinder((x + sx * 0.34, y + 0.36, z0), 0.035, 2.0, "PE_WoodDark", segs=4, cap=False)
    _butts(b, (-1.9, -0.9), -0.6, z0)
    b.box((1.7, -1.5, z0 + 0.5), (0.4, 0.2, 1.0), "PE_StoneGrey")                  # rune stone
    cs.weapon_rack(b, 0.4, -1.6, z0, n=4)
    cs.flagpole(b, "vikings", -2.3, -2.0, z0, h=2.2)


def range_chinese(b, z0):
    """Walled yard with ringed straw targets and a covered viewing pavilion in lacquered red under a teal roof."""
    W = "PE_StoneGrey"
    b.box((0, 2.4, z0 + 0.65), (5.2, 0.35, 1.3), W)
    b.gable_roof((0, 2.4, z0 + 1.3), 5.2, 0.35, 0.2, "PE_RoofDark", overhang=0.12, ridge_axis="x")
    _butts(b, (-1.8, -0.6, 0.6), 1.5, z0)
    px, py = 1.6, -0.6                                                             # viewing pavilion
    b.box((px, py, z0 + 0.12), (1.7, 1.5, 0.24), W)
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.box((px + sx * 0.7, py + sy * 0.6, z0 + 0.24 + 0.6), (0.1, 0.1, 1.2), "PE_LacquerRed")
    b.box((px, py - 0.62, z0 + 1.3), (0.8, 0.03, 0.09), "TEAM_Trim")
    b.hip_roof((px, py, z0 + 1.44), 1.5, 1.3, 0.55, "PE_RoofTeal", overhang=0.3, curve=0.18, under_mat="PE_LacquerRed")
    b.cone((px, py, z0 + 2.0), 0.06, 0.2, "PE_Gold", segs=5, smooth=False)
    cs.weapon_rack(b, -1.4, -1.4, z0, n=4)
    b.cylinder((-2.4, -2.1, z0), 0.03, 2.3, "PE_WoodDark", segs=4, cap=False)
    b.box((-2.2, -2.1, z0 + 1.75), (0.38, 0.02, 0.9), "PE_ClothRed")


# ---------------------------------------------------------------- stables
def stable_ottomans(b, z0):
    """Long stone-and-brick stable under a red tile hip roof, round-arched doorways, hay and a trough."""
    w, d, h, cy = 4.6, 1.6, 1.3, 1.35
    b.box((0, cy, z0 + h / 2), (w, d, h), "PE_StoneWarm")
    b.box((0, cy, z0 + 0.95), (w + 0.03, d + 0.03, 0.08), "PE_StoneBrick")
    fy = cy - d / 2
    _stall_doors(b, -w / 2, w / 2, fy, z0, 4, w=0.55, h=0.85, arch=True, frame="PE_StoneBrick")
    b.box((0, fy - 0.02, z0 + h - 0.15), (1.4, 0.03, 0.08), "TEAM_Trim")
    b.hip_roof((0, cy, z0 + h), w, d, 0.7, "PE_RoofRed", overhang=0.2)
    _paddock(b, "ottomans", z0, coats=("PE_PlasterWhite", "PE_WoodDark"))
    parts.cypress(b, (-2.4, 0.2, z0), height=1.5)
    cs.flagpole(b, "ottomans", 2.3, -2.2, z0, h=2.2)


def stable_byzantines(b, z0):
    """Long single-storey banded brick stable, round-arched doors, tiled gable roof, water trough."""
    w, d, h, cy = 4.6, 1.6, 1.2, 1.35
    b.box((0, cy, z0 + h / 2), (w, d, h), "PE_StoneBrick")
    fy = cy - d / 2
    _stall_doors(b, -w / 2, w / 2, fy, z0, 5, w=0.5, h=0.8, arch=True, frame="PE_StoneWarm")
    b.box((0, fy - 0.02, z0 + h - 0.12), (1.4, 0.03, 0.08), "TEAM_Trim")
    b.gable_roof((0, cy, z0 + h), w, d, 0.55, "PE_RoofRed", overhang=0.15, ridge_axis="x", end_mat="PE_StoneBrick")
    b.gable_end((0, cy, z0 + h), w, d, 0.55, "PE_StoneBrick", ridge_axis="x")
    _paddock(b, "byzantines", z0)
    cs.flagpole(b, "byzantines", 2.3, -2.2, z0, h=2.2)


def stable_britons(b, z0):
    """Timber-framed stable under a deep thatch roof, a stone trough."""
    w, d, h, cy = 4.4, 1.6, 1.1, 1.35
    b.box((0, cy, z0 + h / 2), (w, d, h), "PE_PlasterWhite")
    fy = cy - d / 2
    for i in range(7):
        b.box((-w / 2 + i * w / 6, fy - 0.015, z0 + h / 2), (0.08, 0.03, h), "PE_Beam")
    b.box((0, fy - 0.015, z0 + h - 0.05), (w + 0.04, 0.03, 0.09), "PE_Beam")
    _stall_doors(b, -w / 2, w / 2, fy, z0, 4, w=0.55, h=0.75)
    b.gable_roof((0, cy, z0 + h), w, d, 1.0, "PE_Thatch", overhang=0.3, ridge_axis="x", end_mat="PE_PlasterWhite")
    b.gable_end((0, cy, z0 + h), w, d, 1.0, "PE_PlasterWhite", ridge_axis="x")
    b.box((0, fy - 0.02, z0 + h - 0.2), (1.2, 0.03, 0.08), "TEAM_Trim")
    _paddock(b, "britons", z0)
    b.box((1.3, -1.6, z0 + 0.18), (0.82, 0.28, 0.22), "PE_StoneGrey")           # stone trough over the wooden one
    cs.flagpole(b, "britons", 2.3, -2.2, z0, h=2.2)


def stable_franks(b, z0):
    """Long half-timbered stable on a low stone plinth, a gabled hay-loft door, a horse trough, steep slate roof."""
    w, d, h, cy = 4.6, 1.6, 1.3, 1.35
    b.box((0, cy, z0 + 0.2), (w + 0.06, d + 0.06, 0.4), "PE_StoneWarm")
    b.box((0, cy, z0 + 0.4 + h / 2), (w, d, h), "PE_PlasterCream")
    fy = cy - d / 2
    for i in range(8):
        b.box((-w / 2 + i * w / 7, fy - 0.015, z0 + 0.4 + h / 2), (0.08, 0.03, h), "PE_Beam")
    _stall_doors(b, -w / 2, w / 2, fy, z0 + 0.0, 4, w=0.55, h=0.95)
    b.hip_roof((0, cy, z0 + 0.4 + h), w, d, 1.2, "PE_RoofSlate", overhang=0.15)
    b.box((0, fy + 0.05, z0 + 0.4 + h + 0.35), (0.6, 0.4, 0.7), "PE_WoodDark")    # loft dormer
    b.gable_roof((0, fy + 0.05, z0 + 0.4 + h + 0.7), 0.7, 0.5, 0.35, "PE_RoofSlate", overhang=0.06, ridge_axis="y")
    b.box((0, fy - 0.16, z0 + 0.4 + h + 0.35), (0.35, 0.03, 0.45), "PE_WoodLight")
    b.box((0, fy - 0.02, z0 + 0.4 + h - 0.15), (1.4, 0.03, 0.08), "TEAM_Trim")
    _paddock(b, "franks", z0)
    cs.flagpole(b, "franks", 2.3, -2.2, z0, h=2.4)


def stable_teutons(b, z0):
    """Brick ground floor with a half-timbered hay loft above and a red tile roof."""
    w, d, cy = 4.6, 1.6, 1.35
    b.box((0, cy, z0 + 0.6), (w, d, 1.2), "PE_BrickRed")
    fy = cy - d / 2
    _stall_doors(b, -w / 2, w / 2, fy, z0, 4, w=0.5, h=0.85, arch=True, frame="PE_BrickRed", pointed=True)
    b.box((0, cy, z0 + 1.2 + 0.4), (w + 0.1, d + 0.1, 0.8), "PE_PlasterWhite")
    for i in range(9):
        b.box((-w / 2 + i * w / 8, fy - 0.07, z0 + 1.6), (0.08, 0.03, 0.8), "PE_Beam")
    b.box((0, fy - 0.07, z0 + 1.24), (w + 0.1, 0.03, 0.08), "PE_Beam")
    b.box((0, fy - 0.08, z0 + 1.6), (0.4, 0.03, 0.4), "PE_WoodDark")             # loft hatch
    b.box((0, fy - 0.08, z0 + 1.1), (1.4, 0.03, 0.08), "TEAM_Trim")
    b.gable_roof((0, cy, z0 + 2.0), w + 0.1, d + 0.1, 1.1, "PE_RoofRed", overhang=0.12, ridge_axis="x", end_mat="PE_BrickRed")
    b.gable_end((0, cy, z0 + 2.0), w + 0.1, d + 0.1, 1.1, "PE_BrickRed", ridge_axis="x")
    _paddock(b, "teutons", z0)
    cs.flagpole(b, "teutons", 2.3, -2.2, z0, h=2.4)


def stable_japanese(b, z0):
    """Umaya: an open-fronted timber stable under a thick thatched roof, horses tethered in the stalls."""
    w, d, h, cy = 4.8, 1.8, 1.4, 1.2
    _shed(b, (0, cy, z0), w, d, h, "PE_Thatch", pent=False, bays=4)
    for i in range(3):                                                            # stall partitions + horses
        x = -1.8 + i * 1.8
        b.box((x + 0.9, cy, z0 + 0.45), (0.06, d * 0.9, 0.9), "PE_WoodLight")
        cs.horse(b, x + 0.1, cy - 0.1, z0, facing=1 if i % 2 else -1, coat="PE_WoodDark" if i != 1 else "PE_PlasterWhite")
    b.box((1.3, -0.8, z0 + 0.18), (0.8, 0.26, 0.2), "PE_WoodDark")
    cs.hay(b, -1.9, -0.8, z0)
    cs.horse(b, -0.6, -1.0, z0, facing=1, coat="PE_Beam")                         # tethered in front
    b.box((0.2, -1.0, z0 + 0.45), (0.1, 0.1, 0.9), "PE_WoodDark")
    b.box((2.2, -1.6, z0 + 0.35), (0.22, 0.22, 0.7), "PE_StoneGrey")               # stone lantern
    b.box((2.2, -1.6, z0 + 0.8), (0.34, 0.34, 0.12), "PE_StoneGrey")
    b.cylinder((-2.3, -1.6, z0), 0.025, 2.0, "PE_WoodDark", segs=4, cap=False)
    b.box((-2.18, -1.6, z0 + 1.45), (0.22, 0.02, 0.9), "PE_Banner_japanese")


def stable_saracens(b, z0):
    """Istabl: long sandstone stable with pointed-arch doors under a flat roof, hay, a water trough, a palm."""
    w, d, h, cy = 4.6, 1.6, 1.4, 1.35
    b.box((0, cy, z0 + h / 2), (w, d, h), "PE_Sandstone")
    b.box((0, cy, z0 + h + 0.04), (w + 0.06, d + 0.06, 0.08), "PE_Sandstone")
    fy = cy - d / 2
    _stall_doors(b, -w / 2, w / 2, fy, z0, 4, w=0.55, h=0.9, arch=True, frame="PE_TileTeal", pointed=True)
    b.box((0, fy - 0.02, z0 + h - 0.15), (1.4, 0.03, 0.08), "TEAM_Trim")
    _paddock(b, "saracens", z0, coats=("PE_PlasterWhite", "PE_WoodLight"))
    b.flag((2.3, -2.2, z0), 2.4, "saracens", size=(0.5, 0.35))
    b.box((2.3, -2.2, z0 + 0.3), (0.12, 0.12, 0.1), "TEAM_Trim")


def stable_vikings(b, z0):
    """A low turf-roofed byre with wattle partitions, horses and a trough in front."""
    w, d, h, cy = 4.6, 1.8, 0.85, 1.3
    b.box((0, cy, z0 + h / 2), (w, d, h), "PE_StoneGrey")                         # turf-and-stone walls
    b.box((0, cy - d / 2 - 0.01, z0 + h / 2), (w, 0.02, h), "PE_WoodDark")
    fy = cy - d / 2
    for i in range(4):                                                            # wattle panels
        b.box((-1.8 + i * 1.2, fy - 0.04, z0 + 0.35), (0.9, 0.04, 0.55), "PE_Thatch")
    b.gable_roof((0, cy, z0 + h), w, d, 1.0, "PE_Grass", overhang=0.3, ridge_axis="x", end_mat="PE_WoodDark")
    b.gable_end((0, cy, z0 + h), w, d, 1.0, "PE_WoodDark", ridge_axis="x")
    b.box((0, fy - 0.05, z0 + h - 0.12), (1.2, 0.03, 0.08), "TEAM_Trim")
    _paddock(b, "vikings", z0)
    cs.flagpole(b, "vikings", 2.3, -2.2, z0, h=2.2)


def stable_chinese(b, z0):
    """Open-sided timber shed under a grey tile roof with up-swept eaves, troughs and a stone hitching post."""
    w, d, h, cy = 4.8, 1.8, 1.5, 1.2
    b.box((0, cy, z0 + 0.1), (w + 0.3, d + 0.3, 0.2), "PE_StoneGrey")
    _shed(b, (0, cy, z0 + 0.2), w, d, h, "PE_RoofDark", post="PE_LacquerRed", pent=False, curve=0.16,
          under="PE_LacquerRed", bays=4, back=False)
    for i in range(3):
        cs.horse(b, -1.6 + i * 1.6, cy, z0 + 0.2, facing=1 if i % 2 else -1, coat="PE_WoodDark" if i != 1 else "PE_Beam")
    for x in (-1.0, 1.0):
        b.box((x, -0.6, z0 + 0.18), (0.8, 0.26, 0.2), "PE_WoodDark")
        b.box((x, -0.6, z0 + 0.27), (0.7, 0.18, 0.03), "PE_Window")
    cs.horse(b, -1.4, -1.5, z0, facing=1, coat="PE_WoodDark")                     # tied at the hitching post
    cs.horse(b, 0.2, -1.6, z0, facing=-1, coat="PE_PlasterWhite")
    b.box((-2.2, -1.7, z0 + 0.45), (0.2, 0.2, 0.9), "PE_StoneGrey")                # hitching post
    b.box((-2.2, -1.7, z0 + 0.95), (0.3, 0.3, 0.1), "PE_StoneGrey")
    cs.hay(b, 2.1, -1.0, z0)
    b.cylinder((2.4, -2.1, z0), 0.03, 2.3, "PE_WoodDark", segs=4, cap=False)
    b.box((2.2, -2.1, z0 + 1.75), (0.38, 0.02, 0.9), "PE_ClothRed")


RANGES = {"ottomans": range_ottomans, "byzantines": range_byzantines, "britons": range_britons, "franks": range_franks,
          "teutons": range_teutons, "japanese": range_japanese, "saracens": range_saracens, "vikings": range_vikings,
          "chinese": range_chinese}
STABLES = {"ottomans": stable_ottomans, "byzantines": stable_byzantines, "britons": stable_britons,
           "franks": stable_franks, "teutons": stable_teutons, "japanese": stable_japanese,
           "saracens": stable_saracens, "vikings": stable_vikings, "chinese": stable_chinese}
