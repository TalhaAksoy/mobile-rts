"""Juniper (steppe biome tree, wood): squat, irregular flame-shaped evergreen built from leaning
faceted cones. Low and dense: contrasts with the tall scots pine. 1 draw call."""
import math, random
import pe_kit
from pe_kit import Builder

CIV = "steppe"
ASSET = "tree_juniper"
VARIANTS = [("steppe", "steppe")]


def build(seed=41, biome="steppe"):
    pe_kit.reset_scene()
    rnd = random.Random(seed)
    b = Builder(ASSET, biome=biome)
    b.cylinder((0, 0, 0), 0.12, 0.35, "NAT_bark", segs=6, r_top=0.09, cap=False, smooth=False)
    for (x, y, z), r, h in (((0.0, 0.0, 0.25), 0.7, 1.55), ((0.32, -0.12, 0.2), 0.45, 1.05),
                            ((-0.3, 0.05, 0.2), 0.48, 1.2), ((0.1, 0.3, 0.3), 0.4, 0.9)):
        jx, jy = rnd.uniform(-0.04, 0.04), rnd.uniform(-0.04, 0.04)
        b.cylinder((x + jx, y + jy, z), r * 0.8, 0.12, "NAT_foliage", segs=7, r_top=r, cap=False, smooth=False)
        b.cone((x + jx, y + jy, z + 0.12), r, h, "NAT_foliage", segs=7, smooth=False)
    return b.finalize()


def run(export=True, civ=CIV, biome="steppe"):
    ob = build(biome=biome)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="environment",
                                       extra_meta={"resource": "wood", "biome": biome, "build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
