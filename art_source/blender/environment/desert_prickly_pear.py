"""Prickly pear (desert biome food): branching oval cactus pads crowned with red fruit.
2 surfaces (nature atlas + fruit red), like the temperate berry bush."""
import math, random
import pe_kit
from pe_kit import Builder
from env_parts import pad

CIV = "desert"
ASSET = "prickly_pear"
VARIANTS = [("desert", "desert")]


def build(seed=5, biome="desert"):
    pe_kit.reset_scene()
    rnd = random.Random(seed)
    b = Builder(ASSET, biome=biome)
    fruit_spots = []
    # three base pads; each grows 1-2 child pads from its top edge
    for i, (x, y, yaw) in enumerate(((0.0, 0.05, 0.2), (0.4, -0.2, 1.1), (-0.42, -0.12, -0.9))):
        tip, upv, ax = pad(b, (x, y, 0.28), yaw, rnd.uniform(-0.15, 0.15), 0.42, 0.56, 0.09)
        for s in ((-1, 1) if i == 0 else (rnd.choice((-1, 1)),)):
            child_c = tip + ax * (0.1 * s) + upv * 0.2
            ctip, _, cax = pad(b, child_c, yaw + rnd.uniform(-0.8, 0.8), 0.35 * s, 0.32, 0.42, 0.08)
            fruit_spots += [ctip + cax * 0.08, ctip - cax * 0.08]
        fruit_spots.append(tip + ax * 0.15)
    for p in fruit_spots:
        b.box((p.x, p.y, p.z + 0.04), (0.08, 0.08, 0.1), "PE_ClothRed")
    return b.finalize()


def run(export=True, civ=CIV, biome="desert"):
    ob = build(biome=biome)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="environment",
                                       extra_meta={"resource": "food", "biome": biome, "build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
