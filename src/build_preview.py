import json
from pathlib import Path

from icons import ICONS

SRC = Path(__file__).parent
PATHS = SRC / "paths.json"
OUT = SRC.parent / "assets" / "preview.svg"

# Same values as the presets and defaults in install.sh.in.
TILE = "#0b0b10"
BORDER = "#2c2c38"
ROWS = [
    ("#ececf2", True),
    ("#e8364a", True),
    ("#2bb7d8", False),
]

ICON = 88
PITCH = 120
MARGIN = 28
BACKGROUND = "#16161e"


def icon(path, x, y, fg, tiled):
    scale = ICON / 64
    parts = [f'<g transform="translate({x} {y}) scale({scale})">']
    if tiled:
        parts.append(
            f'<rect x="4" y="4" width="56" height="56" rx="12" fill="{TILE}" '
            f'stroke="{BORDER}" stroke-width="1.5"/>'
        )
    parts.append(f'<path d="{path}" fill="{fg}"/></g>')
    return "".join(parts)


def main():
    paths = json.loads(PATHS.read_text())
    cols = len(ICONS)
    width = 2 * MARGIN + (cols - 1) * PITCH + ICON
    height = 2 * MARGIN + (len(ROWS) - 1) * PITCH + ICON

    lines = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}">',
        f'<rect width="{width}" height="{height}" rx="16" fill="{BACKGROUND}"/>',
    ]
    for row, (fg, tiled) in enumerate(ROWS):
        y = MARGIN + row * PITCH
        for col, key in enumerate(ICONS):
            lines.append(icon(paths[key], MARGIN + col * PITCH, y, fg, tiled))
    lines.append("</svg>")
    OUT.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
