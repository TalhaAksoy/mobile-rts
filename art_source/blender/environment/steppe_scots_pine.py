"""Scots pine (steppe biome tree, wood): tall red-barked trunk, wind-swept flat crown clumps
leaning to one side, the classic lone highland pine. 1 draw call."""
import math, random
import pe_kit
from pe_kit import Builder
from env_parts import blob

CIV = "steppe"
ASSET = "tree_scots_pine"
VARIANTS = [("steppe", "steppe")]


def build(seed=31, biome="steppe"):
    pe_kit.reset_scene()
    rnd = random.Random(seed)
    b = Builder(ASSET, biome=biome)
    b.cylinder_between((0, 0, 0), (0.12, 0.02, 1.2), 0.13, "NAT_bark", segs=6, smooth=False)
    b.cylinder_between((0.12, 0.02, 1.2), (0.3, 0.0, 2.0), 0.1, "NAT_bark", segs=6, smooth=False)
    b.cylinder_between((0.15, 0.02, 1.35), (-0.35, -0.05, 1.75), 0.05, "NAT_bark", segs=5, smooth=False)
    b.cylinder_between((0.22, 0.0, 1.6), (0.75, 0.1, 1.9), 0.05, "NAT_bark", segs=5, smooth=False)
    for (x, y, z), r, h in (((0.32, 0.0, 2.1), 0.62, 0.38), ((-0.38, -0.05, 1.82), 0.45, 0.3),
                            ((0.78, 0.1, 1.95), 0.42, 0.28), ((0.25, 0.05, 2.38), 0.42, 0.28)):
        blob(b, (x + rnd.uniform(-0.03, 0.03), y, z), r, h, "NAT_foliage", segs=8)
    return b.finalize()


def run(export=True, civ=CIV, biome="steppe"):
    ob = build(biome=biome)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="environment",
                                       extra_meta={"resource": "wood", "biome": biome, "build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
