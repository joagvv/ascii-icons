"""Python version of the layout the installer does in awk.

Used to draw the preview and to check the installer's output.
"""

import json
from pathlib import Path

GLYPHS = Path(__file__).parent / "glyphs.json"
SIZES = [30, 30, 24, 18, 15]


def num(value):
    text = f"{value:.3f}".rstrip("0").rstrip(".")
    return "0" if text == "-0" else text


def load():
    return json.loads(GLYPHS.read_text())


def paths(text, font):
    """SVG path elements drawing text centered in a 64x64 box."""
    chars = font["chars"]
    advance = font["advance"]
    scale = SIZES[min(len(text), 5) - 1] / font["unitsPerEm"]

    boxes = [(i * advance, chars[c]["bounds"]) for i, c in enumerate(text) if chars[c]["bounds"]]
    x0 = min(x + b[0] for x, b in boxes)
    y0 = min(b[1] for _, b in boxes)
    x1 = max(x + b[2] for x, b in boxes)
    y1 = max(b[3] for _, b in boxes)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2

    out = []
    for i, c in enumerate(text):
        if not chars[c]["path"]:
            continue
        out.append(
            f'<path transform="matrix({num(scale)} 0 0 {num(-scale)} '
            f'{num(32 + (i * advance - cx) * scale)} {num(32 + cy * scale)})" '
            f'd="{chars[c]["path"]}"/>'
        )
    return "".join(out)
