"""Generates every SkyLens launcher icon, splash image and web icon.

The mark uses the same geometry as `SkyLensMark` in
lib/core/widgets/design_components.dart, so the app, launcher and splash
always match. Re-run after changing the mark or colours:

    python tool/brand/make_icons.py        (from the app/ folder; needs Pillow)
"""
import json
import math
import os

from PIL import Image, ImageChops, ImageDraw

APP = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SS = 4  # supersampling factor

PRIMARY = (0x7E, 0xA6, 0xFF)
STAR = (0xF4, 0xF6, 0xFB)
BG_CENTER = (0x18, 0x26, 0x52)
BG_EDGE = (0x07, 0x0A, 0x12)
ICON_BG = '#0B1430'     # adaptive-icon background layer
SPLASH_BG = '#070A12'   # = SkyTokens.space.bg


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def disc(size, cx, cy, r):
    m = Image.new('L', (size, size), 0)
    ImageDraw.Draw(m).ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)
    return m


def mark(px, color=None):
    """RGBA image of the mark in a px*px box. color=None → full colour,
    otherwise a single-colour silhouette (themed / monochrome icons)."""
    s = px * SS
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))

    def fill(mask, rgb, alpha=1.0):
        layer = Image.new('RGBA', (s, s), rgb + (0,))
        layer.putalpha(mask.point(lambda v: round(v * alpha)))
        img.alpha_composite(layer)

    ring_r, ring_w = 0.38 * s, 0.075 * s
    inner = disc(s, s / 2, s / 2, ring_r - ring_w / 2)

    # Horizon: big circle below centre, clipped to the lens.
    gx, gy, gr = 0.5 * s, 1.22 * s, 0.58 * s
    ground = ImageChops.multiply(disc(s, gx, gy, gr), inner)
    fill(ground, color or PRIMARY, 0.28 if color is None else 0.45)
    edge = ImageChops.subtract(disc(s, gx, gy, gr + 0.015 * s), disc(s, gx, gy, gr - 0.015 * s))
    fill(ImageChops.multiply(edge, inner), color or PRIMARY)

    # Lens ring with a diagonal gradient.
    ring = ImageChops.subtract(
        disc(s, s / 2, s / 2, ring_r + ring_w / 2), disc(s, s / 2, s / 2, ring_r - ring_w / 2)
    )
    if color is None:
        light, deep = lerp(PRIMARY, (255, 255, 255), 0.45), lerp(PRIMARY, (0x33, 0x55, 0xFF), 0.45)
        grad = Image.new('RGBA', (s, s))
        gd = ImageDraw.Draw(grad)
        for i in range(2 * s):
            gd.line([(i, 0), (0, i)], fill=lerp(light, deep, i / (2 * s)) + (255,))
        grad.putalpha(ring)
        img.alpha_composite(grad)
    else:
        fill(ring, color)

    # Four-point star + companion dot.
    cx, cy, ro, ri = 0.585 * s, 0.41 * s, 0.15 * s, 0.035 * s
    pts = []
    for i in range(8):
        r = ro if i % 2 == 0 else ri
        a = -math.pi / 2 + i * math.pi / 4
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    star = Image.new('L', (s, s), 0)
    ImageDraw.Draw(star).polygon(pts, fill=255)
    fill(star, color or STAR)
    fill(disc(s, 0.375 * s, 0.355 * s, 0.026 * s), color or STAR, 0.85)

    return img.resize((px, px), Image.LANCZOS)


def background(px, radius_frac=0.0):
    """Radial navy gradient, optionally as a rounded square."""
    s = px * SS
    bg = Image.new('RGBA', (s, s))
    d = ImageDraw.Draw(bg)
    cx, cy, rmax = s / 2, s * 0.42, s * 0.78
    steps = 120
    for i in range(steps, 0, -1):
        r = rmax * i / steps
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=lerp(BG_CENTER, BG_EDGE, i / steps) + (255,))
    if radius_frac:
        m = Image.new('L', (s, s), 0)
        ImageDraw.Draw(m).rounded_rectangle((0, 0, s - 1, s - 1), radius=radius_frac * s, fill=255)
        bg.putalpha(m)
    return bg.resize((px, px), Image.LANCZOS)


def composed(px, mark_frac, radius_frac=0.0):
    img = background(px, radius_frac)
    m = mark(round(px * mark_frac))
    o = (px - m.width) // 2
    layer = Image.new('RGBA', (px, px), (0, 0, 0, 0))
    layer.paste(m, (o, o))
    out = Image.alpha_composite(img, layer)
    if radius_frac:
        out.putalpha(ImageChops.multiply(out.getchannel('A'), img.getchannel('A')))
    return out


def centred(px, mark_frac, color=None):
    img = Image.new('RGBA', (px, px), (0, 0, 0, 0))
    m = mark(round(px * mark_frac), color)
    o = (px - m.width) // 2
    img.paste(m, (o, o))
    return img


def save(img, *path):
    p = os.path.join(APP, *path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p, optimize=True)


def write(text, *path):
    p = os.path.join(APP, *path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)


DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
RES = ('android', 'app', 'src', 'main', 'res')

# --- Android launcher -------------------------------------------------------
for name, k in DENSITIES.items():
    save(composed(round(48 * k), 0.74, 0.22), *RES, f'mipmap-{name}', 'ic_launcher.png')
    fg = round(108 * k)  # adaptive layers are 108 dp; the safe zone is 66 dp
    save(centred(fg, 0.58), *RES, f'mipmap-{name}', 'ic_launcher_foreground.png')
    save(centred(fg, 0.58, (255, 255, 255)), *RES, f'mipmap-{name}', 'ic_launcher_monochrome.png')
    # Android 12+ splash icon: 288 dp canvas, content inside the 192 dp circle.
    save(centred(round(288 * k), 0.50), *RES, f'drawable-{name}', 'splash_icon.png')

write("""<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
""", *RES, 'mipmap-anydpi-v26', 'ic_launcher.xml')

write(f"""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">{ICON_BG}</color>
    <color name="splash_background">{SPLASH_BG}</color>
</resources>
""", *RES, 'values', 'colors.xml')

# --- iOS ----------------------------------------------------------------
icons = os.path.join(APP, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
if os.path.isdir(icons):
    with open(os.path.join(icons, 'Contents.json'), encoding='utf-8') as f:
        for i in json.load(f)['images']:
            px = round(float(i['size'].split('x')[0]) * float(i['scale'][:-1]))
            # iOS masks the corners itself and rejects transparency.
            save(composed(px, 0.74).convert('RGB'), 'ios', 'Runner', 'Assets.xcassets',
                 'AppIcon.appiconset', i['filename'])

# --- Web ----------------------------------------------------------------
save(composed(32, 0.80, 0.22), 'web', 'favicon.png')
for px in (192, 512):
    save(composed(px, 0.74, 0.22), 'web', 'icons', f'Icon-{px}.png')
    save(composed(px, 0.60), 'web', 'icons', f'Icon-maskable-{px}.png')

# --- Docs ---------------------------------------------------------------
save(composed(512, 0.74, 0.22), '..', 'docs', 'brand', 'skylens-icon.png')
print('Brand assets written.')
