"""Derive a short text label from an icon name.

Short names are kept as they are ("vlc", "gimp"), multi-word names become
initials ("visual-studio-code" -> "vsc") and longer single words are cut
down to their first letter and next consonants ("discord" -> "dsc"),
the way Unix commands tend to be named.
"""

import re

from icons import WORDS

MAX_LENGTH = 4
VOWELS = set("aeiou")

# Leading parts of reverse-DNS application ids.
DOMAINS = {
    "app", "ca", "cc", "ch", "com", "de", "dev", "eu", "fi", "fr", "info",
    "io", "it", "me", "net", "nl", "org", "page", "pm", "ru", "se", "uk", "xyz",
}

# Freedesktop name prefixes in front of the part that tells icons apart.
PREFIXES = (
    "preferences-desktop-", "preferences-system-", "preferences-",
    "applications-", "accessories-", "utilities-", "applets-", "system-",
)

# Words that say nothing about which application it is.
NOISE = {
    "app", "application", "beta", "bin", "client", "desktop", "flatpak",
    "gnome", "gtk", "gtk3", "icon", "kde", "launcher", "linux", "nightly",
    "preview", "qt", "qt5", "stable", "the", "xfce", "xfce4",
}


def words(name):
    for prefix in PREFIXES:
        if name.startswith(prefix) and len(name) > len(prefix):
            name = name[len(prefix):]
            break
    parts = name.split(".")
    if len(parts) > 2 and parts[0].lower() in DOMAINS:
        # org.gnome.Nautilus -> Nautilus, com.github.user.Tool -> Tool
        parts = [parts[-1]]
    text = " ".join(parts)
    text = re.sub(r"([a-z])([A-Z])", r"\1 \2", text)
    found = [w for w in re.split(r"[^a-z0-9]+", text.lower()) if w]
    kept = [w for w in found if w not in NOISE]
    return kept or found


def squeeze(word):
    """discord -> dsc, telegram -> tlg"""
    out = word[0]
    for ch in word[1:]:
        if len(out) == 3:
            break
        if ch not in VOWELS and ch != out[-1]:
            out += ch
    return out if len(out) >= 2 else word[:3]


def label(name):
    found = words(name)
    if not found:
        return "?"
    if len(found) == 1:
        word = found[0]
        if word in WORDS:
            return WORDS[word]
        return word if len(word) <= MAX_LENGTH else squeeze(word)
    return "".join(w[0] for w in found[:3])
