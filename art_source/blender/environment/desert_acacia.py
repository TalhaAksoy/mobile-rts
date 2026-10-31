"""Umbrella acacia (desert biome tree, wood): forked leaning trunk with a wide, flat, layered
canopy. Distinct flat-top silhouette next to the palms. 1 draw call."""
import math, random
import pe_kit
from pe_kit import Builder
from env_parts import blob

CIV = "desert"
ASSET = "tree_acacia"
VARIANTS = [("desert", "desert")]


def build(seed=21, biome="desert"):
    pe_kit.reset_scene()
    rnd = random.Random(seed)
    b = Builder(ASSET, biome=biome)
    b.cylinder_between((0, 0, 0), (0.1, 0, 0.95), 0.13, "NAT_bark", segs=6, smooth=False)
    tips = [(-0.55, -0.15, 1.75), (0.6, 0.1, 1.85), (0.05, 0.45, 1.8)]
    for t in tips:
        b.cylinder_between((0.1, 0, 0.9), t, 0.07, "NAT_bark", segs=5, smooth=False)
    # flat layered canopy: wide, very squashed clumps
    for (x, y, z), r in (((-0.55, -0.15, 1.8), 0.6), ((0.62, 0.1, 1.9), 0.62), ((0.05, 0.5, 1.86), 0.55),
                         ((0.05, -0.1, 1.98), 0.78)):
        blob(b, (x + rnd.uniform(-0.04, 0.04), y, z), r, 0.2, "NAT_foliage", segs=9)
    return b.finalize()


def run(export=True, civ=CIV, biome="desert"):
    ob = build(biome=biome)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="environment",
                                       extra_meta={"resource": "wood", "biome": biome, "build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
