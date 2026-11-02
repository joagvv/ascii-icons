import json
from pathlib import Path

SRC = Path(__file__).parent
ROOT = SRC.parent
PATHS = SRC / "paths.json"
TEMPLATE = SRC / "install.sh.in"
OUT = ROOT / "install.sh"

NAMES = {
    "terminal": [
        "utilities-terminal", "Alacritty", "alacritty", "org.xfce.terminal",
        "org.xfce.terminalemulator", "xfce4-terminal", "terminal",
    ],
    "browser": [
        "firefox", "web-browser", "internet-web-browser", "org.xfce.webbrowser",
        "applications-internet",
    ],
    "folder": [
        "org.xfce.thunar", "org.xfce.filemanager", "system-file-manager",
        "thunar", "Thunar", "file-manager",
    ],
    "code": [
        "code", "visual-studio-code", "com.visualstudio.code", "vscodium",
        "applications-development", "nvim",
    ],
    "music": [
        "multimedia-audio-player", "audio-player", "spotify",
        "applications-multimedia", "org.xfce.parole", "parole",
    ],
    "trash": ["user-trash", "user-trash-full", "org.xfce.trash"],
    "settings": [
        "org.xfce.settings.manager", "xfce4-settings-manager", "preferences-system",
        "preferences-desktop", "applications-system", "system-settings",
    ],
    "monitor": [
        "org.xfce.taskmanager", "utilities-system-monitor", "xfce4-taskmanager",
        "htop", "btop", "timeshift",
    ],
    "clock": ["org.xfce.panel.clock", "preferences-system-time", "clock", "xfce4-clock"],
    "notes": [
        "org.xfce.mousepad", "accessories-text-editor", "mousepad", "text-editor",
        "obsidian", "libreoffice-writer",
    ],
    "search": ["org.xfce.appfinder", "system-search", "xfce4-appfinder"],
    "menu": [
        "start-here", "org.xfce.panel.applicationsmenu", "org.xfce.panel.whiskermenu",
        "xfce4-whiskermenu", "xfce4-panel-menu", "archlinux-logo",
        "distributor-logo-archlinux",
    ],
}


def main():
    paths = json.loads(PATHS.read_text())
    glyphs = "\n".join(f"GLYPH[{key}]='{value}'" for key, value in paths.items())
    names = "\n".join(f"NAMES[{key}]='{' '.join(value)}'" for key, value in NAMES.items())
    script = TEMPLATE.read_text().replace("@GLYPHS@", glyphs).replace("@NAMES@", names)
    OUT.write_text(script)
    OUT.chmod(0o755)


if __name__ == "__main__":
    main()
