#!/usr/bin/env python3
"""
Generate the Glyph app icon as a 1024x1024 PNG.

Renders the simplified QR-inspired brand mark: three finder-pattern squares
(top-left, top-right, bottom-left) plus a four-point sparkle in the
bottom-right.  Cyan→violet gradient, dark background, soft glow.

Usage:
    python3 generate_app_icon.py

Output:
    AppIcon.png in the asset catalog (1024×1024, no transparency)
"""

import math
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter
except ImportError:
    print("Pillow is required.  Install with:  pip3 install Pillow")
    raise SystemExit(1)

CANVAS = 1024

# Colors matching GlyphTheme
BG_COLOR = (10, 10, 20)
CYAN     = (102, 217, 255)
VIOLET   = (153, 102, 255)


def lerp_color(c1: tuple, c2: tuple, t: float) -> tuple:
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


def draw_rounded_rect(draw, rect, radius, fill=None, outline=None, width=1):
    """Draw a rounded rectangle (Pillow ≥ 8.2 has rounded_rectangle)."""
    draw.rounded_rectangle(rect, radius=radius, fill=fill, outline=outline, width=width)


def generate_icon():
    padding = int(CANVAS * 0.18)
    area = CANVAS - 2 * padding
    unit = area / 10.0
    gap = unit * 0.6
    finder = (area - gap) / 2.0

    # ── Layer for shapes ──
    shape_layer = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shape_layer)

    def draw_finder(ox, oy, t_start, t_end):
        """Draw a finder pattern at (ox, oy).  t_start/t_end for gradient lerp."""
        r = finder * 0.18
        lw = int(finder * 0.13)
        t = (t_start + t_end) / 2
        color = lerp_color(CYAN, VIOLET, t)

        # Outer ring (stroked rounded rect)
        sd.rounded_rectangle(
            [ox, oy, ox + finder, oy + finder],
            radius=r, outline=(*color, 255), width=lw
        )

        # Inner filled square
        inset = finder * 0.28
        sd.rounded_rectangle(
            [ox + inset, oy + inset,
             ox + finder - inset, oy + finder - inset],
            radius=r * 0.5, fill=(*color, 255)
        )

    # Three finder patterns
    x0 = padding
    y0 = padding
    draw_finder(x0, y0, 0.0, 0.3)                          # top-left (cyan)
    draw_finder(x0 + finder + gap, y0, 0.4, 0.7)           # top-right (mid)
    draw_finder(x0, y0 + finder + gap, 0.1, 0.4)           # bottom-left (cyan-ish)

    # ── Bottom-right sparkle ──
    cx = x0 + finder + gap + finder / 2
    cy = y0 + finder + gap + finder / 2
    arm = finder * 0.32
    waist = arm * 0.28
    t_sparkle = 0.85
    sparkle_color = lerp_color(CYAN, VIOLET, t_sparkle)

    # Draw a clean four-point sparkle using quadratic Bézier curves
    # (mirrors the SwiftUI addQuadCurve approach in GlyphLogoView)
    def quad_bezier(p0, p1, p2, steps=20):
        """Return points along a quadratic Bézier from p0 to p2 with control p1."""
        pts = []
        for i in range(steps + 1):
            t = i / steps
            x = (1-t)**2 * p0[0] + 2*(1-t)*t * p1[0] + t**2 * p2[0]
            y = (1-t)**2 * p0[1] + 2*(1-t)*t * p1[1] + t**2 * p2[1]
            pts.append((x, y))
        return pts

    top    = (cx, cy - arm)
    right  = (cx + arm, cy)
    bottom = (cx, cy + arm)
    left   = (cx - arm, cy)

    # Control points (same as SwiftUI: pulled toward the diagonal)
    ctrl_tr = (cx + waist, cy - waist)   # top → right
    ctrl_rb = (cx + waist, cy + waist)   # right → bottom
    ctrl_bl = (cx - waist, cy + waist)   # bottom → left
    ctrl_lt = (cx - waist, cy - waist)   # left → top

    sparkle_pts = []
    sparkle_pts += quad_bezier(top, ctrl_tr, right, 24)
    sparkle_pts += quad_bezier(right, ctrl_rb, bottom, 24)[1:]
    sparkle_pts += quad_bezier(bottom, ctrl_bl, left, 24)[1:]
    sparkle_pts += quad_bezier(left, ctrl_lt, top, 24)[1:]

    sd.polygon(sparkle_pts, fill=(*sparkle_color, 255))

    # ── Glow ──
    glow = shape_layer.filter(ImageFilter.GaussianBlur(radius=35))
    glow2 = glow.filter(ImageFilter.GaussianBlur(radius=20))

    # ── Composite ──
    icon = Image.new("RGBA", (CANVAS, CANVAS), (*BG_COLOR, 255))
    icon = Image.alpha_composite(icon, glow2)
    icon = Image.alpha_composite(icon, glow)
    icon = Image.alpha_composite(icon, shape_layer)

    # Flatten
    final = Image.new("RGB", (CANVAS, CANVAS), BG_COLOR)
    final.paste(icon, mask=icon.split()[3])
    return final


if __name__ == "__main__":
    out_path = Path(__file__).parent / "Glyph" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    icon = generate_icon()
    icon.save(str(out_path), "PNG")
    print(f"✅ Saved app icon to {out_path}  ({CANVAS}×{CANVAS})")
