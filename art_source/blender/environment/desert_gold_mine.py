"""Desert gold deposit: wind-cut sandstone hoodoos (stacked, stepped strata) split by gold veins,
with a timber adit frame. Same footprint/height class as the temperate mine. 1 draw call."""
import math, random
import pe_kit
from pe_kit import Builder
from common_gold_mine import gold_crystals, CRYSTALS

CIV = "desert"
ASSET = "gold_mine"
VARIANTS = [("desert", "desert")]


def hoodoo(b, c, r, h, seed, segs=6):
    """Stacked strata: 3 slightly offset, shrinking drums with flat steps between them."""
    rnd = random.Random(seed)
    x, y, z = c
    tiers = 3
    for k in range(tiers):
        rr = r * (1.0 - 0.18 * k) ; hh = h / tiers
        ox, oy = rnd.uniform(-0.05, 0.05), rnd.uniform(-0.05, 0.05)
        b.cylinder((x + ox, y + oy, z + k * hh), rr, hh, "NAT_rock", segs=segs, r_top=rr * 0.9, smooth=False,
                   cap=(k == tiers - 1))
        if k < tiers - 1:   # ledge
            b.cylinder((x + ox, y + oy, z + (k + 1) * hh - 0.04), rr * 0.9, 0.04, "NAT_rock", segs=segs, smooth=False)


def build(biome="desert"):
    pe_kit.reset_scene()
    b = Builder(ASSET, biome=biome)
    for i, (c, r, h) in enumerate([((0, 0.15, 0), 0.6, 1.0), ((0.55, -0.15, 0), 0.38, 0.62),
                                   ((-0.52, -0.2, 0), 0.42, 0.7), ((0.2, 0.62, 0), 0.36, 0.5)]):
        hoodoo(b, c, r, h, seed=30 + i)
    gold_crystals(b, CRYSTALS)
    for x in (-0.32, 0.32):
        b.box((x, -0.72, 0.38), (0.08, 0.08, 0.76), "NAT_bark")
    b.box((0, -0.72, 0.78), (0.8, 0.09, 0.09), "NAT_bark")
    return b.finalize()


def run(export=True, civ=CIV, biome="desert"):
    ob = build(biome=biome)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="environment",
                                       extra_meta={"resource": "gold", "biome": biome, "build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
