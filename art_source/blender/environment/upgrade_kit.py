"""Civilisation 'upgraded building' dressing. Attached by Building3D.set_upgrade_level(2) around ANY
building whose own technology was researched (TechData "level" effect). Modelled for a 3.6 m (2x2)
footprint (corners at +-1.8 m) and scaled in Godot to bigger footprints. It stays at the EDGES:
a low civ-masonry kerb, four civ corner pieces and two front standards with the civ banner and a
team-coloured pennant, so the building itself stays readable. Culture per civ:
  ottomans: lead-capped stone bollards     byzantines: brick piers with terracotta domelets
  britons:  timber posts, thatch caps      franks: stone pillars, slate spirelets, gilt finials
  mongols:  horse-tail standards (no kerb) teutons: dark buttress blocks with slate caps
  japanese: stone lanterns, nobori         saracens: sandstone pillars, teal domelets
  vikings:  carved posts with shields      chinese: red lacquer posts with lanterns, teal caps"""
import math
import pe_kit, parts
from pe_kit import Builder

ASSET = "upgrade_kit"
CIVS = ["ottomans", "byzantines", "britons", "franks", "mongols", "teutons", "japanese", "saracens", "vikings", "chinese"]
VARIANTS = [(c, "temperate") for c in CIVS]
KERB = {"ottomans": "PE_StoneWarm", "byzantines": "PE_StoneBrick", "britons": "PE_StoneGrey", "franks": "PE_StoneWarm",
        "mongols": None, "teutons": "PE_StoneGrey", "japanese": "PE_StoneGrey", "saracens": "PE_Sandstone",
        "vikings": "PE_WoodDark", "chinese": "PE_StoneGrey"}
E = 1.72   # corner position


def corner(b, civ, x, y):
    if civ == "ottomans":
        b.box((x, y, 0.3), (0.22, 0.22, 0.6), "PE_StoneWarm")
        b.cone((x, y, 0.6), 0.16, 0.3, "PE_DomeLead", segs=8)
        b.cylinder((x, y, 0.86), 0.02, 0.16, "PE_Gold", segs=4)
    elif civ == "byzantines":
        b.box((x, y, 0.3), (0.24, 0.24, 0.6), "PE_StoneBrick")
        b.dome((x, y, 0.6), 0.14, "PE_RoofRed", segs=8, rings=2)
    elif civ == "britons":
        b.box((x, y, 0.4), (0.13, 0.13, 0.8), "PE_WoodDark")
        b.cone((x, y, 0.78), 0.16, 0.2, "PE_Thatch", segs=6)
    elif civ == "franks":
        b.box((x, y, 0.35), (0.2, 0.2, 0.7), "PE_StoneWarm")
        b.pyramid_roof((x, y, 0.7), 0.2, 0.2, 0.32, "PE_RoofSlate", overhang=0.03)
        b.cylinder((x, y, 0.98), 0.018, 0.16, "PE_Gold", segs=4)
    elif civ == "mongols":
        b.cylinder((x, y, 0.0), 0.03, 1.5, "PE_WoodDark", segs=5)
        b.cone((x, y, 1.1), 0.12, 0.35, "PE_Felt", segs=7)                       # horse-tail tassel
        b.cylinder((x, y, 1.48), 0.05, 0.12, "PE_Gold", segs=5, r_top=0.0)
    elif civ == "teutons":
        b.box((x, y, 0.32), (0.3, 0.3, 0.64), "PE_StoneGrey")
        b.pyramid_roof((x, y, 0.64), 0.3, 0.3, 0.18, "PE_SlateDark", overhang=0.02)
    elif civ == "japanese":                                                      # toro stone lantern
        b.box((x, y, 0.06), (0.26, 0.26, 0.12), "PE_StoneGrey")
        b.cylinder((x, y, 0.12), 0.05, 0.36, "PE_StoneGrey", segs=6)
        b.box((x, y, 0.56), (0.2, 0.2, 0.16), "PE_PlasterWhite")
        b.pyramid_roof((x, y, 0.64), 0.24, 0.24, 0.14, "PE_StoneGrey", overhang=0.05)
    elif civ == "saracens":
        b.box((x, y, 0.32), (0.2, 0.2, 0.64), "PE_Sandstone")
        b.dome((x, y, 0.64), 0.12, "PE_TileTeal", segs=8, rings=2, height=0.18)
        b.cylinder((x, y, 0.8), 0.015, 0.12, "PE_Gold", segs=4)
    elif civ == "vikings":
        b.box((x, y, 0.45), (0.14, 0.14, 0.9), "PE_WoodDark")
        b.cone((x, y, 0.9), 0.1, 0.16, "PE_WoodLight", segs=4)
        f = (0, -1, 0) if y < 0 else (0, 1, 0)
        parts.round_shield(b, (x, y + (0.08 if y > 0 else -0.08), 0.55), f, r=0.13)
    elif civ == "chinese":
        b.box((x, y, 0.38), (0.12, 0.12, 0.76), "PE_LacquerRed")
        b.box((x, y, 0.62), (0.14, 0.14, 0.18), "PE_ClothRed")                 # paper lantern
        b.hip_roof((x, y, 0.76), 0.18, 0.18, 0.12, "PE_RoofTeal", overhang=0.05, curve=0.05)


def standard(b, civ, x, y):
    pole_mat = "PE_LacquerRed" if civ == "chinese" else "PE_WoodDark"
    h = 1.9 if civ != "japanese" else 2.1
    b.cylinder((x, y, 0.0), 0.035, h, pole_mat, segs=5)
    b.cylinder((x, y, h), 0.05, 0.06, "PE_Gold", segs=5)
    if civ == "japanese":           # nobori: tall narrow banner on an L-pole
        b.banner((x + 0.02, y - 0.04, h - 0.1), (0, -1, 0), 0.22, 0.95, civ, tail=False)
    else:
        b.banner((x, y - 0.04, h - 0.1), (0, -1, 0), 0.3, 0.6, civ)
    b.box((x, y - 0.03, h - 0.85), (0.2, 0.02, 0.12), "TEAM_Trim")            # team pennant board


def build(civ="ottomans"):
    pe_kit.reset_scene()
    b = Builder("upgrade_kit_" + civ)
    k = KERB[civ]
    if k:
        for (cx, cy, sx, sy) in ((0, -E, 2 * E, 0.16), (0, E, 2 * E, 0.16), (-E, 0, 0.16, 2 * E), (E, 0, 0.16, 2 * E)):
            b.box((cx, cy, 0.06), (sx, sy, 0.12), k)
    for x in (-E, E):
        for y in (-E, E):
            corner(b, civ, x, y)
    for x in (-0.95, 0.95):
        standard(b, civ, x, -E - 0.02)
    return b.finalize()


def run(export=True, civ="ottomans", biome="temperate"):
    ob = build(civ)
    if export:
        return ob, pe_kit.export_asset(ob, civ, ASSET, kind="upgrade_kits",
                                       extra_meta={"build_script": pe_kit.env_script_path(__file__)})
    return ob, pe_kit.mesh_stats(ob)
