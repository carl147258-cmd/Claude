#!/usr/bin/env python3
"""Draw the obby's game icon (512x512) and a thumbnail (1920x1080) with Pillow.

Usage: python3 scripts/make_obby_art.py <output_dir>
Everything is drawn from shapes, so there are no third-party image rights to worry about.
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SS = 4  # supersampling factor for smooth edges
FONT = "/usr/share/fonts/opentype/inter/InterDisplay-Black.otf"


def vertical_gradient(w, h, top, bottom):
    img = Image.new("RGB", (w, h), top)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        draw.line([(0, y), (w, y)], fill=color)
    return img


def shade(color, factor):
    return tuple(max(0, min(255, int(c * factor))) for c in color)


def block(draw, x, y, w, h, depth, color):
    """Pseudo-3D block: front face, lighter top face, darker side face."""
    d = depth
    draw.polygon([(x, y), (x + d, y - d), (x + w + d, y - d), (x + w, y)], fill=shade(color, 1.25))  # top
    draw.polygon([(x + w, y), (x + w + d, y - d), (x + w + d, y + h - d), (x + w, y + h)], fill=shade(color, 0.7))
    draw.rectangle([x, y, x + w, y + h], fill=color)


def character(draw, cx, cy, s):
    """Blocky jumping figure, s = scale unit."""
    skin, shirt, pants = (255, 205, 60), (40, 120, 230), (40, 170, 90)
    # legs (spread mid-jump)
    draw.polygon([(cx - 1.0 * s, cy + 1.6 * s), (cx - 0.1 * s, cy + 1.6 * s), (cx - 0.6 * s, cy + 3.3 * s), (cx - 1.6 * s, cy + 3.0 * s)], fill=pants)
    draw.polygon([(cx + 0.1 * s, cy + 1.6 * s), (cx + 1.0 * s, cy + 1.6 * s), (cx + 1.8 * s, cy + 2.9 * s), (cx + 0.9 * s, cy + 3.3 * s)], fill=pants)
    # arms up
    draw.polygon([(cx - 1.0 * s, cy - 0.3 * s), (cx - 1.9 * s, cy - 1.9 * s), (cx - 2.5 * s, cy - 1.5 * s), (cx - 1.0 * s, cy + 0.6 * s)], fill=skin)
    draw.polygon([(cx + 1.0 * s, cy - 0.3 * s), (cx + 1.9 * s, cy - 1.9 * s), (cx + 2.5 * s, cy - 1.5 * s), (cx + 1.0 * s, cy + 0.6 * s)], fill=skin)
    # torso + head
    draw.rectangle([cx - 1.0 * s, cy - 0.4 * s, cx + 1.0 * s, cy + 1.7 * s], fill=shirt)
    draw.rounded_rectangle([cx - 0.75 * s, cy - 1.9 * s, cx + 0.75 * s, cy - 0.5 * s], radius=0.25 * s, fill=skin)
    # face
    draw.ellipse([cx - 0.4 * s, cy - 1.45 * s, cx - 0.2 * s, cy - 1.2 * s], fill=(30, 30, 30))
    draw.ellipse([cx + 0.2 * s, cy - 1.45 * s, cx + 0.4 * s, cy - 1.2 * s], fill=(30, 30, 30))
    draw.arc([cx - 0.4 * s, cy - 1.25 * s, cx + 0.4 * s, cy - 0.75 * s], 20, 160, fill=(30, 30, 30), width=max(1, int(0.08 * s)))


def outlined_text(draw, xy, text, size, fill, outline, anchor="mm"):
    font = ImageFont.truetype(FONT, size)
    draw.text(xy, text, font=font, fill=fill, anchor=anchor, stroke_width=max(2, size // 9), stroke_fill=outline)


def scene(w, h, title_size, show_subtitle):
    W, H = w * SS, h * SS
    img = vertical_gradient(W, H, (90, 170, 255), (190, 235, 255))
    draw = ImageDraw.Draw(img)
    ux, uy = W / 100, H / 100  # layout units
    u = min(ux, uy)

    # lava: soft orange haze above a bright lava band
    for i in range(int(10 * uy)):
        t = i / (10 * uy)
        y = H - 13 * uy - i
        base = img.getpixel((0, int(y)))
        color = tuple(int(base[k] + ((255, 150, 60)[k] - base[k]) * (1 - t) * 0.6) for k in range(3))
        draw.line([(0, y), (W, y)], fill=color)
    draw.rectangle([0, H - 13 * uy, W, H], fill=(255, 90, 0))
    draw.rectangle([0, H - 13 * uy, W, H - 12 * uy], fill=(255, 170, 40))
    for i in range(10):
        bx = (i * 0.1 + 0.035) * W
        r = 1.4 * u
        draw.ellipse([bx - r, H - 5 * uy - r, bx + r, H - 5 * uy + r], fill=(255, 200, 60))

    # platforms stepping up to the right
    block(draw, 6 * ux, 72 * uy, 22 * ux, 6 * uy, 3.5 * u, (70, 200, 90))    # checkpoint (green)
    block(draw, 36 * ux, 62 * uy, 13 * ux, 5 * uy, 3 * u, (200, 200, 210))
    block(draw, 56 * ux, 52 * uy, 11 * ux, 5 * uy, 3 * u, (120, 170, 255))   # disappearing (blue)
    block(draw, 74 * ux, 42 * uy, 17 * ux, 6 * uy, 3.5 * u, (255, 200, 0))   # goal (gold)

    character(draw, 48 * ux, 37 * uy, 4.2 * u)

    cx = W / 2
    outlined_text(draw, (cx, 15 * uy), "OBBY", int(title_size * SS), (255, 255, 255), (25, 40, 90))
    if show_subtitle:
        outlined_text(draw, (cx, 85 * uy), "15 STUFEN · SCHAFFST DU ES?", int(title_size * 0.32 * SS), (255, 255, 255), (120, 30, 0))

    return img.resize((w, h), Image.LANCZOS)


def main():
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "art")
    out.mkdir(parents=True, exist_ok=True)
    scene(512, 512, 120, False).save(out / "icon_512.png")
    scene(1920, 1080, 210, True).save(out / "thumbnail_1920x1080.png")
    print(f"wrote {out}/icon_512.png and {out}/thumbnail_1920x1080.png")


if __name__ == "__main__":
    main()
