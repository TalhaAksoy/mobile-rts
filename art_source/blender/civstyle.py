"""Civilisation building kit: one architectural vocabulary per civ, shared by every building type
(barracks, archery range, stable, blacksmith, camps, towers, castle).

Each civ has a STYLE (wall / base / roof materials, roof form, window form, tower form, fence) taken
from ART_DIRECTION_BIBLE §6. Building scripts compose `hall()`, `tower()`, `ger()` and the props
below, so a building type keeps one recognisable layout for every civ (gameplay readability) while
the civ shows in masonry, roof form and silhouette markers.

Coordinates: Blender Z up, the front (camera side) is -Y. `z` arguments are the ground-pad top.
"""
import math
import parts

STYLES = {
    "ottomans": dict(wall="PE_PlasterCream", base="PE_StoneWarm", roof="hip", roof_mat="PE_RoofRed", pitch=0.5,
                     pointed=True, win_frame="PE_StoneWarm", tower="ottoman", fence="PE_WoodDark"),
    "byzantines": dict(wall="PE_StoneWarm", base="PE_StoneBrick", bands="PE_StoneBrick", roof="gable",
                       roof_mat="PE_RoofRed", pitch=0.4, win_frame="PE_StoneBrick", tower="byzantine", fence="PE_WoodDark"),
    "britons": dict(wall="PE_PlasterWhite", base="PE_StoneGrey", frame="PE_Beam", roof="gable", roof_mat="PE_Thatch",
                    pitch=0.85, win_frame="PE_Beam", tower="round", fence="PE_Beam"),
    "franks": dict(wall="PE_StoneWarm", base="PE_StoneGrey", roof="hip", roof_mat="PE_RoofSlate", pitch=1.0,
                   pointed=True, win_frame="PE_StoneGrey", tower="spire", fence="PE_WoodDark"),
    "teutons": dict(wall="PE_StoneGrey", base="PE_StoneGrey", roof="gable", roof_mat="PE_SlateDark", pitch=1.05,
                    stepped=True, win_frame="PE_StoneGrey", tower="bergfried", fence="PE_WoodDark"),
    "japanese": dict(wall="PE_PlasterWhite", base="PE_StoneGrey", frame="PE_WoodDark", roof="irimoya",
                     roof_mat="PE_RoofDark", pitch=0.7, lattice=True, tower="yagura", fence="bamboo"),
    "chinese": dict(wall="PE_StoneGrey", base="PE_StoneGrey", columns="PE_LacquerRed", roof="hip_curve",
                    roof_mat="PE_RoofTeal", pitch=0.65, lattice=True, tower="pavilion", fence="PE_LacquerRed"),
    "saracens": dict(wall="PE_Sandstone", base="PE_Sandstone", roof="flat", accent="PE_TileTeal", pointed=True,
                     win_frame="PE_TileTeal", tower="saracen", fence="PE_WoodDark"),
    "vikings": dict(wall="PE_WoodDark", base="PE_StoneGrey", planks="PE_WoodLight", roof="gable", roof_mat="PE_Shingle",
                    pitch=1.1, gable_boards=True, win_frame="PE_WoodLight", tower="timber", fence="PE_WoodDark"),
    "mongols": dict(wall="PE_Felt", base="PE_FeltBlue", roof="ger", roof_mat="PE_Felt", tower="mongol", fence="PE_WoodDark"),
}


def style(civ):
    return STYLES[civ]


# ---------------------------------------------------------------- openings
def window(b, civ, pos, facing, w, h):
    s = STYLES[civ]
    x, y, z = pos
    if s.get("lattice"):
        if facing[1]:
            b.box((x, y + facing[1] * 0.015, z + h / 2), (w, 0.03, h), "PE_Lattice")
        else:
            b.box((x + facing[0] * 0.015, y, z + h / 2), (0.03, w, h), "PE_Lattice")
        return
    b.arch_opening(pos, facing, w, h, "PE_Window", s.get("win_frame"), depth=0.03, frame=0.05, segs=4,
                   pointed=s.get("pointed", False))


def door(b, civ, pos, w, h, facing=(0, -1, 0)):
    s = STYLES[civ]
    if civ == "mongols":
        x, y, z = pos
        b.box((x, y - 0.03, z + h / 2), (w, 0.06, h), "PE_LacquerRed")
        return
    b.arch_opening(pos, facing, w, h, "PE_WoodDark", s.get("win_frame") or s["base"], depth=0.05, frame=0.08,
                   segs=5, pointed=s.get("pointed", False))


# ---------------------------------------------------------------- ger (Mongols)
def ger(b, x, y, z, r, wall_h=None, team=True, door_dir=(0, -1)):
    """Felt ger: white felt wall + dome, blue skirt, rope bands, toono crown, red door."""
    wh = wall_h or r * 0.72
    segs = 14
    b.cylinder((x, y, z), r + 0.03, 0.12, "PE_FeltBlue", segs=segs, cap=False, smooth=False)
    b.cylinder((x, y, z + 0.12), r, wh - 0.12, "PE_Felt", segs=segs, cap=False, smooth=False)
    if team:
        b.cylinder((x, y, z + wh * 0.55), r + 0.015, 0.1, "TEAM_Trim", segs=segs, cap=False, smooth=False)
    b.dome((x, y, z + wh), r + 0.06, "PE_Felt", segs=segs, rings=3, height=r * 0.55, smooth=False, top_hole=r * 0.2)
    for i in range(7):
        a = i / 7 * math.tau + 0.2
        p0 = (x + math.cos(a) * (r + 0.07), y + math.sin(a) * (r + 0.07), z + wh + 0.01)
        p1 = (x + math.cos(a) * r * 0.26, y + math.sin(a) * r * 0.26, z + wh + r * 0.5)
        b.cylinder_between(p0, p1, 0.02, "PE_WoodDark", segs=4, smooth=False)
    b.cylinder((x, y, z + wh + r * 0.48), r * 0.26, 0.07, "PE_WoodDark", segs=10, smooth=False)
    dx, dy = door_dir
    dw, dh = min(0.5, r * 0.45), min(0.75, wh * 0.85)
    b.box((x + dx * (r + 0.02), y + dy * (r + 0.02), z + dh / 2), (dw if dy else 0.06, 0.06 if dy else dw, dh), "PE_LacquerRed")
    return z + wh + r * 0.55


# ---------------------------------------------------------------- roofs
def roof(b, civ, c, w, d, ridge="x", rh=None, overhang=0.2, end_mat=None):
    """Civ roof over a w x d block whose wall top is at c[2]. Returns the roof's top z."""
    s = STYLES[civ]
    cx, cy, z = c
    kind = s["roof"]
    mat = s.get("roof_mat")
    rh = rh if rh is not None else s.get("pitch", 0.6) * min(w, d) / 2 * 1.4
    gend = end_mat or s.get("wall")
    if kind == "gable":
        b.gable_roof((cx, cy, z), w, d, rh, mat, overhang=overhang, ridge_axis=ridge, ridge_mat=mat)
        b.gable_end((cx, cy, z), w, d, rh, gend, ridge_axis=ridge)
        if s.get("stepped"):
            _stepped_gables(b, cx, cy, z, w, d, rh, ridge, s["base"])
        if s.get("gable_boards"):
            _gable_boards(b, cx, cy, z, w, d, rh, ridge, overhang)
        return z + rh
    if kind == "hip":
        b.hip_roof((cx, cy, z), w, d, rh, mat, overhang=overhang)
        return z + rh
    if kind == "hip_curve":
        b.hip_roof((cx, cy, z), w, d, rh, mat, overhang=overhang + 0.08, curve=0.16, under_mat="PE_LacquerRed")
        long_x = w >= d
        r = abs(w - d) / 2
        a = (cx - r, cy, z + rh) if long_x else (cx, cy - r, z + rh)
        e = (cx + r, cy, z + rh) if long_x else (cx, cy + r, z + rh)
        if r > 0.05:
            b.cylinder_between(a, e, 0.06, mat, segs=6)
        for p in (a, e):
            b.cone(p, 0.08, 0.28, "PE_Gold", segs=5, smooth=False)
        return z + rh + 0.2
    if kind == "irimoya":
        b.hip_roof((cx, cy, z), w, d, rh, mat, overhang=overhang + 0.1, curve=0.1)
        gz = z + rh * 0.8
        gw, gd = (w * 0.7, d * 0.36) if w >= d else (w * 0.36, d * 0.7)
        gax = "x" if w >= d else "y"
        b.gable_roof((cx, cy, gz), gw, gd, rh * 0.55, mat, overhang=0.1, ridge_axis=gax, ridge_mat=mat)
        b.box((cx, cy, gz - 0.06), (gw, gd, 0.14), "PE_WoodDark")
        b.gable_end((cx, cy, gz), gw, gd, rh * 0.55, "PE_PlasterWhite", ridge_axis=gax)
        return gz + rh * 0.55
    if kind == "flat":
        t = 0.09
        b.box((cx, cy, z + 0.04), (w + 0.04, d + 0.04, 0.08), s["wall"])
        for sy in (-1, 1):
            parts.crenellations(b, cx - w / 2 + 0.05, cx + w / 2 - 0.05, cy + sy * (d / 2 - t), z + 0.08, depth=t * 2,
                                merlon_w=0.2, gap=0.18, h=0.2, mat=s["wall"])
        for sx in (-1, 1):
            parts.crenellations(b, cy - d / 2 + 0.2, cy + d / 2 - 0.2, cx + sx * (w / 2 - t), z + 0.08, depth=t * 2,
                                merlon_w=0.2, gap=0.18, h=0.2, mat=s["wall"], axis="y")
        return z + 0.28
    raise ValueError("no roof for " + kind)


def _stepped_gables(b, cx, cy, z, w, d, rh, ridge, mat, steps=5):
    if ridge == "y":
        for sy in (-1, 1):
            for i in range(steps):
                ww = (w + 0.2) * (1 - i / steps)
                b.box((cx, cy + sy * (d / 2 + 0.06), z + (i + 0.5) * rh / steps), (ww, 0.18, rh / steps + 0.02), mat)
    else:
        for sx in (-1, 1):
            for i in range(steps):
                dd = (d + 0.2) * (1 - i / steps)
                b.box((cx + sx * (w / 2 + 0.06), cy, z + (i + 0.5) * rh / steps), (0.18, dd, rh / steps + 0.02), mat)


def _gable_boards(b, cx, cy, z, w, d, rh, ridge, overhang):
    half = (d if ridge == "x" else w) / 2
    for se in (-1, 1):
        for ss in (-1, 1):
            if ridge == "x":
                x = cx + se * (w / 2 + overhang)
                p0 = (x, cy + ss * half * 0.6, z + rh * 0.4 + 0.05)
                p1 = (x, cy - ss * 0.2, z + rh + 0.3)
                head = (x, cy - ss * 0.25, z + rh + 0.36)
                hs = (0.08, 0.18, 0.1)
            else:
                y = cy + se * (d / 2 + overhang)
                p0 = (cx + ss * half * 0.6, y, z + rh * 0.4 + 0.05)
                p1 = (cx - ss * 0.2, y, z + rh + 0.3)
                head = (cx - ss * 0.25, y, z + rh + 0.36)
                hs = (0.18, 0.08, 0.1)
            b.cylinder_between(p0, p1, 0.05, "PE_WoodDark", segs=4, smooth=False)
            b.box(head, hs, "PE_LacquerRed")


# ---------------------------------------------------------------- walls
def hall(b, civ, c, w, d, h, ridge="x", windows=3, door_w=0.6, door_x=0.0, side_windows=1, rh=None,
         roof_overhang=0.2, team_band=True):
    """Civ hall: plinth, walls with civ surface detail, windows, door, civ roof. Returns roof top z.
    Mongols get a ger whose radius fits the block."""
    s = STYLES[civ]
    cx, cy, z = c
    if civ == "mongols":
        return ger(b, cx, cy, z, min(w, d) / 2, wall_h=min(h, 1.0))
    b.box((cx, cy, z + 0.12), (w + 0.08, d + 0.08, 0.24), s["base"])
    b.box((cx, cy, z + h / 2), (w, d, h), s["wall"])
    fy = cy - d / 2
    if s.get("bands"):
        for zz in (h * 0.38, h * 0.72):
            b.box((cx, cy, z + zz), (w + 0.03, d + 0.03, 0.08), s["bands"])
    if s.get("frame"):
        fm = s["frame"]
        n = max(2, int(w / 0.6))
        for i in range(n + 1):
            b.box((cx - w / 2 + i * w / n, fy - 0.015, z + h / 2), (0.08, 0.03, h), fm)
        b.box((cx, fy - 0.015, z + h - 0.05), (w + 0.04, 0.03, 0.09), fm)
        b.box((cx, fy - 0.015, z + h * 0.5), (w, 0.03, 0.07), fm)
        for sx in (-1, 1):
            b.box((cx + sx * (w / 2 + 0.015), cy, z + h - 0.05), (0.03, d, 0.09), fm)
            for yy in (-d / 2, 0.0, d / 2):
                b.box((cx + sx * (w / 2 + 0.015), cy + yy, z + h / 2), (0.03, 0.08, h), fm)
    if s.get("planks"):
        n = max(3, int(w / 0.32))
        for i in range(n + 1):
            b.box((cx - w / 2 + i * w / n, fy - 0.015, z + h / 2), (0.06, 0.03, h), s["planks"])
    if s.get("columns"):
        n = max(2, int(w / 0.9))
        for i in range(n + 1):
            b.box((cx - w / 2 + i * w / n, fy - 0.08, z + h / 2), (0.11, 0.11, h), s["columns"])
        b.box((cx, fy - 0.08, z + h - 0.07), (w + 0.08, 0.12, 0.14), s["columns"])
    if s.get("accent") and s["roof"] == "flat":
        b.box((cx, fy - 0.012, z + h - 0.18), (w, 0.03, 0.08), s["accent"])
    # windows (skip the door slot)
    ww, wh = 0.26, min(0.5, h * 0.32)
    slots = [cx - w / 2 + (i + 0.5) * w / windows for i in range(windows)]
    for x in slots:
        if door_w and abs(x - (cx + door_x)) < door_w * 0.8:
            continue
        window(b, civ, (x, fy, z + h * 0.42), (0, -1, 0), ww, wh)
    for sx in (-1, 1):
        for j in range(side_windows):
            yy = cy - d / 2 + (j + 0.5) * d / side_windows
            window(b, civ, (cx + sx * w / 2, yy, z + h * 0.42), (sx, 0, 0), ww, wh)
    if door_w:
        door(b, civ, (cx + door_x, fy, z), door_w, min(h * 0.62, 1.1))
    if team_band:
        b.box((cx, fy - 0.03, z + h - 0.3), (min(w * 0.5, 1.2), 0.03, 0.1), "TEAM_Trim")
    top = roof(b, civ, (cx, cy, z + h), w, d, ridge=ridge, rh=rh, overhang=roof_overhang)
    if civ == "ottomans" and w >= 2.4:          # lead-domed cupola on the ridge (Ottoman marker)
        ux = cx + min(w * 0.22, max(0.0, (w - d) / 2))
        b.box((ux, cy, top - 0.05), (0.42, 0.42, 0.34), "PE_PlasterCream")
        b.dome((ux, cy, top + 0.12), 0.26, "PE_DomeLead", segs=10, rings=3, smooth=False)
        b.cylinder((ux, cy, top + 0.36), 0.02, 0.2, "PE_Gold", segs=4)
        top += 0.5
    return top


# ---------------------------------------------------------------- towers
def tower(b, civ, x, y, z, size, h, team=True):
    """Civ tower with footprint `size` (m) and wall height h. Returns top z."""
    s = STYLES[civ]
    kind = s["tower"]
    r = size / 2
    if kind == "ottoman":
        b.cylinder((x, y, z), r * 1.1, 0.3, "PE_StoneWarm", segs=10, cap=False, smooth=False)
        b.cylinder((x, y, z + 0.3), r, h - 0.3, "PE_PlasterCream", segs=10, cap=False, smooth=False)
        b.cylinder((x, y, z + h), r * 1.18, 0.08, "PE_WoodDark", segs=10, smooth=False)
        if team:
            b.cylinder((x, y, z + h - 0.3), r * 1.02, 0.12, "TEAM_Trim", segs=10, cap=False, smooth=False)
        window(b, civ, (x, y - r, z + h * 0.55), (0, -1, 0), r * 0.5, r * 0.9)
        b.cone((x, y, z + h + 0.08), r * 1.2, r * 3.0, "PE_DomeLead", segs=10, smooth=False)
        b.cylinder((x, y, z + h + 0.08 + r * 3.0 - 0.04), 0.02, 0.25, "PE_Gold", segs=4)
        return z + h + r * 3.0
    if kind == "byzantine":
        b.box((x, y, z + h / 2), (size, size, h), "PE_StoneWarm")
        for zz in (h * 0.3, h * 0.6, h * 0.9):
            b.box((x, y, z + zz), (size + 0.03, size + 0.03, 0.08), "PE_StoneBrick")
        window(b, civ, (x, y - r, z + h * 0.62), (0, -1, 0), size * 0.3, size * 0.45)
        if team:
            b.box((x, y - r - 0.015, z + h * 0.45), (size * 0.6, 0.03, 0.1), "TEAM_Trim")
        b.cylinder((x, y, z + h), r * 0.75, 0.2, "PE_StoneWarm", segs=10, smooth=False)
        b.dome((x, y, z + h + 0.2), r * 0.78, "PE_RoofRed", segs=10, rings=3, smooth=False)
        b.cylinder((x, y, z + h + 0.2 + r * 0.75), 0.02, 0.22, "PE_Gold", segs=4)
        return z + h + 0.2 + r * 0.8
    if kind in ("round", "spire"):
        wall = "PE_StoneGrey" if kind == "round" else "PE_StoneWarm"
        cap = r * 2.4 if kind == "round" else r * 4.0
        parts.round_tower(b, (x, y, z), r, h, wall_mat=wall, roof_mat="PE_RoofSlate", cap_h=cap, team_band=team)
        return z + h + cap
    if kind == "bergfried":
        b.box((x, y, z + h / 2), (size, size, h), "PE_StoneGrey")
        b.box((x, y, z + h + 0.06), (size + 0.16, size + 0.16, 0.12), "PE_StoneGrey")
        for sy in (-1, 1):
            parts.crenellations(b, x - r - 0.04, x + r + 0.04, y + sy * (r + 0.02), z + h + 0.12, depth=0.14,
                                merlon_w=0.14, gap=0.12, h=0.18, mat="PE_StoneGrey")
        for sx in (-1, 1):
            parts.crenellations(b, y - r + 0.1, y + r - 0.1, x + sx * (r + 0.02), z + h + 0.12, depth=0.14,
                                merlon_w=0.14, gap=0.12, h=0.18, mat="PE_StoneGrey", axis="y")
        window(b, civ, (x, y - r, z + h * 0.6), (0, -1, 0), size * 0.22, size * 0.4)
        if team:
            b.box((x, y - r - 0.015, z + h * 0.85), (size * 0.7, 0.03, 0.12), "TEAM_Trim")
        parts.square_spire(b, (x, y), size * 0.62, r * 3.2, "PE_SlateDark", z + h + 0.12)
        return z + h + r * 3.2
    if kind == "yagura":
        b.frustum((x, y, z), size * 1.2, size * 1.2, size * 1.0, size * 1.0, h * 0.3, "PE_StoneGrey")
        zb = z + h * 0.3
        b.box((x, y, zb + h * 0.35), (size * 0.92, size * 0.92, h * 0.7), "PE_PlasterWhite")
        for sx in (-1, 1):
            for sy in (-1, 1):
                b.box((x + sx * size * 0.44, y + sy * size * 0.44, zb + h * 0.35), (0.08, 0.08, h * 0.7), "PE_WoodDark")
        b.box((x, y - size * 0.47, zb + h * 0.45), (size * 0.5, 0.03, h * 0.18), "PE_Lattice")
        if team:
            b.box((x, y - size * 0.47, zb + h * 0.62), (size * 0.8, 0.03, 0.1), "TEAM_Trim")
        b.hip_roof((x, y, zb + h * 0.7), size * 0.92, size * 0.92, size * 0.5, "PE_RoofDark", overhang=0.22, curve=0.1)
        return zb + h * 0.7 + size * 0.5
    if kind == "pavilion":
        b.box((x, y, z + h * 0.35), (size, size, h * 0.7), "PE_StoneGrey")
        zb = z + h * 0.7
        for sx in (-1, 1):
            for sy in (-1, 1):
                b.box((x + sx * r * 0.8, y + sy * r * 0.8, zb + h * 0.18), (0.09, 0.09, h * 0.36), "PE_LacquerRed")
        b.box((x, y, zb + h * 0.18), (size * 0.6, size * 0.6, h * 0.34), "PE_Lattice")
        if team:
            b.box((x, y - size * 0.51, z + h * 0.55), (size * 0.6, 0.03, 0.12), "TEAM_Trim")
        b.hip_roof((x, y, zb + h * 0.36), size, size, size * 0.45, "PE_RoofTeal", overhang=0.22, curve=0.14,
                   under_mat="PE_LacquerRed")
        b.cone((x, y, zb + h * 0.36 + size * 0.45), 0.07, 0.25, "PE_Gold", segs=5, smooth=False)
        return zb + h * 0.36 + size * 0.45
    if kind == "saracen":
        b.box((x, y, z + h / 2), (size, size, h), "PE_Sandstone")
        b.box((x, y, z + h - 0.15), (size + 0.04, size + 0.04, 0.09), "PE_TileTeal")
        for sy in (-1, 1):
            parts.crenellations(b, x - r + 0.05, x + r - 0.05, y + sy * (r - 0.06), z + h, depth=0.12, merlon_w=0.13,
                                gap=0.1, h=0.18, mat="PE_Sandstone")
        window(b, civ, (x, y - r, z + h * 0.55), (0, -1, 0), size * 0.25, size * 0.45)
        if team:
            b.box((x, y - r - 0.015, z + h * 0.35), (size * 0.6, 0.03, 0.1), "TEAM_Trim")
        b.cylinder((x, y, z + h), r * 0.55, 0.15, "PE_Sandstone", segs=8, smooth=False)
        b.dome((x, y, z + h + 0.15), r * 0.58, "PE_TileTeal", segs=8, rings=3, smooth=False)
        b.cylinder((x, y, z + h + 0.15 + r * 0.55), 0.02, 0.22, "PE_Gold", segs=4)
        return z + h + 0.15 + r * 0.6
    if kind == "timber":
        for sx in (-1, 1):
            for sy in (-1, 1):
                b.box((x + sx * r * 0.8, y + sy * r * 0.8, z + h / 2), (0.14, 0.14, h), "PE_WoodDark")
        for zz in (h * 0.35, h * 0.7):
            b.box((x, y, z + zz), (size * 0.85, size * 0.85, 0.06), "PE_WoodLight")
        b.box((x, y, z + h - 0.2), (size, size, 0.4), "PE_WoodDark")
        for i in range(5):
            b.box((x - r + 0.1 + i * (size - 0.2) / 4, y - r - 0.015, z + h - 0.2), (0.05, 0.03, 0.4), "PE_WoodLight")
        if team:
            parts.round_shield(b, (x, y - r - 0.02, z + h - 0.2), (0, -1, 0), r=0.15)
        b.pyramid_roof((x, y, z + h), size + 0.1, size + 0.1, size * 0.7, "PE_Shingle", overhang=0.12)
        return z + h + size * 0.7
    if kind == "mongol":
        for sx in (-1, 1):
            for sy in (-1, 1):
                b.cylinder_between((x + sx * r, y + sy * r, z), (x + sx * r * 0.6, y + sy * r * 0.6, z + h), 0.06,
                                   "PE_WoodDark", segs=5, smooth=False)
        b.box((x, y, z + h), (size * 0.8, size * 0.8, 0.08), "PE_WoodDark")
        b.cylinder((x, y, z + h + 0.04), r * 0.7, 0.4, "PE_Felt", segs=10, cap=False, smooth=False)
        if team:
            b.cylinder((x, y, z + h + 0.2), r * 0.71, 0.08, "TEAM_Trim", segs=10, cap=False, smooth=False)
        b.cone((x, y, z + h + 0.44), r * 0.8, r * 1.1, "PE_Felt", segs=10, smooth=False)
        return z + h + 0.44 + r * 1.1
    raise ValueError(kind)


# ---------------------------------------------------------------- props
def fence(b, civ, x0, x1, y, z, h=0.45, axis="x"):
    s = STYLES[civ]
    mat = s.get("fence", "PE_WoodDark")
    n = max(2, int(abs(x1 - x0) / 0.4))
    for i in range(n + 1):
        t = x0 + (x1 - x0) * i / n
        p = (t, y) if axis == "x" else (y, t)
        if mat == "bamboo":
            b.cylinder((p[0], p[1], z), 0.035, h + 0.1, "PE_WoodLight", segs=5, smooth=False)
        else:
            parts.timber_post(b, (p[0], p[1], z), h, s=0.07, mat=mat)
    rail = "PE_WoodDark" if mat == "bamboo" else mat
    mid = (x0 + x1) / 2
    for zz in (h * 0.8, h * 0.4):
        if axis == "x":
            b.box((mid, y, z + zz), (abs(x1 - x0), 0.05, 0.06), rail)
        else:
            b.box((y, mid, z + zz), (0.05, abs(x1 - x0), 0.06), rail)


def weapon_rack(b, x, y, z, n=5, tip="PE_Iron"):
    b.box((x, y, z + 0.55), (0.18 * n, 0.08, 0.06), "PE_WoodDark")
    for k in range(n):
        xx = x - 0.09 * (n - 1) + k * 0.18
        b.cylinder((xx, y + 0.03, z), 0.02, 1.15, "PE_WoodDark", segs=4, cap=False)
        b.cone((xx, y + 0.03, z + 1.15), 0.035, 0.14, tip, segs=4, smooth=False)


def dummy(b, x, y, z, mat="PE_Felt"):
    parts.timber_post(b, (x, y, z), 1.0, s=0.08)
    b.box((x, y, z + 0.8), (0.55, 0.07, 0.07), "PE_WoodDark")
    b.cylinder((x, y, z + 0.5), 0.13, 0.35, mat, segs=6)


def target(b, x, y, z, r=0.4, face=(0, -1)):
    """Archery butt: upright straw disc on an A-frame stand, facing -Y (the camera)."""
    zc = z + r + 0.3
    for sx in (-1, 1):
        b.cylinder_between((x + sx * r * 0.8, y + 0.25, z), (x + sx * r * 0.45, y + 0.08, zc + r * 0.6), 0.03, "PE_WoodDark",
                           segs=4, smooth=False)
    # the butt leans back ~40 degrees so its face reads from the high RTS camera
    import mathutils
    n = mathutils.Vector((0, -0.77, 0.64))
    c = mathutils.Vector((x, y, zc))
    b.cylinder_between(tuple(c - n * 0.1), tuple(c + n * 0.06), r, "PE_Thatch", segs=12, smooth=False, cap=True)
    b.cylinder_between(tuple(c + n * 0.06), tuple(c + n * 0.08), r * 0.6, "PE_ClothRed", segs=12, smooth=False, cap=True)
    b.cylinder_between(tuple(c + n * 0.08), tuple(c + n * 0.1), r * 0.25, "PE_Gold", segs=8, smooth=False, cap=True)


def flagpole(b, civ, x, y, z, h=2.2, size=(0.6, 0.4)):
    b.flag((x, y, z), h, civ, size=size)
    b.box((x, y, z + 0.3), (0.12, 0.12, 0.1), "TEAM_Trim")


def hay(b, x, y, z, s=0.35):
    b.cylinder_between((x - s * 0.6, y, z + s * 0.45), (x + s * 0.6, y, z + s * 0.45), s * 0.45, "PE_Thatch", segs=8, smooth=False, cap=True)


def horse(b, x, y, z, facing=1, coat="PE_WoodDark"):
    """Very simple low-poly standing horse (body, neck, head, 4 legs, tail) facing +X (facing=1) or -X."""
    f = facing
    b.box((x, y, z + 0.62), (0.75, 0.26, 0.3), coat)
    b.cylinder_between((x + f * 0.32, y, z + 0.7), (x + f * 0.48, y, z + 1.0), 0.09, coat, segs=5, smooth=False)
    b.box((x + f * 0.58, y, z + 0.98), (0.26, 0.12, 0.12), coat)
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.box((x + sx * 0.28, y + sy * 0.08, z + 0.24), (0.07, 0.07, 0.48), coat)
    b.cylinder_between((x - f * 0.38, y, z + 0.72), (x - f * 0.5, y, z + 0.38), 0.035, "PE_WoodDark", segs=4, smooth=False)


# ---------------------------------------------------------------- open sheds, walls, carts
def canopy(b, civ, c, w, d, h, ridge="x", back_wall=True):
    """Open-fronted shed on posts with the civ roof (Mongols / Saracens: cloth awning)."""
    s = STYLES[civ]
    cx, cy, z = c
    post = s.get("columns") or ("PE_WoodLight" if civ == "vikings" else "PE_WoodDark")
    n = max(1, int(round(w / 1.2)))
    for i in range(n + 1):
        for sy in (-1, 1):
            parts.timber_post(b, (cx - w / 2 + i * w / n, cy + sy * d / 2, z), h, s=0.1, mat=post)
    if back_wall:
        b.box((cx, cy + d / 2, z + h * 0.45), (w, 0.07, h * 0.9), "PE_WoodDark" if s["roof"] != "flat" else s["wall"])
    b.box((cx, cy - d / 2, z + h - 0.05), (w + 0.1, 0.1, 0.1), post)
    b.box((cx, cy + d / 2, z + h - 0.05), (w + 0.1, 0.1, 0.1), post)
    if s["roof"] in ("flat", "ger"):
        cloth = "PE_Felt" if civ == "mongols" else "PE_ClothRed"
        for flip in (False, True):
            q = [(cx - w / 2 - 0.1, cy - d / 2 - 0.1, z + h), (cx + w / 2 + 0.1, cy - d / 2 - 0.1, z + h),
                 (cx + w / 2 + 0.1, cy + d / 2 + 0.05, z + h + 0.3), (cx - w / 2 - 0.1, cy + d / 2 + 0.05, z + h + 0.3)]
            if flip:
                q = [q[1], q[0], q[3], q[2]]
            b.quad(*q, cloth)
        b.box((cx, cy - d / 2 - 0.1, z + h - 0.06), (w + 0.2, 0.03, 0.12), "TEAM_Trim")
        if civ == "mongols":                   # blue felt edging + rope ties: reads as a felt awning, not cloth
            for sx in (-1, 1):
                b.box((cx + sx * (w / 2 + 0.1), cy, z + h + 0.15), (0.06, d + 0.15, 0.08), "PE_FeltBlue")
            b.box((cx, cy + d / 2 + 0.05, z + h + 0.3), (w + 0.2, 0.06, 0.08), "PE_FeltBlue")
        return z + h + 0.3
    b.box((cx, cy - d / 2 - 0.06, z + h - 0.05), (min(w * 0.4, 0.9), 0.03, 0.1), "TEAM_Trim")
    return roof(b, civ, (cx, cy, z + h), w, d, ridge=ridge, rh=s.get("pitch", 0.6) * min(w, d) / 2, overhang=0.18,
                end_mat="PE_WoodDark")


def curtain(b, civ, x0, x1, y, z, h, t=0.4, axis="x"):
    """Castle curtain wall segment with the civ's wall top (crenels / tile cap / palisade)."""
    s = STYLES[civ]
    L = abs(x1 - x0)
    mid = (x0 + x1) / 2
    size = (L, t, h) if axis == "x" else (t, L, h)
    pos = (mid, y, z + h / 2) if axis == "x" else (y, mid, z + h / 2)
    if civ in ("mongols", "vikings"):                       # timber palisade of pointed stakes
        n = max(3, int(L / 0.26))
        for i in range(n):
            tt = x0 + (i + 0.5) * L / n
            px, py = (tt, y) if axis == "x" else (y, tt)
            b.cylinder((px, py, z), 0.13, h, "PE_WoodDark", segs=5, cap=False, smooth=False)
            b.cone((px, py, z + h), 0.13, 0.25, "PE_WoodLight", segs=5, smooth=False)
        return
    wall = s["base"] if s["roof"] not in ("irimoya",) else "PE_PlasterWhite"
    if civ == "chinese":
        wall = "PE_StoneGrey"
    b.box(pos, size, wall)
    if civ == "japanese":
        b.box((pos[0], pos[1], z + 0.25), (size[0] + 0.04, size[1] + 0.04, 0.5), "PE_StoneGrey")
    if s["roof"] in ("irimoya", "hip_curve"):                # tile-capped wall
        capm = s["roof_mat"]
        if axis == "x":
            b.gable_roof((mid, y, z + h), L, t, 0.22, capm, overhang=0.1, ridge_axis="x", ridge_mat=capm)
        else:
            b.gable_roof((y, mid, z + h), t, L, 0.22, capm, overhang=0.1, ridge_axis="y", ridge_mat=capm)
        return
    if axis == "x":
        parts.crenellations(b, x0 + 0.05, x1 - 0.05, y - t / 2 + 0.07, z + h, depth=0.14, merlon_w=0.2, gap=0.16,
                            h=0.22, mat=wall)
    else:
        parts.crenellations(b, min(x0, x1) + 0.05, max(x0, x1) - 0.05, y - t / 2 + 0.07, z + h, depth=0.14,
                            merlon_w=0.2, gap=0.16, h=0.22, mat=wall, axis="y")


def cart(b, x, y, z, load="PE_StoneGrey", load2=None):
    b.box((x, y, z + 0.38), (0.7, 0.45, 0.22), "PE_WoodLight")
    for sx in (-1, 1):
        b.cylinder_between((x + sx * 0.22, y - 0.25, z + 0.2), (x + sx * 0.22, y - 0.29, z + 0.2), 0.2, "PE_WoodDark",
                           segs=8, smooth=False, cap=True)
        b.cylinder_between((x + sx * 0.22, y + 0.25, z + 0.2), (x + sx * 0.22, y + 0.29, z + 0.2), 0.2, "PE_WoodDark",
                           segs=8, smooth=False, cap=True)
    b.dome((x - 0.1, y, z + 0.48), 0.24, load, segs=6, rings=2, height=0.2, smooth=False)
    if load2:
        b.dome((x + 0.16, y + 0.05, z + 0.48), 0.16, load2, segs=6, rings=2, height=0.16, smooth=False)
    b.cylinder_between((x + 0.35, y, z + 0.4), (x + 0.85, y, z + 0.12), 0.025, "PE_WoodDark", segs=4)


def rock_pile(b, x, y, z, mat="PE_StoneGrey", n=4, s=0.22):
    for i in range(n):
        a = i * 2.4
        b.dome((x + math.cos(a) * s * 0.9, y + math.sin(a) * s * 0.7, z), s * (0.9 - 0.12 * i), mat, segs=6, rings=2,
               height=s * 0.8, smooth=False)


def anvil(b, x, y, z):
    b.cylinder((x, y, z), 0.12, 0.3, "PE_WoodDark", segs=6, smooth=False)
    b.box((x, y, z + 0.36), (0.36, 0.14, 0.12), "PE_Iron")
    b.cone((x + 0.2, y, z + 0.36), 0.06, 0.14, "PE_Iron", segs=4, smooth=False)
