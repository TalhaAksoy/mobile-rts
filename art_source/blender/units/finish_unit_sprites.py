"""Second step of the unit sprite pipeline (system python + ImageMagick):

    python3 art_source/blender/units/finish_unit_sprites.py

For every build/unit_sprites_raw/<civ>/<role>/: box-downsamples each supersampled frame to its final size, makes the
alpha edge hard (pixel-art cut-out), packs the frames into one sheet per team (one row per animation, in
render_unit_sprites.ANIMS order, padded to the longest row) and writes
    sample_project/assets/sprites/units/<civ>/<role>_t0.png / _t1.png  (+ pinned .import: lossless, no mipmaps)
    sample_project/data/art/unit_sprite_manifest.json
"""
import json, os, subprocess, glob, shutil, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
GODOT = os.path.join(REPO, "sample_project")
RAW = os.path.join(REPO, "build", "unit_sprites_raw")
OUT = os.path.join(GODOT, "assets", "sprites", "units")
MANIFEST = os.path.join(GODOT, "data", "art", "unit_sprite_manifest.json")
ORDER = ["idle", "walk", "attack", "gather", "build", "death"]


def pin_import(png, res):
    imp = png + ".import"
    want = {"compress/mode": "0", "mipmaps/generate": "false", "detect_3d/compress_to": "0"}
    if not os.path.exists(imp):
        with open(imp, "w") as f:
            f.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[deps]\n\nsource_file="%s"\n\n[params]\n\n' % res)
            for k, v in want.items():
                f.write("%s=%s\n" % (k, v))
        return
    lines = open(imp).read().splitlines()
    with open(imp, "w") as f:
        f.write("\n".join(("%s=%s" % (l.split("=", 1)[0], want[l.split("=", 1)[0]]) if "=" in l and l.split("=", 1)[0] in want else l)
                          for l in lines) + "\n")


def main():
    manifest = {"version": 1, "units": {}}
    for meta_path in sorted(glob.glob(os.path.join(RAW, "*", "*", "meta.json"))):
        d = os.path.dirname(meta_path)
        role = os.path.basename(d)
        civ = os.path.basename(os.path.dirname(d))
        meta = json.load(open(meta_path))
        w, h = meta["w"], meta["h"]
        cols = max(meta["anims"][a]["frames"] for a in ORDER)
        entry = {"w": w, "h": h, "anchor": meta["anchor"], "px_per_m": meta["px_per_m"], "hframes": cols,
                 "vframes": len(ORDER), "anims": {}}
        os.makedirs(os.path.join(OUT, civ), exist_ok=True)
        for team in (0, 1):
            tmp = tempfile.mkdtemp()
            tiles = []
            for row, a in enumerate(ORDER):
                n = meta["anims"][a]["frames"]
                for i in range(cols):
                    src = os.path.join(d, "t%d_%s_%02d.png" % (team, a, min(i, n - 1)))
                    dst = os.path.join(tmp, "%02d_%02d.png" % (row, i))
                    if i < n:
                        subprocess.run(["magick", src, "-filter", "Box", "-resize", "%dx%d!" % (w, h),
                                        "-channel", "A", "-threshold", "50%", "+channel", dst], check=True)
                    else:
                        subprocess.run(["magick", "-size", "%dx%d" % (w, h), "xc:none", dst], check=True)
                    tiles.append(dst)
            sheet = os.path.join(OUT, civ, "%s_t%d.png" % (role, team))
            subprocess.run(["magick", "montage"] + tiles + ["-tile", "%dx%d" % (cols, len(ORDER)), "-geometry", "+0+0",
                                                             "-background", "none", "-strip", sheet], check=True)
            shutil.rmtree(tmp)
            res = "res://assets/sprites/units/%s/%s_t%d.png" % (civ, role, team)
            pin_import(sheet, res)
            entry["t%d" % team] = res
        for row, a in enumerate(ORDER):
            entry["anims"][a] = dict(meta["anims"][a], row=row)
        manifest["units"].setdefault(civ, {})[role] = entry
        print("sheet %s/%s %dx%d frames, %d cols" % (civ, role, w, h, cols))
    with open(MANIFEST, "w") as f:
        json.dump(manifest, f, indent=1, sort_keys=True)
    print("wrote", MANIFEST)


if __name__ == "__main__":
    main()
