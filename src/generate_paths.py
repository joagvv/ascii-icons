import json
import sys
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

from icons import ICONS

SRC = Path(__file__).parent
FONT = SRC / "JetBrainsMono-Bold.woff2"
OUT = SRC / "paths.json"

CANVAS = 64


def font_size(text):
    if len(text) <= 2:
        return 30
    if len(text) == 3:
        return 24
    return 15


def fmt(value):
    return f"{value:.2f}".rstrip("0").rstrip(".")


def text_bounds(glyphs, cmap, text):
    pen = BoundsPen(glyphs)
    x = 0
    for ch in text:
        glyph = glyphs[cmap[ord(ch)]]
        glyph.draw(TransformPen(pen, (1, 0, 0, 1, x, 0)))
        x += glyph.width
    return pen.bounds


def text_path(glyphs, cmap, upm, text):
    scale = font_size(text) / upm
    xmin, ymin, xmax, ymax = text_bounds(glyphs, cmap, text)
    cx, cy = (xmin + xmax) / 2, (ymin + ymax) / 2
    center = CANVAS / 2

    pen = SVGPathPen(glyphs, ntos=fmt)
    x = 0
    for ch in text:
        glyph = glyphs[cmap[ord(ch)]]
        matrix = (scale, 0, 0, -scale, center + (x - cx) * scale, center + cy * scale)
        glyph.draw(TransformPen(pen, matrix))
        x += glyph.width
    return pen.getCommands()


def main():
    font = TTFont(sys.argv[1] if len(sys.argv) > 1 else FONT)
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    upm = font["head"].unitsPerEm
    paths = {key: text_path(glyphs, cmap, upm, icon["text"]) for key, icon in ICONS.items()}
    OUT.write_text(json.dumps(paths, indent=2) + "\n")


if __name__ == "__main__":
    main()
