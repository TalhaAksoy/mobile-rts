"""Date palm (desert biome tree, wood): ringed, gently curved trunk, arching V-folded fronds and
orange date clusters under the crown. Oasis silhouette that reads even at far zoom. 1 draw call."""
import math, random
import pe_kit
from pe_kit import Builder
from env_parts import frond

CIV = "desert"
ASSET = "tree_palm"
VARIANTS = [("desert", "desert")]


def build(seed=11, biome="desert"):
    pe_kit.reset_scene()
    rnd = random.Random(seed)
    b = Builder(ASSET, biome=biome)
    # trunk: 7 ring segments along a soft curve, alternating radius = the typical leaf-scar rings
    pts = []
    for k in range(8):
        t = k / 7
        pts.append((0.28 * t * t, -0.08 * t, 2.5 * t))
    for k in range(7):
        r = 0.15 - 0.03 * (k / 7)
        b.cylinder_between(pts[k], pts[k + 1], r * (1.12 if k % 2 == 0 else 1.0), "NAT_bark", segs=6, smooth=False)
    top = pts[-1]
    b.cylinder((top[0], top[1], top[2] - 0.08), 0.17, 0.22, "NAT_bark", segs=6, r_top=0.08, smooth=False)
    # fronds: two whorls (upper short/raised, lower long/drooping)
    n = 9
    for i in range(n):
        yaw = 2 * math.pi * i / n + rnd.uniform(-0.15, 0.15)
        frond(b, (top[0], top[1], top[2] + 0.1), yaw, rnd.uniform(1.25, 1.45), 0.2, 0.32, 1.0)
    for i in range(5):
        yaw = 2 * math.pi * (i + 0.5) / 5 + rnd.uniform(-0.2, 0.2)
        frond(b, (top[0], top[1], top[2] + 0.16), yaw, rnd.uniform(0.75, 0.9), 0.16, 0.42, 0.35, segs=3)
    # date clusters hanging under the crown, on the camera side
    for a in (-2.0, -1.2, -0.4):
        x = top[0] + 0.2 * math.cos(a); y = top[1] + 0.2 * math.sin(a)
        b.cylinder((x, y, top[2] - 0.32), 0.07, 0.28, "NAT_gold", segs=5, r_top=0.11, smooth=False)
    return b.finalize()


def run(export=True, civ=CIV, biome="desert"):
    ob = build(biome=biome)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="environment",
                                       extra_meta={"resource": "wood", "biome": biome, "build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
