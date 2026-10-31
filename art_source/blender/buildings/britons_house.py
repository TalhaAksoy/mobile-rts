"""Britons House (2x2 grid -> 3.6 m footprint).

Reference: art/buildings/britons/house.png (half-timbered cottage).
Civ reading: whitewashed wattle-and-daub cottage with a dark timber frame on a rubble-stone
plinth, a deep thatch roof (the Britons' mill shares the thatch, so the farmstead reads as one
culture), a stone chimney, wattle fence, log pile. Team: window shutters + gable pennant.
Must differ from Teutons (dark slate, stone gable) and Franks (blue slate, turret).
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "britons"
ASSET = "house"


def build():
    pe_kit.reset_scene()
    b = Builder("britons_house")
    pe_kit.ground_pad(b, 1.8, 1.8, seed=11)
    z0 = 0.08
    cx, cy = 0.05, 0.25
    W, D, H = 2.2, 1.5, 1.2
    b.box((cx, cy, z0 + 0.12), (W + 0.08, D + 0.08, 0.24), "PE_StoneGrey")
    wz = z0 + 0.24
    b.box((cx, cy, wz + H / 2), (W, D, H), "PE_PlasterWhite")
    fy = cy - D / 2
    # timber frame on the front + sides: posts, mid rail, braces
    for x in (-W / 2, -W / 4, 0.0, W / 4, W / 2):
        b.box((cx + x, fy - 0.015, wz + H / 2), (0.08, 0.03, H), "PE_Beam")
    b.box((cx, fy - 0.015, wz + H * 0.5), (W, 0.03, 0.07), "PE_Beam")
    b.box((cx, fy - 0.015, wz + H - 0.04), (W + 0.04, 0.03, 0.08), "PE_Beam")
    for sx in (-1, 1):
        b.box((cx + sx * (W / 2 + 0.015), cy, wz + H * 0.5), (0.03, D, 0.07), "PE_Beam")
        b.box((cx + sx * (W / 2 + 0.015), cy, wz + H / 2), (0.03, 0.08, H), "PE_Beam")
    # door + windows
    b.arch_opening((cx + 0.3, fy, wz), (0, -1, 0), 0.42, 0.72, "PE_WoodDark", "PE_Beam", depth=0.04, frame=0.05, segs=2)
    for x in (-0.75, 0.88):
        b.box((cx + x, fy - 0.02, wz + 0.72), (0.3, 0.03, 0.28), "PE_Window")
        parts.shutters(b, (cx + x, fy - 0.02, wz + 0.72), (0, -1, 0), 0.3, 0.3)
    b.box((cx + W / 2 + 0.02, cy, wz + 0.72), (0.03, 0.3, 0.28), "PE_Window")
    rz = wz + H
    # rounded hipped thatch: a hip roof plus a thick thatch eave roll
    b.hip_roof((cx, cy, rz), W, D, 1.05, "PE_Thatch", overhang=0.2, thick=0.16, under_mat="PE_Thatch")
    b.box((cx, cy, rz + 1.07), (W - D + 0.25, 0.22, 0.12), "PE_Thatch")          # ridge roll
    # eyebrow dormer over the front windows
    b.box((cx - 0.4, fy + 0.05, rz + 0.12), (0.5, 0.3, 0.32), "PE_PlasterWhite")
    b.box((cx - 0.4, fy - 0.11, rz + 0.12), (0.26, 0.03, 0.2), "PE_Window")
    b.hip_roof((cx - 0.4, fy + 0.05, rz + 0.28), 0.5, 0.3, 0.2, "PE_Thatch", overhang=0.08, under_mat="PE_Thatch")
    # stone chimney through the back slope
    b.box((cx + 0.7, cy + 0.45, rz + 0.75), (0.3, 0.3, 1.5), "PE_StoneGrey")
    b.box((cx + 0.7, cy + 0.45, rz + 1.52), (0.36, 0.36, 0.06), "PE_StoneGrey")
    # gable pennant (team)
    parts.pennant(b, (cx - W / 2 + 0.35, cy, rz + 0.75), h=0.85, length=0.4)
    # wattle fence + log pile + barrel
    for i in range(5):
        parts.timber_post(b, (-1.45 + i * 0.32, -1.3, z0), 0.42, s=0.06)
    b.box((-0.81, -1.3, z0 + 0.3), (1.34, 0.05, 0.16), "PE_Beam")
    parts.log_pile(b, (1.25, -0.95, z0), length=0.6, rows=2, r=0.08, axis="y")
    parts.barrel(b, (-1.35, -0.75, z0), r=0.15, h=0.38)
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                                    "reference": "res://art/buildings/%s/house.png" % CIV})
    return ob, pe_kit.mesh_stats(ob)
