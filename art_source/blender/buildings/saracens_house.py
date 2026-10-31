"""Saracens House (2x2 grid -> 3.6 m footprint).

Reference: art/buildings/saracens/house.png (flat-roofed sandstone house, roof terrace, awnings).
Civ reading: flat-roofed sandstone courtyard house in two heights with parapets, a wind
catcher tower (badgir) as the silhouette marker, a projecting lattice window (mashrabiya),
a teal-tiled door frame, a cloth awning in team colour and water jars. No dome: that is
kept for the Saracen Town Center and Mill granary.
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "saracens"
ASSET = "house"


def parapet(b, cx, cy, w, d, z, h=0.16, t=0.08, mat="PE_Sandstone"):
    for sy in (-1, 1):
        b.box((cx, cy + sy * (d / 2 - t / 2), z + h / 2), (w, t, h), mat)
    for sx in (-1, 1):
        b.box((cx + sx * (w / 2 - t / 2), cy, z + h / 2), (t, d, h), mat)


def build():
    pe_kit.reset_scene()
    b = Builder("saracens_house")
    pe_kit.ground_pad(b, 1.8, 1.8, seed=37)
    z0 = 0.08
    # tall block (back-left)
    tx, ty = -0.35, 0.45
    TW, TD, TH = 1.9, 1.5, 1.9
    b.box((tx, ty, z0 + TH / 2), (TW, TD, TH), "PE_Sandstone")
    parapet(b, tx, ty, TW, TD, z0 + TH)
    tfy = ty - TD / 2
    # mashrabiya: projecting lattice box on the upper floor
    b.box((tx - 0.2, tfy - 0.12, z0 + 1.35), (0.6, 0.24, 0.55), "PE_Lattice")
    b.box((tx - 0.2, tfy - 0.12, z0 + 1.65), (0.68, 0.3, 0.06), "PE_WoodDark")
    b.box((tx - 0.2, tfy - 0.12, z0 + 1.05), (0.68, 0.3, 0.06), "PE_WoodDark")
    b.arch_opening((tx + 0.55, tfy, z0 + 1.15), (0, -1, 0), 0.22, 0.42, "PE_Window", None, depth=0.03, segs=4, pointed=True)
    b.arch_opening((tx - TW / 2, ty, z0 + 1.15), (-1, 0, 0), 0.22, 0.42, "PE_Window", None, depth=0.03, segs=4, pointed=True)
    # wind catcher (badgir) on the tall block
    bx, by = tx + 0.55, ty + 0.35
    b.box((bx, by, z0 + TH + 0.55), (0.5, 0.5, 1.1), "PE_Sandstone")
    for sx in (-1, 1):
        b.box((bx + sx * 0.12, by - 0.255, z0 + TH + 0.75), (0.1, 0.03, 0.5), "PE_WoodDark")
    b.box((bx, by, z0 + TH + 1.14), (0.58, 0.58, 0.08), "PE_TileTeal")
    # low block (front-right) with roof terrace
    lx, ly = 0.75, -0.45
    LW, LD, LH = 1.35, 1.35, 1.05
    b.box((lx, ly, z0 + LH / 2), (LW, LD, LH), "PE_Sandstone")
    parapet(b, lx, ly, LW, LD, z0 + LH)
    lfy = ly - LD / 2
    b.arch_opening((lx - 0.2, lfy, z0), (0, -1, 0), 0.42, 0.75, "PE_WoodDark", "PE_TileTeal", depth=0.04, frame=0.07, segs=4, pointed=True)
    b.arch_opening((lx + LW / 2, ly, z0 + 0.45), (1, 0, 0), 0.22, 0.36, "PE_Window", None, depth=0.03, segs=4, pointed=True)
    b.box((lx, lfy - 0.012, z0 + LH - 0.12), (LW, 0.03, 0.08), "PE_TileTeal")
    # team awning on poles over the terrace edge
    ax0, ax1 = lx - 0.45, lx + 0.5
    for x in (ax0, ax1):
        parts.timber_post(b, (x, ly - 0.25, z0 + LH), 0.6, s=0.05)
    b.quad((ax0, ly - 0.3, z0 + LH + 0.6), (ax1, ly - 0.3, z0 + LH + 0.6),
           (ax1, ly + 0.45, z0 + LH + 0.72), (ax0, ly + 0.45, z0 + LH + 0.72), "TEAM_Trim")
    b.quad((ax1, ly - 0.3, z0 + LH + 0.6), (ax0, ly - 0.3, z0 + LH + 0.6),
           (ax0, ly + 0.45, z0 + LH + 0.72), (ax1, ly + 0.45, z0 + LH + 0.72), "TEAM_Trim")
    # outside stair to the terrace (left of the low block)
    b.stairs((lx - LW / 2 - 0.2, ly + 0.1, z0), 0.36, 4, 0.25, 0.2, "PE_Sandstone")
    # water jars
    for (jx, jy) in ((-1.35, -0.9), (-1.1, -1.15), (-1.4, -1.3)):
        b.cylinder((jx, jy, z0), 0.08, 0.06, "PE_StoneBrick", segs=6, r_top=0.14, cap=False, smooth=False)
        b.cylinder((jx, jy, z0 + 0.06), 0.14, 0.24, "PE_StoneBrick", segs=6, r_top=0.07, smooth=False)
    parts.pennant(b, (tx - TW / 2 + 0.1, ty - TD / 2 + 0.1, z0 + TH), h=0.8, length=0.4)
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                                    "reference": "res://art/buildings/%s/house.png" % CIV})
    return ob, pe_kit.mesh_stats(ob)
