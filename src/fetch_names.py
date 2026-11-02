"""Collect application icon names from upstream icon themes.

Writes src/names.txt with one line per application: the icon's own name
followed by every alias that points at it. Only trees and symlink targets
are downloaded, not the icons themselves.
"""

import subprocess
import tempfile
from pathlib import Path

SRC = Path(__file__).parent
OUT = SRC / "names.txt"

THEMES = [
    ("https://github.com/PapirusDevelopmentTeam/papirus-icon-theme.git",
     ["Papirus/64x64/apps"]),
    ("https://github.com/shimmerproject/elementary-xfce.git",
     ["elementary-xfce/apps/48", "elementary-xfce/categories/48"]),
]


def git(repo, *args, stdin=None):
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        input=stdin, capture_output=True, check=True,
    ).stdout


def icon_name(filename):
    return filename.rsplit("/", 1)[-1].removesuffix(".svg")


def read_theme(url, dirs, workdir):
    """Return {name: target} where target is None for real files."""
    repo = workdir / url.rsplit("/", 1)[-1]
    # Symlinks are a few bytes each; the 200 byte limit skips the SVGs.
    subprocess.run(
        ["git", "clone", "-q", "--bare", "--depth", "1",
         "--filter=blob:limit=200", url, str(repo)],
        check=True,
    )
    entries = {}
    links = {}
    for line in git(repo, "ls-tree", "-z", "HEAD", *[d + "/" for d in dirs]).split(b"\0"):
        if not line:
            continue
        meta, path = line.decode().split("\t", 1)
        mode, _, sha = meta.split()
        if not path.endswith(".svg"):
            continue
        name = icon_name(path)
        if mode == "120000":
            links[name] = sha
        else:
            entries.setdefault(name, None)

    batch = git(repo, "cat-file", "--batch", stdin="\n".join(links.values()).encode() + b"\n")
    targets = {}
    pos = 0
    while pos < len(batch):
        header_end = batch.index(b"\n", pos)
        sha, _, size = batch[pos:header_end].decode().split()
        start = header_end + 1
        targets[sha] = batch[start:start + int(size)].decode()
        pos = start + int(size) + 1
    for name, sha in links.items():
        entries[name] = icon_name(targets[sha])
    return entries


def resolve(entries, name):
    seen = set()
    while entries.get(name) is not None and name not in seen:
        seen.add(name)
        name = entries[name]
    return name


def main():
    groups = {}
    owner = {}
    with tempfile.TemporaryDirectory() as tmp:
        for url, dirs in THEMES:
            entries = read_theme(url, dirs, Path(tmp))
            theme_groups = {}
            for name in entries:
                theme_groups.setdefault(resolve(entries, name), set()).add(name)
            for canonical, names in theme_groups.items():
                names.add(canonical)
                # An alias another theme already knows joins that group.
                known = next((owner[n] for n in sorted(names) if n in owner), canonical)
                groups.setdefault(known, set()).update(names)
                for n in names:
                    owner.setdefault(n, known)

    lines = []
    for canonical in sorted(groups, key=str.lower):
        aliases = sorted(groups[canonical] - {canonical}, key=str.lower)
        lines.append(" ".join([canonical, *aliases]))
    OUT.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
