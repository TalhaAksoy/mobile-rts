"""Pocket Empires logo and app icon (original design).

Style: early-2000s console RTS box-art lettering - chunky bevelled gold letters with a dark iron outline,
over a heraldic emblem (enamel shield with a gold rim, crossed steel swords, jewelled crown).

Run:  blender -b -P art_source/blender/logo/render_logo.py -- <out_dir> [samples]
Writes to <out_dir>:
  logo.png          main-menu logo, transparent, cropped to the artwork
  icon_1024.png     app icon (emblem on a dark crimson field, full bleed)
  icon_192.png      Android legacy launcher icon
  icon_fg_432.png   Android adaptive icon foreground (emblem inside the 66 % safe zone, transparent)
  icon_bg_432.png   Android adaptive icon background
Font: Cinzel (SIL Open Font License). Cinzel-Black.ttf next to this script is the weight-900 instance of the
variable sample_project/assets/Cinzel.ttf, made with:  fonttools varLib.instancer Cinzel.ttf wght=900
The thin default weight gave spiky bevels on its hairline serifs.
"""
import math
import os
import sys

import bpy
import numpy as np

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "logo_out")
SAMPLES = int(ARGS[1]) if len(ARGS) > 1 else 128
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
FONT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Cinzel-Black.ttf")
os.makedirs(OUT, exist_ok=True)

# ------------------------------------------------------------------------------------------------
# scene
# ------------------------------------------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
try:
    scene.render.engine = "CYCLES"
except TypeError:
    pass
scene.cycles.samples = SAMPLES
scene.cycles.use_denoising = True
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.view_settings.view_transform = "Standard"
scene.view_settings.look = "None"
col = scene.collection


def link(obj):
    col.objects.link(obj)
    return obj


def principled(name, color, metallic=0.0, rough=0.4, coat=0.0, emission=None, strength=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = rough
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = coat
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
    return m


GOLD = principled("Gold", (1.0, 0.70, 0.28), metallic=1.0, rough=0.20)
GOLD_DARK = principled("GoldDark", (0.80, 0.50, 0.16), metallic=1.0, rough=0.32)
IRON = principled("Iron", (0.055, 0.045, 0.042), metallic=0.85, rough=0.42)
STEEL = principled("Steel", (0.70, 0.72, 0.76), metallic=1.0, rough=0.18)
ENAMEL_BLUE = principled("EnamelBlue", (0.012, 0.035, 0.20), rough=0.22, coat=1.0)
ENAMEL_RED = principled("EnamelRed", (0.26, 0.010, 0.008), rough=0.22, coat=1.0)
RUBY = principled("Ruby", (0.75, 0.02, 0.03), rough=0.05, coat=1.0, emission=(0.6, 0.0, 0.0), strength=0.6)
SAPPHIRE = principled("Sapphire", (0.03, 0.15, 0.8), rough=0.05, coat=1.0, emission=(0.0, 0.1, 0.6), strength=0.5)
LEATHER = principled("Leather", (0.18, 0.08, 0.04), rough=0.6)

def chrome_text(name, stops, rough=0.22):
    """Console-logo lettering: a metal whose colour runs top to bottom through a bright sky, a dark horizon band
    and a bright lower half (Generated Y = the letters' height after they are stood up)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    # not fully metallic: a pure metal front face only mirrors the dark horizon behind the camera and the
    # gradient vanishes; part diffuse + a little glow of the gradient keeps the classic banded look
    bsdf.inputs["Metallic"].default_value = 0.85
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Emission Strength"].default_value = 0.15
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    els = ramp.color_ramp.elements
    els[0].position, els[0].color = stops[0][0], (*stops[0][1], 1)
    els[1].position, els[1].color = stops[-1][0], (*stops[-1][1], 1)
    for pos, c in stops[1:-1]:
        e = els.new(pos)
        e.color = (*c, 1)
    nt.links.new(tc.outputs["Generated"], sep.inputs[0])
    nt.links.new(sep.outputs["Y"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Emission Color"])
    return m


GOLD_TEXT = chrome_text("GoldText", rough=0.28, stops=[
    (0.0, (0.80, 0.45, 0.10)), (0.40, (1.0, 0.76, 0.28)), (0.45, (0.26, 0.11, 0.02)),
    (0.56, (0.50, 0.26, 0.06)), (0.62, (1.0, 0.84, 0.42)), (1.0, (1.0, 0.94, 0.70))])
STEEL_TEXT = chrome_text("SteelText", rough=0.22, stops=[
    (0.0, (0.45, 0.48, 0.54)), (0.40, (0.80, 0.83, 0.88)), (0.45, (0.14, 0.15, 0.18)),
    (0.56, (0.40, 0.42, 0.47)), (0.62, (0.92, 0.93, 0.96)), (1.0, (1.0, 1.0, 1.0))])

FONT = bpy.data.fonts.load(FONT_PATH)

# objects stand in the XZ plane facing the camera at -Y; "depth" is +Y (further away)


def text_obj(name, body, size, z, depth, mat, extrude, bevel, spacing=1.0):
    """Extruded letters turned into a mesh with a Bevel modifier. A curve bevel/offset on the serif tips threw
    long spikes; the mesh bevel clamps where bevels would overlap."""
    cu = bpy.data.curves.new(name, "FONT")
    cu.body = body
    cu.font = FONT
    cu.size = size
    cu.align_x = "CENTER"
    cu.align_y = "CENTER"
    cu.extrude = extrude
    cu.space_character = spacing
    ob = link(bpy.data.objects.new(name, cu))
    ob.rotation_euler = (math.radians(90), 0, 0)
    ob.location = (0, depth, z)
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.convert(target="MESH")
    ob = bpy.context.active_object
    ob.data.materials.clear()
    ob.data.materials.append(mat)
    bv = ob.modifiers.new("Bevel", "BEVEL")
    bv.width = bevel
    bv.segments = 4
    bv.limit_method = "ANGLE"
    bv.angle_limit = math.radians(30)
    bv.use_clamp_overlap = True
    bv.profile = 0.6
    try:
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40))
    except Exception:
        pass
    return ob


def lettering(body, size, z, face_mat, spacing):
    """Bevelled letters; their dark outline is drawn on the rendered image (outline_png)."""
    return [text_obj(body, body, size, z, 0.0, face_mat, 0.10 * size, 0.035 * size, spacing)]


def shield_half(w=1.0, top=1.1, side_end=0.15, bottom=-1.35, n=24):
    """Right half of a heater shield, from the top centre (slightly arched) round to the bottom point."""
    pts = []
    for i in range(0, 7):
        x = w * i / 6
        pts.append((x, top + 0.07 * math.cos(math.pi * 0.5 * i / 6)))
    pts.append((w, side_end))
    for i in range(1, n):
        t = i / n
        pts.append((w * (1 - t) ** 1.25, side_end + (bottom - side_end) * (1 - math.cos(t * math.pi / 2)) ** 0.9))
    pts.append((0.0, bottom))
    return pts


def shield_points():
    right = shield_half()
    left = [(-x, y) for (x, y) in reversed(right[1:-1])]
    return right + left


def flat_shape(name, pts, z0, depth, scale, mat, extrude, bevel, offset=0.0):
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "2D"
    cu.fill_mode = "BOTH"
    sp = cu.splines.new("POLY")
    sp.points.add(len(pts) - 1)
    for p, (x, y) in zip(sp.points, pts):
        p.co = (x, y, 0, 1)
    sp.use_cyclic_u = True
    cu.extrude = extrude
    cu.bevel_depth = bevel
    cu.bevel_resolution = 4
    cu.offset = offset
    ob = link(bpy.data.objects.new(name, cu))
    ob.rotation_euler = (math.radians(90), 0, 0)
    ob.location = (0, depth, z0)
    ob.scale = (scale, scale, scale)
    ob.data.materials.append(mat)
    return ob


def mesh_obj(name, verts, faces, mat, loc=(0, 0, 0), rot=(0, 0, 0)):
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    ob = link(bpy.data.objects.new(name, me))
    ob.location = loc
    ob.rotation_euler = rot
    ob.data.materials.append(mat)
    for p in me.polygons:
        p.use_smooth = False
    return ob


def prim(kind, name, mat, loc, scale, rot=(0, 0, 0), **kw):
    getattr(bpy.ops.mesh, "primitive_%s_add" % kind)(location=loc, rotation=rot, **kw)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = scale
    ob.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    return ob


def bevel_mod(ob, w=0.02, seg=3):
    m = ob.modifiers.new("Bevel", "BEVEL")
    m.width = w
    m.segments = seg
    m.limit_method = "ANGLE"
    return ob


def sword(name, angle_deg, center, length, depth):
    """Blade + crossguard + grip + pommel, built pointing up, then rotated in the XZ plane."""
    parts = []
    L = length
    bw = 0.13
    t = 0.035
    # blade: hexagonal cross-section, tapering to a point
    verts = [(-bw, -t * 0.2, 0), (0, -t, 0), (bw, -t * 0.2, 0), (bw, t * 0.2, 0), (0, t, 0), (-bw, t * 0.2, 0),
             (-bw * 0.9, -t * 0.2, L * 0.82), (0, -t, L * 0.82), (bw * 0.9, -t * 0.2, L * 0.82),
             (bw * 0.9, t * 0.2, L * 0.82), (0, t, L * 0.82), (-bw * 0.9, t * 0.2, L * 0.82), (0, 0, L)]
    faces = [(0, 1, 7, 6), (1, 2, 8, 7), (2, 3, 9, 8), (3, 4, 10, 9), (4, 5, 11, 10), (5, 0, 6, 11),
             (6, 7, 12), (7, 8, 12), (8, 9, 12), (9, 10, 12), (10, 11, 12), (11, 6, 12), (0, 5, 4, 3, 2, 1)]
    parts.append(mesh_obj(name + "_blade", verts, faces, STEEL))
    parts.append(bevel_mod(prim("cube", name + "_guard", GOLD, (0, 0, -0.03), (0.42, 0.07, 0.06))))
    parts.append(prim("cylinder", name + "_grip", LEATHER, (0, 0, -0.42), (0.06, 0.06, 0.36), vertices=16))
    parts.append(prim("uv_sphere", name + "_pommel", GOLD, (0, 0, -0.84), (0.12, 0.12, 0.12), segments=24, ring_count=12))
    root = link(bpy.data.objects.new(name, None))
    for p in parts:
        p.parent = root
    root.location = (center[0], depth, center[1])
    root.rotation_euler = (0, math.radians(angle_deg), 0)
    return root


def crown(name, center, depth, scale):
    parts = []
    # band: a short wide open cylinder seen from the front
    parts.append(prim("cylinder", name + "_band", GOLD, (0, 0, 0), (1.0, 0.35, 0.22), vertices=48))
    # five points with balls on top
    for i, x in enumerate([-0.82, -0.42, 0.0, 0.42, 0.82]):
        h = 0.55 if i == 2 else (0.42 if i in (1, 3) else 0.32)
        parts.append(prim("cone", name + "_pt%d" % i, GOLD, (x, -0.2, 0.22 + h * 0.5), (0.17, 0.08, h * 0.5), vertices=4, rot=(0, 0, math.radians(45))))
        parts.append(prim("uv_sphere", name + "_ball%d" % i, GOLD, (x, -0.2, 0.24 + h), (0.08, 0.08, 0.08), segments=16, ring_count=8))
    # gems on the band
    for x, mat in [(-0.55, SAPPHIRE), (0.0, RUBY), (0.55, SAPPHIRE)]:
        parts.append(prim("uv_sphere", name + "_gem", mat, (x, -0.37, 0.0), (0.11, 0.06, 0.11), segments=20, ring_count=10))
    root = link(bpy.data.objects.new(name, None))
    for p in parts:
        p.parent = root
    root.location = (center[0], depth, center[1])
    root.scale = (scale, scale, scale)
    return root


def emblem(z, s, monogram=False):
    """Shield (gold rim, quartered enamel field, gold cross), crossed swords behind, crown on top."""
    pts = shield_points()
    objs = []
    objs.append(flat_shape("ShieldRim", pts, z, 0.55, s, GOLD_DARK, 0.10, 0.03, offset=0.10))
    # field per pale: blue (left) / red (right), split by a gold cross
    right = shield_half()
    left = [(-x, y) for (x, y) in right]
    objs.append(flat_shape("FieldRed", right, z, 0.47, s, ENAMEL_RED, 0.08, 0.0))
    objs.append(flat_shape("FieldBlue", list(reversed(left)), z, 0.47, s, ENAMEL_BLUE, 0.08, 0.0))
    # gold cross (pale + fess)
    pale = [(-0.09, 1.12), (0.09, 1.12), (0.09, -1.28), (-0.09, -1.28)]
    fess = [(-0.98, 0.42), (0.98, 0.42), (0.98, 0.24), (-0.98, 0.24)]
    objs.append(flat_shape("Pale", pale, z, 0.40, s, GOLD, 0.05, 0.015))
    objs.append(flat_shape("Fess", fess, z, 0.385, s, GOLD, 0.05, 0.015))   # a hair in front of the pale
    if monogram:
        mono = text_obj("Mono", "P", 1.75 * s, z - 0.12 * s, 0.15, GOLD_TEXT, 0.16 * s, 0.05 * s)
        # dark iron plate behind the letter so it reads on both enamel halves
        plate = prim("cylinder", "MonoPlate", IRON, (0, 0.30, z - 0.12 * s), (0.62 * s, 0.62 * s, 0.05),
                     rot=(math.radians(90), 0, 0), vertices=48)
        bevel_mod(plate, 0.03, 3)
        rim = prim("torus", "MonoRing", GOLD, (0, 0.25, z - 0.12 * s), (s, s, s), rot=(math.radians(90), 0, 0),
                   major_radius=0.64, minor_radius=0.05, major_segments=64, minor_segments=12)
        objs += [mono, plate, rim]
    # crossed swords behind the shield
    objs.append(sword("SwordL", -38, (0, z - 0.35 * s), 3.1 * s, 0.95))
    objs.append(sword("SwordR", 38, (0, z - 0.35 * s), 3.1 * s, 1.0))
    # crown on top
    objs.append(crown("Crown", (0, z + 1.38 * s), 0.35, 0.62 * s))
    return objs


# ------------------------------------------------------------------------------------------------
# world + lights
# ------------------------------------------------------------------------------------------------
world = bpy.data.worlds.new("World")
scene.world = world
world.use_nodes = True
wn = world.node_tree.nodes
wl = world.node_tree.links
bg = next(n for n in wn if n.type == "BACKGROUND")
tc = wn.new("ShaderNodeTexCoord")
sep = wn.new("ShaderNodeSeparateXYZ")
ramp = wn.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].position = 0.40
ramp.color_ramp.elements[0].color = (0.05, 0.03, 0.02, 1)
ramp.color_ramp.elements[1].position = 0.62
ramp.color_ramp.elements[1].color = (1.0, 0.86, 0.66, 1)
mid = ramp.color_ramp.elements.new(0.5)
mid.color = (0.20, 0.12, 0.07, 1)
mapr = wn.new("ShaderNodeMapRange")
mapr.inputs["From Min"].default_value = -1.0
mapr.inputs["From Max"].default_value = 1.0
wl.new(tc.outputs["Generated"], sep.inputs[0])
wl.new(sep.outputs["Z"], mapr.inputs["Value"])
wl.new(mapr.outputs["Result"], ramp.inputs["Fac"])
wl.new(ramp.outputs["Color"], bg.inputs["Color"])
bg.inputs["Strength"].default_value = 1.1


def area(name, loc, rot, power, size, color):
    li = bpy.data.lights.new(name, "AREA")
    li.energy = power
    li.size = size
    li.color = color
    ob = link(bpy.data.objects.new(name, li))
    ob.location = loc
    ob.rotation_euler = [math.radians(a) for a in rot]
    return ob


area("Key", (-6, -8, 7), (55, 0, -35), 2600, 5, (1.0, 0.92, 0.80))
area("Fill", (6, -9, 1), (85, 0, 35), 500, 6, (0.80, 0.86, 1.0))
area("Rim", (0, 6, 6), (-55, 0, 180), 900, 6, (1.0, 0.85, 0.6))
area("Top", (0, -2, 10), (10, 0, 0), 700, 8, (1.0, 1.0, 1.0))

cam_data = bpy.data.cameras.new("Cam")
cam_data.lens = 50
cam = link(bpy.data.objects.new("Cam", cam_data))
scene.camera = cam


def aim(cam_ob, target):
    d = (target[0] - cam_ob.location[0], target[1] - cam_ob.location[1], target[2] - cam_ob.location[2])
    from mathutils import Vector
    cam_ob.rotation_euler = Vector(d).to_track_quat("-Z", "Y").to_euler()


def render(path, w, h):
    scene.render.resolution_x = w
    scene.render.resolution_y = h
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def crop_alpha(path, pad=12):
    img = bpy.data.images.load(path)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    ys, xs = np.where(px[:, :, 3] > 0.01)
    y0, y1 = max(0, ys.min() - pad), min(h, ys.max() + pad + 1)
    x0, x1 = max(0, xs.min() - pad), min(w, xs.max() + pad + 1)
    sub = px[y0:y1, x0:x1].copy()
    out = bpy.data.images.new("crop", x1 - x0, y1 - y0, alpha=True)
    out.pixels[:] = sub.ravel()
    out.filepath_raw = path
    out.file_format = "PNG"
    out.save()
    return x1 - x0, y1 - y0


def _dilate(alpha, r):
    """Max filter with a disc of radius r (pixels)."""
    h, w = alpha.shape
    pad = np.pad(alpha, r)
    out = np.zeros_like(alpha)
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx * dx + dy * dy <= r * r:
                np.maximum(out, pad[r + dy:r + dy + h, r + dx:r + dx + w], out=out)
    return out


def outline_png(path, r_dark, r_gold, shadow=0):
    """Console-box-art finish on a transparent render: a dark iron outline round everything, a thin gold
    hairline outside it, and a soft shadow below."""
    img = bpy.data.images.load(path)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    m = max(r_gold, shadow) + 4
    big = np.zeros((h + 2 * m, w + 2 * m, 4), dtype=np.float32)
    big[m:m + h, m:m + w] = px
    a = big[:, :, 3]
    dark = _dilate(a, r_dark)
    gold = _dilate(a, r_gold)
    H = big.shape[0]
    out = np.zeros_like(big)
    if shadow:
        sh = np.roll(_dilate(a, shadow), -shadow, axis=0) * 0.45
        out[:, :, 3] = sh
    def over(dst, rgb, alpha):
        da = dst[:, :, 3]
        na = alpha + da * (1 - alpha)
        for c in range(3):
            dst[:, :, c] = np.where(na > 0, (rgb[c] * alpha + dst[:, :, c] * da * (1 - alpha)) / np.maximum(na, 1e-6), 0)
        dst[:, :, 3] = na
    gr = 0.25 + 0.75 * (1.0 - np.linspace(0, 1, H, dtype=np.float32))[:, None] * np.ones((1, big.shape[1]), np.float32)
    over(out, (0.78 * gr + 0.2, 0.55 * gr + 0.12, 0.18 * gr + 0.04), gold)
    over(out, (0.10 * gr + 0.03, 0.08 * gr + 0.025, 0.07 * gr + 0.02), dark)
    over(out, (big[:, :, 0], big[:, :, 1], big[:, :, 2]), a)
    res = bpy.data.images.new("outlined", big.shape[1], big.shape[0], alpha=True)
    res.pixels[:] = out.ravel()
    res.filepath_raw = path
    res.file_format = "PNG"
    res.save()


def resize(src, dst, size):
    img = bpy.data.images.load(src)
    img.scale(size, size)
    img.filepath_raw = dst
    img.file_format = "PNG"
    img.save()


# ------------------------------------------------------------------------------------------------
# 1. main-menu logo
# ------------------------------------------------------------------------------------------------
logo_objs = []
logo_objs += emblem(z=1.0, s=1.25)
logo_objs += lettering("POCKET", 0.92, 0.92, STEEL_TEXT, 1.18)
logo_objs += lettering("EMPIRES", 1.62, -0.62, GOLD_TEXT, 1.04)

cam.location = (0, -15.5, 0.2)
aim(cam, (0, 0, 0.35))
render(os.path.join(OUT, "logo.png"), 1800, 1200)
print("logo size", crop_alpha(os.path.join(OUT, "logo.png"), pad=2))
outline_png(os.path.join(OUT, "logo.png"), 9, 13, shadow=16)


def hide(objs, state):
    for o in objs:
        o.hide_render = state
        for c in o.children_recursive:
            c.hide_render = state


# ------------------------------------------------------------------------------------------------
# 2. app icon: emblem with a "P" monogram on a dark crimson field
# ------------------------------------------------------------------------------------------------
hide(logo_objs, True)
icon_objs = emblem(z=0.0, s=1.0, monogram=True)

bg_mat = bpy.data.materials.new("IconBg")
bg_mat.use_nodes = True
nt = bg_mat.node_tree
for n in list(nt.nodes):
    nt.nodes.remove(n)
outp = nt.nodes.new("ShaderNodeOutputMaterial")
emi = nt.nodes.new("ShaderNodeEmission")
grad = nt.nodes.new("ShaderNodeTexGradient")
grad.gradient_type = "SPHERICAL"
mp = nt.nodes.new("ShaderNodeMapping")
mp.inputs["Scale"].default_value = (0.2, 0.2, 0.2)
tco = nt.nodes.new("ShaderNodeTexCoord")
cr = nt.nodes.new("ShaderNodeValToRGB")
cr.color_ramp.elements[0].color = (0.02, 0.004, 0.003, 1)
cr.color_ramp.elements[1].color = (0.40, 0.06, 0.035, 1)
nt.links.new(tco.outputs["Object"], mp.inputs["Vector"])
nt.links.new(mp.outputs["Vector"], grad.inputs["Vector"])
nt.links.new(grad.outputs["Fac"], cr.inputs["Fac"])
nt.links.new(cr.outputs["Color"], emi.inputs["Color"])
emi.inputs["Strength"].default_value = 1.0
nt.links.new(emi.outputs["Emission"], outp.inputs["Surface"])
bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 4.0, 0), rotation=(math.radians(90), 0, 0))
bg_plane = bpy.context.active_object
bg_plane.data.materials.append(bg_mat)

cam.location = (0, -15.0, 0.3)
aim(cam, (0, 0, 0.3))
cam_data.lens = 92
scene.render.film_transparent = False
render(os.path.join(OUT, "icon_1024.png"), 1024, 1024)
resize(os.path.join(OUT, "icon_1024.png"), os.path.join(OUT, "icon_192.png"), 192)

# adaptive background: only the field
hide(icon_objs, True)
render(os.path.join(OUT, "icon_bg_432.png"), 432, 432)

# adaptive foreground: the emblem alone, smaller (launchers crop to the inner 66 %)
hide(icon_objs, False)
bg_plane.hide_render = True
scene.render.film_transparent = True
cam_data.lens = 82
render(os.path.join(OUT, "icon_fg_432.png"), 432, 432)
outline_png(os.path.join(OUT, "icon_fg_432.png"), 3, 5)
fg = bpy.data.images.load(os.path.join(OUT, "icon_fg_432.png"))
fg.scale(432, 432)
fg.save()
print("done", OUT)
