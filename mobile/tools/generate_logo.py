"""Generate high-resolution Zennyt logo assets from vector geometry.

Recreates the Logo.png mark (G-ring + up-right arrow) as crisp SVG/PNG.
Run from the mobile/ directory: python tools/generate_logo.py
"""

from __future__ import annotations

import math
from pathlib import Path

import cairosvg

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "images"

# Geometry tuned to match the original 76x68 Logo.png pixel art.
VIEW_W, VIEW_H = 76, 68
CX, CY = 37.0, 34.0
STROKE = 14.5
R = 21.5

# Gap at the top-right (degrees, 0 = right, clockwise positive).
GAP_START = -62.0
GAP_END = 14.0
ARROW_TIP = -42.0


def _pt(radius: float, degrees: float) -> tuple[float, float]:
    rad = math.radians(degrees)
    return CX + radius * math.cos(rad), CY + radius * math.sin(rad)


def _arc_path(cx: float, cy: float, r: float, start_deg: float, end_deg: float) -> str:
    """SVG arc from start_deg to end_deg, clockwise."""
    x1, y1 = _pt(r, start_deg)
    x2, y2 = _pt(r, end_deg)
    sweep = end_deg - start_deg
    if sweep < 0:
        sweep += 360
    large = 1 if sweep > 180 else 0
    return f"M {x1:.3f} {y1:.3f} A {r:.3f} {r:.3f} 0 {large} 1 {x2:.3f} {y2:.3f}"


def _arrow_path() -> str:
  tip = _pt(R + STROKE * 0.95, ARROW_TIP)
  base_l = _pt(R - STROKE * 0.22, ARROW_TIP - 28)
  base_r = _pt(R - STROKE * 0.22, ARROW_TIP + 28)
  return (
      f"M {tip[0]:.3f} {tip[1]:.3f} "
      f"L {base_l[0]:.3f} {base_l[1]:.3f} "
      f"L {base_r[0]:.3f} {base_r[1]:.3f} Z"
  )


def build_svg(*, transparent: bool = True) -> str:
    bg = "none" if transparent else "#000000"
    ring = _arc_path(CX, CY, R, GAP_END, GAP_START)
    arrow = _arrow_path()

    return f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {VIEW_W} {VIEW_H}" width="{VIEW_W}" height="{VIEW_H}">
  <defs>
    <linearGradient id="zennyt-grad" x1="8%" y1="92%" x2="92%" y2="8%">
      <stop offset="0%" stop-color="#183B7F"/>
      <stop offset="28%" stop-color="#21438A"/>
      <stop offset="48%" stop-color="#5046E5"/>
      <stop offset="68%" stop-color="#7B3FD4"/>
      <stop offset="100%" stop-color="#DE1482"/>
    </linearGradient>
  </defs>
  <rect width="100%" height="100%" fill="{bg}"/>
  <path d="{ring}" fill="none" stroke="url(#zennyt-grad)" stroke-width="{STROKE}"
        stroke-linecap="round" stroke-linejoin="round"/>
  <path d="{arrow}" fill="url(#zennyt-grad)" stroke="none"/>
</svg>
"""


def _svg_to_png(svg: str, out: Path, size: int) -> None:
    cairosvg.svg2png(
        bytestring=svg.encode("utf-8"),
        write_to=str(out),
        output_width=size,
        output_height=int(size * VIEW_H / VIEW_W),
    )


def _logo_on_square(svg_transparent: str, out: Path, size: int, bg: str) -> None:
    """Rasterize logo mark centered on a square canvas (for launcher icons)."""
    logo_h = int(size * 0.72)
    logo_w = int(logo_h * VIEW_W / VIEW_H)
    pad_x = (size - logo_w) // 2
    pad_y = (size - logo_h) // 2

    inner_svg = svg_transparent.split("<svg", 1)[1].split(">", 1)[1].rsplit("</svg>", 1)[0]
    square_svg = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" width="{size}" height="{size}">
  <rect width="100%" height="100%" fill="{bg}"/>
  <svg x="{pad_x}" y="{pad_y}" width="{logo_w}" height="{logo_h}" viewBox="0 0 {VIEW_W} {VIEW_H}">
    {inner_svg}
  </svg>
</svg>"""
    cairosvg.svg2png(bytestring=square_svg.encode("utf-8"), write_to=str(out), output_width=size, output_height=size)


def main() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)

    svg_transparent = build_svg(transparent=True)
    svg_black = build_svg(transparent=False)

    (ASSETS / "Logo.svg").write_text(svg_transparent, encoding="utf-8")

    # High-res in-app asset (4x scale of original proportions).
    _svg_to_png(svg_transparent, ASSETS / "Logo.png", size=1024)

    # Square launcher source on brand navy.
    _logo_on_square(svg_transparent, ASSETS / "app_icon.png", size=1024, bg="#001D55")

    print("Generated:")
    print(f"  {ASSETS / 'Logo.svg'}")
    print(f"  {ASSETS / 'Logo.png'}  (1024x{int(1024 * VIEW_H / VIEW_W)})")
    print(f"  {ASSETS / 'app_icon.png'}  (1024x1024)")


if __name__ == "__main__":
    main()
