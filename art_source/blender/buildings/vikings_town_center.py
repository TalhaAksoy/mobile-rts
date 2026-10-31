"""Viking Town Center (3x3 -> 5.4 m).

Reference: art/buildings/vikings/town_center.png.
Read from the reference: great timber hall (langhus) on a low stone foundation, very steep
wood-shingle roof dominating the silhouette, crossed gable boards ending in carved dragon
heads, dark plank walls with heavy posts, carved entrance porch, blue banners, round shields.
No stone castle, no tiles: timber everywhere.
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "vikings"
ASSET = "town_center"


def dragon_gable(b, ridge_pt, side, h):
    """Crossed gable boards rising above a ridge end, with carved heads."""
    x, y, z = ridge_pt
    for s in (-1, 1):
        a = (x, y + s * 0.55, z - 0.45)
        t = (x, y - s * 0.32, z + h)
        b.cylinder_between(a, t, 0.05, "PE_Beam", segs=4, smooth=False)
        b.box((x, y - s * 0.38, z + h + 0.05), (0.08, 0.2, 0.12), "PE_WoodDark")


def build():
    pe_kit.reset_scene()
    b = Builder("vikings_town_center")
    pe_kit.ground_pad(b, 2.7, 2.7, seed=131)
    z0 = 0.08
    LW, LD, LH = 3.9, 2.5, 1.15
    ly = 0.35
    b.box((0, ly, z0 + 0.12), (LW + 0.15, LD + 0.15, 0.24), "PE_StoneGrey")
    zf = z0 + 0.24
    b.box((0, ly, zf + LH / 2), (LW, LD, LH), "PE_WoodDark")
    # heavy posts along the walls
    for x in (-LW / 2, -LW / 6, LW / 6, LW / 2):
        for y in (ly - LD / 2, ly + LD / 2):
            b.box((x, y, zf + LH / 2), (0.16, 0.16, LH), "PE_Beam")
    RH = 1.85
    b.gable_roof((0, ly, zf + LH), LW, LD, RH, "PE_Shingle", overhang=0.32, ridge_axis="x", end_mat="PE_WoodDark")
    b.gable_end((0, ly, zf + LH), LW, LD, RH, "PE_WoodDark", ridge_axis="x")
    for sx in (-1, 1):
        dragon_gable(b, (sx * (LW / 2 + 0.3), ly, zf + LH + RH), sx, 0.8)
    b.box((0, ly, zf + LH + RH + 0.04), (LW + 0.6, 0.12, 0.08), "PE_WoodDark")
    # entrance porch with its own steep gable (ridge along Y) and carved posts
    PW, PD, PH = 1.3, 0.9, 1.25
    py = ly - LD / 2 - PD / 2 + 0.05
    for sx in (-1, 1):
        b.box((sx * PW / 2, py - PD / 2 + 0.08, zf + PH / 2), (0.14, 0.14, PH), "PE_Beam")
    b.gable_roof((0, py, zf + PH), PW, PD, 0.9, "PE_Shingle", overhang=0.12, ridge_axis="y", end_mat="PE_WoodDark")
    b.poly([(-PW / 2, py - PD / 2 - 0.12, zf + PH - 0.07), (PW / 2, py - PD / 2 - 0.12, zf + PH - 0.07), (0, py - PD / 2 - 0.12, zf + PH + 0.88)], "PE_WoodDark")
    b.box((0, ly - LD / 2 - 0.012, zf + 0.5), (0.6, 0.03, 1.0), "PE_Window")
    b.box((0, py - PD / 2 - 0.13, zf + PH + 0.1), (0.9, 0.03, 0.1), "TEAM_Trim")
    # team-coloured round shields along the front wall
    for x in (-1.5, -1.0, 1.0, 1.5):
        parts.round_shield(b, (x, ly - LD / 2, zf + 0.62), (0, -1, 0), r=0.18)
    # banner poles + flag
    for (x, y, h) in ((-2.3, -1.6, 2.6), (2.3, -1.5, 2.4)):
        b.cylinder((x, y, z0), 0.04, h, "PE_WoodDark", segs=5, cap=False)
        b.box((x, y, z0 + h - 0.06), (0.34, 0.04, 0.04), "PE_WoodDark")
        b.banner((x, y, z0 + h - 0.08), (0, -1, 0), 0.3, 0.75, CIV)
    b.stairs((0, py - PD / 2, z0), 0.9, 2, 0.08, 0.15, "PE_StoneGrey")
    parts.barrel(b, (1.9, -2.0, z0))
    parts.barrel(b, (2.2, -1.85, z0))
    parts.log_pile(b, (-1.7, 2.1, z0), length=1.2, rows=2, r=0.1)
    for (x, y, h) in ((2.3, 2.2, 1.6), (-2.35, 0.9, 1.4)):
        b.cylinder((x, y, z0), 0.06, 0.3, "PE_WoodDark", segs=5, cap=False)
        b.cone((x, y, z0 + 0.25), 0.34, h * 0.6, "PE_Foliage", segs=8)
        b.cone((x, y, z0 + 0.25 + h * 0.35), 0.26, h * 0.6, "PE_Foliage", segs=8)
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [3, 3], "footprint_m": 5.4, "reference": "res://art/buildings/vikings/town_center.png"})
    return ob, pe_kit.mesh_stats(ob)
