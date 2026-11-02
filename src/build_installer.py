import json
from pathlib import Path

from catalog import build

SRC = Path(__file__).parent
ROOT = SRC.parent
GLYPHS = SRC / "glyphs.json"
TEMPLATE = SRC / "install.sh.in"
OUT = ROOT / "install.sh"


def main():
    font = json.loads(GLYPHS.read_text())
    glyphs = []
    for char, glyph in font["chars"].items():
        bounds = " ".join(str(v) for v in glyph["bounds"]) if glyph["bounds"] else "-"
        glyphs.append(f"{ord(char)}\t{bounds}\t{glyph['path']}")

    icons = []
    for context, text, names in build():
        missing = set(text) - set(font["chars"])
        if missing:
            raise SystemExit(f"no glyph for {''.join(sorted(missing))!r} in {text!r}")
        icons.append(f"{context}\t{text}\t{' '.join(names)}")

    script = (
        TEMPLATE.read_text()
        .replace("@GLYPHS@", "\n".join(glyphs))
        .replace("@ICONS@", "\n".join(icons))
        .replace("@UNITS_PER_EM@", str(font["unitsPerEm"]))
        .replace("@ADVANCE@", str(font["advance"]))
    )
    OUT.write_text(script)
    OUT.chmod(0o755)


if __name__ == "__main__":
    main()
