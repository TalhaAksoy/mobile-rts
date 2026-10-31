"""Ottoman House (2x2 grid -> 3.6 m footprint).

Reference: art/buildings/ottomans/house.png.
Read from the reference: two storeys, stone ground floor + cream plaster upper floor that
overhangs (cumba), red barrel-tile hip roof, a slim corner tower with a dark conical cap,
small red awning porch, crates. No dome: economic building stays modest.
"""
import pe_kit, parts
from pe_kit import Builder

CIV = "ottomans"
ASSET = "house"


def build():
    pe_kit.reset_scene()
    b = Builder("ottomans_house")
    pe_kit.ground_pad(b, 1.8, 1.8, seed=21)
    z0 = 0.08
    cx, cy = 0.15, 0.2
    # Ground floor: warm stone
    GW, GD, GH = 2.1, 1.7, 1.0
    b.box((cx, cy, z0 + GH / 2), (GW, GD, GH), "PE_StoneWarm")
    fy = cy - GD / 2
    b.arch_opening((cx + 0.35, fy, z0), (0, -1, 0), 0.5, 0.82, "PE_Window", "PE_WoodDark", depth=0.04, frame=0.06)
    b.arch_opening((cx - 0.55, fy, z0 + 0.4), (0, -1, 0), 0.3, 0.42, "PE_Window", "PE_WoodDark", depth=0.03, frame=0.05)
    b.arch_opening((cx + GW / 2, cy, z0 + 0.4), (1, 0, 0), 0.3, 0.42, "PE_Window", "PE_WoodDark", depth=0.03, frame=0.05)
    # Timber floor band + overhanging plaster upper floor (cumba)
    UW, UD, UH = 2.34, 1.94, 0.86
    b.box((cx, cy, z0 + GH + 0.05), (UW + 0.06, UD + 0.06, 0.1), "PE_WoodDark")
    b.box((cx, cy, z0 + GH + 0.1 + UH / 2), (UW, UD, UH), "PE_PlasterCream")
    zu = z0 + GH + 0.1
    for x in (-0.55, 0.1, 0.75):
        b.arch_opening((cx + x, cy - UD / 2, zu + 0.22), (0, -1, 0), 0.26, 0.42, "PE_Window", "PE_WoodDark", depth=0.03, frame=0.05, segs=3)
    for y in (-0.4, 0.45):
        b.arch_opening((cx + UW / 2, cy + y, zu + 0.22), (1, 0, 0), 0.26, 0.42, "PE_Window", "PE_WoodDark", depth=0.03, frame=0.05, segs=3)
        b.arch_opening((cx - UW / 2, cy + y, zu + 0.22), (-1, 0, 0), 0.26, 0.42, "PE_Window", "PE_WoodDark", depth=0.03, frame=0.05, segs=3)
    # corner brackets under the overhang
    for sx in (-1, 1):
        b.box((cx + sx * (GW / 2 + 0.05), fy - 0.05, z0 + GH - 0.15), (0.08, 0.2, 0.3), "PE_WoodDark")
    # Red barrel-tile hip roof + chimney
    b.hip_roof((cx, cy, zu + UH), UW, UD, 0.72, "PE_RoofRed", overhang=0.22)
    b.box((cx + 0.6, cy + 0.45, zu + UH + 0.55), (0.22, 0.22, 0.7), "PE_StoneWarm")
    b.box((cx + 0.6, cy + 0.45, zu + UH + 0.92), (0.28, 0.28, 0.06), "PE_StoneWarm")
    # Slim corner tower with dark conical cap (front-left), as in the reference
    tx, ty = cx - GW / 2 - 0.12, fy + 0.1
    b.cylinder((tx, ty, z0), 0.3, 0.35, "PE_StoneWarm", segs=10)
    b.cylinder((tx, ty, z0 + 0.35), 0.24, 2.25, "PE_PlasterCream", segs=10, cap=False)
    b.cylinder((tx, ty, z0 + 2.6), 0.29, 0.08, "PE_WoodDark", segs=10)
    b.cylinder((tx, ty, z0 + 2.38), 0.25, 0.12, "TEAM_Trim", segs=10, cap=False)   # ownership band
    b.cone((tx, ty, z0 + 2.68), 0.29, 0.8, "PE_DomeLead", segs=10)
    b.arch_opening((tx, ty - 0.24, z0 + 1.8), (0, -1, 0), 0.14, 0.3, "PE_Window", None, segs=3)
    # Porch awning (red cloth) on two posts + crates
    ax0, ax1 = cx - 0.15, cx + 0.95
    ay = fy - 0.55
    for x in (ax0, ax1):
        parts.timber_post(b, (x, ay, z0), 0.95, s=0.07)
    b.quad((ax0 - 0.08, ay - 0.08, z0 + 0.95), (ax1 + 0.08, ay - 0.08, z0 + 0.95),
           (ax1 + 0.08, fy - 0.01, z0 + 1.2), (ax0 - 0.08, fy - 0.01, z0 + 1.2), "PE_ClothRed")
    b.quad((ax1 + 0.08, ay - 0.08, z0 + 0.95), (ax0 - 0.08, ay - 0.08, z0 + 0.95),
           (ax0 - 0.08, fy - 0.01, z0 + 1.2), (ax1 + 0.08, fy - 0.01, z0 + 1.2), "PE_ClothRed")
    parts.crate(b, (cx - 0.75, fy - 0.45, z0), 0.3)
    parts.crate(b, (cx - 0.48, fy - 0.6, z0), 0.24)
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [2, 2], "footprint_m": 3.6,
                                                                    "reference": "res://art/buildings/ottomans/house.png"})
    return ob, pe_kit.mesh_stats(ob)
