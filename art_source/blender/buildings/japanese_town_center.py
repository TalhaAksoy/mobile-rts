"""Japanese Town Center (3x3 grid -> 5.4 m footprint).

Reference: art/buildings/japanese/town_center.png.
Read from the reference: castle keep (tenshu) of three stacked tiers on a battered stone
base (ishigaki), white plaster walls framed by dark timber, red lacquer balconies, dark
kawara tile hip roofs with strongly upturned eaves, gold ridge finial, red banners with
the hinomaru, stone steps to a gate.
Interpretation: the reference crops the keep tightly. Tier proportions shrink ~25% per level
so the stack still reads at the 45-degree RTS pitch, where the roofs dominate the silhouette.
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "japanese"
ASSET = "town_center"


def tier(b, z, w, d, h, roof_h, overhang, curve, windows, balcony=False):
    """One keep tier: plaster walls with timber frame + kawara hip roof. Returns roof base z."""
    b.box((0, 0.15, z + h / 2), (w, d, h), "PE_PlasterWhite")
    # dark timber frame: corner posts, sill and head beams
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.box((sx * (w / 2 - 0.04), 0.15 + sy * (d / 2 - 0.04), z + h / 2), (0.1, 0.1, h), "PE_WoodDark")
    b.box((0, 0.15, z + 0.05), (w + 0.04, d + 0.04, 0.1), "PE_WoodDark")
    b.box((0, 0.15, z + h - 0.06), (w + 0.04, d + 0.04, 0.12), "PE_WoodDark")
    # windows: dark lattice slits on the front and sides
    fy = 0.15 - d / 2
    for i in range(windows):
        x = (i - (windows - 1) / 2) * (w / (windows + 0.5))
        b.box((x, fy - 0.012, z + h * 0.55), (w / (windows + 2.5), 0.03, h * 0.38), "PE_Lattice")
        b.box((x, fy - 0.022, z + h * 0.55), (0.04, 0.02, h * 0.42), "PE_WoodDark")
    for sx in (-1, 1):
        for j in range(max(1, windows - 1)):
            y = 0.15 + (j - (max(1, windows - 1) - 1) / 2) * (d / (windows + 0.5))
            b.box((sx * (w / 2 + 0.012), y, z + h * 0.55), (0.03, d / (windows + 2.5), h * 0.38), "PE_Lattice")
    if balcony:
        # red lacquer balcony railing round the tier
        bz = z + 0.05
        for sx in (-1, 1):
            b.box((sx * (w / 2 + 0.16), 0.15, bz + 0.18), (0.05, d + 0.36, 0.05), "PE_LacquerRed")
        for sy in (-1, 1):
            b.box((0, 0.15 + sy * (d / 2 + 0.16), bz + 0.18), (w + 0.36, 0.05, 0.05), "PE_LacquerRed")
        for sx in (-1, 1):
            for sy in (-1, 1):
                b.box((sx * (w / 2 + 0.16), 0.15 + sy * (d / 2 + 0.16), bz + 0.1), (0.06, 0.06, 0.22), "PE_LacquerRed")
    # red lacquer band right under the eave (reads strongly from the RTS camera)
    b.box((0, 0.15, z + h - 0.2), (w + 0.05, d + 0.05, 0.1), "PE_LacquerRed")
    b.hip_roof((0, 0.15, z + h), w, d, roof_h, "PE_RoofDark", overhang=overhang, curve=curve, under_mat="PE_LacquerRed")
    return z + h


def build():
    pe_kit.reset_scene()
    b = Builder("japanese_town_center")
    pe_kit.ground_pad(b, 2.7, 2.7, seed=61)
    z0 = 0.08
    # Ishigaki: battered stone base with steps up to the gate
    BH = 0.7
    b.frustum((0, 0.15, z0), 4.3, 4.0, 3.7, 3.4, BH, "PE_StoneGrey", top_mat="PE_Dirt")
    for i in range(4):
        hh = BH * (4 - i) / 4
        b.box((0, -1.85 - 0.16 * i - 0.08, z0 + hh / 2), (1.0, 0.16, hh), "PE_StoneGrey")
    z = z0 + BH
    # Three tiers
    top1 = tier(b, z, 3.0, 2.7, 1.2, 0.5, 0.36, 0.38, windows=3)
    top2 = tier(b, top1 + 0.32, 2.2, 1.95, 0.95, 0.46, 0.32, 0.34, windows=2, balcony=True)
    top3 = tier(b, top2 + 0.3, 1.45, 1.25, 0.8, 0.62, 0.28, 0.3, windows=1)
    # Gold ridge finials (shachihoko) + spire
    ridge_z = top3 + 0.62
    for sx in (-1, 1):
        b.box((sx * 0.12, 0.15, ridge_z + 0.06), (0.1, 0.08, 0.16), "PE_Gold")
    b.cylinder((0, 0.15, ridge_z - 0.05), 0.05, 0.55, "PE_Gold", segs=6, r_top=0.015)
    b.box((0, 0.15, ridge_z - 0.02), (0.4, 0.12, 0.06), "PE_RoofDark")
    # Gate: red lacquer posts + small curved porch roof in front of the first tier
    gy = 0.15 - 2.7 / 2
    for sx in (-1, 1):
        b.box((sx * 0.42, gy - 0.25, z + 0.5), (0.12, 0.12, 1.0), "PE_LacquerRed")
    b.box((0, gy - 0.012, z + 0.4), (0.62, 0.03, 0.8), "PE_Window")
    b.hip_roof((0, gy - 0.22, z + 1.0), 1.0, 0.55, 0.32, "PE_RoofDark", overhang=0.16, curve=0.12)
    b.box((0, gy - 0.5, z + 0.92), (0.95, 0.05, 0.08), "TEAM_Trim")
    # Nobori banners (hinomaru) on poles at the front corners of the base
    for sx in (-1, 1):
        x = sx * 1.95
        b.cylinder((x, -1.75, z0), 0.035, 2.4, "PE_WoodDark", segs=5, cap=False)
        b.box((x, -1.75, z0 + 2.38), (0.32, 0.04, 0.04), "PE_WoodDark")
        b.banner((x, -1.75, z0 + 2.36), (0, -1, 0), 0.3, 0.85, CIV, tail=False)
    b.flag((1.25, 0.9, top1 + 0.1), 1.7, CIV, size=(0.6, 0.4))
    # Pines (round, layered)
    for (x, y, s) in ((-2.25, 1.85, 1.0), (2.25, 1.9, 0.85), (-2.35, -0.6, 0.75)):
        b.cylinder((x, y, z0), 0.06, 0.6 * s, "PE_WoodDark", segs=5, cap=False)
        b.dome((x, y, z0 + 0.45 * s), 0.38 * s, "PE_Foliage", segs=8, rings=2, height=0.3 * s)
        b.dome((x + 0.08, y, z0 + 0.75 * s), 0.28 * s, "PE_Foliage", segs=8, rings=2, height=0.22 * s)
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [3, 3], "footprint_m": 5.4,
                                                                    "reference": "res://art/buildings/japanese/town_center.png"})
    return ob, pe_kit.mesh_stats(ob)
