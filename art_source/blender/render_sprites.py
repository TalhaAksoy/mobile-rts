"""Render the 2D sprite set from the SAME Blender models the 3D mode uses (run INSIDE Blender):

    import runpy; runpy.run_path("<repo>/art_source/blender/render_sprites.py")

Optional global ONLY = ["britons_house", "env:common_tree_pine", ...] restricts the set.

For every building (buildings/<civ>_<asset>.py), mill field (environment/field.py), civ upgrade kit
(environment/upgrade_kit.py) and environment prop (environment/<module>.py, every biome variant) it:
  * builds the model with its own build script (identical geometry and materials to the GLB),
  * renders it with an orthographic camera at the game camera's pitch (45 deg, looking towards +Y),
    at SUPERSAMPLE x the final pixel density, on a transparent background,
  * renders models with TEAM_* surfaces once per team colour (blue, red),
  * writes the raw renders to <repo>/build/sprites_raw/ and their placement data to
    sample_project/data/art/sprite_manifest.json.
Afterwards (outside Blender): python3 art_source/blender/finish_sprites.py
(box-downsamples to PX_PER_M, hard alpha edge, writes sample_project/assets/sprites/...).

Placement in Godot (Building3D / MapGenerator3D): the sprite is a non-billboard plane facing the camera
(+Z), standing at the model's front-most depth (`plane_z`, metres in front of the origin), stretched
vertically by 1/cos(pitch) so a vertical plane seen from the 45 deg camera shows the image undistorted.
`anchor` = pixel (in the FINAL image) of the ground point straight below the origin on that plane.
"""
import sys, os, importlib, glob, json, math
import bpy
import mathutils

HERE = os.path.dirname(os.path.abspath(__file__))
for p in (HERE, os.path.join(HERE, "buildings"), os.path.join(HERE, "environment")):
    if p not in sys.path:
        sys.path.insert(0, p)
import pe_kit, parts, civstyle, bldtypes, env_parts
for _m in (pe_kit, parts, civstyle, bldtypes, env_parts):
    importlib.reload(_m)

PX_PER_M = 32
SUPERSAMPLE = 4
PITCH = math.radians(45.0)
TEAM_COLORS = [(0.18, 0.52, 0.95), (0.92, 0.22, 0.22)]     # FactionArtManager.TEAM_COLORS (sRGB)
RAW_DIR = os.path.join(pe_kit.REPO_ROOT, "build", "sprites_raw")
MANIFEST = os.path.join(pe_kit.GODOT_PROJECT, "data", "art", "sprite_manifest.json")
ONLY = globals().get("ONLY")
## Sprites are unshaded in Godot but still go through its tonemapper, like the lit 3D models. The Blender
## preview light is stronger than Main3D's, so the renders are darkened by EXPOSURE stops to match the 3D
## look in the same in-game capture (calibrated on roofs/walls, see docs/art/BLENDER_PIPELINE.md).
EXPOSURE = globals().get("EXPOSURE", -1.0)

CAM_RIGHT = mathutils.Vector((1, 0, 0))
CAM_UP = mathutils.Vector((0, math.cos(PITCH), math.sin(PITCH)))
CAM_FWD = mathutils.Vector((0, math.sin(PITCH), -math.cos(PITCH)))


def _srgb_to_linear(c):
    return ((c / 12.92) if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)


def _setup_render():
    scene = bpy.context.scene
    engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE", "BLENDER_WORKBENCH"):
        if eng in engines:
            try:
                scene.render.engine = eng
                break
            except TypeError:
                continue
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    try:
        scene.view_settings.view_transform = "Standard"   # Godot tonemaps the result itself
    except TypeError:
        pass
    scene.view_settings.look = "None"
    scene.view_settings.exposure = EXPOSURE
    scene.view_settings.gamma = 1.0
    scene.render.resolution_percentage = 100


def _lights():
    scene = bpy.context.scene
    for o in list(scene.objects):
        if o.name.startswith("PE_Sprite"):
            bpy.data.objects.remove(o, do_unlink=True)
    sun_data = bpy.data.lights.new("PE_SpriteSun", "SUN")
    sun_data.energy = 3.2
    sun_data.color = (1.0, 0.95, 0.86)          # warm key, as in Main3D.tscn
    sun_data.angle = math.radians(2.0)
    sun = bpy.data.objects.new("PE_SpriteSun", sun_data)
    sun.rotation_euler = (math.radians(48), 0, math.radians(-40))
    scene.collection.objects.link(sun)
    if scene.world is None:
        scene.world = bpy.data.worlds.new("PE_PreviewWorld")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == "BACKGROUND"), None)
    if bg:
        bg.inputs[0].default_value = (0.60, 0.65, 0.74, 1.0)
        bg.inputs[1].default_value = 0.8
    return sun


def _world_verts(objs):
    pts = []
    for ob in objs:
        if ob.type != "MESH":
            continue
        mw = ob.matrix_world
        pts.extend(mw @ v.co for v in ob.data.vertices)
    return pts


def _set_team(team):
    mat = bpy.data.materials.get("TEAM_Trim")
    if mat is None or not mat.use_nodes:
        return False
    bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if bsdf is None:
        return False
    for link in list(bsdf.inputs["Base Color"].links):
        mat.node_tree.links.remove(link)
    r, g, b = (_srgb_to_linear(c) for c in TEAM_COLORS[team])
    bsdf.inputs["Base Color"].default_value = (r, g, b, 1.0)
    return True


def render_object(root, out_key, teams):
    """root: the finalized object (children such as mill sails are included). Returns placement meta."""
    bpy.context.view_layer.update()
    objs = [root] + list(root.children_recursive)
    pts = _world_verts(objs)
    xs = [p.dot(CAM_RIGHT) for p in pts]
    ys = [p.dot(CAM_UP) for p in pts]
    pad = 2.0 / PX_PER_M
    minx, maxx = min(xs) - pad, max(xs) + pad
    miny, maxy = min(ys) - pad, max(ys) + pad
    W = int(math.ceil((maxx - minx) * PX_PER_M))
    H = int(math.ceil((maxy - miny) * PX_PER_M))
    maxx = minx + W / PX_PER_M                     # snap the frame to whole pixels
    maxy = miny + H / PX_PER_M
    front_y = min(p.y for p in pts)                # Blender -Y = towards the camera
    plane_z = -front_y
    # ground point under the origin on the front plane: Blender (0, front_y, 0)
    anchor_x = 0.0 - minx
    anchor_up = front_y * CAM_UP.y
    anchor = [anchor_x * PX_PER_M, (maxy - anchor_up) * PX_PER_M]

    scene = bpy.context.scene
    cam_data = bpy.data.cameras.new("PE_SpriteCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = max(W, H) / PX_PER_M
    cam_data.clip_start = 0.1
    cam_data.clip_end = 400.0
    cam = bpy.data.objects.new("PE_SpriteCam", cam_data)
    scene.collection.objects.link(cam)
    cx, cy = (minx + maxx) / 2, (miny + maxy) / 2
    cam.location = CAM_RIGHT * cx + CAM_UP * cy - CAM_FWD * 120.0
    cam.rotation_euler = (math.radians(45.0), 0.0, 0.0)
    scene.camera = cam
    scene.render.resolution_x = W * SUPERSAMPLE
    scene.render.resolution_y = H * SUPERSAMPLE
    files = {}
    for team in teams:
        if team is not None:
            _set_team(team)
        name = out_key.replace("/", "__") + ("" if team is None else "_t%d" % team)
        path = os.path.join(RAW_DIR, name + ".png")
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        files["t%d" % team if team is not None else "img"] = name + ".png"
    bpy.data.objects.remove(cam, do_unlink=True)
    return {"w": W, "h": H, "anchor": [round(anchor[0], 2), round(anchor[1], 2)], "plane_z": round(plane_z, 3),
            "px_per_m": PX_PER_M, "pitch_deg": 45.0, "raw": files}


def _kit_half(ob, half):
    """Copy of `ob` cut at the origin's depth: the part behind it (y >= 0, "back") or in front of it ("front")."""
    import bmesh
    me = ob.data.copy()
    bm = bmesh.new()
    bm.from_mesh(me)
    mw = ob.matrix_world
    # cut exactly at the origin's depth (y = 0 in the object's space; kits are built at the origin)
    geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
    bmesh.ops.bisect_plane(bm, geom=geom, dist=1e-5, plane_co=(0, 0, 0), plane_no=(0, 1, 0),
                           clear_inner=(half == "back"), clear_outer=(half == "front"))
    bm.to_mesh(me)
    bm.free()
    part = bpy.data.objects.new(ob.name + "_" + half, me)
    part.matrix_world = mw.copy()
    bpy.context.scene.collection.objects.link(part)
    ob.hide_render = True
    return part


def _has_team(root):
    for ob in [root] + list(root.children_recursive):
        if ob.type == "MESH" and any(m and m.name.startswith("TEAM_") for m in ob.data.materials):
            return True
    return False


def _want(key):
    return not ONLY or key in ONLY


def main():
    os.makedirs(RAW_DIR, exist_ok=True)
    _setup_render()
    manifest = {"schema_version": 1, "px_per_m": PX_PER_M, "pitch_deg": 45.0,
                "buildings": {}, "fields": {}, "upgrade_kits": {}, "environment": {}}
    if os.path.exists(MANIFEST) and ONLY:
        with open(MANIFEST) as f:
            manifest = json.load(f)
    done = []
    # buildings
    for path in sorted(glob.glob(os.path.join(HERE, "buildings", "*.py"))):
        name = os.path.splitext(os.path.basename(path))[0]
        if not _want(name):
            continue
        mod = importlib.import_module(name)
        importlib.reload(mod)
        res = mod.build()
        root = res[0] if isinstance(res, tuple) else res
        _lights()
        meta = render_object(root, "buildings/%s/%s" % (mod.CIV, mod.ASSET), (0, 1))
        manifest["buildings"].setdefault(mod.CIV, {})[mod.ASSET] = meta
        done.append(name)
    # environment props, fields, upgrade kits
    for path in sorted(glob.glob(os.path.join(HERE, "environment", "*.py"))):
        mname = os.path.splitext(os.path.basename(path))[0]
        if mname == "env_parts":
            continue
        mod = importlib.import_module(mname)
        importlib.reload(mod)
        for folder, biome in mod.VARIANTS:
            if mname == "upgrade_kit":
                key, section = folder, "upgrade_kits"
            else:
                asset = getattr(mod, "ASSET", mname)
                key = asset if folder == "common" else "%s/%s" % (folder, asset)
                section = "fields" if mname == "field" else "environment"
            if not _want("env:" + mname) and not _want("%s:%s" % (section, key)):
                continue
            ob, _ = mod.run(export=False, civ=folder, biome=biome)
            _lights()
            teams = (0, 1) if _has_team(ob) else (None,)
            if section == "upgrade_kits":
                # the kit surrounds the building: render its back half and front half separately so the
                # back pieces can stand BEHIND the building sprite and the front pieces in front of it
                entry = {}
                for half in ("back", "front"):
                    part = _kit_half(ob, half)
                    entry[half] = render_object(part, "%s/%s_%s" % (section, key, half), teams)
                    bpy.data.objects.remove(part, do_unlink=True)
                manifest[section][key] = entry
            else:
                manifest[section][key] = render_object(ob, "%s/%s" % (section, key), teams)
            done.append("%s:%s" % (section, key))
    with open(MANIFEST, "w") as f:
        json.dump(manifest, f, indent=1, sort_keys=True)
    print("rendered %d sprite sets -> %s" % (len(done), RAW_DIR))
    return done


main()
