"""Stone deposit (1 grid cell resource): pale quarry boulders with cut blocks. 1 draw call."""
import pe_kit
from pe_kit import Builder
from common_gold_mine import rock

CIV = "common"
ASSET = "stone_mine"


def build(biome="temperate"):
    pe_kit.reset_scene()
    b = Builder("stone_mine", biome=biome)
    rocks = [((0, 0.1, 0), 0.6, 0.9), ((0.55, -0.15, 0), 0.42, 0.62), ((-0.5, -0.2, 0), 0.45, 0.7),
             ((0.2, 0.6, 0), 0.38, 0.5), ((-0.3, 0.55, 0), 0.3, 0.42)]
    for i, (c, r, h) in enumerate(rocks):
        rock(b, c, r, h, "NAT_rock", seed=10 + i)
    # cut blocks at the front
    b.box((0.25, -0.62, 0.11), (0.34, 0.24, 0.22), "NAT_rock")
    b.box((-0.2, -0.68, 0.09), (0.28, 0.22, 0.18), "NAT_rock")
    b.box((0.05, -0.62, 0.3), (0.26, 0.2, 0.17), "NAT_rock")
    return b.finalize()


# (output folder, nature-atlas biome): the same geometry re-skinned per map biome
VARIANTS = [("common", "temperate"), ("steppe", "steppe")]


def run(export=True, civ=CIV, biome="temperate"):
    ob = build(biome=biome)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="environment",
                                       extra_meta={"resource": "stone", "biome": biome, "build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
