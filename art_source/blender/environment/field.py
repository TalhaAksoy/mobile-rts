"""Farm field (2x2 grid plot = 4 m, built 3.8 m so neighbouring fields show a seam). Crop and
border follow the MAP biome (a field is farmland, not architecture):
  temperate: golden wheat rows, wattle fence      desert: green barley + irrigation canal, mud-brick kerb
  steppe:    pale rye rows, fieldstone cairns       autumn: harvested stubble, sheaves and pumpkins
A corner post carries a TEAM_Trim pennant so ownership reads from far. 2-5 surfaces."""
import math, random
import pe_kit
from pe_kit import Builder

CIV = "fields"
ASSET = "field"
VARIANTS = [("common", "temperate"), ("desert", "desert"), ("steppe", "steppe"), ("autumn", "autumn")]
CROP = {"temperate": "PE_CropWheat", "desert": "PE_CropGreen", "steppe": "PE_CropRye", "autumn": "PE_CropWheat"}
HALF = 1.9


def crop_row(b, y, h, mat, half=HALF - 0.25, w=0.46):
    """Triangular-section ridge of standing crop along X."""
    a = (-half, y - w / 2, 0.06); bb = (half, y - w / 2, 0.06)
    c = (half, y, 0.06 + h); d = (-half, y, 0.06 + h)
    e = (-half, y + w / 2, 0.06); f = (half, y + w / 2, 0.06)
    b.quad(a, bb, c, d, mat)           # camera-facing slope
    b.quad(f, e, d, c, mat)            # back slope
    b.poly([a, d, e], mat); b.poly([bb, f, c], mat)


def build(seed=3, biome="temperate"):
    pe_kit.reset_scene()
    rnd = random.Random(seed)
    b = Builder("field", biome=biome)
    b.box((0, 0, 0.03), (HALF * 2, HALF * 2, 0.06), "PE_Soil")
    crop = CROP[biome]
    rows = 7
    for i in range(rows):
        y = -HALF + 0.4 + i * (2 * HALF - 0.8) / (rows - 1)
        if biome == "autumn":
            crop_row(b, y, 0.1, crop, w=0.3)          # stubble after the harvest
        else:
            crop_row(b, y, 0.3 + rnd.uniform(-0.03, 0.03), crop)
    if biome == "temperate":                         # wattle fence on the back and left sides
        for k in range(9):
            t = -HALF + k * (2 * HALF) / 8
            b.box((t, HALF - 0.05, 0.2), (0.06, 0.06, 0.4), "PE_WoodDark")
            b.box((-HALF + 0.05, t, 0.2), (0.06, 0.06, 0.4), "PE_WoodDark")
        b.box((0, HALF - 0.05, 0.26), (2 * HALF, 0.04, 0.16), "PE_Thatch")
        b.box((-HALF + 0.05, 0, 0.26), (0.04, 2 * HALF, 0.16), "PE_Thatch")
    elif biome == "desert":                          # irrigation canal (front) + mud-brick kerb (back)
        b.box((0, -HALF + 0.14, 0.035), (2 * HALF - 0.1, 0.2, 0.05), "PE_Canal")
        b.box((0, HALF - 0.08, 0.1), (2 * HALF, 0.14, 0.2), "PE_Sandstone")
        b.box((HALF - 0.08, 0, 0.1), (0.14, 2 * HALF, 0.2), "PE_Sandstone")
    elif biome == "steppe":                          # fieldstone cairns at the corners
        for (x, y) in ((-HALF + 0.2, HALF - 0.2), (HALF - 0.2, HALF - 0.2), (HALF - 0.2, -HALF + 0.2)):
            b.cylinder((x, y, 0.0), 0.2, 0.18, "PE_StoneGrey", segs=6, r_top=0.14, smooth=False)
            b.cylinder((x, y, 0.18), 0.12, 0.12, "PE_StoneGrey", segs=5, r_top=0.06, smooth=False)
    elif biome == "autumn":                          # sheaves + pumpkins
        for (x, y) in ((-1.0, 0.6), (0.2, -0.5), (1.1, 0.9), (-0.4, -1.2)):
            b.cylinder((x, y, 0.06), 0.16, 0.42, "PE_CropWheat", segs=6, r_top=0.07, smooth=False)
            b.cylinder((x, y, 0.4), 0.07, 0.14, "PE_CropWheat", segs=6, r_top=0.16, smooth=False)
        for (x, y) in ((0.9, -1.0), (1.3, -0.4), (-1.3, -0.2), (-0.6, 1.2), (0.5, 0.3)):
            b.dome((x, y, 0.06), 0.17, "PE_Pumpkin", segs=8, rings=2, height=0.2, smooth=False)
            b.box((x, y, 0.27), (0.03, 0.03, 0.06), "PE_WoodDark")
    # ownership pennant on the front-right corner post
    px, py = HALF - 0.1, -HALF + 0.1
    b.box((px, py, 0.45), (0.06, 0.06, 0.9), "PE_WoodDark")
    b.box((px - 0.14, py, 0.78), (0.26, 0.02, 0.18), "TEAM_Trim")
    return b.finalize()


def run(export=True, civ="common", biome="temperate"):
    ob = build(biome=biome)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="environment",
                                       extra_meta={"resource": "field", "biome": biome, "build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
