"""Second step of the sprite pipeline (run OUTSIDE Blender, needs ImageMagick `magick`):

    python3 art_source/blender/finish_sprites.py

Reads sample_project/data/art/sprite_manifest.json (written by render_sprites.py), box-downsamples each
supersampled raw render in build/sprites_raw/ to its final pixel size (PX_PER_M), makes the alpha edge
hard (pixel-art cut-out, threshold 50%), writes sample_project/assets/sprites/<section>/<key>[_tN].png
and records the res:// paths in the manifest ("t0"/"t1" for team-coloured sets, "img" otherwise).
"""
import json, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
GODOT = os.path.join(REPO, "sample_project")
MANIFEST = os.path.join(GODOT, "data", "art", "sprite_manifest.json")
RAW = os.path.join(REPO, "build", "sprites_raw")
OUT = os.path.join(GODOT, "assets", "sprites")


def finish(section, key, meta):
    n = 0
    for slot, raw_name in meta.get("raw", {}).items():
        src = os.path.join(RAW, raw_name)
        if not os.path.exists(src):
            print("missing raw render:", src)
            continue
        rel = os.path.join(section, key + ("" if slot == "img" else "_" + slot) + ".png")
        dst = os.path.join(OUT, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        subprocess.run(["magick", src, "-filter", "Box", "-resize", "%dx%d!" % (meta["w"], meta["h"]),
                        "-channel", "A", "-threshold", "50%", "+channel", "-strip", dst], check=True)
        meta[slot] = "res://assets/sprites/" + rel.replace(os.sep, "/")
        _pin_import(dst, meta[slot])
        n += 1
    return n


def _pin_import(png_path, res_path):
    """Keep sprites lossless and without mipmaps: Godot would otherwise switch textures it sees used in
    3D (Sprite3D) to VRAM compression (blurry pixel art). Writes a stub .import for new files (Godot
    fills in the rest on import) and patches existing ones."""
    imp = png_path + ".import"
    want = {"compress/mode": "0", "mipmaps/generate": "false", "detect_3d/compress_to": "0"}
    if not os.path.exists(imp):
        with open(imp, "w") as f:
            f.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[deps]\n\nsource_file="%s"\n\n[params]\n\n' % res_path)
            for k, v in want.items():
                f.write("%s=%s\n" % (k, v))
        return
    lines = open(imp).read().splitlines()
    out = []
    for line in lines:
        k = line.split("=", 1)[0]
        out.append("%s=%s" % (k, want[k]) if k in want and "=" in line else line)
    with open(imp, "w") as f:
        f.write("\n".join(out) + "\n")


def main():
    with open(MANIFEST) as f:
        m = json.load(f)
    total = 0
    for section in ("buildings",):
        for civ, assets in m.get(section, {}).items():
            for asset, meta in assets.items():
                total += finish(section, "%s/%s" % (civ, asset), meta)
    for section in ("fields", "environment"):
        for key, meta in m.get(section, {}).items():
            total += finish(section, key, meta)
    for key, halves in m.get("upgrade_kits", {}).items():
        for half, meta in halves.items():
            total += finish("upgrade_kits", "%s_%s" % (key, half), meta)
    with open(MANIFEST, "w") as f:
        json.dump(m, f, indent=1, sort_keys=True)
    print("wrote %d sprites to %s" % (total, OUT))


if __name__ == "__main__":
    sys.exit(main())
