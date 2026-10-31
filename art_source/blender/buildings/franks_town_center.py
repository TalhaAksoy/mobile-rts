"""Frankish Town Center (3x3 -> 5.4 m).

Reference: art/buildings/franks/town_center.png.
Read from the reference: tall Gothic church-castle in pale limestone, very steep blue-slate
roofs, a central crossing tower with spire, twin facade towers with conical blue spires,
rose window, pointed portal, blue fleur-de-lis banners.
"""
import math
import pe_kit, parts
from pe_kit import Builder

CIV = "franks"
ASSET = "town_center"


def build():
    pe_kit.reset_scene()
    b = Builder("franks_town_center")
    pe_kit.ground_pad(b, 2.7, 2.7, seed=101)
    z0 = 0.08
    # nave (ridge along Y) + transept (ridge along X), steep slate
    NW, NL, NH = 2.0, 3.6, 2.0
    ny = 0.35
    b.box((0, ny, z0 + NH / 2), (NW, NL, NH), "PE_StoneWarm")
    b.gable_roof((0, ny, z0 + NH), NW, NL, 1.45, "PE_RoofSlate", overhang=0.1, ridge_axis="y")
    b.gable_end((0, ny, z0 + NH), NW, NL, 1.45, "PE_StoneWarm", ridge_axis="y")
    TW, TD, TH = 3.9, 1.1, 1.85
    ty = ny + 0.45
    b.box((0, ty, z0 + TH / 2), (TW, TD, TH), "PE_StoneWarm")
    b.gable_roof((0, ty, z0 + TH), TW, TD, 1.2, "PE_RoofSlate", overhang=0.1, ridge_axis="x")
    b.gable_end((0, ty, z0 + TH), TW, TD, 1.2, "PE_StoneWarm", ridge_axis="x")
    for sx in (-1, 1):
        b.arch_opening((sx * TW / 2, ty, z0 + 0.55), (sx, 0, 0), 0.4, 0.95, "PE_Window", "PE_StoneGrey", pointed=True, segs=4)
        for y in (ny - 1.2, ny + 1.4):
            b.arch_opening((sx * NW / 2, y, z0 + 0.6), (sx, 0, 0), 0.3, 0.8, "PE_Window", "PE_StoneGrey", pointed=True, segs=4)
            b.box((sx * (NW / 2 + 0.12), y + 0.35, z0 + 0.8), (0.24, 0.18, 1.6), "PE_StoneWarm")   # buttress
    # crossing tower + spire
    # crossing tower rises well above both ridges so the Gothic spire dominates the silhouette
    b.box((0, ty, z0 + NH + 1.35), (0.85, 0.85, 2.2), "PE_StoneWarm")
    for f, (fx, fy) in (((0, -1, 0), (0, ty - 0.425)), ((1, 0, 0), (0.425, ty)), ((-1, 0, 0), (-0.425, ty))):
        b.arch_opening((fx, fy, z0 + NH + 1.6), f, 0.22, 0.6, "PE_Window", None, pointed=True, segs=3)
    parts.crenellations(b, -0.42, 0.42, ty - 0.42, z0 + NH + 2.45, depth=0.08, merlon_w=0.1, gap=0.08, h=0.12, mat="PE_StoneWarm")
    parts.square_spire(b, (0, ty), 0.8, 2.0, "PE_RoofSlate", z0 + NH + 2.45)
    # west facade with twin towers, rose window and portal
    fy = ny - NL / 2
    for sx in (-1, 1):
        parts.round_tower(b, (sx * 1.05, fy + 0.05, z0), 0.4, 3.5, wall_mat="PE_StoneWarm", cap_h=1.6, team_band=True)
    b.arch_opening((0, fy, z0), (0, -1, 0), 0.72, 1.35, "PE_Window", "PE_StoneGrey", depth=0.06, frame=0.09, pointed=True)
    rose = [(0.32 * math.cos(2 * math.pi * k / 12), fy - 0.02, z0 + 1.68 + 0.32 * math.sin(2 * math.pi * k / 12)) for k in range(12)]
    b.poly(pe_kit._ccw(rose, (0, -1, 0)), "PE_Window")
    ring = [(0.4 * math.cos(2 * math.pi * k / 12), fy - 0.025, z0 + 1.68 + 0.4 * math.sin(2 * math.pi * k / 12)) for k in range(12)]
    for k in range(12):
        j = (k + 1) % 12
        b.poly(pe_kit._ccw([rose[k], ring[k], ring[j], rose[j]], (0, -1, 0)), "PE_StoneGrey")
    for x in (-1.05, 1.05):
        b.banner((x, fy + 0.05 - 0.42, z0 + 1.9), (0, -1, 0), 0.34, 0.85, CIV)
    b.stairs((0, fy, z0), 1.0, 2, 0.08, 0.15, "PE_StoneGrey")
    b.flag((0.75, ty - 0.9, z0 + NH), 1.5, CIV, size=(0.55, 0.36))
    parts.cypress(b, (-2.3, -2.0, z0), height=1.3, r=0.24)
    parts.round_tree(b, (2.25, -1.95, z0), height=1.1, r=0.36)
    parts.round_tree(b, (-2.25, 2.1, z0), height=1.2, r=0.4)
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [3, 3], "footprint_m": 5.4, "reference": "res://art/buildings/franks/town_center.png"})
    return ob, pe_kit.mesh_stats(ob)
