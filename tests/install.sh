#!/usr/bin/env bash
# Installs the theme into a temporary data directory and checks the result.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
data="$(mktemp -d)"
trap 'rm -rf "$data"' EXIT
export XDG_DATA_HOME="$data"
theme="$data/icons/ASCII"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

"$root/install.sh" >/dev/null
[[ -f "$theme/index.theme" ]] || fail "index.theme missing"
[[ -f "$theme/scalable/apps/utilities-terminal.svg" ]] || fail "terminal icon missing"
[[ -f "$theme/scalable/places/user-trash.svg" ]] || fail "trash icon not in places"
grep -q 'fill="#ececf2"' "$theme/scalable/apps/firefox.svg" || fail "default text color"
for svg in "$theme"/scalable/*/*.svg; do
  xmllint --noout "$svg" || fail "invalid svg: $svg"
done

"$root/install.sh" cyan none none >/dev/null
grep -q '<rect' "$theme/scalable/apps/firefox.svg" && fail "tile drawn with none none"
grep -q 'fill="#2bb7d8"' "$theme/scalable/apps/firefox.svg" || fail "preset text color"

"$root/install.sh" "#ff8800" "#000000" none >/dev/null
grep -q 'stroke=' "$theme/scalable/apps/firefox.svg" && fail "border drawn with none"
grep -q 'fill="#ff8800"' "$theme/scalable/apps/firefox.svg" || fail "hex text color"

"$root/install.sh" purple >/dev/null 2>&1 && fail "accepted invalid color"
"$root/install.sh" none >/dev/null 2>&1 && fail "accepted none as text color"
"$root/install.sh" a b c d >/dev/null 2>&1 && fail "accepted four arguments"

"$root/install.sh" --uninstall >/dev/null
[[ -e "$theme" ]] && fail "theme left behind after uninstall"

echo "ok"
