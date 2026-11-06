"""Civ watch towers (2x2 grid, pad +-1.8 m), one per civ from docs/art/culture/<civ>.md (watch_tower) and the
2D layouts, instead of the shared civ tower on a plinth. The Mongol felt lookout stays in bldtypes.
Budget: the towers were 250-510 triangles; keep each under ~550.
Coordinates: Blender Z up, front (camera side) = -Y, z0 = ground-pad top.
"""
import math
import parts
import civstyle as cs
from castles import wall, ring_merlons


def _door(b, y, z, w=0.42, h=0.75, pointed=False):
    b.arch_opening((0, y, z), (0, -1, 0), w, h, "PE_Window", "PE_WoodDark", depth=0.06, frame=0.06, segs=4,
                   pointed=pointed)


def _crenels(b, x, y, z, s, mat, stepped=False):
    r = s / 2
    for sy in (-1, 1):
        wall(b, (x - r, y + sy * (r - 0.06)), (x + r, y + sy * (r - 0.06)), z, 0.0, 0.12, mat, merlon=0.2, gap=0.18,
             stepped=stepped)
    for sx in (-1, 1):
        wall(b, (x + sx * (r - 0.06), y - r + 0.12), (x + sx * (r - 0.06), y + r - 0.12), z, 0.0, 0.12, mat,
             merlon=0.2, gap=0.18, stepped=stepped)


def ottomans(b, z0):
    """Square ashlar tower with brick bands, a timber gallery cantilevered on top, a lead hip cap."""
    s, h, W = 1.4, 3.3, "PE_StoneWarm"
    b.box((0, 0.1, z0 + h / 2), (s, s, h), W)
    for zz in (1.1, 2.2):
        b.box((0, 0.1, z0 + zz), (s + 0.03, s + 0.03, 0.08), "PE_StoneBrick")
    _door(b, 0.1 - s / 2, z0, pointed=True)
    b.arch_opening((0, 0.1 - s / 2, z0 + 1.6), (0, -1, 0), 0.22, 0.4, "PE_Window", None, segs=3, pointed=True)
    b.box((0, 0.1, z0 + h + 0.35), (s + 0.4, s + 0.4, 0.7), "PE_WoodDark")             # gallery
    for i in range(4):
        b.box((-0.6 + i * 0.4, 0.1 - s / 2 - 0.21, z0 + h + 0.4), (0.2, 0.03, 0.35), "PE_Window")
    for sx in (-1, 1):                                                                 # brackets
        b.box((sx * (s / 2 + 0.1), 0.1 - s / 2 - 0.1, z0 + h - 0.15), (0.07, 0.2, 0.3), "PE_WoodDark")
    b.box((0, 0.1 - s / 2 - 0.215, z0 + h + 0.08), (s * 0.7, 0.03, 0.1), "TEAM_Trim")
    b.hip_roof((0, 0.1, z0 + h + 0.7), s + 0.4, s + 0.4, 0.7, "PE_DomeLead", overhang=0.15, ridge_frac=0.05)
    b.cylinder((0, 0.1, z0 + h + 1.35), 0.02, 0.28, "PE_Gold", segs=4)
    return z0 + h + 1.4


def byzantines(b, z0):
    """Square tower banded in brick, crenellated top, a beacon brazier burning on the roof."""
    s, h, W = 1.45, 3.4, "PE_StoneWarm"
    b.box((0, 0.1, z0 + h / 2), (s, s, h), W)
    for zz in (0.9, 1.8, 2.7):
        b.box((0, 0.1, z0 + zz), (s + 0.03, s + 0.03, 0.1), "PE_StoneBrick")
    _door(b, 0.1 - s / 2, z0)
    b.arch_opening((0, 0.1 - s / 2, z0 + 2.0), (0, -1, 0), 0.24, 0.42, "PE_Window", None, segs=3)
    b.box((0, 0.1 - s / 2 - 0.015, z0 + h - 0.35), (s * 0.7, 0.03, 0.1), "TEAM_Trim")
    _crenels(b, 0, 0.1, z0 + h, s, W)
    b.cylinder((0, 0.1, z0 + h), 0.05, 0.4, "PE_Iron", segs=4, cap=False)               # brazier on a post
    b.cylinder((0, 0.1, z0 + h + 0.4), 0.18, 0.14, "PE_Iron", segs=6, r_top=0.26)
    b.cone((0, 0.1, z0 + h + 0.52), 0.2, 0.42, "PE_ClothRed", segs=5, smooth=False)       # flames
    b.cone((0.05, 0.12, z0 + h + 0.55), 0.11, 0.3, "PE_Gold", segs=4, smooth=False)
    return z0 + h + 1.0


def britons(b, z0):
    """Square grey-stone tower, its crenels hidden under a timber hoarding (brattice) with a shingle pent roof."""
    s, h, W = 1.45, 3.0, "PE_StoneGrey"
    b.box((0, 0.1, z0 + h / 2), (s, s, h), W)
    _door(b, 0.1 - s / 2, z0)
    b.arch_opening((0, 0.1 - s / 2, z0 + 1.7), (0, -1, 0), 0.12, 0.42, "PE_Window", None, segs=3)
    b.box((0, 0.1, z0 + h + 0.3), (s + 0.36, s + 0.36, 0.6), "PE_WoodDark")             # hoarding
    for i in range(5):
        b.box((-0.66 + i * 0.33, 0.1 - s / 2 - 0.185, z0 + h + 0.3), (0.05, 0.03, 0.6), "PE_WoodLight")
    b.box((0, 0.1 - s / 2 - 0.19, z0 + h + 0.48), (s * 0.6, 0.03, 0.1), "TEAM_Trim")
    b.pyramid_roof((0, 0.1, z0 + h + 0.6), s + 0.36, s + 0.36, 0.7, "PE_Shingle", overhang=0.1)
    return z0 + h + 1.3


def franks(b, z0):
    """Slim round limestone tower under a steep slate pepper-pot cone, with a pennon."""
    r, h = 0.62, 3.6
    parts.round_tower(b, (0, 0.1, z0), r, h, wall_mat="PE_StoneWarm", roof_mat="PE_RoofSlate", cap_h=1.8,
                      team_band=True)
    _door(b, 0.1 - r * 0.97, z0, w=0.36, h=0.7, pointed=True)
    parts.pennant(b, (0, 0.1, z0 + h + 1.75), h=0.7, length=0.4)
    return z0 + h + 2.4


def teutons(b, z0):
    """Square Brick Gothic tower under a steep tile gable facing the street, stepped gable ends."""
    s, h, W = 1.4, 3.2, "PE_BrickRed"
    b.box((0, 0.1, z0 + h / 2), (s, s, h), W)
    _door(b, 0.1 - s / 2, z0, pointed=True)
    for x in (-0.3, 0.3):
        b.arch_opening((x, 0.1 - s / 2, z0 + 2.0), (0, -1, 0), 0.16, 0.5, "PE_Window", None, segs=3, pointed=True)
    b.box((0, 0.1 - s / 2 - 0.015, z0 + 1.5), (s * 0.7, 0.03, 0.1), "TEAM_Trim")
    rh = 1.4
    b.gable_roof((0, 0.1, z0 + h), s, s, rh, "PE_RoofRed", overhang=0.08, ridge_axis="y", end_mat=W)
    cs._stepped_gables(b, 0, 0.1, z0 + h, s, s, rh, "y", W, steps=4)
    return z0 + h + rh


def japanese(b, z0):
    """Open timber yagura on four braced posts: a small boarded lookout with a tiled roof and a war drum."""
    hp, s = 2.6, 1.3
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.box((sx * s / 2, 0.1 + sy * s / 2, z0 + hp / 2), (0.12, 0.12, hp), "PE_WoodDark")
    for sx in (-1, 1):                                                                 # X braces on the sides
        b.cylinder_between((sx * s / 2, 0.1 - s / 2, z0 + 0.2), (sx * s / 2, 0.1 + s / 2, z0 + hp - 0.4), 0.035,
                           "PE_WoodLight", segs=4)
        b.cylinder_between((sx * s / 2, 0.1 + s / 2, z0 + 0.2), (sx * s / 2, 0.1 - s / 2, z0 + hp - 0.4), 0.035,
                           "PE_WoodLight", segs=4)
    b.cylinder_between((-s / 2, 0.1 - s / 2, z0 + 0.2), (s / 2, 0.1 - s / 2, z0 + hp - 0.4), 0.035, "PE_WoodLight", segs=4)
    b.box((0, 0.1, z0 + hp), (s + 0.3, s + 0.3, 0.1), "PE_WoodDark")                    # platform
    b.box((0, 0.1, z0 + hp + 0.4), (s + 0.1, s + 0.1, 0.7), "PE_PlasterWhite")           # lookout room
    b.box((0, 0.1 - (s + 0.1) / 2 - 0.01, z0 + hp + 0.45), (s * 0.7, 0.03, 0.3), "PE_Lattice")
    b.box((0, 0.1 - (s + 0.1) / 2 - 0.02, z0 + hp + 0.15), (s * 0.8, 0.03, 0.08), "TEAM_Trim")
    b.hip_roof((0, 0.1, z0 + hp + 0.75), s + 0.1, s + 0.1, 0.5, "PE_RoofDark", overhang=0.3, curve=0.12)
    b.cylinder_between((0.2, 0.1 - 0.25, z0 + hp + 0.25), (0.2, 0.1 - 0.45, z0 + hp + 0.25), 0.16, "PE_LacquerRed",
                       segs=8, cap=True)                                               # taiko drum on the rail
    b.cylinder_between((-0.4, 0.1 - s / 2 - 0.3, z0), (-0.25, 0.1 - s / 2, z0 + hp), 0.03, "PE_WoodLight", segs=4)
    return z0 + hp + 1.25


def chinese(b, z0):
    """Square brick-faced tower with crenels and a small lacquered pavilion under a curved teal roof."""
    s, h, W = 1.5, 2.6, "PE_StoneGrey"
    b.frustum((0, 0.1, z0), s + 0.2, s + 0.2, s, s, h, W)
    _door(b, 0.1 - s / 2 - 0.05, z0)
    b.box((0, 0.1 - s / 2 - 0.02, z0 + 1.7), (s * 0.6, 0.03, 0.1), "TEAM_Trim")
    _crenels(b, 0, 0.1, z0 + h, s, W)
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.box((sx * 0.4, 0.1 + sy * 0.4, z0 + h + 0.35), (0.08, 0.08, 0.7), "PE_LacquerRed")
    b.box((0, 0.1 + 0.4, z0 + h + 0.35), (0.8, 0.05, 0.7), "PE_Lattice")
    b.hip_roof((0, 0.1, z0 + h + 0.7), 0.95, 0.95, 0.45, "PE_RoofTeal", overhang=0.3, curve=0.18,
               under_mat="PE_LacquerRed")
    b.cone((0, 0.1, z0 + h + 1.15), 0.06, 0.2, "PE_Gold", segs=5, smooth=False)
    return z0 + h + 1.35


def saracens(b, z0):
    """Square sandstone tower with stepped crenellations and a flag on top."""
    s, h, W = 1.45, 3.4, "PE_Sandstone"
    b.frustum((0, 0.1, z0), s + 0.3, s + 0.3, s, s, 0.7, W)
    b.box((0, 0.1, z0 + h / 2), (s, s, h), W)
    b.box((0, 0.1, z0 + h - 0.3), (s + 0.03, s + 0.03, 0.09), "PE_TileTeal")
    _door(b, 0.1 - s / 2, z0, pointed=True)
    b.arch_opening((0, 0.1 - s / 2, z0 + 2.0), (0, -1, 0), 0.2, 0.42, "PE_Window", None, segs=3, pointed=True)
    b.box((0, 0.1 - s / 2 - 0.015, z0 + 1.4), (s * 0.6, 0.03, 0.1), "TEAM_Trim")
    _crenels(b, 0, 0.1, z0 + h, s, W, stepped=True)
    cs.flagpole(b, "saracens", 0.3, 0.3, z0 + h, h=1.4, size=(0.45, 0.3))
    return z0 + h + 1.4


def vikings(b, z0):
    """Timber platform tower with a ladder and a horn: four posts, a plank parapet, a shingle hood."""
    s, hp = 1.3, 2.4
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.box((sx * s / 2, 0.1 + sy * s / 2, z0 + (hp + 0.8) / 2), (0.14, 0.14, hp + 0.8), "PE_WoodDark")
    for zz in (0.8, 1.6):
        b.box((0, 0.1, z0 + zz), (s, s, 0.06), "PE_WoodLight")
    b.box((0, 0.1, z0 + hp), (s + 0.2, s + 0.2, 0.1), "PE_WoodDark")
    b.box((0, 0.1 - s / 2 - 0.1, z0 + hp + 0.3), (s + 0.2, 0.06, 0.5), "PE_WoodLight")
    for sx in (-1, 1):
        b.box((sx * (s / 2 + 0.1), 0.1, z0 + hp + 0.3), (0.06, s + 0.2, 0.5), "PE_WoodLight")
    parts.round_shield(b, (0, 0.1 - s / 2 - 0.14, z0 + hp + 0.3), (0, -1, 0), r=0.17)
    b.pyramid_roof((0, 0.1, z0 + hp + 0.8), s + 0.2, s + 0.2, 0.6, "PE_Shingle", overhang=0.1)
    for sx in (-1, 1):                                                                  # ladder
        b.cylinder_between((0.25 + sx * 0.15, 0.1 - s / 2 - 0.5, z0), (0.25 + sx * 0.15, 0.1 - s / 2 - 0.05, z0 + hp),
                           0.03, "PE_WoodLight", segs=4)
    for k in range(5):
        t = (k + 1) / 6
        b.box((0.25, 0.1 - s / 2 - 0.5 + 0.45 * t, z0 + hp * t), (0.32, 0.04, 0.04), "PE_WoodLight")
    b.cone((-0.4, 0.1 - s / 2 - 0.2, z0 + hp + 0.55), 0.07, 0.35, "PE_Felt", segs=5, smooth=False)   # horn
    return z0 + hp + 1.4


BUILDERS = {"ottomans": ottomans, "byzantines": byzantines, "britons": britons, "franks": franks,
            "teutons": teutons, "japanese": japanese, "chinese": chinese, "saracens": saracens, "vikings": vikings}
