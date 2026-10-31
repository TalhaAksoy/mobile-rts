"""Franks House (2x2 grid -> 3.6 m footprint).

Reference: art/buildings/franks/house.png (pale stone house, blue slate).
Civ reading: tall pale-stone manor house with a steep blue-slate hip roof, a dormer, and a
round stair turret with a slate spire and gilt finial (the Franks' spires, scaled down).
Height + turret separate it from the Britons cottage and the dark Teuton gable house.
Team: shutters + pennant on the turret.
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "franks"
ASSET = "house"


def build():
    pe_kit.reset_scene()
    b = Builder("franks_house")
    pe_kit.ground_pad(b, 1.8, 1.8, seed=23)
    z0 = 0.08
    cx, cy = 0.25, 0.25
    W, D, H = 2.1, 1.7, 1.9
    b.box((cx, cy, z0 + 0.1), (W + 0.06, D + 0.06, 0.2), "PE_StoneGrey")
    b.box((cx, cy, z0 + H / 2), (W, D, H), "PE_StoneWarm")
    b.box((cx, cy, z0 + 0.98), (W + 0.04, D + 0.04, 0.07), "PE_StoneGrey")     # string course
    fy = cy - D / 2
    b.arch_opening((cx + 0.15, fy, z0), (0, -1, 0), 0.44, 0.78, "PE_WoodDark", "PE_StoneGrey", depth=0.04, frame=0.07, segs=4, pointed=True)
    for x in (-0.55, 0.75):
        b.box((cx + x, fy - 0.02, z0 + 0.6), (0.26, 0.03, 0.4), "PE_Window")
    for x in (-0.55, 0.15, 0.75):
        b.box((cx + x, fy - 0.02, z0 + 1.45), (0.26, 0.03, 0.46), "PE_Window")
        parts.shutters(b, (cx + x, fy - 0.02, z0 + 1.45), (0, -1, 0), 0.26, 0.46)
    for y in (-0.35, 0.4):
        b.box((cx + W / 2 + 0.02, cy + y, z0 + 1.45), (0.03, 0.26, 0.46), "PE_Window")
    # steep blue slate hip roof + front dormer
    rz = z0 + H
    b.hip_roof((cx, cy, rz), W, D, 1.25, "PE_RoofSlate", overhang=0.14)
    dz = rz + 0.05
    b.box((cx + 0.15, fy + 0.28, dz + 0.25), (0.42, 0.4, 0.5), "PE_StoneWarm")
    b.box((cx + 0.15, fy + 0.07, dz + 0.24), (0.22, 0.03, 0.3), "PE_Window")
    b.gable_roof((cx + 0.15, fy + 0.28, dz + 0.5), 0.42, 0.4, 0.3, "PE_RoofSlate", overhang=0.05, ridge_axis="y")
    b.gable_end((cx + 0.15, fy + 0.28, dz + 0.5), 0.42, 0.4, 0.3, "PE_StoneWarm", ridge_axis="y")
    b.box((cx - 0.5, cy + 0.35, rz + 0.75), (0.24, 0.24, 1.1), "PE_StoneWarm")      # chimney
    # round stair turret, front-left corner, with slate spire + gilt finial
    tx, ty = cx - W / 2 - 0.05, fy + 0.15
    b.cylinder((tx, ty, z0), 0.38, 2.45, "PE_StoneWarm", segs=10, cap=False, smooth=False)
    b.cylinder((tx, ty, z0 + 2.45), 0.42, 0.08, "PE_StoneGrey", segs=10, smooth=False)
    for z in (0.8, 1.6):
        b.box((tx - 0.06, ty - 0.37, z0 + z), (0.12, 0.04, 0.3), "PE_Window")
    b.cone((tx, ty, z0 + 2.53), 0.44, 1.35, "PE_RoofSlate", segs=10, smooth=False)
    b.cylinder((tx, ty, z0 + 3.85), 0.025, 0.22, "PE_Gold", segs=4)
    parts.pennant(b, (tx + 0.02, ty, z0 + 3.95), h=0.3, length=0.34, pole="PE_Gold")
    # yard: barrels + low stone wall
    parts.barrel(b, (1.45, -1.2, z0), r=0.15, h=0.38)
    parts.barrel(b, (1.15, -1.4, z0), r=0.14, h=0.36)
    b.box((-0.45, -1.42, z0 + 0.14), (1.6, 0.18, 0.28), "PE_StoneGrey")
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                                    "reference": "res://art/buildings/%s/house.png" % CIV})
    return ob, pe_kit.mesh_stats(ob)
