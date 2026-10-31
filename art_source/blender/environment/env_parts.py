"""Small geometry helpers shared by the biome environment props (palm fronds, cactus pads,
rotated blocks). Everything is emitted through pe_kit.Builder, so NAT_* faces still atlas-fit."""
import math
from mathutils import Vector as V
from pe_kit import UVS


def frond(b, base, yaw, length, width, rise, droop, mat="NAT_foliage", segs=4, fold=0.35):
    """Arching palm frond: a V-folded strip (ridge raised by `fold`*width) with top AND bottom
    faces, so it reads from the 45-degree camera and from below. ~segs*8 tris."""
    d = V((math.cos(yaw), math.sin(yaw), 0.0))
    side = V((-d.y, d.x, 0.0))
    up = V((0, 0, 1))
    rows = []
    for k in range(segs + 1):
        t = k / segs
        p = V(base) + d * (length * t) + up * (rise * math.sin(math.pi * t * 0.75) - droop * t * t)
        w = width * math.sin(math.pi * (0.12 + 0.88 * t * 0.92)) if k < segs else width * 0.08
        rows.append((p + side * w, p + up * (w * fold), p - side * w, length * t))
    verts, faces, uvs = [], [], []
    for k in range(segs):
        l0, c0, r0, u0 = rows[k]
        l1, c1, r1, u1 = rows[k + 1]
        for a0, a1, b0, b1 in ((l0, l1, c0, c1), (c0, c1, r0, r1)):
            base_i = len(verts)
            verts += [a0.copy(), b0.copy(), b1.copy(), a1.copy()]
            uv = [(u0 * UVS, 0), (u0 * UVS, width * UVS), (u1 * UVS, width * UVS), (u1 * UVS, 0)]
            faces.append((base_i, base_i + 1, base_i + 2, base_i + 3))      # top
            uvs.append(uv)
            faces.append((base_i + 3, base_i + 2, base_i + 1, base_i))      # underside
            uvs.append(list(reversed(uv)))
    b.mesh(verts, faces, uvs, mat)


def pad(b, center, yaw, tilt, w, h, thick, mat="NAT_foliage", n=8):
    """Flattened oval cactus pad standing roughly upright. yaw turns it around Z, tilt leans it
    sideways. Front + back n-gon + rim quads = 2*(n-2) + 2*n tris."""
    c = V(center)
    ax = V((math.cos(yaw), math.sin(yaw), 0.0))          # pad width direction
    nrm = V((-ax.y, ax.x, 0.0))                          # pad facing direction
    upv = (V((0, 0, 1)) * math.cos(tilt) + ax * math.sin(tilt)).normalized()
    ring = [c + ax * (w * 0.5 * math.cos(2 * math.pi * i / n)) + upv * (h * 0.5 * math.sin(2 * math.pi * i / n))
            for i in range(n)]
    front = [p + nrm * (thick * 0.5) for p in ring]
    back = [p - nrm * (thick * 0.5) for p in ring]
    uv_ring = [((0.5 + 0.5 * math.cos(2 * math.pi * i / n)) * w * UVS, (0.5 + 0.5 * math.sin(2 * math.pi * i / n)) * h * UVS)
               for i in range(n)]
    b.mesh(front, [tuple(reversed(range(n)))], [list(reversed(uv_ring))], mat)
    b.mesh(back, [tuple(range(n))], [uv_ring], mat)
    verts, faces, uvs = [], [], []
    for i in range(n):
        j = (i + 1) % n
        k = len(verts)
        verts += [front[i].copy(), front[j].copy(), back[j].copy(), back[i].copy()]
        faces.append((k, k + 1, k + 2, k + 3))
        uvs.append([(0, 0), (0.05, 0), (0.05, 0.05), (0, 0.05)])
    b.mesh(verts, faces, uvs, mat)
    return c + upv * (h * 0.5), upv, ax


def rbox(b, cx, cy, z0, w, d, h, ang, mat, cap=True):
    """Box of size w x d x h standing on z0, rotated `ang` radians around Z (via prism)."""
    ca, sa = math.cos(ang), math.sin(ang)
    pts = []
    for (x, y) in ((-w / 2, -d / 2), (w / 2, -d / 2), (w / 2, d / 2), (-w / 2, d / 2)):
        pts.append((cx + x * ca - y * sa, cy + x * sa + y * ca))
    b.prism(pts, z0, z0 + h, mat, cap=cap)


def blob(b, c, r, h, mat, segs=7):
    """Low-poly foliage/rock clump: short skirt + squashed dome (same idiom as the oak canopy)."""
    x, y, z = c
    b.cylinder((x, y, z - h * 0.3), r * 0.72, h * 0.3, mat, segs=segs, r_top=r, cap=False, smooth=False)
    b.dome((x, y, z), r, mat, segs=segs, rings=2, height=h * 0.7, smooth=False)
