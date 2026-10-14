#!/usr/bin/env python3
"""Black coupé (modelled after a 2-door sports coupé) built from Roblox primitive parts.

One geometry definition feeds two outputs:
  * BlackCoupe.model.json  -> Rojo model file (build to .rbxm / insert into Studio)
  * render.py              -> preview images rendered from the very same parts

Coordinates are Roblox studs: X = car's right, Y = up, -Z = front of the car.
Scale: 1 stud ~ 0.28 m (length 16.2, width 6.6, height 5.0 studs).
"""

import json
import math
from pathlib import Path

import numpy as np

# Roblox WedgePart convention assumed here: slope rises from the front (-Z, low)
# to the back (+Z, high). If Studio shows the slopes mirrored, flip this flag.
WEDGE_HIGH_AT_PLUS_Z = True

PLATE_TEXT = "RB 2026"

# --- materials ----------------------------------------------------------------------
PAINT = dict(color=(14, 14, 17), material="SmoothPlastic", reflectance=0.15)
GLASS = dict(color=(10, 12, 16), material="Glass", reflectance=0.2, transparency=0.2)
MATTE = dict(color=(10, 10, 11), material="SmoothPlastic", reflectance=0.0)
TRIM = dict(color=(38, 38, 42), material="SmoothPlastic", reflectance=0.15)
RUBBER = dict(color=(24, 24, 24), material="Rubber", reflectance=0.0)
RIM = dict(color=(84, 74, 64), material="Metal", reflectance=0.25)
RIM_DARK = dict(color=(18, 18, 19), material="SmoothPlastic", reflectance=0.0)
LED = dict(color=(235, 245, 255), material="Neon", reflectance=0.0)
TAIL = dict(color=(220, 20, 30), material="Neon", reflectance=0.0)
TAIL_GLASS = dict(color=(70, 8, 12), material="SmoothPlastic", reflectance=0.3)
PLATE = dict(color=(236, 236, 236), material="SmoothPlastic", reflectance=0.05)
PLATE_BLUE = dict(color=(0, 60, 160), material="SmoothPlastic", reflectance=0.05)
EXHAUST = dict(color=(60, 60, 64), material="Metal", reflectance=0.4)

parts = []


def rot(rx=0.0, ry=0.0, rz=0.0):
    """Rotation matrix equal to Roblox CFrame.Angles(rx, ry, rz) in degrees (Rx*Ry*Rz)."""
    a, b, c = (math.radians(v) for v in (rx, ry, rz))
    Rx = np.array([[1, 0, 0], [0, math.cos(a), -math.sin(a)], [0, math.sin(a), math.cos(a)]])
    Ry = np.array([[math.cos(b), 0, math.sin(b)], [0, 1, 0], [-math.sin(b), 0, math.cos(b)]])
    Rz = np.array([[math.cos(c), -math.sin(c), 0], [math.sin(c), math.cos(c), 0], [0, 0, 1]])
    return Rx @ Ry @ Rz


def add(name, size, pos, mat, cls="Part", shape="Block", r=None, mirror=False, **extra):
    """Add a part; with mirror=True also add its copy on the other side (x -> -x)."""
    R = np.eye(3) if r is None else r
    parts.append(dict(name=name, cls=cls, shape=shape, size=tuple(size), pos=tuple(pos), rot=R, **mat, **extra))
    if mirror:
        M = np.diag([-1, 1, 1])
        # mirror the orientation: keep a proper rotation by also flipping local X
        Rm = M @ R @ M
        parts.append(dict(name=name.replace("Right", "Left").replace("_R", "_L"), cls=cls, shape=shape,
                          size=tuple(size), pos=(-pos[0], pos[1], pos[2]), rot=Rm, **mat, **extra))


def box(name, x0, x1, y0, y1, z0, z1, mat, mirror=False, **extra):
    add(name, (x1 - x0, y1 - y0, z1 - z0), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), mat, mirror=mirror, **extra)


def wedge(name, size, pos, mat, rising_to_front=False, r=None, mirror=False):
    """Wedge in the YZ profile. Default: low at front (-Z), high at back (+Z)."""
    R = np.eye(3) if r is None else r
    flip = rising_to_front == WEDGE_HIGH_AT_PLUS_Z
    if flip:
        R = R @ rot(ry=180)
    add(name, size, pos, mat, cls="WedgePart", r=R, mirror=mirror)


# --- dimensions -------------------------------------------------------------------
HW = 3.3            # half width of the body
ZF, ZR = -8.1, 8.1  # front / rear ends
AXLE_F, AXLE_R = -5.1, 4.7
WR = 1.22           # wheel radius
WX = 2.82           # wheel centre x
ARCH = 1.34         # half length of wheel openings
BOTTOM, SILL = 0.55, 2.65
BELT = 3.35         # beltline / window bottom
ROOF = 5.0

# --- lower body ---------------------------------------------------------------------
box("Core", -2.35, 2.35, BOTTOM, SILL, -7.9, 7.9, PAINT)
for z0, z1, n in [(-7.9, AXLE_F - ARCH, "FrontQuarter"), (AXLE_F + ARCH, AXLE_R - ARCH, "Door"),
                  (AXLE_R + ARCH, 7.9, "RearQuarter")]:
    box(f"{n}_R", 2.35, HW, 1.55, SILL, z0, z1, PAINT, mirror=True)
    box(f"{n}Lower_R", 2.35, HW - 0.08, BOTTOM, 1.55, z0, z1, PAINT, mirror=True)
for zc, n in [(AXLE_F, "FrontArch"), (AXLE_R, "RearArch")]:
    box(f"{n}_R", 2.35, HW, 2.47, SILL, zc - ARCH, zc + ARCH, PAINT, mirror=True)
    box(f"{n}Liner_R", 2.33, 2.37, BOTTOM, 2.47, zc - ARCH, zc + ARCH, MATTE, mirror=True)
    # flared arch lip
    box(f"{n}Lip_R", HW - 0.05, HW + 0.04, 2.38, 2.5, zc - ARCH, zc + ARCH, PAINT, mirror=True)
    # round off the upper corners of the wheel opening
    wedge(f"{n}CornerFront_R", (HW - 2.35, 0.5, 0.42), ((HW + 2.35) / 2, 2.13, zc - ARCH + 0.21), PAINT, r=rot(rx=180), mirror=True)
    wedge(f"{n}CornerRear_R", (HW - 2.35, 0.5, 0.42), ((HW + 2.35) / 2, 2.13, zc + ARCH - 0.21), PAINT, r=rot(rz=180), mirror=True)
box("SideSkirt_R", HW - 0.1, HW + 0.03, BOTTOM - 0.05, 0.85, AXLE_F + ARCH, AXLE_R - ARCH, MATTE, mirror=True)

# door shut lines + handle
for z, n in [(-1.95, "DoorLineFront_R"), (2.95, "DoorLineRear_R")]:
    box(n, HW, HW + 0.02, 0.9, SILL - 0.03, z - 0.02, z + 0.02, MATTE, mirror=True)
box("DoorHandle_R", HW, HW + 0.05, 2.35, 2.5, 2.1, 2.65, dict(PAINT, color=(30, 30, 34)), mirror=True)

# --- upper body, hood, trunk -------------------------------------------------------
GH = 2.45  # half width of the greenhouse (cabin)
box("Shoulder", -3.2, 3.2, SILL, 3.05, -1.8, 6.6, PAINT)
box("ShoulderTop", -GH, GH, 3.05, BELT, -1.8, 6.6, PAINT)
# tumblehome: shoulder slopes inward from the body side up to the windows
wedge("ShoulderSlope_R", (8.4, BELT - 3.05, 3.2 - GH), ((3.2 + GH) / 2, (3.05 + BELT) / 2, 2.4), PAINT,
      r=rot(ry=-90), mirror=True)
box("HoodBase", -3.2, 3.2, SILL, 2.7, -7.6, -1.8, PAINT)
wedge("HoodSlope", (6.4, BELT - 2.7, 5.8), (0, (2.7 + BELT) / 2, -4.7), PAINT)   # rises toward windshield
wedge("NoseTop", (6.5, 0.32, 0.55), (0, 2.54, -7.85), PAINT)                    # rounded front edge
box("TrunkDeck", -3.15, 3.15, SILL, 3.3, 6.6, 7.95, PAINT)
wedge("TrunkSlope_R", (1.35, 3.3 - 3.05, 3.15 - GH), ((3.15 + GH) / 2, 3.175, 7.275), PAINT, r=rot(ry=-90), mirror=True)
box("TrunkTop", -GH, GH, 3.3, 3.42, 6.6, 7.95, PAINT)
box("Ducktail", -2.3, 2.3, 3.42, 3.55, 7.45, 7.95, PAINT)

# --- greenhouse -------------------------------------------------------------------
wedge("Windshield", (2 * GH, ROOF - 0.05 - BELT, 2.7), (0, (BELT + ROOF - 0.05) / 2, -0.45), GLASS)
box("Roof", -GH + 0.05, GH - 0.05, 4.75, ROOF, 0.9, 3.4, PAINT)
wedge("RearWindow", (2 * GH - 0.1, ROOF - 0.05 - BELT, 3.4), (0, (BELT + ROOF - 0.05) / 2, 5.1), GLASS, rising_to_front=True)
box("SideWindow_R", GH - 0.02, GH + 0.04, BELT, 4.75, 0.9, 3.4, GLASS, mirror=True)
wedge("SideWindowFront_R", (0.07, ROOF - 0.05 - BELT, 2.7), (GH + 0.01, (BELT + ROOF - 0.05) / 2, -0.45), GLASS, mirror=True)
wedge("SideWindowRear_R", (0.07, ROOF - 0.05 - BELT, 3.4), (GH + 0.01, (BELT + ROOF - 0.05) / 2, 5.1), GLASS, rising_to_front=True, mirror=True)
box("BPillar_R", GH - 0.01, GH + 0.06, BELT, 4.75, 2.95, 3.15, MATTE, mirror=True)
# A-pillars along the windshield edges, C-pillars along the rear window
a_len, a_ang = math.hypot(2.7, ROOF - 0.05 - BELT), math.degrees(math.atan2(ROOF - 0.05 - BELT, 2.7))
add("APillar_R", (0.16, 0.12, a_len), (GH - 0.04, (BELT + ROOF - 0.05) / 2 + 0.03, -0.45), PAINT, r=rot(rx=-a_ang), mirror=True)
c_len, c_ang = math.hypot(3.4, ROOF - 0.05 - BELT), math.degrees(math.atan2(ROOF - 0.05 - BELT, 3.4))
add("CPillar_R", (0.5, 0.12, c_len), (GH - 0.2, (BELT + ROOF - 0.05) / 2 + 0.03, 5.1), PAINT, r=rot(rx=c_ang), mirror=True)
box("WindowTrim_R", GH, GH + 0.06, BELT - 0.04, BELT + 0.04, -1.6, 6.4, MATTE, mirror=True)

# mirrors
box("Mirror_R", 3.0, 3.6, 3.4, 3.78, -1.45, -0.85, PAINT, mirror=True)
box("MirrorStalk_R", GH, 3.05, 3.4, 3.52, -1.3, -1.0, MATTE, mirror=True)

# --- front fascia -----------------------------------------------------------------
box("FrontFascia", -3.25, 3.25, BOTTOM, 2.38, -8.1, -7.9, PAINT)
fz = -8.1
# kidney grilles (frame + dark mesh + slats)
for cx, n in [(0.62, "Grille_R")]:
    box(f"{n}Frame", cx - 0.55, cx + 0.55, 1.3, 2.42, fz - 0.05, fz, TRIM, mirror=True)
    box(f"{n}Mesh", cx - 0.46, cx + 0.46, 1.38, 2.34, fz - 0.08, fz - 0.03, MATTE, mirror=True)
    for i, sx in enumerate((-0.3, -0.1, 0.1, 0.3)):
        box(f"{n}Slat{i}", cx + sx - 0.025, cx + sx + 0.025, 1.4, 2.32, fz - 0.1, fz - 0.06, TRIM, mirror=True)
# headlights: dark housing + LED "eyebrow" + wrap-around on the side
box("Headlight_R", 1.35, 3.1, 1.95, 2.36, fz - 0.05, fz, dict(TRIM, color=(22, 22, 26)), mirror=True)
box("HeadlightLED_R", 1.45, 2.85, 2.24, 2.31, fz - 0.08, fz - 0.03, LED, mirror=True)
box("HeadlightLEDHook_R", 2.78, 2.86, 2.0, 2.31, fz - 0.08, fz - 0.03, LED, mirror=True)
box("HeadlightLens_R", 1.6, 2.6, 2.02, 2.17, fz - 0.07, fz - 0.03, dict(TRIM, color=(60, 64, 72), reflectance=0.5), mirror=True)
box("HeadlightSide_R", HW, HW + 0.03, 1.95, 2.36, -7.95, -7.1, dict(TRIM, color=(22, 22, 26)), mirror=True)
box("HeadlightSideLED_R", HW + 0.02, HW + 0.05, 2.24, 2.31, -7.95, -7.3, LED, mirror=True)
# big triangular side intakes + lower intake
wedge("SideIntake_R", (0.06, 1.15, 1.3), (2.3, 1.38, fz - 0.04), MATTE, r=rot(ry=90), mirror=True)
box("SideIntakeTrim_R", 1.62, 1.7, 0.8, 1.35, fz - 0.06, fz, TRIM, mirror=True)
box("LowerIntake", -1.35, 1.35, 0.68, 1.12, fz - 0.05, fz, MATTE)
box("Splitter", -3.1, 3.1, 0.45, 0.56, -8.35, -7.9, MATTE)
box("SplitterCanard_R", 2.9, 3.25, 0.7, 0.78, -8.3, -8.05, MATTE, mirror=True)
# licence plate (text via SurfaceGui in Studio)
box("FrontPlate", -0.98, 0.98, 1.0, 1.42, fz - 0.14, fz - 0.1, PLATE, plate_text=PLATE_TEXT, plate_face="Front")
box("FrontPlateBand", -0.96, -0.8, 1.02, 1.4, fz - 0.15, fz - 0.13, PLATE_BLUE)

# --- rear -------------------------------------------------------------------------
box("RearFascia", -3.25, 3.25, BOTTOM, SILL, 7.9, 8.1, PAINT)
rz = 8.1
box("TailLight_R", 1.5, 3.12, 2.55, 3.05, rz, rz + 0.05, TAIL_GLASS, mirror=True)
box("TailLED_R", 1.65, 3.0, 2.85, 2.92, rz + 0.03, rz + 0.08, TAIL, mirror=True)
box("TailLEDHook_R", 2.92, 3.0, 2.62, 2.92, rz + 0.03, rz + 0.08, TAIL, mirror=True)
box("TailLightSide_R", HW, HW + 0.03, 2.55, 3.05, 7.3, 7.95, TAIL_GLASS, mirror=True)
box("Diffuser", -2.6, 2.6, 0.45, 0.95, 7.95, 8.3, MATTE)
for x in (-1.2, 1.2):
    add(f"Exhaust{'_R' if x > 0 else '_L'}", (0.4, 0.42, 0.42), (x, 0.72, 8.22), EXHAUST, shape="Cylinder", r=rot(ry=90))
box("RearPlate", -0.98, 0.98, 1.25, 1.67, rz + 0.06, rz + 0.1, PLATE, plate_text=PLATE_TEXT, plate_face="Back")

# --- wheels -------------------------------------------------------------------------
def wheel(tag, side, zc):
    sx = 1 if side > 0 else -1
    xc = sx * WX
    out = sx  # outward direction along X
    add(f"Tire{tag}", (0.95, 2 * WR, 2 * WR), (xc, WR, zc), RUBBER, shape="Cylinder")
    add(f"Rim{tag}", (0.06, 1.86, 1.86), (xc + out * 0.45, WR, zc), RIM, shape="Cylinder")
    add(f"RimDark{tag}", (0.04, 1.62, 1.62), (xc + out * 0.48, WR, zc), RIM_DARK, shape="Cylinder")
    for k in range(5):
        for off in (-7, 7):
            a = math.radians(k * 72 + off)
            r_mid = 0.43
            pos = (xc + out * 0.5, WR - r_mid * math.sin(a), zc + r_mid * math.cos(a))
            add(f"Spoke{tag}_{k}{'a' if off < 0 else 'b'}", (0.05, 0.12, 0.84), pos, RIM, r=rot(rx=math.degrees(a)))
    add(f"Hub{tag}", (0.08, 0.42, 0.42), (xc + out * 0.53, WR, zc), RIM, shape="Cylinder")
    add(f"HubCap{tag}", (0.04, 0.22, 0.22), (xc + out * 0.57, WR, zc), RIM_DARK, shape="Cylinder")


for side, n in [(1, "R"), (-1, "L")]:
    wheel(f"F{n}", side, AXLE_F)
    wheel(f"R{n}", side, AXLE_R)


# --- export -------------------------------------------------------------------------
def to_rojo():
    children = []
    for p in parts:
        props = {
            "Anchored": True,
            "Size": list(p["size"]),
            "CFrame": {"CFrame": {"position": list(p["pos"]), "orientation": [list(map(float, row)) for row in p["rot"]]}},
            "Color": [c / 255 for c in p["color"]],
            "Material": p["material"],
            "TopSurface": "Smooth",
            "BottomSurface": "Smooth",
        }
        if p.get("reflectance"):
            props["Reflectance"] = p["reflectance"]
        if p.get("transparency"):
            props["Transparency"] = p["transparency"]
        if p["shape"] != "Block":
            props["Shape"] = p["shape"]
        child = {"name": p["name"], "className": p["cls"], "properties": props}
        if p.get("plate_text"):
            child["children"] = [{
                "name": "PlateGui", "className": "SurfaceGui",
                "properties": {"Face": p["plate_face"], "SizingMode": "PixelsPerStud", "PixelsPerStud": 100},
                "children": [{
                    "name": "Text", "className": "TextLabel",
                    "properties": {
                        "Size": {"UDim2": [[1, 0], [1, 0]]}, "BackgroundTransparency": 1, "Text": p["plate_text"],
                        "TextScaled": True, "Font": "GothamBold", "TextColor3": [0.05, 0.05, 0.05],
                    },
                }],
            }]
        children.append(child)
    return {"className": "Model", "children": children}


if __name__ == "__main__":
    here = Path(__file__).parent
    (here / "BlackCoupe.model.json").write_text(json.dumps(to_rojo(), indent=1))
    print(f"{len(parts)} parts -> BlackCoupe.model.json")
