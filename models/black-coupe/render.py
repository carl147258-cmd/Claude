#!/usr/bin/env python3
"""Tiny software renderer for Roblox-style primitive parts (blocks, wedges, cylinders).

Renders the exact parts list from car.py, so preview images match the Studio model.
Usage: python3 render.py <out.png> [view] [env]
  view: front34 (default) | side | rear34 | top
  env:  studio (grey sky) | neon (synthwave reflections, transparent background)
"""

import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

import car

FONT = "/usr/share/fonts/opentype/inter/Inter-Bold.otf"


# --- meshes in local unit space (-0.5..0.5) -------------------------------------------
def block_mesh():
    v = np.array([[x, y, z] for x in (-.5, .5) for y in (-.5, .5) for z in (-.5, .5)])
    idx = lambda x, y, z: (x > 0) * 4 + (y > 0) * 2 + (z > 0)
    quads = []
    for axis in range(3):
        for s in (-.5, .5):
            pts = []
            for a in (-.5, .5):
                for b in (-.5, .5):
                    p = [0, 0, 0]
                    p[axis] = s
                    others = [i for i in range(3) if i != axis]
                    p[others[0]], p[others[1]] = a, b
                    pts.append(idx(*p))
            quads.append((pts[0], pts[1], pts[3], pts[2]))
    tris = [t for q in quads for t in ((q[0], q[1], q[2]), (q[0], q[2], q[3]))]
    return v, np.array(tris)


def wedge_mesh():
    # low edge at -Z (front), vertical face at +Z (back), as Roblox WedgePart
    v = np.array([
        [-.5, -.5, -.5], [.5, -.5, -.5], [.5, -.5, .5], [-.5, -.5, .5],  # bottom
        [-.5, .5, .5], [.5, .5, .5],                                      # top back edge
    ])
    tris = [(0, 1, 2), (0, 2, 3),        # bottom
            (3, 2, 5), (3, 5, 4),        # back face
            (0, 4, 5), (0, 5, 1),        # slope
            (0, 3, 4), (1, 5, 2)]        # sides
    return v, np.array(tris)


def cylinder_mesh(n=40):
    ang = np.linspace(0, 2 * np.pi, n, endpoint=False)
    ring = np.stack([np.cos(ang) * .5, np.sin(ang) * .5], 1)
    v = [[-.5, 0, 0], [.5, 0, 0]]
    for x in (-.5, .5):
        v += [[x, r[0], r[1]] for r in ring]
    v = np.array(v)
    tris = []
    for i in range(n):
        j = (i + 1) % n
        a0, a1, b0, b1 = 2 + i, 2 + j, 2 + n + i, 2 + n + j
        tris += [(0, a1, a0), (1, b0, b1), (a0, a1, b1), (a0, b1, b0)]
    return v, np.array(tris)


MESHES = {"Block": block_mesh(), "Wedge": wedge_mesh(), "Cylinder": cylinder_mesh()}


def part_triangles(p):
    shape = "Wedge" if p["cls"] == "WedgePart" else p["shape"]
    v, t = MESHES[shape]
    world = (v * np.array(p["size"])) @ p["rot"].T + np.array(p["pos"])
    tri = world[t]
    n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-12
    # make normals point away from the part centre
    # use the solid's vertex centroid (a wedge's slope passes through its box centre)
    centroid = world.mean(0)
    outward = np.einsum("ij,ij->i", n, tri.mean(1) - centroid) < 0
    n[outward] *= -1
    return tri, n


# --- environment / shading ---------------------------------------------------------------
def env_color(R, env):
    y = R[..., 1:2]
    if env == "neon":
        sky_top, horizon, ground = np.array([0.12, 0.04, 0.3]), np.array([1.0, 0.25, 0.7]), np.array([0.05, 0.02, 0.1])
        stripe = np.array([0.3, 0.9, 1.0])
    else:
        sky_top, horizon, ground = np.array([0.55, 0.68, 0.85]), np.array([0.92, 0.93, 0.95]), np.array([0.22, 0.22, 0.24])
        stripe = np.array([1.0, 1.0, 1.0])
    up = np.clip(y, 0, 1)
    c = np.where(y > 0, horizon * (1 - up ** 0.5) + sky_top * up ** 0.5, horizon * 0.4 + ground * 0.6)
    # bright softbox stripes give the glossy paint its "studio" highlights
    band = np.exp(-((y - 0.32) / 0.05) ** 2) * 1.6 + np.exp(-((y - 0.08) / 0.03) ** 2) * 0.8
    return c + stripe * band


def render(view="front34", env="studio", W=1600, H=1200, ss=2):
    W2, H2 = W * ss, H * ss
    cams = {
        "front34": ((-19.5, 4.6, -21.0), (0.3, 2.0, -0.3), 30),
        "side": ((-30, 3.0, 0.0), (0, 2.3, 0), 30),
        "rear34": ((15, 5.0, 18), (0, 2.0, 0.5), 32),
        "top": ((-12, 20, -14), (0, 1.5, 0), 34),
        "icon": ((-10.5, 3.9, -21.5), (1.2, 3.3, -0.8), 33),
    }
    eye, target, fov = cams[view]
    eye, target = np.array(eye, float), np.array(target, float)
    f = target - eye
    f /= np.linalg.norm(f)
    r = np.cross(f, [0, 1, 0])
    r /= np.linalg.norm(r)
    u = np.cross(r, f)
    focal = (W2 / 2) / math.tan(math.radians(fov) / 2)

    color = np.zeros((H2, W2, 3))
    idbuf = np.full((H2, W2), -1)
    zbuf = np.zeros((H2, W2))          # stores 1/z (bigger = closer)
    neon = np.zeros((H2, W2, 3))
    plate_quads = []

    sun = np.array([-0.45, 0.8, -0.4])
    sun /= np.linalg.norm(sun)
    # per-pixel view directions
    ys, xs = np.mgrid[0:H2, 0:W2]
    dirs = ((xs - W2 / 2 + 0.5)[..., None] * r - (ys - H2 / 2 + 0.5)[..., None] * u + focal * f)
    dirs /= np.linalg.norm(dirs, axis=2, keepdims=True)

    for pi, p in enumerate(car.parts):
        tris, normals = part_triangles(p)
        base = np.array(p["color"]) / 255.0
        refl = p.get("reflectance", 0.0)
        is_neon = p["material"] == "Neon"
        for tri, n in zip(tris, normals):
            rel = tri - eye
            xc, yc, zc = rel @ r, rel @ u, rel @ f
            if np.any(zc < 0.2):
                continue
            sx = W2 / 2 + xc / zc * focal
            sy = H2 / 2 - yc / zc * focal
            x0, x1 = int(max(0, math.floor(sx.min()))), int(min(W2 - 1, math.ceil(sx.max())))
            y0, y1 = int(max(0, math.floor(sy.min()))), int(min(H2 - 1, math.ceil(sy.max())))
            if x0 > x1 or y0 > y1:
                continue
            # back-face culling (normal facing away from the camera)
            if np.dot(n, tri.mean(0) - eye) > 0:
                continue
            px, py = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
            (ax, bx, cx), (ay, by, cy) = sx, sy
            area = (bx - ax) * (cy - ay) - (cx - ax) * (by - ay)
            if abs(area) < 1e-9:
                continue
            w0 = ((bx - px) * (cy - py) - (cx - px) * (by - py)) / area
            w1 = ((cx - px) * (ay - py) - (ax - px) * (cy - py)) / area
            w2 = 1 - w0 - w1
            inside = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
            if not inside.any():
                continue
            invz = w0 / zc[0] + w1 / zc[1] + w2 / zc[2]
            zslice = zbuf[y0:y1 + 1, x0:x1 + 1]
            draw = inside & (invz > zslice)
            if not draw.any():
                continue
            zslice[draw] = invz[draw]
            d = dirs[y0:y1 + 1, x0:x1 + 1][draw]
            if is_neon:
                col = np.tile(base * 1.1, (len(d), 1))
                neon[y0:y1 + 1, x0:x1 + 1][draw] = base
            else:
                ndotl = max(0.0, float(n @ sun))
                hemi = 0.5 + 0.5 * n[1]
                amb = (np.array([0.32, 0.33, 0.38]) * hemi + np.array([0.12, 0.11, 0.1]) * (1 - hemi))
                if env == "neon":
                    amb = amb * np.array([0.9, 0.7, 1.2])
                diffuse = base * (amb + 0.85 * ndotl)
                R = d - 2 * (d @ n)[:, None] * n
                cosv = np.clip(-(d @ n), 0, 1)[:, None]
                fres = np.clip(refl * 0.35 + (1 - cosv) ** 4 * refl * 2.2, 0, 0.9)  # glossy but stays dark at normal view
                h = sun - d
                h /= np.linalg.norm(h, axis=1, keepdims=True)
                spec = np.clip(h @ n, 0, 1)[:, None] ** 80 * (0.6 if refl > 0.1 else 0.15)
                col = diffuse * (1 - fres) + env_color(R, env) * fres + spec
                neon[y0:y1 + 1, x0:x1 + 1][draw] = 0
            color[y0:y1 + 1, x0:x1 + 1][draw] = col
            idbuf[y0:y1 + 1, x0:x1 + 1][draw] = pi
        if p.get("plate_text"):
            plate_quads.append(p)

    mask = (zbuf > 0).astype(np.float32)
    global LAST_IDS, LAST_SS
    LAST_IDS, LAST_SS = idbuf, ss

    # glow around neon parts
    glow = Image.fromarray((np.clip(neon, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(14 * ss))
    color = color + np.array(glow) / 255.0 * 0.9
    glow_alpha = np.array(glow.convert("L")) / 255.0

    img = Image.fromarray((np.clip(color, 0, 1) ** (1 / 1.1) * 255).astype(np.uint8))
    alpha = np.clip(mask + glow_alpha * 1.5, 0, 1)
    rgba = img.convert("RGBA")
    rgba.putalpha(Image.fromarray((alpha * 255).astype(np.uint8)))

    # licence plate text: project the plate's outer face and draw text onto it
    for p in plate_quads:
        sxz = np.array(p["size"]) / 2
        face_z = -sxz[2] if p["plate_face"] == "Front" else sxz[2]
        # seen from outside, local +X is on the viewer's left for the front face
        corners = [(sxz[0], sxz[1]), (-sxz[0], sxz[1]), (-sxz[0], -sxz[1]), (sxz[0], -sxz[1])]
        if p["plate_face"] == "Back":
            corners = [(-sxz[0], sxz[1]), (sxz[0], sxz[1]), (sxz[0], -sxz[1]), (-sxz[0], -sxz[1])]
        world = np.array([[cx, cy, face_z * 1.3] for cx, cy in corners]) @ p["rot"].T + np.array(p["pos"])
        normal = p["rot"] @ np.array([0, 0, -1 if p["plate_face"] == "Front" else 1])
        if np.dot(normal, world.mean(0) - eye) > 0:
            continue
        rel = world - eye
        q = [(W2 / 2 + (v @ r) / (v @ f) * focal, H2 / 2 - (v @ u) / (v @ f) * focal) for v in rel]
        TW, TH = 700, 150
        tex = Image.new("RGBA", (TW, TH), (0, 0, 0, 0))
        ImageDraw.Draw(tex).text((TW / 2 + 30, TH / 2 + 4), p["plate_text"], font=ImageFont.truetype(FONT, 104),
                                 fill=(15, 15, 15, 255), anchor="mm")
        src = [(0, 0), (TW, 0), (TW, TH), (0, TH)]
        A, Bv = [], []
        for (x, y), (U, V) in zip(q, src):
            A += [[x, y, 1, 0, 0, 0, -U * x, -U * y], [0, 0, 0, x, y, 1, -V * x, -V * y]]
            Bv += [U, V]
        coeffs = np.linalg.solve(np.array(A), np.array(Bv)).tolist()
        warped = tex.transform((W2, H2), Image.PERSPECTIVE, coeffs, Image.BICUBIC)
        rgba.alpha_composite(warped)

    return rgba.resize((W, H), Image.LANCZOS)


def with_floor(img, env):
    W, H = img.size
    if env == "neon":
        return img
    bg = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    top, bottom = np.array([200, 205, 212]), np.array([120, 122, 128])
    grad = np.linspace(0, 1, H)[:, None, None]
    bg = Image.fromarray((top * (1 - grad) + bottom * grad).repeat(W, 1).astype(np.uint8)).convert("RGBA")
    a = np.array(img.split()[3])
    rows = np.where(a.max(1) > 0)[0]
    cols = np.where(a.max(0) > 0)[0]
    if len(rows):
        sh = Image.new("L", (W, H), 0)
        ImageDraw.Draw(sh).ellipse([cols.min() + W * 0.02, rows.max() - H * 0.05, cols.max() - W * 0.02, rows.max() + H * 0.03], fill=150)
        shadow = Image.new("RGBA", (W, H), (0, 0, 0, 255))
        shadow.putalpha(sh.filter(ImageFilter.GaussianBlur(H * 0.025)))
        bg.alpha_composite(shadow)
    bg.alpha_composite(img)
    return bg


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "preview.png"
    view = sys.argv[2] if len(sys.argv) > 2 else "front34"
    env = sys.argv[3] if len(sys.argv) > 3 else "studio"
    im = render(view, env)
    with_floor(im, env).save(out)
    print("saved", out)
