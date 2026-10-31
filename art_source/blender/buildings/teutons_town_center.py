"""Teutonic Town Center (3x3 -> 5.4 m).

Reference: art/buildings/teutons/town_center.png.
Read from the reference: heavy grey-stone fortified monastery-keep, dark (near-black) slate
roofs, a tall square bergfried tower with crenellations and spire, pointed gothic openings,
corner turrets with dark spires, black-and-white cross banners.
Difference to the Franks: darker, heavier, more fortress than church (crenellations, fewer
windows, square keep instead of a crossing spire).
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "teutons"
ASSET = "town_center"


def build():
    pe_kit.reset_scene()
    b = Builder("teutons_town_center")
    pe_kit.ground_pad(b, 2.7, 2.7, seed=111)
    z0 = 0.08
    # main hall, steep dark hip roof
    HW, HD, HH = 3.2, 2.3, 2.0
    hy = 0.45
    b.box((0, hy, z0 + 0.15), (HW + 0.1, HD + 0.1, 0.3), "PE_StoneGrey")
    b.box((0, hy, z0 + HH / 2), (HW, HD, HH), "PE_StoneGrey")
    b.hip_roof((0, hy, z0 + HH), HW, HD, 1.25, "PE_SlateDark", overhang=0.12)
    for x in (-1.1, 1.1):
        b.arch_opening((x, hy - HD / 2, z0 + 0.75), (0, -1, 0), 0.24, 0.6, "PE_Window", "PE_StoneWarm", pointed=True, segs=4)
    # bergfried (square keep tower) back-left
    kx, ky = -1.0, 1.25
    KH = 3.9
    b.box((kx, ky, z0 + KH / 2), (1.15, 1.15, KH), "PE_StoneGrey")
    b.box((kx, ky, z0 + KH + 0.05), (1.3, 1.3, 0.1), "PE_StoneGrey")
    for yy in (ky - 0.6, ky + 0.6):
        parts.crenellations(b, kx - 0.6, kx + 0.6, yy, z0 + KH + 0.1, depth=0.12, merlon_w=0.15, gap=0.11, h=0.18, mat="PE_StoneGrey")
    for xx in (kx - 0.6, kx + 0.6):
        parts.crenellations(b, ky - 0.5, ky + 0.5, xx, z0 + KH + 0.1, depth=0.12, merlon_w=0.15, gap=0.11, h=0.18, mat="PE_StoneGrey", axis="y")
    parts.square_spire(b, (kx, ky), 0.8, 1.2, "PE_SlateDark", z0 + KH + 0.1)
    b.arch_opening((kx, ky - 0.575, z0 + 2.6), (0, -1, 0), 0.22, 0.5, "PE_Window", None, pointed=True, segs=3)
    b.box((kx, ky - 0.587, z0 + KH - 0.35), (1.0, 0.03, 0.1), "TEAM_Trim")
    # gatehouse to the front with crenellations
    GW, GD, GH = 1.5, 0.9, 2.3
    gy = hy - HD / 2 - GD / 2 + 0.2
    b.box((0, gy, z0 + GH / 2), (GW, GD, GH), "PE_StoneGrey")
    gf = gy - GD / 2
    b.arch_opening((0, gf, z0), (0, -1, 0), 0.7, 1.3, "PE_Window", "PE_StoneWarm", depth=0.06, frame=0.08, pointed=True)
    parts.crenellations(b, -GW / 2 + 0.04, GW / 2 - 0.04, gf + 0.08, z0 + GH, depth=0.16, merlon_w=0.15, gap=0.11, h=0.16, mat="PE_StoneGrey")
    for x in (-0.55, 0.55):
        b.banner((x, gf, z0 + GH - 0.25), (0, -1, 0), 0.3, 0.8, CIV)
    # corner turrets with dark spires (front corners of the hall)
    for sx in (-1, 1):
        parts.round_tower(b, (sx * 1.75, hy - HD / 2 - 0.05, z0), 0.36, 2.7, wall_mat="PE_StoneGrey", roof_mat="PE_SlateDark", cap_h=1.2, team_band=(sx > 0))
    parts.round_tower(b, (1.75, hy + HD / 2, z0), 0.34, 2.4, wall_mat="PE_StoneGrey", roof_mat="PE_SlateDark", cap_h=1.0)
    b.stairs((0, gf, z0), 0.9, 2, 0.08, 0.15, "PE_StoneGrey")
    b.flag((kx, ky, z0 + KH + 1.25), 0.9, CIV, size=(0.55, 0.38))
    for (x, y, h) in ((-2.3, -2.0, 1.4), (2.35, -2.1, 1.2), (2.3, 2.3, 1.5)):
        b.cylinder((x, y, z0), 0.06, 0.3, "PE_WoodDark", segs=5, cap=False)
        b.cone((x, y, z0 + 0.25), 0.34, h * 0.6, "PE_Foliage", segs=8)
        b.cone((x, y, z0 + 0.25 + h * 0.35), 0.26, h * 0.6, "PE_Foliage", segs=8)
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [3, 3], "footprint_m": 5.4, "reference": "res://art/buildings/teutons/town_center.png"})
    return ob, pe_kit.mesh_stats(ob)
