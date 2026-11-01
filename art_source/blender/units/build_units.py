"""Builds 3D unit characters (rig + body + actions) and exports them to Godot.

    blender -b --factory-startup --python art_source/blender/units/build_units.py -- [civ/role ...] [--preview]

No arguments = every civ/role in unitstyle.STYLES. Writes
    sample_project/assets/3d/units/<civ>/<role>.glb
    sample_project/assets/3d/materials/textures/PE_UnitPalette.png (+ pinned .import)
    art_source/blender/units/meta/<civ>_<role>.json        (tris, bones, actions, height)
    docs/art/previews/units/<civ>_<role>.png              (--preview: front-left 3/4 + RTS view)
"""
import bpy, sys, os, json, math, importlib

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import charkit, outfit, unitstyle
for m in (charkit, outfit, unitstyle):
    importlib.reload(m)

REPO = charkit.REPO
GODOT = charkit.GODOT
PALETTE_PNG = os.path.join(GODOT, "assets", "3d", "materials", "textures", "PE_UnitPalette.png")


def _pin_import(png):
    imp = png + ".import"
    res = "res://" + os.path.relpath(png, GODOT).replace(os.sep, "/")
    want = {"compress/mode": "0", "mipmaps/generate": "false", "detect_3d/compress_to": "0"}
    if not os.path.exists(imp):
        with open(imp, "w") as f:
            f.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[deps]\n\nsource_file="%s"\n\n[params]\n\n' % res)
            for k, v in want.items():
                f.write("%s=%s\n" % (k, v))


def build_one(civ, role, palette_img, preview=False):
    charkit.reset()
    style = unitstyle.get(civ, role)
    mats = charkit.get_materials(palette_img)
    mount = style.get("mount")
    props = []
    if mount:
        body, bones = outfit.build_mounted(style, role, mount)
        arm = charkit.build_armature("Rig", bones)
    else:
        arm = charkit.build_armature("Rig")
        body = outfit.build_body(style, role)
    ob = body.to_object("Body", arm, mats)
    tris = body.tris
    if role == "villager":
        cb = outfit.build_cargo()
        cb.to_object("PROP_cargo_wood", arm, mats)
        tris += cb.tris
        props.append("PROP_cargo_wood")
    if mount:
        charkit.make_mount_actions(arm, style.get("attack", "slash"))
    else:
        charkit.make_actions(arm, style.get("attack", "slash"))
    out = os.path.join(GODOT, "assets", "3d", "units", civ, role + ".glb")
    charkit.export_glb(out)
    zs = [(ob.matrix_world @ v.co).z for v in ob.data.vertices]
    meta = {"civ": civ, "role": role, "tris": tris, "bones": len(arm.data.bones), "height": round(max(zs), 3),
            "actions": sorted(a.name for a in bpy.data.actions), "props": props, "attack": style.get("attack", "slash"),
            "mount": mount or "", "model": "res://assets/3d/units/%s/%s.glb" % (civ, role)}
    md = os.path.join(HERE, "meta")
    os.makedirs(md, exist_ok=True)
    with open(os.path.join(md, "%s_%s.json" % (civ, role)), "w") as f:
        json.dump(meta, f, indent=1)
    blend_dir = os.path.join(HERE, "blend", civ)
    os.makedirs(blend_dir, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(blend_dir, role + ".blend"), copy=True)
    if preview:
        render_preview(arm, os.path.join(REPO, "docs", "art", "previews", "units", "%s_%s.png" % (civ, role)),
                       scale=3.4 if mount else 2.6)
    print("BUILT %s/%s tris=%d height=%.2f mount=%s" % (civ, role, tris, meta["height"], mount or "-"))
    return meta


def render_preview(arm, path, action=None, frame=1, scale=2.6):
    """Workbench render, gallery-like 3/4 front-left view, transparent background."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    scn = bpy.context.scene
    scn.render.engine = 'BLENDER_WORKBENCH'
    scn.display.shading.light = 'STUDIO'
    scn.display.shading.color_type = 'TEXTURE'
    scn.render.film_transparent = True
    scn.render.resolution_x = scn.render.resolution_y = 512
    cam_data = bpy.data.cameras.new("PrevCam")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = scale
    cam = bpy.data.objects.new("PrevCam", cam_data)
    scn.collection.objects.link(cam)
    scn.camera = cam
    d = (-0.55, -0.85, 0.45)
    import mathutils
    v = mathutils.Vector(d).normalized()
    cam.location = mathutils.Vector((0, 0, 1.0)) + v * 8
    cam.rotation_euler = (mathutils.Vector((0, 0, 1.0)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
    if action:
        arm.animation_data.action = bpy.data.actions[action]
        scn.frame_set(frame)
    scn.render.filepath = path
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    preview = "--preview" in argv
    targets = [a for a in argv if "/" in a]
    if not targets:
        targets = ["%s/%s" % (c, r) for c in unitstyle.STYLES for r in unitstyle.STYLES[c]]
    os.makedirs(os.path.dirname(PALETTE_PNG), exist_ok=True)
    charkit.register_patterns(unitstyle.PATTERNS)
    pal = charkit.bake_palette(PALETTE_PNG)
    _pin_import(PALETTE_PNG)
    for t in targets:
        civ, role = t.split("/")
        build_one(civ, role, pal, preview)


if __name__ == "__main__":
    main()
