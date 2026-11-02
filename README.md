<div align="center">

# ASCII icons

Monospace text icon theme for Linux.

![preview](assets/preview.svg)

</div>

## Icons

The theme covers about 8,600 application icon names, taken from the app lists of
[Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) and
[elementary-xfce](https://github.com/shimmerproject/elementary-xfce).

Apps of the same kind share one glyph:

| Glyph   | Apps                     | Glyph  | Apps                      |
| ------- | ------------------------ | ------ | ------------------------- |
| `>_`    | Terminals                | `\|>`  | Video players             |
| `://`   | Web browsers             | `@`    | Mail                      |
| `~/`    | File managers            | `...`  | Chat (IRC, XMPP)          |
| `</>`   | Code editors, IDEs       | `+-`   | Calculators               |
| `/\/`   | Music players            | `cal`  | Calendars                 |
| `.md`   | Text editors, notes      | `.pdf` | Document viewers          |
| `rm`    | Trash                    | `.png` | Image viewers             |
| `cfg`   | Settings                 | `.zip` | Archive managers          |
| `top`   | System monitors          | `pkg`  | Software centers, updates |
| `12:00` | Clocks                   | `[ ]`  | Screenshot tools          |
| `/?`    | Search, launchers        | `***`  | Password managers         |
| `~$`    | App menu, distro logos   | `fun`  | Game launchers            |

Plus `vol` audio mixers, `bt` bluetooth, `ip` network, `lp` printers and scanners,
`df` disk tools, `du` disk usage, `bak` backups, `rdp` remote desktop, `vm` virtual
machines, `p2p` torrents, `sql` databases, `.doc` `.xls` `.ppt` office apps, `cam`,
`log`, `man`, `Aa` fonts and a few settings panels (`kbd`, `ptr`, `dpy`, `bg`,
`i18n`, `a11y`, `pwr`, `!`, `zzz`, `usr`, `#`).

Every other app gets a short name the way Unix commands are named: `gimp`, `obs`,
`dc` (Discord), `tg` (Telegram), `kdn` (Kdenlive), `krt` (Krita).
Icons outside applications, such as folders, mimetypes and status icons, come from
Papirus-Dark.

## Installation

```sh
git clone https://github.com/joagvv/ascii-icons.git
cd ascii-icons
./install.sh
```

The theme is installed to `~/.local/share/icons/ASCII` and switched on for the
current session:

| Session                                | Setting changed                                    |
| -------------------------------------- | -------------------------------------------------- |
| XFCE                                   | `xfconf` xsettings                                 |
| KDE Plasma                             | `kdeglobals`, through `plasma-changeicons`         |
| GNOME, Budgie, Pantheon, COSMIC, Unity | `org.gnome.desktop.interface`                      |
| Cinnamon, MATE                         | their own `gsettings` schema                       |
| LXQt                                   | `~/.config/lxqt/lxqt.conf`                         |
| Hyprland, Sway, i3, niri, other WMs    | GTK 3/4 `settings.ini`, gsettings, qt5ct and qt6ct |

Running `./install.sh` again replaces the previous install, so it's also how you
change colors. `./install.sh --uninstall` removes the theme and switches back to the
icon theme that was active before. Use `--no-apply` to install without switching.

On a window manager, launchers with their own icon setting need it too, for
example `rofi -show drun -icon-theme ASCII` or `icon-theme=ASCII` in `fuzzel.ini`.
Apps that are already running pick up the change after a restart.

### Dependencies

- bash, awk
- `papirus-icon-theme` (recommended, used for every icon this theme doesn't draw)
- `gtk-update-icon-cache` (optional)

## Usage

```
./install.sh [--no-apply] [text] [tile] [border]
```

Each color accepts a preset, a hex color or `none`.

| Command                                | Result                       |
| -------------------------------------- | ---------------------------- |
| `./install.sh`                         | White text on a dark tile    |
| `./install.sh red`                     | Preset text color            |
| `./install.sh "#ff8800"`               | Custom text color            |
| `./install.sh red "#000000" "#333344"` | Custom text, tile and border |
| `./install.sh cyan none none`          | Text only, no tile           |
| `./install.sh --uninstall`             | Remove the theme             |

Presets: `white`, `red`, `magenta`, `cyan`, `yellow`, `green`, `gray`, `black`.

## Building

`install.sh` and `assets/preview.svg` are generated from `src/`. Don't edit them directly.

```sh
make          # rebuild install.sh and the preview
make check    # bash -n and shellcheck
make test     # install into a temporary home and check the result
make names    # refresh src/names.txt from Papirus and elementary-xfce
```

The installer draws each icon from per-character outlines in `src/glyphs.json`.
They only need regenerating if the font changes:

```sh
pip install fonttools brotli
cp /path/to/JetBrainsMono-Bold.woff2 src/
make glyphs && make
```

| File                | Purpose                                                      |
| ------------------- | ------------------------------------------------------------ |
| `src/names.txt`     | Application icon names, one app and its aliases per line     |
| `src/icons.py`      | Shared glyphs by kind of app, and hand-picked names          |
| `src/labels.py`     | Turns an icon name into a short label                        |
| `src/catalog.py`    | Decides the text for every icon name                         |
| `src/glyphs.json`   | Character outlines from JetBrains Mono Bold                  |
| `src/install.sh.in` | Installer template                                           |
| `src/render.py`     | The installer's layout in Python, for the preview and tests  |

### Adding an app

Find the icon name the app asks for (the `Icon=` line in its `.desktop` file).
Add it to a group in `ROLES` or give it a name in `LABELS`, both in `src/icons.py`,
then run `make`.

## Credits

- [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono), SIL Open Font License 1.1
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) and
  [elementary-xfce](https://github.com/shimmerproject/elementary-xfce), both GPL-3.0:
  only the lists of icon names are used, none of the artwork

## License

[MIT](LICENSE)
