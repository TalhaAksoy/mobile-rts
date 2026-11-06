"""Character kit for the 3D units (run inside Blender, usually headless:  blender -b --python build_units.py).

One shared humanoid armature (20 bones) for every civ and role. Every body part is a small low-poly mesh weighted
100 % to one bone (rigid skinning: deterministic, no weight painting, fits the chunky pixel-art look). Parts are
joined into one "Body" mesh with two materials:
  * PE_UnitPalette : a shared 128x128 palette atlas (16x16 swatches of 8x8 px, each lightly dithered). Every face
                     is UV-mapped inside the swatch of its colour, so ALL units share one texture / material.
  * team colour    : faces in the team colour use the palette too, on a reserved swatch (TEAM_SWATCH, bottom-right
                     8x8 px, painted team-0 blue here). The game gives each team a palette copy with its colour
                     in that swatch (FactionArtManager.team_palette_material), so a unit body is ONE surface / material:
                     one draw call (plus its X-ray and shadow passes) instead of two.
Props that the game switches on and off (villager tools, carried cargo) are separate small meshes, named PROP_*.

Animations are authored here once for the shared rig (pose-bone keyframes) and exported as glTF actions:
  idle-loop, walk-loop, attack, gather-loop, build-loop, death        ("-loop" -> Godot sets looping)
The attack depends on the role's weapon: slash (sword, axe), thrust (spear), bow (draw + release), gun (aim + recoil).

Conventions (same as the buildings): 1 unit = 1 m, Z up, the character faces -Y (= Godot +Z, towards the camera),
feet on z = 0, origin at the ground centre.
"""
import bpy, bmesh, math, os, random
from mathutils import Vector, Matrix, Euler

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
GODOT = os.path.join(REPO, "sample_project")
FPS = 24

# ---------------------------------------------------------------------------------------------------------------
# Atlas (256 x 256): flat colour swatches, 16 px pattern cells, 32 px emblem cells
# ---------------------------------------------------------------------------------------------------------------
ATLAS = 256
FLAT_CELL, FLAT_COLS, FLAT_TOP = 8, 32, 0          # rows y 0..63    : 32 x 8 flat swatches
PAT_CELL, PAT_COLS, PAT_TOP = 16, 16, 64           # rows y 64..191  : 16 x 8 patterns
EMB_CELL, EMB_COLS, EMB_TOP = 32, 8, 192           # rows y 192..255 : 8 x 2 emblems
EMBLEM_DIR = os.path.join(REPO, "art_source", "textures", "emblems")
# Team colour swatch: the last emblem cell's bottom-right corner (emblems fill cells 0..9 of 16). Godot fills it with
# each team's colour (keep in sync with FactionArtManager.TEAM_SWATCH: x, y from the top-left, in pixels).
TEAM_SWATCH = (248, 248, 8, 8)
TEAM_PREVIEW = (0.18, 0.52, 0.95)                  # team 0 blue, for Blender previews

PALETTE = {
    # skin / hair
    "skin": "e0a57a", "skin_dark": "b97c55", "skin_pale": "ecc29a", "skin_tan": "c98d5e",
    "hair_black": "2a211c", "hair_brown": "5a3a22", "hair_blond": "c79a52", "hair_red": "9a4a26", "hair_grey": "8c8478",
    "beard_black": "2e2420", "beard_brown": "4e3220", "beard_blond": "b0843e", "beard_red": "8a4222",
    "eye": "1e1612", "mouth": "7a3a2a", "tattoo": "2e5a9a",
    # cloth
    "white": "efe6d2", "cream": "e2d3ae", "linen": "d8c9a4", "grey_cloth": "8e8a84", "black_cloth": "2c2a2c",
    "red": "b8262a", "red_dark": "7e1a1e", "red_bright": "d8403a", "crimson": "9a1f2a",
    "blue": "2a4f9c", "blue_dark": "1c3166", "navy": "1f2a44", "sky": "6f9fd0", "royal": "2c46a8",
    "green": "2f6b3a", "green_dark": "1d4527", "teal": "2d7a70", "green_bright": "3f8a4a",
    "purple": "6e2a6a", "purple_dark": "47183f", "violet": "8a3a86",
    "yellow": "e2b23a", "orange": "d0782e",
    "brown": "6b4426", "brown_dark": "45291a", "brown_light": "93653c", "tan": "b98a58", "leather": "7a4a26",
    "fur": "d9cdb4", "fur_dark": "8a7a64", "fur_grey": "9c958c", "fur_wolf": "a8a299", "fur_brown": "7e5a38",
    "straw": "d4b46a", "straw_dark": "a8843e",
    # metal / wood
    "iron": "8f959b", "iron_dark": "5a5f66", "steel": "c3c9cf", "gold": "e0b048", "gold_dark": "a87a2a",
    "bronze": "b07a3a", "wood": "8a5a32", "wood_dark": "5e3a1e", "string": "e8e0c8", "black_lacquer": "26201e",
    "red_lacquer": "a82a24",
    "log": "7a5232", "log_end": "c79a62", "stone": "9a968e", "gold_ore": "e8c046", "berry": "c0303a",
    # animals
    "horse_brown": "6e4528", "horse_bay": "5a3220", "horse_dark": "3a2a22", "horse_grey": "9a948c", "horse_white": "d8d0c2",
    "mane": "2a1e18", "hoof": "2e2622", "camel": "c9a06a", "camel_dark": "9a7446",
}

# patterns: name -> (kind, colour 1, colour 2, colour 3). Kinds are drawn by _pattern_pixels.
PATTERNS = {}
# emblems: name -> flag image in EMBLEM_DIR (centre square of the flag, nearest-resampled to 32 px)
EMBLEMS = {c: c + ".png" for c in ("britons", "byzantines", "chinese", "franks", "japanese", "mongols",
                                   "ottomans", "saracens", "teutons", "vikings")}
_flat_slot, _pat_slot, _emb_slot = {}, {}, {}


def _hex(h):
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def register_patterns(d):
    PATTERNS.update(d)


def _rgb(name):
    return _hex(PALETTE[name])


def _pattern_pixels(kind, c1, c2, c3, seed):
    """16x16 rows of RGB (row 0 = top). Small hand-tuned pixel motifs, readable at 1-2 px per texel."""
    import random as _r
    rnd = _r.Random(seed)
    A, B = _rgb(c1), _rgb(c2)
    C = _rgb(c3) if c3 else B
    g = [[A for _ in range(16)] for _ in range(16)]

    def put(x, y, c):
        g[y % 16][x % 16] = c
    if kind == "embroidery":          # band at top + bottom, diamond motif in the middle, scattered stitches
        for x in range(16):
            put(x, 1, B); put(x, 14, B)
            if x % 4 == 0: put(x, 2, B); put(x + 2, 13, B)
        for dx, dy in ((0, -2), (-1, -1), (1, -1), (-2, 0), (2, 0), (-1, 1), (1, 1), (0, 2)):
            put(7 + dx, 7 + dy, B)
        put(7, 7, C)
        for x, y in ((3, 5), (12, 5), (3, 10), (12, 10)):
            put(x, y, B)
    elif kind == "brocade":           # repeated small flowers (silk)
        for ox, oy in ((2, 2), (10, 2), (6, 10), (14, 10)):
            for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                put(ox + dx, oy + dy, B)
            put(ox, oy, C)
    elif kind == "mail":              # chain mail rings
        for y in range(16):
            for x in range(16):
                off = 2 if (y // 2) % 2 else 0
                if (x + off) % 4 == 0 or ((x + off) % 4 == 2 and y % 2 == 1):
                    put(x, y, B)
    elif kind == "lamellar":          # rows of small plates, lacing between rows
        for y in range(16):
            for x in range(16):
                if y % 5 == 4:
                    put(x, y, C if x % 2 == 0 else B)
                elif x % 3 == 0:
                    put(x, y, B)
    elif kind == "scale":             # overlapping scales
        for y in range(16):
            for x in range(16):
                off = 2 if (y // 4) % 2 else 0
                lx, ly = (x + off) % 4, y % 4
                if ly == 3 or (ly == 2 and lx in (0, 3)):
                    put(x, y, B)
                elif ly == 0 and lx in (1, 2):
                    put(x, y, C)
    elif kind == "plates":            # horizontal lacquered bands (do / Chinese armour) with lacing dots
        for y in range(16):
            for x in range(16):
                if y % 4 == 3:
                    put(x, y, B)
                elif y % 4 == 1 and x % 4 == 1:
                    put(x, y, C)
    elif kind == "fur":
        for _ in range(26):
            x, y = rnd.randrange(16), rnd.randrange(16)
            for k in range(rnd.randint(2, 4)):
                put(x, y + k, B)
    elif kind == "quilt":             # quilted gambeson diamonds
        for y in range(16):
            for x in range(16):
                if (x + y) % 6 == 0 or (x - y) % 6 == 0:
                    put(x, y, B)
    elif kind == "studded":
        for y in range(2, 16, 5):
            for x in range(2, 16, 5):
                put(x, y, B)
    elif kind == "straw":
        for y in range(16):
            for x in range(16):
                if (x + 2 * y) % 5 == 0:
                    put(x, y, B)
    elif kind == "wood":
        for y in range(16):
            for x in range(16):
                if (x * 3 + (y // 5)) % 7 == 0:
                    put(x, y, B)
    elif kind == "knot":              # interlaced band (Norse borders)
        for x in range(16):
            for y in (2, 13):
                put(x, y, B)
            put(x, 4 + (x % 8 if x % 8 < 4 else 7 - x % 8), C)
            put(x, 11 - (x % 8 if x % 8 < 4 else 7 - x % 8), C)
    elif kind == "check":             # small check (Britons / Frankish heraldry fields)
        for y in range(16):
            for x in range(16):
                if (x // 4 + y // 4) % 2:
                    put(x, y, B)
    # light Bayer dither so flat areas keep a pixel-art grain
    bay = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    out = []
    for y in range(16):
        row = []
        for x in range(16):
            d = (bay[y % 4][x % 4] / 16.0 - 0.47) * 0.05
            r, gg, b = g[y][x]
            row.append((max(0, min(1, r + d)), max(0, min(1, gg + d)), max(0, min(1, b + d))))
        out.append(row)
    return out


def _emblem_pixels(name):
    """32x32 rows of RGB from the centre square of a flag image (inside its gold border)."""
    img = bpy.data.images.load(os.path.join(EMBLEM_DIR, EMBLEMS[name]), check_existing=True)
    w, h = img.size
    px = list(img.pixels)
    side = min(w, h) - 8
    x0 = (w - side) // 2
    y0 = (h - side) // 2
    out = []
    for yy in range(32):
        row = []
        for xx in range(32):
            sx = x0 + int((xx + 0.5) * side / 32)
            sy = y0 + int(((31 - yy) + 0.5) * side / 32)      # image rows are bottom-up
            o = (sy * w + sx) * 4
            row.append((px[o], px[o + 1], px[o + 2]))
        out.append(row)
    return out


def bake_palette(path):
    """Writes the unit atlas PNG and fills the slot tables (flat colours, patterns, emblems)."""
    _flat_slot.clear(); _pat_slot.clear(); _emb_slot.clear()
    canvas = [[(1.0, 0.0, 1.0)] * ATLAS for _ in range(ATLAS)]     # magenta = unused
    bay = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    for i, name in enumerate(PALETTE):
        cx, cy = i % FLAT_COLS, i // FLAT_COLS
        _flat_slot[name] = (cx, cy)
        r, g, b = _rgb(name)
        for y in range(FLAT_CELL):
            for x in range(FLAT_CELL):
                d = (bay[y % 4][x % 4] / 16.0 - 0.47) * 0.06
                canvas[FLAT_TOP + cy * FLAT_CELL + y][cx * FLAT_CELL + x] = (max(0, min(1, r + d)), max(0, min(1, g + d)), max(0, min(1, b + d)))
    for i, name in enumerate(sorted(PATTERNS)):
        cx, cy = i % PAT_COLS, i // PAT_COLS
        _pat_slot[name] = (cx, cy)
        kind, c1, c2, *rest = PATTERNS[name]
        pix = _pattern_pixels(kind, c1, c2, rest[0] if rest else None, seed=i * 7 + 3)
        for y in range(PAT_CELL):
            for x in range(PAT_CELL):
                canvas[PAT_TOP + cy * PAT_CELL + y][cx * PAT_CELL + x] = pix[y][x]
    for i, name in enumerate(sorted(EMBLEMS)):
        cx, cy = i % EMB_COLS, i // EMB_COLS
        _emb_slot[name] = (cx, cy)
        pix = _emblem_pixels(name)
        for y in range(EMB_CELL):
            for x in range(EMB_CELL):
                canvas[EMB_TOP + cy * EMB_CELL + y][cx * EMB_CELL + x] = pix[y][x]
    assert len(EMBLEMS) < EMB_COLS * 2, "emblem cells would reach the team swatch"
    tx, ty, tw, th = TEAM_SWATCH
    for y in range(ty, ty + th):
        for x in range(tx, tx + tw):
            canvas[y][x] = TEAM_PREVIEW
    img = bpy.data.images.get("PE_UnitPalette") or bpy.data.images.new("PE_UnitPalette", ATLAS, ATLAS, alpha=False)
    flat = []
    for y in range(ATLAS - 1, -1, -1):                 # Blender pixel rows are bottom-up
        for x in range(ATLAS):
            r, g, b = canvas[y][x]
            flat.extend((r, g, b, 1.0))
    img.pixels = flat
    img.filepath_raw = path
    img.file_format = 'PNG'
    img.save()
    return img


def _cell_uv(top, cell, cols, slot, inset=1.5):
    cx, cy = slot
    u0 = (cx * cell + inset) / ATLAS
    u1 = ((cx + 1) * cell - inset) / ATLAS
    v1 = 1.0 - (top + cy * cell + inset) / ATLAS
    v0 = 1.0 - (top + (cy + 1) * cell - inset) / ATLAS
    return u0, v0, u1, v1


def team_uv():
    tx, ty, tw, th = TEAM_SWATCH
    inset = 1.5
    return (tx + inset) / ATLAS, 1.0 - (ty + th - inset) / ATLAS, (tx + tw - inset) / ATLAS, 1.0 - (ty + inset) / ATLAS


def swatch_uv(color):
    return _cell_uv(FLAT_TOP, FLAT_CELL, FLAT_COLS, _flat_slot[color])


def pattern_uv(name):
    return _cell_uv(PAT_TOP, PAT_CELL, PAT_COLS, _pat_slot[name], inset=0.5)


def emblem_uv(name):
    return _cell_uv(EMB_TOP, EMB_CELL, EMB_COLS, _emb_slot[name], inset=0.5)


def get_materials(palette_img):
    mats = {}
    m = bpy.data.materials.get("PE_UnitPalette") or bpy.data.materials.new("PE_UnitPalette")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    tex = next((n for n in nt.nodes if n.type == "TEX_IMAGE"), None) or nt.nodes.new("ShaderNodeTexImage")
    tex.image = palette_img
    tex.interpolation = 'Closest'
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.9
    mats["palette"] = m
    return mats


# ---------------------------------------------------------------------------------------------------------------
# Armatures
# ---------------------------------------------------------------------------------------------------------------
# name: (head, tail, parent).  The character faces -Y, so its LEFT side is +X.
BONES = {
    "root":       ((0, 0, 0), (0, 0, 0.25), None),
    "hips":       ((0, 0, 0.68), (0, 0, 0.84), "root"),
    "spine":      ((0, 0, 0.84), (0, 0, 1.00), "hips"),
    "chest":      ((0, 0, 1.00), (0, 0, 1.20), "spine"),
    "head":       ((0, 0, 1.22), (0, 0, 1.60), "chest"),
    "thigh.L":    ((0.11, 0, 0.68), (0.11, 0, 0.38), "hips"),
    "shin.L":     ((0.11, 0, 0.38), (0.11, 0, 0.09), "thigh.L"),
    "foot.L":     ((0.11, 0, 0.09), (0.11, -0.16, 0.04), "shin.L"),
    "thigh.R":    ((-0.11, 0, 0.68), (-0.11, 0, 0.38), "hips"),
    "shin.R":     ((-0.11, 0, 0.38), (-0.11, 0, 0.09), "thigh.R"),
    "foot.R":     ((-0.11, 0, 0.09), (-0.11, -0.16, 0.04), "shin.R"),
    "upperarm.L": ((0.28, 0, 1.16), (0.33, 0, 0.93), "chest"),
    "forearm.L":  ((0.33, 0, 0.93), (0.35, -0.03, 0.72), "upperarm.L"),
    "hand.L":     ((0.35, -0.03, 0.72), (0.35, -0.05, 0.62), "forearm.L"),
    "upperarm.R": ((-0.28, 0, 1.16), (-0.33, 0, 0.93), "chest"),
    "forearm.R":  ((-0.33, 0, 0.93), (-0.35, -0.03, 0.72), "upperarm.R"),
    "hand.R":     ((-0.35, -0.03, 0.72), (-0.35, -0.05, 0.62), "forearm.R"),
    "back":       ((0, 0.13, 1.10), (0, 0.17, 1.30), "chest"),       # quiver / cargo / cape / banner mount
}

# Mounts: the rider's upper body is the humanoid rig lifted by RIDER_DZ and parented to the mount's saddle;
# the rider's legs straddle the barrel. Same bone names for horse and camel (different proportions), so the
# mounted actions work for both.
RIDER_DZ = {"horse": 0.70, "camel": 1.05}
MOUNT_DIMS = {
    # body length/height, leg length, neck, head
    "horse": dict(back_z=1.12, leg=0.98, half_len=0.62, neck=((0, -0.58, 1.22), (0, -0.92, 1.72)),
                  head=((0, -0.92, 1.72), (0, -1.22, 1.45)), tail=((0, 0.62, 1.20), (0, 0.86, 0.78))),
    "camel": dict(back_z=1.45, leg=1.32, half_len=0.66, neck=((0, -0.62, 1.42), (0, -1.00, 1.55)),
                  head=((0, -1.00, 1.55), (0, -1.10, 2.02)), tail=((0, 0.66, 1.45), (0, 0.80, 1.05))),
}


def mounted_bones(kind):
    d = MOUNT_DIMS[kind]
    dz = RIDER_DZ[kind]
    bz, leg, hl = d["back_z"], d["leg"], d["half_len"]
    knee = bz - leg * 0.52
    bones = {
        "root":   ((0, 0, 0), (0, 0, 0.25), None),
        "mbody":  ((0, hl * 0.7, bz), (0, -hl * 0.7, bz), "root"),
        "mneck":  (d["neck"][0], d["neck"][1], "mbody"),
        "mhead":  (d["head"][0], d["head"][1], "mneck"),
        "mtail":  (d["tail"][0], d["tail"][1], "mbody"),
        "saddle": ((0, 0, bz + 0.05), (0, 0, bz + 0.25), "mbody"),
    }
    for side, x in (("L", 0.17), ("R", -0.17)):
        for end, y in (("f", -hl * 0.78), ("h", hl * 0.78)):
            bones["%sleg_up.%s" % (end, side)] = ((x, y, bz - 0.12), (x, y, knee), "mbody")
            bones["%sleg_lo.%s" % (end, side)] = ((x, y, knee), (x, y, 0.0), "%sleg_up.%s" % (end, side))
    # rider: humanoid upper body lifted onto the saddle, legs straddling forward and down
    for bn, (h, t, p) in BONES.items():
        if bn in ("root",) or bn.startswith(("thigh", "shin", "foot")):
            continue
        bones[bn] = ((h[0], h[1], h[2] + dz), (t[0], t[1], t[2] + dz), "saddle" if bn == "hips" else p)
    hz = BONES["hips"][0][2] + dz
    for side, x in (("L", 1), ("R", -1)):
        bones["thigh." + side] = ((0.11 * x, 0, hz), (0.26 * x, -0.28, hz - 0.12), "hips")
        bones["shin." + side] = ((0.26 * x, -0.28, hz - 0.12), (0.28 * x, -0.18, hz - 0.50), "thigh." + side)
        bones["foot." + side] = ((0.28 * x, -0.18, hz - 0.50), (0.28 * x, -0.32, hz - 0.54), "shin." + side)
    return bones


def build_armature(name="Rig", bones=None):
    bones = bones or BONES
    ad = bpy.data.armatures.new(name)
    arm = bpy.data.objects.new(name, ad)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    for bn, (h, t, p) in bones.items():
        eb = ad.edit_bones.new(bn)
        eb.head, eb.tail = h, t
        eb.roll = 0.0
    for bn, (h, t, p) in bones.items():
        if p:
            ad.edit_bones[bn].parent = ad.edit_bones[p]
    ad.edit_bones["root"].use_deform = False
    bpy.ops.object.mode_set(mode='OBJECT')
    for pb in arm.pose.bones:
        pb.rotation_mode = 'XYZ'
    arm["bone_names"] = list(bones.keys())
    return arm


# ---------------------------------------------------------------------------------------------------------------
# Parts
# ---------------------------------------------------------------------------------------------------------------
class Body:
    """Collects rigid parts: each part = (bmesh geometry, bone, colour).
    colour: palette name | "TEAM" | "pat:<pattern>" (pattern fitted to each face) | "emb:<emblem>" (planar, see
    emblem_face)."""

    def __init__(self, bones=None):
        self.bones = bones or BONES
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.dl = self.bm.verts.layers.deform.new()
        self.bone_index = {n: i for i, n in enumerate(self.bones)}
        self.tris = 0

    def _assign_uv(self, faces, color):
        if color == "TEAM":                      # the reserved team swatch of the palette (see TEAM_SWATCH)
            u0, v0, u1, v1 = team_uv()
            for f in faces:
                f.material_index = 0
                for i, l in enumerate(f.loops):
                    l[self.uv].uv = (u0 + (u1 - u0) * (i % 2), v0 + (v1 - v0) * ((i // 2) % 2))
            return
        if color.startswith("pat:"):
            u0, v0, u1, v1 = pattern_uv(color[4:])
            for f in faces:
                f.material_index = 0
                n = f.normal
                ax = Vector((0, 0, 1)) if abs(n.z) < 0.8 else Vector((0, 1, 0))
                t1 = ax.cross(n).normalized() if ax.cross(n).length > 1e-6 else Vector((1, 0, 0))
                t2 = n.cross(t1).normalized()
                pts = [(l.vert.co.dot(t1), l.vert.co.dot(t2)) for l in f.loops]
                mnx = min(p[0] for p in pts); mxx = max(p[0] for p in pts)
                mny = min(p[1] for p in pts); mxy = max(p[1] for p in pts)
                for l, (px_, py_) in zip(f.loops, pts):
                    fx = (px_ - mnx) / (mxx - mnx) if mxx - mnx > 1e-6 else 0.5
                    fy = (py_ - mny) / (mxy - mny) if mxy - mny > 1e-6 else 0.5
                    l[self.uv].uv = (u0 + (u1 - u0) * fx, v0 + (v1 - v0) * fy)
            return
        u0, v0, u1, v1 = swatch_uv(color)
        for f in faces:
            f.material_index = 0
            for i, l in enumerate(f.loops):
                l[self.uv].uv = (u0 + (u1 - u0) * (i % 2), v0 + (v1 - v0) * ((i // 2) % 2))

    def _finish(self, verts, faces, bone, color):
        gi = self.bone_index[bone]
        for v in verts:
            v[self.dl][gi] = 1.0
        for f in faces:
            f.smooth = False
        self._assign_uv(faces, color)

    def _add(self, ret_verts, bone, color, xform):
        bmesh.ops.transform(self.bm, matrix=xform, verts=ret_verts)
        faces = list({f for v in ret_verts for f in v.link_faces})
        for f in faces:
            f.normal_update()
        self._finish(ret_verts, faces, bone, color)
        return faces

    @staticmethod
    def _matrix(loc, rot, scale):
        return (Matrix.Translation(Vector(loc)) @ Euler(rot, 'XYZ').to_matrix().to_4x4()
                @ Matrix.Diagonal(Vector((scale[0], scale[1], scale[2], 1.0))))

    def box(self, loc, size, bone, color, rot=(0, 0, 0), taper=None):
        """Box centred at loc, size (x, y, z). taper=(sx, sy) scales the top face."""
        r = bmesh.ops.create_cube(self.bm, size=1.0)
        verts = r["verts"]
        if taper:
            for v in verts:
                if v.co.z > 0:
                    v.co.x *= taper[0]
                    v.co.y *= taper[1]
        return self._add(verts, bone, color, self._matrix(loc, rot, size))

    def segment(self, p0, p1, w, d, bone, color, taper=1.0):
        """Box from p0 to p1 (limb between two joints), cross-section w x d (taper scales the p1 end)."""
        p0, p1 = Vector(p0), Vector(p1)
        axis = p1 - p0
        L = axis.length
        r = bmesh.ops.create_cube(self.bm, size=1.0)
        for v in r["verts"]:
            if v.co.z > 0:
                v.co.x *= taper
                v.co.y *= taper
        q = Vector((0, 0, 1)).rotation_difference(axis.normalized())
        m = Matrix.Translation((p0 + p1) / 2) @ q.to_matrix().to_4x4() @ Matrix.Diagonal(Vector((w, d, L, 1)))
        return self._add(r["verts"], bone, color, m)

    def cyl(self, loc, radius, depth, bone, color, rot=(0, 0, 0), segs=8, r2=None, scale_xy=(1, 1)):
        """Cylinder / cone along local Z. r2 = top radius (cone / taper)."""
        r = bmesh.ops.create_cone(self.bm, cap_ends=True, cap_tris=False, segments=segs,
                                  radius1=radius, radius2=radius if r2 is None else r2, depth=depth)
        return self._add(r["verts"], bone, color, self._matrix(loc, rot, (scale_xy[0], scale_xy[1], 1)))

    def ball(self, loc, size, bone, color, rot=(0, 0, 0), segs=8, rings=6):
        r = bmesh.ops.create_uvsphere(self.bm, u_segments=segs, v_segments=rings, radius=0.5)
        return self._add(r["verts"], bone, color, self._matrix(loc, rot, size))

    def half_ball(self, loc, size, bone, color, rot=(0, 0, 0), segs=8, rings=6):
        """Dome: upper half of a sphere (z >= 0), open bottom closed by a flat cap."""
        r = bmesh.ops.create_uvsphere(self.bm, u_segments=segs, v_segments=rings, radius=0.5)
        low = [v for v in r["verts"] if v.co.z < -1e-4]
        bmesh.ops.delete(self.bm, geom=low, context='VERTS')
        verts = [v for v in r["verts"] if v.is_valid]
        edges = [e for v in verts for e in v.link_edges if len(e.link_faces) == 1]
        if edges:
            bmesh.ops.contextual_create(self.bm, geom=list(set(edges)))
        return self._add(verts, bone, color, self._matrix(loc, rot, size))

    def torus(self, loc, major, minor, bone, color, rot=(0, 0, 0), segs=10, arc=1.0, tube_segs=4):
        """Ring (or arc part of one) in the XY plane: crescents, shield rims, turban wraps."""
        verts, faces = [], []
        n = segs if arc >= 1.0 else segs + 1
        for i in range(n):
            a = 2 * math.pi * arc * i / segs
            for j in range(tube_segs):
                b = 2 * math.pi * j / tube_segs
                rr = major + minor * math.cos(b)
                verts.append(self.bm.verts.new((rr * math.cos(a), rr * math.sin(a), minor * math.sin(b))))
        for i in range(segs):
            i2 = (i + 1) % n
            for j in range(tube_segs):
                j2 = (j + 1) % tube_segs
                faces.append(self.bm.faces.new((verts[i * tube_segs + j], verts[i2 * tube_segs + j],
                                                verts[i2 * tube_segs + j2], verts[i * tube_segs + j2])))
        bmesh.ops.transform(self.bm, matrix=self._matrix(loc, rot, (1, 1, 1)), verts=verts)
        for f in faces:
            f.normal_update()
        self._finish(verts, faces, bone, color)
        return faces

    def plate(self, outline, thickness, loc, rot, bone, face_color, side_color, emblem=None):
        """Flat shield / banner: 2D outline (x, z) extruded by thickness along -Y (the front). The front face
        shows `emblem` (planar UV over the outline's bounding box) or face_color."""
        front, back = [], []
        for x, z in outline:
            front.append(self.bm.verts.new((x, -thickness / 2, z)))
            back.append(self.bm.verts.new((x, thickness / 2, z)))
        ff = self.bm.faces.new(front)
        bf = self.bm.faces.new(list(reversed(back)))
        sides = []
        n = len(outline)
        for i in range(n):
            j = (i + 1) % n
            sides.append(self.bm.faces.new((front[j], front[i], back[i], back[j])))
        verts = front + back
        # orient: front face must point -Y
        ff.normal_update()
        if ff.normal.y > 0:
            for f in [ff, bf] + sides:
                f.normal_flip()
        m = self._matrix(loc, rot, (1, 1, 1))
        if emblem:
            xs = [p[0] for p in outline]; zs = [p[1] for p in outline]
            mnx, mxx, mnz, mxz = min(xs), max(xs), min(zs), max(zs)
            u0, v0, u1, v1 = emblem_uv(emblem)
        bmesh.ops.transform(self.bm, matrix=m, verts=verts)
        for f in [ff, bf] + sides:
            f.normal_update()
        gi = self.bone_index[bone]
        for v in verts:
            v[self.dl][gi] = 1.0
        self._assign_uv([bf] + sides, side_color)
        if emblem:
            ff.material_index = 0
            for l, (x, z) in zip(ff.loops, outline):
                pass
            # loops follow the vertex order of `front`
            for l in ff.loops:
                k = front.index(l.vert)
                x, z = outline[k]
                l[self.uv].uv = (u0 + (u1 - u0) * (x - mnx) / (mxx - mnx), v0 + (v1 - v0) * (z - mnz) / (mxz - mnz))
        else:
            self._assign_uv([ff], face_color)
        for f in [ff, bf] + sides:
            f.smooth = False
        return [ff]

    def to_object(self, name, arm, mats):
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=1e-5)
        me = bpy.data.meshes.new(name)
        self.bm.to_mesh(me)
        self.tris = sum(len(p.vertices) - 2 for p in me.polygons)
        self.bm.free()
        ob = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(ob)
        me.materials.append(mats["palette"])     # one material: team faces sit on the palette's team swatch
        for bn in self.bones:
            ob.vertex_groups.new(name=bn)
        ob.parent = arm
        mod = ob.modifiers.new("Armature", 'ARMATURE')
        mod.object = arm
        return ob


# ---------------------------------------------------------------------------------------------------------------
# Animations (shared rig). Rotations are in each bone's local space (X = swing forward/back for limbs).
# ---------------------------------------------------------------------------------------------------------------
def _key(arm, frame, pose):
    """pose: {bone: (rx, ry, rz) degrees} or {bone: {"rot": (..), "loc": (..)}}"""
    for bn in [b.name for b in arm.pose.bones]:
        pb = arm.pose.bones[bn]
        spec = pose.get(bn)
        rot, loc = (0, 0, 0), (0, 0, 0)
        if isinstance(spec, dict):
            rot = spec.get("rot", rot)
            loc = spec.get("loc", loc)
        elif spec is not None:
            rot = spec
        pb.rotation_euler = tuple(math.radians(a) for a in rot)
        pb.location = loc
        pb.keyframe_insert("rotation_euler", frame=frame)
        pb.keyframe_insert("location", frame=frame)


def _action(arm, name, keys):
    act = bpy.data.actions.new(name)
    arm.animation_data.action = act
    for frame, pose in keys:
        _key(arm, frame, pose)
    act.use_fake_user = True
    tr = arm.animation_data.nla_tracks.new()
    tr.name = name
    tr.strips.new(name, 1, act)
    arm.animation_data.action = None
    return act


# grip poses (right arm holds the weapon in front of the body, left arm the shield)
ARM_REST = {"upperarm.L": (0, 0, -8), "upperarm.R": (0, 0, 8), "forearm.L": (-15, 0, 0), "forearm.R": (-15, 0, 0)}


def make_actions(arm, attack_style):
    """attack_style: slash | thrust | bow | gun"""
    arm.animation_data_create()
    base = dict(ARM_REST)

    def P(**over):
        p = dict(base)
        for k, v in over.items():
            p[k.replace("_L", ".L").replace("_R", ".R")] = v
        return p

    # idle: slow breathing, 2 s
    _action(arm, "idle-loop", [
        (1, P(chest=(2, 0, 0))),
        (25, P(chest=(-1, 0, 0), head=(-3, 0, 2), upperarm_L=(3, 0, -9), upperarm_R=(3, 0, 9))),
        (49, P(chest=(2, 0, 0))),
    ])
    # walk: 20 frames, legs +-28 deg, arms counter-swing, small bob
    def walk_pose(s):
        return P(hips={"loc": (0, 0, 0.025 * abs(s))}, chest=(4, 0, 6 * s),
                 thigh_L=(-28 * s, 0, 0), shin_L=(max(0, 30 * s), 0, 0),
                 thigh_R=(28 * s, 0, 0), shin_R=(max(0, -30 * s), 0, 0),
                 upperarm_L=(22 * s, 0, -8), upperarm_R=(-22 * s, 0, 8))
    _action(arm, "walk-loop", [(1, walk_pose(1)), (6, walk_pose(0)), (11, walk_pose(-1)), (16, walk_pose(0)), (21, walk_pose(1))])

    # attack (played once, ~0.8 s)
    if attack_style == "slash":
        keys = [(1, P()),
                (7, P(chest=(0, 0, 25), upperarm_R=(-130, 0, 30), forearm_R=(-40, 0, 0))),
                (12, P(chest=(6, 0, -25), upperarm_R=(-20, 0, -30), forearm_R=(-10, 0, 0), upperarm_L=(-30, 0, -10))),
                (20, P())]
    elif attack_style == "thrust":
        keys = [(1, P()),
                (7, P(chest=(-4, 0, 15), upperarm_R=(-40, 0, 25), forearm_R=(-70, 0, 0))),
                (11, P(hips={"loc": (0, -0.08, 0)}, chest=(10, 0, -10), upperarm_R=(-85, 0, 0), forearm_R=(-5, 0, 0))),
                (20, P())]
    elif attack_style == "bow":
        aim = dict(upperarm_L=(-88, 0, -10), forearm_L=(0, 0, 0), upperarm_R=(-80, 0, 25))
        keys = [(1, P()),
                (6, P(chest=(0, 0, -20), **aim, forearm_R=(-60, 0, 0))),
                (13, P(chest=(0, 0, -25), **aim, forearm_R=(-120, 0, 0))),
                (15, P(chest=(0, 0, -25), **aim, forearm_R=(-20, 0, 0))),
                (22, P())]
    else:  # gun
        aim = dict(upperarm_R=(-70, 0, 15), forearm_R=(-30, 0, 0), upperarm_L=(-75, 0, -20), forearm_L=(-25, 0, 0))
        keys = [(1, P()),
                (7, P(chest=(0, 0, -15), head=(5, 0, -10), **aim)),
                (11, P(chest=(-8, 0, -15), head=(0, 0, -10), **aim)),
                (14, P(chest=(0, 0, -15), **aim)),
                (22, P())]
    _action(arm, "attack", keys)

    # gather: two-handed chop, 0.9 s loop
    up = P(chest=(-10, 0, 0), upperarm_R=(-150, 0, 10), forearm_R=(-30, 0, 0), upperarm_L=(-150, 0, -10), forearm_L=(-30, 0, 0))
    down = P(chest=(18, 0, 0), hips={"loc": (0, 0, -0.03)}, upperarm_R=(-55, 0, 10), forearm_R=(0, 0, 0),
             upperarm_L=(-55, 0, -10), forearm_L=(0, 0, 0))
    _action(arm, "gather-loop", [(1, up), (13, up), (17, down), (21, down), (23, up)])
    # build: hammering with the right arm, 0.5 s loop
    _action(arm, "build-loop", [
        (1, P(chest=(12, 0, 0), upperarm_R=(-120, 0, 15), forearm_R=(-50, 0, 0), upperarm_L=(-45, 0, -15), forearm_L=(-40, 0, 0))),
        (7, P(chest=(16, 0, 0), upperarm_R=(-50, 0, 15), forearm_R=(-5, 0, 0), upperarm_L=(-45, 0, -15), forearm_L=(-40, 0, 0))),
        (13, P(chest=(12, 0, 0), upperarm_R=(-120, 0, 15), forearm_R=(-50, 0, 0), upperarm_L=(-45, 0, -15), forearm_L=(-40, 0, 0))),
    ])
    # death: fall backwards, ~1 s, ends lying
    _action(arm, "death", [
        (1, P()),
        (8, P(root={"rot": (-20, 0, 0)}, chest=(-15, 0, 0), head=(-20, 0, 0), upperarm_L=(-60, 0, -40), upperarm_R=(-60, 0, 40),
              thigh_L=(-15, 0, 0), thigh_R=(-25, 0, 0), shin_L=(30, 0, 0), shin_R=(40, 0, 0))),
        (18, P(root={"rot": (-88, 0, 0), "loc": (0, 0.0, 0.18)}, chest=(-5, 0, 0), head=(-10, 0, 15),
               upperarm_L=(-150, 0, -50), upperarm_R=(-150, 0, 50), thigh_L=(-5, 0, 0), thigh_R=(-15, 0, 0))),
        (24, P(root={"rot": (-90, 0, 0), "loc": (0, 0.0, 0.16)}, head=(-10, 0, 15),
               upperarm_L=(-160, 0, -55), upperarm_R=(-160, 0, 55), thigh_L=(-5, 0, 0), thigh_R=(-15, 0, 0))),
    ])


def make_mount_actions(arm, attack_style):
    """Mounted units (horse or camel + rider). Same action names as on foot; gather/build reuse the idle."""
    arm.animation_data_create()
    reins = {"upperarm.L": (-35, 0, -6), "forearm.L": (-45, 0, 0), "upperarm.R": (-30, 0, 6), "forearm.R": (-40, 0, 0)}
    if attack_style == "bow":
        reins.update({"upperarm.L": (-80, 0, -12), "forearm.L": (0, 0, 0)})

    def P(**over):
        p = dict(reins)
        for k, v in over.items():
            p[k.replace("_L", ".L").replace("_R", ".R")] = v
        return p

    idle = [(1, P(mneck=(0, 0, 0), mtail=(0, 0, 4))),
            (25, P(mneck=(6, 0, 2), mhead=(-4, 0, 0), mtail=(0, 0, -4), chest=(-1, 0, 0))),
            (49, P(mneck=(0, 0, 0), mtail=(0, 0, 4)))]
    _action(arm, "idle-loop", idle)
    _action(arm, "gather-loop", idle)
    _action(arm, "build-loop", idle)

    def canter(ph):
        a = math.sin(ph)
        c = math.cos(ph)
        return P(root={"loc": (0, 0, 0.05 * abs(a))}, mbody=(3 * c, 0, 0), mneck=(-6 * c, 0, 0), mtail=(10 * a, 0, 0),
                 **{"fleg_up_L": (35 * a, 0, 0), "fleg_lo_L": (-30 * max(0, -a), 0, 0),
                    "fleg_up_R": (35 * math.sin(ph + 0.6), 0, 0), "fleg_lo_R": (-30 * max(0, -math.sin(ph + 0.6)), 0, 0),
                    "hleg_up_L": (-35 * math.sin(ph + 2.6), 0, 0), "hleg_lo_L": (30 * max(0, math.sin(ph + 2.6)), 0, 0),
                    "hleg_up_R": (-35 * math.sin(ph + 3.2), 0, 0), "hleg_lo_R": (30 * max(0, math.sin(ph + 3.2)), 0, 0)},
                 chest=(4 + 3 * c, 0, 0))
    _action(arm, "walk-loop", [(1 + i * 2, canter(i * math.pi / 4)) for i in range(9)])

    if attack_style == "thrust":       # couched lance thrust
        keys = [(1, P()), (8, P(chest=(-8, 0, 18), upperarm_R=(-20, 0, 25), forearm_R=(-60, 0, 0))),
                (12, P(chest=(12, 0, -10), upperarm_R=(-80, 0, 0), forearm_R=(-5, 0, 0), mneck=(-8, 0, 0))), (20, P())]
    elif attack_style == "bow":        # horse archer: draw and loose to the side
        aim = dict(upperarm_L=(-88, 0, -10), forearm_L=(0, 0, 0), upperarm_R=(-80, 0, 25))
        keys = [(1, P()), (6, P(chest=(0, 0, -20), **aim, forearm_R=(-60, 0, 0))),
                (13, P(chest=(0, 0, -25), **aim, forearm_R=(-120, 0, 0))), (15, P(chest=(0, 0, -25), **aim, forearm_R=(-20, 0, 0))), (22, P())]
    else:                              # sabre / sword slash from the saddle
        keys = [(1, P()), (7, P(chest=(0, 0, 25), upperarm_R=(-140, 0, 30), forearm_R=(-40, 0, 0))),
                (12, P(chest=(8, 0, -25), upperarm_R=(-30, 0, -30), forearm_R=(-10, 0, 0))), (20, P())]
    _action(arm, "attack", keys)
    _action(arm, "death", [
        (1, P()),
        (10, P(root={"rot": (0, 0, 30)}, mneck=(20, 0, 0), chest=(-20, 0, 0), upperarm_L=(-100, 0, -40), upperarm_R=(-100, 0, 40),
               **{"fleg_up_L": (40, 0, 0), "fleg_up_R": (30, 0, 0), "hleg_up_L": (-30, 0, 0), "hleg_up_R": (-20, 0, 0)})),
        (20, P(root={"rot": (0, 0, 84), "loc": (0, 0, 0.0)}, mneck=(30, 0, 0), mhead=(20, 0, 0), chest=(-30, 0, 0),
               upperarm_L=(-150, 0, -50), upperarm_R=(-150, 0, 50),
               **{"fleg_up_L": (50, 0, 0), "fleg_lo_L": (-60, 0, 0), "fleg_up_R": (40, 0, 0), "hleg_up_L": (-40, 0, 0),
                  "hleg_lo_L": (50, 0, 0), "hleg_up_R": (-30, 0, 0)})),
        (26, P(root={"rot": (0, 0, 88), "loc": (0, 0, 0.0)}, mneck=(32, 0, 0), mhead=(22, 0, 0), chest=(-30, 0, 0),
               upperarm_L=(-150, 0, -50), upperarm_R=(-150, 0, 50),
               **{"fleg_up_L": (50, 0, 0), "fleg_lo_L": (-60, 0, 0), "fleg_up_R": (40, 0, 0), "hleg_up_L": (-40, 0, 0),
                  "hleg_lo_L": (50, 0, 0), "hleg_up_R": (-30, 0, 0)})),
    ])


# ---------------------------------------------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------------------------------------------
def export_glb(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', export_animations=True, export_animation_mode='ACTIONS',
                              export_image_format='NONE', export_materials='EXPORT', export_yup=True,
                              export_apply=False, export_skins=True, export_def_bones=True,
                              export_anim_slide_to_zero=True, export_force_sampling=True)


def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.armatures, bpy.data.actions):
        for d in list(coll):
            coll.remove(d)
