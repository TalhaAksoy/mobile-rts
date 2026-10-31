"""Broadleaf (oak) tree: chunky low-poly canopy clusters on a forked trunk. 1 draw call."""
import math, random
import pe_kit
from pe_kit import Builder

CIV = "common"
ASSET = "tree_oak"


def build(seed=5, biome="temperate"):
    pe_kit.reset_scene()
    rnd = random.Random(seed)
    b = Builder("tree_oak", biome=biome)
    b.cylinder((0, 0, 0), 0.17, 1.0, "NAT_bark", segs=6, r_top=0.12, cap=False)
    b.cylinder_between((0, 0, 0.8), (0.32, 0.1, 1.35), 0.07, "NAT_bark", segs=5, smooth=False)
    b.cylinder_between((0, 0, 0.85), (-0.3, -0.05, 1.3), 0.07, "NAT_bark", segs=5, smooth=False)
    clusters = [((0, 0, 1.55), 0.82, 0.62), ((0.42, 0.12, 1.42), 0.55, 0.45), ((-0.4, -0.08, 1.38), 0.55, 0.45),
                ((0.05, 0.38, 1.4), 0.5, 0.42), ((0.0, -0.36, 1.45), 0.5, 0.42), ((0.08, 0.02, 1.95), 0.5, 0.4)]
    for (x, y, z), r, h in clusters:
        jx, jy = (rnd.random() - 0.5) * 0.08, (rnd.random() - 0.5) * 0.08
        b.cylinder((x + jx, y + jy, z - h * 0.35), r * 0.7, h * 0.35, "NAT_foliage", segs=8, r_top=r, cap=False, smooth=False)
        b.dome((x + jx, y + jy, z), r, "NAT_foliage", segs=8, rings=2, height=h, smooth=False)
    return b.finalize()


# (output folder, nature-atlas biome): the same geometry re-skinned per map biome
VARIANTS = [("common", "temperate"), ("autumn", "autumn")]


def run(export=True, civ=CIV, biome="temperate"):
    ob = build(biome=biome)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="environment",
                                       extra_meta={"resource": "wood", "biome": biome, "build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
