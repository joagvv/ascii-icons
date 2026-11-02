import json
import sys
from pathlib import Path

from icons import ICONS

SRC = Path(__file__).parent
ROOT = SRC.parent
PATHS = SRC / "paths.json"
TEMPLATE = SRC / "install.sh.in"
OUT = ROOT / "install.sh"


def bash_array(name, values):
    return "\n".join(f"{name}[{key}]='{value}'" for key, value in values.items())


def main():
    paths = json.loads(PATHS.read_text())
    missing = ICONS.keys() - paths.keys()
    if missing:
        sys.exit(f"no path for {', '.join(sorted(missing))}; run generate_paths.py")

    tables = "\n".join([
        bash_array("GLYPH", {key: paths[key] for key in ICONS}),
        bash_array("CONTEXT", {key: icon["context"] for key, icon in ICONS.items()}),
        bash_array("NAMES", {key: " ".join(icon["names"]) for key, icon in ICONS.items()}),
    ])
    script = TEMPLATE.read_text().replace("@ICONS@", tables)
    OUT.write_text(script)
    OUT.chmod(0o755)


if __name__ == "__main__":
    main()
