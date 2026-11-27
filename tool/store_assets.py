#!/usr/bin/env python3
"""Builds the Google Play listing graphics into store/play/.

Inputs:
  - assets/branding/app-icon.png (the app icon artwork)
  - assets/art/home-glade.png (in-app backdrop, for the feature graphic)
  - raw 1080x2160 app screens in a folder (default build/store_raw/), named
    puzzle.png, win.png, modes.png, map.png. They were captured from
    the real app (Linux desktop build at 3x scale, see store/play/README.md).

Run:  python3 tool/store_assets.py [raw_screens_dir]
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "store" / "play"
RAW = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "build" / "store_raw"
FONT = str(ROOT / "assets" / "fonts" / "ZenMaruGothic-Bold.ttf")

CREAM = (250, 246, 234)
GREEN = (53, 99, 76)
DEEP = (40, 61, 48)
SUB = (76, 101, 71)

# (file, headline, sub line). Every claim matches the shipped app.
SCREENS = [
    ("puzzle", "ひらがなの\nことば当て", "文字を大きくする設定もあります"),
    ("win", "正解すると\n森が育つ", "毎日すこしずつ、にぎやかに"),
    ("modes", "3・4・5文字から\nえらべる", "全800問・何度でもあそべます"),
    ("map", "花咲く小道を\nすすもう", "ステージをクリアして星を集めます"),
]


def font(size):
    return ImageFont.truetype(FONT, size)


def centered(draw, y, text, size, fill, width, spacing=18):
    f = font(size)
    box = draw.multiline_textbbox((0, 0), text, font=f, spacing=spacing, align="center")
    w = box[2] - box[0]
    draw.multiline_text(((width - w) / 2 - box[0], y), text, font=f, fill=fill,
                        spacing=spacing, align="center")
    return y + (box[3] - box[1])


def rounded(im, radius):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *im.size), radius, fill=255)
    im = im.convert("RGBA")
    im.putalpha(mask)
    return im


def icon():
    """512x512 full-square icon: Play applies its own corner mask, so the
    pre-rounded artwork is cropped until no transparent corner remains."""
    src = Image.open(ROOT / "assets" / "branding" / "app-icon.png").convert("RGBA")
    alpha = src.split()[3]
    size = src.size[0]
    inset = 0
    while inset < size // 4:
        box = (inset, inset, size - inset, size - inset)
        edge = alpha.crop(box)
        w, h = edge.size
        border = [edge.getpixel((x, y)) for x in range(w) for y in (0, h - 1)]
        border += [edge.getpixel((x, y)) for y in range(h) for x in (0, w - 1)]
        if min(border) == 255:
            break
        inset += 2
    art = src.crop((inset, inset, size - inset, size - inset)).resize((512, 512), Image.LANCZOS)
    out = Image.new("RGB", (512, 512), GREEN)
    out.paste(art, (0, 0), art)
    out.save(OUT / "icon-512.png", optimize=True)
    return inset


def feature():
    """1024x500. Text sits left, inside the safe middle area."""
    W, H = 1024, 500
    bg = Image.open(ROOT / "assets" / "art" / "home-glade.png").convert("RGB")
    scale = W / bg.width
    bg = bg.resize((W, int(bg.height * scale)), Image.LANCZOS)
    top = int(bg.height * 0.30)
    bg = bg.crop((0, top, W, top + H))
    veil = Image.new("RGBA", (W, H))
    vd = ImageDraw.Draw(veil)
    for x in range(W):
        a = int(235 * max(0.0, min(1.0, (720 - x) / 380)))
        vd.line([(x, 0), (x, H)], fill=(*CREAM, a))
    img = Image.alpha_composite(bg.convert("RGBA"), veil)
    d = ImageDraw.Draw(img)
    d.text((80, 118), "ことばの森", font=font(112), fill=GREEN)
    d.text((86, 268), "ゆっくり、ひとことば。", font=font(50), fill=DEEP)
    d.text((88, 350), "ひらがなの ことば当てパズル", font=font(34), fill=SUB)
    ic = Image.open(OUT / "icon-512.png").convert("RGB").resize((280, 280), Image.LANCZOS)
    ic = rounded(ic, 64)
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((692, 118, 692 + 280, 118 + 280), 64,
                                             fill=(0, 0, 0, 90))
    img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(14)))
    img.paste(ic, (684, 106), ic)
    img.convert("RGB").save(OUT / "feature-1024x500.png", optimize=True)


def screenshots():
    """1080x2160 portrait (Play allows at most a 2:1 ratio)."""
    W, H = 1080, 2160
    shots = OUT / "screenshots"
    shots.mkdir(parents=True, exist_ok=True)
    for i, (name, head, sub) in enumerate(SCREENS, 1):
        canvas = Image.new("RGBA", (W, H), (*CREAM, 255))
        d = ImageDraw.Draw(canvas)
        y = centered(d, 90, head, 96, GREEN, W, spacing=22)
        centered(d, y + 50, sub, 50, DEEP, W)
        screen_top = 500
        avail = H - screen_top - 70
        raw = Image.open(RAW / f"{name}.png").convert("RGB")
        sw = int(raw.width * avail / raw.height)
        screen = rounded(raw.resize((sw, avail), Image.LANCZOS), 48)
        x = (W - sw) // 2
        shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(shadow).rounded_rectangle((x, screen_top + 14, x + sw, screen_top + 14 + avail),
                                                 48, fill=(40, 61, 48, 70))
        canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(22)))
        frame = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(frame).rounded_rectangle((x - 6, screen_top - 6, x + sw + 6, screen_top + avail + 6),
                                                54, fill=(*GREEN, 255))
        canvas = Image.alpha_composite(canvas, frame)
        canvas.paste(screen, (x, screen_top), screen)
        canvas.convert("RGB").save(shots / f"{i:02d}-{name}.png", optimize=True)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    inset = icon()
    feature()
    screenshots()
    print(f"icon inset {inset}px; wrote {OUT}")
