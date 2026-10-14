"""High-fidelity black sports coupé (no brand) for Roblox, built with Blender's Python API.

Run with a Python that has the `bpy` module (Blender 5.x):
    python build_car.py [--render out_dir] [--export car.glb]

Units are Roblox studs (1 stud ~ 0.28 m). Blender axes: X = car's right, Y = forward (front at +Y),
Z = up. glTF export converts to Y-up with the front facing -Z, which is Roblox's forward direction.
Reference: 2-door compact sports coupé, 4.54 x 1.84 x 1.39 m, wheelbase 2.74 m, 245/35 R19 tyres.
"""

import math
import os
import sys

import bpy  # must come first: bmesh/mathutils are provided by bpy
import bmesh
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))
PLATE_TEXT = "RB 2026"

# --- key dimensions (studs) -------------------------------------------------------------
L = 16.2                     # overall length; u = distance from the front bumper
FRONT_AXLE_U, REAR_AXLE_U = 2.86, 12.65
WHEEL_R, TYRE_W, TRACK_HALF = 1.17, 0.87, 2.82
RIM_R = 0.86


def y_of(u):
    """Blender Y coordinate for a distance u measured from the front bumper."""
    return L / 2 - u


def interp(u, keys):
    ks = np.array(keys, dtype=float)
    return float(np.interp(u, ks[:, 0], ks[:, 1]))


# --- body profile keyframes: (u, value) -------------------------------------------------------
TOP_Y = [(0.0, 2.52), (0.12, 2.7), (0.4, 2.8), (1.5, 2.95), (3.0, 3.1), (4.5, 3.2), (5.4, 3.25),
         (7.5, 3.28), (14.6, 3.36), (15.2, 3.48), (15.7, 3.6), (15.95, 3.56), (16.1, 3.4), (16.2, 3.0)]
MAX_HALF = [(0.0, 2.85), (0.18, 3.05), (0.6, 3.15), (1.6, 3.2), (2.9, 3.22), (4.4, 3.2), (8.0, 3.16),
            (11.0, 3.22), (12.6, 3.28), (14.6, 3.24), (15.6, 3.08), (16.0, 2.9), (16.2, 2.6)]
DECK_HALF = [(0.0, 2.45), (0.25, 2.75), (1.0, 2.88), (3.0, 2.92), (6.5, 2.95), (14.5, 2.95), (15.6, 2.8),
             (16.2, 2.3)]
BOT_Y = [(0.0, 0.62), (0.3, 0.5), (15.9, 0.55), (16.2, 0.68)]

# greenhouse (cabin): roof height along the car, base sits on the beltline
CAB_U0, CAB_U1 = 5.4, 15.05
ROOF_Y = [(5.4, 3.26), (6.0, 3.64), (7.0, 4.28), (7.8, 4.7), (8.6, 4.9), (9.6, 4.96), (10.8, 4.92),
          (11.9, 4.72), (13.0, 4.35), (14.0, 3.92), (14.7, 3.62), (15.05, 3.5)]
CAB_BASE_HALF = [(5.4, 2.55), (6.1, 2.8), (7.0, 2.86), (13.0, 2.86), (14.4, 2.74), (15.05, 2.55)]
CAB_TOP_HALF = [(5.4, 2.45), (6.0, 2.3), (7.6, 2.2), (12.0, 2.2), (13.6, 2.25), (15.05, 2.45)]
ROOF_U0, ROOF_U1 = 8.0, 11.6          # roof panel between windshield and rear window
DLO_U0, DLO_U1, KINK_U = 6.25, 13.55, 12.3
B_PILLAR_U = 10.45


# --- helpers -------------------------------------------------------------------------------------
def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name, color, rough=0.4, metal=0.0, coat=0.0, emit=None, emit_strength=0.0, image=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    b.inputs["Coat Weight"].default_value = coat
    b.inputs["Coat Roughness"].default_value = 0.03
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = emit_strength
    if image:
        tex = m.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = image
        m.node_tree.links.new(tex.outputs["Color"], b.inputs["Base Color"])
    return m


def obj_from_bmesh(name, bm, mat):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(mat)
    return ob


def loft(name, rings, mat, cap_start=True, cap_end=True, closed=True):
    """rings: list of lists of (x, y, z) with equal point count. Builds a quad surface."""
    bm = bmesh.new()
    vrings = [[bm.verts.new(p) for p in ring] for ring in rings]
    n = len(rings[0])
    for a, b in zip(vrings[:-1], vrings[1:]):
        for i in range(n if closed else n - 1):
            j = (i + 1) % n
            try:
                bm.faces.new((a[i], a[j], b[j], b[i]))
            except ValueError:
                pass
    if cap_start:
        bm.faces.new(vrings[0][::-1])
    if cap_end:
        bm.faces.new(vrings[-1])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bmesh(name, bm, mat)


def add_modifier_subsurf(ob, levels=2):
    m = ob.modifiers.new("Subsurf", "SUBSURF")
    m.levels = levels
    m.render_levels = levels
    return m


def apply_all(ob):
    bpy.context.view_layer.objects.active = ob
    for m in list(ob.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)


def shade_smooth(ob, angle=40):
    for p in ob.data.polygons:
        p.use_smooth = True
    try:
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.shade_auto_smooth(angle=math.radians(angle))
    except Exception:
        pass


def cylinder(name, r, depth, loc, mat, axis="X", verts=48, bevel=0.0):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc)
    ob = bpy.context.active_object
    ob.name = name
    if axis == "X":
        ob.rotation_euler = (0, math.radians(90), 0)
    elif axis == "Y":
        ob.rotation_euler = (math.radians(90), 0, 0)
    ob.data.materials.append(mat)
    if bevel:
        b = ob.modifiers.new("Bevel", "BEVEL")
        b.width = bevel
        b.segments = 4
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return ob


def rounded_box(name, size, loc, mat, bevel=0.05, rot=(0, 0, 0), segments=3):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        b = ob.modifiers.new("Bevel", "BEVEL")
        b.width = bevel
        b.segments = segments
        b.limit_method = "NONE"
    ob.data.materials.append(mat)
    return ob


class Surface:
    """Ray-cast helper to place details exactly on the body surface."""

    def __init__(self, objs):
        deps = bpy.context.evaluated_depsgraph_get()
        verts, polys, off = [], [], 0
        for ob in objs:
            ev = ob.evaluated_get(deps)
            me = ev.to_mesh()
            mw = ob.matrix_world
            verts += [mw @ v.co for v in me.vertices]
            polys += [[i + off for i in p.vertices] for p in me.polygons]
            off += len(me.vertices)
            ev.to_mesh_clear()
        self.bvh = BVHTree.FromPolygons(verts, polys)

    def hit(self, origin, direction):
        loc, normal, _, _ = self.bvh.ray_cast(Vector(origin), Vector(direction).normalized(), 100)
        return loc, normal


def _point_in_poly(pts, poly):
    poly = np.asarray(poly)
    x, y = pts[:, 0], pts[:, 1]
    inside = np.zeros(len(pts), bool)
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, yi = poly[i]
        xj, yj = poly[j]
        cond = ((yi > y) != (yj > y)) & (x < (xj - xi) * (y - yi) / (yj - yi + 1e-12) + xi)
        inside ^= cond
        j = i
    return inside


def _densify(outline, res):
    pts = []
    for (a0, b0), (a1, b1) in zip(outline, outline[1:] + outline[:1]):
        n = max(1, int(math.hypot(a1 - a0, b1 - b0) / res))
        pts += [(a0 + (a1 - a0) * k / n, b0 + (b1 - b0) * k / n) for k in range(n)]
    return pts


def patch(name, surf, outline, axis, mat, offset=0.02, res=0.08):
    """Conforming decal-like mesh with an exact outline: triangulate the 2D polygon, refine it,
    then ray-cast every vertex onto the body and push it out along the surface normal."""
    outline = [tuple(map(float, p)) for p in outline]
    bm = bmesh.new()
    vs = [bm.verts.new((a, b, 0)) for a, b in _densify(outline, res)]
    face = bm.faces.new(vs)
    bmesh.ops.triangulate(bm, faces=[face])
    for _ in range(8):
        long_edges = [e for e in bm.edges if e.calc_length() > res * 1.6]
        if not long_edges:
            break
        bmesh.ops.subdivide_edges(bm, edges=long_edges, cuts=1, use_grid_fill=False)
        bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 3])
    missing = []
    for v in bm.verts:
        a, b = v.co.x, v.co.y
        if axis == "front":
            o, d = (a, L, b), (0, -1, 0)
        elif axis == "rear":
            o, d = (a, -L, b), (0, 1, 0)
        elif axis == "right":
            o, d = (6, y_of(a), b), (-1, 0, 0)
        else:
            o, d = (-6, y_of(a), b), (1, 0, 0)
        loc, n = surf.hit(o, d)
        if loc is not None and n.dot(Vector(d)) > 0:
            n = -n  # open surfaces may have inward normals; always offset towards the viewer
        # only accept surfaces that face the projection direction (skip grazing roof hits etc.)
        if loc is None or n.dot(Vector(d)) > -0.3:
            missing.append(v)
        else:
            v.co = loc + n * offset
    if missing:
        bmesh.ops.delete(bm, geom=missing, context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = obj_from_bmesh(name, bm, mat)
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def bar(name, p0, p1, width, thick, mat, bevel=0.015):
    """Box spanning from p0 to p1 (centre line), e.g. a wheel spoke."""
    p0, p1 = Vector(p0), Vector(p1)
    d = p1 - p0
    ob = rounded_box(name, (thick, width, d.length), (p0 + p1) / 2, mat, bevel=bevel)
    ob.rotation_euler = d.to_track_quat("Z", "X").to_euler()
    return ob


# --- build -----------------------------------------------------------------------------------------
def build():
    clear_scene()
    M = {
        "Paint": material("Paint", (0.006, 0.006, 0.008), rough=0.18, coat=1.0),
        "Glass": material("Glass", (0.07, 0.075, 0.085), rough=0.02, metal=0.65),
        "Trim": material("Trim", (0.02, 0.02, 0.021), rough=0.6),
        "Chrome": material("Chrome", (0.18, 0.18, 0.2), rough=0.18, metal=1.0),
        "Gloss": material("Gloss", (0.01, 0.01, 0.011), rough=0.08),
        "Tyre": material("Tyre", (0.02, 0.02, 0.02), rough=0.85),
        "Rim": material("Rim", (0.26, 0.21, 0.16), rough=0.32, metal=1.0),
        "Brake": material("Brake", (0.35, 0.35, 0.36), rough=0.4, metal=1.0),
        "Lens": material("Lens", (0.16, 0.17, 0.19), rough=0.04, metal=0.6),
        "LED": material("LED", (1, 1, 1), emit=(0.85, 0.92, 1.0), emit_strength=12),
        "Tail": material("Tail", (0.25, 0.0, 0.01), rough=0.08, emit=(1.0, 0.02, 0.03), emit_strength=0.6),
        "TailLED": material("TailLED", (1, 0.1, 0.1), emit=(1.0, 0.02, 0.03), emit_strength=14),
    }
    plate_img = make_plate_image()
    M["Plate"] = material("Plate", (1, 1, 1), rough=0.4, image=plate_img)

    # lower body: loft of cross-sections
    us = np.concatenate([[0.0, 0.06, 0.16, 0.3, 0.5, 0.8], np.arange(1.2, 15.0, 0.45), [15.2, 15.5, 15.75, 15.95, 16.1, 16.2]])
    rings = []
    for u in us:
        top, mh, dh, by = interp(u, TOP_Y), interp(u, MAX_HALF), interp(u, DECK_HALF), interp(u, BOT_Y)
        sh_y = top - 0.32
        y = y_of(u)
        half = [(0, by), (mh - 0.45, by), (mh - 0.1, 0.95), (mh, 1.75), (mh - 0.04, sh_y), (dh, top - 0.06),
                (dh * 0.5, top - 0.01)]
        ring = [(x, y, z) for x, z in half] + [(0, y, top + 0.02)] + [(-x, y, z) for x, z in reversed(half[1:])]
        rings.append(ring)
    body = loft("Paint_Body", rings, M["Paint"])
    add_modifier_subsurf(body, 2)
    apply_all(body)

    # wheel openings: boolean-cut cylinders
    for u in (FRONT_AXLE_U, REAR_AXLE_U):
        cut = cylinder("cut", 1.36, 10, (0, y_of(u), WHEEL_R + 0.02), M["Trim"], axis="X", verts=64)
        mod = body.modifiers.new("Arch", "BOOLEAN")
        mod.operation = "DIFFERENCE"
        mod.object = cut
        mod.solver = "EXACT"
        apply_all(body)
        bpy.data.objects.remove(cut)
    shade_smooth(body, 50)

    # wheel-arch liners (dark half-tubes inside the openings)
    for u in (FRONT_AXLE_U, REAR_AXLE_U):
        for s in (1, -1):
            liner = cylinder(f"Trim_Liner_{u:.0f}_{s}", 1.35, 0.95, (s * 2.75, y_of(u), WHEEL_R + 0.02), M["Trim"], axis="X")
            # keep only the upper part
            bm = bmesh.new()
            bm.from_mesh(liner.data)
            bmesh.ops.delete(bm, geom=[v for v in bm.verts if (liner.matrix_world @ v.co).z < WHEEL_R - 0.4], context="VERTS")
            bm.to_mesh(liner.data)
            bm.free()

    # greenhouse
    cus = np.concatenate([[CAB_U0, 5.55, 5.75], np.arange(6.0, 14.7, 0.22), [14.8, 14.95, CAB_U1]])
    crings = []
    for u in cus:
        roof, bh, th = interp(u, ROOF_Y), interp(u, CAB_BASE_HALF), interp(u, CAB_TOP_HALF)
        base = interp(u, TOP_Y) - 0.04
        y = y_of(u)
        h = roof - base
        mid_h = (bh * 0.55 + th * 0.45) + 0.03
        half = [(bh, base)]
        for t in (0.2, 0.4, 0.6, 0.8):
            half.append((bh + (th - bh) * t ** 1.3 + 0.04 * math.sin(math.pi * t), base + (roof - 0.13 - base) * t))
        half += [(th, roof - 0.13), (th * 0.75, roof - 0.06), (th * 0.4, roof - 0.015)]
        crings.append([(x, y, z) for x, z in half] + [(0, y, roof)] + [(-x, y, z) for x, z in reversed(half)])
    cab = loft("Paint_Cabin", crings, M["Paint"], cap_start=False, cap_end=False, closed=False)
    add_modifier_subsurf(cab, 2)
    apply_all(cab)
    shade_smooth(cab, 50)

    windows(Surface([cab]), M)
    surf = Surface([body, cab])
    details(surf, M)
    wheels(M)
    return M


def windows(surf, M):
    """Glass panes with black frames, projected onto the cabin with exact outlines."""
    base = interp(CAB_U0 + 1.0, TOP_Y)
    # windshield (front projection, x/z), A-pillars left as paint
    ws = [(-2.42, base + 0.06), (2.42, base + 0.06), (1.98, 4.8), (-1.98, 4.8)]
    patch("Trim_WindshieldFrame", surf, ws, "front", M["Trim"], offset=0.008, res=0.14)
    patch("Glass_Windshield", surf, inset(ws, 0.06), "front", M["Glass"], offset=0.016, res=0.14)
    # rear window (rear projection)
    rw = [(-1.72, 3.7), (1.72, 3.7), (1.48, 4.6), (-1.48, 4.6)]
    patch("Trim_RearWindowFrame", surf, rw, "rear", M["Trim"], offset=0.008, res=0.14)
    patch("Glass_RearWindow", surf, inset(rw, 0.06), "rear", M["Glass"], offset=0.016, res=0.14)
    # side windows (side projection, u/z) following the roof line, with a rear kink
    bottom = base + 0.1
    top = [(u, interp(u, ROOF_Y) - 0.22 - max(0.0, u - 11.4) * 0.14) for u in np.arange(DLO_U1 - 0.35, DLO_U0 + 0.6, -0.25)]
    dlo = ([(DLO_U0, bottom + 0.02), (KINK_U, bottom), (DLO_U1, bottom + (DLO_U1 - KINK_U) * 0.75)]
           + [(u, max(z, bottom + 0.15)) for u, z in top])
    for side in ("right", "left"):
        sg = 1 if side == "right" else -1
        patch(f"Trim_DLO{sg}", surf, dlo, side, M["Trim"], offset=0.008, res=0.14)
        front_pane = [(u, z) for u, z in inset(dlo, 0.06) if u < B_PILLAR_U - 0.08]
        rear_pane = [(u, z) for u, z in inset(dlo, 0.06) if u > B_PILLAR_U + 0.08]
        for name, pane in (("Front", front_pane), ("Rear", rear_pane)):
            pane = clip_u(inset(dlo, 0.06), *( (DLO_U0, B_PILLAR_U - 0.08) if name == "Front" else (B_PILLAR_U + 0.08, DLO_U1)))
            patch(f"Glass_Side{name}{sg}", surf, pane, side, M["Glass"], offset=0.016, res=0.14)


def inset(poly, d):
    """Shrink a polygon towards its centroid by roughly d (good enough for convex-ish outlines)."""
    P = np.asarray(poly, float)
    c = P.mean(0)
    out = []
    for p in P:
        v = p - c
        n = np.linalg.norm(v)
        out.append(tuple(p - v / n * d) if n > d else tuple(p))
    return out


def clip_u(poly, u0, u1):
    """Clip polygon (u, z) to u0 <= u <= u1 (Sutherland-Hodgman on two vertical lines)."""
    def clip(pts, keep, x):
        res = []
        for i in range(len(pts)):
            a, b = pts[i], pts[(i + 1) % len(pts)]
            ina, inb = keep(a[0]), keep(b[0])
            if ina:
                res.append(a)
            if ina != inb:
                t = (x - a[0]) / (b[0] - a[0])
                res.append((x, a[1] + t * (b[1] - a[1])))
        return res
    pts = clip(list(poly), lambda u: u >= u0, u0)
    return clip(pts, lambda u: u <= u1, u1)


def assign_cabin_materials(cab):
    """Glass where windows are, paint for roof and pillars, trim for B-pillar/DLO edges."""
    mw = cab.matrix_world
    for p in cab.data.polygons:
        c = mw @ p.center
        n = p.normal
        u = L / 2 - c.y
        roof = interp(u, ROOF_Y)
        base = interp(u, TOP_Y)
        th = interp(u, CAB_TOP_HALF)
        side = abs(n.x) > 0.55
        mat = 0  # glass
        if not side:
            if ROOF_U0 <= u <= ROOF_U1:
                mat = 1  # roof
            elif u < ROOF_U0:  # windshield with A-pillars
                if abs(c.x) > th + (interp(u, CAB_BASE_HALF) - th) * max(0, (roof - c.z)) / max(roof - base, 1e-3) - 0.32:
                    mat = 1
            else:  # rear window, wide C-pillars
                if abs(c.x) > 1.75 or u > 14.75:
                    mat = 1
        else:
            top_line = roof - 0.2
            bottom = base + 0.1 + max(0.0, u - KINK_U) * 0.75   # Hofmeister-style kink at the rear
            if not (DLO_U0 < u < DLO_U1 and bottom < c.z < top_line):
                mat = 1
            if abs(u - B_PILLAR_U) < 0.07 and c.z < top_line:
                mat = 2
            if abs(c.z - bottom) < 0.05 and DLO_U0 - 0.2 < u < DLO_U1 + 0.05:
                mat = 2  # window sill trim
            if abs(c.z - top_line) < 0.045 and DLO_U0 < u < DLO_U1 - 0.3:
                mat = 2  # window top trim
        p.material_index = mat


def details(surf, M):
    # kidney grilles: frame, dark mesh and vertical slats
    for s in (1, -1):
        cx = s * 0.56
        frame = [(cx - 0.47, 1.22), (cx + 0.47, 1.22), (cx + 0.47, 2.32), (cx - 0.47, 2.32)]
        patch(f"Gloss_KidneyFrame{s}", surf, rounded(frame, 0.16), "front", M["Gloss"], offset=0.035)
        inner = [(cx - 0.38, 1.3), (cx + 0.38, 1.3), (cx + 0.38, 2.24), (cx - 0.38, 2.24)]
        patch(f"Trim_KidneyMesh{s}", surf, rounded(inner, 0.12), "front", M["Trim"], offset=0.05)
        for k in range(5):
            x = cx - 0.3 + k * 0.15
            patch(f"Chrome_Slat{s}_{k}", surf, [(x - 0.02, 1.34), (x + 0.02, 1.34), (x + 0.02, 2.2), (x - 0.02, 2.2)],
                  "front", M["Chrome"], offset=0.07, res=0.02)
    for s in (1, -1):
        def f(pts):
            return [(s * x, z) for x, z in pts]
        # slim angular headlights with LED eyebrow and outer hook
        patch(f"Lens_Headlight{s}", surf, f([(1.18, 1.98), (1.12, 2.2), (2.7, 2.42), (3.2, 2.36), (3.08, 2.02)]),
              "front", M["Lens"], offset=0.03)
        patch(f"LED_Brow{s}", surf, f([(1.2, 2.14), (1.18, 2.2), (2.72, 2.38), (2.76, 2.31)]), "front", M["LED"], offset=0.05, res=0.02)
        patch(f"LED_Lower{s}", surf, f([(1.28, 2.02), (1.3, 2.07), (2.15, 2.12), (2.16, 2.07)]), "front", M["LED"], offset=0.05, res=0.02)
        patch(f"LED_Hook{s}", surf, f([(2.7, 2.07), (2.76, 2.07), (2.8, 2.36), (2.73, 2.36)]), "front", M["LED"], offset=0.05, res=0.02)
        patch(f"Chrome_Reflector{s}", surf, f([(1.75, 2.06), (2.45, 2.12), (2.45, 2.24), (1.75, 2.2)]), "front", M["Chrome"], offset=0.045)
        # large outer intakes and side "air curtain"
        patch(f"Trim_Intake{s}", surf, f([(1.72, 0.78), (2.98, 0.78), (3.06, 1.78), (2.62, 1.82)]), "front", M["Trim"], offset=0.03)
        patch(f"Chrome_IntakeEdge{s}", surf, f([(1.66, 0.78), (1.74, 0.78), (2.64, 1.84), (2.56, 1.84)]), "front", M["Chrome"], offset=0.04, res=0.02)
        # mirrors
        rounded_box(f"Paint_Mirror{s}", (0.52, 0.6, 0.36), (s * 3.36, y_of(6.15), 3.62), M["Paint"], bevel=0.12, rot=(0, 0, math.radians(-s * 8)))
        bar(f"Trim_MirrorArm{s}", (s * 2.8, y_of(6.2), 3.38), (s * 3.2, y_of(6.15), 3.55), 0.22, 0.09, M["Trim"])
        # side: door shut lines, handle
        side = "right" if s > 0 else "left"
        patch(f"Trim_DoorFront{s}", surf, [(5.02, 0.95), (5.07, 0.95), (5.07, 3.12), (5.02, 3.12)], side, M["Trim"], offset=0.01, res=0.02)
        patch(f"Trim_DoorRear{s}", surf, [(10.9, 0.95), (10.95, 0.95), (10.95, 3.1), (10.9, 3.1)], side, M["Trim"], offset=0.01, res=0.02)
        patch(f"Trim_Handle{s}", surf, [(9.75, 2.7), (10.35, 2.72), (10.35, 2.84), (9.75, 2.82)], side, M["Trim"], offset=0.03, res=0.02)
        patch(f"Trim_SideSkirt{s}", surf, [(4.2, 0.55), (11.2, 0.55), (11.2, 0.82), (4.2, 0.82)], side, M["Trim"], offset=0.015)
        # rear: L-shaped tail lights
        patch(f"Tail_Light{s}", surf, f([(1.35, 2.62), (2.95, 2.78), (3.12, 2.62), (3.05, 2.36), (2.75, 2.4), (1.4, 2.48)]),
              "rear", M["Tail"], offset=0.03)
        patch(f"TailLED_Bar{s}", surf, f([(1.45, 2.56), (2.85, 2.68), (2.86, 2.62), (1.45, 2.51)]), "rear", M["TailLED"], offset=0.05, res=0.02)
        patch(f"TailLED_Hook{s}", surf, f([(2.82, 2.42), (2.88, 2.42), (2.88, 2.68), (2.82, 2.68)]), "rear", M["TailLED"], offset=0.05, res=0.02)
        cylinder(f"Chrome_Exhaust{s}", 0.2, 0.5, (s * 2.05, y_of(16.05), 0.72), M["Chrome"], axis="Y", bevel=0.03)
    patch("Trim_LowerIntake", surf, [(-1.25, 0.62), (1.25, 0.62), (1.12, 1.08), (-1.12, 1.08)], "front", M["Trim"], offset=0.03)
    patch("Plate_Front", surf, [(-0.95, 1.0), (0.95, 1.0), (0.95, 1.42), (-0.95, 1.42)], "front", M["Plate"], offset=0.09, res=0.12)
    patch("Plate_Rear", surf, [(-0.95, 1.22), (0.95, 1.22), (0.95, 1.64), (-0.95, 1.64)], "rear", M["Plate"], offset=0.05, res=0.12)
    patch("Trim_Diffuser", surf, [(-2.55, 0.55), (2.55, 0.55), (2.45, 1.02), (-2.45, 1.02)], "rear", M["Trim"], offset=0.03)
    rounded_box("Trim_Splitter", (5.2, 0.3, 0.06), (0, y_of(0.32), 0.49), M["Trim"], bevel=0.025)
    fix_plate_uvs()


def rounded(rect, r, seg=4):
    (x0, z0), (x1, _), (_, z1) = rect[0], rect[1], rect[2]
    pts = []
    for cx, cz, a0 in [(x1 - r, z0 + r, -90), (x1 - r, z1 - r, 0), (x0 + r, z1 - r, 90), (x0 + r, z0 + r, 180)]:
        for k in range(seg + 1):
            a = math.radians(a0 + 90 * k / seg)
            pts.append((cx + r * math.cos(a), cz + r * math.sin(a)))
    return pts


def make_plate_image():
    from PIL import Image, ImageDraw, ImageFont
    W, H = 520, 115
    im = Image.new("RGB", (W, H), (236, 236, 236))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, W - 1, H - 1], outline=(20, 20, 20), width=6)
    d.rectangle([6, 6, 62, H - 7], fill=(0, 60, 160))
    d.text((W / 2 + 28, H / 2 + 2), PLATE_TEXT, font=ImageFont.truetype("/usr/share/fonts/opentype/inter/Inter-Bold.otf", 76),
           fill=(15, 15, 15), anchor="mm")
    path = os.path.join(HERE, "plate.png")
    im.save(path)
    img = bpy.data.images.load(path)
    img.pack()
    return img


def fix_plate_uvs():
    """Planar UVs for the plates so the text texture maps left-to-right as seen from outside."""
    for name, flip in (("Plate_Front", True), ("Plate_Rear", False)):
        ob = bpy.data.objects[name]
        me = ob.data
        uv = me.uv_layers.new(name="UVMap")
        xs = [v.co.x for v in me.vertices]
        zs = [v.co.z for v in me.vertices]
        x0, x1, z0, z1 = min(xs), max(xs), min(zs), max(zs)
        for loop in me.loops:
            v = me.vertices[loop.vertex_index].co
            uu = (v.x - x0) / (x1 - x0)
            uv.data[loop.index].uv = ((1 - uu) if flip else uu, (v.z - z0) / (z1 - z0))


def wheels(M):
    for u in (FRONT_AXLE_U, REAR_AXLE_U):
        for s in (1, -1):
            tag = f"{'F' if u < 8 else 'R'}{'R' if s > 0 else 'L'}"
            cx, cy, cz = s * TRACK_HALF, y_of(u), WHEEL_R
            cylinder(f"Tyre_{tag}", WHEEL_R, TYRE_W, (cx, cy, cz), M["Tyre"], axis="X", verts=64, bevel=0.16)
            face = cx + s * (TYRE_W / 2 - 0.02)
            cylinder(f"Rim_Lip_{tag}", RIM_R, 0.08, (face, cy, cz), M["Rim"], axis="X", verts=64, bevel=0.02)
            cylinder(f"Trim_Barrel_{tag}", RIM_R - 0.07, 0.1, (face + s * 0.012, cy, cz), M["Trim"], axis="X", verts=64)
            cylinder(f"Brake_Disc_{tag}", 0.62, 0.06, (face - s * 0.25, cy, cz), M["Brake"], axis="X", verts=48)
            rounded_box(f"Trim_Caliper_{tag}", (0.18, 0.5, 0.32), (face - s * 0.16, cy - 0.35, cz + 0.42), M["Trim"], bevel=0.05)
            # 5 double spokes (Y-spokes) from hub to lip
            for k in range(5):
                for off in (-11, 11):
                    a0 = math.radians(k * 72)
                    a1 = math.radians(k * 72 + off)
                    r0, r1 = 0.18, RIM_R - 0.04
                    x = face + s * 0.035
                    bar(f"Rim_Spoke_{tag}_{k}{off}", (x, cy + r0 * math.sin(a0), cz + r0 * math.cos(a0)),
                        (x, cy + r1 * math.sin(a1), cz + r1 * math.cos(a1)), 0.13, 0.08, M["Rim"])
            cylinder(f"Rim_Hub_{tag}", 0.24, 0.1, (face + s * 0.04, cy, cz), M["Rim"], axis="X", verts=32, bevel=0.03)
            cylinder(f"Trim_Cap_{tag}", 0.12, 0.04, (face + s * 0.09, cy, cz), M["Trim"], axis="X", verts=32)


# --- export & render ------------------------------------------------------------------------------
def export_glb(path, max_tris=19000):
    """Join parts into one mesh per material (and per wheel), keep each under Roblox's
    20k-triangle limit, and export a GLB for Studio's 3D Importer (Scale Unit: Studs)."""
    meshes = [o for o in bpy.data.objects if o.type == "MESH" and not o.name.startswith("_")]
    for ob in meshes:
        bpy.context.view_layer.objects.active = ob
        for m in list(ob.modifiers):
            bpy.ops.object.modifier_apply(modifier=m.name)
    groups = {}
    for ob in meshes:
        mat = ob.data.materials[0].name if ob.data.materials else "Paint"
        wheel = next((t for t in ("FL", "FR", "RL", "RR") if ob.name.endswith("_" + t) or f"_{t}_" in ob.name), None)
        if ob.name.startswith(("Tyre", "Rim", "Brake")) or (wheel and ob.name.startswith("Trim_")):
            key = f"Wheel{wheel}_{mat}"
        elif ob.name.startswith("Paint_Cabin"):
            key = "Cabin_Paint"
        elif ob.name.startswith("Trim_Liner"):
            key = "Liners_Trim"
        elif ob.name.startswith(("Trim_DLO", "Trim_Windshield", "Trim_RearWindow")):
            key = "Windows_Trim"
        else:
            key = mat
        groups.setdefault(key, []).append(ob)
    report = []
    for key, obs in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for o in obs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = obs[0]
        if len(obs) > 1:
            bpy.ops.object.join()
        ob = bpy.context.view_layer.objects.active
        ob.name = key
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
        if tris > max_tris:
            d = ob.modifiers.new("Decimate", "DECIMATE")
            d.ratio = max_tris / tris * 0.97
            bpy.ops.object.modifier_apply(modifier=d.name)
            tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
        report.append((tris, key))
    bpy.ops.object.select_all(action="DESELECT")
    for o in bpy.data.objects:
        if o.type == "MESH" and not o.name.startswith("_"):
            o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_yup=True, export_image_format="AUTO")
    report.sort(reverse=True)
    print("EXPORT", len(report), "mesh parts; largest:", report[:4], "total tris:", sum(t for t, _ in report))


def setup_render(env="studio"):
    bpy.ops.preferences.addon_enable(module="cycles")
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 24 if "--fast" in sys.argv else 64
    sc.cycles.use_denoising = True
    sc.render.film_transparent = True
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "AgX - Medium High Contrast"
    world = bpy.data.worlds.new("World")
    sc.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Strength"].default_value = 0.35 if env == "studio" else 0.15
    bg.inputs["Color"].default_value = (0.6, 0.62, 0.68, 1) if env == "studio" else (0.25, 0.05, 0.35, 1)
    # ground that only catches shadows
    bpy.ops.mesh.primitive_plane_add(size=80, location=(0, 0, 0))
    ground = bpy.context.active_object
    ground.name = "_Ground"
    ground.is_shadow_catcher = True
    # softbox lights for the glossy reflections
    lights = [((0, 0, 14), (0, 0, 0), 16, 12, 900, (1, 1, 1)),
              ((-9, -2, 6), (0, math.radians(-60), 0), 10, 4, 500, (1, 1, 1)),
              ((9, 6, 6), (0, math.radians(60), 0), 10, 4, 350, (1, 1, 1))]
    if env == "neon":
        lights = [((0, 0, 14), (0, 0, 0), 16, 12, 500, (0.7, 0.35, 1.0)),
                  ((-10, 4, 5), (math.radians(10), math.radians(-65), 0), 12, 3, 900, (0.2, 0.85, 1.0)),
                  ((10, 2, 5), (0, math.radians(65), 0), 12, 3, 700, (1.0, 0.25, 0.7)),
                  ((0, 16, 4), (math.radians(-75), 0, 0), 10, 3, 400, (1.0, 0.35, 0.75))]
    for i, (loc, rot, sx, sy, power, color) in enumerate(lights):
        ld = bpy.data.lights.new(f"Soft{i}", "AREA")
        ld.shape = "RECTANGLE"
        ld.size, ld.size_y = sx, sy
        ld.energy = power
        ld.color = color
        lo = bpy.data.objects.new(f"_Soft{i}", ld)
        lo.location = loc
        lo.rotation_euler = rot
        bpy.context.collection.objects.link(lo)
        if loc[2] < 10:
            lo.rotation_euler = (0, 0, 0)
            direction = Vector((0, 0, 1.5)) - Vector(loc)
            lo.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


VIEWS = {  # camera location, look-at, focal length (mm)
    "front34": ((-13.5, 20.5, 4.4), (0.3, 0.3, 1.9), 50),
    "side": ((-28, 0, 2.6), (0, 0, 2.2), 50),
    "rear34": ((12, -18, 5.0), (0, 0, 2.0), 50),
    "photo": ((-6.8, 15.6, 3.6), (1.3, 2.2, 1.9), 30),
    "icon": ((-9.5, 18.5, 3.5), (0.9, 1.0, 2.2), 42),
}


def render(view, out, w=1600, h=1200):
    sc = bpy.context.scene
    loc, look, lens = VIEWS[view]
    cam_data = bpy.data.cameras.get("Cam") or bpy.data.cameras.new("Cam")
    cam_data.lens = lens
    cam = bpy.data.objects.get("_Cam") or bpy.data.objects.new("_Cam", cam_data)
    if cam.name not in bpy.context.collection.objects:
        bpy.context.collection.objects.link(cam)
    cam.location = loc
    cam.rotation_euler = (Vector(look) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    sc.camera = cam
    sc.render.resolution_x, sc.render.resolution_y = w, h
    sc.render.filepath = out
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    args = sys.argv[1:]
    build()
    if "--export" in args:
        export_glb(args[args.index("--export") + 1])
    if "--render" in args:
        out_dir = args[args.index("--render") + 1]
        env = args[args.index("--env") + 1] if "--env" in args else "studio"
        views = args[args.index("--views") + 1].split(",") if "--views" in args else ["front34", "side", "rear34", "photo"]
        setup_render(env)
        for v in views:
            sq = v == "icon"
            size = (1600, 1600) if sq else ((1200, 1600) if v == "photo" else (1600, 1200))
            if "--fast" in args:
                size = (size[0] * 3 // 4, size[1] * 3 // 4)
            render(v, os.path.join(out_dir, f"hd_{v}.png"), *size)
