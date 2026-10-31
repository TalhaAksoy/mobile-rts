"""Teutons House (2x2 grid -> 3.6 m footprint).

Reference: art/buildings/teutons/house.png (dark-roofed half-timber house).
Civ reading: gable-to-street town house. Dark rubble-stone ground floor, jettied half-timber
upper floor (dark beams on cream), a very steep near-black slate roof, and a STEPPED stone
gable on the front (Treppengiebel) as the silhouette marker. Team: shutters + pennant on the
top step. Must differ from Britons (thatch, whitewash) and Franks (pale stone, blue slate, turret).
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "teutons"
ASSET = "house"


def build():
    pe_kit.reset_scene()
    b = Builder("teutons_house")
    pe_kit.ground_pad(b, 1.8, 1.8, seed=17)
    z0 = 0.08
    cx, cy = 0.1, 0.2
    GW, GD, GH = 2.0, 2.2, 0.95
    b.box((cx, cy, z0 + GH / 2), (GW, GD, GH), "PE_StoneGrey")
    fy = cy - GD / 2
    b.arch_opening((cx - 0.35, fy, z0), (0, -1, 0), 0.42, 0.72, "PE_WoodDark", "PE_StoneGrey", depth=0.04, frame=0.07, segs=4)
    b.box((cx + 0.45, fy - 0.02, z0 + 0.55), (0.32, 0.03, 0.34), "PE_Window")
    parts.shutters(b, (cx + 0.45, fy - 0.02, z0 + 0.55), (0, -1, 0), 0.32, 0.34)
    # jettied half-timber upper floor
    UW, UD, UH = 2.14, 2.3, 0.9
    uz = z0 + GH
    b.box((cx, cy, uz + 0.04), (UW + 0.04, UD + 0.04, 0.08), "PE_WoodDark")
    b.box((cx, cy, uz + 0.08 + UH / 2), (UW, UD, UH), "PE_PlasterCream")
    ufy = cy - UD / 2
    for x in (-UW / 2, -UW / 6, UW / 6, UW / 2):
        b.box((cx + x, ufy - 0.015, uz + 0.08 + UH / 2), (0.08, 0.03, UH), "PE_WoodDark")
    b.box((cx, ufy - 0.015, uz + 0.08 + UH - 0.04), (UW, 0.03, 0.08), "PE_WoodDark")
    for x0, x1 in ((-UW / 2, -UW / 6), (UW / 6, UW / 2)):          # K-braces
        b.cylinder_between((cx + x0, ufy - 0.02, uz + 0.1), (cx + x1, ufy - 0.02, uz + UH), 0.035, "PE_WoodDark", segs=4, smooth=False)
    b.box((cx, ufy - 0.02, uz + 0.55), (0.34, 0.03, 0.36), "PE_Window")
    for sx in (-1, 1):
        for y in (-0.5, 0.5):
            b.box((cx + sx * (UW / 2 + 0.015), cy + y, uz + 0.55), (0.03, 0.28, 0.32), "PE_Window")
        b.box((cx + sx * (UW / 2 + 0.015), cy, uz + 0.08 + UH / 2), (0.03, 0.08, UH), "PE_WoodDark")
    # very steep near-black slate roof, ridge front-to-back (gable faces the street / camera)
    rz = uz + 0.08 + UH
    RH = 1.55
    b.gable_roof((cx, cy, rz), UW, UD, RH, "PE_SlateDark", overhang=0.1, ridge_axis="y", ridge_mat="PE_SlateDark")
    b.gable_end((cx, cy, rz), UW, UD, RH, "PE_PlasterCream", ridge_axis="y")
    # stepped stone gable in front of the front gable end
    steps = 5
    gy = ufy - 0.12
    for i in range(steps):
        w = (UW + 0.24) * (1 - i / steps)
        b.box((cx, gy, rz + (i + 0.5) * RH / steps), (w, 0.2, RH / steps + 0.02), "PE_StoneGrey")
    b.box((cx, gy - 0.11, rz + 0.55), (0.24, 0.03, 0.3), "PE_Window")
    parts.pennant(b, (cx, gy, rz + RH), h=0.6, length=0.38)
    # back chimney
    b.box((cx - 0.5, cy + 0.7, rz + 0.9), (0.26, 0.26, 1.2), "PE_StoneGrey")
    # yard: barrel, crate, bench
    parts.barrel(b, (1.45, -1.25, z0), r=0.15, h=0.38)
    parts.crate(b, (1.45, -0.8, z0), s=0.28)
    b.box((-1.2, -1.15, z0 + 0.2), (0.7, 0.22, 0.06), "PE_WoodDark")
    for x in (-1.45, -0.95):
        b.box((x, -1.15, z0 + 0.09), (0.06, 0.18, 0.18), "PE_WoodDark")
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                                    "reference": "res://art/buildings/%s/house.png" % CIV})
    return ob, pe_kit.mesh_stats(ob)
