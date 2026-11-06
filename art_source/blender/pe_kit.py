"""
Pocket Empires — Blender building kit (run inside Blender, e.g. through Blender MCP).

Shared, deterministic asset-production library:
  * Pixel-art material library: small hand-tuned 5-colour hue-shifted ramps + procedural
    patterns (ashlar, barrel tiles, slate, planks, lead ribs, felt ...) baked to 64x64 PNGs
    at 32 px/m, nearest-filtered. One material per surface family, shared by every building.
  * Geometry builder: primitives with explicit, world-scaled UVs (1 UV unit = 2 m so one
    64 px texture tile = 2 m) assembled into ONE mesh object per building
    (one surface per material).
  * Export helpers: save .blend, export .glb, write .meta.json with tri/material counts.

Conventions (verified Blender 5.2 -> Godot 4.7, see docs/art/BLENDER_PIPELINE.md):
  * Z-up in Blender, metres. Origin = ground centre of the gameplay footprint.
  * FRONT / entrance faces Blender -Y  (== Godot +Z == towards the RTS camera).
  * Footprint: grid_size * 2.0 m * 0.9 (TC 5.4 m, House/camps 3.6 m, Castle 7.2 m).
"""
import bpy, bmesh, math, os, json, random
import numpy as np
from mathutils import Vector

KIT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(KIT_DIR, "..", ".."))
TEX_DIR = os.path.join(REPO_ROOT, "art_source", "textures", "materials")
EMBLEM_DIR = os.path.join(REPO_ROOT, "art_source", "textures", "emblems")
GODOT_PROJECT = os.path.join(REPO_ROOT, "sample_project")
TEX_SIZE = 64          # pixels per texture tile
TILE_M = 2.0           # metres covered by one texture tile  -> 32 px / m
UVS = 1.0 / TILE_M     # world metres -> UV

# ----------------------------------------------------------------------------------------
# Palette: 5-step hue-shifted ramps (dark -> light). Darks drift to violet, lights to warm.
# ----------------------------------------------------------------------------------------
def _hex(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]

RAMPS = {
    "plaster_cream": ["#5e4a45", "#8f7462", "#c2a789", "#e3cfaa", "#f6ead0"],
    "plaster_white": ["#5a5560", "#8c8790", "#bdb8b4", "#e0dbd2", "#f7f3ea"],
    "stone_warm":    ["#4a3c3a", "#7a6558", "#a8907a", "#cbb497", "#e6d4b4"],
    "stone_grey":    ["#3a3a46", "#5f606b", "#8a8b90", "#b0afab", "#d4d0c4"],
    "sandstone":     ["#5a4030", "#8c6a4a", "#bf9a68", "#dbbd88", "#f0dcaa"],
    "brick_red":     ["#3c1c1e", "#6a2c26", "#94402e", "#b85e3c", "#d48a5c"],
    "roof_red":      ["#4a1f22", "#7f2f28", "#b0452f", "#d4683e", "#ec9a5c"],
    "roof_slate":    ["#1d2236", "#2c3552", "#3e4c72", "#566a94", "#7b92b6"],
    "roof_dark":     ["#1c1e26", "#2b2e3a", "#3d4250", "#565c6b", "#767d8a"],
    "roof_teal":     ["#10302e", "#1a4a44", "#24665c", "#3a8676", "#62a892"],
    "dome_lead":     ["#171a23", "#232834", "#323946", "#465062", "#636e82"],
    "tile_teal":     ["#12343a", "#1a4d54", "#23686d", "#3a8a88", "#66b0a8"],
    "gold":          ["#5a3a12", "#8f6420", "#c79a32", "#e8c75a", "#fff1a0"],
    "wood_dark":     ["#2e1d18", "#4a2e22", "#6b4430", "#8c5d3e", "#a8794f"],
    "wood_light":    ["#4a3020", "#74502f", "#9c7243", "#c0955c", "#dcb87c"],
    "lacquer_red":   ["#3a0d10", "#651519", "#922126", "#bb3532", "#dd5d47"],
    "cloth_red":     ["#3f0d14", "#6e1520", "#a3202a", "#cf3a36", "#ec6a52"],
    "felt_white":    ["#6b5a4a", "#9c8670", "#c6ae8e", "#e0caa4", "#f0e0bf"],
    "felt_blue":     ["#121c3c", "#1d2f63", "#2a458f", "#3c62b8", "#6a8fd6"],
    "dirt":          ["#4a3a2e", "#6b5440", "#8c7254", "#ab9068", "#c8ae84"],
    "grass":         ["#23401f", "#335a2a", "#477a34", "#63993f", "#8cba52"],
    "foliage":       ["#173322", "#22472c", "#2f6034", "#457d3c", "#6a9c48"],
    "window_dark":   ["#120e14", "#1d1820", "#2a2430", "#3a3340", "#4c4452"],
    "iron":          ["#1e1e24", "#303038", "#48484f", "#66666c", "#8c8c90"],
    "rock":          ["#2c2a31", "#45434b", "#625e64", "#837d78", "#a49c8f"],
    "shingle":       ["#2e1c14", "#4a2e1e", "#68422a", "#85583a", "#a2724c"],
    # ground (HD-2D environment pass): warm, slightly yellow-shifted highlights, cool deep shadows
    "grass_lush":    ["#1c3824", "#2a5530", "#3c7437", "#599443", "#86b656"],
    "grass_dry":     ["#36432a", "#526134", "#73803f", "#989f52", "#c0b96e"],
    "path":          ["#3d2f26", "#584333", "#745943", "#90735a", "#a98e72"],
    "sand":          ["#6d5338", "#93744c", "#b79660", "#d3b67c", "#e9d39e"],
    "sand_dark":     ["#57412d", "#78593d", "#98764e", "#b49262", "#cbad7c"],
    # biome sets (environment props): see NATURE_BIOMES
    "palm":          ["#24331c", "#3a5226", "#58732f", "#7d943c", "#a8b456"],   # olive-yellow date-palm fronds
    "palm_bark":     ["#3e2a1c", "#5e4229", "#83603a", "#a4804e", "#c2a068"],   # fibrous tan trunk
    "rock_sand":     ["#4e3427", "#7a5238", "#a3714a", "#c4935e", "#dfb67a"],   # wind-worn sandstone
    "foliage_steppe":["#1b2b26", "#29402f", "#3d5636", "#58703f", "#7f8f52"],   # sage / juniper green
    "bark_pine":     ["#2e1a16", "#4f2a1e", "#7a4026", "#a35c30", "#c47f45"],   # scots-pine red bark
    "rock_granite":  ["#2a2c33", "#43464e", "#64666a", "#878680", "#aca594"],   # pale lichen granite
    "foliage_autumn":["#3a1418", "#6e2419", "#a8461c", "#d97a26", "#f2b545"],   # crimson -> orange -> gold
    "grass_steppe":  ["#33372a", "#4a4f35", "#646743", "#7f7f52", "#9e9866"],   # muted sage-ochre
    "grass_autumn":  ["#2a3224", "#3e4a2e", "#566136", "#727a40", "#95914e"],   # late-season olive
    # mills & fields
    "thatch":        ["#4a3418", "#6f5226", "#9a7838", "#c29f50", "#e0c478"],
    "soil":          ["#2e1f18", "#45301f", "#5e4229", "#785637", "#94704a"],
    "crop_wheat":    ["#5a3e14", "#8a6420", "#b98e30", "#ddb84c", "#f6e08a"],
    "crop_green":    ["#1c3418", "#2c4f22", "#40702c", "#5f9238", "#8fb852"],
    "crop_rye":      ["#4a4224", "#6e6232", "#958744", "#b8a95c", "#d8cb84"],
    "pumpkin":       ["#5a1e0c", "#8f3612", "#c25a1a", "#e6842a", "#f8b450"],
    "water_canal":   ["#0c2830", "#123c46", "#1b5a62", "#2f7c80", "#5aa8a4"],
    "sail_cloth":    ["#6a5e52", "#9a8c7c", "#c4b8a4", "#e2d8c4", "#f6f0e2"],
    "team":          ["#7a7a7a", "#a0a0a0", "#c8c8c8", "#e6e6e6", "#ffffff"],  # tinted in Godot
}

BAYER4 = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0 - 0.5

# ----------------------------------------------------------------------------------------
# Pattern generators -> float "ramp position" arrays in [0, 4], shape (TEX, TEX), row 0 = top
# ----------------------------------------------------------------------------------------
def _rng(name):
    # deterministic across runs (Python hash() is salted per process)
    return np.random.default_rng(sum(map(ord, name)) * 7919)

def _noise(rng, scale=1.0, cells=8):
    """Tileable value noise (bilinear) with `cells` lattice cells across the tile."""
    g = rng.random((cells, cells))
    x = np.arange(TEX_SIZE) * cells / TEX_SIZE
    i0 = np.floor(x).astype(int); f = x - i0; i1 = (i0 + 1) % cells
    f = f * f * (3 - 2 * f)
    a = g[np.ix_(i0, i0)]; b = g[np.ix_(i0, i1)]; c = g[np.ix_(i1, i0)]; d = g[np.ix_(i1, i1)]
    fy = f[:, None]; fx = f[None, :]
    return ((a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy) * scale

def pat_flat(rng, base=2.6):
    return base + _noise(rng, 0.7, 8) - 0.35 + (rng.random((TEX_SIZE, TEX_SIZE)) - 0.5) * 0.35

def pat_plaster(rng):
    v = 3.0 + _noise(rng, 0.9, 4) - 0.45 + _noise(rng, 0.5, 16) - 0.25
    speck = rng.random((TEX_SIZE, TEX_SIZE)) < 0.025
    v[speck] -= 0.9
    return v

def pat_ashlar(rng, row_h=10, min_w=12, max_w=22):
    v = np.zeros((TEX_SIZE, TEX_SIZE))
    y = 0
    rows = TEX_SIZE // row_h
    row_h = TEX_SIZE / rows
    for r in range(rows):
        y0 = int(round(r * row_h)); y1 = int(round((r + 1) * row_h))
        x = int(rng.integers(0, max_w))
        start = x
        while x < start + TEX_SIZE:
            w = int(rng.integers(min_w, max_w))
            tone = 2.4 + rng.random() * 1.0
            xs = np.arange(x, x + w) % TEX_SIZE
            v[y0:y1, xs] = tone
            v[y0, xs] = tone + 0.8               # top highlight
            v[y1 - 2:y1, xs] = tone - 0.6        # bottom shade
            v[y0:y1, xs[0]] = 0.6                # vertical mortar joint
            x += w
        v[y1 - 1, :] = 0.5                       # horizontal mortar joint
    v += _noise(rng, 0.6, 16) - 0.3
    return v

def pat_brick_band(rng):
    """Byzantine opus mixtum: 3 stone courses + 2 thin brick courses (brick drawn darker)."""
    v = pat_ashlar(rng, row_h=11)
    band = np.zeros(TEX_SIZE, bool)
    band[44:52] = True
    for yy in range(44, 52):
        v[yy, :] = 1.5 + (0.6 if (yy - 44) % 4 == 0 else 0.0)
        if (yy - 44) % 4 == 3:
            v[yy, :] = 0.4
    for xx in range(0, TEX_SIZE, 8):
        v[44:48, xx] = 0.5
        v[48:52, (xx + 4) % TEX_SIZE] = 0.5
    return v

def pat_brick(rng):
    """Brick Gothic (Teutonic Order castles): small courses of red brick."""
    return pat_ashlar(rng, row_h=6, min_w=9, max_w=13)

def pat_barrel_tiles(rng, col_w=8, row_h=12):
    """Mediterranean / Ottoman barrel (Roman) tiles: vertical rounded columns, overlapped rows."""
    v = np.zeros((TEX_SIZE, TEX_SIZE))
    prof = np.array([0.9, 1.8, 2.7, 3.4, 3.7, 3.4, 2.6, 1.4])[:col_w]
    for c in range(TEX_SIZE // col_w):
        for r in range(TEX_SIZE // row_h + 1):
            jitter = (rng.random() - 0.5) * 0.7
            y0 = r * row_h; y1 = min(y0 + row_h, TEX_SIZE)
            for yy in range(y0, y1):
                t = (yy - y0) / row_h
                shade = -0.5 * t                # tile darkens towards its lower end
                v[yy, c * col_w:(c + 1) * col_w] = prof + jitter + shade
            if y0 < TEX_SIZE:
                v[y0, c * col_w:(c + 1) * col_w] = 0.3   # overlap shadow line
    return v + _noise(rng, 0.4, 16) - 0.2

def pat_kawara(rng):
    """East-Asian kawara: narrow, very regular round tiles."""
    v = pat_barrel_tiles(rng, col_w=6, row_h=8)
    return v * 0.92

def pat_slate(rng, row_h=8):
    v = np.zeros((TEX_SIZE, TEX_SIZE))
    for r in range(TEX_SIZE // row_h):
        y0 = r * row_h
        off = (r % 2) * 5
        for c in range(-1, TEX_SIZE // 10 + 1):
            x0 = c * 10 + off
            tone = 2.2 + rng.random() * 1.2
            xs = np.arange(x0, x0 + 10) % TEX_SIZE
            v[y0:y0 + row_h, xs] = tone
            v[y0 + row_h - 2:y0 + row_h, xs] = tone - 0.9
            v[y0:y0 + row_h, xs[0]] = 0.5
        v[y0, :] = 3.8
    return v + _noise(rng, 0.4, 16) - 0.2

def pat_planks(rng, plank_w=10):
    v = np.zeros((TEX_SIZE, TEX_SIZE))
    for c in range(int(np.ceil(TEX_SIZE / plank_w))):
        tone = 2.0 + rng.random() * 1.2
        xs = np.arange(c * plank_w, min((c + 1) * plank_w, TEX_SIZE))
        grain = _noise(rng, 1.0, 16)[:, :1] * 0.0
        v[:, xs] = tone
        for g in range(3):
            gx = int(rng.integers(xs[0] + 1, xs[-1] + 1)) if len(xs) > 2 else xs[0]
            v[:, gx] -= 0.5
        v[:, xs[0]] = 0.4
        knot_y = int(rng.integers(0, TEX_SIZE))
        v[knot_y:knot_y + 2, xs[len(xs) // 2]] = 0.8
    return v + _noise(rng, 0.5, 8) - 0.25

def pat_beam(rng):
    """Horizontal timber grain (for beams / logs, U runs along the beam)."""
    v = 2.4 + _noise(rng, 0.5, 4) - 0.25
    for yy in range(0, TEX_SIZE, 5):
        v[yy, :] -= 0.7
    for _ in range(18):
        y = int(rng.integers(0, TEX_SIZE)); x = int(rng.integers(0, TEX_SIZE))
        v[y, x:x + 6] += 0.8
    return v

def pat_lead_ribs(rng):
    v = np.zeros((TEX_SIZE, TEX_SIZE)) + 2.5
    for x in range(0, TEX_SIZE, 8):
        v[:, x] = 3.9
        v[:, (x + 1) % TEX_SIZE] = 3.2
        v[:, (x + 7) % TEX_SIZE] = 1.2
    for y in range(0, TEX_SIZE, 16):
        v[y, :] -= 0.8
    return v + _noise(rng, 0.6, 8) - 0.3

def pat_felt(rng):
    v = 3.0 + _noise(rng, 0.8, 8) - 0.4 + _noise(rng, 0.3, 32) - 0.15
    for y in range(0, TEX_SIZE, 16):
        v[y, :] -= 0.6
    return v

def pat_lattice(rng):
    """Mongol khana lattice / Japanese shoji: criss-cross."""
    v = np.zeros((TEX_SIZE, TEX_SIZE)) + 3.2
    for k in range(-TEX_SIZE, TEX_SIZE, 8):
        for i in range(TEX_SIZE):
            for j in (i + k, -i + k + TEX_SIZE):
                if 0 <= j < TEX_SIZE:
                    v[i, j] = 1.0
    return v + _noise(rng, 0.3, 8)

def pat_dirt(rng):
    v = 2.3 + _noise(rng, 1.4, 4) - 0.7 + _noise(rng, 0.6, 16) - 0.3
    pebbles = rng.random((TEX_SIZE, TEX_SIZE)) < 0.02
    v[pebbles] += 1.3
    return v

def pat_grass(rng):
    v = 2.2 + _noise(rng, 1.2, 8) - 0.6
    blades = rng.random((TEX_SIZE, TEX_SIZE)) < 0.08
    v[blades] += 1.2
    return v

def pat_window(rng):
    return 1.2 + _noise(rng, 0.6, 4) - 0.3

def pat_grass_blades(rng):
    """Grass with individual 2-4 px blade strokes (light tips, dark roots) over soft clumps."""
    v = 2.0 + _noise(rng, 1.0, 4) - 0.5 + _noise(rng, 0.6, 16) - 0.3
    for _ in range(260):
        x = int(rng.integers(0, TEX_SIZE)); y = int(rng.integers(0, TEX_SIZE))
        ln = int(rng.integers(2, 5))
        for k in range(ln):
            v[(y - k) % TEX_SIZE, x] += 0.55 + 0.25 * k
        v[(y + 1) % TEX_SIZE, x] -= 0.9
    return v

def pat_pebble_path(rng):
    """Packed earth path with scattered pebbles (light top, dark underside)."""
    v = 2.1 + _noise(rng, 0.9, 4) - 0.45 + _noise(rng, 0.4, 16) - 0.2
    for _ in range(26):
        cx = int(rng.integers(0, TEX_SIZE)); cy = int(rng.integers(0, TEX_SIZE))
        rx = int(rng.integers(1, 3)); ry = int(rng.integers(1, 2))
        for dy in range(-ry, ry + 2):
            for dx in range(-rx, rx + 1):
                yy = (cy + dy) % TEX_SIZE; xx = (cx + dx) % TEX_SIZE
                if dy == ry + 1:
                    v[yy, xx] = min(v[yy, xx], 0.9)
                elif (dx * dx) / max(rx * rx, 1) + (dy * dy) / max(ry * ry, 1) <= 1.2:
                    v[yy, xx] = 3.2 + (0.6 if dy < 0 else 0.0)
    return v

def pat_sand(rng):
    """Wind-rippled sand: soft diagonal ripples + grain."""
    yy, xx = np.mgrid[0:TEX_SIZE, 0:TEX_SIZE]
    ripple = np.sin((xx * 2 + yy) * (2 * np.pi / 16.0)) * 0.35
    v = 2.5 + ripple + _noise(rng, 0.8, 4) - 0.4 + (rng.random((TEX_SIZE, TEX_SIZE)) - 0.5) * 0.5
    return v

def pat_thatch(rng):
    """Straw thatch: dense vertical strands in overlapping courses (dark course line every 12 px)."""
    v = 2.6 + _noise(rng, 0.6, 8) - 0.3
    for _ in range(420):
        x = int(rng.integers(0, TEX_SIZE)); y = int(rng.integers(0, TEX_SIZE)); ln = int(rng.integers(3, 8))
        for k in range(ln):
            v[(y + k) % TEX_SIZE, x] += 0.55 if k < ln - 1 else -0.4
    for y in range(0, TEX_SIZE, 12):
        v[y, :] -= 0.9
    return v

def pat_furrows(rng):
    """Ploughed soil: horizontal ridges (light crest, dark trough) every 8 px."""
    yy = np.arange(TEX_SIZE)[:, None] * np.ones((1, TEX_SIZE))
    v = 2.2 + np.sin(yy * 2 * np.pi / 8.0) * 0.9 + _noise(rng, 0.6, 16) - 0.3
    v[rng.random((TEX_SIZE, TEX_SIZE)) < 0.02] += 1.0
    return v

def pat_crop(rng):
    """Standing crop seen from above/side: dense stalk strokes with bright ear tips."""
    v = 1.6 + _noise(rng, 0.8, 8) - 0.4
    for _ in range(520):
        x = int(rng.integers(0, TEX_SIZE)); y = int(rng.integers(0, TEX_SIZE)); ln = int(rng.integers(3, 7))
        for k in range(ln):
            v[(y - k) % TEX_SIZE, x] += 0.45 + 0.35 * k
    return v

PATTERNS = {
    "thatch": pat_thatch, "furrows": pat_furrows, "crop": pat_crop,
    "flat": pat_flat, "plaster": pat_plaster, "ashlar": pat_ashlar, "brick_band": pat_brick_band, "brick": pat_brick,
    "barrel": pat_barrel_tiles, "kawara": pat_kawara, "slate": pat_slate, "planks": pat_planks,
    "beam": pat_beam, "lead": pat_lead_ribs, "felt": pat_felt, "lattice": pat_lattice,
    "dirt": pat_dirt, "grass": pat_grass, "window": pat_window,
    "grass_blades": pat_grass_blades, "pebble_path": pat_pebble_path, "sand": pat_sand,
}

# material id -> (pattern, ramp, roughness, metallic)
MATERIALS = {
    "PE_PlasterCream": ("plaster", "plaster_cream", 0.95, 0.0),
    "PE_PlasterWhite": ("plaster", "plaster_white", 0.95, 0.0),
    "PE_StoneWarm":    ("ashlar", "stone_warm", 0.9, 0.0),
    "PE_StoneGrey":    ("ashlar", "stone_grey", 0.9, 0.0),
    "PE_Sandstone":    ("ashlar", "sandstone", 0.9, 0.0),
    "PE_StoneBrick":   ("brick_band", "stone_warm", 0.9, 0.0),
    "PE_BrickRed":     ("brick", "brick_red", 0.9, 0.0),
    "PE_RoofRed":      ("barrel", "roof_red", 0.8, 0.0),
    "PE_RoofSlate":    ("slate", "roof_slate", 0.7, 0.0),
    "PE_RoofDark":     ("kawara", "roof_dark", 0.7, 0.0),
    "PE_RoofTeal":     ("kawara", "roof_teal", 0.7, 0.0),
    "PE_DomeLead":     ("lead", "dome_lead", 0.55, 0.2),
    "PE_TileTeal":     ("lead", "tile_teal", 0.6, 0.0),
    "PE_Gold":         ("flat", "gold", 0.35, 0.8),
    "PE_WoodDark":     ("planks", "wood_dark", 0.9, 0.0),
    "PE_WoodLight":    ("planks", "wood_light", 0.9, 0.0),
    "PE_Beam":         ("beam", "wood_dark", 0.9, 0.0),
    "PE_LacquerRed":   ("flat", "lacquer_red", 0.6, 0.0),
    "PE_ClothRed":     ("flat", "cloth_red", 0.95, 0.0),
    "PE_Felt":         ("felt", "felt_white", 1.0, 0.0),
    "PE_FeltBlue":     ("felt", "felt_blue", 1.0, 0.0),
    "PE_Lattice":      ("lattice", "wood_light", 0.9, 0.0),
    "PE_Dirt":         ("dirt", "dirt", 1.0, 0.0),
    "PE_Grass":        ("grass", "grass", 1.0, 0.0),
    "PE_Foliage":      ("grass", "foliage", 1.0, 0.0),
    "PE_Window":       ("window", "window_dark", 0.6, 0.0),
    "PE_Iron":         ("flat", "iron", 0.5, 0.6),
    "PE_Shingle":      ("slate", "shingle", 0.9, 0.0),
    "PE_SlateDark":    ("slate", "roof_dark", 0.7, 0.0),
    # ground textures for the terrain shader (shaders/hd2d_ground.gdshader)
    "GR_GrassLush":    ("grass_blades", "grass_lush", 1.0, 0.0),
    "GR_GrassDry":     ("grass_blades", "grass_dry", 1.0, 0.0),
    "GR_Dirt":         ("dirt", "path", 1.0, 0.0),
    "GR_Path":         ("pebble_path", "path", 1.0, 0.0),
    "GR_Sand":         ("sand", "sand", 1.0, 0.0),
    "GR_SandDark":     ("sand", "sand_dark", 1.0, 0.0),
    "GR_GrassSteppe":  ("grass_blades", "grass_steppe", 1.0, 0.0),
    "GR_GrassAutumn":  ("grass_blades", "grass_autumn", 1.0, 0.0),
    "PE_Thatch":       ("thatch", "thatch", 1.0, 0.0),
    "PE_Soil":         ("furrows", "soil", 1.0, 0.0),
    "PE_CropWheat":    ("crop", "crop_wheat", 1.0, 0.0),
    "PE_CropGreen":    ("crop", "crop_green", 1.0, 0.0),
    "PE_CropRye":      ("crop", "crop_rye", 1.0, 0.0),
    "PE_Pumpkin":      ("flat", "pumpkin", 0.8, 0.0),
    "PE_Canal":        ("flat", "water_canal", 0.3, 0.0),
    "PE_SailCloth":    ("felt", "sail_cloth", 1.0, 0.0),
    "TEAM_Trim":       ("flat", "team", 0.8, 0.0),   # Godot replaces albedo with team colour
}

def bake_texture(mat_id):
    pattern, ramp, _, _ = MATERIALS[mat_id]
    rng = _rng(mat_id)
    v = PATTERNS[pattern](rng)
    v = np.clip(v + BAYER4[np.arange(TEX_SIZE)[:, None] % 4, np.arange(TEX_SIZE)[None, :] % 4] * 0.55, 0, 4.49)
    idx = np.floor(v + 0.5).astype(int).clip(0, 4)
    cols = np.array([_hex(h) for h in RAMPS[ramp]])
    rgb = cols[idx]
    rgba = np.concatenate([rgb, np.ones((TEX_SIZE, TEX_SIZE, 1))], axis=2)
    os.makedirs(TEX_DIR, exist_ok=True)
    path = os.path.join(TEX_DIR, mat_id + ".png")
    img = bpy.data.images.get(mat_id) or bpy.data.images.new(mat_id, TEX_SIZE, TEX_SIZE, alpha=True)
    img.scale(TEX_SIZE, TEX_SIZE)
    img.pixels.foreach_set(np.flipud(rgba).astype(np.float32).ravel())  # Blender rows are bottom-up
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    return img

# Environment props share ONE atlas material (1 draw call per tree/mine): 64x64 texture split in
# quadrants. Faces built with a NAT_* material id are region-fitted into their quadrant.
# Each map biome gets its own atlas (same layout, different ramps), so one prop script can be
# re-skinned per biome and every biome prop is still 1 draw call.
NATURE_ATLAS = {"NAT_foliage": (0, 0, "grass", "foliage"), "NAT_bark": (1, 0, "planks", "wood_dark"),
                "NAT_rock": (0, 1, "ashlar", "rock"), "NAT_gold": (1, 1, "flat", "gold")}
NATURE_BIOMES = {
    "temperate": {},   # = NATURE_ATLAS ramps (Yesil Vadi, Nehir Gecidi)
    "desert": {"NAT_foliage": "palm", "NAT_bark": "palm_bark", "NAT_rock": "rock_sand"},
    "steppe": {"NAT_foliage": "foliage_steppe", "NAT_bark": "bark_pine", "NAT_rock": "rock_granite"},
    "autumn": {"NAT_foliage": "foliage_autumn"},
}

def nature_atlas_name(biome="temperate"):
    return "PE_NatureAtlas" if biome == "temperate" else "PE_NatureAtlas_" + biome.capitalize()

def bake_nature_atlas(biome="temperate"):
    half = TEX_SIZE // 2
    rgba = np.ones((TEX_SIZE, TEX_SIZE, 4))
    for key, (qx, qy, pattern, ramp) in NATURE_ATLAS.items():
        ramp = NATURE_BIOMES[biome].get(key, ramp)
        rng = _rng(key)
        v = PATTERNS[pattern](rng)
        if key == "NAT_rock":
            v = 2.3 + _noise(rng, 1.3, 4) - 0.65 + _noise(rng, 0.35, 16) - 0.17
            v[rng.random((TEX_SIZE, TEX_SIZE)) < 0.015] += 1.2
            if biome == "desert":   # horizontal wind-cut strata
                v += np.sin(np.arange(TEX_SIZE)[:, None] * (2 * np.pi / 7.0)) * 0.35
        if key == "NAT_gold":
            v = 2.6 + _noise(rng, 1.4, 8) - 0.7
            v[rng.random((TEX_SIZE, TEX_SIZE)) < 0.06] = 4.4
        if key == "NAT_foliage" and biome == "autumn":   # broad warm/cool leaf-cluster patches
            v = v + _noise(_rng("autumn"), 1.2, 4) - 0.6
        v = np.clip(v + BAYER4[np.arange(TEX_SIZE)[:, None] % 4, np.arange(TEX_SIZE)[None, :] % 4] * 0.55, 0, 4.49)
        idx = np.floor(v + 0.5).astype(int).clip(0, 4)
        cols = np.array([_hex(h) for h in RAMPS[ramp]])
        rgba[qy * half:(qy + 1) * half, qx * half:(qx + 1) * half, :3] = cols[idx][:half, :half]
    name = nature_atlas_name(biome)
    path = os.path.join(TEX_DIR, name + ".png")
    img = bpy.data.images.get(name) or bpy.data.images.new(name, TEX_SIZE, TEX_SIZE, alpha=True)
    img.scale(TEX_SIZE, TEX_SIZE)
    img.pixels.foreach_set(np.flipud(rgba).astype(np.float32).ravel())
    img.filepath_raw = path; img.file_format = "PNG"; img.save()
    return img

def _image_material(name, img, roughness, metallic=0.0, alpha=False):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"      # -> glTF sampler NEAREST (pixel-art)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if alpha:
        nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    nt.links.new(bsdf.outputs[0], out.inputs[0])
    return mat

def get_material(mat_id):
    if mat_id.startswith("PE_Banner_"):
        civ = mat_id[len("PE_Banner_"):].lower()
        path = os.path.join(EMBLEM_DIR, "banner_%s.png" % civ)
        img = bpy.data.images.load(path, check_existing=True)
        return _image_material(mat_id, img, 0.95)
    if mat_id.startswith("PE_NatureAtlas"):
        biome = mat_id[len("PE_NatureAtlas_"):].lower() if mat_id != "PE_NatureAtlas" else "temperate"
        return _image_material(mat_id, bake_nature_atlas(biome), 0.95)
    if mat_id in bpy.data.materials and mat_id in bpy.data.images:
        return bpy.data.materials[mat_id]
    pattern, ramp, rough, metal = MATERIALS[mat_id]
    return _image_material(mat_id, bake_texture(mat_id), rough, metal)

# ----------------------------------------------------------------------------------------
# Geometry builder
# ----------------------------------------------------------------------------------------
V = Vector

class Builder:
    """Accumulates faces (with per-loop UVs and a material id) into one bmesh."""

    def __init__(self, name, biome="temperate"):
        self.name = name
        self.biome = biome
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.mat_index = {}

    def _mi(self, mat_id):
        if mat_id not in self.mat_index:
            self.mat_index[mat_id] = len(self.mat_index)
        return self.mat_index[mat_id]

    # -- low level ------------------------------------------------------------------
    def mesh(self, verts, faces, uvs, mat, smooth=False):
        """verts: list of Vector; faces: list of index tuples; uvs: list (per face) of uv lists."""
        bv = [self.bm.verts.new(v) for v in verts]
        mi = self._mi(mat)
        for f, fuv in zip(faces, uvs):
            try:
                face = self.bm.faces.new([bv[i] for i in f])
            except ValueError:
                continue
            face.material_index = mi
            face.smooth = smooth
            for loop, uv in zip(face.loops, fuv):
                loop[self.uv].uv = uv

    def quad(self, a, b, c, d, mat, uv=None):
        """Single quad a-b-c-d (CCW seen from outside). Default UV: planar box projection."""
        pts = [V(a), V(b), V(c), V(d)]
        self.mesh(pts, [(0, 1, 2, 3)], [uv or box_uv(pts)], mat)

    def poly(self, pts, mat, uv=None):
        pts = [V(p) for p in pts]
        self.mesh(pts, [tuple(range(len(pts)))], [uv or box_uv(pts)], mat)

    # -- primitives -----------------------------------------------------------------
    def box(self, center, size, mat, top_mat=None, bottom=False, sides_mat=None):
        cx, cy, cz = center; sx, sy, sz = (s * 0.5 for s in size)
        x0, x1, y0, y1, z0, z1 = cx - sx, cx + sx, cy - sy, cy + sy, cz - sz, cz + sz
        sm = sides_mat or mat
        self.quad((x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1), sm)   # front -Y
        self.quad((x1, y1, z0), (x0, y1, z0), (x0, y1, z1), (x1, y1, z1), sm)   # back +Y
        self.quad((x0, y1, z0), (x0, y0, z0), (x0, y0, z1), (x0, y1, z1), sm)   # left -X
        self.quad((x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (x1, y0, z1), sm)   # right +X
        self.quad((x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1), top_mat or mat)
        if bottom:
            self.quad((x0, y1, z0), (x1, y1, z0), (x1, y0, z0), (x0, y0, z0), mat)

    def prism(self, outline, z0, z1, mat, top_mat=None, cap=True, smooth=False, uv_u_scale=1.0):
        """Vertical extrusion of a CCW 2D outline. Side UV: U = perimeter length, V = height."""
        n = len(outline)
        verts = [V((x, y, z0)) for x, y in outline] + [V((x, y, z1)) for x, y in outline]
        faces, uvs = [], []
        u = 0.0
        for i in range(n):
            j = (i + 1) % n
            seg = (V(outline[j]) - V(outline[i])).length
            faces.append((i, j, n + j, n + i))
            uvs.append([(u * UVS * uv_u_scale, z0 * UVS), ((u + seg) * UVS * uv_u_scale, z0 * UVS),
                        ((u + seg) * UVS * uv_u_scale, z1 * UVS), (u * UVS * uv_u_scale, z1 * UVS)])
            u += seg
        self.mesh(verts, faces, uvs, mat, smooth=smooth)
        if cap:
            top = [V((x, y, z1)) for x, y in outline]
            self.mesh(top, [tuple(range(n))], [[(p.x * UVS, p.y * UVS) for p in top]], top_mat or mat)

    def cylinder(self, center, r, h, mat, segs=12, top_mat=None, cap=True, smooth=True, r_top=None):
        cx, cy, cz = center
        rt = r if r_top is None else r_top
        n = segs
        verts = [V((cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n), cz)) for i in range(n)]
        verts += [V((cx + rt * math.cos(2 * math.pi * i / n), cy + rt * math.sin(2 * math.pi * i / n), cz + h)) for i in range(n)]
        circ = 2 * math.pi * r
        faces, uvs = [], []
        for i in range(n):
            j = (i + 1) % n
            u0 = circ * i / n * UVS; u1 = circ * (i + 1) / n * UVS
            faces.append((i, j, n + j, n + i))
            uvs.append([(u0, cz * UVS), (u1, cz * UVS), (u1, (cz + h) * UVS), (u0, (cz + h) * UVS)])
        self.mesh(verts, faces, uvs, mat, smooth=smooth)
        if cap and rt > 0.001:
            top = verts[n:]
            self.mesh(top, [tuple(range(n))], [[(p.x * UVS, p.y * UVS) for p in top]], top_mat or mat)

    def cone(self, center, r, h, mat, segs=12, smooth=True):
        cx, cy, cz = center
        apex = V((cx, cy, cz + h))
        slant = math.hypot(r, h)
        verts, faces, uvs = [], [], []
        for i in range(segs):
            a0 = 2 * math.pi * i / segs; a1 = 2 * math.pi * (i + 1) / segs
            p0 = V((cx + r * math.cos(a0), cy + r * math.sin(a0), cz))
            p1 = V((cx + r * math.cos(a1), cy + r * math.sin(a1), cz))
            k = len(verts)
            verts += [p0, p1, apex.copy()]
            faces.append((k, k + 1, k + 2))
            u0 = r * a0 * UVS; u1 = r * a1 * UVS
            uvs.append([(u0, 0), (u1, 0), ((u0 + u1) / 2, slant * UVS)])
        self.mesh(verts, faces, uvs, mat, smooth=smooth)

    def dome(self, center, r, mat, segs=16, rings=6, height=None, smooth=True, top_hole=0.0):
        """Hemisphere (optionally squashed/stretched to `height`). UV: U=arc around, V=arc down."""
        cx, cy, cz = center
        hgt = r if height is None else height
        verts, faces, uvs = [], [], []
        ring_pts = []
        for k in range(rings + 1):
            phi = (math.pi / 2) * k / rings          # 0 at equator -> pi/2 at top
            if k == rings and top_hole <= 0:
                ring_pts.append(None)
                continue
            rr = r * math.cos(phi); zz = cz + hgt * math.sin(phi)
            ring_pts.append([V((cx + rr * math.cos(2 * math.pi * i / segs), cy + rr * math.sin(2 * math.pi * i / segs), zz)) for i in range(segs)])
        apex = V((cx, cy, cz + hgt))
        arc = lambda k: (math.pi / 2) * r * k / rings
        for k in range(rings):
            for i in range(segs):
                j = (i + 1) % segs
                u0 = 2 * math.pi * r * i / segs * UVS; u1 = 2 * math.pi * r * (i + 1) / segs * UVS
                v0 = -arc(k) * UVS; v1 = -arc(k + 1) * UVS
                if ring_pts[k + 1] is None:
                    base = len(verts)
                    verts += [ring_pts[k][i], ring_pts[k][j], apex.copy()]
                    faces.append((base, base + 1, base + 2))
                    uvs.append([(u0, v0), (u1, v0), ((u0 + u1) / 2, v1)])
                else:
                    base = len(verts)
                    verts += [ring_pts[k][i], ring_pts[k][j], ring_pts[k + 1][j], ring_pts[k + 1][i]]
                    faces.append((base, base + 1, base + 2, base + 3))
                    uvs.append([(u0, v0), (u1, v0), (u1, v1), (u0, v1)])
        # weld duplicated ring verts so smooth shading is continuous
        self.mesh(verts, faces, uvs, mat, smooth=smooth)

    def gable_roof(self, center, w, d, h, mat, overhang=0.25, thick=0.12, ridge_axis="x", end_mat=None, ridge_mat=None):
        """Gable roof. ridge_axis 'x': ridge runs along X (slopes face -Y/+Y)."""
        cx, cy, cz = center
        if ridge_axis == "y":
            # build along x then rotate 90 degrees by swapping coordinates
            pts = self._gable_pts(w=d, d=w, h=h, overhang=overhang)
            pts = {k: [(-p[1], p[0], p[2]) for p in v] for k, v in pts.items()}
        else:
            pts = self._gable_pts(w, d, h, overhang)
        off = V((cx, cy, cz))
        P = {k: [off + V(p) for p in v] for k, v in pts.items()}
        sl = math.hypot(d / 2 + overhang, h)
        lx = (w + 2 * overhang)
        for side in ("front", "back"):
            a, b, c, e = P[side]
            self.quad(a, b, c, e, mat, uv=[(0, 0), (lx * UVS, 0), (lx * UVS, sl * UVS), (0, sl * UVS)])
            # roof thickness (fascia) at eave
            down = V((0, 0, -thick))
            self.quad(a + down, b + down, b, a, end_mat or "PE_WoodDark")
        # undersides (so the roof reads solid from low angles)
        fa, fb, fc, fe = P["front"]; ba, bb, bc, be = P["back"]
        down = V((0, 0, -thick))
        self.quad(fb + down, fa + down, fe + down, fc + down, end_mat or "PE_WoodDark")
        self.quad(bb + down, ba + down, be + down, bc + down, end_mat or "PE_WoodDark")
        # gable end triangles (walls) are added by caller with wall material; ridge cap:
        if ridge_mat:
            r0 = fe; r1 = fc
            axis = (r1 - r0).normalized()
            self.cylinder_between(r0 - axis * 0.05, r1 + axis * 0.05, 0.09, ridge_mat, segs=6)

    @staticmethod
    def _gable_pts(w, d, h, overhang):
        x0, x1 = -w / 2 - overhang, w / 2 + overhang
        y0, y1 = -d / 2 - overhang, d / 2 + overhang
        drop = h * overhang / (d / 2)
        return {
            # eave left, eave right, ridge right, ridge left (CCW from outside)
            "front": [(x0, y0, -drop), (x1, y0, -drop), (x1, 0, h), (x0, 0, h)],
            "back":  [(x1, y1, -drop), (x0, y1, -drop), (x0, 0, h), (x1, 0, h)],
        }

    def gable_end(self, center, w, d, h, mat, ridge_axis="x"):
        """Triangular wall pieces closing the gable under a gable_roof (no overhang)."""
        cx, cy, cz = center
        if ridge_axis == "x":
            for sx in (-1, 1):
                x = cx + sx * w / 2
                tri = [(x, cy - d / 2, cz), (x, cy + d / 2, cz), (x, cy, cz + h)]
                if sx < 0:
                    tri = [tri[1], tri[0], tri[2]]
                self.poly(tri, mat)
        else:
            for sy in (-1, 1):
                y = cy + sy * d / 2
                tri = [(cx + w / 2, y, cz), (cx - w / 2, y, cz), (cx, y, cz + h)]
                if sy < 0:
                    tri = [tri[1], tri[0], tri[2]]
                self.poly(tri, mat)

    def hip_roof(self, center, w, d, h, mat, overhang=0.25, thick=0.1, ridge_frac=0.35, curve=0.0, under_mat="PE_WoodDark"):
        """Hip roof (ridge along the longer axis). `curve` lifts the eave corners (East-Asian)."""
        cx, cy, cz = center
        W = w / 2 + overhang; D = d / 2 + overhang
        drop = h * overhang / (min(w, d) / 2)
        if w >= d:
            r = (w - d) / 2 * (1 - ridge_frac) + ridge_frac * 0
            r = max(0.0, w / 2 - d / 2) + ridge_frac * 0
            ra, rb = V((cx - r, cy, cz + h)), V((cx + r, cy, cz + h))
        else:
            r = max(0.0, d / 2 - w / 2)
            ra, rb = V((cx, cy - r, cz + h)), V((cx, cy + r, cz + h))
        lift = V((0, 0, curve))
        c00 = V((cx - W, cy - D, cz - drop)) + lift
        c10 = V((cx + W, cy - D, cz - drop)) + lift
        c11 = V((cx + W, cy + D, cz - drop)) + lift
        c01 = V((cx - W, cy + D, cz - drop)) + lift
        if curve > 0:
            # mid-eave points stay low -> upturned corners
            m0 = V((cx, cy - D, cz - drop)); m1 = V((cx + W, cy, cz - drop))
            m2 = V((cx, cy + D, cz - drop)); m3 = V((cx - W, cy, cz - drop))
        if w >= d:
            faces = [[c00, c10, rb, ra], [c11, c01, ra, rb], [c10, c11, rb], [c01, c00, ra]]
        else:
            faces = [[c10, c11, rb, ra], [c01, c00, ra, rb], [c11, c01, rb], [c00, c10, ra]]
        if curve > 0:
            new_faces = []
            for f in faces:
                if len(f) == 4:
                    a, b, c, e = f
                    m = (a + b) / 2; m.z = cz - drop
                    mid_top = (e + c) / 2
                    new_faces += [[a, m, mid_top, e], [m, b, c, mid_top]]
                else:
                    a, b, c = f
                    m = (a + b) / 2; m.z = cz - drop
                    new_faces += [[a, m, c], [m, b, c]]
            faces = new_faces
        for f in faces:
            pts = f
            # UV: u along eave edge, v up the slope
            e0, e1 = pts[0], pts[1]
            ax = (e1 - e0); ax.z = 0
            ax = ax.normalized() if ax.length > 1e-6 else V((1, 0, 0))
            up = V((0, 0, 1))
            nrm = ax.cross(up).normalized() * -1
            uv = []
            for p in pts:
                rel = p - e0
                horiz = V((rel.x, rel.y, 0))
                u = rel.dot(ax)
                along = -horiz.dot(nrm)
                v = math.hypot(along, rel.z)
                uv.append((u * UVS, v * UVS))
            self.mesh([p.copy() for p in pts], [tuple(range(len(pts)))], [uv], mat)
        # underside skirt; with upturned corners the eave ring has 8 points (corners lifted,
        # mid-eave points low), so the underside must follow it instead of a flat corner quad
        # (a flat quad at corner height would poke through the roof at mid-eave).
        if curve > 0:
            ring = [c00, m0, c10, m1, c11, m2, c01, m3]
        else:
            ring = [c00, c10, c11, c01]
        dn = V((0, 0, -thick))
        for i in range(len(ring)):
            a, b = ring[i], ring[(i + 1) % len(ring)]
            self.quad(a + dn, b + dn, b, a, under_mat)
        centre = V((cx, cy, cz - drop - thick * 1.5))
        for i in range(len(ring)):
            a, b = ring[i], ring[(i + 1) % len(ring)]
            self.poly([b + dn, a + dn, centre], under_mat)

    def pyramid_roof(self, center, w, d, h, mat, overhang=0.15, under_mat="PE_WoodDark"):
        cx, cy, cz = center
        apex = V((cx, cy, cz + h))
        W = w / 2 + overhang; D = d / 2 + overhang
        drop = h * overhang / (min(w, d) / 2)
        cs = [V((cx - W, cy - D, cz - drop)), V((cx + W, cy - D, cz - drop)), V((cx + W, cy + D, cz - drop)), V((cx - W, cy + D, cz - drop))]
        for i in range(4):
            a, b = cs[i], cs[(i + 1) % 4]
            L = (b - a).length; sl = (apex - (a + b) / 2).length
            self.mesh([a.copy(), b.copy(), apex.copy()], [(0, 1, 2)], [[(0, 0), (L * UVS, 0), (L * UVS / 2, sl * UVS)]], mat)
        self.poly([cs[3], cs[2], cs[1], cs[0]], under_mat)

    def frustum(self, base_center, w0, d0, w1, d1, h, mat, top_mat=None):
        """Axis-aligned tapered block (e.g. Japanese ishigaki stone base, battered walls)."""
        cx, cy, cz = base_center
        bot = [V((cx - w0 / 2, cy - d0 / 2, cz)), V((cx + w0 / 2, cy - d0 / 2, cz)), V((cx + w0 / 2, cy + d0 / 2, cz)), V((cx - w0 / 2, cy + d0 / 2, cz))]
        top = [V((cx - w1 / 2, cy - d1 / 2, cz + h)), V((cx + w1 / 2, cy - d1 / 2, cz + h)), V((cx + w1 / 2, cy + d1 / 2, cz + h)), V((cx - w1 / 2, cy + d1 / 2, cz + h))]
        for i in range(4):
            j = (i + 1) % 4
            self.poly([bot[i], bot[j], top[j], top[i]], mat)
        self.poly(top, top_mat or mat)

    def cylinder_between(self, a, b, r, mat, segs=6, smooth=True, cap=False):
        a, b = V(a), V(b)
        axis = b - a
        L = axis.length
        z = axis.normalized()
        x = z.orthogonal().normalized(); y = z.cross(x)
        verts, faces, uvs = [], [], []
        for i in range(segs):
            ang = 2 * math.pi * i / segs
            off = (x * math.cos(ang) + y * math.sin(ang)) * r
            verts += [a + off, b + off]
        for i in range(segs):
            j = (i + 1) % segs
            faces.append((2 * i, 2 * j, 2 * j + 1, 2 * i + 1))
            u0 = i / segs * 2 * math.pi * r * UVS; u1 = (i + 1) / segs * 2 * math.pi * r * UVS
            uvs.append([(0, u0), (0, u1), (L * UVS, u1), (L * UVS, u0)])
        self.mesh(verts, faces, uvs, mat, smooth=smooth)
        if cap:   # flat end discs (wheels, straw butts, bale ends); default off keeps older assets unchanged
            ring = [(math.cos(2 * math.pi * i / segs) * 0.5 + 0.5, math.sin(2 * math.pi * i / segs) * 0.5 + 0.5) for i in range(segs)]
            self.mesh([verts[2 * i + 1].copy() for i in range(segs)], [tuple(range(segs))], [ring], mat)
            self.mesh([verts[2 * i].copy() for i in reversed(range(segs))], [tuple(range(segs))], [list(reversed(ring))], mat)

    def arch_opening(self, center, facing, w, h, mat, frame_mat=None, depth=0.08, frame=0.1, segs=6, pointed=False):
        """Recessed arched opening (door/window) on a wall. center = bottom-centre on wall surface.
        facing: unit vector pointing out of the wall (e.g. (0,-1,0) for the front)."""
        f = V(facing).normalized()
        right = V((0, 0, 1)).cross(f).normalized() * -1   # x-axis along the wall
        if right.length < 0.5:
            right = V((1, 0, 0))
        up = V((0, 0, 1))
        c = V(center)
        def outline(scale_w, extra_h):
            pts = []
            hw = w / 2 * scale_w
            spring = h - hw if not pointed else h - hw * 1.3
            pts.append(c + right * (-hw))
            pts.append(c + right * hw)
            for k in range(segs + 1):
                a = math.pi * k / segs
                if pointed:
                    # two arcs meeting at a point
                    xx = hw * math.cos(a)
                    yy = (hw * 1.3) * math.sin(a) ** 0.8
                else:
                    xx = hw * math.cos(a); yy = hw * math.sin(a)
                pts.append(c + right * xx + up * (spring + yy + extra_h))
            return pts
        inner = outline(1.0, 0.0)
        # ring order: bottom-right -> arc (right..left) -> bottom-left
        ring_i = [inner[1]] + inner[2:] + [inner[0]]
        hole_c = sum(ring_i, V((0, 0, 0))) / len(ring_i)
        # Openings are applied ON solid wall boxes, so the dark panel sits just in front of the
        # wall surface and a raised frame (protruding `depth`) with inward-facing reveals fakes
        # the recess. (A true recess would be hidden behind the wall face.)
        panel_off = 0.012
        self.poly(_ccw([p + f * panel_off for p in ring_i], f), mat)
        if frame_mat:
            fo = panel_off + depth
            outer = outline(1.0 + 2 * frame / w, frame)
            ring_o = [outer[1]] + outer[2:] + [outer[0]]
            o = [p + f * fo for p in ring_o]; i_ = [p + f * fo for p in ring_i]
            for k in range(len(o) - 1):
                self.poly(_ccw([i_[k], o[k], o[k + 1], i_[k + 1]], f), frame_mat)
                # outer side of the frame (facing away from the opening)
                p0, p1 = ring_o[k], ring_o[k + 1]
                away = (p0 + p1) / 2 - hole_c
                away -= f * away.dot(f)
                self.poly(_ccw([p0, p1, p1 + f * fo, p0 + f * fo], away), frame_mat)
            for k in range(len(ring_i) - 1):
                p0, p1 = ring_i[k], ring_i[k + 1]
                toward = hole_c - (p0 + p1) / 2
                toward -= f * toward.dot(f)
                self.poly(_ccw([p0 + f * panel_off, p1 + f * panel_off, p1 + f * fo, p0 + f * fo], toward), frame_mat)

    def banner(self, top_center, facing, w, h, civ, mat_override=None, tail=True):
        """Hanging cloth banner with civ emblem; slight forward offset from wall."""
        f = V(facing).normalized()
        right = V((0, 0, 1)).cross(f).normalized() * -1
        c = V(top_center) + f * 0.06
        up = V((0, 0, 1))
        a = c - right * (w / 2); b = c + right * (w / 2)
        bl = a - up * h; br = b - up * h
        mat = mat_override or ("PE_Banner_" + civ)
        if tail:
            mid = c - up * (h + 0.18)
            pts = [bl, br, b, a]
            self.mesh([p.copy() for p in pts], [(0, 1, 2, 3)], [[(0, 0.1), (1, 0.1), (1, 1), (0, 1)]], mat)
            self.mesh([bl.copy(), mid.copy(), br.copy()], [(0, 1, 2)], [[(0, 0.1), (0.5, 0.0), (1, 0.1)]], mat)
        else:
            self.mesh([bl, br, b, a], [(0, 1, 2, 3)], [[(0, 0), (1, 0), (1, 1), (0, 1)]], mat)
        # rod
        self.cylinder_between(a - right * 0.08 + f * 0.02, b + right * 0.08 + f * 0.02, 0.03, "PE_Gold", segs=4)

    def flag(self, base, height, civ, size=(0.9, 0.6), wave=0.12):
        """Pole + waving flag (flag faces -Y/+Y, flies towards +X)."""
        b = V(base)
        self.cylinder(b, 0.04, height, "PE_WoodDark", segs=5, cap=False)
        self.cylinder(b + V((0, 0, height)), 0.07, 0.08, "PE_Gold", segs=5)
        fw, fh = size
        n = 4
        verts, faces, uvs = [], [], []
        for i in range(n + 1):
            t = i / n
            x = b.x + 0.04 + fw * t
            yoff = math.sin(t * math.pi * 1.5) * wave
            verts += [V((x, b.y + yoff, b.z + height - fh)), V((x, b.y + yoff, b.z + height - 0.02))]
        for i in range(n):
            k = 2 * i
            faces.append((k, k + 2, k + 3, k + 1))
            t0, t1 = i / n, (i + 1) / n
            uvs.append([(t0 * 0.92 + 0.04, 0.2), (t1 * 0.92 + 0.04, 0.2), (t1 * 0.92 + 0.04, 0.68), (t0 * 0.92 + 0.04, 0.68)])
        self.mesh(verts, faces, uvs, "PE_Banner_" + civ)
        # back side
        self.mesh([v.copy() for v in verts], [(f[0], f[3], f[2], f[1]) for f in faces], [[u[0], u[3], u[2], u[1]] for u in uvs], "PE_Banner_" + civ)

    def stairs(self, front_center, w, steps, step_h, step_d, mat):
        c = V(front_center)
        for i in range(steps):
            hh = step_h * (steps - i)
            yc = c.y - step_d * (i + 0.5)
            self.box((c.x, yc, hh / 2), (w, step_d, hh), mat)

    def _atlasize_nature(self):
        """Region-fit every NAT_* face into its atlas quadrant and merge them into PE_NatureAtlas."""
        nat = {mi: m for m, mi in self.mat_index.items() if m in NATURE_ATLAS}
        if not nat:
            return
        target = self._mi(nature_atlas_name(self.biome))
        margin = 0.06
        for f in self.bm.faces:
            if f.material_index in nat:
                qx, qy, _, _ = NATURE_ATLAS[nat[f.material_index]]
                uvs = [l[self.uv].uv.copy() for l in f.loops]
                mnu = min(u.x for u in uvs); mxu = max(u.x for u in uvs)
                mnv = min(u.y for u in uvs); mxv = max(u.y for u in uvs)
                su = max(mxu - mnu, 1e-6); sv = max(mxv - mnv, 1e-6)
                # keep texel density: a face spanning <=0.5 UV uses that much of the quadrant
                scale = min(1.0, 0.5 / max(su, sv)) * (0.5 - 2 * margin) / 0.5
                u0 = qx * 0.5 + margin
                v0 = (0.5 if qy == 0 else 0.0) + margin   # image row 0 (qy=0) = top = UV v 0.5..1
                for l, uv in zip(f.loops, uvs):
                    l[self.uv].uv = (u0 + (uv.x - mnu) * scale, v0 + (uv.y - mnv) * scale)
                f.material_index = target
        # drop the now-unused NAT_* slots and compact indices
        used = sorted({f.material_index for f in self.bm.faces})
        remap = {old: new for new, old in enumerate(used)}
        inv = {mi: m for m, mi in self.mat_index.items()}
        self.mat_index = {inv[old]: new for old, new in remap.items()}
        for f in self.bm.faces:
            f.material_index = remap[f.material_index]

    def finalize(self, collection=None):
        self._atlasize_nature()
        me = bpy.data.meshes.new(self.name)
        self.bm.normal_update()
        self.bm.to_mesh(me)
        self.bm.free()
        ordered = sorted(self.mat_index.items(), key=lambda kv: kv[1])
        for mat_id, _ in ordered:
            me.materials.append(get_material(mat_id))
        ob = bpy.data.objects.new(self.name, me)
        (collection or bpy.context.scene.collection).objects.link(ob)
        return ob


def _side_normal(a, b, f):
    return (b - a).cross(f).normalized()

def _ccw(pts, normal):
    """Return pts ordered so the polygon normal points along `normal`."""
    pts = [V(p) for p in pts]
    n = V((0, 0, 0))
    for i in range(len(pts)):
        a, b = pts[i], pts[(i + 1) % len(pts)]
        n.x += (a.y - b.y) * (a.z + b.z); n.y += (a.z - b.z) * (a.x + b.x); n.z += (a.x - b.x) * (a.y + b.y)
    if n.dot(V(normal)) < 0:
        pts.reverse()
    return pts

def box_uv(pts):
    """Planar projection on the dominant axis of the polygon normal, world-scaled."""
    n = V((0, 0, 0))
    for i in range(len(pts)):
        a, b = pts[i], pts[(i + 1) % len(pts)]
        n.x += (a.y - b.y) * (a.z + b.z); n.y += (a.z - b.z) * (a.x + b.x); n.z += (a.x - b.x) * (a.y + b.y)
    ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
    if az >= ax and az >= ay:
        return [(p.x * UVS, p.y * UVS) for p in pts]
    if ax >= ay:
        return [((p.y if n.x > 0 else -p.y) * UVS, p.z * UVS) for p in pts]
    return [((-p.x if n.y > 0 else p.x) * UVS, p.z * UVS) for p in pts]

# ----------------------------------------------------------------------------------------
# Common diorama pieces
# ----------------------------------------------------------------------------------------
def ground_pad(b, half_w, half_d, mat="PE_Dirt", edge_mat="PE_Dirt", h=0.08, seed=1):
    """Irregular dirt/grass diorama pad sitting on y=0 (top at +h). Stays inside the footprint."""
    rng = random.Random(seed)
    pts = []
    n = 20
    for i in range(n):
        a = 2 * math.pi * i / n
        # superellipse (squircle) outline with jitter
        ca, sa = math.cos(a), math.sin(a)
        ex = 2.6
        r = 1.0 / ((abs(ca) ** ex + abs(sa) ** ex) ** (1 / ex))
        j = 0.94 + rng.random() * 0.06
        pts.append((half_w * ca * r * j, half_d * sa * r * j))
    b.prism(pts, 0.0, h, edge_mat, top_mat=mat)

def reset_scene():
    """Remove every object/mesh/material in the CURRENT file (builds happen in a dedicated file)."""
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    for me in list(bpy.data.meshes):
        bpy.data.meshes.remove(me)
    for m in list(bpy.data.materials):
        bpy.data.materials.remove(m)

def mesh_stats(ob):
    me = ob.data
    tris = sum(len(p.vertices) - 2 for p in me.polygons)
    bb = [ob.matrix_world @ V(c) for c in ob.bound_box]
    mn = V((min(p.x for p in bb), min(p.y for p in bb), min(p.z for p in bb)))
    mx = V((max(p.x for p in bb), max(p.y for p in bb), max(p.z for p in bb)))
    return {"tris": tris, "verts": len(me.vertices), "materials": [m.name for m in me.materials],
            "bounds_min": [round(v, 3) for v in mn], "bounds_max": [round(v, 3) for v in mx]}

def export_asset(ob, civ, asset_id, kind="buildings", extra_meta=None, extra_objects=()):
    blend_dir = os.path.join(REPO_ROOT, "art_source", "blender", civ)
    glb_dir = os.path.join(GODOT_PROJECT, "assets", "3d", kind, civ)
    os.makedirs(blend_dir, exist_ok=True); os.makedirs(glb_dir, exist_ok=True)
    blend_path = os.path.join(blend_dir, asset_id + ".blend")
    glb_path = os.path.join(glb_dir, asset_id + ".glb")
    keep = {ob, *extra_objects}
    for o in bpy.context.scene.objects:
        o.select_set(o in keep)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.wm.save_as_mainfile(filepath=blend_path, relative_remap=True)
    # Materials are exported by NAME only (no images): Godot remaps every surface to the shared
    # library in res://assets/3d/materials/ (see export_material_library / FactionArtManager),
    # so textures are not duplicated per model and all buildings share the same materials.
    bpy.ops.export_scene.gltf(filepath=glb_path, export_format="GLB", use_selection=True,
                              export_apply=True, export_yup=True, export_image_format="NONE",
                              export_materials="EXPORT")
    meta = mesh_stats(ob)
    for xo in extra_objects:   # animated sub-parts (e.g. windmill "Sails") count towards the asset
        xs = mesh_stats(xo)
        meta["tris"] += xs["tris"]
        meta["materials"] = sorted(set(meta["materials"]) | set(xs["materials"]))
        meta.setdefault("parts", []).append(xo.name)
    meta.update({"asset_id": asset_id, "civ": civ, "kind": kind,
                 "blend": os.path.relpath(blend_path, REPO_ROOT),
                 "glb": "res://" + os.path.relpath(glb_path, GODOT_PROJECT),
                 "glb_bytes": os.path.getsize(glb_path)})
    if extra_meta:
        meta.update(extra_meta)
    with open(os.path.join(blend_dir, asset_id + ".meta.json"), "w") as fh:
        json.dump(meta, fh, indent=2)
    return meta


def env_script_path(file):
    """Repo-relative path of an environment build script (manifest metadata, no machine paths)."""
    return os.path.relpath(os.path.abspath(file), REPO_ROOT)


def export_material_library():
    """Write the shared Godot material library: textures + one StandardMaterial3D .tres each."""
    import shutil
    mat_dir = os.path.join(GODOT_PROJECT, "assets", "3d", "materials")
    tex_dir = os.path.join(mat_dir, "textures")
    os.makedirs(tex_dir, exist_ok=True)
    entries = []
    for mat_id, (pattern, ramp, rough, metal) in MATERIALS.items():
        bake_texture(mat_id)
        entries.append((mat_id, os.path.join(TEX_DIR, mat_id + ".png"), rough, metal, False))
    for biome in NATURE_BIOMES:
        bake_nature_atlas(biome)
        name = nature_atlas_name(biome)
        entries.append((name, os.path.join(TEX_DIR, name + ".png"), 0.95, 0.0, False))
    for fn in sorted(os.listdir(EMBLEM_DIR)):
        if fn.startswith("banner_") and fn.endswith(".png"):
            civ = fn[len("banner_"):-4]
            entries.append(("PE_Banner_" + civ, os.path.join(EMBLEM_DIR, fn), 0.95, 0.0, True))
    written = []
    for mat_id, src, rough, metal, double_sided in entries:
        shutil.copyfile(src, os.path.join(tex_dir, mat_id + ".png"))
        _pin_texture_import(os.path.join(tex_dir, mat_id + ".png"))
        lines = [
            '[gd_resource type="StandardMaterial3D" load_steps=2 format=3]',
            '',
            '[ext_resource type="Texture2D" path="res://assets/3d/materials/textures/%s.png" id="1_tex"]' % mat_id,
            '',
            '[resource]',
            'resource_name = "%s"' % mat_id,
            'albedo_texture = ExtResource("1_tex")',
            'roughness = %.2f' % rough,
            'metallic = %.2f' % metal,
            'metallic_specular = 0.3',
            'texture_filter = 2',          # NEAREST_WITH_MIPMAPS: crisp pixels, no shimmer at far zoom
        ]
        if double_sided:
            lines.append('cull_mode = 2')
        with open(os.path.join(mat_dir, mat_id + ".tres"), "w") as fh:
            fh.write("\n".join(lines) + "\n")
        written.append(mat_id)
    return written


# Pixel-art textures must stay lossless. Godot's default "Detect 3D" would VRAM-compress them the
# first time the editor sees them on a 3D material (smearing the pixels), so pin the importer.
_PINNED_PARAMS = {"compress/mode": "0", "mipmaps/generate": "true", "detect_3d/compress_to": "0"}

def _pin_texture_import(png_path):
    imp = png_path + ".import"
    if not os.path.exists(imp):
        with open(imp, "w") as fh:
            fh.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\n')
            for k, v in _PINNED_PARAMS.items():
                fh.write("%s=%s\n" % (k, v))
        return
    lines = open(imp).read().split("\n")
    seen = set()
    for i, ln in enumerate(lines):
        k = ln.split("=", 1)[0]
        if k in _PINNED_PARAMS:
            lines[i] = "%s=%s" % (k, _PINNED_PARAMS[k]); seen.add(k)
    for k, v in _PINNED_PARAMS.items():
        if k not in seen:
            lines.append("%s=%s" % (k, v))
    open(imp, "w").write("\n".join(lines))


def render_preview(ob, out_path, size=512, view=(0.0, -1.0, 1.0), ortho_pad=1.15):
    """Render a turntable-style preview of `ob` from the RTS camera direction (45 deg pitch,
    looking towards +Y) to `out_path`. Uses EEVEE (falls back to Workbench)."""
    import mathutils
    scene = bpy.context.scene
    for o in list(scene.objects):
        if o.type in {"CAMERA", "LIGHT"} and o.name.startswith("PE_Preview"):
            bpy.data.objects.remove(o, do_unlink=True)
    st = mesh_stats(ob)
    mn, mx = V(st["bounds_min"]), V(st["bounds_max"])
    centre = (mn + mx) / 2
    radius = (mx - mn).length / 2
    cam_data = bpy.data.cameras.new("PE_PreviewCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = radius * 2 * ortho_pad
    cam = bpy.data.objects.new("PE_PreviewCam", cam_data)
    scene.collection.objects.link(cam)
    d = V(view).normalized()
    cam.location = centre + d * (radius * 4)
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    sun_data = bpy.data.lights.new("PE_PreviewSun", "SUN")
    sun_data.energy = 3.2
    sun_data.color = (1.0, 0.95, 0.86)   # same warm key as Main3D.tscn DirectionalLight3D
    sun = bpy.data.objects.new("PE_PreviewSun", sun_data)
    sun.rotation_euler = (math.radians(48), 0, math.radians(-40))
    scene.collection.objects.link(sun)
    if scene.world is None:
        scene.world = bpy.data.worlds.new("PE_PreviewWorld")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == "BACKGROUND"), None)
    if bg:
        bg.inputs[0].default_value = (0.60, 0.65, 0.74, 1.0)   # Main3D ambient colour
        bg.inputs[1].default_value = 0.8
    engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE", "BLENDER_WORKBENCH"):
        if eng in engines:
            try:
                scene.render.engine = eng
                break
            except TypeError:
                continue
    scene.render.resolution_x = scene.render.resolution_y = size
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = out_path
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)
    bpy.data.objects.remove(sun, do_unlink=True)
    return out_path


# ----------------------------------------------------------------------------------------
# Ground scatter atlas (HD-2D environment pass): 64x128 RGBA, 4 columns x 8 rows of 16x16 sprites
#   row 0: grass tufts (lush) x4   row 1: flowers (red, yellow, white, violet)
#   row 2: dry tufts x2, ferns x2  row 3: pebbles x2, twigs, mushrooms
#   row 4 (autumn): leaf litter orange / red / gold, russet tuft
#   row 5 (desert): barrel cactus, dune grass x2, sun-bleached stones
#   row 6 (steppe): feather grass x2, purple thistle, lichen stone
#   row 7: reserved (transparent)
# Drawn bottom-centre anchored; alpha-cut in Godot (shaders/hd2d_scatter.gdshader).
# ----------------------------------------------------------------------------------------
def bake_scatter_atlas():
    S = 16
    ROWS = 8
    img = np.zeros((S * ROWS, TEX_SIZE, 4))
    def ramp(name):
        return [np.array(_hex(h) + [1.0]) for h in RAMPS[name]]
    def put(cell, x, y, col):
        cx, cy = cell
        if 0 <= x < S and 0 <= y < S:
            img[cy * S + y, cx * S + x] = col
    def tuft(cell, r, rng, blades=7, tall=11, spread=6):
        g = ramp(r)
        for b in range(blades):
            x0 = 8 + int(rng.integers(-spread // 2, spread // 2 + 1))
            lean = float(rng.uniform(-0.45, 0.45))
            h = int(rng.integers(tall - 5, tall + 1))
            for k in range(h):
                x = int(round(x0 + lean * k))
                y = 15 - k
                shade = 1 if k < 2 else (2 if k < h * 0.5 else (3 if k < h - 1 else 4))
                put(cell, x, y, g[shade])
    rng = np.random.default_rng(4321)
    for i in range(4):
        tuft((i, 0), "grass_lush", rng, blades=6 + i, tall=9 + i)
    flower_cols = ["#d8433a", "#f2c641", "#f3eedb", "#9a6bd3"]
    for i, fc in enumerate(flower_cols):
        tuft((i, 1), "grass_lush", rng, blades=5, tall=8, spread=6)
        c = np.array(_hex(fc) + [1.0]); dark = c * np.array([0.65, 0.65, 0.7, 1.0])
        for (fx, fy) in [(5, 6), (10, 4), (8, 8)][: 2 + (i % 2)]:
            for yy in range(fy + 2, 16):   # stem down to the ground
                put((i, 1), fx + (1 if yy % 3 == 0 else 0), yy, ramp("grass_lush")[2])
            for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
                put((i, 1), fx + dx, fy + dy, c if dy == 0 else dark)
            put((i, 1), fx, fy, np.array(_hex("#fff4c8") + [1.0]) if fc != "#f2c641" else np.array(_hex("#9c5a1c") + [1.0]))
    for i in range(2):
        tuft((i, 2), "grass_dry", rng, blades=6, tall=9 + i * 2)
    for i in range(2, 4):  # ferns: fronds as diagonal strokes
        g = ramp("foliage")
        for side in (-1, 1):
            for k in range(7):
                x = 8 + side * (k // 1) // 1
                y = 14 - k
                for t in range(3):
                    put((i, 2), 8 + side * (k + t) // 2, 15 - k - t // 2, g[2 + (t == 0) + (k > 4)])
        for k in range(10):
            put((i, 2), 8, 15 - k, g[1])
    stone = ramp("rock")
    for i in range(2):
        rx, ry = (3 + i, 2 + i)
        for y in range(-ry, ry + 1):
            for x in range(-rx, rx + 1):
                if (x * x) / ((rx + 0.5) ** 2) + (y * y) / ((ry + 0.5) ** 2) <= 1.0:
                    shade = 3 if y < 0 else (2 if y < ry else 1)
                    if y < 0 and x < 0:
                        shade = 4   # light from upper-left
                    put((i, 3), 8 + x, 13 + y, stone[shade])
        for x in range(-rx + 1, rx):
            put((i, 3), 8 + x, 14 + ry, np.array([0.1, 0.1, 0.12, 0.45]))
    wood = ramp("wood_dark")
    for k in range(10):
        put((2, 3), 3 + k, 13 - k // 4, wood[2 + (k % 3 == 0)])
    cap = np.array(_hex("#c4473a") + [1.0]); stem = np.array(_hex("#efe2c4") + [1.0])
    for (mx, my) in ((6, 12), (10, 13)):
        for x in range(-2, 3):
            put((3, 3), mx + x, my - 3, cap)
        for x in range(-1, 2):
            put((3, 3), mx + x, my - 4, cap)
        put((3, 3), mx - 1, my - 3, np.array(_hex("#f6efe0") + [1.0]))
        for y in range(3):
            put((3, 3), mx, my - y, stem)
    # ---- row 4: autumn leaf litter (flat-ish piles of 1-2 px leaves) + russet tuft
    def litter(cell, cols, rng, n=26):
        for _ in range(n):
            x = int(rng.integers(2, 14)); y = int(rng.integers(11, 16))
            c = np.array(_hex(cols[int(rng.integers(0, len(cols)))]) + [1.0])
            put(cell, x, y, c)
            if rng.random() < 0.5:
                put(cell, x + 1, y, c * np.array([0.8, 0.8, 0.8, 1.0]))
    litter((0, 4), ["#d97a26", "#f2b545", "#a8461c"], rng)
    litter((1, 4), ["#a8461c", "#6e2419", "#d97a26"], rng)
    litter((2, 4), ["#f2b545", "#e8c75a", "#c79a32"], rng)
    tuft((3, 4), "grass_autumn", rng, blades=7, tall=10)
    # ---- row 5: desert
    cac = ramp("palm")
    for y in range(7, 16):            # barrel cactus: ribbed 7 px wide body
        half = 3 if 9 <= y <= 14 else 2
        for x in range(-half, half + 1):
            shade = 3 if x < 0 else (2 if x < 2 else 1)
            if x % 2 == 0 and y % 2 == 0:
                shade = min(shade + 1, 4)
            put((0, 5), 8 + x, y, cac[shade])
    put((0, 5), 8, 6, np.array(_hex("#e8506a") + [1.0])); put((0, 5), 9, 6, np.array(_hex("#f6a0b0") + [1.0]))
    tuft((1, 5), "sand_dark", rng, blades=6, tall=11, spread=8)
    tuft((2, 5), "grass_dry", rng, blades=5, tall=8, spread=10)
    bone = [np.array(_hex(h) + [1.0]) for h in RAMPS["sand"]]
    for (bx, by, rx, ry) in ((5, 13, 2, 1), (10, 12, 3, 2)):
        for y in range(-ry, ry + 1):
            for x in range(-rx, rx + 1):
                if (x * x) / ((rx + 0.5) ** 2) + (y * y) / ((ry + 0.5) ** 2) <= 1.0:
                    put((3, 5), bx + x, by + y, bone[4 if y < 0 else 2])
    # ---- row 6: steppe
    tuft((0, 6), "grass_steppe", rng, blades=8, tall=13, spread=8)
    tuft((1, 6), "grass_steppe", rng, blades=6, tall=11, spread=10)
    tuft((2, 6), "foliage_steppe", rng, blades=5, tall=9, spread=6)
    th = np.array(_hex("#9a5cc4") + [1.0]); th2 = np.array(_hex("#c890e6") + [1.0])
    for (fx, fy) in ((6, 4), (10, 6)):
        for dx in range(-1, 2):
            put((2, 6), fx + dx, fy, th2 if dx < 1 else th)
            put((2, 6), fx + dx, fy + 1, th)
    gr = ramp("rock_granite"); lich = np.array(_hex("#a8b04a") + [1.0])
    for y in range(-3, 4):
        for x in range(-4, 5):
            if (x * x) / 20.0 + (y * y) / 10.0 <= 1.0:
                c = gr[3 if y < 0 else (2 if y < 2 else 1)]
                if y < 0 and x < -1:
                    c = gr[4]
                put((3, 6), 8 + x, 12 + y, c)
    for (x, y) in ((6, 10), (7, 10), (9, 11), (10, 9)):
        put((3, 6), x, y, lich)
    path = os.path.join(TEX_DIR, "SC_ScatterAtlas.png")
    im = bpy.data.images.get("SC_ScatterAtlas") or bpy.data.images.new("SC_ScatterAtlas", TEX_SIZE, S * ROWS, alpha=True)
    im.scale(TEX_SIZE, S * ROWS)
    im.pixels.foreach_set(np.flipud(img).astype(np.float32).ravel())
    im.filepath_raw = path; im.file_format = "PNG"; im.save()
    import shutil
    dst = os.path.join(GODOT_PROJECT, "assets", "3d", "materials", "textures", "SC_ScatterAtlas.png")
    shutil.copyfile(path, dst)
    _pin_texture_import(dst)
    return dst
