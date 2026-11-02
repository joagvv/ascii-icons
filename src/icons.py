"""Hand-picked icons.

ROLES give every application of one kind the same glyph. A role applies to
an icon name listed here and to every alias of it in names.txt, so listing
one well-known name usually covers the rest of its group. Names that start
with one of a role's prefixes are matched too.

LABELS override the generated label of a single application, and WORDS
override how one word is shortened wherever it appears.
"""

ROLES = {
    "unknown": {
        "text": "?",
        "names": [
            "application-default-icon", "application-x-executable", "unknown",
            "image-missing", "application-x-generic",
        ],
    },
    "terminal": {
        "text": ">_",
        "names": [
            "utilities-terminal", "utilities-x-terminal", "terminal", "Alacritty",
            "alacritty", "org.xfce.terminal", "org.xfce.terminalemulator",
            "xfce4-terminal", "org.gnome.Terminal", "org.gnome.Console",
            "org.gnome.Ptyxis", "kitty", "foot", "konsole", "org.kde.konsole",
            "yakuake", "org.kde.yakuake", "guake", "tilix", "com.gexperts.Tilix",
            "terminator", "xterm", "uxterm", "urxvt", "rxvt-unicode", "st",
            "wezterm", "org.wezfurlong.wezterm", "com.mitchellh.ghostty",
            "ghostty", "com.raggesilver.BlackBox", "lxterminal", "qterminal",
            "mate-terminal", "deepin-terminal", "cool-retro-term", "terminology",
            "sakura", "termite", "contour", "rio",
        ],
    },
    "browser": {
        "text": "://",
        "names": [
            "web-browser", "internet-web-browser", "applications-internet",
            "org.xfce.webbrowser", "firefox", "firefox-esr", "firefox-developer-edition",
            "org.mozilla.firefox", "chromium", "chromium-browser", "org.chromium.Chromium",
            "google-chrome", "google-chrome-beta", "google-chrome-unstable",
            "com.google.Chrome", "brave", "brave-browser", "com.brave.Browser",
            "vivaldi", "com.vivaldi.Vivaldi", "opera", "librewolf",
            "io.gitlab.librewolf-community", "waterfox", "floorp", "zen-browser",
            "app.zen_browser.zen", "epiphany", "org.gnome.Epiphany", "falkon",
            "org.kde.falkon", "konqueror", "midori", "qutebrowser",
            "org.qutebrowser.qutebrowser", "torbrowser", "torbrowser-launcher",
            "tor-browser", "microsoft-edge", "palemoon", "seamonkey", "min",
            "ungoogled-chromium", "thorium-browser", "mullvad-browser",
        ],
    },
    "folder": {
        "text": "~/",
        "names": [
            "system-file-manager", "file-manager", "org.xfce.thunar",
            "org.xfce.filemanager", "thunar", "Thunar", "org.gnome.Nautilus",
            "nautilus", "nemo", "caja", "pcmanfm", "pcmanfm-qt", "dolphin",
            "org.kde.dolphin", "krusader", "org.kde.krusader", "doublecmd",
            "spacefm", "io.elementary.files", "deepin-file-manager", "nnn",
            "ranger", "yazi",
        ],
    },
    "code": {
        "text": "</>",
        "names": [
            "applications-development", "code", "vscode", "visual-studio-code",
            "com.visualstudio.code", "code-oss", "vscodium", "com.vscodium.codium",
            "codium", "nvim", "neovim", "vim", "gvim", "emacs", "sublime-text",
            "com.sublimetext.three", "atom", "zed", "dev.zed.Zed", "geany",
            "org.geany.Geany", "kdevelop", "org.gnome.Builder", "lapce",
            "dev.lapce.lapce", "helix", "cursor", "windsurf",
        ],
    },
    "notes": {
        "text": ".md",
        "names": [
            "accessories-text-editor", "text-editor", "org.xfce.mousepad", "mousepad",
            "gedit", "org.gnome.gedit", "org.gnome.TextEditor", "kate", "org.kde.kate",
            "kwrite", "org.kde.kwrite", "pluma", "xed", "featherpad", "notepadqq",
            "leafpad", "l3afpad", "obsidian", "md.obsidian.Obsidian", "joplin",
            "net.cozic.joplin_desktop", "logseq", "com.logseq.Logseq", "marktext",
            "ghostwriter", "apostrophe", "org.gnome.gitlab.somas.Apostrophe",
            "typora", "zettlr", "notion", "simplenote", "standard-notes", "notes",
            "xpad", "knotes", "gnote", "tomboy",
        ],
    },
    "music": {
        "text": "/\\/",
        "names": [
            "multimedia-audio-player", "audio-player", "applications-multimedia",
            "spotify", "spotify-client", "com.spotify.Client", "rhythmbox",
            "org.gnome.Rhythmbox3", "elisa", "org.kde.elisa", "lollypop",
            "strawberry", "clementine", "amarok", "audacious", "deadbeef",
            "quodlibet", "gnome-music", "org.gnome.Music", "cantata", "juk",
            "exaile", "guayadeque", "cmus", "ncmpcpp", "tauon", "g4music",
            "com.github.neithern.g4music", "tidal-hifi", "youtube-music",
            "spotube", "amberol", "io.bassi.Amberol", "musique", "sayonara",
            "harmonoid",
        ],
    },
    "video": {
        "text": "|>",
        "names": [
            "multimedia-video-player", "video-player", "vlc", "org.videolan.VLC",
            "mpv", "io.mpv.Mpv", "totem", "org.gnome.Totem", "celluloid",
            "io.github.celluloid_player.Celluloid", "smplayer", "haruna",
            "org.kde.haruna", "dragonplayer", "org.kde.dragonplayer", "kaffeine",
            "mplayer", "gnome-mplayer", "parole", "org.xfce.parole", "clapper",
            "com.github.rafostar.Clapper", "showtime", "org.gnome.Showtime",
            "xplayer", "mpc-qt", "qmplay2", "kodi", "stremio", "jellyfin-media-player",
            "plex", "freetube",
        ],
    },
    "image": {
        "text": ".png",
        "names": [
            "image-viewer", "eog", "org.gnome.eog", "org.gnome.Loupe", "loupe",
            "gwenview", "org.kde.gwenview", "ristretto", "org.xfce.ristretto",
            "shotwell", "org.gnome.Shotwell", "nomacs", "gthumb", "xviewer", "eom",
            "feh", "sxiv", "nsxiv", "imv", "qimgv", "geeqie", "gpicview", "lximage-qt",
            "viewnior", "mirage", "oculante", "image-roll",
        ],
    },
    "document": {
        "text": ".pdf",
        "names": [
            "evince", "org.gnome.Evince", "okular", "org.kde.okular", "atril",
            "xreader", "zathura", "org.pwmt.zathura", "papers", "org.gnome.Papers",
            "qpdfview", "mupdf", "epdfview", "pdfarranger", "com.github.jeromerobert.pdfarranger",
            "masterpdfeditor5", "xournalpp", "com.github.xournalpp.xournalpp",
            "sioyek", "foxitreader",
        ],
    },
    "ebook": {
        "text": ".epub",
        "names": [
            "accessories-ebook-reader", "calibre", "calibre-gui", "foliate",
            "com.github.johnfactotum.Foliate", "bookworm", "koodo-reader",
        ],
    },
    "mail": {
        "text": "@",
        "names": [
            "internet-mail", "mail-client", "thunderbird", "org.mozilla.Thunderbird",
            "betterbird", "evolution", "org.gnome.Evolution", "geary",
            "org.gnome.Geary", "kmail", "org.kde.kmail2", "mailspring", "claws-mail",
            "sylpheed", "trojita", "kube", "mutt", "neomutt", "aerc", "tutanota-desktop",
            "protonmail-bridge", "electron-mail",
        ],
    },
    "calculator": {
        "text": "+-",
        "names": [
            "accessories-calculator", "gnome-calculator", "org.gnome.Calculator",
            "kcalc", "org.kde.kcalc", "galculator", "qalculate", "qalculate-gtk",
            "qalculate-qt", "mate-calc", "speedcrunch", "io.elementary.calculator",
            "kalk", "org.kde.kalk", "xcalc", "deepin-calculator",
        ],
    },
    "calendar": {
        "text": "cal",
        "names": [
            "office-calendar", "calendar", "gnome-calendar", "org.gnome.Calendar",
            "korganizer", "org.kde.korganizer", "merkuro", "org.kde.merkuro.calendar",
            "kalendar", "orage", "org.xfce.orage", "evolution-calendar", "calcurse",
            "io.elementary.calendar",
        ],
    },
    "clock": {
        "text": "12:00",
        "names": [
            "org.xfce.panel.clock", "preferences-system-time", "clock", "xfce4-clock",
            "gnome-clocks", "org.gnome.clocks", "kclock", "org.kde.kclock",
            "alarm-clock", "time-admin", "preferences-desktop-time",
        ],
    },
    "trash": {
        "text": "rm",
        "context": "places",
        "names": ["user-trash", "user-trash-full", "org.xfce.trash", "trashcan_full",
                  "trashcan_empty"],
    },
    "settings": {
        "text": "cfg",
        "names": [
            "org.xfce.settings.manager", "xfce4-settings-manager", "preferences-system",
            "preferences-desktop", "applications-system", "system-settings",
            "systemsettings", "org.gnome.Settings", "gnome-control-center",
            "preferences-other", "utilities-tweak-tool", "org.gnome.tweaks",
            "gnome-tweak-tool", "mate-control-center", "lxqt-config", "lxappearance",
            "cinnamon-settings", "budgie-control-center", "nwg-look", "qt5ct", "qt6ct",
            "kvantummanager", "hyprland-settings", "io.elementary.settings",
            "deepin-control-center", "plasma-settings",
        ],
    },
    "monitor": {
        "text": "top",
        "names": [
            "utilities-system-monitor", "org.xfce.taskmanager", "xfce4-taskmanager",
            "htop", "btop", "gnome-system-monitor", "org.gnome.SystemMonitor",
            "ksysguard", "plasma-systemmonitor", "org.kde.plasma-systemmonitor",
            "mate-system-monitor", "lxtask", "qps", "io.missioncenter.MissionCenter",
            "mission-center", "net.nokyan.Resources", "resources", "bottom", "glances",
            "nvtop", "stacer", "system-monitor",
        ],
    },
    "search": {
        "text": "/?",
        "names": [
            "system-search", "org.xfce.appfinder", "xfce4-appfinder", "catfish",
            "org.xfce.catfish", "kfind", "org.kde.kfind", "gnome-search-tool",
            "searchmonkey", "albert", "ulauncher", "rofi", "wofi", "fuzzel", "tofi",
            "krunner", "synapse", "kupfer", "cerebro", "fsearch",
            "io.github.cboxdoerfer.FSearch", "recoll", "baloo",
        ],
    },
    "menu": {
        "text": "~$",
        "names": [
            "start-here", "org.xfce.panel.applicationsmenu", "org.xfce.panel.whiskermenu",
            "xfce4-whiskermenu", "xfce4-panel-menu", "applications-all",
            "kde-start-here", "plasma-start-here", "view-app-grid",
        ],
        "prefixes": ["start-here-", "distributor-logo", "archlinux-logo"],
    },
    "store": {
        "text": "pkg",
        "names": [
            "software-store", "system-software-install", "gnome-software",
            "org.gnome.Software", "plasmadiscover", "org.kde.discover", "pamac",
            "pamac-manager", "pamac-updater", "octopi", "synaptic", "mintinstall",
            "bauh", "flathub", "io.github.flattool.Warehouse", "warehouse",
            "io.elementary.appcenter", "appcenter", "muon", "apper",
            "system-software-update", "update-manager", "mintupdate",
            "software-properties", "gnome-packagekit", "yumex", "dnfdragora",
            "storeup", "deepin-app-store", "cosmic-store",
        ],
    },
    "archive": {
        "text": ".zip",
        "names": [
            "ark", "org.kde.ark", "file-roller", "org.gnome.FileRoller", "engrampa",
            "xarchiver", "peazip", "lxqt-archiver", "squeeze", "io.github.peazip.PeaZip",
            "p7zip", "7zip", "xarchive", "utilities-file-archiver",
        ],
    },
    "disks": {
        "text": "df",
        "names": [
            "gparted", "gnome-disks", "org.gnome.DiskUtility", "partitionmanager",
            "org.kde.partitionmanager", "disk-utility", "gnome-disk-utility",
            "drive-harddisk", "kdiskfree", "usb-creator", "balena-etcher",
            "balenaetcher", "mintstick", "impression", "io.gitlab.adhami3310.Impression",
            "ventoy",
        ],
    },
    "usage": {
        "text": "du",
        "names": [
            "baobab", "org.gnome.baobab", "filelight", "org.kde.filelight",
            "qdirstat", "k4dirstat", "gdmap", "ncdu", "diskonaut", "mate-disk-usage-analyzer",
        ],
    },
    "screenshot": {
        "text": "[ ]",
        "names": [
            "applets-screenshooter", "accessories-screenshot", "screenshot",
            "org.xfce.screenshooter", "xfce4-screenshooter", "gnome-screenshot",
            "org.gnome.Screenshot", "spectacle", "org.kde.spectacle", "flameshot",
            "org.flameshot.Flameshot", "ksnip", "shutter", "grim", "swappy",
            "gradia", "satty", "deepin-screenshot", "mate-screenshot",
        ],
    },
    "volume": {
        "text": "vol",
        "names": [
            "kmix", "pavucontrol", "pavucontrol-qt", "pwvucontrol",
            "com.saivert.pwvucontrol", "multimedia-volume-control", "audio-card",
            "preferences-sound", "preferences-desktop-sound", "gnome-sound-recorder",
            "org.xfce.pulseaudio-plugin", "xfce4-mixer", "alsamixer",
            "audio-volume-high", "pnmixer", "volumeicon", "pasystray",
        ],
    },
    "bluetooth": {
        "text": "bt",
        "names": [
            "bluetooth", "preferences-system-bluetooth", "blueman", "blueman-manager",
            "blueberry", "bluedevil", "blueman-device", "overskride",
            "io.github.kaii_lb.Overskride",
        ],
    },
    "network": {
        "text": "ip",
        "names": [
            "preferences-system-network", "network-workgroup", "nm-connection-editor",
            "preferences-network", "network-manager", "networkmanager", "nm-applet",
            "connman", "cmst", "wicd", "preferences-system-network-proxy",
            "gnome-nettool", "wireshark", "org.wireshark.Wireshark", "zenmap",
            "nmtui",
        ],
    },
    "printer": {
        "text": "lp",
        "names": [
            "printer", "preferences-desktop-printer", "system-config-printer",
            "print-manager", "printers", "hplip", "cups", "gnome-printers-panel",
            "simple-scan", "org.gnome.SimpleScan", "skanlite", "xsane",
            "scanner", "skanpage",
        ],
    },
    "passwords": {
        "text": "***",
        "names": [
            "keepassxc", "org.keepassxc.KeePassXC", "keepass", "keepass2", "bitwarden",
            "com.bitwarden.desktop", "1password", "seahorse", "org.gnome.seahorse.Application",
            "kwalletmanager", "kwalletmanager2", "passwordsafe", "secrets",
            "org.gnome.World.Secrets", "enpass", "authenticator", "dialog-password",
            "preferences-desktop-user-password", "proton-pass", "kgpg", "gpa",
        ],
    },
    "help": {
        "text": "man",
        "names": [
            "help-browser", "help-contents", "system-help", "yelp", "org.gnome.Yelp",
            "khelpcenter", "org.kde.khelpcenter", "help-about", "mate-help",
            "manpages", "gnome-help",
        ],
    },
    "fonts": {
        "text": "Aa",
        "names": [
            "preferences-desktop-font", "gnome-font-viewer", "org.gnome.font-viewer",
            "font-manager", "org.gnome.FontManager", "kfontview", "fontforge",
            "fontmatrix", "fonts",
        ],
    },
    "characters": {
        "text": "&",
        "names": [
            "accessories-character-map", "gucharmap", "kcharselect",
            "org.kde.kcharselect", "gnome-characters", "org.gnome.Characters",
            "emote", "smile", "it.mijorus.smile",
        ],
    },
    "todo": {
        "text": "[x]",
        "names": [
            "gnome-todo", "org.gnome.Todo", "endeavour", "planner", "planify",
            "io.github.alainm23.planify", "todoist", "ticktick", "errands",
            "io.github.mrvladus.List", "kongress", "task-due",
        ],
    },
    "remote": {
        "text": "rdp",
        "names": [
            "remmina", "org.remmina.Remmina", "krdc", "org.kde.krdc", "vinagre",
            "gnome-connections", "org.gnome.Connections", "anydesk", "teamviewer",
            "rustdesk", "nomachine", "x2goclient", "tigervnc", "vncviewer",
            "preferences-desktop-remote-desktop", "krfb", "parsec", "moonlight",
            "sunshine",
        ],
    },
    "backup": {
        "text": "bak",
        "names": [
            "timeshift", "deja-dup", "org.gnome.DejaDup", "backintime", "kbackup",
            "vorta", "com.borgbase.Vorta", "pika-backup", "org.gnome.World.PikaBackup",
            "luckybackup", "grsync", "kup",
        ],
    },
    "camera": {
        "text": "cam",
        "names": [
            "accessories-camera", "camera", "cheese", "org.gnome.Cheese",
            "org.gnome.Snapshot", "snapshot", "kamoso", "org.kde.kamoso", "guvcview",
            "webcamoid", "camera-photo", "camera-web",
        ],
    },
    "logs": {
        "text": "log",
        "names": [
            "gnome-logs", "org.gnome.Logs", "ksystemlog", "org.kde.ksystemlog",
            "mate-system-log", "gnome-system-log", "logviewer", "journal-viewer",
        ],
    },
    "users": {
        "text": "usr",
        "names": [
            "system-users", "preferences-system-users", "user-info", "users-admin",
            "gnome-user-accounts", "kuser", "user-manager", "preferences-desktop-user",
        ],
    },
    "color": {
        "text": "#",
        "names": [
            "gpick", "gcolor2", "gcolor3", "kcolorchooser", "org.kde.kcolorchooser",
            "eyedropper", "com.github.finefindus.eyedropper", "colorpicker",
            "preferences-color", "preferences-desktop-color", "hyprpicker",
            "color-picker", "kcoloredit",
        ],
    },
    "power": {
        "text": "pwr",
        "names": [
            "preferences-system-power", "preferences-system-power-management",
            "xfce4-power-manager", "org.xfce.powermanager", "gnome-power-manager",
            "org.gnome.PowerStats", "powerdevil", "battery", "tlp", "tlpui",
            "cpupower-gui", "power-profiles", "auto-cpufreq", "system-shutdown",
            "system-log-out", "xfce4-session-logout", "wlogout",
        ],
    },
    "display": {
        "text": "dpy",
        "names": [
            "preferences-desktop-display", "display", "org.xfce.display",
            "xfce4-display-settings", "arandr", "lxrandr", "nwg-displays",
            "wdisplays", "kscreen", "video-display", "autorandr",
        ],
    },
    "keyboard": {
        "text": "kbd",
        "names": [
            "preferences-desktop-keyboard", "input-keyboard", "org.xfce.keyboard",
            "xfce4-keyboard-settings", "preferences-desktop-keyboard-shortcuts",
            "fcitx", "fcitx5", "ibus", "ibus-setup", "onboard", "florence",
            "preferences-desktop-keyboard-layout", "keyboard",
        ],
    },
    "mouse": {
        "text": "ptr",
        "names": [
            "preferences-desktop-peripherals", "input-mouse", "org.xfce.mouse",
            "xfce4-mouse-settings", "input-touchpad", "piper", "solaar",
            "preferences-desktop-mouse",
        ],
    },
    "wallpaper": {
        "text": "bg",
        "names": [
            "preferences-desktop-wallpaper", "preferences-desktop-background",
            "org.xfce.xfdesktop", "xfdesktop", "nitrogen", "variety", "waypaper",
            "azote", "hyprpaper", "swww", "wallpaper",
        ],
    },
    "locale": {
        "text": "i18n",
        "names": [
            "preferences-desktop-locale", "preferences-desktop-locale-symbolic",
            "config-language", "language-selector", "gnome-language-selector",
            "preferences-desktop-language", "translator", "dialect",
            "app.drey.Dialect", "crow-translate",
        ],
    },
    "accessibility": {
        "text": "a11y",
        "names": [
            "preferences-desktop-accessibility", "accessibility", "org.xfce.accessibility",
            "xfce4-accessibility-settings", "orca", "preferences-desktop-assistive-technology",
            "magnifier", "kmag", "kmousetool",
        ],
    },
    "notifications": {
        "text": "!",
        "names": [
            "preferences-desktop-notification", "preferences-system-notifications",
            "xfce4-notifyd", "org.xfce.notification", "dunst", "mako", "swaync",
            "notification-daemon", "notifications",
        ],
    },
    "screensaver": {
        "text": "zzz",
        "names": [
            "preferences-desktop-screensaver", "xscreensaver", "xfce4-screensaver",
            "org.xfce.ScreenSaver", "light-locker", "system-lock-screen", "swaylock",
            "hyprlock", "i3lock", "slock", "xsecurelock",
        ],
    },
    "torrent": {
        "text": "p2p",
        "names": [
            "transmission", "transmission-gtk", "transmission-qt", "qbittorrent",
            "org.qbittorrent.qBittorrent", "deluge", "ktorrent", "org.kde.ktorrent",
            "fragments", "de.haeckerfelix.Fragments", "tixati", "biglybt", "frostwire",
            "vuze", "qbittorrent-nox",
        ],
    },
    "office_doc": {
        "text": ".doc",
        "names": [
            "libreoffice-writer", "libreoffice6.0-writer", "ms-word", "wps-office-wps",
            "abiword", "calligrawords", "onlyoffice-documenteditor",
            "x-office-document", "office-document",
        ],
    },
    "office_sheet": {
        "text": ".xls",
        "names": [
            "libreoffice-calc", "libreoffice6.0-calc", "ms-excel", "wps-office-et",
            "gnumeric", "calligrasheets", "x-office-spreadsheet", "office-spreadsheet",
        ],
    },
    "office_slides": {
        "text": ".ppt",
        "names": [
            "libreoffice-impress", "libreoffice6.0-impress", "ms-powerpoint",
            "wps-office-wpp", "calligrastage", "x-office-presentation",
            "office-presentation",
        ],
    },
    "database": {
        "text": "sql",
        "names": [
            "libreoffice-base", "dbeaver", "io.dbeaver.DBeaverCommunity", "pgadmin4",
            "pgadmin3", "sqlitebrowser", "org.sqlitebrowser.sqlitebrowser",
            "mysql-workbench", "beekeeper-studio", "datagrip", "kexi",
            "x-office-database", "office-database",
        ],
    },
    "virtual": {
        "text": "vm",
        "names": [
            "virtualbox", "VirtualBox", "virt-manager", "gnome-boxes",
            "org.gnome.Boxes", "qemu", "vmware-workstation", "vmware-player",
            "quickemu", "quickgui", "virt-viewer", "aqemu", "distrobox",
            "boxbuddy", "io.github.dvlv.boxbuddy",
        ],
    },
    "games": {
        "text": "fun",
        "names": [
            "applications-games", "steam", "com.valvesoftware.Steam", "lutris",
            "net.lutris.Lutris", "heroic", "com.heroicgameslauncher.hgl",
            "bottles", "com.usebottles.bottles", "playonlinux", "itch", "io.itch.itch",
            "gamehub", "minigalaxy", "retroarch", "org.libretro.RetroArch",
            "gnome-games", "prismlauncher", "org.prismlauncher.PrismLauncher",
            "minecraft-launcher", "faugus-launcher",
        ],
    },
    "chat": {
        "text": "...",
        "names": [
            "internet-chat", "applications-chat", "empathy", "pidgin", "hexchat",
            "io.github.Hexchat", "konversation", "polari", "org.gnome.Polari",
            "quassel", "weechat", "irssi",
        ],
    },
}

# Applications with an obvious short name the rules wouldn't arrive at.
LABELS = {
    "discord": "dc",
    "com.discordapp.Discord": "dc",
    "vesktop": "dc",
    "dev.vencord.Vesktop": "dc",
    "webcord": "dc",
    "telegram": "tg",
    "telegram-desktop": "tg",
    "org.telegram.desktop": "tg",
    "signal-desktop": "sig",
    "org.signal.Signal": "sig",
    "whatsapp": "wa",
    "whatsapp-for-linux": "wa",
    "zapzap": "wa",
    "teams-for-linux": "ms",
    "teams": "ms",
    "element-desktop": "mx",
    "im.riot.Riot": "mx",
    "fractal": "mx",
    "slack": "slk",
    "com.slack.Slack": "slk",
    "zoom": "zoom",
    "Zoom": "zoom",
    "us.zoom.Zoom": "zoom",
    "intellij": "ij",
    "intellij-idea-community": "ij",
    "intellij-idea-ultimate-edition": "ij",
    "pycharm": "pc",
    "pycharm-community": "pc",
    "webstorm": "ws",
    "clion": "cl",
    "goland": "go",
    "rider": "rd",
    "phpstorm": "php",
    "rubymine": "rb",
    "rustrover": "rs",
    "androidstudio": "as",
    "android-studio": "as",
    "libreoffice-main": "lo",
    "libreoffice-startcenter": "lo",
    "libreoffice-draw": "drw",
    "libreoffice-math": "f(x)",
    "asc-de": "oo",
    "onlyoffice-desktopeditors": "oo",
    "github-desktop": "git",
    "gitkraken": "git",
    "git-cola": "git",
    "gitg": "git",
    "org.gnome.gitg": "git",
    "docker-desktop": "dkr",
    "docker": "dkr",
    "postman": "api",
    "insomnia": "api",
    "obs": "obs",
    "com.obsproject.Studio": "obs",
    "blender": "3d",
    "freecad": "cad",
    "librecad": "cad",
    "openscad": "cad",
    "kicad": "pcb",
    "minecraft": "mc",
    "gimp": "gimp",
    "inkscape": "ink",
    "krita": "krt",
    "kdenlive": "kdn",
    "audacity": "wav",
    "handbrake": "enc",
    "fr.handbrake.ghb": "enc",
    "wine": "wine",
    "filezilla": "ftp",
}

# Words that have a well-known short form.
WORDS = {
    "accessories": "acc",
    "audio": "aud",
    "browser": "www",
    "calendar": "cal",
    "configuration": "cfg",
    "config": "cfg",
    "contacts": "abk",
    "control": "ctl",
    "editor": "ed",
    "manager": "mgr",
    "monitor": "mon",
    "network": "net",
    "player": "ply",
    "recorder": "rec",
    "settings": "cfg",
    "system": "sys",
    "viewer": "vw",
}
