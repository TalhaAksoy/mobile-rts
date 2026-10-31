"""Mongol Town Center (3x3 grid -> 5.4 m footprint).

Reference: art/buildings/mongols/town_center.png.
Read from the reference: one great ger (yurt): round cream felt wall on a timber platform,
shallow felt dome roof with radial rope/rafter lines and a timber crown ring (toono), painted
orange-red door frame with a blue felt band above it, several tall blue banners on poles,
a cauldron, crates and steps. Mobile steppe civilization: NO stone walls, no tiled roofs.
"""
import math
import pe_kit, parts
from pe_kit import Builder

CIV = "mongols"
ASSET = "town_center"


def build():
    pe_kit.reset_scene()
    b = Builder("mongols_town_center")
    pe_kit.ground_pad(b, 2.7, 2.7, seed=71)
    z0 = 0.08
    # timber platform
    b.cylinder((0, 0.2, z0), 2.2, 0.16, "PE_WoodLight", segs=20, smooth=False)
    zp = z0 + 0.16
    R, WH = 1.85, 1.15
    # felt wall + lattice band peeking at the base + blue decorative band near the top
    b.cylinder((0, 0.2, zp), R, WH, "PE_Felt", segs=24, cap=False)
    b.cylinder((0, 0.2, zp), R + 0.01, 0.16, "PE_Lattice", segs=24, cap=False)
    b.cylinder((0, 0.2, zp + WH - 0.3), R + 0.015, 0.2, "PE_FeltBlue", segs=24, cap=False)
    # rope bands around the wall
    for zz in (zp + 0.45, zp + WH - 0.06):
        b.cylinder((0, 0.2, zz), R + 0.025, 0.035, "PE_WoodLight", segs=24, cap=False)
    # roof: shallow felt dome + radial rafter ropes + TEAM band at the eave
    RR = R + 0.12
    b.cylinder((0, 0.2, zp + WH - 0.02), RR, 0.06, "TEAM_Trim", segs=24, cap=False)
    roof_base = zp + WH + 0.04
    RH = 0.95
    b.dome((0, 0.2, roof_base), RR, "PE_Felt", segs=24, rings=5, height=RH)
    # orange ornament band on the lower roof (reference shows painted orange patterns)
    # (radii sit just OUTSIDE the dome surface: dome r(h) = RR*sqrt(1-(h/RH)^2))
    b.cylinder((0, 0.2, roof_base + 0.08), RR * 1.0 + 0.012, 0.11, "PE_LacquerRed", segs=24, cap=False, r_top=RR * 0.982 + 0.012)
    for i in range(12):
        a = 2 * math.pi * i / 12
        pts = []
        for k in range(5):
            phi = (math.pi / 2) * k / 5 * 0.86
            rr = (RR + 0.02) * math.cos(phi)
            pts.append((rr * math.cos(a), 0.2 + rr * math.sin(a), roof_base + (RH + 0.02) * math.sin(phi)))
        for k in range(4):
            b.cylinder_between(pts[k], pts[k + 1], 0.034, "PE_WoodDark", segs=4)
    # crown ring (toono)
    b.cylinder((0, 0.2, roof_base + RH - 0.12), 0.42, 0.14, "PE_WoodLight", segs=12)
    b.cylinder((0, 0.2, roof_base + RH + 0.02), 0.3, 0.12, "PE_LacquerRed", segs=12)
    b.cylinder((0, 0.2, roof_base + RH + 0.14), 0.04, 0.35, "PE_WoodDark", segs=5)
    b.dome((0, 0.2, roof_base + RH + 0.47), 0.09, "PE_LacquerRed", segs=6, rings=2)
    # door: painted orange-red frame, dark doorway, blue felt label, small canopy
    fy = 0.2 - R
    b.box((0, fy - 0.08, zp + 0.48), (0.84, 0.18, 0.96), "PE_LacquerRed")
    b.box((0, fy - 0.175, zp + 0.42), (0.58, 0.02, 0.8), "PE_Window")
    b.box((0, fy - 0.12, zp + 1.05), (1.0, 0.12, 0.2), "PE_FeltBlue")
    b.quad((-0.6, fy - 0.6, zp + 1.2), (0.6, fy - 0.6, zp + 1.2), (0.6, fy - 0.05, zp + 1.42), (-0.6, fy - 0.05, zp + 1.42), "PE_FeltBlue")
    b.quad((0.6, fy - 0.6, zp + 1.2), (-0.6, fy - 0.6, zp + 1.2), (-0.6, fy - 0.05, zp + 1.42), (0.6, fy - 0.05, zp + 1.42), "PE_FeltBlue")
    for sx in (-1, 1):
        parts.timber_post(b, (sx * 0.58, fy - 0.58, z0), 1.34, s=0.06)
    b.stairs((0, 0.2 - 2.2, z0), 0.9, 2, 0.08, 0.16, "PE_WoodLight")
    # tall banner poles (blue, steppe standards) around the ger
    for (x, y, h) in ((-2.25, -1.6, 3.0), (2.3, -1.4, 2.7), (-1.9, 2.1, 3.3), (2.1, 2.0, 2.9)):
        b.cylinder((x, y, z0), 0.04, h, "PE_WoodDark", segs=5, cap=False)
        b.cone((x, y, z0 + h), 0.06, 0.25, "PE_Gold", segs=5)
        b.box((x, y, z0 + h - 0.08), (0.36, 0.04, 0.04), "PE_WoodDark")
        b.banner((x, y, z0 + h - 0.1), (0, -1, 0), 0.32, 0.75, CIV)
    # cauldron on stones, crates
    for k in range(5):
        a = 2 * math.pi * k / 5
        b.box((1.35 + 0.2 * math.cos(a), -1.75 + 0.2 * math.sin(a), z0 + 0.06), (0.14, 0.14, 0.12), "PE_StoneGrey")
    b.cylinder((1.35, -1.75, z0 + 0.12), 0.22, 0.3, "PE_Iron", segs=10, r_top=0.27)
    parts.crate(b, (-1.45, -1.7, z0), 0.3)
    parts.crate(b, (-1.2, -1.95, z0), 0.24)
    parts.barrel(b, (-1.65, -1.25, z0))
    return b.finalize()


def run(export=True):
    ob = build()
    if export:
        return ob, pe_kit.export_asset(ob, CIV, ASSET, extra_meta={"grid": [3, 3], "footprint_m": 5.4,
                                                                    "reference": "res://art/buildings/mongols/town_center.png"})
    return ob, pe_kit.mesh_stats(ob)
