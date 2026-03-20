#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
APP_ICON_DIR = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
TRAY_TEMPLATE_PATH = ROOT / "assets/tray/tray_icon_template.png"
TRAY_COLOR_PATH = ROOT / "assets/tray/tray_icon_color.png"
PREVIEW_PATH = ROOT / "assets/branding/lockbar_icon_preview.png"
MASTER_PATH = ROOT / "assets/branding/lockbar_app_icon_master.png"


def hex_rgba(value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = value.lstrip("#")
    return (
        int(value[0:2], 16),
        int(value[2:4], 16),
        int(value[4:6], 16),
        alpha,
    )


def vertical_gradient(size: tuple[int, int], top: str, bottom: str) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size)
    draw = ImageDraw.Draw(image)
    r1, g1, b1, _ = hex_rgba(top)
    r2, g2, b2, _ = hex_rgba(bottom)
    for y in range(height):
      t = y / max(height - 1, 1)
      color = (
          int(r1 + (r2 - r1) * t),
          int(g1 + (g2 - g1) * t),
          int(b1 + (b2 - b1) * t),
          255,
      )
      draw.line((0, y, width, y), fill=color)
    return image


def radial_glow(
    size: tuple[int, int],
    center: tuple[int, int],
    radius: int,
    color: tuple[int, int, int, int],
) -> Image.Image:
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    cx, cy = center
    max_radius = max(radius, 1)
    for index in range(max_radius, 0, -12):
      alpha = int(color[3] * (index / max_radius) ** 2)
      fill = (color[0], color[1], color[2], alpha)
      draw.ellipse((cx - index, cy - index, cx + index, cy + index), fill=fill)
    return image.filter(ImageFilter.GaussianBlur(radius / 8))


def rounded_mask(size: tuple[int, int], radius: int, inset: int = 0) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(
        (inset, inset, size[0] - inset, size[1] - inset),
        radius=radius,
        fill=255,
    )
    return mask


def cut_mask(mask: Image.Image, shape_drawer) -> Image.Image:
    cut = Image.new("L", mask.size, 0)
    draw = ImageDraw.Draw(cut)
    shape_drawer(draw)
    return ImageChops.subtract(mask, cut)


def draw_beveled_body(
    canvas: Image.Image,
    bounds: tuple[int, int, int, int],
    radius: int,
) -> None:
    body_mask = Image.new("L", canvas.size, 0)
    body_draw = ImageDraw.Draw(body_mask)
    body_draw.rounded_rectangle(bounds, radius=radius, fill=255)

    x1, y1, x2, y2 = bounds
    stripe = Image.new("L", canvas.size, 0)
    stripe_draw = ImageDraw.Draw(stripe)
    stripe_draw.polygon(
        [
            (x1 + 230, y1 - 18),
            (x2 + 80, y1 - 18),
            (x2 - 80, y2 + 18),
            (x1 + 70, y2 + 18),
        ],
        fill=255,
    )
    stripe_mask = ImageChops.multiply(body_mask, stripe)

    body_fill = vertical_gradient(canvas.size, "#20343C", "#0E171B")
    canvas.alpha_composite(Image.composite(body_fill, Image.new("RGBA", canvas.size), body_mask))

    diagonal_fill = vertical_gradient(canvas.size, "#B6FFF0", "#5AD7FF")
    diagonal_fill.putalpha(0)
    highlight_alpha = stripe_mask.filter(ImageFilter.GaussianBlur(2))
    diagonal_fill.putalpha(highlight_alpha)
    canvas.alpha_composite(diagonal_fill)

    edge = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    edge_draw = ImageDraw.Draw(edge)
    edge_draw.rounded_rectangle(bounds, radius=radius, outline=hex_rgba("#E7FFF7", 76), width=6)
    inner_bounds = (x1 + 14, y1 + 14, x2 - 14, y2 - 14)
    edge_draw.rounded_rectangle(inner_bounds, radius=radius - 16, outline=hex_rgba("#0B1014", 120), width=14)
    canvas.alpha_composite(edge)

    notch = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    notch_draw = ImageDraw.Draw(notch)
    notch_draw.rounded_rectangle((486, 566, 538, 678), radius=24, fill=hex_rgba("#071015", 210))
    notch_draw.ellipse((480, 500, 544, 564), fill=hex_rgba("#0C171C", 230))
    canvas.alpha_composite(notch)


def draw_bar_and_lock(size: int = 1024) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon_mask = rounded_mask((size, size), 230, inset=46)

    background = vertical_gradient((size, size), "#0B1115", "#0E2224")
    canvas.alpha_composite(Image.composite(background, Image.new("RGBA", (size, size)), icon_mask))

    for glow in [
        radial_glow((size, size), (292, 284), 260, hex_rgba("#9DFF69", 84)),
        radial_glow((size, size), (760, 334), 240, hex_rgba("#62D7FF", 72)),
        radial_glow((size, size), (672, 760), 280, hex_rgba("#FFD36E", 52)),
    ]:
        canvas.alpha_composite(Image.composite(glow, Image.new("RGBA", (size, size)), icon_mask))

    sweep = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sweep_draw = ImageDraw.Draw(sweep)
    sweep_draw.polygon(
        [(84, 764), (280, 120), (472, 120), (286, 764)],
        fill=hex_rgba("#F2FFF6", 22),
    )
    canvas.alpha_composite(Image.composite(sweep.filter(ImageFilter.GaussianBlur(28)), Image.new("RGBA", (size, size)), icon_mask))

    emblem = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    emblem_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(emblem_shadow)
    shadow_draw.rounded_rectangle((232, 232, 792, 304), radius=36, fill=hex_rgba("#021014", 180))
    shadow_draw.arc((374, 304, 654, 598), start=180, end=360, fill=hex_rgba("#021014", 180), width=80)
    shadow_draw.rounded_rectangle((322, 442, 722, 790), radius=118, fill=hex_rgba("#021014", 180))
    emblem_shadow = emblem_shadow.filter(ImageFilter.GaussianBlur(28))
    canvas.alpha_composite(emblem_shadow)

    bar_glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bar_glow_draw = ImageDraw.Draw(bar_glow)
    bar_glow_draw.rounded_rectangle((238, 218, 786, 300), radius=38, fill=hex_rgba("#8FFE71", 132))
    bar_glow_draw.rounded_rectangle((254, 228, 804, 310), radius=38, fill=hex_rgba("#68DFFF", 76))
    canvas.alpha_composite(bar_glow.filter(ImageFilter.GaussianBlur(32)))

    bar = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bar_draw = ImageDraw.Draw(bar)
    bar_draw.rounded_rectangle((246, 228, 778, 290), radius=31, fill=hex_rgba("#7DFF63"))
    bar_draw.polygon(
        [(246, 228), (330, 228), (292, 290), (206, 290)],
        fill=hex_rgba("#A7FF85"),
    )
    bar_draw.polygon(
        [(694, 228), (778, 228), (818, 290), (734, 290)],
        fill=hex_rgba("#52D8FF"),
    )
    bar_draw.rounded_rectangle((246, 228, 778, 248), radius=20, fill=hex_rgba("#EAFFF4", 120))
    emblem.alpha_composite(bar)

    shackle = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shackle_draw = ImageDraw.Draw(shackle)
    shackle_draw.arc((388, 308, 650, 572), start=182, end=360, fill=hex_rgba("#E7FFF6", 238), width=76)
    shackle_draw.arc((412, 334, 626, 548), start=182, end=360, fill=hex_rgba("#8FE86B", 80), width=16)
    shackle_draw.arc((390, 306, 652, 570), start=182, end=246, fill=hex_rgba("#8FE86B", 140), width=14)
    shackle_draw.arc((390, 306, 652, 570), start=280, end=360, fill=hex_rgba("#6ED8FF", 100), width=12)
    shackle = shackle.rotate(-7, resample=Image.Resampling.BICUBIC, center=(520, 440))
    emblem.alpha_composite(shackle)

    draw_beveled_body(emblem, (318, 448, 718, 790), radius=116)
    emblem = emblem.rotate(-7, resample=Image.Resampling.BICUBIC, center=(520, 560))
    canvas.alpha_composite(emblem)

    rim = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rim_draw = ImageDraw.Draw(rim)
    rim_draw.rounded_rectangle((46, 46, size - 46, size - 46), radius=230, outline=hex_rgba("#F1FFF7", 46), width=4)
    rim_draw.rounded_rectangle((52, 52, size - 52, size - 52), radius=226, outline=hex_rgba("#061116", 150), width=14)
    canvas.alpha_composite(rim)

    specular = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    specular_draw = ImageDraw.Draw(specular)
    specular_draw.polygon(
        [(118, 138), (472, 138), (340, 256), (86, 256)],
        fill=hex_rgba("#FFFFFF", 34),
    )
    canvas.alpha_composite(Image.composite(specular.filter(ImageFilter.GaussianBlur(18)), Image.new("RGBA", (size, size)), icon_mask))

    background_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_ring_mask = ImageChops.subtract(icon_mask, rounded_mask((size, size), 210, inset=78))
    shadow_fill = Image.new("RGBA", (size, size), hex_rgba("#02090C", 62))
    canvas.alpha_composite(Image.composite(shadow_fill, Image.new("RGBA", (size, size)), shadow_ring_mask.filter(ImageFilter.GaussianBlur(18))))

    return canvas


def draw_tray_icon(size: int = 256) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    color = (0, 0, 0, 255)

    draw.rounded_rectangle((34, 54, 222, 76), radius=11, fill=color)
    draw.arc((72, 70, 186, 186), start=180, end=360, fill=color, width=24)
    draw.rounded_rectangle((78, 140, 180, 224), radius=28, fill=color)
    draw.rounded_rectangle((120, 164, 138, 196), radius=9, fill=(255, 255, 255, 0))
    draw.ellipse((116, 144, 142, 170), fill=(255, 255, 255, 0))

    return image.resize((64, 64), Image.Resampling.LANCZOS)


def draw_tray_color_icon(size: int = 256) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.rounded_rectangle((30, 44, 226, 72), radius=14, fill=hex_rgba("#7DFF63", 168))
    glow_draw.arc((74, 66, 182, 174), start=180, end=360, fill=hex_rgba("#FFFFFF", 158), width=20)
    glow_draw.rounded_rectangle((82, 128, 176, 222), radius=28, fill=hex_rgba("#5AD7FF", 132))
    image.alpha_composite(glow.filter(ImageFilter.GaussianBlur(12)))

    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((36, 50, 220, 74), radius=12, fill=hex_rgba("#02090D", 170))
    shadow_draw.arc((78, 72, 188, 182), start=180, end=360, fill=hex_rgba("#02090D", 170), width=24)
    shadow_draw.rounded_rectangle((84, 136, 182, 226), radius=30, fill=hex_rgba("#02090D", 170))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(6)))

    art = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(art)

    draw.rounded_rectangle((38, 46, 214, 68), radius=11, fill=hex_rgba("#7DFF63"))
    draw.polygon([(38, 46), (96, 46), (82, 68), (24, 68)], fill=hex_rgba("#A8FF87"))
    draw.polygon([(178, 46), (214, 46), (228, 68), (192, 68)], fill=hex_rgba("#55D9FF"))
    draw.rounded_rectangle((38, 46, 214, 54), radius=7, fill=hex_rgba("#F0FFF5", 138))

    draw.arc((82, 70, 184, 172), start=180, end=360, fill=hex_rgba("#F4FBFB"), width=22)
    draw.arc((88, 78, 178, 168), start=188, end=252, fill=hex_rgba("#88F26D", 120), width=6)
    draw.arc((88, 78, 178, 168), start=282, end=360, fill=hex_rgba("#6BDFFF", 100), width=6)

    draw.rounded_rectangle((84, 132, 180, 220), radius=28, fill=hex_rgba("#18252B"))
    draw.polygon(
        [(132, 132), (180, 132), (180, 220), (114, 220)],
        fill=hex_rgba("#6AD8F1"),
    )
    draw.rounded_rectangle((84, 132, 180, 220), radius=28, outline=hex_rgba("#E8FFF7", 62), width=2)
    draw.rounded_rectangle((110, 160, 128, 198), radius=9, fill=hex_rgba("#122028", 240))
    draw.ellipse((108, 140, 130, 162), fill=hex_rgba("#122028", 240))

    image.alpha_composite(art)
    return image.resize((72, 72), Image.Resampling.LANCZOS)


def save_app_icon_sizes(master: Image.Image, sizes: Iterable[int]) -> None:
    for size in sizes:
        resized = master.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(APP_ICON_DIR / f"app_icon_{size}.png")


def build_preview(master: Image.Image, tray_template: Image.Image, tray_color: Image.Image) -> Image.Image:
    preview = Image.new("RGBA", (1540, 1040), hex_rgba("#0A1115"))
    draw = ImageDraw.Draw(preview)
    draw.rounded_rectangle((52, 52, 880, 988), radius=52, fill=hex_rgba("#101A1F"))
    draw.rounded_rectangle((930, 52, 1488, 430), radius=44, fill=hex_rgba("#101A1F"))
    draw.rounded_rectangle((930, 468, 1488, 988), radius=44, fill=hex_rgba("#101A1F"))

    preview.alpha_composite(master.resize((768, 768), Image.Resampling.LANCZOS), (82, 132))

    dark_strip = Image.new("RGBA", (460, 96), hex_rgba("#0B1014"))
    light_strip = Image.new("RGBA", (460, 96), hex_rgba("#F4F6F8"))
    tray_large = tray_template.resize((48, 48), Image.Resampling.LANCZOS)
    tray_light = Image.new("RGBA", tray_large.size, (255, 255, 255, 255))
    tray_dark = Image.new("RGBA", tray_large.size, (0, 0, 0, 255))
    dark_strip.alpha_composite(Image.composite(tray_light, Image.new("RGBA", tray_large.size), tray_large.split()[-1]), (34, 24))
    light_strip.alpha_composite(Image.composite(tray_dark, Image.new("RGBA", tray_large.size), tray_large.split()[-1]), (34, 24))
    preview.alpha_composite(dark_strip, (980, 110))
    preview.alpha_composite(light_strip, (980, 226))
    preview.alpha_composite(tray_color.resize((54, 54), Image.Resampling.LANCZOS), (1392, 132))
    preview.alpha_composite(tray_color.resize((54, 54), Image.Resampling.LANCZOS), (1392, 248))

    scale_positions = [(980, 554, 256), (1180, 584, 128), (1328, 618, 64), (1412, 646, 32)]
    for x, y, size in scale_positions:
        resized = master.resize((size, size), Image.Resampling.LANCZOS)
        preview.alpha_composite(resized, (x, y))

    draw.text((982, 500), "App Icon Sizes", fill=hex_rgba("#F0F7F5"))
    draw.text((982, 86), "Tray Icons", fill=hex_rgba("#F0F7F5"))
    draw.text((82, 86), "LockBar", fill=hex_rgba("#F0F7F5"))
    draw.text((82, 108), "flashier app icon + color tray icon", fill=hex_rgba("#91A9A9"))
    return preview


def main() -> None:
    APP_ICON_DIR.mkdir(parents=True, exist_ok=True)
    TRAY_TEMPLATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)

    master = draw_bar_and_lock()
    tray_template = draw_tray_icon()
    tray_color = draw_tray_color_icon()

    master.save(MASTER_PATH)
    save_app_icon_sizes(master, [16, 32, 64, 128, 256, 512, 1024])
    tray_template.save(TRAY_TEMPLATE_PATH)
    tray_color.save(TRAY_COLOR_PATH)
    build_preview(master, tray_template, tray_color).save(PREVIEW_PATH)


if __name__ == "__main__":
    main()
