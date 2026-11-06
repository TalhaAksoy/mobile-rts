"""Civ barracks (3x3 grid, pad +-2.7 m), one per civ from docs/art/culture/<civ>.md (barracks) and the 2D layouts
(art_source/aseprite/landmarks), instead of one hall + tower + training yard with civ materials.
The Ottoman janissary oda (buildings/ottomans_barracks.py) and the Mongol ger camp (bldtypes) are unchanged.
Budget: the barracks were 780-1190 triangles; keep each under ~1200.
Coordinates: Blender Z up, front (camera side) = -Y, z0 = ground-pad top.
"""
import parts
import civstyle as cs


def _arcade(b, x0, x1, y, z, n, w, h, pointed=False, frame=None):
    step = (x1 - x0) / n
    for i in range(n):
        b.arch_opening((x0 + step * (i + 0.5), y, z), (0, -1, 0), w, h, "PE_Window", frame, depth=0.06, frame=0.07,
                       segs=4, pointed=pointed)


def _windows(b, x0, x1, y, z, n, w, h, pointed=False, lattice=False):
    step = (x1 - x0) / n
    for i in range(n):
        x = x0 + step * (i + 0.5)
        if lattice:
            b.box((x, y - 0.015, z + h / 2), (w, 0.03, h), "PE_Lattice")
        else:
            b.arch_opening((x, y, z), (0, -1, 0), w, h, "PE_Window", None, depth=0.03, frame=0.05, segs=3, pointed=pointed)


def _yard(b, civ, z0, tip="PE_Iron", dummies=True):
    cs.weapon_rack(b, 1.7, -1.5, z0, n=5, tip=tip)
    if dummies:
        cs.dummy(b, -1.6, -1.6, z0, mat="PE_Thatch")
        cs.dummy(b, -0.9, -2.0, z0, mat="PE_Thatch")


def byzantines(b, z0):
    """Long two-storey block banded in brick and stone, an arcade of round arches below, a red-tile hip roof."""
    W, w, d, h = "PE_StoneWarm", 4.6, 1.9, 2.6
    cy = 1.2
    b.box((0, cy, z0 + h / 2), (w, d, h), W)
    for zz in (0.9, 1.35, 2.2):
        b.box((0, cy, z0 + zz), (w + 0.03, d + 0.03, 0.09), "PE_StoneBrick")
    fy = cy - d / 2
    _arcade(b, -w / 2 + 0.2, w / 2 - 0.2, fy, z0, 5, 0.55, 1.05, frame="PE_StoneBrick")
    _windows(b, -w / 2 + 0.2, w / 2 - 0.2, fy, z0 + 1.55, 5, 0.22, 0.45)
    b.box((0, fy - 0.015, z0 + 2.45), (w * 0.4, 0.03, 0.1), "TEAM_Trim")
    b.hip_roof((0, cy, z0 + h), w, d, 0.75, "PE_RoofRed", overhang=0.2)
    for x in (-1.4, 1.4):
        b.banner((x, fy, z0 + h - 0.1), (0, -1, 0), 0.3, 0.7, "byzantines")
    _yard(b, "byzantines", z0)
    for k in range(3):                                                   # shield rack
        parts.round_shield(b, (0.3 + k * 0.38, -1.2, z0 + 0.5), (0, -1, 0), r=0.16, mat="PE_ClothRed")
    b.box((0.68, -1.15, z0 + 0.5), (1.2, 0.06, 0.08), "PE_WoodDark")
    cs.flagpole(b, "byzantines", -2.3, -2.2, z0, h=2.4)


def britons(b, z0):
    """Stone-footed oak-framed hall with daub panels and braces, a slate roof, a weapon rack, St George pennon."""
    w, d, h = 4.4, 2.0, 1.6
    cy = 1.15
    b.box((0, cy, z0 + 0.3), (w + 0.08, d + 0.08, 0.6), "PE_StoneGrey")
    b.box((0, cy, z0 + 0.6 + h / 2), (w, d, h), "PE_PlasterWhite")
    fy = cy - d / 2
    for i in range(8):                                                   # posts
        b.box((-w / 2 + i * w / 7, fy - 0.015, z0 + 0.6 + h / 2), (0.09, 0.03, h), "PE_Beam")
    b.box((0, fy - 0.015, z0 + 0.6 + h - 0.05), (w + 0.04, 0.03, 0.1), "PE_Beam")
    b.box((0, fy - 0.015, z0 + 0.65), (w + 0.04, 0.03, 0.1), "PE_Beam")
    for i in range(7):                                                   # down-braces
        x = -w / 2 + (i + 0.5) * w / 7
        b.cylinder_between((x - 0.25, fy - 0.02, z0 + 0.65), (x + 0.25, fy - 0.02, z0 + 0.6 + h - 0.1), 0.035, "PE_Beam", segs=4)
    b.arch_opening((-0.2, fy, z0 + 0.6), (0, -1, 0), 0.6, 1.0, "PE_WoodDark", "PE_StoneGrey", depth=0.05, frame=0.08, segs=4)
    b.box((-0.2, fy - 0.02, z0 + 0.6 + h - 0.25), (0.8, 0.03, 0.1), "TEAM_Trim")
    b.gable_roof((0, cy, z0 + 0.6 + h), w, d, 1.15, "PE_RoofSlate", overhang=0.22, ridge_axis="x", end_mat="PE_PlasterWhite")
    b.gable_end((0, cy, z0 + 0.6 + h), w, d, 1.15, "PE_PlasterWhite", ridge_axis="x")
    _yard(b, "britons", z0)
    cs.hay(b, -2.2, -0.6, z0)
    parts.pennant(b, (1.3, -0.6, z0), h=2.6, length=0.55, mat="PE_ClothRed")
    b.box((1.3, -0.6, z0 + 0.3), (0.12, 0.12, 0.1), "TEAM_Trim")


def franks(b, z0):
    """Tall limestone hall with stepped buttresses, pointed lancets and a steep slate roof, fleur-de-lis banner."""
    W, w, d, h = "PE_StoneWarm", 4.2, 2.0, 2.4
    cy = 1.2
    b.box((0, cy, z0 + h / 2), (w, d, h), W)
    fy = cy - d / 2
    for x in (-w / 2, -1.05, 1.05, w / 2):                                # buttresses (two steps)
        b.box((x, fy - 0.18, z0 + 0.9), (0.26, 0.36, 1.8), W)
        b.box((x, fy - 0.1, z0 + 1.95), (0.22, 0.2, 0.7), W)
    _windows(b, -1.0, 1.0, fy, z0 + 1.0, 2, 0.24, 0.95, pointed=True)
    for x in (-1.6, 1.6):
        b.arch_opening((x, fy, z0 + 1.0), (0, -1, 0), 0.24, 0.95, "PE_Window", None, depth=0.03, frame=0.05, segs=3, pointed=True)
    b.arch_opening((0, fy, z0), (0, -1, 0), 0.6, 1.15, "PE_WoodDark", "PE_StoneGrey", depth=0.06, frame=0.08, segs=4, pointed=True)
    b.box((0, fy - 0.02, z0 + 2.15), (1.0, 0.03, 0.1), "TEAM_Trim")
    b.gable_roof((0, cy, z0 + h), w, d, 1.7, "PE_RoofSlate", overhang=0.15, ridge_axis="x", end_mat=W)
    b.gable_end((0, cy, z0 + h), w, d, 1.7, W, ridge_axis="x")
    b.banner((0, fy - 0.02, z0 + h - 0.05), (0, -1, 0), 0.32, 0.7, "franks")
    _yard(b, "franks", z0)
    cs.flagpole(b, "franks", -2.3, -2.2, z0, h=2.6)


def teutons(b, z0):
    """Long Brick Gothic dormitory hall under a red tile roof, a row of small lancets, a gate house with a stepped
    gable and the cross."""
    W, w, d, h = "PE_BrickRed", 4.8, 1.8, 1.9
    cy = 1.3
    b.box((0, cy, z0 + h / 2), (w, d, h), W)
    fy = cy - d / 2
    _windows(b, -w / 2 + 0.2, w / 2 - 0.2, fy, z0 + 0.8, 7, 0.16, 0.6, pointed=True)
    b.gable_roof((0, cy, z0 + h), w, d, 1.25, "PE_RoofRed", overhang=0.12, ridge_axis="x", end_mat=W)
    b.gable_end((0, cy, z0 + h), w, d, 1.25, W, ridge_axis="x")
    gx, gw, gd, gh = 0.0, 1.3, 0.7, 2.5                                  # gate house
    b.box((gx, fy - gd / 2, z0 + gh / 2), (gw, gd, gh), W)
    b.gable_roof((gx, fy - gd / 2, z0 + gh), gw, gd + 0.2, 1.0, "PE_RoofRed", overhang=0.08, ridge_axis="y", end_mat=W)
    cs._stepped_gables(b, gx, fy - gd / 2, z0 + gh, gw, gd + 0.2, 1.0, "y", W, steps=4)
    b.arch_opening((gx, fy - gd, z0), (0, -1, 0), 0.6, 1.1, "PE_WoodDark", "PE_StoneGrey", depth=0.06, frame=0.08, segs=4, pointed=True)
    b.box((gx, fy - gd - 0.02, z0 + 1.75), (0.1, 0.03, 0.45), "PE_PlasterWhite")      # the cross
    b.box((gx, fy - gd - 0.02, z0 + 1.85), (0.36, 0.03, 0.1), "PE_PlasterWhite")
    b.box((gx, fy - gd - 0.02, z0 + 2.3), (0.9, 0.03, 0.1), "TEAM_Trim")
    _yard(b, "teutons", z0)
    parts.barrel(b, (-2.2, -0.5, z0))
    cs.flagpole(b, "teutons", 2.3, -2.2, z0, h=2.4)


def japanese(b, z0):
    """Nagaya: long low timber row house under a dark tile roof, yari racks and nobori banners in the yard."""
    w, d, h = 5.0, 1.6, 1.25
    cy = 1.5
    b.box((0, cy, z0 + 0.12), (w + 0.1, d + 0.1, 0.24), "PE_StoneGrey")
    b.box((0, cy, z0 + 0.24 + h / 2), (w, d, h), "PE_PlasterWhite")
    fy = cy - d / 2
    for i in range(9):
        b.box((-w / 2 + i * w / 8, fy - 0.02, z0 + 0.24 + h / 2), (0.08, 0.04, h), "PE_WoodDark")
    b.box((0, fy - 0.02, z0 + 0.24 + 0.35), (w, 0.04, 0.7), "PE_WoodDark")           # board skirting
    for i in range(4):
        x = -1.9 + i * 1.25
        b.box((x, fy - 0.03, z0 + 0.24 + 0.85), (0.5, 0.03, 0.35), "PE_Lattice")
    b.box((0, fy - 0.03, z0 + 0.24 + h - 0.1), (1.2, 0.03, 0.08), "TEAM_Trim")
    b.hip_roof((0, cy, z0 + 0.24 + h), w, d, 0.75, "PE_RoofDark", overhang=0.35, curve=0.1)
    for x in (-2.2, -1.1, 1.1, 2.2):                                     # nobori: tall narrow banners on poles
        b.cylinder((x, -1.6, z0), 0.025, 2.2, "PE_WoodDark", segs=4, cap=False)
        b.box((x + 0.13, -1.6, z0 + 1.55), (0.24, 0.02, 1.1), "PE_Banner_japanese")
        b.box((x + 0.13, -1.6, z0 + 2.12), (0.28, 0.03, 0.03), "PE_WoodDark")
    cs.weapon_rack(b, 0.0, -0.4, z0, n=6, tip="PE_Iron")
    cs.dummy(b, 1.6, -0.5, z0, mat="PE_Thatch")


def saracens(b, z0):
    """Tibaq: a tall plain sandstone block of three storeys, small windows, a pointed arcade at the base, flat roof
    with stepped merlons, the yellow sultanic banner."""
    W, w, d, h = "PE_Sandstone", 4.2, 2.0, 3.4
    cy = 1.3
    b.box((0, cy, z0 + h / 2), (w, d, h), W)
    fy = cy - d / 2
    _arcade(b, -w / 2 + 0.2, w / 2 - 0.2, fy, z0, 4, 0.62, 1.05, pointed=True, frame="PE_TileTeal")
    for row in range(2):
        _windows(b, -w / 2 + 0.2, w / 2 - 0.2, fy, z0 + 1.45 + row * 0.9, 6, 0.16, 0.36, pointed=True)
    b.box((0, fy - 0.015, z0 + 1.3), (w, 0.03, 0.08), "PE_TileTeal")
    b.box((0, fy - 0.02, z0 + h - 0.25), (1.2, 0.03, 0.1), "TEAM_Trim")
    from castles import wall
    wall(b, (-w / 2, fy + 0.07), (w / 2, fy + 0.07), z0 + h, 0.0, 0.14, W, stepped=True)
    b.flag((-2.3, -1.6, z0), 2.8, "saracens", size=(0.6, 0.45))
    b.box((-2.3, -1.6, z0 + 0.3), (0.12, 0.12, 0.1), "TEAM_Trim")
    _yard(b, "saracens", z0, tip="PE_Gold", dummies=False)
    parts.barrel(b, (-1.2, -1.4, z0), r=0.18, h=0.5)


def vikings(b, z0):
    """Trelleborg hall: long plank hall with bowed walls, sloping outer posts propping the eaves, a shingle roof,
    round shields hung along the wall."""
    w, d, h = 4.8, 2.0, 1.25
    cy = 1.3
    # bowed plan: three boxes, the middle one wider
    b.box((0, cy, z0 + h / 2), (w * 0.5, d + 0.2, h), "PE_WoodDark")
    for sx in (-1, 1):
        b.box((sx * w * 0.375, cy, z0 + h / 2), (w * 0.25, d, h), "PE_WoodDark")
    fy = cy - (d + 0.2) / 2
    for i in range(10):
        b.box((-w * 0.25 + i * w * 0.05, fy - 0.015, z0 + h / 2), (0.04, 0.03, h), "PE_WoodLight")
    b.gable_roof((0, cy, z0 + h), w, d + 0.2, 1.5, "PE_Shingle", overhang=0.3, ridge_axis="x", end_mat="PE_WoodDark")
    b.gable_end((0, cy, z0 + h), w, d + 0.2, 1.5, "PE_WoodDark", ridge_axis="x")
    for i in range(6):                                                   # sloping outer posts
        x = -w / 2 + 0.3 + i * (w - 0.6) / 5
        b.cylinder_between((x, fy - 0.7, z0), (x, fy - 0.12, z0 + h - 0.05), 0.06, "PE_WoodDark", segs=4)
    for i in range(4):                                                   # shields on the wall
        parts.round_shield(b, (-1.5 + i * 1.0, fy - 0.03, z0 + 0.75), (0, -1, 0), r=0.2)
    b.box((0, fy - 0.03, z0 + 0.4), (0.7, 0.04, 0.8), "PE_WoodLight")    # door
    _yard(b, "vikings", z0)
    cs.flagpole(b, "vikings", -2.3, -2.2, z0, h=2.4)


def chinese(b, z0):
    """Long timber hall with red-lacquered columns under a grey tile roof with up-swept eaves, halberd racks,
    red character banners and a war drum on its stand."""
    w, d, h = 4.6, 1.8, 1.6
    cy = 1.3
    b.box((0, cy, z0 + 0.15), (w + 0.4, d + 0.4, 0.3), "PE_StoneGrey")          # platform
    b.box((0, cy + 0.1, z0 + 0.3 + h / 2), (w - 0.2, d - 0.2, h), "PE_PlasterWhite")
    fy = cy - d / 2
    for i in range(7):
        b.box((-w / 2 + 0.1 + i * (w - 0.2) / 6, fy, z0 + 0.3 + h / 2), (0.12, 0.12, h), "PE_LacquerRed")
    for i in range(3):
        b.box((-1.4 + i * 1.4, fy + 0.1, z0 + 0.3 + h * 0.55), (0.9, 0.03, h * 0.6), "PE_Lattice")
    b.box((0, fy + 0.08, z0 + 0.3 + h - 0.1), (1.0, 0.03, 0.08), "TEAM_Trim")
    b.hip_roof((0, cy, z0 + 0.3 + h), w, d, 0.75, "PE_RoofDark", overhang=0.4, curve=0.16, under_mat="PE_LacquerRed")
    for x in (-2.3, 2.3):                                                # red banners on poles
        b.cylinder((x, -1.5, z0), 0.03, 2.3, "PE_WoodDark", segs=4, cap=False)
        b.box((x + 0.2, -1.5, z0 + 1.75), (0.38, 0.02, 0.9), "PE_ClothRed")
    cs.weapon_rack(b, -1.0, -0.6, z0, n=5, tip="PE_Iron")
    for sx in (-1, 1):                                                   # drum stand
        b.cylinder_between((0.9 + sx * 0.35, -1.0, z0), (0.9 + sx * 0.18, -1.0, z0 + 0.9), 0.04, "PE_WoodDark", segs=4)
    b.cylinder_between((0.9, -1.12, z0 + 0.85), (0.9, -0.88, z0 + 0.85), 0.32, "PE_LacquerRed", segs=10, cap=True)


BUILDERS = {"byzantines": byzantines, "britons": britons, "franks": franks, "teutons": teutons,
            "japanese": japanese, "saracens": saracens, "vikings": vikings, "chinese": chinese}
