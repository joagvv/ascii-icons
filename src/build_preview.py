from pathlib import Path

from render import load, paths

OUT = Path(__file__).parent.parent / "assets" / "preview.svg"

# Same values as the presets and defaults in install.sh.in.
TILE = "#0b0b10"
BORDER = "#2c2c38"
ROWS = [
    ("#ececf2", True, [">_", "://", "~/", "</>", "/\\/", "rm", "cfg", "top", "12:00", ".md", "/?", "~$"]),
    ("#e8364a", True, ["|>", "@", "+-", ".pdf", ".png", "pkg", ".zip", "[ ]", "***", "cal", "man", "Aa"]),
    ("#2bb7d8", False, ["gimp", "ink", "obs", "dc", "tg", "3d", "vm", "fun", "git", "kdn", "p2p", "sql"]),
]

ICON = 88
PITCH = 120
MARGIN = 28
BACKGROUND = "#16161e"


def icon(text, font, x, y, fg, tiled):
    parts = [f'<g transform="translate({x} {y}) scale({ICON / 64})">']
    if tiled:
        parts.append(
            f'<rect x="4" y="4" width="56" height="56" rx="12" fill="{TILE}" '
            f'stroke="{BORDER}" stroke-width="1.5"/>'
        )
    parts.append(f'<g fill="{fg}">{paths(text, font)}</g></g>')
    return "".join(parts)


def main():
    font = load()
    cols = max(len(texts) for _, _, texts in ROWS)
    width = 2 * MARGIN + (cols - 1) * PITCH + ICON
    height = 2 * MARGIN + (len(ROWS) - 1) * PITCH + ICON

    lines = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}">',
        f'<rect width="{width}" height="{height}" rx="16" fill="{BACKGROUND}"/>',
    ]
    for row, (fg, tiled, texts) in enumerate(ROWS):
        for col, text in enumerate(texts):
            lines.append(icon(text, font, MARGIN + col * PITCH, MARGIN + row * PITCH, fg, tiled))
    lines.append("</svg>")
    OUT.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
