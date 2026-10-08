#!/usr/bin/env python3
"""Regenerate site images from the source logo. Run: python3 scripts/make-assets.py"""
import colorsys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "brand" / "nanofaas-logo-transparent.png"
OUT = ROOT / "assets" / "img"
WORDMARK_TOP = 760  # rows above this hold only the cloud mark


def trim(im):
    alpha = im.getchannel("A").point(lambda v: 255 if v > 40 else 0)
    return im.crop(alpha.getbbox())


def for_dark_bg(im):
    # mirror the lightness of dark pixels (navy -> pale blue), keep hue and alpha
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if not a:
                continue
            h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            if l < 0.5:
                r, g, b = (round(c * 255) for c in colorsys.hls_to_rgb(h, 1 - l, s))
                px[x, y] = (r, g, b, a)
    return im


def square(im, size):
    side = max(im.size)
    canvas = Image.new("RGBA", (side, side))
    canvas.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
    return canvas.resize((size, size), Image.LANCZOS)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    src = Image.open(SRC).convert("RGBA")

    logo = trim(src)
    logo = logo.resize((480, round(480 * logo.height / logo.width)), Image.LANCZOS)
    logo.save(OUT / "logo.png", optimize=True)
    for_dark_bg(logo).save(OUT / "logo-dark.png", optimize=True)

    mark = square(trim(src.crop((0, 0, src.width, WORDMARK_TOP))), 64)
    mark.save(OUT / "mark.png", optimize=True)
    for_dark_bg(mark).save(OUT / "mark-dark.png", optimize=True)

    # link preview (Open Graph / Twitter large card): logo centered on the light section tint
    og = Image.new("RGBA", (1200, 630), (0xF4, 0xF7, 0xFC, 255))
    big = trim(src)
    big = big.resize((round(400 * big.width / big.height), 400), Image.LANCZOS)
    og.alpha_composite(big, ((og.width - big.width) // 2, (og.height - big.height) // 2))
    og.convert("RGB").save(OUT / "og.png", optimize=True)

    assert Image.open(OUT / "og.png").size == (1200, 630)
    for name in ("logo.png", "logo-dark.png", "mark.png", "mark-dark.png"):
        im = Image.open(OUT / name)
        assert im.mode == "RGBA", name
        assert im.getpixel((0, 0))[3] == 0, f"{name}: corner not transparent"
    assert Image.open(OUT / "mark.png").size == (64, 64)
    assert Image.open(OUT / "logo.png").width == 480
    print("assets ok")


if __name__ == "__main__":
    main()
