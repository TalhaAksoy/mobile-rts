"""Chinese Town Center (3x3 -> 5.4 m).

Reference: art/buildings/chinese/town_center.png.
Read from the reference: two-storey hall-pavilion on a walled grey-stone platform with a
crenellated parapet and central gate, red lacquer columns and walls, green-teal glazed
roof tiles with upturned eaves and gold ridge ornaments, red dragon banners on the wall.
Difference to the Japanese: green-teal (not dark) tiles, red (not white) walls, wide walled
platform instead of a tall battered keep, two broad tiers instead of three narrow ones.
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "chinese"
ASSET = "town_center"


def pavilion(b, z, w, d, h, roof_h, overhang, curve, cols):
    yc = 0.35
    b.box((0, yc, z + h / 2), (w - 0.3, d - 0.3, h), "PE_LacquerRed")
    # lattice window panels on the front between columns
    for i in range(cols - 1):
        x = -w / 2 + (i + 0.5) * (w / (cols - 1))
        b.box((x, yc - (d - 0.3) / 2 - 0.012, z + h * 0.55), (w / (cols - 1) * 0.7, 0.03, h * 0.55), "PE_Lattice")
    # red columns around a veranda
    for i in range(cols):
        x = -w / 2 + 0.08 + i * ((w - 0.16) / (cols - 1))
        for y in (yc - d / 2 + 0.08, yc + d / 2 - 0.08):
            b.box((x, y, z + h / 2), (0.1, 0.1, h), "PE_LacquerRed")
    b.box((0, yc, z + h - 0.06), (w, d, 0.12), "PE_WoodDark")
    b.hip_roof((0, yc, z + h), w, d, roof_h, "PE_RoofTeal", overhang=overhang, curve=curve, under_mat="PE_LacquerRed")
    return z + h


def build():
    pe_kit.reset_scene()
    b = Builder("chinese_town_center")
    pe_kit.ground_pad(b, 2.7, 2.7, seed=141)
    z0 = 0.08
    PH = 0.95
    b.frustum((0, 0.25, z0), 4.6, 4.4, 4.3, 4.1, PH, "PE_StoneGrey", top_mat="PE_StoneWarm")
    zt = z0 + PH
    pf = 0.25 - 4.1 / 2
    parts.crenellations(b, -2.1, 2.1, pf + 0.08, zt, depth=0.14, merlon_w=0.2, gap=0.14, h=0.2, mat="PE_StoneGrey")
    # gate through the platform + steps
    b.arch_opening((0, 0.25 - 4.4 / 2 + 0.01, z0), (0, -1, 0), 0.7, 0.8, "PE_Window", "PE_LacquerRed", depth=0.04, frame=0.07)
    b.box((0, 0.25 - 4.4 / 2 - 0.02, z0 + 0.86), (0.9, 0.03, 0.08), "TEAM_Trim")
    for x in (-1.45, 1.45):
        b.banner((x, 0.25 - 4.4 / 2 + 0.02, zt - 0.05), (0, -1, 0), 0.32, 0.72, CIV, tail=False)
    top1 = pavilion(b, zt, 3.1, 2.5, 1.25, 0.55, 0.34, 0.38, cols=5)
    top2 = pavilion(b, top1 + 0.45, 2.1, 1.7, 1.0, 0.6, 0.3, 0.34, cols=4)
    # gold ridge ornaments
    rz = top2 + 0.62
    b.box((0, 0.35, rz - 0.02), (0.5, 0.12, 0.08), "PE_RoofTeal")
    for sx in (-1, 1):
        b.box((sx * 0.28, 0.35, rz + 0.08), (0.1, 0.1, 0.22), "PE_Gold")
    b.cylinder((0, 0.35, rz - 0.05), 0.05, 0.35, "PE_Gold", segs=6, r_top=0.02)
    b.flag((1.25, 1.1, top1 + 0.1), 1.6, CIV, size=(0.6, 0.4))
    for (x, y) in ((-2.25, 2.25), (2.3, 2.25)):
        parts.round_tree(b, (x, y, z0), height=1.0, r=0.34)
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [3, 3], "footprint_m": 5.4, "reference": "res://art/buildings/chinese/town_center.png"})
    return ob, pe_kit.mesh_stats(ob)
