"""Compose a 512x512 game icon (synthwave style) from the HD render `hd_icon.png` (transparent)."""
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SRC, TITLE, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
FONT = "/usr/share/fonts/opentype/inter/InterDisplay-BlackItalic.otf"
S = 1600


def background():
    arr = np.zeros((S, S, 3))
    top, mid, hor, floor = map(np.array, ([8, 10, 35], [45, 10, 70], [255, 60, 140], [20, 8, 40]))
    for y in range(S):
        t = y / S
        arr[y] = top + (mid - top) * (t / 0.55) if t < 0.55 else (mid + (hor - mid) * ((t - 0.55) / 0.07) if t < 0.62 else floor)
    bg = Image.fromarray(arr.astype(np.uint8))
    c, r = (S * 0.66, S * 0.5), S * 0.2
    sun = Image.new("L", (S, S), 0)
    sd = ImageDraw.Draw(sun)
    sd.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=255)
    for i in range(7):
        y = c[1] + r * (0.05 + i * 0.14)
        sd.rectangle([0, y, S, y + 8 + i * 5], fill=0)
    sun.paste(0, (0, int(S * 0.62), S, S))
    bg = Image.composite(Image.new("RGB", (S, S), (255, 80, 160)), bg, sun.filter(ImageFilter.GaussianBlur(50)).point(lambda v: v * 0.6))
    bg = Image.composite(Image.new("RGB", (S, S), (255, 170, 60)), bg, sun)
    d = ImageDraw.Draw(bg)
    horizon, vp = S * 0.62, (S * 0.5, S * 0.62)
    for i in range(-14, 15):
        d.line([vp, (S * 0.5 + i * S * 0.16, S)], fill=(255, 60, 200), width=4)
    y, step = horizon + 5, 6
    while y < S:
        d.line([(0, y), (S, y)], fill=(255, 60, 200), width=3)
        step *= 1.35
        y += step
    bg = Image.blend(bg, bg.filter(ImageFilter.GaussianBlur(6)), 0.5).convert("RGBA")
    st = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd2 = ImageDraw.Draw(st)
    rng = np.random.default_rng(3)
    for _ in range(36):
        y0, x0 = rng.uniform(S * 0.3, S * 0.9), rng.uniform(0, S * 0.45)
        sd2.line([(x0, y0), (x0 + rng.uniform(150, 450), y0)], fill=(120, 220, 255, int(rng.uniform(60, 160))), width=int(rng.uniform(2, 6)))
    bg.alpha_composite(st.filter(ImageFilter.GaussianBlur(2)))
    return bg


car = Image.open(SRC).convert("RGBA").resize((S, S), Image.LANCZOS)
bg = background()
a = car.split()[3]
solid = a.point(lambda v: 255 if v > 200 else 0)
M = 60  # margin so the glow is not clipped
rim = Image.new("RGBA", (S, S), (60, 220, 255, 0))
rim.putalpha(solid.filter(ImageFilter.MaxFilter(17)).filter(ImageFilter.GaussianBlur(20)).point(lambda v: int(v * 0.7)))
bg.alpha_composite(rim)
bg.alpha_composite(car)
vig = Image.new("L", (S, S), 0)
ImageDraw.Draw(vig).ellipse([-S * 0.25, -S * 0.25, S * 1.25, S * 1.25], fill=255)
bg = Image.composite(bg, Image.new("RGBA", (S, S), (0, 0, 0, 255)), vig.filter(ImageFilter.GaussianBlur(160)))
if TITLE:
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    td = ImageDraw.Draw(layer)
    font = ImageFont.truetype(FONT, 230)
    words = TITLE.split()
    lines = [" ".join(words[: max(1, len(words) // 2)]), " ".join(words[max(1, len(words) // 2):])]
    y = S * 0.13
    for line in filter(None, lines):
        td.text((S / 2, y), line, font=font, anchor="mm", fill=(255, 255, 255), stroke_width=17, stroke_fill=(255, 40, 160))
        y += 230
    bg.alpha_composite(layer.filter(ImageFilter.GaussianBlur(24)))
    bg.alpha_composite(layer)
bg.convert("RGB").resize((512, 512), Image.LANCZOS).save(OUT)
bg.convert("RGB").resize((1024, 1024), Image.LANCZOS).save(OUT.replace(".png", "_1024.png"))
print("saved", OUT)
