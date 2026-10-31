"""Desert stone deposit: a sandstone quarry face (stepped, squared-off outcrop) with cut blocks
stacked in front. Reads as quarried, not as natural boulders. 1 draw call."""
import math
import pe_kit
from pe_kit import Builder
from env_parts import rbox

CIV = "desert"
ASSET = "stone_mine"
VARIANTS = [("desert", "desert")]


def build(biome="desert"):
    pe_kit.reset_scene()
    b = Builder(ASSET, biome=biome)
    # stepped outcrop (back): three terraces, each a rotated squared block
    rbox(b, 0.0, 0.35, 0.0, 1.5, 0.8, 0.45, 0.08, "NAT_rock")
    rbox(b, 0.05, 0.42, 0.45, 1.15, 0.62, 0.35, 0.12, "NAT_rock")
    rbox(b, -0.1, 0.5, 0.8, 0.7, 0.45, 0.25, 0.02, "NAT_rock")
    rbox(b, 0.62, 0.05, 0.0, 0.5, 0.55, 0.55, -0.3, "NAT_rock")
    rbox(b, -0.66, 0.0, 0.0, 0.45, 0.5, 0.38, 0.35, "NAT_rock")
    # cut blocks in front (camera side)
    rbox(b, 0.25, -0.5, 0.0, 0.36, 0.26, 0.22, 0.15, "NAT_rock")
    rbox(b, -0.22, -0.55, 0.0, 0.32, 0.24, 0.2, -0.2, "NAT_rock")
    rbox(b, 0.02, -0.5, 0.22, 0.3, 0.22, 0.18, 0.05, "NAT_rock")
    rbox(b, -0.55, -0.6, 0.0, 0.2, 0.2, 0.15, 0.6, "NAT_rock")
    # wooden sledge/lever
    b.cylinder_between((0.45, -0.75, 0.05), (0.8, -0.35, 0.45), 0.035, "NAT_bark", segs=5, smooth=False)
    return b.finalize()


def run(export=True, civ=CIV, biome="desert"):
    ob = build(biome=biome)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="environment",
                                       extra_meta={"resource": "stone", "biome": biome, "build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
