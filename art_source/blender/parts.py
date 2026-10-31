"""Reusable architectural parts built on pe_kit.Builder (shared across civilizations)."""
import math
from mathutils import Vector as V


def ottoman_minaret(b, base, height=5.0, shaft_r=0.17, cap_mat="PE_DomeLead", shaft_mat="PE_PlasterWhite",
                    team_band=True):
    """Pencil minaret: square stone base, 12-gon shaft, serefe balcony, conical lead cap, gold alem."""
    x, y, z = base
    b.box((x, y, z + 0.3), (0.5, 0.5, 0.6), "PE_StoneWarm")
    b.box((x, y, z + 0.63), (0.56, 0.56, 0.06), "PE_StoneWarm")
    shaft_top = z + height * 0.72
    b.cylinder((x, y, z + 0.66), shaft_r * 1.15, 0.25, "PE_StoneWarm", segs=12, cap=False)
    b.cylinder((x, y, z + 0.91), shaft_r, shaft_top - (z + 0.91), shaft_mat, segs=12, cap=False)
    # serefe (balcony) with corbel and parapet
    b.cylinder((x, y, shaft_top - 0.12), shaft_r, 0.12, "PE_StoneWarm", segs=12, cap=False, r_top=shaft_r * 1.8)
    b.cylinder((x, y, shaft_top), shaft_r * 1.8, 0.14, "PE_StoneWarm", segs=12)
    if team_band:
        b.cylinder((x, y, shaft_top - 0.34), shaft_r * 1.03, 0.1, "TEAM_Trim", segs=12, cap=False)
    upper_h = height * 0.16
    b.cylinder((x, y, shaft_top + 0.14), shaft_r * 0.85, upper_h, shaft_mat, segs=12, cap=False)
    cap_z = shaft_top + 0.14 + upper_h
    b.cylinder((x, y, cap_z), shaft_r * 1.05, 0.05, "PE_StoneWarm", segs=12)
    b.cone((x, y, cap_z + 0.05), shaft_r * 1.05, height - (cap_z + 0.05 - z) - 0.18, cap_mat, segs=12)
    b.cylinder((x, y, z + height - 0.2), 0.025, 0.28, "PE_Gold", segs=4)
    b.cylinder((x, y, z + height - 0.02), 0.05, 0.07, "PE_Gold", segs=6)


def cypress(b, base, height=1.8, r=0.32, seed=0):
    x, y, z = base
    b.cylinder((x, y, z), 0.05, 0.25, "PE_WoodDark", segs=5, cap=False)
    # stacked cones read as a stylised cypress
    b.cylinder((x, y, z + 0.2), r * 0.7, height * 0.35, "PE_Foliage", segs=8, r_top=r)
    b.cone((x, y, z + 0.2 + height * 0.35), r, height * 0.65, "PE_Foliage", segs=8)


def round_tree(b, base, height=1.6, r=0.55):
    x, y, z = base
    b.cylinder((x, y, z), 0.07, height * 0.45, "PE_WoodDark", segs=5, cap=False)
    b.dome((x, y, z + height * 0.4), r, "PE_Foliage", segs=10, rings=3, height=r * 0.5)
    # underside of canopy
    b.cylinder((x, y, z + height * 0.4 - r * 0.25), r * 0.75, r * 0.25, "PE_Foliage", segs=10, r_top=r, cap=False)
    b.dome((x, y, z + height * 0.55), r * 0.75, "PE_Foliage", segs=10, rings=3, height=r * 0.75)


def crenellations(b, x0, x1, y, z, depth=0.2, merlon_w=0.18, gap=0.14, h=0.18, mat="PE_StoneWarm", axis="x"):
    """Row of merlons along X (axis='x', at fixed y) or along Y (axis='y', at fixed x=y-arg)."""
    L = x1 - x0
    n = max(1, int((L + gap) / (merlon_w + gap)))
    step = L / n
    for i in range(n):
        c = x0 + step * (i + 0.5)
        if axis == "x":
            b.box((c, y, z + h / 2), (merlon_w, depth, h), mat)
        else:
            b.box((y, c, z + h / 2), (depth, merlon_w, h), mat)


def log_pile(b, center, length=1.2, rows=3, r=0.11, axis="x"):
    x, y, z = center
    k = 0
    for row in range(rows):
        count = rows - row + 1
        for i in range(count):
            off = (i - (count - 1) / 2) * r * 2.05
            zz = z + r + row * r * 1.75
            if axis == "x":
                a = (x - length / 2, y + off, zz); c = (x + length / 2, y + off, zz)
            else:
                a = (x + off, y - length / 2, zz); c = (x + off, y + length / 2, zz)
            b.cylinder_between(a, c, r, "PE_Beam", segs=6, smooth=False)
            k += 1


def crate(b, center, s=0.35):
    x, y, z = center
    b.box((x, y, z + s / 2), (s, s, s), "PE_WoodLight")
    b.box((x, y, z + s + 0.01), (s + 0.02, s + 0.02, 0.03), "PE_WoodDark")


def barrel(b, center, r=0.17, h=0.42):
    x, y, z = center
    b.cylinder((x, y, z), r * 0.85, h * 0.5, "PE_WoodLight", segs=8, cap=False, r_top=r)
    b.cylinder((x, y, z + h * 0.5), r, h * 0.5, "PE_WoodLight", segs=8, r_top=r * 0.85)
    b.cylinder((x, y, z + h * 0.18), r * 0.95, 0.04, "PE_Iron", segs=8, cap=False)
    b.cylinder((x, y, z + h * 0.78), r * 0.95, 0.04, "PE_Iron", segs=8, cap=False)


def timber_post(b, base, h, s=0.12, mat="PE_WoodDark"):
    x, y, z = base
    b.box((x, y, z + h / 2), (s, s, h), mat)


def round_tower(b, base, r, h, wall_mat="PE_StoneGrey", roof_mat="PE_RoofSlate", cap_h=None, segs=10,
                windows=True, team_band=False, finial=True):
    """Round tower with a conical cap (Briton / Frankish / Teutonic castles)."""
    x, y, z = base
    b.cylinder((x, y, z), r * 1.08, 0.25, wall_mat, segs=segs, cap=False)
    b.cylinder((x, y, z + 0.25), r, h - 0.25, wall_mat, segs=segs, cap=False)
    b.cylinder((x, y, z + h - 0.08), r * 1.1, 0.1, wall_mat, segs=segs)
    if team_band:
        b.cylinder((x, y, z + h - 0.3), r * 1.01, 0.1, "TEAM_Trim", segs=segs, cap=False)
    if windows:
        b.arch_opening((x, y - r * 0.99, z + h * 0.55), (0, -1, 0), r * 0.4, r * 0.75, "PE_Window", None, segs=3)
    ch = cap_h if cap_h is not None else r * 2.6
    b.cone((x, y, z + h + 0.02), r * 1.22, ch, roof_mat, segs=segs, smooth=False)
    if finial:
        b.cylinder((x, y, z + h + ch - 0.05), 0.022, 0.3, "PE_Gold", segs=4)


def square_spire(b, center, w, h, mat, base_z):
    x, y = center
    b.pyramid_roof((x, y, base_z), w, w, h, mat, overhang=0.06)
    b.cylinder((x, y, base_z + h - 0.04), 0.022, 0.32, "PE_Gold", segs=4)


def saracen_minaret(b, base, height=4.2, r=0.17):
    """Sandstone minaret with teal balconies and a small teal dome + gold crescent."""
    x, y, z = base
    b.box((x, y, z + 0.35), (0.5, 0.5, 0.7), "PE_Sandstone")
    b.cylinder((x, y, z + 0.7), r * 1.15, height * 0.55, "PE_Sandstone", segs=8, cap=False, r_top=r)
    zb = z + 0.7 + height * 0.55
    b.cylinder((x, y, zb), r * 1.7, 0.1, "PE_TileTeal", segs=8)
    b.cylinder((x, y, zb + 0.1), r * 0.9, height * 0.18, "PE_Sandstone", segs=8, cap=False)
    zt = zb + 0.1 + height * 0.18
    b.cylinder((x, y, zt), r * 1.25, 0.08, "PE_TileTeal", segs=8)
    b.dome((x, y, zt + 0.08), r * 1.15, "PE_TileTeal", segs=8, rings=3, height=r * 1.6)
    b.cylinder((x, y, zt + 0.08 + r * 1.6 - 0.03), 0.02, 0.25, "PE_Gold", segs=4)


def round_shield(b, center, facing, r=0.16, mat="TEAM_Trim"):
    """Painted round shield hung on a wall (team-coloured: ownership readable from far)."""
    import mathutils
    f = mathutils.Vector(facing).normalized()
    c = mathutils.Vector(center) + f * 0.04
    right = mathutils.Vector((0, 0, 1)).cross(f).normalized() * -1
    up = mathutils.Vector((0, 0, 1))
    pts = [c + (right * math.cos(2 * math.pi * k / 8) + up * math.sin(2 * math.pi * k / 8)) * r for k in range(8)]
    import pe_kit
    b.poly(pe_kit._ccw(pts, f), mat)
    b.cylinder_between(c - f * 0.0, c + f * 0.04, r * 0.25, "PE_Iron", segs=5)


# ------------------------------------------------------------------------------------------------
# Mill (farm centre). One shared layout so every civ's Mill reads as "the mill" at a glance (tower
# + turning sails), with the civilisation carried by tower masonry, cap shape/material, the granary
# annex and small cultural props. Sails are a SEPARATE object "Sails" (origin = hub, turning axis =
# Blender Y = towards the camera) so Godot can spin them.
# ------------------------------------------------------------------------------------------------
def _sails(hub, radius=1.25, cloth="PE_SailCloth", frame="PE_WoodDark", arms=4, lattice=False):
    import pe_kit
    from pe_kit import Builder
    s = Builder("Sails")
    s.cylinder_between((0, 0.0, 0), (0, -0.12, 0), 0.09, frame, segs=6, smooth=False)   # hub boss
    for k in range(arms):
        a = 2 * math.pi * k / arms + math.pi / 4
        d = V((math.cos(a), 0, math.sin(a)))
        side = V((-d.z, 0, d.x))
        y = -0.1
        tip = d * radius
        s.cylinder_between((0, y, 0), (tip.x, y, tip.z), 0.035, frame, segs=4, smooth=False)  # stock
        # sail panel: from 0.28 to 0.95 of the arm, offset to one side (classic common sail)
        p0 = d * (radius * 0.28); p1 = d * (radius * 0.97)
        w = 0.3
        quad = [p0 + V((0, y - 0.01, 0)), p1 + V((0, y - 0.01, 0)), p1 + side * w + V((0, y - 0.01, 0)), p0 + side * w + V((0, y - 0.01, 0))]
        mat = "PE_Lattice" if lattice else cloth
        s.poly(pe_kit._ccw(quad, (0, -1, 0)), mat)
        s.poly(pe_kit._ccw([q + V((0, 0.02, 0)) for q in quad], (0, 1, 0)), mat)
        # frame bars along the panel edge
        s.cylinder_between(p1 + V((0, y - 0.02, 0)), p1 + side * w + V((0, y - 0.02, 0)), 0.018, frame, segs=4, smooth=False)
        s.cylinder_between(p0 + side * w + V((0, y - 0.02, 0)), p1 + side * w + V((0, y - 0.02, 0)), 0.018, frame, segs=4, smooth=False)
    ob = s.finalize()
    ob.location = hub
    return ob


def sack(b, c, r=0.13, mat="PE_Felt"):
    x, y, z = c
    b.cylinder((x, y, z), r, r * 1.2, mat, segs=6, r_top=r * 0.75, smooth=False)
    b.cylinder((x, y, z + r * 1.2), r * 0.35, r * 0.35, mat, segs=5, smooth=False)


def build_mill(name, civ, spec):
    """spec keys: tower_mat, base_mat, cap ('cone'|'dome'|'tiered'|'thatch'|'tent'), cap_mat,
    annex ('gable'|'kura'|'ger'|'dome'|'pavilion'|'stabbur'|'timber'), annex_wall, annex_roof,
    sails ('cloth'|'lattice'), extras (callable(b, z0) for cultural props)."""
    import pe_kit
    from pe_kit import Builder
    pe_kit.reset_scene()
    b = Builder(name)
    pe_kit.ground_pad(b, 1.8, 1.8, seed=sum(map(ord, civ)) % 97)
    z0 = 0.08
    tx, ty = -0.45, 0.3                       # tower sits back-left, annex front-right
    r0, r1, th = 0.78, 0.58, 2.25
    base_mat = spec.get("base_mat", spec["tower_mat"])
    b.cylinder((tx, ty, z0), r0 * 1.06, 0.28, base_mat, segs=10, cap=False, smooth=False)
    b.cylinder((tx, ty, z0 + 0.28), r0, th - 0.28, spec["tower_mat"], segs=10, r_top=r1, cap=False, smooth=False)
    b.arch_opening((tx, ty - r0 * 0.97, z0 + 0.02), (0, -1, 0), 0.38, 0.62, "PE_WoodDark", base_mat, segs=4)
    b.arch_opening((tx + 0.0, ty - (r0 + r1) * 0.5 * 0.96, z0 + 1.3), (0, -1, 0), 0.18, 0.3, "PE_Window", None, segs=3)
    b.cylinder((tx, ty, z0 + th - 0.34), r1 * 1.06, 0.12, "TEAM_Trim", segs=10, cap=False, smooth=False)  # ownership band
    b.cylinder((tx, ty, z0 + th - 0.04), r1 * 1.12, 0.08, spec.get("rim_mat", "PE_WoodDark"), segs=10, smooth=False)
    cz = z0 + th + 0.04
    cap, cm = spec["cap"], spec["cap_mat"]
    if cap == "cone":
        b.cone((tx, ty, cz), r1 * 1.25, 0.85, cm, segs=10, smooth=False)
    elif cap == "thatch":
        b.cylinder((tx, ty, cz), r1 * 1.32, 0.18, cm, segs=10, r_top=r1 * 1.1, cap=False, smooth=False)
        b.dome((tx, ty, cz + 0.18), r1 * 1.1, cm, segs=10, rings=3, height=0.7, smooth=False)
    elif cap == "dome":
        b.dome((tx, ty, cz), r1 * 1.15, cm, segs=12, rings=4, height=0.75, smooth=False)
        b.cylinder((tx, ty, cz + 0.72), 0.02, 0.28, "PE_Gold", segs=4)
    elif cap == "tiered":                         # East-Asian double-eave pavilion cap
        b.hip_roof((tx, ty, cz), r1 * 1.7, r1 * 1.7, 0.32, cm, overhang=0.18, curve=0.12)
        b.box((tx, ty, cz + 0.42), (r1 * 0.9, r1 * 0.9, 0.22), spec.get("cap_wall", "PE_LacquerRed"))
        b.hip_roof((tx, ty, cz + 0.53), r1 * 1.15, r1 * 1.15, 0.36, cm, overhang=0.14, curve=0.1)
    elif cap == "tent":                           # felt-covered conical cap with ribs
        b.cone((tx, ty, cz), r1 * 1.3, 0.72, cm, segs=10, smooth=False)
        b.cylinder((tx, ty, cz + 0.62), 0.07, 0.14, "PE_WoodDark", segs=6)
    if spec.get("finial", True) and cap in ("cone", "thatch"):
        b.cylinder((tx, ty, cz + 0.78), 0.02, 0.26, "PE_Gold" if spec.get("gold_finial") else "PE_WoodDark", segs=4)
    hub = (tx, ty - r1 * 1.15, z0 + th + 0.18)
    b.cylinder_between((tx, ty, hub[2]), hub, 0.07, "PE_WoodDark", segs=6, smooth=False)   # wind shaft

    # granary / annex (front-right)
    ax, ay = 0.85, -0.45
    aw, ad, ah = 1.25, 1.0, 0.85
    kind = spec["annex"]
    wall, roof = spec.get("annex_wall", "PE_StoneWarm"), spec.get("annex_roof", "PE_RoofRed")
    if kind in ("gable", "kura", "timber"):
        if kind == "timber":
            b.box((ax, ay, z0 + 0.12), (aw + 0.06, ad + 0.06, 0.24), "PE_StoneGrey")
            b.box((ax, ay, z0 + 0.24 + (ah - 0.24) / 2), (aw, ad, ah - 0.24), wall)
            for xx in (-aw / 2, 0.0, aw / 2):
                b.box((ax + xx, ay - ad / 2 - 0.01, z0 + 0.24 + (ah - 0.24) / 2), (0.07, 0.03, ah - 0.24), "PE_Beam")
        else:
            b.box((ax, ay, z0 + ah / 2), (aw, ad, ah), wall)
        if kind == "kura":
            b.box((ax, ay, z0 + 0.12), (aw + 0.04, ad + 0.04, 0.24), "PE_RoofDark")   # dark namako base
        b.gable_roof((ax, ay, z0 + ah), aw, ad, 0.5, roof, overhang=0.14, ridge_axis="x", ridge_mat=roof)
        b.gable_end((ax, ay, z0 + ah), aw, ad, 0.5, wall if kind != "timber" else "PE_WoodDark", ridge_axis="x")
        b.arch_opening((ax - 0.25, ay - ad / 2, z0 + 0.0), (0, -1, 0), 0.34, 0.55, "PE_WoodDark", None, segs=3)
    elif kind == "ger":
        b.cylinder((ax, ay, z0), 0.62, 0.55, wall, segs=12, cap=False, smooth=False)
        b.dome((ax, ay, z0 + 0.55), 0.66, roof, segs=12, rings=3, height=0.42, smooth=False)
        b.cylinder((ax, ay, z0 + 0.94), 0.14, 0.06, "PE_WoodDark", segs=8)
        b.cylinder((ax, ay, z0 + 0.4), 0.63, 0.06, "PE_FeltBlue", segs=12, cap=False)
        b.arch_opening((ax, ay - 0.6, z0), (0, -1, 0), 0.26, 0.42, "PE_LacquerRed", None, segs=2)
    elif kind == "dome":
        b.box((ax, ay, z0 + ah / 2), (aw * 0.9, ad, ah), wall)
        b.cylinder((ax, ay, z0 + ah), 0.42, 0.12, wall, segs=10, smooth=False)
        b.dome((ax, ay, z0 + ah + 0.12), 0.42, roof, segs=10, rings=3, smooth=False)
        b.arch_opening((ax, ay - ad / 2, z0), (0, -1, 0), 0.32, 0.55, "PE_WoodDark", None, segs=4, pointed=True)
    elif kind == "pavilion":
        b.box((ax, ay, z0 + 0.1), (aw + 0.1, ad + 0.1, 0.2), "PE_StoneGrey")
        for xx in (-aw / 2 + 0.06, aw / 2 - 0.06):
            for yy in (-ad / 2 + 0.06, ad / 2 - 0.06):
                b.box((ax + xx, ay + yy, z0 + 0.2 + 0.32), (0.09, 0.09, 0.64), "PE_LacquerRed")
        b.box((ax, ay + 0.1, z0 + 0.2 + 0.3), (aw * 0.8, ad * 0.6, 0.6), wall)
        b.hip_roof((ax, ay, z0 + 0.84), aw, ad, 0.45, roof, overhang=0.18, curve=0.14)
    elif kind == "stabbur":                      # storehouse raised on posts
        for xx in (-aw / 2 + 0.1, aw / 2 - 0.1):
            for yy in (-ad / 2 + 0.1, ad / 2 - 0.1):
                b.box((ax + xx, ay + yy, z0 + 0.15), (0.12, 0.12, 0.3), "PE_StoneGrey")
        b.box((ax, ay, z0 + 0.3 + 0.32), (aw, ad, 0.64), wall)
        b.gable_roof((ax, ay, z0 + 0.94), aw, ad, 0.62, roof, overhang=0.16, ridge_axis="x", ridge_mat=roof)
        b.gable_end((ax, ay, z0 + 0.94), aw, ad, 0.62, wall, ridge_axis="x")
        b.stairs((ax - 0.3, ay - ad / 2, z0), 0.3, 3, 0.1, 0.1, "PE_WoodDark")
    # grain sacks + crate in front, banner post with civ banner
    for (sx, sy) in ((0.35, -1.25), (0.62, -1.3), (0.48, -1.05)):
        sack(b, (sx, sy, z0))
    crate(b, (1.35, -1.25, z0), s=0.32)
    timber_post(b, (-1.45, -1.2, z0), 1.5, s=0.07)
    b.box((-1.45, -1.2, z0 + 1.52), (0.11, 0.11, 0.12), "TEAM_Trim")
    b.banner((-1.45, -1.24, z0 + 1.45), (0, -1, 0), 0.26, 0.5, civ)
    if spec.get("extras"):
        spec["extras"](b, z0)
    main = b.finalize()
    sails = _sails(hub, radius=1.2, cloth=spec.get("sail_mat", "PE_SailCloth"), frame=spec.get("sail_frame", "PE_WoodDark"),
                   lattice=spec.get("sails") == "lattice")
    sails.parent = main
    return main, sails


def pennant(b, base, h=1.5, length=0.45, mat="TEAM_Trim", pole="PE_WoodDark", tip=None):
    """Pole with a triangular team pennant flying towards +X (two-sided). Reads the owner
    from the RTS camera on small buildings whose roofs hide wall trims."""
    x, y, z = base
    b.cylinder((x, y, z), 0.03, h, pole, segs=4, cap=False, smooth=False)
    if tip:
        b.cone((x, y, z + h), 0.05, 0.12, tip, segs=4, smooth=False)
    top, low = z + h - 0.03, z + h - 0.33
    tri = [(x + 0.02, y, top), (x + 0.02, y, low), (x + length, y - 0.03, (top + low) / 2)]
    b.poly(tri, mat)
    b.poly([tri[1], tri[0], tri[2]], mat)


def shutters(b, center, facing, w, h, mat="TEAM_Trim"):
    """A pair of open window shutters beside an opening (facing = (0,-1,0) or (+-1,0,0))."""
    x, y, z = center
    fx, fy = facing[0], facing[1]
    for s in (-1, 1):
        if fy:
            b.box((x + s * (w / 2 + w * 0.28), y + fy * 0.03, z), (w * 0.5, 0.03, h), mat)
        else:
            b.box((x + fx * 0.03, y + s * (w / 2 + w * 0.28), z), (0.03, w * 0.5, h), mat)
