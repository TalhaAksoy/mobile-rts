"""Ottoman Town Center (3x3 grid -> 5.4 m footprint).

Reference: art/buildings/ottomans/town_center.png (gallery row 1, col 1).
Identity taken from the reference: dark slate-lead main dome on a windowed drum, cascading
half-domes, four tall pencil minarets with conical caps and gold alems, cream plaster over warm
stone masonry, pointed-arch monumental portal (pishtaq), red crescent banners, red-tile
porticos, cypress greenery on a paved forecourt.
Interpretation notes: the reference only shows a front-left 3/4 view. The back is mirrored
from the front massing without the portal, and the outer courtyard wall of the illustration
became two red-tiled porticos (revak) so the 5.4 m footprint stays readable from the RTS camera.
"""
import math
import pe_kit, parts
from pe_kit import Builder

CIV = "ottomans"
ASSET = "town_center"


def portico(b, x_inner, x_outer, y0, y1, z0, h, n_arches, facing_x):
    """Arcade along Y with a red barrel-tile lean-to roof sloping away from the hall."""
    depth = abs(x_outer - x_inner)
    xc = (x_inner + x_outer) / 2
    b.box((xc, (y0 + y1) / 2, z0 + 0.06), (depth, y1 - y0, 0.12), "PE_StoneWarm")
    # arcade front wall with arches
    wall_t = 0.14
    xf = x_outer - facing_x * wall_t / 2
    b.box((xf, (y0 + y1) / 2, z0 + h / 2), (wall_t, y1 - y0, h), "PE_PlasterCream")
    step = (y1 - y0) / n_arches
    for i in range(n_arches):
        yc = y0 + step * (i + 0.5)
        b.arch_opening((x_outer, yc, z0 + 0.12), (facing_x, 0, 0), step * 0.62, h * 0.72, "PE_Window",
                       "PE_StoneWarm", depth=0.03, frame=0.06, pointed=True, segs=4)
    # end walls
    for yy in (y0, y1):
        b.box((xc, yy, z0 + h / 2), (depth, 0.14, h), "PE_PlasterCream")
    # roof: hip roof, red barrel tiles
    b.hip_roof((xc, (y0 + y1) / 2, z0 + h), depth, y1 - y0, 0.42, "PE_RoofRed", overhang=0.12)


def build():
    pe_kit.reset_scene()
    b = Builder("ottomans_town_center")
    HALF = 2.7
    pe_kit.ground_pad(b, HALF, HALF, seed=11)

    # Paved forecourt + stone plinth of the hall
    b.box((0, 0.0, 0.08 + 0.05), (4.75, 4.85, 0.1), "PE_StoneGrey")
    z_court = 0.18
    T = 0.22
    HW, HD, HH = 1.45, 1.35, 1.7
    yc = 0.3
    b.box((0, yc, z_court + T / 2), (HW * 2 + 0.5, HD * 2 + 0.4, T), "PE_StoneWarm")
    b.stairs((0, yc - HD - 0.2, z_court), 1.1, 2, T / 2, 0.16, "PE_StoneWarm")
    z0 = z_court + T

    # Main prayer-hall block
    b.box((0, yc, z0 + HH / 2), (HW * 2, HD * 2, HH), "PE_PlasterCream")
    b.box((0, yc, z0 + 0.1), (HW * 2 + 0.06, HD * 2 + 0.06, 0.2), "PE_StoneWarm")
    b.box((0, yc, z0 + HH + 0.06), (HW * 2 + 0.16, HD * 2 + 0.16, 0.12), "PE_StoneWarm")
    top = z0 + HH + 0.12
    front_y = yc - HD
    for x in (-1.1, 1.1):
        b.arch_opening((x, front_y, z0 + 0.42), (0, -1, 0), 0.32, 0.62, "PE_Window", "PE_StoneWarm", pointed=True)
        b.arch_opening((x, front_y, z0 + 1.22), (0, -1, 0), 0.2, 0.3, "PE_Window", "PE_StoneWarm", pointed=True, segs=4)
    for side in (-1, 1):
        for yy in (-0.75, 0.0, 0.75):
            b.arch_opening((side * HW, yc + yy, z0 + 1.0), (side, 0, 0), 0.24, 0.42, "PE_Window", "PE_StoneWarm", pointed=True, segs=4)
    for x in (-0.8, 0.0, 0.8):
        b.arch_opening((x, yc + HD, z0 + 0.42), (0, 1, 0), 0.34, 0.66, "PE_Window", "PE_StoneWarm", pointed=True)

    # Pishtaq: monumental portal projecting from the front facade
    PW, PD, PH = 1.3, 0.3, 2.15
    py = front_y - PD / 2
    b.box((0, py, z0 + PH / 2), (PW, PD, PH), "PE_StoneWarm")
    b.arch_opening((0, front_y - PD, z0), (0, -1, 0), 0.8, 1.5, "PE_Window", "PE_PlasterCream", depth=0.05, frame=0.09, pointed=True)
    b.box((0, front_y - PD - 0.012, z0 + PH - 0.24), (PW - 0.24, 0.03, 0.1), "TEAM_Trim")
    parts.crenellations(b, -PW / 2 + 0.03, PW / 2 - 0.03, py, z0 + PH, depth=PD, merlon_w=0.13, gap=0.09, h=0.13)
    for x in (-0.8, 0.8):
        b.banner((x, front_y, z0 + HH - 0.1), (0, -1, 0), 0.24, 0.62, CIV)

    # Roof: corner turrets with small domes, cascading half domes, drum and main dome
    for sx in (-1, 1):
        for sy in (-1, 1):
            cx, cy = sx * (HW - 0.22), yc + sy * (HD - 0.22)
            b.cylinder((cx, cy, top), 0.22, 0.3, "PE_PlasterCream", segs=10, cap=False)
            b.cylinder((cx, cy, top + 0.3), 0.25, 0.05, "PE_StoneWarm", segs=10)
            b.dome((cx, cy, top + 0.35), 0.23, "PE_DomeLead", segs=10, rings=3)
            b.cylinder((cx, cy, top + 0.57), 0.018, 0.13, "PE_Gold", segs=4)
    for sy in (-1, 1):
        b.dome((0, yc + sy * 0.88, top), 0.6, "PE_DomeLead", segs=14, rings=4, height=0.48)
    for sx in (-1, 1):
        b.dome((sx * 0.9, yc, top), 0.45, "PE_DomeLead", segs=12, rings=3, height=0.36)
    DR, DH = 0.98, 0.46
    b.cylinder((0, yc, top), DR + 0.06, 0.1, "PE_StoneWarm", segs=16)
    b.cylinder((0, yc, top + 0.1), DR, DH, "PE_PlasterCream", segs=16, smooth=False)
    for i in range(16):
        a = 2 * math.pi * (i + 0.5) / 16
        nx, ny = math.cos(a), math.sin(a)
        b.arch_opening((nx * DR * 0.99, yc + ny * DR * 0.99, top + 0.16), (nx, ny, 0), 0.15, 0.28, "PE_Window", None, segs=3)
    b.cylinder((0, yc, top + 0.1 + DH), DR + 0.05, 0.06, "PE_StoneWarm", segs=16)
    dome_base = top + 0.16 + DH
    b.dome((0, yc, dome_base), DR + 0.02, "PE_DomeLead", segs=20, rings=7, height=1.08)
    tip = dome_base + 1.08
    b.cylinder((0, yc, tip - 0.02), 0.05, 0.1, "PE_Gold", segs=6)
    b.dome((0, yc, tip + 0.08), 0.07, "PE_Gold", segs=6, rings=2)
    b.cylinder((0, yc, tip + 0.13), 0.018, 0.3, "PE_Gold", segs=4)
    b.cylinder_between((-0.07, yc, tip + 0.42), (0.07, yc, tip + 0.42), 0.035, "PE_Gold", segs=5)

    # Red-tile porticos either side
    for sx in (-1, 1):
        portico(b, sx * (HW + 0.25), sx * 2.3, yc - 1.15, yc + 1.25, z_court, 1.0, 4, sx)

    # Four pencil minarets at the forecourt corners
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.ottoman_minaret(b, (sx * 2.18, 0.05 + sy * 2.08, z_court), height=5.0 if sy > 0 else 4.7,
                                  shaft_r=0.14)

    # Greenery, props and flag
    parts.cypress(b, (-1.35, -2.25, z_court), height=1.25, r=0.22)
    parts.cypress(b, (1.4, -2.25, z_court), height=1.15, r=0.2)
    parts.round_tree(b, (-2.25, 1.75, 0.08), height=1.2, r=0.38)
    parts.cypress(b, (2.45, 1.2, 0.08), height=1.4, r=0.22)
    b.flag((1.2, -0.6, top), 2.0, CIV, size=(0.72, 0.48))
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [3, 3], "footprint_m": 5.4,
                                                                    "reference": "res://art/buildings/ottomans/town_center.png"})
    return ob, pe_kit.mesh_stats(ob)
