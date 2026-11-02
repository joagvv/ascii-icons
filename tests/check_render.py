"""Check the icons install.sh wrote against the Python renderer."""

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from catalog import build  # noqa: E402
from render import load, paths  # noqa: E402

INNER = re.compile(r'<g fill="[^"]+">(.*)</g></svg>')


def main():
    theme = Path(sys.argv[1]) / "scalable"
    font = load()
    catalog = build()
    # Case-insensitive filesystems keep one of JabRef.svg and jabref.svg.
    seen = {}
    for _, _, names in catalog:
        for name in names:
            seen[name.lower()] = seen.get(name.lower(), 0) + 1
    failures = 0
    for context, text, names in catalog:
        for name in names:
            if seen[name.lower()] > 1:
                continue
            svg = (theme / context / f"{name}.svg").read_text()
            if INNER.search(svg).group(1) != paths(text, font):
                print(f"{context}/{name}.svg doesn't draw {text!r}")
                failures += 1
    if failures:
        sys.exit(1)


if __name__ == "__main__":
    main()
