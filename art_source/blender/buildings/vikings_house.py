"""Vikings House (2x2 grid -> 3.6 m footprint).

Reference: art/buildings/vikings/house.png (timber house, steep roof).
Civ reading: a small longhouse: low plank walls on a stone footing, a steep shingle roof that comes
down close to the ground (turf was tried and read as grass ground on green maps), crossed carved gable boards ending in beast heads, a smoke
hole, round team shields on the wall, a drying rack and a wood pile. No stone castle forms.
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "vikings"
ASSET = "house"


def build():
    pe_kit.reset_scene()
    b = Builder("vikings_house")
    pe_kit.ground_pad(b, 1.8, 1.8, seed=53)
    z0 = 0.08
    cx, cy = 0.0, 0.35
    W, D, H = 2.6, 1.45, 0.75
    b.box((cx, cy, z0 + 0.1), (W + 0.08, D + 0.08, 0.2), "PE_StoneGrey")
    wz = z0 + 0.2
    b.box((cx, cy, wz + H / 2), (W, D, H), "PE_WoodDark")
    fy = cy - D / 2
    for i in range(9):                                     # vertical planks / stave posts
        x = -W / 2 + i * W / 8
        b.box((cx + x, fy - 0.015, wz + H / 2), (0.06, 0.03, H), "PE_WoodLight")
    # door in a small gabled porch on the long side
    b.box((cx + 0.3, fy - 0.2, wz + 0.4), (0.62, 0.4, 0.8), "PE_WoodDark")
    b.box((cx + 0.3, fy - 0.41, wz + 0.33), (0.32, 0.03, 0.62), "PE_Beam")
    b.gable_roof((cx + 0.3, fy - 0.2, wz + 0.8), 0.62, 0.4, 0.38, "PE_Shingle", overhang=0.08, ridge_axis="y", end_mat="PE_WoodDark")
    b.gable_end((cx + 0.3, fy - 0.2, wz + 0.8), 0.62, 0.4, 0.38, "PE_WoodDark", ridge_axis="y")
    # team shields along the wall
    for x in (-0.95, -0.45, 0.95):
        parts.round_shield(b, (cx + x, fy - 0.03, wz + 0.45), (0, -1, 0), r=0.16)
    # steep shingle roof, ridge along X
    rz = wz + H
    RH = 1.25
    b.gable_roof((cx, cy, rz), W, D, RH, "PE_Shingle", overhang=0.2, thick=0.18, ridge_axis="x", end_mat="PE_WoodDark")
    b.gable_end((cx, cy, rz), W, D, RH, "PE_WoodDark", ridge_axis="x")
    # crossed carved gable boards with beast heads at both ends + smoke hole
    for sx in (-1, 1):
        x = cx + sx * (W / 2 + 0.22)
        for sy in (-1, 1):   # barge boards along the gable edge, crossing above the ridge
            p0 = (x, cy + sy * 0.45, rz + RH * (1 - 0.45 / (D / 2)) + 0.05)
            p1 = (x, cy - sy * 0.2, rz + RH + 0.28)
            b.cylinder_between(p0, p1, 0.05, "PE_WoodDark", segs=4, smooth=False)
            b.box((x, cy - sy * 0.24, rz + RH + 0.33), (0.08, 0.18, 0.1), "PE_LacquerRed")
    b.box((cx - 0.45, cy, rz + RH + 0.02), (0.36, 0.3, 0.14), "PE_WoodDark")
    # drying rack (front-left) + wood pile (right) + pennant
    for x in (-1.5, -0.85):
        parts.timber_post(b, (x, -1.25, z0), 0.85, s=0.06)
    b.cylinder_between((-1.5, -1.25, z0 + 0.82), (-0.85, -1.25, z0 + 0.82), 0.025, "PE_WoodDark", segs=4)
    for k in range(4):
        b.box((-1.38 + k * 0.15, -1.25, z0 + 0.64), (0.05, 0.03, 0.3), "PE_Beam")
    parts.log_pile(b, (1.2, -1.1, z0), length=0.75, rows=3, r=0.08, axis="x")
    parts.pennant(b, (cx + W / 2 + 0.05, cy - D / 2 - 0.05, z0), h=1.7, length=0.42)
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                                    "reference": "res://art/buildings/%s/house.png" % CIV})
    return ob, pe_kit.mesh_stats(ob)
