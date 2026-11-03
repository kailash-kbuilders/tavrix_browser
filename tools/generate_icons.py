"""Generate Android launcher icons and notification icons from the Tavrix logo.

Run from the repository root:

    python3 tools/generate_icons.py

It reads assets/branding/logo_source.jpg and writes:

    assets/android_icons/res/mipmap-anydpi-v26/ic_launcher.xml
    assets/android_icons/res/mipmap-anydpi-v26/ic_launcher_round.xml
    assets/android_icons/res/mipmap-*/ic_launcher.png          (legacy, rounded)
    assets/android_icons/res/mipmap-*/ic_launcher_round.png    (legacy, circular)
    assets/android_icons/res/drawable-*/ic_launcher_foreground.png
    assets/android_icons/res/drawable-*/ic_launcher_background.png
    assets/android_icons/res/drawable-*/ic_stat_tavrix.png     (notification)

The adaptive icon is what makes the launcher apply its own shape (circle,
squircle, teardrop) instead of showing a square picture with rounded corners
baked into it.

Requires Pillow and numpy.
"""

import pathlib
from collections import deque

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/branding/logo_source.jpg"
OUT = ROOT / "assets/android_icons/res"

# Adaptive icons are 108dp canvases; only the middle 72dp is guaranteed visible,
# and the safe zone is a 66dp circle. Keep the mark inside that.
MARK_FRACTION = 0.63

DENSITIES = {
    "mdpi": 1.0,
    "hdpi": 1.5,
    "xhdpi": 2.0,
    "xxhdpi": 3.0,
    "xxxhdpi": 4.0,
}


def ramp(values, low, high):
    return np.clip((values - low) / (high - low), 0.0, 1.0)


def extract_mark(source: Image.Image) -> Image.Image:
    """Cut the logo mark out of its dark tile, keeping the dark inner shapes."""
    array = np.asarray(source)
    non_black = array.max(axis=2) > 6
    ys, xs = np.where(non_black)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max(), ys.max()
    inset = int(min(x1 - x0, y1 - y0) * 0.055)
    crop = source.crop((x0 + inset, y0 + inset, x1 - inset, y1 - inset))
    pixels = np.asarray(crop).astype(np.float32)

    low = np.asarray(crop.filter(ImageFilter.GaussianBlur(30))).astype(np.float32)
    diff = np.abs(pixels - low).max(axis=2)
    alpha = ramp(diff, 14, 42)
    mask = alpha > 0.5

    height, width = mask.shape
    outside = np.zeros((height, width), bool)
    queue = deque()
    for x in range(width):
        for y in (0, height - 1):
            if not mask[y, x] and not outside[y, x]:
                outside[y, x] = True
                queue.append((y, x))
    for y in range(height):
        for x in (0, width - 1):
            if not mask[y, x] and not outside[y, x]:
                outside[y, x] = True
                queue.append((y, x))
    while queue:
        y, x = queue.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < height and 0 <= nx < width and not mask[ny, nx] and not outside[ny, nx]:
                outside[ny, nx] = True
                queue.append((ny, nx))
    filled = ~outside

    # Keep only the largest connected region so stray glow patches in the
    # corners are dropped.
    labels = np.zeros((height, width), np.int32)
    sizes = {}
    current = 0
    for start_y in range(height):
        for start_x in range(width):
            if not filled[start_y, start_x] or labels[start_y, start_x]:
                continue
            current += 1
            stack = [(start_y, start_x)]
            labels[start_y, start_x] = current
            count = 0
            while stack:
                y, x = stack.pop()
                count += 1
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < height and 0 <= nx < width and filled[ny, nx] and not labels[ny, nx]:
                        labels[ny, nx] = current
                        stack.append((ny, nx))
            sizes[current] = count
    keep = labels == max(sizes, key=sizes.get)

    mask_image = Image.fromarray((keep * 255).astype(np.uint8))
    mask_image = (
        mask_image.filter(ImageFilter.MinFilter(5))
        .filter(ImageFilter.MaxFilter(3))
        .filter(ImageFilter.GaussianBlur(1.4))
    )
    soft = np.asarray(mask_image).astype(np.float32) / 255.0

    rgba = np.dstack([np.clip(pixels, 0, 255), soft * 255]).astype(np.uint8)
    mark = Image.fromarray(rgba, "RGBA")
    bbox = mark.split()[-1].point(lambda v: 255 if v > 40 else 0).getbbox()
    return mark.crop(bbox)


def gradient_background(size: int) -> Image.Image:
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    nx, ny = x / size, y / size
    base = np.zeros((size, size, 3), np.float32)
    base[..., :] = (5, 7, 14)

    def glow(cx, cy, radius, color, power):
        distance = np.sqrt((nx - cx) ** 2 + (ny - cy) ** 2)
        factor = np.clip(1 - distance / radius, 0, 1) ** 2 * power
        for channel in range(3):
            base[..., channel] += color[channel] * factor

    glow(0.0, 0.0, 0.95, (14, 60, 180), 1.0)
    glow(1.0, 1.0, 1.0, (100, 28, 180), 0.9)
    return Image.fromarray(np.clip(base, 0, 255).astype(np.uint8))


def place_mark(mark: Image.Image, size: int, fraction: float) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    side = int(size * fraction)
    scaled = mark.copy()
    scaled.thumbnail((side, side), Image.LANCZOS)
    canvas.paste(scaled, ((size - scaled.width) // 2, (size - scaled.height) // 2), scaled)
    return canvas


def rounded_mask(size: int, radius_fraction: float) -> Image.Image:
    scale = 4
    mask = Image.new("L", (size * scale, size * scale), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size * scale - 1, size * scale - 1),
        radius=int(size * scale * radius_fraction),
        fill=255,
    )
    return mask.resize((size, size), Image.LANCZOS)


def circle_mask(size: int) -> Image.Image:
    scale = 4
    mask = Image.new("L", (size * scale, size * scale), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size * scale - 1, size * scale - 1), fill=255)
    return mask.resize((size, size), Image.LANCZOS)


def write(path: pathlib.Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print("wrote", path.relative_to(ROOT))


def main() -> None:
    source = Image.open(SOURCE).convert("RGB")
    mark = extract_mark(source)
    print("mark size", mark.size)

    for density, factor in DENSITIES.items():
        adaptive = int(108 * factor)
        background = gradient_background(adaptive)
        foreground = place_mark(mark, adaptive, MARK_FRACTION)
        write(OUT / f"drawable-{density}/ic_launcher_background.png", background)
        write(OUT / f"drawable-{density}/ic_launcher_foreground.png", foreground)

        legacy_size = int(48 * factor)
        legacy = gradient_background(legacy_size)
        legacy_mark = place_mark(mark, legacy_size, MARK_FRACTION)
        legacy.paste(legacy_mark, (0, 0), legacy_mark)
        legacy = legacy.convert("RGB")

        square = Image.new("RGB", (legacy_size, legacy_size), (5, 7, 14))
        square.paste(legacy, (0, 0), rounded_mask(legacy_size, 0.22))
        write(OUT / f"mipmap-{density}/ic_launcher.png", square)

        circle = Image.new("RGB", (legacy_size, legacy_size), (5, 7, 14))
        circle.paste(legacy, (0, 0), circle_mask(legacy_size))
        write(OUT / f"mipmap-{density}/ic_launcher_round.png", circle)

        # Notification icons must be a flat white silhouette; Android tints
        # them itself. Use only the bright strokes so it reads as a glyph.
        status_size = int(24 * factor)
        strokes = np.asarray(mark).astype(np.float32)
        rgb = strokes[..., :3]
        stroke_alpha = strokes[..., 3] / 255.0
        brightness = rgb.max(axis=2)
        chroma = rgb.max(axis=2) - rgb.min(axis=2)
        glyph = ((brightness > 135) & (chroma > 45) & (stroke_alpha > 0.5))
        glyph_img = Image.fromarray((glyph * 255).astype(np.uint8))
        glyph_img = glyph_img.filter(ImageFilter.MaxFilter(3)).filter(
            ImageFilter.GaussianBlur(0.6))
        glyph_img.thumbnail((int(status_size * 0.92), int(status_size * 0.92)),
                            Image.LANCZOS)
        status = Image.new("RGBA", (status_size, status_size), (0, 0, 0, 0))
        white = Image.new("RGBA", glyph_img.size, (255, 255, 255, 0))
        white.putalpha(glyph_img)
        status.paste(white, ((status_size - glyph_img.width) // 2,
                             (status_size - glyph_img.height) // 2), white)
        write(OUT / f"drawable-{density}/ic_stat_tavrix.png", status)

    adaptive_xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
"""
    for name in ("ic_launcher", "ic_launcher_round"):
        path = OUT / f"mipmap-anydpi-v26/{name}.xml"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(adaptive_xml)
        print("wrote", path.relative_to(ROOT))

    # in-app logo (transparent mark)
    app_logo = place_mark(mark, 512, 0.92)
    app_logo.save(ROOT / "assets/branding/logo_mark.png")
    print("wrote assets/branding/logo_mark.png")


if __name__ == "__main__":
    main()
