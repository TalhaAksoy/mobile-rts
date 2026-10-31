"""Berry bush (1 grid cell resource, food): three chunky foliage clumps studded with red berries.
Replaces the last flat sprite resource. 2 surfaces (nature atlas + berry red)."""
import math, random
import pe_kit
from pe_kit import Builder

CIV = "common"
ASSET = "berry_bush"
BERRY_MAT = {"autumn": "PE_FeltBlue"}   # sloes read against orange autumn leaves


def build(seed=7, biome="temperate"):
    pe_kit.reset_scene()
    rnd = random.Random(seed)
    b = Builder("berry_bush", biome=biome)
    clumps = [((0.0, 0.05, 0.0), 0.55, 0.62), ((0.42, -0.18, 0.0), 0.38, 0.45), ((-0.4, -0.15, 0.0), 0.4, 0.48)]
    for (x, y, z), r, h in clumps:
        b.cylinder((x, y, z), r * 0.8, h * 0.3, "NAT_foliage", segs=8, r_top=r, cap=False, smooth=False)
        b.dome((x, y, z + h * 0.3), r, "NAT_foliage", segs=8, rings=2, height=h * 0.7, smooth=False)
    # berries: small red boxes on the camera-facing (-Y) and top surfaces
    for (cx, cy, cz), r, h in clumps:
        for _ in range(7):
            a = rnd.uniform(math.pi * 0.9, math.pi * 2.1)    # mostly front/sides
            el = rnd.uniform(0.15, 0.85)
            rr = r * math.cos(el * math.pi / 2) * 1.02
            px, py = cx + rr * math.cos(a), cy + rr * math.sin(a)
            pz = cz + h * 0.3 + h * 0.7 * math.sin(el * math.pi / 2) + 0.02
            b.box((px, py, pz), (0.09, 0.09, 0.09), BERRY_MAT.get(biome, "PE_ClothRed"))
    return b.finalize()


# (output folder, nature-atlas biome): the same geometry re-skinned per map biome
VARIANTS = [("common", "temperate"), ("autumn", "autumn")]


def run(export=True, civ=CIV, biome="temperate"):
    ob = build(biome=biome)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="environment",
                                       extra_meta={"resource": "food", "biome": biome, "build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
