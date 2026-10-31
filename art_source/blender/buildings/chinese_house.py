"""Chinese House (2x2 grid -> 3.6 m footprint).

Reference: art/buildings/chinese/house.png (red-pillared house, layered roofs).
Civ reading: a small courtyard house. Main hall on a stone platform with red lacquer columns
and lattice, grey brick end walls, a teal-tiled curved roof with gold ridge ends; a grey
courtyard wall in front with a small teal-roofed gate. Avoids Japanese white walls/dark tiles.
Team: hanging lanterns under the eaves + pennant.
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "chinese"
ASSET = "house"


def build():
    pe_kit.reset_scene()
    b = Builder("chinese_house")
    pe_kit.ground_pad(b, 1.8, 1.8, seed=47)
    z0 = 0.08
    cx, cy = 0.0, 0.5
    W, D, H = 2.3, 1.2, 1.05
    b.box((cx, cy, z0 + 0.13), (W + 0.3, D + 0.3, 0.26), "PE_StoneGrey")          # platform
    pz = z0 + 0.26
    b.box((cx, cy + 0.08, pz + H / 2), (W - 0.2, D - 0.2, H), "PE_StoneBrick")      # grey brick core
    fy = cy - D / 2
    for x in (-W / 2, -W / 6, W / 6, W / 2):                                         # red columns
        b.box((cx + x, fy, pz + H / 2), (0.1, 0.1, H), "PE_LacquerRed")
    b.box((cx, fy, pz + H - 0.06), (W + 0.06, 0.1, 0.12), "PE_LacquerRed")
    for x in (-W / 3, W / 3):
        b.box((cx + x, fy + 0.11, pz + 0.55), (W / 3 - 0.14, 0.03, 0.62), "PE_Lattice")
    b.box((cx, fy + 0.11, pz + 0.42), (0.42, 0.03, 0.84), "PE_WoodDark")
    b.stairs((cx, fy - 0.12, z0), 0.6, 2, 0.13, 0.12, "PE_StoneGrey")
    # teal curved roof + gold ridge ends
    rz = pz + H
    b.hip_roof((cx, cy, rz), W, D, 0.7, "PE_RoofTeal", overhang=0.3, curve=0.16, under_mat="PE_LacquerRed")
    rr = max(0.0, W / 2 - D / 2)
    b.cylinder_between((cx - rr - 0.05, cy, rz + 0.72), (cx + rr + 0.05, cy, rz + 0.72), 0.06, "PE_RoofTeal", segs=6)
    for sx in (-1, 1):
        b.cone((cx + sx * (rr + 0.08), cy, rz + 0.72), 0.08, 0.26, "PE_Gold", segs=5, smooth=False)
    # team lanterns hanging from the eave
    for x in (-0.8, 0.8):
        b.cylinder((cx + x, fy - 0.12, rz - 0.42), 0.02, 0.3, "PE_WoodDark", segs=4, cap=False)
        b.cylinder((cx + x, fy - 0.12, rz - 0.62), 0.1, 0.2, "TEAM_Trim", segs=8, r_top=0.08)
    # courtyard wall with a small gate roof (front)
    wy = -1.25
    for x0, x1 in ((-1.55, -0.38), (0.38, 1.55)):
        b.box(((x0 + x1) / 2, wy, z0 + 0.32), (x1 - x0, 0.14, 0.64), "PE_StoneGrey")
        b.box(((x0 + x1) / 2, wy, z0 + 0.67), (x1 - x0 + 0.06, 0.24, 0.06), "PE_RoofTeal")
    for sx in (-1, 1):
        b.box((sx * 1.55, (wy + cy - D / 2) / 2 - 0.05, z0 + 0.32), (0.14, 1.1, 0.64), "PE_StoneGrey")
        b.box((sx * 0.38, wy, z0 + 0.45), (0.1, 0.1, 0.9), "PE_LacquerRed")
    b.hip_roof((0, wy, z0 + 0.9), 0.86, 0.3, 0.22, "PE_RoofTeal", overhang=0.12, curve=0.08, under_mat="PE_LacquerRed")
    # courtyard: water vat
    b.cylinder((0.85, -0.6, z0), 0.2, 0.3, "PE_StoneGrey", segs=8, smooth=False, top_mat="PE_Window")
    parts.pennant(b, (-1.45, -0.85, z0), h=1.5, length=0.38, tip="PE_Gold")
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                                    "reference": "res://art/buildings/%s/house.png" % CIV})
    return ob, pe_kit.mesh_stats(ob)
