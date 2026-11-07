#!/usr/bin/env python3
"""Generate MoneyMate launcher icons + splash screens (Material You warm theme).

Design: warm cream squircle background, terracotta rounded square, cream '₹'.
"""
import os
import math
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(HERE, '..', 'android', 'app', 'src', 'main', 'res')

CREAM = (253, 243, 238, 255)
BRAND = (123, 64, 40, 255)
BRAND_LIGHT = (252, 220, 208, 255)
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'


def squircle_mask(size, radius_ratio=0.225):
    m = Image.new('L', (size, size), 0)
    d = ImageDraw.Draw(m)
    r = int(size * radius_ratio)
    d.rounded_rectangle((0, 0, size - 1, size - 1), radius=r, fill=255)
    return m


def rupee(size, glyph_size, fg=CREAM):
    """Transparent canvas with the ₹ glyph centred."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, glyph_size)
    box = d.textbbox((0, 0), '\u20b9', font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    d.text(((size - w) / 2 - box[0], (size - h) / 2 - box[1]), '\u20b9', font=font, fill=fg)
    return img


def legacy_icon(size, with_bg=True):
    """Full launcher icon: cream squircle + terracotta rounded square + ₹."""
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    if with_bg:
        bg = Image.new('RGBA', (size, size), CREAM)
        canvas.paste(bg, (0, 0), squircle_mask(size))
    inner_pad = int(size * 0.20)
    inner = size - inner_pad * 2
    tile = Image.new('RGBA', (inner, inner), BRAND)
    tile.putalpha(squircle_mask(inner, 0.28))
    canvas.paste(tile, (inner_pad, inner_pad), tile)
    glyph = rupee(inner, int(inner * 0.66))
    canvas.paste(glyph, (inner_pad, inner_pad), glyph)
    return canvas


def adaptive_foreground(size):
    """Adaptive icon foreground: glyph inside the 66% safe zone, transparent bg."""
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    tile = int(size * 0.50)
    off = (size - tile) // 2
    sq = Image.new('RGBA', (tile, tile), BRAND)
    sq.putalpha(squircle_mask(tile, 0.28))
    canvas.paste(sq, (off, off), sq)
    glyph = rupee(tile, int(tile * 0.66))
    canvas.paste(glyph, (off, off), glyph)
    return canvas


def round_icon(size):
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    bg = Image.new('RGBA', (size, size), CREAM)
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    canvas.paste(bg, (0, 0), mask)
    inner_pad = int(size * 0.20)
    inner = size - inner_pad * 2
    tile = Image.new('RGBA', (inner, inner), BRAND)
    m = Image.new('L', (inner, inner), 0)
    ImageDraw.Draw(m).ellipse((0, 0, inner - 1, inner - 1), fill=255)
    tile.putalpha(m)
    canvas.paste(tile, (inner_pad, inner_pad), tile)
    glyph = rupee(inner, int(inner * 0.66))
    canvas.paste(glyph, (inner_pad, inner_pad), glyph)
    return canvas


def splash():
    """Large cream splash with the brand mark centred (Capacitor scales it)."""
    S = 2732
    img = Image.new('RGB', (S, S), CREAM[:3])
    mark = legacy_icon(int(S * 0.30), with_bg=False)
    img.paste(mark, ((S - mark.width) // 2, (S - mark.height) // 2), mark)
    # subtle wordmark below the mark
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, int(S * 0.028))
    text = 'MONEYMATE'
    box = d.textbbox((0, 0), text, font=font)
    w = box[2] - box[0]
    d.text(((S - w) / 2 - box[0], S / 2 + mark.height * 0.62), text, font=font, fill=(150, 110, 92))
    return img


MIPMAPS = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
}

for dens, size in MIPMAPS.items():
    folder = os.path.join(RES, f'mipmap-{dens}')
    os.makedirs(folder, exist_ok=True)
    legacy_icon(size).save(os.path.join(folder, 'ic_launcher.png'))
    round_icon(size).save(os.path.join(folder, 'ic_launcher_round.png'))
    fgsize = int(size * 108 / 48)
    adaptive_foreground(fgsize).save(os.path.join(folder, 'ic_launcher_foreground.png'))
    print(f'{dens}: {size}px legacy/round, {fgsize}px foreground')

sp = splash()
for dens, (w, h) in {
    'mdpi': (320, 480),
    'hdpi': (480, 800),
    'xhdpi': (720, 1280),
    'xxhdpi': (960, 1600),
    'xxxhdpi': (1280, 1920),
}.items():
    for orient, size in (('port', (w, h)), ('land', (h, w))):
        folder = os.path.join(RES, f'drawable-{orient}-{dens}')
        os.makedirs(folder, exist_ok=True)
        # resize from the square source, fitting inside the target box
        ratio = min(size[0] / sp.width, size[1] / sp.height)
        new = sp.resize((int(sp.width * ratio), int(sp.height * ratio)), Image.LANCZOS)
        canvas = Image.new('RGB', size, CREAM[:3])
        canvas.paste(new, ((size[0] - new.width) // 2, (size[1] - new.height) // 2))
        canvas.save(os.path.join(folder, 'splash.png'))
print('splash screens written')

# single big splash used as the default drawable
sp.resize((1280, 1280), Image.LANCZOS).save(os.path.join(RES, 'drawable', 'splash.png'))
print('done')
