"""Extract outlines for printable ASCII from the font into glyphs.json.

Coordinates stay in font units; the installer scales and places them.
"""

import json
import sys
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.ttLib import TTFont

SRC = Path(__file__).parent
FONT = SRC / "JetBrainsMono-Bold.woff2"
OUT = SRC / "glyphs.json"


def fmt(value):
    return f"{value:.2f}".rstrip("0").rstrip(".")


def main():
    font = TTFont(sys.argv[1] if len(sys.argv) > 1 else FONT)
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()

    chars = {}
    for code in range(32, 127):
        glyph = glyphs[cmap[code]]
        bounds = BoundsPen(glyphs)
        glyph.draw(bounds)
        path = SVGPathPen(glyphs, ntos=fmt)
        glyph.draw(path)
        chars[chr(code)] = {
            "bounds": [round(v, 2) for v in bounds.bounds] if bounds.bounds else None,
            "path": path.getCommands(),
        }

    data = {
        "unitsPerEm": font["head"].unitsPerEm,
        "advance": glyphs[cmap[ord("0")]].width,
        "chars": chars,
    }
    OUT.write_text(json.dumps(data, indent=1) + "\n")


if __name__ == "__main__":
    main()
