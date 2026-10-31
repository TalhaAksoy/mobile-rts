"""Ottoman Barracks (3x3 grid -> 5.4 m footprint).

Reference: art/buildings/ottomans/barracks.png.
Read from the reference: long cream hall with red barrel-tile gable roof, a projecting stone
gatehouse with a pointed-arch gate and crenellations, red banners flanking the gate, a small
lead cupola, a side wing with red hip roof, training yard with weapon rack, crescent flag.
Military, not religious: one small cupola only, no minarets.
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "ottomans"
ASSET = "barracks"


def build():
    pe_kit.reset_scene()
    b = Builder("ottomans_barracks")
    pe_kit.ground_pad(b, 2.7, 2.7, seed=31)
    z0 = 0.08
    # Main hall (back), ridge along X
    HW, HD, HH = 3.9, 2.0, 1.45
    hy = 0.75
    b.box((0, hy, z0 + 0.12), (HW + 0.08, HD + 0.08, 0.24), "PE_StoneWarm")
    b.box((0, hy, z0 + HH / 2), (HW, HD, HH), "PE_PlasterCream")
    fy = hy - HD / 2
    for x in (-1.45, -0.8, 0.8, 1.45):
        b.arch_opening((x, fy, z0 + 0.5), (0, -1, 0), 0.3, 0.58, "PE_Window", "PE_StoneWarm", pointed=True, segs=4)
    for sx in (-1, 1):
        b.arch_opening((sx * HW / 2, hy, z0 + 0.5), (sx, 0, 0), 0.3, 0.58, "PE_Window", "PE_StoneWarm", pointed=True, segs=4)
    b.gable_roof((0, hy, z0 + HH), HW, HD, 0.95, "PE_RoofRed", overhang=0.2, ridge_axis="x", ridge_mat="PE_RoofRed")
    b.gable_end((0, hy, z0 + HH), HW, HD, 0.95, "PE_PlasterCream", ridge_axis="x")
    # Cupola on the ridge
    b.box((0.9, hy, z0 + HH + 0.95), (0.5, 0.5, 0.35), "PE_PlasterCream")
    b.dome((0.9, hy, z0 + HH + 1.12), 0.3, "PE_DomeLead", segs=10, rings=3)

    # Gatehouse projecting to the front
    GW, GD, GH = 1.6, 1.1, 2.2
    gy = fy - GD / 2 + 0.15
    b.box((0, gy, z0 + GH / 2), (GW, GD, GH), "PE_StoneWarm")
    gfront = gy - GD / 2
    b.arch_opening((0, gfront, z0), (0, -1, 0), 0.85, 1.45, "PE_Window", "PE_PlasterCream", depth=0.05, frame=0.09, pointed=True)
    b.box((0, gfront - 0.012, z0 + GH - 0.3), (GW - 0.25, 0.03, 0.1), "TEAM_Trim")
    parts.crenellations(b, -GW / 2 + 0.04, GW / 2 - 0.04, gy - GD / 2 + 0.1, z0 + GH, depth=0.2, merlon_w=0.15, gap=0.11, h=0.15)
    parts.crenellations(b, -GW / 2 + 0.04, GW / 2 - 0.04, gy + GD / 2 - 0.1, z0 + GH, depth=0.2, merlon_w=0.15, gap=0.11, h=0.15)
    for sx in (-1, 1):
        parts.crenellations(b, gy - GD / 2 + 0.25, gy + GD / 2 - 0.25, sx * (GW / 2 - 0.1), z0 + GH, depth=0.2, merlon_w=0.15, gap=0.11, h=0.15, axis="y")
    for x in (-0.62, 0.62):
        b.banner((x, gfront, z0 + GH - 0.45), (0, -1, 0), 0.28, 0.8, CIV)
    b.flag((-0.55, gy + 0.2, z0 + GH), 1.4, CIV, size=(0.6, 0.4))

    # Side wing (front-left) with red hip roof
    WW, WD, WH = 1.35, 1.5, 1.15
    wx, wy = -1.85, -0.85
    b.box((wx, wy, z0 + WH / 2), (WW, WD, WH), "PE_PlasterCream")
    b.box((wx, wy, z0 + 0.1), (WW + 0.06, WD + 0.06, 0.2), "PE_StoneWarm")
    b.arch_opening((wx, wy - WD / 2, z0), (0, -1, 0), 0.45, 0.8, "PE_Window", "PE_StoneWarm", pointed=True, segs=4)
    b.arch_opening((wx - WW / 2, wy, z0 + 0.45), (-1, 0, 0), 0.26, 0.45, "PE_Window", "PE_StoneWarm", pointed=True, segs=4)
    b.hip_roof((wx, wy, z0 + WH), WW, WD, 0.6, "PE_RoofRed", overhang=0.16)

    # Training yard (front-right): fence, weapon rack with spears, target dummy
    for i in range(5):
        parts.timber_post(b, (1.0 + i * 0.4, -2.35, z0), 0.45, s=0.07)
    b.box((1.8, -2.35, z0 + 0.38), (1.7, 0.05, 0.06), "PE_WoodDark")
    b.box((1.8, -2.35, z0 + 0.18), (1.7, 0.05, 0.06), "PE_WoodDark")
    for j in range(3):
        parts.timber_post(b, (2.55, -1.95 + j * 0.4, z0), 0.45, s=0.07)
    b.box((2.55, -1.55, z0 + 0.38), (0.05, 0.85, 0.06), "PE_WoodDark")
    # weapon rack
    b.box((1.4, -1.5, z0 + 0.55), (0.9, 0.08, 0.06), "PE_WoodDark")
    for k in range(5):
        x = 1.05 + k * 0.17
        b.cylinder((x, -1.47, z0), 0.02, 1.15, "PE_WoodDark", segs=4, cap=False)
        b.cone((x, -1.47, z0 + 1.15), 0.035, 0.14, "PE_StoneWarm", segs=4, smooth=False)
    # dummy
    parts.timber_post(b, (2.0, -1.0, z0), 1.0, s=0.08)
    b.box((2.0, -1.0, z0 + 0.8), (0.55, 0.07, 0.07), "PE_WoodDark")
    b.cylinder((2.0, -1.0, z0 + 0.5), 0.13, 0.35, "PE_ClothRed", segs=6)
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [3, 3], "footprint_m": 5.4,
                                                                    "reference": "res://art/buildings/ottomans/barracks.png"})
    return ob, pe_kit.mesh_stats(ob)
