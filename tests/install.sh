#!/usr/bin/env bash
# Installs the theme into a temporary home and checks the result.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
home="$(mktemp -d)"
trap 'rm -rf "$home"' EXIT
export HOME="$home"
unset XDG_DATA_HOME XDG_CONFIG_HOME XDG_CACHE_HOME
export XDG_CURRENT_DESKTOP=Hyprland
theme="$home/.local/share/icons/ASCII"
apps="$theme/scalable/apps"
gtk3="$home/.config/gtk-3.0/settings.ini"
qt6="$home/.config/qt6ct/qt6ct.conf"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

mkdir -p "$(dirname "$gtk3")" "$(dirname "$qt6")"
printf '[Settings]\ngtk-theme-name=Adwaita-dark\ngtk-icon-theme-name=Papirus-Dark\n' > "$gtk3"
printf '[Appearance]\nicon_theme=breeze\nstyle=Fusion\n' > "$qt6"

"$root/install.sh" >/dev/null 2>&1
[[ -f "$theme/index.theme" ]] || fail "index.theme missing"
[[ -f "$theme/scalable/places/user-trash.svg" ]] || fail "trash icon not in places"
for name in utilities-terminal firefox org.kde.dolphin steam discord vlc org.gnome.Calculator; do
  [[ -f "$apps/$name.svg" ]] || fail "$name icon missing"
done
count="$(find "$theme" -name '*.svg' | wc -l)"
(( count > 8000 )) || fail "only $count icons"
grep -q 'fill="#ececf2"' "$apps/firefox.svg" || fail "default text color"
find "$theme" -name '*.svg' -print0 | xargs -0 xmllint --noout || fail "invalid svg"
python3 "$root/tests/check_render.py" "$theme" || fail "layout differs from render.py"

grep -qx 'gtk-icon-theme-name=ASCII' "$gtk3" || fail "gtk-3.0 not switched"
grep -qx 'gtk-theme-name=Adwaita-dark' "$gtk3" || fail "gtk-3.0 lost other keys"
grep -qx 'gtk-icon-theme-name=ASCII' "$home/.config/gtk-4.0/settings.ini" || fail "gtk-4.0 not switched"
grep -qx 'icon_theme=ASCII' "$qt6" || fail "qt6ct not switched"

"$root/install.sh" cyan none none >/dev/null 2>&1
grep -q '<rect' "$apps/firefox.svg" && fail "tile drawn with none none"
grep -q 'fill="#2bb7d8"' "$apps/firefox.svg" || fail "preset text color"

"$root/install.sh" "#ff8800" "#000000" none >/dev/null 2>&1
grep -q 'stroke=' "$apps/firefox.svg" && fail "border drawn with none"
grep -q 'fill="#ff8800"' "$apps/firefox.svg" || fail "hex text color"

"$root/install.sh" purple >/dev/null 2>&1 && fail "accepted invalid color"
"$root/install.sh" none >/dev/null 2>&1 && fail "accepted none as text color"
"$root/install.sh" a b c d >/dev/null 2>&1 && fail "accepted four colors"
"$root/install.sh" --bogus >/dev/null 2>&1 && fail "accepted unknown option"

"$root/install.sh" --uninstall >/dev/null
[[ -e "$theme" ]] && fail "theme left behind after uninstall"
grep -qx 'gtk-icon-theme-name=Papirus-Dark' "$gtk3" || fail "gtk-3.0 not restored"
grep -qx 'icon_theme=breeze' "$qt6" || fail "qt6ct not restored"

"$root/install.sh" --no-apply >/dev/null 2>&1
[[ -f "$apps/firefox.svg" ]] || fail "--no-apply didn't install"
grep -qx 'gtk-icon-theme-name=Papirus-Dark' "$gtk3" || fail "--no-apply switched the theme"

# Stand-ins for each desktop's settings tool, keeping the value in a file.
stubs="$home/stubs"
store="$home/store"
mkdir -p "$stubs" "$store"
cat > "$stubs/xfconf-query" <<'STUB'
#!/bin/sh
for a; do last="$a"; done
case " $* " in *" -s "*) echo "$last" > "$STORE/xfce" ;; *) cat "$STORE/xfce" ;; esac
STUB
cat > "$stubs/kreadconfig6" <<'STUB'
#!/bin/sh
cat "$STORE/kde"
STUB
cat > "$stubs/kwriteconfig6" <<'STUB'
#!/bin/sh
for a; do last="$a"; done
echo "$last" > "$STORE/kde"
STUB
cat > "$stubs/gsettings" <<'STUB'
#!/bin/sh
case "$1" in
  get) echo "'$(cat "$STORE/$2")'" ;;
  set) echo "$4" > "$STORE/$2" ;;
esac
STUB
chmod +x "$stubs"/*
export STORE="$store"

check_desktop() {
  local desktop="$1" file="$2"
  echo Previous > "$file"
  XDG_CURRENT_DESKTOP="$desktop" PATH="$stubs:$PATH" "$root/install.sh" >/dev/null 2>&1
  [[ "$(cat "$file")" == ASCII ]] || fail "$desktop: theme not applied"
  XDG_CURRENT_DESKTOP="$desktop" PATH="$stubs:$PATH" "$root/install.sh" --uninstall >/dev/null
  [[ "$(cat "$file")" == Previous ]] || fail "$desktop: previous theme not restored"
}

check_desktop XFCE "$store/xfce"
check_desktop KDE "$store/kde"
check_desktop GNOME "$store/org.gnome.desktop.interface"
check_desktop ubuntu:GNOME "$store/org.gnome.desktop.interface"
check_desktop X-Cinnamon "$store/org.cinnamon.desktop.interface"
check_desktop MATE "$store/org.mate.interface"

lxqt="$home/.config/lxqt/lxqt.conf"
mkdir -p "$(dirname "$lxqt")"
printf '[General]\nicon_theme=Previous\ntheme=dark\n' > "$lxqt"
XDG_CURRENT_DESKTOP=LXQt "$root/install.sh" >/dev/null 2>&1
grep -qx 'icon_theme=ASCII' "$lxqt" || fail "LXQt: theme not applied"
XDG_CURRENT_DESKTOP=LXQt "$root/install.sh" --uninstall >/dev/null
grep -qx 'icon_theme=Previous' "$lxqt" || fail "LXQt: previous theme not restored"
grep -qx 'theme=dark' "$lxqt" || fail "LXQt: lost other keys"

echo "ok"
