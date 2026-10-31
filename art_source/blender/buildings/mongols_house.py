"""Mongols House (2x2 grid -> 3.6 m footprint).

Reference: art/buildings/mongols/house.png (white felt ger with banners).
Civ reading: a family ger: white felt wall and roof, dark rope bands, blue felt skirt, a
toono crown with a stove pipe, a painted (lacquer-red) door, a felt-covered ox cart, and a
hitching line. No stone, no tile (ART_DIRECTION_BIBLE §6). Team: band round the wall + pennant.
"""
import math
import pe_kit, parts
from pe_kit import Builder

CIV = "mongols"
ASSET = "house"


def build():
    pe_kit.reset_scene()
    b = Builder("mongols_house")
    pe_kit.ground_pad(b, 1.8, 1.8, seed=41)
    z0 = 0.08
    gx, gy = -0.1, 0.3
    R, WH = 1.15, 0.85
    b.cylinder((gx, gy, z0), R + 0.03, 0.14, "PE_FeltBlue", segs=14, cap=False, smooth=False)
    b.cylinder((gx, gy, z0 + 0.14), R, WH - 0.14, "PE_Felt", segs=14, cap=False, smooth=False)
    b.cylinder((gx, gy, z0 + 0.5), R + 0.015, 0.1, "TEAM_Trim", segs=14, cap=False, smooth=False)
    b.dome((gx, gy, z0 + WH), R + 0.06, "PE_Felt", segs=14, rings=3, height=0.62, smooth=False, top_hole=0.24)
    # rope bands over the roof (radial) + wall girth rope
    for i in range(7):
        a = i / 7 * math.tau + 0.2
        p0 = (gx + math.cos(a) * (R + 0.07), gy + math.sin(a) * (R + 0.07), z0 + WH + 0.01)
        p1 = (gx + math.cos(a) * 0.3, gy + math.sin(a) * 0.3, z0 + WH + 0.58)
        b.cylinder_between(p0, p1, 0.02, "PE_WoodDark", segs=4, smooth=False)
    b.cylinder((gx, gy, z0 + 0.3), R + 0.012, 0.04, "PE_WoodDark", segs=14, cap=False, smooth=False)
    # toono crown + stove pipe
    b.cylinder((gx, gy, z0 + WH + 0.56), 0.3, 0.07, "PE_WoodDark", segs=10, smooth=False)
    b.cylinder((gx + 0.12, gy + 0.08, z0 + WH + 0.5), 0.05, 0.55, "PE_Iron", segs=6, smooth=False)
    # painted door in a short felt porch, facing the camera
    dy = gy - R
    b.box((gx, dy - 0.08, z0 + 0.36), (0.5, 0.2, 0.72), "PE_Felt")
    b.box((gx, dy - 0.19, z0 + 0.32), (0.34, 0.03, 0.6), "PE_LacquerRed")
    b.box((gx, dy - 0.2, z0 + 0.66), (0.42, 0.04, 0.06), "PE_WoodDark")
    # felt-covered ox cart (front-right)
    cx, cy = 1.15, -0.95
    b.box((cx, cy, z0 + 0.42), (0.95, 0.6, 0.06), "PE_WoodDark")
    b.dome((cx, cy, z0 + 0.45), 0.36, "PE_Felt", segs=8, rings=2, height=0.38, smooth=False)
    for sy in (-1, 1):
        b.cylinder_between((cx + 0.05, cy + sy * 0.33, z0 + 0.27), (cx + 0.05, cy + sy * 0.38, z0 + 0.27), 0.27, "PE_WoodDark", segs=8, smooth=False, cap=True)
    b.cylinder_between((cx - 0.48, cy, z0 + 0.42), (cx - 1.0, cy, z0 + 0.1), 0.03, "PE_WoodDark", segs=4, smooth=False)
    # hitching line with a pennant post
    for x in (-1.5, -0.8):
        parts.timber_post(b, (x, -1.35, z0), 0.6, s=0.06)
    b.cylinder_between((-1.5, -1.35, z0 + 0.55), (-0.8, -1.35, z0 + 0.55), 0.015, "PE_WoodDark", segs=4, smooth=False)
    parts.pennant(b, (-1.5, -1.35, z0), h=1.55, length=0.42, tip="PE_Gold")
    # dung/firewood stack behind
    parts.log_pile(b, (1.2, 1.1, z0), length=0.55, rows=2, r=0.08, axis="y")
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                                    "reference": "res://art/buildings/%s/house.png" % CIV})
    return ob, pe_kit.mesh_stats(ob)
