"""Rosehip / dog-rose bush (steppe biome food): arching thorny canes with small leaf clumps and
bright oval hips. Sparser and twiggier than the temperate berry bush. 2 surfaces."""
import math, random
import pe_kit
from pe_kit import Builder
from env_parts import blob

CIV = "steppe"
ASSET = "rosehip_bush"
VARIANTS = [("steppe", "steppe")]


def build(seed=17, biome="steppe"):
    pe_kit.reset_scene()
    rnd = random.Random(seed)
    b = Builder(ASSET, biome=biome)
    tips = []
    for i in range(6):
        a = 2 * math.pi * i / 6 + rnd.uniform(-0.3, 0.3)
        mid = (0.3 * math.cos(a), 0.3 * math.sin(a), 0.55)
        tip = (0.62 * math.cos(a), 0.55 * math.sin(a), 0.32)
        b.cylinder_between((0, 0, 0), mid, 0.035, "NAT_bark", segs=4, smooth=False)
        b.cylinder_between(mid, tip, 0.03, "NAT_bark", segs=4, smooth=False)
        tips.append((mid, tip))
    blob(b, (0, 0, 0.42), 0.4, 0.32, "NAT_foliage", segs=7)
    for mid, tip in tips[::2]:
        blob(b, ((mid[0] + tip[0]) / 2, (mid[1] + tip[1]) / 2, 0.42), 0.22, 0.18, "NAT_foliage", segs=6)
    for mid, tip in tips:
        for t in (0.55, 1.0):
            x = mid[0] + (tip[0] - mid[0]) * t; y = mid[1] + (tip[1] - mid[1]) * t; z = mid[2] + (tip[2] - mid[2]) * t
            b.box((x, y, z + 0.06), (0.07, 0.07, 0.11), "PE_ClothRed")
    for _ in range(6):
        a = rnd.uniform(math.pi * 0.95, math.pi * 2.05); rr = 0.36
        b.box((rr * math.cos(a), rr * math.sin(a), rnd.uniform(0.45, 0.7)), (0.07, 0.07, 0.11), "PE_ClothRed")
    return b.finalize()


def run(export=True, civ=CIV, biome="steppe"):
    ob = build(biome=biome)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="environment",
                                       extra_meta={"resource": "food", "biome": biome, "build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
