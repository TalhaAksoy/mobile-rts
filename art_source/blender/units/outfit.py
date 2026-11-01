"""Builds one character (civ x role) on the shared rig from a style dict (unitstyle.STYLES).

Proportions follow the gallery sheets: chunky figures ~3.3 heads tall (big head, short legs, broad shoulders),
~1.8 m to the top of the head. Low-poly, flat-shaded; colour from the shared atlas: flat palette swatches, 16 px
patterns ("pat:<name>": embroidery, mail, lamellar, scale, fur, quilting, straw ...) fitted to each face, and the civ
emblems from the gallery flags on shields and banners ("emblem": <civ>). Small geometric details (trim bands,
crosses, crests, plumes, horns) carry what reads from the RTS camera.

Mounted units: build_mounted() builds the rider's upper body with the same functions, lifts it onto the saddle and
adds straddling legs plus the mount (horse or camel, optional barding).
"""
import math
import bmesh
from mathutils import Vector
from charkit import Body, BONES, mounted_bones, RIDER_DZ, MOUNT_DIMS

HEAD_Z = 1.46
HIP_Z = 0.68
R = math.radians


# ---------------------------------------------------------------------------------------------------------------
# legs / feet
# ---------------------------------------------------------------------------------------------------------------
def legs(b, s):
    trou = s.get("trousers", "brown")
    boot = s.get("boots", "brown_dark")
    baggy = s.get("legs", "straight") == "baggy"
    for side, x in (("L", 0.11), ("R", -0.11)):
        w = 0.19 if baggy else 0.16
        b.box((x, 0, 0.53), (w, w, 0.32), "thigh." + side, trou, taper=(0.9, 0.9))
        b.box((x, 0, 0.27), ((0.17 if baggy else 0.14), 0.15, 0.22), "shin." + side, s.get("shins", trou))
        bh = s.get("boot_h", 0.20)
        b.box((x, -0.005, 0.03 + bh / 2), (0.15, 0.17, bh), "shin." + side, boot)
        b.box((x, -0.075, 0.035), (0.14, 0.15, 0.07), "foot." + side, s.get("feet", boot))
        if s.get("boot_cuff"):
            b.box((x, -0.005, 0.03 + bh), (0.165, 0.185, 0.035), "shin." + side, s["boot_cuff"])
        if s.get("wraps"):                     # leg wrappings (Japanese / Viking)
            for k in range(3):
                b.box((x, 0, 0.12 + k * 0.07), (0.155, 0.165, 0.025), "shin." + side, s["wraps"])
        if s.get("greaves"):
            b.box((x, -0.06, 0.28), (0.12, 0.05, 0.24), "shin." + side, s["greaves"])


def rider_legs(b, s, bones):
    trou = s.get("trousers", "brown")
    boot = s.get("boots", "brown_dark")
    for side in ("L", "R"):
        h0, h1, _ = bones["thigh." + side]
        k1 = bones["shin." + side][1]
        f1 = bones["foot." + side][1]
        b.segment(h0, h1, 0.17, 0.18, "thigh." + side, trou)
        b.segment(h1, k1, 0.15, 0.16, "shin." + side, boot)
        b.segment(k1, f1, 0.13, 0.12, "foot." + side, boot)


# ---------------------------------------------------------------------------------------------------------------
# torso
# ---------------------------------------------------------------------------------------------------------------
def torso(b, s):
    shirt = s.get("shirt", "white")
    armor = s.get("armor")                 # worn over the shirt, under coat / surcoat
    core = armor or shirt
    b.box((0, 0, 0.92), (0.42, 0.28, 0.18), "spine", core)
    b.box((0, 0, 1.10), (0.50, 0.31, 0.22), "chest", core, taper=(1.04, 1.0))
    if s.get("armor_skirt"):               # mail / lamellar skirt below the waist
        al = s.get("armor_skirt_len", 0.22)
        b.box((0, 0, 0.80 - al / 2), (0.47, 0.30, al), "hips", s["armor_skirt"], taper=(0.95, 0.95))
    coat = s.get("coat")
    if coat:                               # open-front coat / kaftan / deel
        for x in (0.13, -0.13):
            b.box((x, -0.012, 1.02), (0.23, 0.29, 0.38), "chest", coat)
        b.box((0, 0.035, 1.02), (0.50, 0.23, 0.38), "chest", coat)
        sk = s.get("skirt_len", 0.34)
        for x in (0.125, -0.125):
            b.box((x, -0.005, 0.80 - sk / 2), (0.23, 0.30, sk), "hips", coat, taper=(0.92, 0.95))
        b.box((0, 0.045, 0.80 - sk / 2), (0.46, 0.21, sk), "hips", coat, taper=(0.92, 0.95))
        trim = s.get("trim")
        if trim:
            for x in (0.025, -0.025):
                b.box((x, -0.16, 1.00), (0.035, 0.02, 0.42), "chest", trim)
            b.box((0, -0.005, 0.80 - sk + 0.02), (0.48, 0.31, 0.04), "hips", trim)
            b.box((0, -0.01, 1.215), (0.30, 0.30, 0.03), "chest", trim)
    if s.get("robe"):                      # closed robe crossing at the front (Chinese / Japanese / Saracen)
        b.box((0, 0, 1.02), (0.50, 0.30, 0.40), "chest", s["robe"])
        rl = s.get("robe_len", 0.32)
        b.box((0, 0, 0.82 - rl / 2), (0.47, 0.29, rl), "hips", s["robe"], taper=(0.96, 0.96))
        if s.get("robe_trim"):
            b.box((0.06, -0.152, 1.06), (0.05, 0.02, 0.30), "chest", s["robe_trim"], rot=(0, R(-28), 0))
            b.box((0, -0.005, 0.82 - rl + 0.02), (0.49, 0.30, 0.04), "hips", s["robe_trim"])
    if s.get("vest"):
        for x in (0.14, -0.14):
            b.box((x, -0.012, 1.04), (0.20, 0.30, 0.30), "chest", s["vest"])
        b.box((0, 0.035, 1.04), (0.48, 0.23, 0.30), "chest", s["vest"])
    if s.get("tunic"):                     # surcoat / tunic over the armour
        b.box((0, 0, 1.02), (0.51, 0.32, 0.40), "chest", s["tunic"])
        tl = s.get("tunic_len", 0.30)
        b.box((0, 0, 0.82 - tl / 2), (0.48, 0.31, tl), "hips", s["tunic"], taper=(0.96, 0.96))
        if s.get("tunic_trim"):
            b.box((0, -0.005, 0.82 - tl + 0.02), (0.49, 0.32, 0.04), "hips", s["tunic_trim"])
            b.box((0, -0.005, 1.215), (0.32, 0.32, 0.03), "chest", s["tunic_trim"])
    if s.get("cuirass"):                   # plate / lamellar chest piece over the robe
        b.box((0, -0.005, 1.04), (0.53, 0.33, 0.32), "chest", s["cuirass"])
        if s.get("cuirass_trim"):
            b.box((0, -0.17, 1.19), (0.40, 0.02, 0.04), "chest", s["cuirass_trim"])
            b.box((0, -0.17, 0.89), (0.46, 0.02, 0.04), "chest", s["cuirass_trim"])
        if s.get("tassets"):               # hanging armour flaps (kusazuri / Chinese skirt plates)
            for x in (0.16, 0.0, -0.16):
                b.box((x, -0.02, 0.72), (0.16, 0.30, 0.18), "hips", s["tassets"], rot=(R(4), 0, 0))
    chest = s.get("chest_cross")           # heraldic cross on the chest (Teutons / Britons)
    if chest:
        b.box((0, -0.168, 1.03), (0.07, 0.02, 0.30), "chest", chest)
        b.box((0, -0.168, 1.08), (0.24, 0.02, 0.07), "chest", chest)
    if s.get("chest_emblem"):
        b.plate([(-0.09, -0.09), (0.09, -0.09), (0.09, 0.09), (-0.09, 0.09)], 0.01, (0, -0.172, 1.06), (0, 0, 0),
                "chest", "gold", "gold", emblem=s["chest_emblem"])
    # belt + team sash
    b.box((0, 0, 0.83), (0.47, 0.32, 0.08), "hips", "TEAM")
    if s.get("belt"):
        b.box((0, 0, 0.885), (0.48, 0.325, 0.035), "spine", s["belt"])
        if s.get("buckle"):
            b.box((0, -0.168, 0.885), (0.06, 0.02, 0.05), "spine", s["buckle"])
    if s.get("crossbelt"):
        b.box((0, -0.165, 1.03), (0.05, 0.02, 0.48), "chest", s["crossbelt"], rot=(0, R(38), 0))
    sh = s.get("shoulders")
    if sh:
        kind = s.get("shoulder_kind", "pad")
        for side, x in (("L", 1), ("R", -1)):
            if kind == "sode":             # big rectangular Japanese shoulder plates
                b.box((0.33 * x, 0, 1.08), (0.06, 0.28, 0.26), "upperarm." + side, sh, rot=(0, R(-14 * x), 0))
            elif kind == "fur":            # fur mantle lumps
                b.ball((0.22 * x, 0.0, 1.21), (0.24, 0.34, 0.16), "chest", sh, segs=8, rings=5)
            else:
                b.box((0.29 * x, 0, 1.18), (0.18, 0.28, 0.10), "upperarm." + side, sh)
    if s.get("collar"):                    # fur collar / mantle around the neck
        b.torus((0, 0.0, 1.22), 0.19, 0.07, "chest", s["collar"], segs=10, tube_segs=4)
    cape = s.get("cape")
    if cape:                               # cape hanging from the shoulders down the back
        cl = s.get("cape_len", 0.78)
        b.box((0, 0.19, 1.20 - cl / 2), (0.52, 0.04, cl), "chest", cape, taper=(1.15, 1.0), rot=(R(-6), 0, 0))
        if s.get("cape_trim"):
            b.box((0, 0.205, 1.20 - cl + 0.02), (0.60, 0.05, 0.04), "chest", s["cape_trim"])
        if s.get("cape_cross"):
            b.box((0, 0.215, 0.92), (0.06, 0.02, 0.26), "chest", s["cape_cross"])
            b.box((0, 0.215, 0.98), (0.22, 0.02, 0.06), "chest", s["cape_cross"])


def arms(b, s):
    sleeve = s.get("sleeve", s.get("coat") or s.get("robe") or s.get("tunic") or s.get("shirt", "white"))
    skin = s.get("skin", "skin")
    for side, x in (("L", 1), ("R", -1)):
        b.box((0.305 * x, 0, 1.05), (0.15, 0.16, 0.26), "upperarm." + side, sleeve)
        b.box((0.34 * x, -0.015, 0.83), (0.14, 0.15, 0.22), "forearm." + side,
              s.get("bracers") or s.get("cuff", sleeve))
        b.box((0.35 * x, -0.04, 0.68), (0.12, 0.12, 0.11), "hand." + side, s.get("gloves", skin))
        if s.get("bare_arms"):             # berserker: bare skin with tattoos
            b.box((0.305 * x, -0.005, 1.05), (0.152, 0.162, 0.20), "upperarm." + side, s.get("arm_skin", skin))
            b.box((0.305 * x, -0.085, 1.07), (0.08, 0.01, 0.10), "upperarm." + side, "tattoo")


# ---------------------------------------------------------------------------------------------------------------
# head
# ---------------------------------------------------------------------------------------------------------------
def head(b, s):
    skin = s.get("skin", "skin")
    b.ball((0, 0.0, HEAD_Z), (0.50, 0.48, 0.52), "head", skin, segs=10, rings=7)
    for x in (0.245, -0.245):
        b.box((x, 0.0, HEAD_Z - 0.01), (0.05, 0.08, 0.10), "head", skin)
    b.box((0, -0.245, HEAD_Z - 0.035), (0.06, 0.05, 0.07), "head", s.get("skin_dark", "skin_dark"))
    brow = s.get("brows", s.get("beard") or s.get("hair") or "hair_black")
    for x in (0.085, -0.085):
        b.box((x, -0.225, HEAD_Z + 0.03), (0.045, 0.03, 0.06), "head", "eye")
        b.box((x, -0.228, HEAD_Z + 0.085), (0.08, 0.03, 0.025), "head", brow)
    beard = s.get("beard")
    if beard:
        kind = s.get("beard_kind", "full")
        if kind in ("full", "long"):
            b.box((0, -0.17, HEAD_Z - 0.17), (0.30, 0.12, 0.12), "head", beard)
            b.box((0, -0.19, HEAD_Z - 0.23), (0.16, 0.08, 0.06), "head", beard)
            if kind == "long":
                b.box((0, -0.20, HEAD_Z - 0.31), (0.12, 0.06, 0.12), "head", beard)
        if kind == "goatee":
            b.box((0, -0.21, HEAD_Z - 0.18), (0.10, 0.06, 0.10), "head", beard)
        b.box((0, -0.245, HEAD_Z - 0.085), (0.18, 0.03, 0.035), "head", beard)          # moustache
    if s.get("veil"):                      # face veil (Saracen archer / mamluk)
        b.box((0, -0.16, HEAD_Z - 0.13), (0.44, 0.16, 0.18), "head", s["veil"])
    hair = s.get("hair")
    if hair:                               # hair on the top and back of the head, the brow stays free
        b.box((0, 0.10, HEAD_Z + 0.0), (0.49, 0.26, 0.38), "head", hair)
        b.half_ball((0, 0.05, HEAD_Z + 0.11), (0.52, 0.50, 0.34), "head", hair, segs=10)
        if s.get("topknot"):
            b.ball((0, 0.06, HEAD_Z + 0.30), (0.14, 0.14, 0.14), "head", hair)
        if s.get("braids"):
            for x in (0.2, -0.2):
                b.box((x, -0.02, HEAD_Z - 0.22), (0.06, 0.06, 0.26), "head", hair)


def headwear(b, s):
    kind = s.get("hat")
    z = HEAD_Z
    col = s.get("hat_color", "steel")
    if kind == "turban":
        b.half_ball((0, 0.0, z + 0.12), (0.44, 0.44, 0.50), "head", s.get("hat_cap", "red"), segs=10, rings=6)
        b.cyl((0, 0, z + 0.36), 0.03, 0.08, "head", s.get("hat_cap", "red"), segs=6)
        for i, (r, dz) in enumerate(((0.27, 0.11), (0.26, 0.18), (0.235, 0.245), (0.19, 0.30))):
            b.torus((0, 0.0, z + dz), r, 0.07 - i * 0.01, "head", col, rot=(R(6 * (i % 2) - 3), 0, 0), segs=12, tube_segs=4)
        if s.get("turban_tail"):
            b.box((0.0, 0.25, z - 0.05), (0.12, 0.05, 0.40), "head", col, rot=(R(-12), 0, 0))
    elif kind == "bork":
        b.cyl((0, 0.0, z + 0.17), 0.265, 0.11, "head", s.get("hat_band", "gold"), segs=10)
        b.cyl((0, 0.03, z + 0.43), 0.245, 0.42, "head", col, segs=10, r2=0.21)
        b.box((0, 0.20, z + 0.36), (0.36, 0.09, 0.50), "head", col, rot=(R(-12), 0, 0))
        b.box((0, -0.235, z + 0.34), (0.12, 0.04, 0.26), "head", s.get("hat_band", "gold"))
        b.box((0, -0.25, z + 0.36), (0.05, 0.02, 0.18), "head", "red")
    elif kind == "hood":
        # hood sits on the back of the head and frames the face; a short shoulder cape below
        lin = s.get("hood_lining", col)
        b.half_ball((0, 0.06, z - 0.01), (0.58, 0.56, 0.66), "head", col, segs=10, rings=6)
        b.box((0, 0.20, z - 0.10), (0.48, 0.14, 0.30), "head", col)
        b.torus((0, -0.03, z + 0.01), 0.25, 0.035, "head", lin, rot=(R(90), 0, 0), segs=12, tube_segs=4)
        b.box((0, 0.02, z - 0.27), (0.58, 0.44, 0.10), "chest", col)
        b.box((0, -0.05, z - 0.33), (0.52, 0.36, 0.06), "chest", col)
        if s.get("hood_point"):
            b.box((0, 0.32, z + 0.06), (0.10, 0.14, 0.22), "head", col, rot=(R(-35), 0, 0))
    elif kind == "coif":                   # mail hood under a helmet (also used alone)
        b.half_ball((0, 0.02, z + 0.02), (0.56, 0.56, 0.60), "head", s.get("coif", "pat:mail_iron"), segs=10)
        for x in (0.25, -0.25):
            b.box((x, -0.06, z - 0.08), (0.05, 0.28, 0.30), "head", s.get("coif", "pat:mail_iron"))
        b.box((0, 0.02, z - 0.27), (0.54, 0.40, 0.09), "chest", s.get("coif", "pat:mail_iron"))
    if kind in ("helm_nasal", "helm_spangen", "helm_byz", "helm_mongol", "helm_chinese"):
        if s.get("coif"):
            headwear(b, dict(s, hat="coif"))
        b.half_ball((0, 0, z + 0.08), (0.54, 0.54, 0.56 if kind != "helm_nasal" else 0.66), "head", col, segs=10, rings=6)
        b.torus((0, 0, z + 0.10), 0.27, 0.025, "head", s.get("helm_band", col), segs=12, tube_segs=4)
        if kind in ("helm_nasal", "helm_spangen"):
            b.box((0, -0.27, z + 0.02), (0.05, 0.03, 0.18), "head", s.get("helm_band", col))
        if kind == "helm_spangen":
            for a in (0, 90):
                b.box((0, 0, z + 0.25), (0.035, 0.56, 0.03), "head", "bronze", rot=(0, 0, R(a)))
            for x in (0.09, -0.09):        # spectacle guard
                b.torus((x, -0.255, z + 0.03), 0.045, 0.012, "head", col, rot=(R(90), 0, 0), segs=8, tube_segs=4)
        if kind == "helm_nasal":
            b.cyl((0, 0, z + 0.43), 0.035, 0.08, "head", col, r2=0.0, segs=6)
        if kind == "helm_byz":
            b.box((0, 0.02, z + 0.38), (0.06, 0.40, 0.10), "head", "gold")
            b.box((0, 0.02, z + 0.47), (0.08, 0.44, 0.14), "head", s.get("plume", "purple"), taper=(1.0, 1.1))
            for x in (0.24, -0.24):        # cheek guards
                b.box((x, -0.10, z - 0.10), (0.04, 0.16, 0.20), "head", col)
        if kind == "helm_mongol":
            b.torus((0, 0, z + 0.08), 0.29, 0.06, "head", s.get("fur", "fur"), segs=12, tube_segs=4)
            b.cyl((0, 0, z + 0.40), 0.03, 0.14, "head", "gold", segs=6)
            b.box((0, 0.04, z + 0.52), (0.07, 0.16, 0.16), "head", s.get("plume", "blue"), rot=(R(-30), 0, 0))
            b.box((0, 0.20, z - 0.10), (0.42, 0.06, 0.30), "head", s.get("neck_guard", "pat:lamellar_brown"))
        if kind == "helm_chinese":
            b.cyl((0, 0, z + 0.40), 0.03, 0.10, "head", "gold", segs=6)
            b.box((0, 0.0, z + 0.53), (0.10, 0.12, 0.18), "head", s.get("plume", "red"), taper=(1.4, 1.4))
            for x in (0.25, -0.25):
                b.box((x, 0.02, z - 0.10), (0.05, 0.24, 0.26), "head", s.get("flaps", "pat:lamellar_red"))
            b.box((0, -0.27, z + 0.14), (0.20, 0.03, 0.06), "head", "gold")
    elif kind == "helm_kettle":            # round helm with a brim (Britons)
        if s.get("coif"):
            headwear(b, dict(s, hat="coif"))
        b.half_ball((0, 0, z + 0.10), (0.52, 0.52, 0.52), "head", col, segs=10, rings=6)
        b.cyl((0, 0, z + 0.11), 0.34, 0.03, "head", col, segs=12)
    elif kind == "helm_great":             # Teutonic knight's great helm with a gold cross
        b.cyl((0, 0, z + 0.06), 0.27, 0.56, "head", col, segs=10)
        b.half_ball((0, 0, z + 0.34), (0.54, 0.54, 0.20), "head", col, segs=10)
        b.box((0, -0.27, z + 0.08), (0.30, 0.02, 0.05), "head", "black_cloth")      # eye slit
        b.box((0, -0.272, z + 0.0), (0.06, 0.02, 0.36), "head", s.get("helm_band", "gold"))
        b.box((0, -0.272, z + 0.08), (0.30, 0.02, 0.06), "head", s.get("helm_band", "gold"))
        for k in range(3):
            b.box((0.10 - k * 0.1, -0.272, z - 0.12), (0.025, 0.02, 0.025), "head", "black_cloth")
        if s.get("plume"):                 # crest of feathers (Frankish knight)
            b.box((0.05, 0.02, z + 0.50), (0.10, 0.30, 0.22), "head", s["plume"], taper=(1.3, 1.4), rot=(0, R(10), 0))
            b.box((-0.06, 0.02, z + 0.48), (0.10, 0.26, 0.18), "head", s.get("plume2", "white"), taper=(1.3, 1.4), rot=(0, R(-14), 0))
    elif kind == "kabuto":                 # samurai helmet: bowl, flared neck guard, gold kuwagata horns
        b.half_ball((0, 0, z + 0.10), (0.56, 0.56, 0.52), "head", col, segs=10, rings=6)
        for i, (r, dz) in enumerate(((0.30, 0.02), (0.33, -0.05), (0.36, -0.12))):    # neck guard, behind the face
            b.cyl((0, 0.13, z + dz), r, 0.05, "head", s.get("shikoro", "pat:plates_red"), segs=10, r2=r - 0.04)
        # kuwagata: a gold V rising from the crest plate on the forehead
        base = Vector((0, -0.27, z + 0.20))
        for x in (1, -1):
            b.segment(base, base + Vector((0.16 * x, -0.04, 0.30)), 0.045, 0.025, "head", "gold")
            b.segment(base + Vector((0.16 * x, -0.04, 0.30)), base + Vector((0.24 * x, -0.06, 0.40)), 0.04, 0.025, "head", "gold")
        b.box(tuple(base), (0.12, 0.04, 0.09), "head", "gold")
    elif kind == "jingasa":                # conical lacquered (or straw) hat
        b.cyl((0, 0, z + 0.20), 0.46, 0.20, "head", col, segs=12, r2=0.06)
        b.cyl((0, 0, z + 0.10), 0.47, 0.02, "head", s.get("hat_rim", col), segs=12)
        if s.get("hat_mon"):
            b.box((0, -0.30, z + 0.20), (0.10, 0.02, 0.08), "head", s["hat_mon"], rot=(R(-30), 0, 0))
    elif kind == "straw_hat":
        b.cyl((0, 0, z + 0.22), 0.50, 0.24, "head", s.get("hat_color", "pat:straw_hat"), segs=12, r2=0.04)
        b.box((0, -0.20, z - 0.14), (0.02, 0.02, 0.20), "head", "brown_dark")
    elif kind == "hachimaki":
        b.torus((0, 0, z + 0.13), 0.255, 0.035, "head", "white", segs=12, tube_segs=4)
        b.box((0, -0.27, z + 0.13), (0.07, 0.02, 0.06), "head", "red")
        b.box((0, 0.26, z + 0.12), (0.05, 0.10, 0.04), "head", "white")
        for x in (0.05, -0.05):
            b.box((x, 0.32, z + 0.06), (0.04, 0.02, 0.16), "head", "white", rot=(R(20), 0, R(15 * (1 if x > 0 else -1))))
    elif kind == "fur_hat":                # Mongol villager: fur brim, blue crown
        b.half_ball((0, 0, z + 0.12), (0.46, 0.46, 0.46), "head", s.get("hat_cap", "blue"), segs=10)
        b.torus((0, 0, z + 0.12), 0.27, 0.07, "head", s.get("fur", "pat:fur_white"), segs=12, tube_segs=4)
        b.ball((0, 0, z + 0.36), (0.08, 0.08, 0.08), "head", "gold")
    elif kind == "wolf_pelt":              # berserker: wolf head over the head, pelt down the back
        b.half_ball((0, 0.02, z + 0.10), (0.58, 0.60, 0.50), "head", "pat:fur_wolf", segs=10)
        b.box((0, -0.27, z + 0.22), (0.30, 0.22, 0.14), "head", "pat:fur_wolf", taper=(0.6, 0.8))      # snout
        b.box((0, -0.39, z + 0.20), (0.10, 0.06, 0.06), "head", "hair_black")
        for x in (0.15, -0.15):
            b.box((x, 0.0, z + 0.36), (0.08, 0.06, 0.14), "head", "pat:fur_wolf", taper=(0.3, 0.6))
            b.box((x * 0.8, -0.20, z + 0.26), (0.04, 0.02, 0.025), "head", "yellow")
        b.box((0, 0.20, z - 0.30), (0.50, 0.08, 0.70), "chest", "pat:fur_wolf", taper=(1.15, 1.0), rot=(R(-8), 0, 0))
        for x in (0.20, -0.20):            # forelegs of the pelt over the shoulders
            b.box((x, -0.06, z - 0.30), (0.10, 0.10, 0.26), "chest", "pat:fur_wolf")


# ---------------------------------------------------------------------------------------------------------------
# weapons (right hand unless noted) and shields (left forearm)
# ---------------------------------------------------------------------------------------------------------------
def weapon(b, s, hand=(-0.35, -0.05, 0.68)):
    kind = s.get("weapon")
    hx, hy, hz = hand
    blade = s.get("blade", "steel")
    if kind in ("scimitar", "sword", "katana", "dao"):
        b.box((hx, hy, hz + 0.03), (0.05, 0.05, 0.15 if kind != "katana" else 0.24), "hand.R", s.get("grip", "brown_dark"))
        guard = s.get("guard", "gold")
        if kind == "katana":
            b.cyl((hx, hy, hz - 0.06), 0.06, 0.025, "hand.R", guard, segs=8)
        else:
            b.box((hx, hy, hz - 0.06), (0.20 if kind == "sword" else 0.16, 0.05, 0.03), "hand.R", guard)
        n, length = (5, 0.56) if kind == "katana" else (4, 0.50 if kind == "sword" else 0.48)
        curve = {"scimitar": 0.10, "katana": 0.05, "dao": 0.07, "sword": 0.0}[kind]
        width = {"scimitar": 0.075, "katana": 0.045, "dao": 0.09, "sword": 0.06}[kind]
        for i in range(n):
            t = (i + 0.5) / n
            off = curve * t * t
            w = width * (1.0 + (0.35 * t if kind == "dao" else 0.0))
            b.box((hx, hy - off, hz - 0.08 - length * t), (0.03, w, length / n + 0.01), "hand.R", blade,
                  rot=(R(-curve * 160 * t), 0, 0))
    elif kind in ("spear", "yari", "lance"):
        length = 2.0 if kind != "lance" else 2.6
        lift = 0.36 if kind != "lance" else 0.6       # butt end just above the ground (foot) / the hand (mounted)
        b.cyl((hx, hy, hz + lift), 0.022 if kind != "lance" else 0.03, length, "hand.R", s.get("shaft", "wood"), segs=6)
        tip = hz + lift + length / 2
        if kind == "yari":
            b.box((hx, hy, tip + 0.13), (0.04, 0.025, 0.26), "hand.R", "steel", taper=(0.2, 0.5))
        else:
            b.cyl((hx, hy, tip + 0.10), 0.05, 0.22, "hand.R", "steel", segs=4, r2=0.0)
        if kind == "lance":
            b.cyl((hx, hy, hz - 0.12), 0.06, 0.12, "hand.R", "steel", segs=8, r2=0.03)
        if s.get("tassel"):
            b.box((hx, hy, tip - 0.05), (0.08, 0.08, 0.16), "hand.R", s["tassel"], taper=(1.3, 1.3))
        if s.get("pennant"):
            b.plate([(0, 0), (0.30, -0.06), (0, -0.16)], 0.01, (hx, hy, tip - 0.08), (0, 0, R(90)),
                    "hand.R", s["pennant"], s["pennant"], emblem=s.get("pennant_emblem"))
    elif kind == "musket":
        ang = R(42)
        dx, dz = math.sin(ang), math.cos(ang)

        def at(t):
            return (hx + dx * t, -0.25, hz + dz * t)
        b.box(at(-0.08), (0.08, 0.07, 0.30), "hand.R", "wood_dark", rot=(0, ang, 0))
        b.box(at(0.30), (0.06, 0.06, 0.55), "hand.R", "wood", rot=(0, ang, 0))
        b.cyl(at(0.62), 0.024, 0.80, "hand.R", "iron_dark", rot=(0, ang, 0), segs=6)
        b.box(at(0.18), (0.07, 0.03, 0.07), "hand.R", "gold", rot=(0, ang, 0))
        b.box(at(0.42), (0.065, 0.065, 0.03), "hand.R", "gold", rot=(0, ang, 0))
    elif kind == "chukonu":                # repeating crossbow held in front, magazine on top
        b.box((hx + 0.16, -0.30, hz + 0.18), (0.08, 0.50, 0.08), "hand.R", "wood")
        b.box((hx + 0.16, -0.36, hz + 0.28), (0.07, 0.30, 0.12), "hand.R", "wood_dark")
        b.box((hx + 0.16, -0.52, hz + 0.18), (0.60, 0.05, 0.04), "hand.R", "wood_dark")
        b.box((hx + 0.16, -0.46, hz + 0.18), (0.58, 0.01, 0.01), "hand.R", "string")
        b.box((hx + 0.16, -0.10, hz + 0.10), (0.05, 0.10, 0.14), "hand.R", "red_lacquer")
    elif kind in ("axe", "bearded_axe"):
        b.cyl((hx, hy, hz - 0.10), 0.024, 0.66, "hand.R", "wood", segs=6)
        if kind == "bearded_axe":
            b.box((hx, hy - 0.09, hz - 0.36), (0.035, 0.18, 0.12), "hand.R", "steel", taper=(1.0, 1.4))
            b.box((hx, hy - 0.13, hz - 0.44), (0.035, 0.10, 0.10), "hand.R", "steel")
        else:
            b.box((hx, hy - 0.08, hz - 0.36), (0.04, 0.16, 0.14), "hand.R", "iron", taper=(1.0, 1.3))
    if s.get("weapon_left") == "bearded_axe":      # berserker: an axe in each hand
        lh = (0.35, -0.05, 0.68)
        b.cyl((lh[0], lh[1], lh[2] - 0.10), 0.024, 0.66, "hand.L", "wood", segs=6)
        b.box((lh[0], lh[1] - 0.09, lh[2] - 0.36), (0.035, 0.18, 0.12), "hand.L", "steel", taper=(1.0, 1.4))
        b.box((lh[0], lh[1] - 0.13, lh[2] - 0.44), (0.035, 0.10, 0.10), "hand.L", "steel")


def bow(b, s, hand=(0.35, -0.08, 0.68)):
    """Bow in the left hand. kind: short (recurve), long (longbow, man-high), yumi (tall, grip below centre)."""
    hx, hy, hz = hand
    kind = s.get("bow", "short")
    half = {"short": 0.55, "long": 0.92, "yumi": 1.0}[kind]
    centre = hz + {"short": 0.0, "long": 0.30, "yumi": 0.38}[kind]     # long bows stand clear of the ground
    seg = 9 if kind != "short" else 7
    for i in range(seg):
        t = (i + 0.5) / seg * 2 - 1
        z = centre + t * half
        bend = 0.14 if kind == "short" else 0.10
        y = hy - bend * (1 - t * t) + (0.05 * t ** 4 if kind == "short" else 0.0)
        b.box((hx, y, z), (0.05, 0.06, 2 * half / seg + 0.03), "hand.L", s.get("bow_color", "wood"),
              rot=(R((34 if kind == "short" else 20) * t), 0, 0))
    b.box((hx, hy + 0.04, centre), (0.014, 0.014, 2 * half), "hand.L", "string")
    if kind == "yumi":
        b.box((hx, hy - 0.10, hz), (0.07, 0.08, 0.10), "hand.L", "red")


def quiver(b, s):
    b.cyl((0.10, 0.20, 1.02), 0.075, 0.44, "back", s.get("quiver", "brown"), rot=(R(10), R(-20), 0), segs=6)
    b.torus((0.135, 0.21, 1.20), 0.075, 0.015, "back", s.get("quiver_trim", "gold"), rot=(R(10), R(-20), 0), segs=8)
    for dx in (-0.035, 0.0, 0.035):
        b.box((0.17 + dx, 0.23, 1.30), (0.02, 0.02, 0.12), "back", "wood")
        b.box((0.17 + dx, 0.23, 1.37), (0.04, 0.01, 0.06), "back", s.get("fletch", "white"))


def sashimono(b, s):
    """Back banner (Japanese): pole on the back with a white flag and the red disc."""
    b.cyl((0.0, 0.22, 1.55), 0.02, 1.10, "back", "black_lacquer", segs=6)
    b.box((0.0, 0.22, 2.06), (0.30, 0.02, 0.02), "back", "black_lacquer")
    b.plate([(-0.15, -0.30), (0.15, -0.30), (0.15, 0.30), (-0.15, 0.30)], 0.015, (0.0, 0.23, 1.76), (0, 0, 0),
            "back", "white", "white", emblem=s.get("sashimono", "japanese"))


SHIELD_OUTLINES = {
    "kite": [(0.0, -0.46), (0.17, -0.16), (0.22, 0.12), (0.18, 0.26), (0.0, 0.30), (-0.18, 0.26), (-0.22, 0.12), (-0.17, -0.16)],
    "heater": [(0.0, -0.32), (0.16, -0.18), (0.22, 0.04), (0.22, 0.26), (-0.22, 0.26), (-0.22, 0.04), (-0.16, -0.18)],
    "oval": [(0.21 * math.cos(a), 0.34 * math.sin(a)) for a in [i * 2 * math.pi / 12 for i in range(12)]],
    "round": [(0.30 * math.cos(a), 0.30 * math.sin(a)) for a in [i * 2 * math.pi / 14 for i in range(14)]],
}


def shield(b, s):
    kind = s.get("shield")
    if not kind:
        return
    sx, sy, sz = 0.47, -0.08, 0.86
    rot = (0, 0, R(-25))                  # faces front-left like the sheets
    face = s.get("shield_color", "red")
    rim = s.get("shield_rim", "gold")
    b.plate(SHIELD_OUTLINES[kind], 0.05, (sx, sy, sz), rot, "forearm.L", face, rim, emblem=s.get("emblem"))
    if s.get("shield_cross"):             # heraldic cross painted on the shield (Teutons)
        c, sn = math.cos(R(-25)), math.sin(R(-25))
        front = (sx + 0.03 * sn, sy - 0.03 * c, sz)
        b.plate([(-0.035, -0.28), (0.035, -0.28), (0.035, 0.24), (-0.035, 0.24)], 0.01, front, rot, "forearm.L",
                s["shield_cross"], s["shield_cross"])
        b.plate([(-0.20, 0.03), (0.20, 0.03), (0.20, 0.10), (-0.20, 0.10)], 0.01, front, rot, "forearm.L",
                s["shield_cross"], s["shield_cross"])
    if kind == "round":
        b.torus((sx, sy, sz), 0.30, 0.03, "forearm.L", rim, rot=(R(90), 0, R(-25)), segs=14, tube_segs=4)
        if not s.get("emblem") or s.get("boss"):
            b.cyl((sx + 0.012, sy - 0.045, sz), 0.07, 0.05, "forearm.L", s.get("boss", rim), rot=(R(90), 0, R(-25)), segs=8)
        if s.get("emblem_shape") == "sunburst":
            c, sn = math.cos(R(-25)), math.sin(R(-25))
            for i in range(8):
                a = i * math.pi / 4
                lx, lz = 0.15 * math.cos(a), 0.15 * math.sin(a)
                b.box((sx + lx * c, sy - 0.04 + lx * sn, sz + lz), (0.06, 0.02, 0.06), "forearm.L", s.get("emblem_color", "gold"),
                      rot=(0, 0, R(-25)))


def back_items(b, s, role):
    if s.get("weapon") == "bow" or s.get("quiver"):
        quiver(b, s)
    if s.get("sashimono"):
        sashimono(b, s)
    if s.get("scabbard"):
        b.box((-0.24, 0.05, 0.70), (0.05, 0.06, 0.50), "hips", s["scabbard"], rot=(R(30), 0, 0))


def cargo(b, s):
    """Log bundle on the back (gallery villagers): shown by the game while the villager carries wood."""
    for (dx, dz) in ((-0.08, 0.0), (0.08, 0.0), (0.0, 0.09), (-0.16, 0.09), (0.16, 0.09)):
        b.cyl((dx, 0.24, 1.00 + dz), 0.055, 0.62, "back", "log", rot=(0, R(90), R(8)), segs=6)


def upper_body(b, s, role):
    torso(b, s)
    arms(b, s)
    head(b, s)
    headwear(b, s)
    if s.get("weapon") == "bow":
        bow(b, s)
    else:
        weapon(b, s)
    shield(b, s)
    back_items(b, s, role)


def build_body(s, role=""):
    b = Body()
    legs(b, s)
    upper_body(b, s, role)
    return b


def build_cargo():
    b = Body()
    cargo(b, {})
    return b


# ---------------------------------------------------------------------------------------------------------------
# mounts
# ---------------------------------------------------------------------------------------------------------------
def horse(b, s, bones, kind="horse"):
    d = MOUNT_DIMS[kind]
    bz, hl = d["back_z"], d["half_len"]
    coat = s.get("mount_color", "horse_brown" if kind == "horse" else "camel")
    mane = s.get("mane", "mane" if kind == "horse" else "camel_dark")
    barding = s.get("barding")
    if kind == "horse":
        b.ball((0, 0.0, bz - 0.10), (0.48, hl * 2.25, 0.52), "mbody", coat, segs=10, rings=6)          # barrel
        b.ball((0, hl * 0.72, bz - 0.06), (0.46, 0.46, 0.48), "mbody", coat, segs=8, rings=6)          # rump
        b.ball((0, -hl * 0.78, bz - 0.04), (0.44, 0.44, 0.52), "mbody", coat, segs=8, rings=6)         # chest
    else:
        b.ball((0, 0.0, bz - 0.16), (0.50, hl * 2.2, 0.52), "mbody", coat, segs=10, rings=6)
        b.ball((0, 0.05, bz + 0.14), (0.40, 0.66, 0.44), "mbody", coat, segs=8, rings=5)               # hump
    n0, n1 = Vector(d["neck"][0]), Vector(d["neck"][1])
    b.segment(n0 - Vector((0, -0.04, 0.10)), n1, 0.26, 0.34, "mneck", coat, taper=0.75)
    if kind == "horse":
        b.segment(n0 + Vector((0, 0.14, 0.12)), n1 + Vector((0, 0.10, 0.08)), 0.08, 0.12, "mneck", mane)
        b.box(tuple(n1 + Vector((0, -0.02, 0.10))), (0.08, 0.12, 0.10), "mhead", mane)                   # forelock
    h0, h1 = Vector(d["head"][0]), Vector(d["head"][1])
    b.segment(h0, h1, 0.24, 0.30, "mhead", coat, taper=0.72)
    b.box(tuple(h1), (0.17, 0.12, 0.13), "mhead", "hoof" if kind == "horse" else "camel_dark")       # muzzle
    for x in (0.09, -0.09):
        b.box(tuple(h0 + Vector((x, 0.0, 0.13))), (0.05, 0.05, 0.13), "mhead", coat, taper=(0.5, 0.6))   # ears
        b.box(tuple(h0 + (h1 - h0) * 0.30 + Vector((x * 1.35, 0, 0.04))), (0.02, 0.06, 0.045), "mhead", "eye")
    for side in ("L", "R"):
        for end in ("f", "h"):
            u0, u1, _ = bones["%sleg_up.%s" % (end, side)]
            l0, l1, _ = bones["%sleg_lo.%s" % (end, side)]
            b.segment(u0, u1, 0.16, 0.22, "%sleg_up.%s" % (end, side), coat, taper=0.7)
            b.segment(l0, (l1[0], l1[1], l1[2] + 0.10), 0.085, 0.10, "%sleg_lo.%s" % (end, side), coat)
            b.box((l1[0], l1[1] - 0.02, 0.05), (0.12, 0.14, 0.10), "%sleg_lo.%s" % (end, side),
                  "hoof" if kind == "horse" else "camel_dark")
            if kind == "horse" and not barding:
                b.box((l1[0], l1[1], 0.14), (0.10, 0.11, 0.06), "%sleg_lo.%s" % (end, side), mane)   # fetlock hair
    t0, t1 = d["tail"]
    b.segment(t0, t1, 0.09, 0.09, "mtail", mane, taper=1.5)
    b.box((0, 0.02, bz + 0.16), (0.44, 0.50, 0.08), "saddle", s.get("saddle", "leather"))
    b.box((0, -0.22, bz + 0.22), (0.30, 0.06, 0.12), "saddle", s.get("saddle", "leather"))          # pommel
    if s.get("blanket"):
        b.box((0, 0.02, bz + 0.11), (0.56, 0.76, 0.05), "mbody", s["blanket"])
        for x in (0.28, -0.28):
            b.box((x, 0.02, bz - 0.08), (0.03, 0.74, 0.40), "mbody", s["blanket"])
            if s.get("tassels"):
                for k in range(4):
                    b.box((x * 1.02, -0.24 + k * 0.16, bz - 0.33), (0.035, 0.05, 0.11), "mbody", s["tassels"])
    if barding:
        # armour / caparison: a shell over the barrel, a skirt to the knees, a crinet on the neck
        b.ball((0, 0.0, bz - 0.06), (0.54, hl * 2.45, 0.56), "mbody", barding, segs=10, rings=6)
        for x in (1, -1):                  # skirt flaring out a little below the shell, open front and back
            b.box((0.27 * x, 0.0, bz - 0.42), (0.04, hl * 1.7, 0.30), "mbody", barding, rot=(0, R(-8 * x), 0))
        b.segment(n0 - Vector((0, -0.06, 0.06)), n1, 0.29, 0.37, "mneck", barding, taper=0.75)
        if s.get("barding_trim"):
            for x in (1, -1):
                b.box((0.295 * x, 0.0, bz - 0.565), (0.04, hl * 1.72, 0.05), "mbody", s["barding_trim"], rot=(0, R(-8 * x), 0))
        if s.get("barding_emblem"):
            for x, rz in ((0.29, R(90)), (-0.29, R(-90))):
                b.plate([(-0.15, -0.15), (0.15, -0.15), (0.15, 0.15), (-0.15, 0.15)], 0.01, (x, 0.0, bz - 0.34),
                        (0, 0, rz), "mbody", "gold", "gold", emblem=s["barding_emblem"])
        if s.get("chanfron"):
            b.segment(h0 + Vector((0, -0.03, 0.08)), h1 + Vector((0, -0.02, 0.09)), 0.18, 0.06, "mhead", s["chanfron"])
    b.segment(tuple(h1 + Vector((0, 0.05, 0.0))), (0, -0.20, bz + 0.20), 0.012, 0.012, "mneck", "leather")   # reins


def build_mounted(s, role, kind="horse"):
    bones = mounted_bones(kind)
    b = Body(bones)
    upper_body(b, s, role)
    # lift everything built so far (the rider's upper body) onto the saddle
    bmesh.ops.translate(b.bm, verts=list(b.bm.verts), vec=(0, 0, RIDER_DZ[kind]))
    rider_legs(b, s, bones)
    horse(b, s, bones, kind)
    return b, bones
