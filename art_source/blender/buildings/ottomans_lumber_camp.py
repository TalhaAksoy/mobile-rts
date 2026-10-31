"""Ottoman Lumber Camp (2x2 grid -> 3.6 m footprint).

Reference: art/buildings/ottomans/lumber_camp.png.
Read from the reference: open timber shed on posts with a red barrel-tile roof, plank back
wall, stacked log piles in front, chopping stump, saw-horse, pines behind. Utility building:
no plaster, no dome; Ottoman identity carried by the red tiles and a small crescent banner.
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "ottomans"
ASSET = "lumber_camp"


def build():
    pe_kit.reset_scene()
    b = Builder("ottomans_lumber_camp")
    pe_kit.ground_pad(b, 1.8, 1.8, seed=41)
    z0 = 0.08
    # Open shed: 6 posts, plank back wall, red gable roof (ridge along X)
    SW, SD, SH = 2.5, 1.5, 1.15
    sy = 0.55
    for x in (-SW / 2, 0.0, SW / 2):
        for y in (sy - SD / 2, sy + SD / 2):
            parts.timber_post(b, (x, y, z0), SH, s=0.11)
    b.box((0, sy + SD / 2, z0 + SH * 0.45), (SW, 0.08, SH * 0.9), "PE_WoodDark")
    b.box((-SW / 2, sy + 0.2, z0 + SH * 0.4), (0.08, SD * 0.6, SH * 0.8), "PE_WoodDark")
    b.box((0, sy - SD / 2, z0 + SH - 0.05), (SW + 0.1, 0.1, 0.1), "PE_Beam")
    b.box((0, sy + SD / 2, z0 + SH - 0.05), (SW + 0.1, 0.1, 0.1), "PE_Beam")
    b.gable_roof((0, sy, z0 + SH), SW, SD, 0.6, "PE_RoofRed", overhang=0.2, ridge_axis="x", ridge_mat="PE_RoofRed")
    b.gable_end((0, sy, z0 + SH), SW, SD, 0.6, "PE_WoodDark", ridge_axis="x")
    # stacked logs under the roof
    parts.log_pile(b, (0.25, sy + 0.3, z0), length=1.6, rows=3, r=0.1)
    # front log piles + chopping stump with axe + saw-horse
    parts.log_pile(b, (-0.75, -0.75, z0), length=1.1, rows=2, r=0.11, axis="y")
    parts.log_pile(b, (0.85, -1.05, z0), length=1.0, rows=2, r=0.1)
    b.cylinder((0.0, -0.75, z0), 0.2, 0.32, "PE_WoodLight", segs=8)
    b.cylinder_between((0.0, -0.75, z0 + 0.3), (0.18, -0.9, z0 + 0.6), 0.025, "PE_WoodDark", segs=4)
    b.box((0.2, -0.92, z0 + 0.62), (0.12, 0.04, 0.1), "PE_Iron")
    for x in (1.1, 1.5):
        b.cylinder_between((x, -0.25, z0), (x, -0.05, z0 + 0.45), 0.03, "PE_WoodDark", segs=4)
        b.cylinder_between((x, 0.15, z0), (x, -0.05, z0 + 0.45), 0.03, "PE_WoodDark", segs=4)
    b.cylinder_between((0.95, -0.05, z0 + 0.5), (1.65, -0.05, z0 + 0.5), 0.09, "PE_Beam", segs=6, smooth=False)
    # pines at the back corners (inside the footprint) and a banner post
    for (x, y, h) in ((-1.4, 1.38, 1.7), (1.38, 1.4, 1.4)):
        b.cylinder((x, y, z0), 0.06, 0.3, "PE_WoodDark", segs=5, cap=False)
        b.cone((x, y, z0 + 0.25), 0.36, h * 0.55, "PE_Foliage", segs=8)
        b.cone((x, y, z0 + 0.25 + h * 0.35), 0.28, h * 0.55, "PE_Foliage", segs=8)
    parts.timber_post(b, (-1.45, -0.2, z0), 1.4, s=0.07)
    b.box((-1.45, -0.2, z0 + 1.42), (0.11, 0.11, 0.12), "TEAM_Trim")               # ownership cap
    b.box((0, sy - SD / 2 - 0.06, z0 + SH - 0.05), (0.8, 0.03, 0.1), "TEAM_Trim")   # ownership board
    b.banner((-1.45, -0.24, z0 + 1.35), (0, -1, 0), 0.24, 0.45, CIV)
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                                    "reference": "res://art/buildings/ottomans/lumber_camp.png"})
    return ob, pe_kit.mesh_stats(ob)
