"""Pine tree (1 grid cell resource, wood). Stylised stacked-cone conifer with slight tier
offsets so a forest of instances does not look stamped. One atlas material = 1 draw call."""
import math, random
import pe_kit
from pe_kit import Builder

CIV = "common"
ASSET = "tree_pine"


def build(seed=3, biome="temperate"):
    pe_kit.reset_scene()
    rnd = random.Random(seed)
    b = Builder("tree_pine", biome=biome)
    b.cylinder((0, 0, 0), 0.13, 0.75, "NAT_bark", segs=6, r_top=0.09, cap=False)
    tiers = [(0.5, 0.95, 0.72), (1.0, 0.78, 0.64), (1.45, 0.58, 0.58), (1.86, 0.36, 0.55)]
    for z, r, h in tiers:
        ox, oy = (rnd.random() - 0.5) * 0.06, (rnd.random() - 0.5) * 0.06
        # skirt under each tier so it reads solid from the 45-degree camera
        b.cylinder((ox, oy, z - 0.02), r * 0.78, 0.06, "NAT_foliage", segs=9, r_top=r, cap=False, smooth=False)
        b.cone((ox, oy, z + 0.04), r, h, "NAT_foliage", segs=9, smooth=False)
    return b.finalize()


# (output folder, nature-atlas biome): the same geometry re-skinned per map biome
VARIANTS = [("common", "temperate"), ("autumn", "autumn")]


def run(export=True, civ=CIV, biome="temperate"):
    ob = build(biome=biome)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="environment",
                                       extra_meta={"resource": "wood", "biome": biome, "build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
