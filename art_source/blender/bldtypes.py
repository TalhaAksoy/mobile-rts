"""Building-type layouts built from the civ kit (civstyle.py). One layout per type keeps a type
recognisable across civs; the civ shows in masonry, roof form, tower form and props.
Every builder returns the finalized object. Front = -Y (camera side)."""
import pe_kit, parts
import civstyle as cs
import castles
import towers
import barracks
import yards
import camps
from pe_kit import Builder


def _seed(civ, k):
    return (sum(map(ord, civ)) * 7 + k) % 97


def build_barracks(civ):
    """3x3 (pad +-2.7): hall at the back, civ tower front-left, fenced training yard front-right."""
    pe_kit.reset_scene()
    b = Builder("%s_barracks" % civ)
    pe_kit.ground_pad(b, 2.7, 2.7, seed=_seed(civ, 3))
    z0 = 0.08
    if civ in barracks.BUILDERS:              # the civ's own barracks type (barracks.py)
        barracks.BUILDERS[civ](b, z0)
        return b.finalize()
    if civ == "mongols":
        top = cs.ger(b, 0.45, 0.75, z0, 1.3, wall_h=0.95)
        cs.ger(b, -1.65, 1.25, z0, 0.78, team=False)
        b.banner((0.45, 0.75 - 1.33, z0 + 0.9), (0, -1, 0), 0.34, 0.5, civ, tail=False)
    else:
        hw, hd, hh = 3.5, 1.9, 1.45
        hx, hy = 0.35, 0.8
        top = cs.hall(b, civ, (hx, hy, z0), hw, hd, hh, ridge="x", windows=4, door_w=0.62, side_windows=1)
        fy = hy - hd / 2
        for x in (hx - 0.62, hx + 0.62):
            b.banner((x, fy, z0 + hh - 0.12), (0, -1, 0), 0.26, 0.62, civ)
    cs.tower(b, civ, -1.75, -0.95, z0, 1.0, 2.2)
    # training yard
    cs.fence(b, civ, -0.8, 2.45, -2.3, z0)
    cs.fence(b, civ, -2.3, -0.7, 2.45, z0, axis="y")
    cs.weapon_rack(b, 0.45, -1.25, z0, tip="PE_Gold" if civ in ("chinese", "saracens") else "PE_Iron")
    dmat = "PE_Thatch" if civ in ("japanese", "chinese", "britons") else "PE_Felt"
    cs.dummy(b, 1.6, -1.05, z0, mat=dmat)
    cs.dummy(b, 1.05, -1.75, z0, mat=dmat)
    cs.flagpole(b, civ, -0.95, -2.15, z0, h=2.4)
    return b.finalize()


def _pad(civ, name, half, k):
    pe_kit.reset_scene()
    b = Builder("%s_%s" % (civ, name))
    pe_kit.ground_pad(b, half, half, seed=_seed(civ, k))
    return b, 0.08


def build_archery_range(civ):
    """3x3: hall back-left, open shooting shed back-right, row of straw butts along the front."""
    b, z0 = _pad(civ, "archery_range", 2.7, 5)
    if civ in yards.RANGES:                   # the civ's own range (yards.py)
        yards.RANGES[civ](b, z0)
        return b.finalize()
    if civ == "mongols":
        cs.ger(b, -1.0, 1.2, z0, 1.05)
    else:
        cs.hall(b, civ, (-1.0, 1.35, z0), 2.6, 1.6, 1.25, ridge="x", windows=3, door_w=0.55, side_windows=1)
        b.banner((-1.0 - 0.75, 1.35 - 0.8, z0 + 1.1), (0, -1, 0), 0.24, 0.55, civ)
    cs.canopy(b, civ, (1.45, 1.0, z0), 1.7, 1.9, 1.15, ridge="y")
    # quivers / arrow bundles in the shed
    for k in range(3):
        x = 1.0 + k * 0.42
        b.cylinder((x, 1.3, z0), 0.08, 0.4, "PE_WoodLight", segs=6, smooth=False)
        for j in range(3):
            b.cylinder((x - 0.03 + j * 0.03, 1.3, z0 + 0.4), 0.008, 0.25, "PE_WoodDark", segs=3, cap=False)
    # shooting lane: three butts facing the camera + lane stakes
    for x in (-1.7, -0.45, 0.8):
        cs.target(b, x, -2.05, z0)
    for x in (-2.2, -1.1, 0.15, 1.4):
        parts.timber_post(b, (x, -0.55, z0), 0.35, s=0.06)
    b.box((-0.4, -0.55, z0 + 0.3), (3.6, 0.04, 0.04), "PE_WoodDark")
    cs.weapon_rack(b, 1.85, -1.2, z0, n=4, tip="PE_Iron")
    cs.flagpole(b, civ, 2.2, -2.2, z0, h=2.3)
    return b.finalize()


def build_stable(civ):
    """3x3: long low stable with a row of stall doors at the back, fenced paddock with horses in front."""
    b, z0 = _pad(civ, "stable", 2.7, 7)
    if civ in yards.STABLES:                  # the civ's own stable (yards.py)
        yards.STABLES[civ](b, z0)
        return b.finalize()
    if civ == "mongols":
        cs.ger(b, -1.3, 1.3, z0, 0.95)
        cs.canopy(b, civ, (1.1, 1.3, z0), 2.4, 1.3, 1.0)
    else:
        hw, hd, hh = 4.4, 1.6, 1.1
        hx, hy = 0.0, 1.35
        cs.hall(b, civ, (hx, hy, z0), hw, hd, hh, ridge="x", windows=0, door_w=0, side_windows=1, team_band=False)
        fy = hy - hd / 2
        for i in range(5):                       # stall doors (split doors)
            x = hx - hw / 2 + 0.45 + i * (hw - 0.9) / 4
            b.box((x, fy - 0.03, z0 + 0.35), (0.5, 0.05, 0.62), "PE_WoodDark")
            b.box((x, fy - 0.05, z0 + 0.36), (0.52, 0.03, 0.06), "PE_WoodLight")
        b.box((hx, fy - 0.04, z0 + hh - 0.22), (hw * 0.7, 0.03, 0.1), "TEAM_Trim")
        b.banner((hx, fy, z0 + hh - 0.05), (0, -1, 0), 0.3, 0.45, civ, tail=False)
    # paddock + horses + trough + hay
    cs.fence(b, civ, -2.45, 0.9, -2.35, z0)
    cs.fence(b, civ, -2.35, 0.1, -2.45, z0, axis="y")
    cs.fence(b, civ, -2.35, 0.1, 0.9, z0, axis="y")
    cs.horse(b, -1.5, -1.0, z0, facing=1, coat="PE_WoodDark")
    cs.horse(b, -0.2, -1.65, z0, facing=-1, coat="PE_Beam")
    b.box((-1.4, -1.95, z0 + 0.18), (0.8, 0.26, 0.2), "PE_WoodDark")
    b.box((-1.4, -1.95, z0 + 0.27), (0.7, 0.18, 0.03), "PE_Window")
    for (x, y) in ((1.6, -1.2), (2.05, -1.25), (1.8, -1.75)):
        cs.hay(b, x, y, z0)
    cs.flagpole(b, civ, 2.25, -2.2, z0, h=2.2)
    return b.finalize()


def build_blacksmith(civ):
    """2x2: small workshop with a big forge chimney, open forge under a lean-to, anvil, quench barrel."""
    b, z0 = _pad(civ, "blacksmith", 1.8, 9)
    if civ in camps.SMITHS:                 # the civ's own blacksmith (camps.py)
        camps.SMITHS[civ](b, z0)
        return b.finalize()
    st = cs.style(civ)
    if civ == "mongols":
        cs.ger(b, -0.45, 0.6, z0, 0.85)
    else:
        cs.hall(b, civ, (-0.3, 0.7, z0), 2.2, 1.3, 1.1, ridge="x", windows=2, door_w=0.5, door_x=-0.45, side_windows=0)
    # forge chimney (front-right) with glowing hearth
    fx, fy = 0.95, 0.05
    chim = st["base"] if civ not in ("mongols", "vikings") else "PE_StoneGrey"
    b.box((fx, fy, z0 + 0.35), (0.75, 0.6, 0.7), chim)
    b.box((fx, fy - 0.31, z0 + 0.42), (0.36, 0.03, 0.22), "PE_Gold")
    b.box((fx + 0.12, fy + 0.1, z0 + 1.3), (0.34, 0.34, 1.9), chim)
    b.box((fx + 0.12, fy + 0.1, z0 + 2.28), (0.42, 0.42, 0.08), chim)
    cs.canopy(b, civ, (0.55, -0.55, z0), 1.4, 0.75, 1.0, back_wall=False)
    cs.anvil(b, 0.35, -0.95, z0)
    parts.barrel(b, (1.4, -1.0, z0), r=0.15, h=0.36)
    cs.weapon_rack(b, -1.0, -0.9, z0, n=3)
    b.cylinder_between((-0.25, -1.25, z0 + 0.25), (-0.25, -1.35, z0 + 0.25), 0.22, "PE_StoneGrey", segs=8, smooth=False, cap=True)
    parts.pennant(b, (-1.45, -1.35, z0), h=1.5, length=0.38)
    return b.finalize()


def build_lumber_camp(civ):
    """2x2: open civ shed with stacked logs, log piles, chopping stump, saw-horse, pennant."""
    b, z0 = _pad(civ, "lumber_camp", 1.8, 11)
    if civ in camps.LUMBER:                 # the civ's own lumber camp (camps.py)
        camps.LUMBER[civ](b, z0)
        return b.finalize()
    cs.canopy(b, civ, (0.0, 0.6, z0), 2.4, 1.3, 1.1)
    parts.log_pile(b, (0.2, 0.75, z0), length=1.6, rows=3, r=0.1)
    parts.log_pile(b, (-0.85, -0.75, z0), length=1.0, rows=2, r=0.11, axis="y")
    parts.log_pile(b, (0.85, -1.1, z0), length=1.0, rows=2, r=0.1)
    b.cylinder((0.0, -0.75, z0), 0.2, 0.32, "PE_WoodLight", segs=8)
    b.cylinder_between((0.0, -0.75, z0 + 0.3), (0.18, -0.9, z0 + 0.6), 0.025, "PE_WoodDark", segs=4)
    b.box((0.2, -0.92, z0 + 0.62), (0.12, 0.04, 0.1), "PE_Iron")
    for x in (1.1, 1.5):
        b.cylinder_between((x, -0.25, z0), (x, -0.05, z0 + 0.45), 0.03, "PE_WoodDark", segs=4)
        b.cylinder_between((x, 0.15, z0), (x, -0.05, z0 + 0.45), 0.03, "PE_WoodDark", segs=4)
    b.cylinder_between((0.95, -0.05, z0 + 0.5), (1.65, -0.05, z0 + 0.5), 0.09, "PE_Beam", segs=6, smooth=False)
    parts.pennant(b, (-1.45, -0.2, z0), h=1.5, length=0.4)
    b.banner((-1.45, -0.24, z0 + 1.15), (0, -1, 0), 0.22, 0.4, civ)
    return b.finalize()


def build_mining_camp(civ):
    """2x2: open civ shed over ore bins, ore cart on a short track, stone and gold piles, picks."""
    b, z0 = _pad(civ, "mining_camp", 1.8, 13)
    if civ in camps.MINES:                 # the civ's own mining camp (camps.py)
        camps.MINES[civ](b, z0)
        return b.finalize()
    cs.canopy(b, civ, (-0.1, 0.65, z0), 2.3, 1.2, 1.1)
    for x, m in ((-0.7, "PE_StoneGrey"), (0.0, "PE_Gold"), (0.6, "PE_StoneGrey")):
        b.box((x, 0.7, z0 + 0.18), (0.55, 0.7, 0.36), "PE_WoodDark")
        b.dome((x, 0.7, z0 + 0.36), 0.25, m, segs=6, rings=2, height=0.16, smooth=False)
    for y in (-0.55, -0.85):                       # rail track
        b.box((0.1, y, z0 + 0.02), (2.4, 0.05, 0.04), "PE_Iron")
    for i in range(6):
        b.box((-1.0 + i * 0.44, -0.7, z0 + 0.01), (0.1, 0.46, 0.03), "PE_WoodDark")
    cs.cart(b, 0.45, -0.7, z0, load="PE_StoneGrey", load2="PE_Gold")
    cs.rock_pile(b, -1.15, -1.25, z0, mat="PE_StoneGrey")
    cs.rock_pile(b, 1.3, 0.0, z0, mat="PE_Gold", n=3, s=0.16)
    for k in range(2):                              # picks leaning on a crate
        b.cylinder_between((0.95 + k * 0.15, -1.3, z0), (1.05 + k * 0.15, -1.15, z0 + 0.55), 0.02, "PE_WoodDark", segs=4)
        b.box((1.05 + k * 0.15, -1.15, z0 + 0.55), (0.22, 0.04, 0.04), "PE_Iron")
    parts.crate(b, (1.25, -1.3, z0), s=0.3)
    parts.pennant(b, (-1.45, -0.3, z0), h=1.5, length=0.4)
    b.banner((-1.45, -0.34, z0 + 1.15), (0, -1, 0), 0.22, 0.4, civ)
    return b.finalize()


def build_watch_tower(civ):
    """2x2: the civ tower at full size on a stone (or timber) base, with door and flag."""
    b, z0 = _pad(civ, "watch_tower", 1.8, 15)
    if civ in towers.BUILDERS:                 # every civ but the Mongols: its own tower type (towers.py)
        towers.BUILDERS[civ](b, z0)
        if civ not in ("saracens", "franks"):  # those two fly their flag / pennon from the tower itself
            cs.flagpole(b, civ, 1.25, -1.2, z0, h=1.6, size=(0.45, 0.3))
        for (x, y) in ((-1.3, -1.25), (-1.0, -1.4)):
            parts.crate(b, (x, y, z0), s=0.26)
        return b.finalize()
    st = cs.style(civ)
    if civ not in ("mongols", "vikings"):
        b.box((0, 0.1, z0 + 0.15), (2.0, 2.0, 0.3), st["base"])
        z = z0 + 0.3
    else:
        z = z0
    top = cs.tower(b, civ, 0.0, 0.1, z, 1.6, 3.0)
    if civ not in ("mongols", "vikings"):      # Viking/Mongol towers are open timber frames
        cs.door(b, civ, (0.0, 0.1 - (0.8 if st["tower"] not in ("round", "spire", "ottoman") else 0.78), z), 0.4, 0.7)
    cs.flagpole(b, civ, 1.25, -1.2, z0, h=1.6, size=(0.45, 0.3))
    for (x, y) in ((-1.3, -1.25), (-1.0, -1.4)):
        parts.crate(b, (x, y, z0), s=0.26)
    return b.finalize()


def build_castle(civ):
    """4x4 (pad +-3.6). Every civ but the Mongols builds its own fortress type (castles.py); the Mongol
    karakorum camp (palisade, gers) is the layout below."""
    b, z0 = _pad(civ, "castle", 3.6, 17)
    if civ in castles.BUILDERS:
        castles.BUILDERS[civ](b, z0)
        return b.finalize()
    st = cs.style(civ)
    H = 1.5
    e = 2.75                       # wall line
    ts = 1.15                      # corner tower size
    for sy in (-1, 1):
        if sy < 0:                 # front wall split by the gate
            cs.curtain(b, civ, -e, -0.75, -e, z0, H)
            cs.curtain(b, civ, 0.75, e, -e, z0, H)
        else:
            cs.curtain(b, civ, -e, e, e, z0, H)
    for sx in (-1, 1):
        cs.curtain(b, civ, -e, e, sx * e, z0, H, axis="y")
    for sx in (-1, 1):
        for sy in (-1, 1):
            cs.tower(b, civ, sx * e, sy * e, z0, ts, H + 0.9)
    # gatehouse
    if civ in ("mongols", "vikings"):
        for sx in (-1, 1):
            cs.tower(b, civ, sx * 0.85, -e, z0, 0.8, H + 0.6, team=sx < 0)
    else:
        gw = 1.6
        b.box((0, -e, z0 + (H + 0.5) / 2), (gw, 0.8, H + 0.5), st["base"] if civ != "japanese" else "PE_PlasterWhite")
        cs.door(b, civ, (0, -e - 0.4, z0), 0.75, 1.1)
        b.box((0, -e - 0.42, z0 + H + 0.2), (gw * 0.7, 0.03, 0.12), "TEAM_Trim")
        cs.roof(b, civ, (0, -e, z0 + H + 0.5), gw, 0.8, ridge="x", rh=0.45, overhang=0.12) if st["roof"] != "flat" else \
            cs.roof(b, civ, (0, -e, z0 + H + 0.5), gw, 0.8)
    # keep
    if civ == "mongols":
        cs.ger(b, 0.0, 0.6, z0, 1.5, wall_h=1.1)
        cs.ger(b, -1.4, -0.9, z0, 0.6, team=False)
        cs.ger(b, 1.4, -0.9, z0, 0.6, team=False)
    elif civ == "vikings":
        cs.hall(b, civ, (0.0, 0.6, z0), 3.2, 1.9, 1.2, ridge="x", windows=3, door_w=0.6)
    else:
        cs.hall(b, civ, (0.0, 0.85, z0), 2.6, 1.8, 2.1, ridge="x", windows=3, door_w=0.6, side_windows=1)
        cs.tower(b, civ, -0.75, -0.15, z0, 1.2, 3.4)
    for x in (-0.45, 0.45):
        b.banner((x, -e - 0.42, z0 + H + 0.1), (0, -1, 0), 0.26, 0.6, civ)
    cs.flagpole(b, civ, 0.9, 1.6, z0 + (0 if civ in ("mongols", "vikings") else 3.2), h=1.8)
    return b.finalize()


def run_type(civ, asset, builder, grid):
    ob = builder(civ)
    fp = grid * 1.8
    return ob, pe_kit.export_asset(ob, civ, asset, extra_meta={"grid": [grid, grid], "footprint_m": fp,
                                                                "reference": "res://art/buildings/%s/%s.png" % (civ, asset)})
