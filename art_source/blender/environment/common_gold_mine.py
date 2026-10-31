"""Gold deposit (1 grid cell resource): grey boulder pile with gold veins/nuggets + a small
timber prop frame so it reads as a mine, not just rocks. 1 atlas draw call."""
import math, random
import pe_kit
from pe_kit import Builder

CIV = "common"
ASSET = "gold_mine"


def rock(b, c, r, h, mat, segs=7, seed=0):
    rnd = random.Random(seed)
    x, y, z = c
    b.cylinder((x, y, z), r, h * 0.45, mat, segs=segs, r_top=r * 0.85, cap=False, smooth=False)
    b.dome((x, y, z + h * 0.45), r * 0.85, mat, segs=segs, rings=2, height=h * 0.55, smooth=False)


# gold crystal clusters: large and bright enough to read as GOLD at far zoom
CRYSTALS = [((0.15, -0.35, 0.35), 0.17, 0.5, 0.25), ((-0.22, -0.32, 0.4), 0.15, 0.42, -0.3),
            ((0.45, -0.25, 0.2), 0.14, 0.38, 0.4), ((0.02, -0.05, 0.75), 0.16, 0.48, 0.1),
            ((-0.5, -0.4, 0.12), 0.12, 0.32, -0.45), ((0.25, 0.25, 0.8), 0.13, 0.36, 0.3),
            ((-0.3, 0.1, 0.7), 0.12, 0.34, -0.2), ((0.6, -0.5, 0.0), 0.1, 0.28, 0.5)]


def gold_crystals(b, crystals):
    import mathutils
    for (x, y, z), r, h, tilt in crystals:
        top = (x + tilt * 0.25, y - 0.12, z + h)
        b.cylinder_between((x, y, z), top, r, "NAT_gold", segs=5, smooth=False)
        # pointed tip
        d = (mathutils.Vector(top) - mathutils.Vector((x, y, z))).normalized()
        tip = mathutils.Vector(top) + d * r * 1.3
        ring = []
        ax = d.orthogonal().normalized(); ay = d.cross(ax)
        for k in range(5):
            ang = 2 * math.pi * k / 5
            ring.append(mathutils.Vector(top) + (ax * math.cos(ang) + ay * math.sin(ang)) * r)
        for k in range(5):
            b.mesh([ring[k], ring[(k + 1) % 5], tip.copy()], [(0, 1, 2)], [[(0, 0), (0.1, 0), (0.05, 0.15)]], "NAT_gold")


def build(biome="temperate"):
    pe_kit.reset_scene()
    b = Builder("gold_mine", biome=biome)
    rocks = [((0, 0.1, 0), 0.62, 0.95), ((0.55, -0.2, 0), 0.38, 0.55), ((-0.5, -0.25, 0), 0.42, 0.6),
             ((0.15, 0.62, 0), 0.4, 0.5), ((-0.25, -0.62, 0), 0.28, 0.35)]
    for i, (c, r, h) in enumerate(rocks):
        rock(b, c, r, h, "NAT_rock", seed=i)
    gold_crystals(b, CRYSTALS)
    # timber prop frame at the mine mouth
    for x in (-0.32, 0.32):
        b.box((x, -0.72, 0.38), (0.08, 0.08, 0.76), "NAT_bark")
    b.box((0, -0.72, 0.78), (0.8, 0.09, 0.09), "NAT_bark")
    return b.finalize()


# (output folder, nature-atlas biome): the same geometry re-skinned per map biome
VARIANTS = [("common", "temperate"), ("steppe", "steppe")]


def run(export=True, civ=CIV, biome="temperate"):
    ob = build(biome=biome)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="environment",
                                       extra_meta={"resource": "gold", "biome": biome, "build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
