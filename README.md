<div align="center">

# ASCII icons

Monospace text icon theme for Linux.

![preview](assets/preview.png)

</div>

## Icons

| Glyph   | Application         |
| ------- | ------------------- |
| `>_`    | Terminal            |
| `://`   | Web browser         |
| `~/`    | File manager        |
| `</>`   | Code editor         |
| `/\/`   | Music player        |
| `rm`    | Trash               |
| `cfg`   | Settings            |
| `top`   | System monitor      |
| `12:00` | Clock               |
| `.md`   | Text editor         |
| `/?`    | Search, app finder  |
| `~$`    | Application menu    |

Icons not covered by the theme are inherited from Papirus-Dark.

## Installation

```sh
git clone https://github.com/YOUR-USERNAME/ascii-icons.git
cd ascii-icons
./install.sh
```

The theme is installed to `~/.local/share/icons/ASCII` and applied automatically on XFCE.
On other desktops, select **ASCII** in the appearance settings.

### Dependencies

- `papirus-icon-theme`
- `gtk-update-icon-cache` (optional)

## Usage

```
./install.sh [text] [tile] [border]
```

Each argument accepts a preset, a hex color or `none`.

| Command                               | Result                        |
| ------------------------------------- | ----------------------------- |
| `./install.sh`                        | White text on a dark tile     |
| `./install.sh red`                    | Preset text color             |
| `./install.sh "#ff8800"`              | Custom text color             |
| `./install.sh red "#000000" "#333344"`| Custom text, tile and border  |
| `./install.sh cyan none none`         | Text only, no tile            |
| `./install.sh --uninstall`            | Remove the theme              |

Presets: `white`, `red`, `magenta`, `cyan`, `yellow`, `green`, `gray`, `black`.

## Building

`install.sh` is generated from the files in `src/`.

```sh
pip install fonttools brotli
cp /path/to/JetBrainsMono-Bold.woff2 src/
python src/generate_paths.py
python src/build_installer.py
```

| File                     | Purpose                                  |
| ------------------------ | ---------------------------------------- |
| `src/generate_paths.py`  | Converts glyph text into SVG paths       |
| `src/paths.json`         | Generated SVG paths                      |
| `src/build_installer.py` | Maps paths to icon names                 |
| `src/install.sh.in`      | Installer template                       |

## Credits

- [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono), SIL Open Font License 1.1
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme), GPL-3.0

## License

[MIT](LICENSE)
