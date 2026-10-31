"""Japanese House (2x2 grid -> 3.6 m footprint).

Reference: art/buildings/japanese/house.png. The gallery sprite reads European, so the model
follows the civ rules instead (ART_DIRECTION_BIBLE §6: white plaster + dark timber, dark kawara,
upturned eaves, red accents; avoid Chinese red walls / teal tiles).
Civ reading: a farmhouse (minka) on a low stone base, white plaster panels in a dark timber
frame, shoji lattice, a wooden veranda (engawa), a dark-tiled hip-and-gable (irimoya) roof with
lifted corners, a bamboo fence and a rain barrel. Team: noren curtain over the door + pennant.
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "japanese"
ASSET = "house"


def build():
    pe_kit.reset_scene()
    b = Builder("japanese_house")
    pe_kit.ground_pad(b, 1.8, 1.8, seed=43)
    z0 = 0.08
    cx, cy = 0.05, 0.3
    W, D, H = 2.2, 1.45, 1.2
    b.box((cx, cy, z0 + 0.1), (W + 0.12, D + 0.12, 0.2), "PE_StoneGrey")
    wz = z0 + 0.2
    b.box((cx, cy, wz + H / 2), (W, D, H), "PE_PlasterWhite")
    fy = cy - D / 2
    # dark timber frame: posts + head/sill beams on every side
    for x in (-W / 2, -W / 4, 0.0, W / 4, W / 2):
        b.box((cx + x, fy - 0.015, wz + H / 2), (0.08, 0.03, H), "PE_WoodDark")
    for z in (0.04, H * 0.45, H - 0.05):
        b.box((cx, fy - 0.015, wz + z), (W, 0.03, 0.07), "PE_WoodDark")
    for sx in (-1, 1):
        for y in (-D / 2, 0.0, D / 2):
            b.box((cx + sx * (W / 2 + 0.015), cy + y, wz + H / 2), (0.03, 0.08, H), "PE_WoodDark")
        b.box((cx + sx * (W / 2 + 0.015), cy, wz + H - 0.05), (0.03, D, 0.07), "PE_WoodDark")
        b.box((cx + sx * (W / 2 + 0.02), cy - D / 4, wz + 0.68), (0.03, D * 0.32, 0.3), "PE_Lattice")
    # shoji panels + sliding door under a team noren curtain
    for x in (-0.86, -0.29):
        b.box((cx + x, fy - 0.02, wz + 0.25), (0.48, 0.03, 0.4), "PE_Lattice")
    b.box((cx + 0.58, fy - 0.02, wz + 0.37), (0.46, 0.03, 0.74), "PE_WoodDark")
    for k in range(3):
        b.box((cx + 0.43 + k * 0.15, fy - 0.045, wz + 0.68), (0.13, 0.02, 0.24), "TEAM_Trim")
    # engawa veranda along the front
    vy = fy - 0.25
    b.box((cx - 0.3, vy, z0 + 0.22), (1.6, 0.46, 0.06), "PE_WoodLight")
    for x in (-1.0, -0.3, 0.4):
        b.box((cx + x, vy - 0.18, z0 + 0.1), (0.07, 0.07, 0.2), "PE_WoodDark")
    # irimoya roof: curved hip roof + a small gable on top
    rz = wz + H
    b.hip_roof((cx, cy, rz), W, D, 0.78, "PE_RoofDark", overhang=0.3, curve=0.1)
    # upper gable part of the irimoya: a gable roof sitting on the hip, with timber gable ends
    gz = rz + 0.62
    GW, GD = W * 0.7, D * 0.36
    b.gable_roof((cx, cy, gz), GW, GD, 0.42, "PE_RoofDark", overhang=0.1, ridge_axis="x", ridge_mat="PE_RoofDark")
    b.box((cx, cy, gz - 0.06), (GW, GD, 0.14), "PE_WoodDark")
    b.gable_end((cx, cy, gz), GW, GD, 0.42, "PE_PlasterWhite", ridge_axis="x")
    for sx in (-1, 1):          # ridge-end tiles (onigawara)
        b.box((cx + sx * (GW / 2 + 0.1), cy, gz + 0.44), (0.08, 0.2, 0.18), "PE_RoofDark")
    # bamboo fence (left) + rain barrel + pennant
    for i in range(6):
        b.cylinder((-1.5 + i * 0.13, -1.25, z0), 0.035, 0.55, "PE_WoodLight", segs=5, smooth=False)
    b.box((-1.18, -1.25, z0 + 0.42), (0.75, 0.05, 0.04), "PE_WoodDark")
    parts.barrel(b, (1.45, -0.75, z0), r=0.16, h=0.4)
    parts.pennant(b, (1.45, -1.3, z0), h=1.6, length=0.24)
    b.box((1.45 + 0.13, -1.3, z0 + 1.0), (0.24, 0.02, 0.55), "TEAM_Trim")      # nobori-style vertical cloth
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                                    "reference": "res://art/buildings/%s/house.png" % CIV})
    return ob, pe_kit.mesh_stats(ob)
