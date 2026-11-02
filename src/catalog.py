"""Decide which text every icon name gets.

Returns a list of (context, text, names) entries, built from the
application groups in names.txt and the hand-picked rules in icons.py.
"""

import re
from pathlib import Path

from icons import LABELS, ROLES
from labels import label

SRC = Path(__file__).parent
NAMES = SRC / "names.txt"
VALID_NAME = re.compile(r"^[A-Za-z0-9._+-]+$")


def role_of(name):
    for key, role in ROLES.items():
        if name in role["names"]:
            return key
    for key, role in ROLES.items():
        if any(name.startswith(p) for p in role.get("prefixes", ())):
            return key
    return None


def load_groups():
    return [line.split() for line in NAMES.read_text().splitlines() if line.strip()]


def build():
    entries = {}
    taken = set()

    def add(context, text, names):
        fresh = [n for n in names if n not in taken and VALID_NAME.match(n)]
        taken.update(fresh)
        if fresh:
            entries.setdefault((context, text), []).extend(fresh)

    def add_role(key, names):
        role = ROLES[key]
        add(role.get("context", "apps"), role["text"], names)

    # Names listed by hand come first so a group can't claim them.
    for key, role in ROLES.items():
        add_role(key, role["names"])

    # The same application can show up as JabRef in one group and jabref
    # in another; both should get the same text.
    seen = {}
    for group in load_groups():
        key = next((k for k in map(role_of, group) if k), None)
        if key:
            add_role(key, group)
            continue
        text = next((LABELS[n] for n in group if n in LABELS), None)
        text = text or next((seen[n.lower()] for n in group if n.lower() in seen), None)
        text = text or label(group[0])
        seen.update((n.lower(), text) for n in group)
        add("apps", text, group)

    for name, text in LABELS.items():
        add("apps", text, [name])

    return [(context, text, sorted(names, key=str.lower))
            for (context, text), names in sorted(entries.items())]
