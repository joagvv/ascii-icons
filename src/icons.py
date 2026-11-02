"""Icon definitions shared by the build scripts.

Each entry maps a key to the text drawn on the icon, the theme context
directory it is written to, and the icon names it replaces.
"""

ICONS = {
    "terminal": {
        "text": ">_",
        "context": "apps",
        "names": [
            "utilities-terminal", "Alacritty", "alacritty", "org.xfce.terminal",
            "org.xfce.terminalemulator", "xfce4-terminal", "terminal",
            "org.gnome.Terminal", "org.gnome.Console", "kitty", "foot",
        ],
    },
    "browser": {
        "text": "://",
        "context": "apps",
        "names": [
            "firefox", "web-browser", "internet-web-browser", "org.xfce.webbrowser",
            "applications-internet", "chromium", "google-chrome", "brave-browser",
        ],
    },
    "folder": {
        "text": "~/",
        "context": "apps",
        "names": [
            "org.xfce.thunar", "org.xfce.filemanager", "system-file-manager",
            "thunar", "Thunar", "file-manager", "org.gnome.Nautilus", "nemo",
            "pcmanfm",
        ],
    },
    "code": {
        "text": "</>",
        "context": "apps",
        "names": [
            "code", "visual-studio-code", "com.visualstudio.code", "vscodium",
            "applications-development", "nvim",
        ],
    },
    "music": {
        "text": "/\\/",
        "context": "apps",
        "names": [
            "multimedia-audio-player", "audio-player", "spotify",
            "applications-multimedia", "org.xfce.parole", "parole",
        ],
    },
    "trash": {
        "text": "rm",
        "context": "places",
        "names": ["user-trash", "user-trash-full", "org.xfce.trash"],
    },
    "settings": {
        "text": "cfg",
        "context": "apps",
        "names": [
            "org.xfce.settings.manager", "xfce4-settings-manager", "preferences-system",
            "preferences-desktop", "applications-system", "system-settings",
            "org.gnome.Settings",
        ],
    },
    "monitor": {
        "text": "top",
        "context": "apps",
        "names": [
            "org.xfce.taskmanager", "utilities-system-monitor", "xfce4-taskmanager",
            "htop", "btop", "org.gnome.SystemMonitor",
        ],
    },
    "clock": {
        "text": "12:00",
        "context": "apps",
        "names": [
            "org.xfce.panel.clock", "preferences-system-time", "clock", "xfce4-clock",
        ],
    },
    "notes": {
        "text": ".md",
        "context": "apps",
        "names": [
            "org.xfce.mousepad", "accessories-text-editor", "mousepad", "text-editor",
            "obsidian", "libreoffice-writer", "org.gnome.TextEditor", "gedit",
        ],
    },
    "search": {
        "text": "/?",
        "context": "apps",
        "names": ["org.xfce.appfinder", "system-search", "xfce4-appfinder"],
    },
    "menu": {
        "text": "~$",
        "context": "apps",
        "names": [
            "start-here", "org.xfce.panel.applicationsmenu", "org.xfce.panel.whiskermenu",
            "xfce4-whiskermenu", "xfce4-panel-menu", "archlinux-logo",
            "distributor-logo-archlinux",
        ],
    },
}
