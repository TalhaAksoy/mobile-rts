"""Civ castles (4x4 grid, pad +-3.6 m). Each civ gets its own fortress type from docs/art/culture/<civ>.md
(and the 2D landmark layout in art_source/aseprite/landmarks/<civ>.lua), instead of one shared four-tower
plan with civ materials. The Mongol karakorum camp stays in bldtypes.build_castle.

Budget: the castles were 1.2k-2.6k triangles; keep every civ under ~2.6k (perf rule: no heavier buildings).
Coordinates: Blender Z up, front (camera side) = -Y, z0 = ground-pad top.
"""
import math
import parts
import civstyle as cs


# ---------------------------------------------------------------- helpers
def obox(b, c, L, t, z0, h, ang, mat, top=None):
    """Box of length L (along `ang`), thickness t, from z0 to z0+h, centred on c=(x, y)."""
    ca, sa = math.cos(ang), math.sin(ang)
    pts = []
    for px, py in ((-L / 2, -t / 2), (L / 2, -t / 2), (L / 2, t / 2), (-L / 2, t / 2)):
        pts.append((c[0] + px * ca - py * sa, c[1] + px * sa + py * ca))
    b.prism(pts, z0, z0 + h, mat, top_mat=top)


def wall(b, p0, p1, z0, h, t, mat, cren=True, merlon=0.22, gap=0.22, mh=0.2, stepped=False, top=None):
    """Curtain wall from p0 to p1 (any direction) with merlons along its top."""
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    L = math.hypot(dx, dy)
    ang = math.atan2(dy, dx)
    obox(b, ((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2), L, t, z0, h, ang, mat, top=top)
    if not cren:
        return
    n = max(1, int((L - 0.1) / (merlon + gap)))
    step = L / n
    for i in range(n):
        f = (i + 0.5) / n
        cx, cy = p0[0] + dx * f, p0[1] + dy * f
        obox(b, (cx, cy), merlon, t * 0.9, z0 + h, mh, ang, mat)
        if stepped:      # Mamluk stepped merlon: a narrower second step
            obox(b, (cx, cy), merlon * 0.5, t * 0.6, z0 + h + mh, mh * 0.7, ang, mat)


def ring_merlons(b, x, y, z, r, mat, n=8, w=0.2, h=0.2, t=0.14):
    for i in range(n):
        a = 2 * math.pi * (i + 0.5) / n
        obox(b, (x + math.cos(a) * (r - t / 2), y + math.sin(a) * (r - t / 2)), w, t, z, h, a + math.pi / 2, mat)


def drum_tower(b, x, y, z, r, h, mat, segs=10, cap=None, cap_mat="PE_RoofSlate", cap_h=None, merlons=True,
               team=True, window=True, band=None):
    """Round tower: flat crenellated top (cap=None) or a conical roof. Returns top z."""
    b.cylinder((x, y, z), r * 1.06, 0.3, mat, segs=segs, cap=False, smooth=False)
    b.cylinder((x, y, z + 0.3), r, h - 0.3, mat, segs=segs, smooth=False)
    if band:
        for zz in (h * 0.4, h * 0.75):
            b.cylinder((x, y, z + zz), r * 1.01, 0.08, band, segs=segs, cap=False, smooth=False)
    if team:
        b.cylinder((x, y, z + h - 0.35), r * 1.015, 0.1, "TEAM_Trim", segs=segs, cap=False, smooth=False)
    if window:
        b.arch_opening((x, y - r * 0.98, z + h * 0.55), (0, -1, 0), r * 0.32, r * 0.6, "PE_Window", None, segs=3)
    if cap:
        ch = cap_h if cap_h is not None else r * 2.6
        b.cylinder((x, y, z + h), r * 1.12, 0.08, "PE_WoodDark", segs=segs, smooth=False)
        b.cone((x, y, z + h + 0.08), r * 1.15, ch, cap_mat, segs=segs, smooth=False)
        b.cylinder((x, y, z + h + 0.08 + ch - 0.05), 0.02, 0.25, "PE_Gold", segs=4)
        return z + h + ch
    if merlons:
        ring_merlons(b, x, y, z + h, r, mat, n=max(6, int(r * 9)))
    return z + h


def square_tower(b, x, y, z, s, h, mat, merlons=True, team=True, roof=None, roof_h=None, glacis=0.0, band=None,
                 stepped=False):
    """Square tower, optional battered base (glacis), crenels or a pyramid roof. Returns top z."""
    if glacis > 0:
        b.frustum((x, y, z), s + glacis, s + glacis, s, s, h * 0.35, mat)
    b.box((x, y, z + h / 2), (s, s, h), mat)
    if band:
        for zz in (h * 0.35, h * 0.7):
            b.box((x, y, z + zz), (s + 0.03, s + 0.03, 0.08), band)
    b.arch_opening((x, y - s / 2, z + h * 0.58), (0, -1, 0), s * 0.22, s * 0.38, "PE_Window", None, segs=3)
    if team:
        b.box((x, y - s / 2 - 0.015, z + h * 0.82), (s * 0.7, 0.03, 0.1), "TEAM_Trim")
    if roof:
        rh = roof_h if roof_h is not None else s * 0.9
        b.pyramid_roof((x, y, z + h), s, s, rh, roof, overhang=0.1)
        return z + h + rh
    if merlons:
        r = s / 2
        for sy in (-1, 1):
            wall(b, (x - r, y + sy * (r - 0.07)), (x + r, y + sy * (r - 0.07)), z + h, 0.0, 0.14, mat, stepped=stepped)
        for sx in (-1, 1):
            wall(b, (x + sx * (r - 0.07), y - r + 0.14), (x + sx * (r - 0.07), y + r - 0.14), z + h, 0.0, 0.14, mat,
                 stepped=stepped)
    return z + h


def gate(b, x, y, z, w, h, mat, pointed=False, facing=(0, -1, 0)):
    b.arch_opening((x, y, z), facing, w, h, "PE_Window", "PE_WoodDark", depth=0.1, frame=0.08, segs=4,
                   pointed=pointed)


# ---------------------------------------------------------------- civs
def ottomans(b, z0):
    """Rumelihisari: three massive round towers with conical lead caps on a hillside, crenellated curtain walls
    of ashlar with brick bands following the slope, a pointed-arch gate and a small mescit minaret inside."""
    W, H = "PE_StoneBrick", 1.6
    big = [(-2.3, -1.9, 1.15, 3.4), (2.2, 1.9, 1.25, 3.8), (2.5, -2.3, 0.8, 2.6)]
    poly = [(-2.3, -1.9), (2.5, -2.3), (2.2, 1.9), (-0.6, 2.8), (-2.9, 1.3)]
    for i in range(len(poly)):
        p0, p1 = poly[i], poly[(i + 1) % len(poly)]
        if i == 0:                                          # front wall: gate in the middle
            m = ((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2)
            wall(b, p0, (m[0] - 0.55, m[1] - 0.04), z0, H, 0.45, W)
            wall(b, (m[0] + 0.55, m[1] + 0.04), p1, z0, H, 0.45, W)
            b.box((m[0], m[1], z0 + (H + 0.45) / 2), (1.2, 0.6, H + 0.45), W)
            gate(b, m[0], m[1] - 0.3, z0, 0.62, 1.0, W, pointed=True)
            b.banner((m[0], m[1] - 0.32, z0 + H + 0.3), (0, -1, 0), 0.3, 0.62, "ottomans")
        else:
            wall(b, p0, p1, z0, H, 0.45, W)
    for x, y, r, h in big:
        drum_tower(b, x, y, z0, r, h, W, segs=12, cap=True, cap_mat="PE_DomeLead", cap_h=r * 1.9)
    drum_tower(b, -2.9, 1.3, z0, 0.55, 2.2, W, segs=8, cap=True, cap_mat="PE_DomeLead", cap_h=0.9, team=False)
    parts.ottoman_minaret(b, (-0.4, 1.3, z0), height=3.4)
    b.box((0.6, 0.9, z0 + 0.5), (1.3, 1.0, 1.0), "PE_PlasterCream")              # mescit
    b.dome((0.6, 0.9, z0 + 1.0), 0.45, "PE_DomeLead", segs=8, rings=3, smooth=False)
    cs.flagpole(b, "ottomans", 2.2, 1.9, z0 + 3.8 + 2.3, h=1.2)


def byzantines(b, z0):
    """Theodosian walls: low outer moat wall, tall inner wall with square and octagonal banded towers, a gate
    between two towers, and a banded keep with a red-tile dome."""
    W, BAND = "PE_StoneWarm", "PE_StoneBrick"
    wall(b, (-3.3, -3.0), (-0.7, -3.0), z0, 0.8, 0.35, BAND)                      # outer (moat) wall
    wall(b, (0.7, -3.0), (3.3, -3.0), z0, 0.8, 0.35, BAND)
    H = 2.0
    wall(b, (-3.0, -1.8), (-0.75, -1.8), z0, H, 0.55, BAND)
    wall(b, (0.75, -1.8), (3.0, -1.8), z0, H, 0.55, BAND)
    for sx in (-1, 1):
        wall(b, (sx * 3.0, -1.8), (sx * 3.0, 2.6), z0, H * 0.85, 0.5, BAND)
    wall(b, (-3.0, 2.6), (3.0, 2.6), z0, H * 0.85, 0.5, BAND)
    for sx in (-1, 1):
        square_tower(b, sx * 3.0, -1.8, z0, 1.1, H + 1.0, W, band="PE_StoneBrick")
        square_tower(b, sx * 3.0, 2.6, z0, 0.9, H + 0.7, W, band="PE_StoneBrick", team=False)
        # octagonal gate towers
        b.cylinder((sx * 1.05, -1.8, z0), 0.6, H + 0.8, W, segs=8, smooth=False)
        for zz in (0.8, 1.6):
            b.cylinder((sx * 1.05, -1.8, z0 + zz), 0.61, 0.09, "PE_StoneBrick", segs=8, cap=False, smooth=False)
        ring_merlons(b, sx * 1.05, -1.8, z0 + H + 0.8, 0.6, W, n=6)
    b.box((0, -1.8, z0 + (H + 0.3) / 2), (1.0, 0.6, H + 0.3), W)
    gate(b, 0, -2.1, z0, 0.7, 1.1, W)
    b.box((0, -2.12, z0 + H), (0.7, 0.03, 0.12), "TEAM_Trim")
    b.banner((0, -2.12, z0 + H + 0.25), (0, -1, 0), 0.32, 0.65, "byzantines")
    # keep: banded square block with a red-tile dome on a drum
    b.box((0.4, 1.0, z0 + 1.4), (2.0, 1.6, 2.8), W)
    for zz in (0.9, 1.8, 2.7):
        b.box((0.4, 1.0, z0 + zz), (2.03, 1.63, 0.1), "PE_StoneBrick")
    for x in (-0.2, 0.4, 1.0):
        b.arch_opening((x, 0.2, z0 + 1.6), (0, -1, 0), 0.22, 0.42, "PE_Window", None, segs=3)
    b.box((0.4, 0.19, z0 + 2.45), (1.4, 0.03, 0.1), "TEAM_Trim")
    b.cylinder((0.4, 1.0, z0 + 2.8), 0.6, 0.35, W, segs=10, smooth=False)
    b.dome((0.4, 1.0, z0 + 3.15), 0.62, "PE_RoofRed", segs=10, rings=3, smooth=False)
    b.cylinder((0.4, 1.0, z0 + 3.75), 0.02, 0.3, "PE_Gold", segs=4)
    cs.flagpole(b, "byzantines", -1.6, 1.2, z0, h=2.6)


def britons(b, z0):
    """Edwardian concentric castle: a low outer curtain with small drum towers, a high inner ward with big
    flat-topped drum towers (no cones: Welsh castles had none) and a twin-towered gatehouse; grey stone."""
    W = "PE_StoneGrey"
    e1 = 3.2
    for sy in (-1, 1):
        if sy < 0:
            wall(b, (-e1, -e1), (-0.7, -e1), z0, 0.9, 0.35, W)
            wall(b, (0.7, -e1), (e1, -e1), z0, 0.9, 0.35, W)
        else:
            wall(b, (-e1, e1), (e1, e1), z0, 0.9, 0.35, W)
    for sx in (-1, 1):
        wall(b, (sx * e1, -e1), (sx * e1, e1), z0, 0.9, 0.35, W)
        for sy in (-1, 1):
            drum_tower(b, sx * e1, sy * e1, z0, 0.45, 1.3, W, segs=8, team=False, window=False)
    e2, H = 2.0, 2.2
    for sx in (-1, 1):
        wall(b, (sx * e2, -e2), (sx * e2, e2), z0, H, 0.5, W)
    wall(b, (-e2, e2), (e2, e2), z0, H, 0.5, W)
    wall(b, (-e2, -e2), (-0.95, -e2), z0, H, 0.5, W)
    wall(b, (0.95, -e2), (e2, -e2), z0, H, 0.5, W)
    for sx in (-1, 1):
        for sy in (-1, 1):
            drum_tower(b, sx * e2, sy * e2, z0, 0.75, H + 0.8, W, segs=10)
        drum_tower(b, sx * 0.75, -e2 - 0.15, z0, 0.55, H + 0.6, W, segs=10, team=sx < 0)   # twin gatehouse towers
    b.box((0, -e2, z0 + (H + 0.4) / 2), (1.1, 0.8, H + 0.4), W)
    gate(b, 0, -e2 - 0.4, z0, 0.6, 1.0, W)
    for x in (-0.25, 0.25):
        b.banner((x, -e2 - 0.42, z0 + H + 0.3), (0, -1, 0), 0.22, 0.55, "britons")
    cs.hall(b, "britons", (0.0, 0.9, z0), 2.6, 1.3, 1.3, ridge="x", windows=3, door_w=0.5)   # great hall
    cs.flagpole(b, "britons", 2.0, 2.0, z0 + H + 0.8 + 0.2, h=1.6)


def franks(b, z0):
    """Philippe-Auguste castle: a rectangular enceinte of pale limestone with round towers under steep
    pepper-pot slate cones, a tall round donjon, a twin-towered gate; height is what tells the Franks apart."""
    W = "PE_StoneWarm"
    ex, ey, H = 2.8, 2.6, 1.7
    wall(b, (-ex, -ey), (-0.75, -ey), z0, H, 0.45, W)
    wall(b, (0.75, -ey), (ex, -ey), z0, H, 0.45, W)
    wall(b, (-ex, ey), (ex, ey), z0, H, 0.45, W)
    for sx in (-1, 1):
        wall(b, (sx * ex, -ey), (sx * ex, ey), z0, H, 0.45, W)
        for sy in (-1, 1):
            drum_tower(b, sx * ex, sy * ey, z0, 0.62, H + 1.1, W, segs=10, cap=True, cap_h=1.7)
        drum_tower(b, sx * 0.72, -ey - 0.1, z0, 0.45, H + 0.9, W, segs=8, cap=True, cap_h=1.3, team=sx < 0)
    b.box((0, -ey, z0 + (H + 0.3) / 2), (1.0, 0.7, H + 0.3), W)
    gate(b, 0, -ey - 0.35, z0, 0.55, 0.95, W, pointed=True)
    b.banner((0, -ey - 0.37, z0 + H + 0.2), (0, -1, 0), 0.28, 0.6, "franks")
    drum_tower(b, -0.7, 0.9, z0, 1.0, 4.4, W, segs=12, cap=True, cap_h=2.4)                 # donjon
    cs.hall(b, "franks", (1.25, 1.2, z0), 1.6, 1.4, 1.5, ridge="y", windows=2, door_w=0.45, side_windows=0)
    cs.flagpole(b, "franks", -0.7, 0.9, z0 + 4.4 + 2.4 - 0.3, h=1.2)


def teutons(b, z0):
    """Malbork-type Ordensburg: four red-brick wings with steep tile roofs and stepped gables round a court,
    a tall square main tower with a steep pyramid roof, a gate tower, timber hoardings on the outer wall."""
    W, R = "PE_BrickRed", "PE_RoofRed"
    e, H = 3.0, 1.2
    wall(b, (-e, -e), (-0.7, -e), z0, H, 0.4, W)
    wall(b, (0.7, -e), (e, -e), z0, H, 0.4, W)
    for sx in (-1, 1):
        wall(b, (sx * e, -e), (sx * e, e), z0, H, 0.4, W, cren=False)
        b.box((sx * e, 0, z0 + H + 0.22), (0.5, 2 * e, 0.44), "PE_WoodDark")             # hoarding
    wall(b, (-e, e), (e, e), z0, H, 0.4, W, cren=False)
    b.box((0, e, z0 + H + 0.22), (2 * e, 0.5, 0.44), "PE_WoodDark")
    # convent wings round the court: back wing + two side wings, steep roofs, stepped gable ends
    wh, rh = 1.9, 1.2
    b.box((0, 1.6, z0 + wh / 2), (3.8, 1.2, wh), W)
    b.gable_roof((0, 1.6, z0 + wh), 3.8, 1.2, rh, R, overhang=0.1, ridge_axis="x", end_mat=W)
    for sx in (-1, 1):
        b.box((sx * 1.5, -0.3, z0 + wh / 2), (1.0, 2.6, wh), W)
        b.gable_roof((sx * 1.5, -0.3, z0 + wh), 1.0, 2.6, rh * 0.9, R, overhang=0.1, ridge_axis="y", end_mat=W)
        cs._stepped_gables(b, sx * 1.5, -0.3, z0 + wh, 1.0, 2.6, rh * 0.9, "y", W, steps=4)
    cs._stepped_gables(b, 0, 1.6, z0 + wh, 3.8, 1.2, rh, "x", W, steps=4)
    for x in (-0.9, 0, 0.9):
        b.arch_opening((x, 1.0, z0 + 0.9), (0, -1, 0), 0.2, 0.55, "PE_Window", None, segs=3, pointed=True)
    square_tower(b, 1.9, 1.9, z0, 1.1, 4.0, W, roof=R, roof_h=1.7)                         # main tower
    square_tower(b, 0, -e, z0, 1.2, 2.4, W, roof=R, roof_h=0.9)                            # gate tower
    gate(b, 0, -e - 0.6, z0, 0.55, 0.95, W, pointed=True)
    b.banner((0, -e - 0.62, z0 + 2.1), (0, -1, 0), 0.3, 0.6, "teutons")
    cs.flagpole(b, "teutons", 1.9, 1.9, z0 + 5.6, h=1.0)


def japanese(b, z0):
    """Early yamajiro / yakata: earth terrace on a battered ishigaki stone base, a small two-tier wooden tenshu
    in white plaster with dark tile irimoya roofs, a wooden yagura gate and corner yagura, palisade on the bank."""
    STONE, PL, R = "PE_StoneGrey", "PE_PlasterWhite", "PE_RoofDark"
    b.frustum((0.2, 0.6, z0), 4.6, 4.2, 4.0, 3.6, 0.9, STONE, top_mat="PE_Dirt")          # ishigaki terrace
    zt = z0 + 0.9
    # tenshu: stone base, two plastered storeys, two curved hip roofs
    b.frustum((0.5, 1.0, zt), 2.0, 1.8, 1.7, 1.5, 0.45, STONE)
    z1 = zt + 0.45
    b.box((0.5, 1.0, z1 + 0.6), (1.6, 1.4, 1.2), PL)
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.box((0.5 + sx * 0.78, 1.0 + sy * 0.68, z1 + 0.6), (0.07, 0.07, 1.2), "PE_WoodDark")
    b.box((0.5, 0.29, z1 + 0.65), (0.7, 0.03, 0.3), "PE_Lattice")
    b.hip_roof((0.5, 1.0, z1 + 1.2), 1.6, 1.4, 0.5, R, overhang=0.35, curve=0.12)
    z2 = z1 + 1.45
    b.box((0.5, 1.0, z2 + 0.45), (1.1, 0.95, 0.9), PL)
    b.box((0.5, 0.52, z2 + 0.5), (0.5, 0.03, 0.25), "PE_Lattice")
    b.box((0.5, 0.51, z2 + 0.78), (0.8, 0.03, 0.09), "TEAM_Trim")
    b.hip_roof((0.5, 1.0, z2 + 0.9), 1.1, 0.95, 0.55, R, overhang=0.3, curve=0.14)
    b.cylinder((0.5, 1.0, z2 + 1.45), 0.05, 0.18, "PE_Gold", segs=4)
    # palisade along the front edge of the terrace with a yagura gate, corner yagura
    for x0, x1 in ((-2.0, -0.6), (0.6, 2.4)):
        n = int((x1 - x0) / 0.22)
        for i in range(n):
            x = x0 + (i + 0.5) * (x1 - x0) / n
            b.box((x, -1.4, zt + 0.35), (0.12, 0.1, 0.7), "PE_WoodDark")
        b.box(((x0 + x1) / 2, -1.43, zt + 0.55), (x1 - x0, 0.05, 0.08), "PE_WoodLight")
    for sx in (-1, 1):
        b.box((sx * 0.5, -1.45, zt + 0.7), (0.14, 0.14, 1.4), "PE_WoodDark")
    b.box((0, -1.45, zt + 1.3), (1.3, 0.5, 0.35), PL)
    b.hip_roof((0, -1.45, zt + 1.48), 1.3, 0.5, 0.35, R, overhang=0.2, curve=0.1)
    b.banner((0, -1.72, zt + 1.25), (0, -1, 0), 0.26, 0.5, "japanese", tail=False)
    cs.tower(b, "japanese", -1.6, 1.6, zt, 0.9, 1.4)
    # stone steps up the terrace to the gate
    b.stairs((0, -2.15, z0), 1.0, 4, 0.225, 0.2, STONE)
    cs.flagpole(b, "japanese", 1.9, -1.1, zt, h=2.2)


def saracens(b, z0):
    """Ayyubid / Mamluk citadel (Cairo, Aleppo): massive square sandstone towers on sloping glacis bases,
    stepped crenellations, a bent gate reached by a ramp, a teal-domed mosque and a minaret inside."""
    W = "PE_Sandstone"
    e, H = 2.7, 1.9
    b.frustum((0, 0, z0), 2 * e + 1.0, 2 * e + 1.0, 2 * e + 0.5, 2 * e + 0.5, 0.45, W, top_mat="PE_Sandstone")
    zb = z0 + 0.45
    wall(b, (-e, -e), (-0.8, -e), zb, H, 0.5, W, stepped=True)
    wall(b, (0.8, -e), (e, -e), zb, H, 0.5, W, stepped=True)
    wall(b, (-e, e), (e, e), zb, H, 0.5, W, stepped=True)
    for sx in (-1, 1):
        wall(b, (sx * e, -e), (sx * e, e), zb, H, 0.5, W, stepped=True)
        for sy in (-1, 1):
            square_tower(b, sx * e, sy * e, zb, 1.25, H + 1.0, W, glacis=0.45, stepped=True, team=sy < 0)
    square_tower(b, 0, -e, zb, 1.5, H + 0.6, W, glacis=0.3, stepped=True, team=False)    # gate tower
    gate(b, 0, -e - 0.75, zb, 0.6, 1.1, W, pointed=True)
    b.box((0, -e - 0.77, zb + 1.35), (0.9, 0.03, 0.12), "PE_TileTeal")
    b.box((0, -e - 0.77, zb + 1.55), (0.7, 0.03, 0.1), "TEAM_Trim")
    b.quad((-0.45, -3.6, z0 - 0.02), (0.45, -3.6, z0 - 0.02), (0.45, -e - 0.75, zb), (-0.45, -e - 0.75, zb), W)
    b.banner((0, -e - 0.77, zb + H + 0.35), (0, -1, 0), 0.32, 0.6, "saracens")
    # mosque with a teal dome + minaret
    b.box((-0.5, 0.9, zb + 0.7), (1.8, 1.5, 1.4), W)
    b.box((-0.5, 0.9, zb + 1.32), (1.83, 1.53, 0.1), "PE_TileTeal")
    b.cylinder((-0.5, 0.9, zb + 1.4), 0.55, 0.3, W, segs=10, smooth=False)
    b.dome((-0.5, 0.9, zb + 1.7), 0.57, "PE_TileTeal", segs=10, rings=3, smooth=False)
    b.cylinder((-0.5, 0.9, zb + 2.25), 0.02, 0.25, "PE_Gold", segs=4)
    parts.saracen_minaret(b, (1.2, 1.2, zb), height=3.4)
    cs.flagpole(b, "saracens", e, -e, zb + H + 1.0 + 0.4, h=1.3)


def vikings(b, z0):
    """Trelleborg ring fortress: a circular earth rampart faced with timber and topped by a palisade, four
    gates at the cardinal points, longhouses inside. No stone (docs: 'No stone castles')."""
    R0, R1, Rt, H, n = 3.3, 2.5, 2.85, 0.75, 20
    gate_a = [0, math.pi / 2, math.pi, 3 * math.pi / 2]

    def is_gate(a):
        return any(abs((a - g + math.pi) % (2 * math.pi) - math.pi) < 0.2 for g in gate_a)
    for i in range(n):
        a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
        am = (a0 + a1) / 2
        if is_gate(am):
            continue
        c0, s0, c1, s1 = math.cos(a0), math.sin(a0), math.cos(a1), math.sin(a1)
        ob0, ob1 = (R0 * c0, R0 * s0, z0), (R0 * c1, R0 * s1, z0)
        ot0, ot1 = (Rt * 1.07 * c0, Rt * 1.07 * s0, z0 + H), (Rt * 1.07 * c1, Rt * 1.07 * s1, z0 + H)
        it0, it1 = (Rt * 0.93 * c0, Rt * 0.93 * s0, z0 + H), (Rt * 0.93 * c1, Rt * 0.93 * s1, z0 + H)
        ib0, ib1 = (R1 * c0, R1 * s0, z0), (R1 * c1, R1 * s1, z0)
        b.quad(ob0, ob1, ot1, ot0, "PE_WoodDark")             # timber-faced outer bank
        b.quad(ot0, ot1, it1, it0, "PE_Grass")                # turf top
        b.quad(it0, it1, ib1, ib0, "PE_Grass")                # inner slope
        for k in range(2):                                    # palisade stakes on the crest
            a = a0 + (k + 0.5) * (a1 - a0) / 2
            px, py = Rt * 1.04 * math.cos(a), Rt * 1.04 * math.sin(a)
            b.cylinder((px, py, z0 + H), 0.11, 0.6, "PE_WoodDark", segs=4, cap=False, smooth=False)
            b.cone((px, py, z0 + H + 0.6), 0.11, 0.2, "PE_WoodLight", segs=4, smooth=False)
    for g in gate_a:                                          # timber gate posts + lintel
        gx, gy = math.cos(g) * Rt, math.sin(g) * Rt
        ax, ay = -math.sin(g) * 0.45, math.cos(g) * 0.45
        for s in (-1, 1):
            b.box((gx + s * ax, gy + s * ay, z0 + 0.7), (0.18, 0.18, 1.4), "PE_WoodDark")
        b.box((gx, gy, z0 + 1.4), (abs(ax) * 2 + 0.3, abs(ay) * 2 + 0.3, 0.14), "PE_WoodDark")
    gx, gy = 0, -Rt
    b.box((0.0, -Rt - 0.1, z0 + 1.2), (0.6, 0.03, 0.12), "TEAM_Trim")
    parts.round_shield(b, (0.0, -Rt - 0.12, z0 + 0.95), (0, -1, 0), r=0.16)
    # longhouses in the four quadrants (two shown fully, the court keeps the gates readable)
    for x, y in ((-1.05, 0.9), (1.05, 0.9)):
        cs.hall(b, "vikings", (x, y, z0), 1.5, 0.9, 0.7, ridge="y", windows=0, door_w=0.35, side_windows=0)
    cs.hall(b, "vikings", (0.0, -1.0, z0), 1.4, 0.8, 0.65, ridge="x", windows=1, door_w=0.35, side_windows=0)
    cs.flagpole(b, "vikings", 0.0, 0.2, z0, h=2.4)


def chinese(b, z0):
    """City gate: a thick brick-faced rammed-earth wall with crenels, a two-storey chenglou gate tower in red
    lacquer under teal double-eaved roofs, a semicircular barbican (wengcheng) in front, corner pavilions."""
    W = "PE_StoneGrey"
    H, T = 1.7, 1.1
    yw = 0.3
    b.box((-2.05, yw, z0 + H / 2), (3.1, T, H), W)
    b.box((2.05, yw, z0 + H / 2), (3.1, T, H), W)
    b.box((0, yw, z0 + H / 2), (1.0, T, H), W)
    gate(b, 0, yw - T / 2, z0, 0.7, 1.15, W)
    for x0, x1 in ((-3.55, -0.55), (0.55, 3.55)):
        wall(b, (x0, yw - T / 2 + 0.07), (x1, yw - T / 2 + 0.07), z0 + H, 0.0, 0.14, W)
    for sx in (-1, 1):
        b.box((sx * 3.3, yw + 1.6, z0 + H * 0.45), (0.8, 2.2, H * 0.9), W)                # side walls going back
        cs.tower(b, "chinese", sx * 3.0, yw, z0 + H - 0.9, 1.0, 1.4, team=sx < 0)
    # chenglou: two lacquered storeys, double eaves
    zt = z0 + H
    for sx in (-1, 0, 1):
        for sy in (-1, 1):
            b.box((sx * 0.95, yw + sy * 0.4, zt + 0.5), (0.1, 0.1, 1.0), "PE_LacquerRed")
    b.box((0, yw + 0.4, zt + 0.5), (2.0, 0.08, 1.0), "PE_LacquerRed")
    b.box((0, yw - 0.38, zt + 0.55), (1.6, 0.03, 0.45), "PE_Lattice")
    b.hip_roof((0, yw, zt + 1.0), 2.2, 1.0, 0.45, "PE_RoofTeal", overhang=0.35, curve=0.15, under_mat="PE_LacquerRed")
    b.box((0, yw, zt + 1.55), (1.5, 0.7, 0.6), "PE_LacquerRed")
    b.box((0, yw - 0.36, zt + 1.55), (1.1, 0.03, 0.3), "PE_Lattice")
    b.box((0, yw - 0.37, zt + 1.3), (1.2, 0.03, 0.1), "TEAM_Trim")
    b.hip_roof((0, yw, zt + 1.85), 1.6, 0.8, 0.55, "PE_RoofTeal", overhang=0.3, curve=0.18, under_mat="PE_LacquerRed")
    b.cone((0, yw, zt + 2.4), 0.07, 0.25, "PE_Gold", segs=5, smooth=False)
    # wengcheng barbican: semicircle of wall segments in front, gate on its side
    R, n = 1.9, 7
    cy = yw - T / 2
    pts = [(R * math.cos(math.pi + math.pi * k / n), cy + R * 1.05 * math.sin(math.pi + math.pi * k / n)) for k in range(n + 1)]
    for k in range(n):
        if k == 1:
            continue                                           # side gate of the barbican
        wall(b, pts[k], pts[k + 1], z0, H * 0.7, 0.5, W)
    b.banner((0, cy - 0.02, z0 + H - 0.1), (0, -1, 0), 0.32, 0.6, "chinese")
    cs.flagpole(b, "chinese", 1.5, yw + 0.2, zt, h=2.2)


BUILDERS = {"ottomans": ottomans, "byzantines": byzantines, "britons": britons, "franks": franks,
            "teutons": teutons, "japanese": japanese, "saracens": saracens, "vikings": vikings, "chinese": chinese}
