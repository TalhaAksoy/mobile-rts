"""2D mode: renders every animation of the 3D units into sprite sheets (run in Blender, headless):

    blender -b --factory-startup --python art_source/blender/units/render_unit_sprites.py -- [civ/role ...]

then  python3 art_source/blender/units/finish_unit_sprites.py  (downsample, hard alpha, montage, manifest).

One view, like the gallery sheets: 3/4 from the front-left (yaw 30 deg, pitch 35 deg), orthographic, same warm sun
and exposure as the building sprites (render_sprites.py), team colour on the TEAM_Trim sash. The game shows the
sheet on a billboard and mirrors it when the unit walks to the right.
Frames per animation (ANIMS) are sampled evenly over each action; every frame of a role has the same size and the
feet at the same pixel, so the animation never jitters.
"""
import bpy, sys, os, json, math, mathutils

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
RAW = os.path.join(REPO, "build", "unit_sprites_raw")
PX_PER_M = 32
SUPERSAMPLE = 4
YAW = math.radians(30.0)       # camera to the character's front-left
PITCH = math.radians(35.0)
EXPOSURE = -1.5                # same calibration as the building sprites
TEAM_COLORS = [(0.18, 0.52, 0.95), (0.92, 0.22, 0.22)]
ANIMS = [("idle", "idle-loop", 4, 4), ("walk", "walk-loop", 8, 10), ("attack", "attack", 6, 8),
         ("gather", "gather-loop", 6, 7), ("build", "build-loop", 4, 8), ("death", "death", 6, 7)]   # name, action, frames, fps

# camera basis: looks at the character from the front-left and above (character faces -Y)
_dir_to_cam = mathutils.Vector((-math.sin(YAW) * math.cos(PITCH), -math.cos(YAW) * math.cos(PITCH), math.sin(PITCH)))
CAM_FWD = -_dir_to_cam
CAM_RIGHT = CAM_FWD.cross(mathutils.Vector((0, 0, 1))).normalized()
CAM_UP = CAM_RIGHT.cross(CAM_FWD).normalized()


def _lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def setup_render():
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
        scene.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    scene.view_settings.look = "None"
    scene.view_settings.exposure = EXPOSURE
    scene.render.resolution_percentage = 100
    try:
        scene.eevee.taa_render_samples = 8      # flat-shaded low-poly: 8 samples look the same as 64, ~6x faster
    except AttributeError:
        pass
    sun_data = bpy.data.lights.new("PE_SpriteSun", "SUN")
    sun_data.energy = 3.2
    sun_data.color = (1.0, 0.95, 0.86)
    sun = bpy.data.objects.new("PE_SpriteSun", sun_data)
    sun.rotation_euler = (math.radians(48), 0, math.radians(-40))
    scene.collection.objects.link(sun)
    if scene.world is None:
        scene.world = bpy.data.worlds.new("PE_World")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == "BACKGROUND"), None)
    if bg:
        bg.inputs[0].default_value = (0.60, 0.65, 0.74, 1.0)
        bg.inputs[1].default_value = 0.8


def set_team(team):
    mat = bpy.data.materials.get("TEAM_Trim")
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    r, g, b = (_lin(c) for c in TEAM_COLORS[team])
    bsdf.inputs["Base Color"].default_value = (r, g, b, 1.0)


def frames_of(action, n):
    f0, f1 = int(action.frame_range[0]), int(action.frame_range[1])
    loop = action.name.endswith("-loop")
    span = (f1 - f0) if not loop else (f1 - f0)          # loops: last key == first key, so sample [f0, f1)
    if loop:
        return [f0 + span * i / n for i in range(n)]
    return [f0 + span * i / (n - 1) for i in range(n)]


def visible_meshes():
    return [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.name.startswith("PROP_")]


def bounds(arm):
    """Camera-space bounds over every sampled frame of every animation (so all frames share one size)."""
    dg = bpy.context.evaluated_depsgraph_get()
    lo = [1e9, 1e9]
    hi = [-1e9, -1e9]
    for _, act_name, n, _ in ANIMS:
        arm.animation_data.action = bpy.data.actions[act_name]
        for f in frames_of(bpy.data.actions[act_name], n):
            bpy.context.scene.frame_set(int(f), subframe=f - int(f))
            dg = bpy.context.evaluated_depsgraph_get()
            for ob in visible_meshes():
                ev = ob.evaluated_get(dg)
                me = ev.to_mesh()
                mw = ob.matrix_world
                for v in me.vertices:
                    p = mw @ v.co
                    x, y = p.dot(CAM_RIGHT), p.dot(CAM_UP)
                    lo[0] = min(lo[0], x); lo[1] = min(lo[1], y)
                    hi[0] = max(hi[0], x); hi[1] = max(hi[1], y)
                ev.to_mesh_clear()
    return lo, hi


def render_unit(blend, civ, role):
    bpy.ops.wm.open_mainfile(filepath=blend)
    setup_render()
    scene = bpy.context.scene
    arm = bpy.data.objects["Rig"]
    for o in scene.objects:
        if o.name.startswith("PROP_"):
            o.hide_render = True
    lo, hi = bounds(arm)
    pad = 2.0 / PX_PER_M
    lo = [lo[0] - pad, lo[1] - pad]
    W = int(math.ceil((hi[0] + pad - lo[0]) * PX_PER_M))
    H = int(math.ceil((hi[1] + pad - lo[1]) * PX_PER_M))
    cx = lo[0] + W / PX_PER_M / 2
    cy = lo[1] + H / PX_PER_M / 2
    cam_data = bpy.data.cameras.new("PE_SpriteCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = max(W, H) / PX_PER_M
    cam = bpy.data.objects.new("PE_SpriteCam", cam_data)
    scene.collection.objects.link(cam)
    centre = CAM_RIGHT * cx + CAM_UP * cy
    cam.location = centre - CAM_FWD * 20.0
    cam.rotation_euler = CAM_FWD.to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    scene.render.resolution_x = W * SUPERSAMPLE
    scene.render.resolution_y = H * SUPERSAMPLE
    # pixel of the feet (world origin) inside the frame, measured from the top-left
    anchor = [(0.0 - lo[0]) * PX_PER_M, (lo[1] + H / PX_PER_M - 0.0) * PX_PER_M]
    out_dir = os.path.join(RAW, civ, role)
    os.makedirs(out_dir, exist_ok=True)
    meta = {"w": W, "h": H, "anchor": anchor, "px_per_m": PX_PER_M, "yaw_deg": math.degrees(YAW),
            "pitch_deg": math.degrees(PITCH), "anims": {}}
    for team in (0, 1):
        set_team(team)
        for name, act_name, n, fps in ANIMS:
            act = bpy.data.actions[act_name]
            arm.animation_data.action = act
            for i, f in enumerate(frames_of(act, n)):
                scene.frame_set(int(f), subframe=f - int(f))
                scene.render.filepath = os.path.join(out_dir, "t%d_%s_%02d.png" % (team, name, i))
                bpy.ops.render.render(write_still=True)
            meta["anims"][name] = {"frames": n, "fps": fps, "loop": act_name.endswith("-loop")}
    with open(os.path.join(out_dir, "meta.json"), "w") as fh:
        json.dump(meta, fh, indent=1)
    print("RENDERED %s/%s %dx%d" % (civ, role, W, H))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    targets = [a for a in argv if "/" in a]
    blend_root = os.path.join(HERE, "blend")
    if not targets:
        for civ in sorted(os.listdir(blend_root)):
            for f in sorted(os.listdir(os.path.join(blend_root, civ))):
                if f.endswith(".blend"):
                    targets.append("%s/%s" % (civ, f[:-6]))
    for t in targets:
        civ, role = t.split("/")
        render_unit(os.path.join(blend_root, civ, role + ".blend"), civ, role)


main()
