#!/usr/bin/env bash
# Generated from src/install.sh.in by src/build_installer.py. Edit those instead.
set -euo pipefail

THEME_NAME="ASCII"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
THEME_DIR="$DATA_HOME/icons/$THEME_NAME"
PREVIOUS_FILE="$THEME_DIR/.previous-theme"

usage() {
  cat <<'USAGE'
usage: install.sh [--no-apply] [text] [tile] [border]
       install.sh --uninstall

  each color is a preset name, a hex value (#rrggbb) or "none"
  presets: white red magenta cyan yellow green gray black

  --no-apply   install the theme without switching to it

  install.sh
  install.sh red
  install.sh "#ff8800"
  install.sh red "#000000" "#333344"
  install.sh cyan none none
USAGE
}

color() {
  case "$1" in
    white)   echo "#ececf2" ;;
    red)     echo "#e8364a" ;;
    magenta) echo "#e23a9b" ;;
    cyan)    echo "#2bb7d8" ;;
    yellow)  echo "#f2c14e" ;;
    green)   echo "#5fd38d" ;;
    gray)    echo "#8a8aa0" ;;
    black)   echo "#0b0b10" ;;
    *)       echo "$1" ;;
  esac
}

valid() {
  [[ "$1" == "none" || "$1" =~ ^#[0-9a-fA-F]{6}$ ]]
}

have() {
  command -v "$1" >/dev/null
}

theme_exists() {
  local dir
  for dir in "$DATA_HOME/icons" "$HOME/.icons" /usr/local/share/icons /usr/share/icons; do
    [[ -f "$dir/$1/index.theme" ]] && return 0
  done
  return 1
}

# ini_get FILE SECTION KEY
ini_get() {
  [[ -f "$1" ]] || return 0
  awk -v section="[$2]" -v key="$3" '
    $0 == section { on = 1; next }
    /^\[/ { on = 0 }
    on {
      split($0, kv, "=")
      gsub(/^[ \t]+|[ \t]+$/, "", kv[1])
      if (kv[1] == key) { sub(/^[^=]*=[ \t]*/, ""); print; exit }
    }' "$1"
}

# ini_set FILE SECTION KEY VALUE
ini_set() {
  mkdir -p "$(dirname "$1")"
  [[ -f "$1" ]] || : > "$1"
  awk -v section="[$2]" -v key="$3" -v value="$4" '
    function put() { if (!done) print key "=" value; done = 1 }
    $0 == section { print; on = 1; next }
    /^\[/ { if (on) put(); on = 0 }
    on && $0 ~ "^[ \t]*" key "[ \t]*=" { put(); next }
    { print }
    END { if (!done) { if (!on) print section; put() } }' "$1" > "$1.tmp"
  mv "$1.tmp" "$1"
}

# Which settings store holds the icon theme for the running session.
backend() {
  local desktop
  for desktop in $(echo "${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}" | tr '[:upper:]:' '[:lower:] '); do
    case "$desktop" in
      xfce)                     echo xfce; return ;;
      kde|plasma)               echo kde; return ;;
      lxqt)                     echo lxqt; return ;;
      x-cinnamon|cinnamon)      echo cinnamon; return ;;
      mate)                     echo mate; return ;;
      gnome|ubuntu|unity|budgie*|pantheon|cosmic|deepin|pop) echo gnome; return ;;
      ?*)                       echo generic; return ;;
    esac
  done
  if have xfconf-query; then echo xfce; else echo generic; fi
}

kde_config() {
  local tool
  for tool in "$1"6 "$1"5; do
    if have "$tool"; then
      "$tool" --file kdeglobals --group Icons --key Theme "${@:2}" 2>/dev/null || true
      return
    fi
  done
}

plasma_changeicons() {
  local path
  for path in "$(command -v plasma-changeicons 2>/dev/null)" \
      /usr/libexec/plasma-changeicons /usr/lib/plasma-changeicons \
      /usr/lib/*/libexec/plasma-changeicons /usr/lib/libexec/plasma-changeicons; do
    if [[ -x "$path" ]]; then
      "$path" "$1" >/dev/null 2>&1 || true
      return 0
    fi
  done
  return 1
}

gsettings_get() {
  have gsettings || return 0
  gsettings get "$1" icon-theme 2>/dev/null | tr -d "'" || true
}

gsettings_set() {
  have gsettings || return 0
  gsettings set "$1" icon-theme "$2" 2>/dev/null || true
}

GTK3_INI="$CONFIG_HOME/gtk-3.0/settings.ini"
GTK4_INI="$CONFIG_HOME/gtk-4.0/settings.ini"

get_theme() {
  case "$(backend)" in
    xfce)
      if have xfconf-query; then
        xfconf-query -c xsettings -p /Net/IconThemeName 2>/dev/null || true
      fi
      ;;
    kde)      kde_config kreadconfig ;;
    lxqt)     ini_get "$CONFIG_HOME/lxqt/lxqt.conf" General icon_theme ;;
    cinnamon) gsettings_get org.cinnamon.desktop.interface ;;
    mate)     gsettings_get org.mate.interface ;;
    gnome)    gsettings_get org.gnome.desktop.interface ;;
    generic)
      local theme
      theme="$(ini_get "$GTK3_INI" Settings gtk-icon-theme-name)"
      [[ -n "$theme" ]] || theme="$(gsettings_get org.gnome.desktop.interface)"
      echo "$theme"
      ;;
  esac
}

set_theme() {
  local conf saved value old
  case "$(backend)" in
    xfce)
      have xfconf-query || return 0
      xfconf-query -c xsettings -p /Net/IconThemeName -s "$1" 2>/dev/null || true
      ;;
    kde)
      if ! plasma_changeicons "$1"; then
        kde_config kwriteconfig "$1"
        if have dbus-send; then
          dbus-send --session --type=signal /KIconLoader \
            org.kde.KIconLoader.iconChanged int32:0 2>/dev/null || true
        fi
      fi
      ;;
    lxqt)     ini_set "$CONFIG_HOME/lxqt/lxqt.conf" General icon_theme "$1" ;;
    cinnamon) gsettings_set org.cinnamon.desktop.interface "$1" ;;
    mate)     gsettings_set org.mate.interface "$1" ;;
    gnome)    gsettings_set org.gnome.desktop.interface "$1" ;;
    generic)
      # Window managers (Hyprland, Sway, i3, ...) leave this to GTK and Qt.
      ini_set "$GTK3_INI" Settings gtk-icon-theme-name "$1"
      ini_set "$GTK4_INI" Settings gtk-icon-theme-name "$1"
      gsettings_set org.gnome.desktop.interface "$1"
      # qt5ct and qt6ct keep their own setting, remembered next to the theme.
      for conf in "$CONFIG_HOME/qt5ct/qt5ct.conf" "$CONFIG_HOME/qt6ct/qt6ct.conf"; do
        [[ -f "$conf" ]] || continue
        saved="$THEME_DIR/.previous-$(basename "$conf" .conf)"
        value="$1"
        if [[ "$1" == "$THEME_NAME" ]]; then
          old="$(ini_get "$conf" Appearance icon_theme)"
          if [[ -n "$old" && "$old" != "$THEME_NAME" ]]; then
            printf '%s\n' "$old" > "$saved"
          fi
        elif [[ -f "$saved" ]]; then
          value="$(cat "$saved")"
        fi
        ini_set "$conf" Appearance icon_theme "$value"
      done
      ;;
  esac
}

default_theme() {
  if theme_exists Papirus-Dark; then
    echo Papirus-Dark
  elif [[ "$(backend)" == kde ]]; then
    echo breeze
  else
    echo Adwaita
  fi
}

# The theme that was active before ASCII, so --uninstall can go back to it.
previous_theme() {
  local theme
  theme="$(get_theme)"
  if [[ -z "$theme" || "$theme" == "$THEME_NAME" ]]; then
    theme="$(cat "$PREVIOUS_FILE" 2>/dev/null || true)"
  fi
  [[ -n "$theme" ]] || theme="$(default_theme)"
  echo "$theme"
}

apply=1
colors=()
for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
    --uninstall)
      previous="$(previous_theme)"
      set_theme "$previous"
      rm -rf "$THEME_DIR" "$HOME/.icons/$THEME_NAME"
      echo "removed $THEME_DIR"
      exit 0
      ;;
    --no-apply)
      apply=0
      ;;
    -*)
      echo "unknown option: $arg" >&2
      usage >&2
      exit 1
      ;;
    *)
      colors+=("$arg")
      ;;
  esac
done

if (( ${#colors[@]} > 3 )); then
  usage >&2
  exit 1
fi

FG="$(color "${colors[0]:-white}")"
BG="$(color "${colors[1]:-black}")"
BORDER="$(color "${colors[2]:-#2c2c38}")"

for c in "$FG" "$BG" "$BORDER"; do
  if ! valid "$c"; then
    echo "invalid color: $c" >&2
    usage >&2
    exit 1
  fi
done

if [[ "$FG" == "none" ]]; then
  echo "text color can't be none" >&2
  exit 1
fi

if ! theme_exists Papirus-Dark; then
  echo "warning: Papirus-Dark not found, icons outside this theme will come from Adwaita" >&2
fi

# Outlines of each printable ASCII character in font units:
# code, bounds (xmin ymin xmax ymax, or - for blank) and SVG path.
glyphs() {
  cat <<'GLYPHS'
32	-	
33	216 -5 384 730	M246 227 232 730H368L354 227ZM285 -5Q254 -5 235 13.5Q216 32 216 61Q216 90 235 108.5Q254 127 285 127H315Q347 127 365.5 108.5Q384 90 384 61Q384 32 364.5 13.5Q345 -5 314 -5Z
34	115 430 485 730	M124 430 115 730H249L241 430ZM360 430 351 730H485L477 430Z
35	35 0 565 730	M77 0 111 190H35V275H125L156 455H70V540H171L205 730H293L259 540H401L435 730H523L489 540H565V455H474L443 275H530V190H428L395 0H307L341 190H198L165 0ZM213 275H355L386 455H244Z
36	57 -140 543 870	M269 -140V-8Q171 0 114.5 54Q58 108 57 196H182Q182 159 205 134.5Q228 110 269 102V314L251 319Q165 341 118.5 398Q72 455 72 536Q72 621 125 675.5Q178 730 269 738V870H331V739Q424 731 477.5 677.5Q531 624 532 539H407Q407 613 331 628V426L364 417Q451 395 497 338.5Q543 282 543 199Q543 112 485.5 55.5Q428 -1 331 -9V-140ZM197 543Q197 508 215.5 482Q234 456 269 444V628Q197 614 197 543ZM331 101Q372 107 395 131.5Q418 156 418 194Q418 231 395 258Q372 285 331 294Z
37	0 -5 600 735	M151 400Q83 400 44 436.5Q5 473 6 535V600Q5 662 44.5 698.5Q84 735 151 735Q217 735 256.5 698.5Q296 662 297 600V535Q297 473 257.5 436.5Q218 400 151 400ZM0 0 510 730H600L90 0ZM151 477Q177 477 192.5 492.5Q208 508 208 535V600Q208 627 193 642.5Q178 658 152 658Q126 658 110.5 642.5Q95 627 95 600V535Q95 508 110 492.5Q125 477 151 477ZM448 -5Q382 -5 342.5 31.5Q303 68 303 130V195Q303 257 342 293.5Q381 330 448 330Q515 330 554.5 293.5Q594 257 594 195V130Q594 68 554.5 31.5Q515 -5 448 -5ZM448 73Q474 73 489.5 88.5Q505 104 505 130V195Q505 222 489.5 237.5Q474 253 448 253Q423 253 407.5 237.5Q392 222 392 195V130Q391 104 406.5 88.5Q422 73 448 73Z
38	17 -10 624 740	M223 -10Q128 -10 72.5 42.5Q17 95 17 183V249Q17 326 57 374Q97 422 165 430L143 460Q121 490 109.5 519.5Q98 549 98 576Q98 624 121.5 661Q145 698 186.5 719Q228 740 282 740Q340 740 383.5 715.5Q427 691 451.5 646.5Q476 602 476 544H361Q361 587 339 613Q317 639 282 639Q252 639 233 620Q214 601 214 571Q214 557 220 541Q226 525 236 512L420 269L496 365H624L482 185L621 0H490L415 100L396 76Q367 36 321 13Q275 -10 223 -10ZM227 94Q257 94 280.5 108Q304 122 323 148L351 183L234 338H220Q181 338 158.5 314Q136 290 136 249V183Q136 142 160.5 118Q185 94 227 94Z
39	233 430 367 730	M242 430 233 730H367L359 430Z
40	167 -120 485 840	M485 -120Q333 -85 250 17.5Q167 120 167 271V450Q167 600 250 702Q333 804 485 840V716Q396 695 344.5 623.5Q293 552 293 450V271Q293 169 344.5 97.5Q396 26 485 5Z
41	115 -120 433 840	M115 -120V5Q204 26 255.5 97.5Q307 169 307 271V450Q307 552 255.5 623.5Q204 695 115 716V840Q267 804 350 702Q433 600 433 450V271Q433 120 350 17.5Q267 -85 115 -120Z
42	32 98 568 620	M183 98 100 157 170 256Q184 276 201.5 294.5Q219 313 239 330Q186 335 145 350L32 392L67 487L180 446Q220 431 263 403Q257 426 253 449.5Q249 473 249 499V620H351V499Q351 473 347 449.5Q343 426 336 403Q380 431 420 446L533 487L568 392L455 350Q414 335 361 330Q381 313 398.5 294.5Q416 276 430 256L500 157L417 98L346 197Q332 217 320.5 239.5Q309 262 300 286Q291 263 279.5 240Q268 217 254 197Z
43	59 92 541 568	M238 92V272H59V388H238V568H362V388H541V272H362V92Z
44	190 -160 386 146	M190 -160 243 146H386L310 -160Z
45	140 272 460 388	M140 272V388H460V272Z
46	207 -10 393 175	M300 -10Q258 -10 232.5 15.5Q207 41 207 82Q207 123 232.5 149Q258 175 300 175Q342 175 367.5 149Q393 123 393 82Q393 41 367.5 15.5Q342 -10 300 -10Z
47	60 -110 540 830	M60 -110 410 830H540L190 -110Z
48	68 -10 532 740	M300 -10Q229 -10 177 17Q125 44 96.5 93Q68 142 68 208V522Q68 588 96.5 637Q125 686 177 713Q229 740 300 740Q371 740 423 713Q475 686 503.5 637Q532 588 532 522V208Q532 142 503.5 93Q475 44 423 17Q371 -10 300 -10ZM300 98Q352 98 383 128Q414 158 414 208V522Q414 572 383.5 602Q353 632 300 632Q247 632 216.5 602Q186 572 186 522V208Q186 158 217 128Q248 98 300 98ZM300 305Q270 305 252 321.5Q234 338 234 368Q234 398 252 413.5Q270 429 300 429Q330 429 348 413.5Q366 398 366 368Q366 338 348 321.5Q330 305 300 305Z
49	83 0 552 730	M84 0V113H274V609L83 469V609L251 730H399V113H552V0Z
50	63 0 538 740	M74 0V113L337 382Q401 449 401 518Q401 567 372.5 597.5Q344 628 296 628Q247 628 217.5 596.5Q188 565 188 513H63Q63 581 93 632Q123 683 176 711.5Q229 740 299 740Q368 740 420 713Q472 686 500.5 637.5Q529 589 529 524Q529 468 502.5 412Q476 356 415 296L231 113H538V0Z
51	59 -10 528 730	M293 -10Q185 -10 122 46.5Q59 103 59 200H185Q185 154 214 126.5Q243 99 294 99Q344 99 373 126.5Q402 154 402 200V255Q402 304 373.5 331.5Q345 359 294 359H202V459L370 620H85V730H507V624L339 463Q427 451 477.5 396.5Q528 342 528 255V200Q528 103 464.5 46.5Q401 -10 293 -10Z
52	59 0 508 730	M382 0V145H59V326L329 730H468L179 293V255H382V420H508V0Z
53	62 -10 530 730	M296 -10Q189 -10 125.5 46.5Q62 103 62 200H187Q187 154 216.5 126.5Q246 99 297 99Q348 99 376.5 126.5Q405 154 405 203V251Q405 300 377 327.5Q349 355 298 355H87V730H503V617H205L206 465H304Q412 465 471 409Q530 353 530 251V203Q530 104 467.5 47Q405 -10 296 -10Z
54	53 -10 547 730	M300 -10Q225 -10 169.5 20Q114 50 83.5 104.5Q53 159 53 232Q53 275 71.5 330.5Q90 386 122 443L280 730H422L234 408L238 406Q253 427 282 439Q311 451 345 451Q406 451 451.5 423.5Q497 396 522 346Q547 296 547 228Q547 156 516.5 102.5Q486 49 430.5 19.5Q375 -10 300 -10ZM300 96Q356 96 390 131.5Q424 167 424 226Q424 286 390 321.5Q356 357 300 357Q244 357 210 321.5Q176 286 176 226Q176 167 210 131.5Q244 96 300 96Z
55	67 0 560 730	M158 0 425 620H192V501H67V730H560V620L295 0Z
56	53 -10 547 740	M300 -10Q227 -10 171 17.5Q115 45 84 93.5Q53 142 53 206Q53 273 91.5 323Q130 373 192 386V388Q139 399 106.5 442Q74 485 74 544Q74 602 102.5 646Q131 690 182 715Q233 740 300 740Q367 740 418.5 715Q470 690 498.5 646Q527 602 527 544Q527 485 494 442Q461 399 408 388V386Q470 373 508.5 323Q547 273 547 206Q547 142 516 93.5Q485 45 429 17.5Q373 -10 300 -10ZM300 431Q347 431 376 459.5Q405 488 405 533Q405 579 376 607.5Q347 636 300 636Q253 636 224 607.5Q195 579 195 533Q195 488 224 459.5Q253 431 300 431ZM300 96Q355 96 390 128Q425 160 425 212Q425 265 390 297.5Q355 330 300 330Q245 330 210 297.5Q175 265 175 212Q175 160 210 128Q245 96 300 96Z
57	53 0 547 740	M175 0 346 295Q334 286 318 279.5Q302 273 270 273Q210 273 160.5 302Q111 331 82 382.5Q53 434 53 502Q53 574 83.5 627.5Q114 681 169.5 710.5Q225 740 300 740Q375 740 430.5 710Q486 680 516.5 625.5Q547 571 547 498Q547 455 528.5 399.5Q510 344 478 287L320 0ZM300 373Q356 373 390 408.5Q424 444 424 504Q424 563 390 598.5Q356 634 300 634Q244 634 210 598.5Q176 563 176 504Q176 444 210 408.5Q244 373 300 373Z
58	207 -10 393 560	M300 393Q257 393 232 416Q207 439 207 477Q207 514 232 537Q257 560 300 560Q343 560 368 537Q393 514 393 477Q393 439 368 416Q343 393 300 393ZM300 -10Q257 -10 232 13Q207 36 207 73Q207 111 232 134Q257 157 300 157Q343 157 368 134Q393 111 393 73Q393 36 368 13Q343 -10 300 -10Z
59	185 -160 394 560	M290 392Q253 392 229.5 416Q206 440 206 476Q206 512 230 536Q254 560 290 560H310Q346 560 370 536Q394 512 394 476Q394 440 370.5 416Q347 392 310 392ZM185 -160 238 146H381L305 -160Z
60	76 56 524 603	M524 56 76 267V392L524 603V488L234 354Q214 345 194.5 338.5Q175 332 164 330Q175 328 195 322Q215 316 234 307L524 173Z
61	82 150 518 510	M82 395V510H518V395ZM82 150V265H518V150Z
62	76 56 524 603	M76 56V171L366 305Q386 314 405.5 320Q425 326 436 329Q425 331 405 337Q385 343 366 351L76 486V603L524 392V267Z
63	115 -5 500 730	M188 227 186 417H265Q315 417 345 444Q375 471 375 515Q375 560 345 586.5Q315 613 264 613H115V730H258Q332 730 386 703.5Q440 677 470 629Q500 581 500 515Q500 454 474.5 407.5Q449 361 404 334.5Q359 308 299 307V227ZM229 -5Q198 -5 179 13.5Q160 32 160 61Q160 90 179 108.5Q198 127 229 127H259Q290 127 308.5 108.5Q327 90 327 61Q327 32 308 13.5Q289 -5 258 -5Z
64	33 -180 572 740	M325 -180Q235 -180 169.5 -144.5Q104 -109 68.5 -44Q33 21 33 111V450Q33 540 67 605Q101 670 164 705Q227 740 315 740Q395 740 452.5 709.5Q510 679 541 624.5Q572 570 572 498V228Q572 148 525.5 101.5Q479 55 400 55Q322 55 276.5 100.5Q231 146 231 223V330Q231 405 266 448Q301 491 362 491Q403 491 430 474Q457 457 466 427H468V498Q468 571 428 610.5Q388 650 311 650Q229 650 183 597.5Q137 545 137 450V111Q137 18 186.5 -33.5Q236 -85 325 -85H435V-180ZM400 138Q433 138 450.5 160.5Q468 183 468 223V330Q468 371 450.5 393Q433 415 400 415Q367 415 349.5 392.5Q332 370 332 330V223Q332 183 349.5 160.5Q367 138 400 138Z
65	35 0 565 730	M35 0 219 730H380L565 0H437L397 177H203L163 0ZM226 279H374L330 475Q319 524 311 563.5Q303 603 300 621Q297 603 289 563.5Q281 524 270 476Z
66	77 0 548 730	M77 0V730H301Q406 730 468.5 679Q531 628 531 542Q531 482 496.5 439Q462 396 407 387V385Q448 380 480 355.5Q512 331 530 292.5Q548 254 548 208Q548 145 519 98Q490 51 437 25.5Q384 0 312 0ZM199 429H299Q348 429 377 455.5Q406 482 406 528Q406 573 377.5 599.5Q349 626 299 626H199ZM199 104H305Q360 104 391.5 133.5Q423 163 423 214Q423 265 391.5 296.5Q360 328 305 328H199Z
67	76 -10 540 740	M308 -10Q237 -10 185 16.5Q133 43 104.5 91.5Q76 140 76 206V524Q76 590 104.5 638.5Q133 687 185 713.5Q237 740 308 740Q378 740 430 713.5Q482 687 511 638.5Q540 590 540 524H414Q414 575 386.5 602.5Q359 630 308 630Q257 630 229 602.5Q201 575 201 524V206Q201 155 229 127.5Q257 100 308 100Q359 100 386.5 127.5Q414 155 414 206H540Q540 140 511 91.5Q482 43 430 16.5Q378 -10 308 -10Z
68	75 0 535 730	M75 0V730H292Q366 730 420.5 701.5Q475 673 505 622Q535 571 535 502V229Q535 160 505 108.5Q475 57 420.5 28.5Q366 0 292 0ZM200 112H292Q346 112 378 143.5Q410 175 410 229V502Q410 555 378 586.5Q346 618 292 618H200Z
69	88 0 526 730	M88 0V730H526V620H211V430H491V324H211V110H526V0Z
70	80 0 534 730	M80 0V730H534V614H203V419H508V303H205V0Z
71	72 -10 536 740	M304 -10Q233 -10 181 16.5Q129 43 100.5 91.5Q72 140 72 206V524Q72 590 100.5 638.5Q129 687 181 713.5Q233 740 304 740Q374 740 426 713.5Q478 687 507 638.5Q536 590 536 524H410Q410 575 382.5 602.5Q355 630 304 630Q253 630 225 603Q197 576 197 525V206Q197 155 225 127Q253 99 304 99Q355 99 382.5 127Q410 155 410 206V287H286V395H536V206Q536 140 507 91.5Q478 43 426 16.5Q374 -10 304 -10Z
72	77 0 523 730	M77 0V730H202V434H398V730H523V0H398V321H202V0Z
73	90 0 510 730	M90 0V113H237V617H90V730H510V617H363V113H510V0Z
74	30 -10 510 730	M270 -10Q159 -10 94.5 51Q30 112 30 216H155Q155 162 185.5 130.5Q216 99 270 99Q323 99 354 130Q385 161 385 215V730H510V215Q510 111 445.5 50.5Q381 -10 270 -10Z
75	76 0 569 730	M76 0V730H201V432H287L426 730H561L397 382L569 0H430L286 323H201V0Z
76	121 0 556 730	M121 0V730H246V113H556V0Z
77	54 0 546 730	M54 0V730H217L299 416L382 730H546V0H429V307Q429 370 432.5 437.5Q436 505 441 568.5Q446 632 452 684L349 317H246L147 675Q156 606 163.5 510.5Q171 415 171 307V0Z
78	72 0 528 730	M72 0V730H225L428 140Q425 172 422 215.5Q419 259 416.5 304Q414 349 414 384V730H528V0H375L174 590Q176 561 179 520Q182 479 184 436Q186 393 186 357V0Z
79	72 -10 528 740	M300 -10Q195 -10 133.5 50Q72 110 72 216V514Q72 620 133.5 680Q195 740 300 740Q405 740 466.5 680Q528 620 528 515V216Q528 110 466.5 50Q405 -10 300 -10ZM300 100Q351 100 377 127.5Q403 155 403 206V524Q403 575 377 602.5Q351 630 300 630Q249 630 223 602.5Q197 575 197 524V206Q197 155 223 127.5Q249 100 300 100Z
80	77 0 562 730	M77 0V730H320Q393 730 447.5 702Q502 674 532 623.5Q562 573 562 505Q562 437 532 386.5Q502 336 447.5 308Q393 280 320 280H202V0ZM202 390H320Q373 390 404 422Q435 454 435 505Q435 556 404 588Q373 620 320 620H202Z
81	68 -180 544 740	M409 -180 306 -10Q303 -10 300 -10Q230 -10 178 17Q126 44 97 93Q68 142 68 208V522Q68 588 96.5 637Q125 686 177.5 713Q230 740 300 740Q370 740 422 713Q474 686 503 637Q532 588 532 522V208Q532 142 503.5 92.5Q475 43 423 17L544 -180ZM300 100Q352 100 379.5 128.5Q407 157 407 208V522Q407 573 378.5 602Q350 631 300 631Q250 631 221.5 602Q193 573 193 522V208Q193 157 220.5 128.5Q248 100 300 100Z
82	77 0 557 730	M77 0V730H307Q380 730 433.5 703Q487 676 517 627.5Q547 579 547 513Q547 440 511 385.5Q475 331 414 308L557 0H420L292 290H201V0ZM201 400H307Q360 400 390 429Q420 458 420 509Q420 560 389.5 590Q359 620 307 620H201Z
83	57 -10 543 740	M303 -10Q229 -10 173.5 16Q118 42 87.5 90.5Q57 139 57 206H180Q180 157 213.5 128Q247 99 303 99Q357 99 388.5 127.5Q420 156 420 204Q420 240 399.5 267.5Q379 295 341 305L243 330Q164 350 118 405Q72 460 72 536Q72 629 133 684.5Q194 740 296 740Q365 740 416.5 715Q468 690 496 644.5Q524 599 524 538H402Q402 580 373 606Q344 632 296 632Q249 632 221.5 606.5Q194 581 194 540Q194 506 213.5 484Q233 462 268 452L369 427Q450 407 496.5 347Q543 287 543 204Q543 139 513.5 91Q484 43 430 16.5Q376 -10 303 -10Z
84	46 0 554 730	M237 0V617H46V730H554V617H363V0Z
85	72 -10 528 730	M300 -10Q193 -10 132.5 48.5Q72 107 72 208V730H198V209Q198 157 224 128Q250 99 300 99Q349 99 375.5 128Q402 157 402 209V730H528V208Q528 107 468 48.5Q408 -10 300 -10Z
86	35 0 565 730	M219 0 35 730H164L275 254Q284 219 291.5 178.5Q299 138 303 114Q307 138 314.5 178.5Q322 219 331 255L438 730H565L381 0Z
87	14 0 586 730	M90 0 14 730H118L164 220Q166 194 168.5 153.5Q171 113 171 85Q174 113 177.5 153.5Q181 194 184 220L248 730H355L415 220Q418 194 422.5 153.5Q427 113 430 85Q431 113 433.5 153.5Q436 194 438 220L483 730H586L506 0H368L312 512Q309 541 306 582.5Q303 624 301 651Q299 624 296 582.5Q293 541 290 512L229 0Z
88	28 0 572 730	M28 0 230 374 40 730H180L272 547Q282 527 290 508.5Q298 490 302 480Q305 490 313 508.5Q321 527 331 547L424 730H560L370 377L572 0H432L329 202Q319 221 310.5 240.5Q302 260 298 271Q294 260 286 241Q278 222 268 202L164 0Z
89	23 0 577 730	M237 0V265L23 730H155L268 477Q281 447 290 418Q299 389 302 373Q306 389 314.5 418Q323 447 336 477L447 730H577L363 265V0Z
90	79 0 521 730	M79 0V116L372 617H86V730H510V614L216 113H521V0Z
91	185 -110 465 830	M185 -110V830H465V715H310V5H465V-110Z
92	60 -110 539 830	M409 -110 60 830H190L539 -110Z
93	135 -110 415 830	M135 -110V5H290V715H135V830H415V-110Z
94	68 340 532 730	M68 340 241 730H361L532 340H415L323 570Q315 591 309.5 610.5Q304 630 302 640Q299 630 293 610.5Q287 591 279 570L184 340Z
95	60 -138 540 -25	M60 -138V-25H540V-138Z
96	143 645 388 785	M259 645 143 785H281L388 645Z
97	58 -10 523 560	M239 -10Q155 -10 106.5 37.5Q58 85 58 162Q58 242 113 289.5Q168 337 264 337H398V376Q398 459 301 459Q257 459 231 442Q205 425 202 394H82Q86 468 144.5 514Q203 560 302 560Q407 560 465 511Q523 462 523 373V0H401V103Q394 50 351 20Q308 -10 239 -10ZM279 92Q334 92 366 119Q398 146 398 191V256H270Q229 256 205 233Q181 210 181 174Q181 137 206.5 114.5Q232 92 279 92Z
98	77 -10 529 730	M350 -10Q292 -10 253 19Q214 48 199 100V0H77V730H202V576L198 450Q214 502 253.5 531Q293 560 350 560Q431 560 480 503Q529 446 529 349V200Q529 104 479.5 47Q430 -10 350 -10ZM303 98Q351 98 377.5 124Q404 150 404 204V346Q404 400 377.5 426Q351 452 303 452Q255 452 228.5 423Q202 394 202 341V209Q202 156 228.5 127Q255 98 303 98Z
99	75 -10 540 560	M309 -10Q238 -10 185.5 16.5Q133 43 104 91.5Q75 140 75 206V344Q75 410 104 458.5Q133 507 185.5 533.5Q238 560 309 560Q412 560 474.5 506.5Q537 453 540 361H417Q414 404 384.5 427.5Q355 451 309 451Q258 451 229 423.5Q200 396 200 345V206Q200 155 229 127Q258 99 309 99Q356 99 385 122.5Q414 146 417 189H540Q537 97 474.5 43.5Q412 -10 309 -10Z
100	71 -10 523 730	M250 -10Q170 -10 120.5 47Q71 104 71 200V349Q71 446 120 503Q169 560 250 560Q307 560 346.5 531Q386 502 402 450L398 576V730H523V0H401V100Q386 48 347 19Q308 -10 250 -10ZM297 98Q345 98 371.5 127Q398 156 398 209V341Q398 394 371.5 423Q345 452 297 452Q249 452 222.5 426Q196 400 196 346V204Q196 150 222.5 124Q249 98 297 98Z
101	70 -10 530 560	M301 -10Q231 -10 179 17Q127 44 98.5 93.5Q70 143 70 210V340Q70 407 98.5 456.5Q127 506 179 533Q231 560 301 560Q370 560 421.5 533Q473 506 501.5 457.5Q530 409 530 344V244H190V206Q190 150 219 121.5Q248 93 301 93Q340 93 367.5 106.5Q395 120 400 146H524Q511 75 450 32.5Q389 -10 301 -10ZM190 344V325L410 326V345Q410 402 382 433Q354 464 301 464Q246 464 218 432.5Q190 401 190 344Z
102	49 0 536 730	M200 0V362H49V475H200V572Q200 644 248 687Q296 730 375 730H536V620H378Q354 620 339.5 606.5Q325 593 325 570V475H536V362H325V0Z
103	72 -180 523 560	M152 -180V-76H307Q351 -76 375 -52.5Q399 -29 399 11V44L401 130Q384 84 346.5 58.5Q309 33 255 33Q171 33 121.5 89.5Q72 146 72 243V350Q72 446 121.5 503Q171 560 255 560Q309 560 346.5 534.5Q384 509 401 462V550H523V8Q523 -79 465.5 -129.5Q408 -180 309 -180ZM297 140Q345 140 371.5 168.5Q398 197 398 248V344Q398 395 371.5 423.5Q345 452 297 452Q249 452 223 424.5Q197 397 197 348V244Q197 195 223 167.5Q249 140 297 140Z
104	77 0 525 730	M77 0V730H202V550L199 448Q209 500 248 530Q287 560 347 560Q428 560 476.5 506Q525 452 525 361V0H400V346Q400 397 373.5 424.5Q347 452 302 452Q255 452 228.5 424Q202 396 202 344V0Z
105	76 0 558 786	M76 0V113H264V437H96V550H389V113H558V0ZM318 642Q280 642 258 661.5Q236 681 236 714Q236 747 258 766.5Q280 786 318 786Q356 786 378 766.5Q400 747 400 714Q400 681 378 661.5Q356 642 318 642Z
106	76 -180 468 786	M81 -180V-67H226Q274 -67 302 -38.5Q330 -10 330 39V437H76V550H455V36Q455 -64 395 -122Q335 -180 233 -180ZM386 642Q348 642 326 661.5Q304 681 304 714Q304 747 326 766.5Q348 786 386 786Q424 786 446 766.5Q468 747 468 714Q468 681 446 661.5Q424 642 386 642Z
107	82 0 571 730	M82 0V730H207V334H295L426 550H565L402 284L571 0H429L295 228H207V0Z
108	27 0 559 730	M389 0Q307 0 257.5 49Q208 98 208 178V617H27V730H333V181Q333 150 350.5 131.5Q368 113 398 113H559V0Z
109	47 0 553 560	M47 0V550H151V470H154Q157 510 182 535Q207 560 245 560Q282 560 308 536.5Q334 513 343 473Q347 513 372.5 536.5Q398 560 437 560Q487 560 520 520.5Q553 481 553 419V0H443V410Q443 437 430.5 452.5Q418 468 395 468Q350 468 350 410V0H250V410Q250 437 238.5 452.5Q227 468 205 468Q157 468 157 410V0Z
110	77 0 525 560	M77 0V550H199V447Q209 499 248 529.5Q287 560 347 560Q428 560 476.5 506Q525 452 525 361V0H400V346Q400 397 373.5 424.5Q347 452 302 452Q255 452 228.5 424Q202 396 202 344V0Z
111	70 -9 530 559	M300 -9Q194 -9 132 50.5Q70 110 70 211V339Q70 441 132 500Q194 559 300 559Q406 559 468 500Q530 441 530 339V211Q530 110 468 50.5Q406 -9 300 -9ZM300 100Q350 100 377.5 127.5Q405 155 405 207V343Q405 395 377.5 422.5Q350 450 300 450Q250 450 222.5 422.5Q195 395 195 343V207Q195 155 222.5 127.5Q250 100 300 100Z
112	77 -180 529 560	M77 -180V550H199V449Q214 501 253 530.5Q292 560 350 560Q403 560 443.5 534Q484 508 506.5 460.5Q529 413 529 350V201Q529 106 480 48Q431 -10 350 -10Q292 -10 252.5 20Q213 50 198 104L202 -26V-180ZM303 98Q351 98 377.5 124Q404 150 404 204V346Q404 400 377.5 426Q351 452 303 452Q255 452 228.5 423Q202 394 202 341V209Q202 156 228.5 127Q255 98 303 98Z
113	71 -180 523 560	M398 -180V-26L402 99H401Q385 48 346 19Q307 -10 250 -10Q169 -10 120 47Q71 104 71 201V350Q71 446 120.5 503Q170 560 250 560Q308 560 347 531Q386 502 401 450V550H523V-180ZM297 98Q345 98 371.5 127Q398 156 398 209V341Q398 394 371.5 423Q345 452 297 452Q249 452 222.5 426Q196 400 196 348V202Q196 150 222.5 124Q249 98 297 98Z
114	97 0 549 560	M97 0V550H219V443Q229 497 268.5 528.5Q308 560 371 560Q455 560 502 506Q549 452 549 355V303H424V349Q424 399 398 425.5Q372 452 324 452Q274 452 248 422Q222 392 222 337V0Z
115	65 -9 535 559	M277 -9Q179 -9 122 35.5Q65 80 65 156H188Q188 124 211.5 107Q235 90 277 90H321Q366 90 390.5 107Q415 124 415 156Q415 186 398 200.5Q381 215 346 220L209 238Q143 247 107.5 289Q72 331 72 398Q72 476 124 517.5Q176 559 274 559H320Q412 559 468 517Q524 475 526 405H402Q401 431 379 446.5Q357 462 320 462H274Q234 462 213 445.5Q192 429 192 401Q192 376 207.5 364Q223 352 253 349L382 331Q458 322 496.5 277.5Q535 233 535 158Q535 78 480.5 34.5Q426 -9 321 -9Z
116	35 0 532 705	M355 0Q278 0 232.5 44.5Q187 89 187 165V437H35V550H187V705H313V550H532V437H313V168Q313 144 326.5 128.5Q340 113 364 113H527V0Z
117	75 -10 525 550	M300 -10Q195 -10 135 48.5Q75 107 75 208V550H200V209Q200 157 226 128Q252 99 300 99Q347 99 373.5 128Q400 157 400 209V550H525V208Q525 107 464 48.5Q403 -10 300 -10Z
118	36 0 564 550	M221 0 36 550H167L273 216Q283 186 290.5 155.5Q298 125 301 103Q305 125 311.5 155.5Q318 186 327 215L432 550H564L380 0Z
119	16 0 584 550	M102 0 16 550H115L164 213Q168 182 171 146Q174 110 176 86Q177 110 180 146Q183 182 189 213L249 550H353L411 213Q417 182 420.5 145.5Q424 109 426 85Q428 109 430.5 145.5Q433 182 438 213L488 550H584L496 0H367L315 339Q310 367 306 403.5Q302 440 300 463Q299 440 294 403.5Q289 367 285 339L231 0Z
120	36 0 564 550	M36 0 228 284 49 550H190L275 415Q283 403 290 388Q297 373 300 364Q304 373 310.5 388Q317 403 325 415L410 550H552L373 284L564 0H422L327 151Q319 163 311.5 178.5Q304 194 300 203Q296 194 289 178.5Q282 163 274 151L178 0Z
121	36 -180 564 550	M165 -180 243 30 36 550H168L274 269Q283 244 292 214.5Q301 185 305 160Q308 185 316.5 214.5Q325 244 334 269L432 550H564L296 -180Z
122	78 0 522 550	M78 0V113L365 440H87V550H511V437L221 110H522V0Z
123	69 -111 511 830	M442 -111Q354 -111 303 -62.5Q252 -14 260 67L275 219Q279 260 261 281Q243 302 199 302H69V417H199Q243 417 261 438Q279 459 275 499L260 656Q252 735 303 782.5Q354 830 442 830H511V715H460Q423 715 403 696.5Q383 678 385 644L400 488Q405 437 373.5 403.5Q342 370 280 362Q342 353 373.5 318Q405 283 400 231L385 75Q382 42 402.5 23.5Q423 5 460 5H511V-111Z
124	237 -110 363 830	M237 -110V830H363V-110Z
125	89 -111 531 830	M89 -111V5H140Q177 5 198 23.5Q219 42 215 75L195 231Q189 282 219 317.5Q249 353 303 362Q249 371 219 404Q189 437 195 488L215 644Q219 678 198 696.5Q177 715 140 715H89V830H158Q216 830 259.5 808.5Q303 787 324.5 748Q346 709 340 656L320 499Q310 417 397 417H531V302H397Q310 302 320 219L340 67Q346 13 324.5 -27Q303 -67 260 -89Q217 -111 158 -111Z
126	52 235 548 470	M52 255V334Q52 395 92 432.5Q132 470 197 470Q238 470 265 456Q292 442 309.5 422Q327 402 341 381.5Q355 361 369 347.5Q383 334 404 334Q442 334 442 377V450H548V371Q548 310 508.5 272.5Q469 235 403 235Q362 235 335 249Q308 263 290.5 283Q273 303 259 323.5Q245 344 231 357.5Q217 371 196 371Q158 371 158 328V255Z
GLYPHS
}

# Theme context, text drawn on the icon and the icon names it replaces.
icons() {
  cat <<'ICONS'
apps	!	cs-notifications dunst help-faq knotify mako mate-notification-properties notification-daemon notifications notifyconf org.xfce.notification plugin-notification preferences-desktop-notification preferences-desktop-notifications preferences-system-notifications swaync xfce4-notifyd
apps	#	appimagekit-colorpicker application-vnd.iccprofile applications-graphics color-picker colorgrab colorpicker colors com.github.finefindus.eyedropper com.github.ronnydo.colorpicker cs-cat-appearance cs-color deepin-picker eyedropper gcolor gcolor2 gcolor3 gnome-color-chooser gnome-color-manager gnome-paint gnome-settings-theme gpick hyprpicker kcolorchooser kcoloredit kipi kipi-logo mypaint nl.hjdskes.gcolor3 org.gnome.ColorViewer org.kde.kcolorchooser org.kde.plasma.colorpicker org.mypaint.MyPaint org.xfce.settings.color package_graphics pick-colour-picker preferences-color preferences-desktop-color preferences-desktop-display-color unity-color-panel xfce-ui xfce4-color-settings xfce4-ui
apps	&	accessories-character-map autokey emote gnome-character-map gnome-characters gucharmap indicator-keylock it.mijorus.smile kcharselect org.gnome.Characters org.kde.kcharselect smile
apps	***	1password appimagekit-1password appimagekit-bitwarden appimagekit-org.keepassxc.KeePassXC authenticator bitwarden com.bitwarden.desktop cryptfolder-indicator cryptkeeper dialog-password enpass gnupg gpa io.enpass.Enpass kali-vuln-assessment-trans keepass keepass2 keepassxc kgpg kwalletmanager kwalletmanager2 me.proton.Pass org.gnome.PasswordSafe org.gnome.seahorse.Application org.gnome.World.Secrets org.kde.kwalletmanager5 org.keepassxc.KeePassXC passwordsafe pinentry preferences-desktop-user-password proton-pass seahorse seahorse-preferences secrets yast-kerberos
apps	+-	accessories-calculator calc deepin-calculator galculator gcbalculator gnome-calculator io.elementary.calculator io.github.Qalculate io.github.Qalculate.qalculate-qt io.liri.Calculator kalk kcalc mate-calc org.gnome.Calculator org.kde.kalk org.kde.kcalc org.speedcrunch.SpeedCrunch qalculate qalculate-gtk qalculate-qt speedcrunch xcalc xfce4-calculator-plugin
apps	...	applications-chat empathy hexchat im.pidgin.Pidgin internet-chat io.github.Hexchat irc-chat irssi kde-telepathy konversation org.gnome.Empathy org.gnome.Polari org.kde.konversation org.quassel_irc.QuasselClient pidgin polari quassel relay smuxi smuxi-frontend-gnome weechat
apps	.doc	abiword calligrawords com.abisource.AbiWord io.gitlab.o20.word libreoffice-writer libreoffice6.0-writer libreoffice7.3-writer libreoffice7.4-writer libreoffice7.5-writer libreoffice7.6-writer ms-word office-document onlyoffice-documenteditor openoffice4-writer org.libreoffice.LibreOffice.writer solstice-microsoft-365-word words wps-office-wps x-office-document
apps	.epub	accessories-ebook-reader bookreader bookworm calibre calibre-gui com.calibre_ebook.calibre com.github.babluboy.bookworm com.github.johnfactotum.Foliate foliate gnome-books io.github.troyeguo.koodo-reader koodo-reader lrfviewer org.gnome.Books
apps	.md	1E64_notepad.0 accessories-notes accessories-text-editor apostrophe appimagekit-joplin appimagekit-obsidian appimagekit-standard-notes appimagekit-zettlr basket bijiben bottles_notepad brave-cnmnfnkedfekfidgojcdmndbcipagogc-Default chrome-cnmnfnkedfekfidgojcdmndbcipagogc-Default com.github.marktext.marktext com.logseq.Logseq com.notepadqq.Notepadqq com.simplenote.Simplenote com.zettlr.Zettlr cs-desklets deepin-editor deepin-note edile evolution-memos featherpad footnote gedit gedit-icon gedit-logo ghostwriter gnome-note gnome-sticky-notes-applet gnome-word gnote indicator-stickynotes io.github.wereturtle.ghostwriter io.liri.Text io.typora.Typora joplin joplin-desktop juffed kate kate2 kedit knotes korg-todo kwrite l3afpad leafpad logseq marktext mate-sticky-notes-applet md.obsidian.Obsidian medit mousepad mynotes net.cozic.joplin_desktop noblenote notepad notepadqq notes notion Notion obsidian org.gnome.bijiben org.gnome.gedit org.gnome.gitlab.somas.Apostrophe org.gnome.Gnote org.gnome.TextEditor org.gnome.Tomboy org.joplinapp.joplin org.kde.ghostwriter org.kde.kate org.kde.kwrite org.standardnotes.standardnotes org.xfce.mousepad org.xfce.notes org.xfce.panel.notes package_editors pluma preferences-composer simplenote standard-notes sticky-notes text-editor tomboy tomboy-ng typora wine-notepad wp xed xedit xfce-edit xfce4-notes-plugin xfw xpad zettlr Zettlr zim
apps	.pdf	atril com.github.ahrm.sioyek com.github.jeromerobert.pdfarranger com.github.xournalpp.xournalpp deepin-reader document-viewer epdfview evince foxit-reader foxitreader FoxitReader gnome-pdf indicator-privacy kpdf master-pdf-editor masterpdfeditor masterpdfeditor4 masterpdfeditor5 mupdf mx-viewer net.codeindustry.MasterPDFEditor okular org.gnome.Evince org.gnome.Papers org.kde.okular org.pwmt.zathura papers pdfarranger postscript-viewer qpdfview sioyek sioyek-icon-linux x-pdf xournal xournalpp xpdf xreader yagf zathura
apps	.png	com.github.vikdevelop.photopea_app de.swsnr.pictureoftheday deepin-album deepin-image-viewer eog eom feh geeqie gpicview gthumb gwenview image-roll image-viewer imv io.elementary.photos loupe lximage lximage-qt mirage multimedia-photo-manager multimedia-photo-viewer nomacs nsxiv oculante org.geeqie.Geeqie org.gnome.eog org.gnome.gThumb org.gnome.Loupe org.gnome.Shotwell org.kde.gwenview org.kde.pix org.nomacs.ImageLounge org.photoqt.PhotoQt org.xfce.ristretto photoqt pix qimgv ristretto shotwell sxiv viewnior xviewer
apps	.ppt	calligrastage libreoffice-impress libreoffice6.0-impress libreoffice7.3-impress libreoffice7.4-impress libreoffice7.5-impress libreoffice7.6-impress ms-powerpoint office-presentation org.libreoffice.LibreOffice.impress solstice-microsoft-365-powerpoint stage wps-office-wpp x-office-presentation
apps	.xls	calligrasheets gnome-gnumeric gnumeric libreoffice-calc libreoffice6.0-calc libreoffice7.3-calc libreoffice7.4-calc libreoffice7.5-calc libreoffice7.6-calc ms-excel office-spreadsheet openoffice4-calc org.gnumeric.Gnumeric org.libreoffice.LibreOffice.calc sheets solstice-microsoft-365-excel wps-office-et x-office-spreadsheet
apps	.zip	7z 7zip accessories-archiver archive-manager archivemanager ark deepin-compressor engrampa file-roller io.github.peazip.PeaZip lxqt-archiver org.gnome.ArchiveManager org.gnome.FileRoller org.kde.ark p7zip peazip squeeze utilities-file-archiver xar xarchive xarchiver xfp
apps	/?	5961_Defunct_x86.0 albert baloo catfish cerebro edit-find fsearch fuzzel gnome-hideseek gnome-search-tool gnome-searchtool gnome-tracker io.github.cboxdoerfer.FSearch kali-info-gathering-trans kappfinder kfind krunner kupfer mx-findshares org.kde.kfind org.xfce.appfinder org.xfce.catfish plasma-search preferences-desktop-baloo preferences-desktop-search preferences-system-search recoll rofi searchmonkey spacefm-find synapse system-search tofi tracker ulauncher wofi xfce4-appfinder xmag
apps	/\/	alsaplayer amarok amarok-icon amarok2 amberol appimagekit-youtube-music applications-multimedia audacious audio-player brave-cinhimbnkkaeohfgghhklpknlkffjgod-Default cantata chrome-cinhimbnkkaeohfgghhklpknlkffjgod-Default clementine cmus com.github.neithern.g4music com.mastermindzh.tidal-hifi com.sayonara_player.Sayonara com.spotify.Client deadbeef deepin-music deepin-music-player dog.unix.cantata.Cantata elisa exaile g4music gmpc gmusicbrowser gnome-audio gnome-music gstreamer-properties guayadeque harmonoid io.bassi.Amberol io.elementary.music io.github.Pithos io.github.quodlibet.QuodLibet itunes juk lollypop lxmusic media-player-48 multimedia multimedia-audio-player musique ncmpcpp org.atheme.audacious org.clementine_player.Clementine org.exaile.Exaile org.gmusicbrowser.gmusicbrowser org.gnome.Lollypop org.gnome.Music org.gnome.Rhythmbox org.gnome.Rhythmbox3 org.kde.elisa org.kde.juk org.strawberrymusicplayer.strawberry package_multimedia pithos Pithos preferences-desktop-multimedia quodlibet rhythmbox sayonara solstice-google-youtube-music solstice-spotify-spotify sonata spotify spotify-client spotube strawberry tauon tidal-hifi xmms2 yast-checkmedia youtube-music
apps	010	010editor com.sweetscape.ZeroOneZeroEditor
apps	0ad	0ad com.play0ad.zeroad lutris_0-ad
apps	0f	0cc-famitracker
apps	12:00	accessories-clock alarm-clock appointment cairo-clock clock cs-date-time cuckoo gnome-clocks gnome-schedule gnome-set-time hourglass kalarm kclock mate-panel-clock mx-clocky mx-timeset-gui-icon orage_globaltime org.gnome.clocks org.kde.kclock org.xfce.orage.globaltime org.xfce.panel.clock preferences-desktop-time preferences-system-time stock_alarm system-config-date time time-admin timeset-gui-icon unity-datetime-panel xclock xfce-schedule xfce4-clock yast-timezone
apps	1cd	1cedt
apps	1cs	1cestart 1cv8 1cv8c
apps	1g	140-game lutris_140 steam_icon_242820
apps	2048	2048-qt gnome-2048 org.gnome.TwentyFortyEight
apps	2gis	2gis
apps	2ro	2064-read-only-memories lutris_read-only-memories steam_icon_330820
apps	3c	3D-Coat
apps	3d	blender Blender lutris_blender org.blender.Blender steam_icon_365670
apps	3dp	3depict
apps	4dg	4digits
apps	4i	4diac-ide org.eclipse.iot.fourdiac.Ide
apps	4ks	4kslideshowmaker 4kstogram
apps	4kv	4kvideodownloader 4kvideotomp3
apps	4ky	4kyoutubetomp3
apps	4pn	4Pane 4PaneIcon48
apps	6m	6180-the-moon lutris_6180-the-moon steam_icon_299660
apps	7dt	7-days-to-die lutris_7-days-to-die steam_icon_251570
apps	7kaa	7kaa lutris_seven-kingdoms-ancient-adversaries steam_icon_450140
apps	8bt	8bitmmo lutris_8bitmmo steam_icon_250420
apps	8tr	8tracks
apps	9gag	9gag
apps	://	7596_iexplore.0 81F5_winebrowser.0 app.zen_browser.zen appimagekit-librewolf applications-internet applications-webbrowsers brave brave-browser brave-desktop browser browser-tor chromium chromium-browser chromium-browser-privacy chromium-freeworld com.brave.Browser com.github.micahflee.torbrowser-launcher com.google.Chrome com.google.ChromeDev com.microsoft.Edge com.opera.Opera com.vivaldi.Vivaldi cqcb.plasma.webslice deepin-browser ECB7_iexplore.0 epiphany falkon FB4C_iexplore.0 firefox firefox-beta firefox-bin firefox-devedition firefox-developer-edition firefox-esr firefox-icon firefox-mozilla-build floorp galeon gnome-internet google-chrome google-chrome-beta google-chrome-unstable google-chrome2 googlechrome internet-web-browser io.github.ungoogled_software.ungoogled_chromium io.github.zen_browser.zen io.gitlab.LibreWolf io.gitlab.librewolf-community konqueror librewolf microsoft-edge midori min mullvad-browser net.mullvad.MullvadBrowser net.waterfox.waterfox opera org.chromium.Chromium org.deepin.browser org.gnome.Epiphany org.kde.falkon org.midori_browser.Midori org.mozilla.firefox org.mozilla.Firefox org.qutebrowser.qutebrowser org.torproject.torbrowser-launcher org.xfce.webbrowser palemoon preferences-web-browser-identification preferences-web-browser-shortcuts qutebrowser redhat-web-browser rekonq seamonkey seamonkey-mozilla-build thorium-browser tor tor-browser tor-browser-en tor-browser-ru torbrowser torbrowser-launcher ungoogled-chromium ungoogled-chromium-browser uosbrowser-cn vivaldi vivaldi-stable waterfox waterfox-classic waterfox-current waterfox-icon web-browser webbrowser-app www-browser yast-inetd zen-browser
apps	</>	appimagekit-emacs applications-development applications-engineering atom builder co.anysphere.cursor code code-oss codium com.helix_editor.Helix com.sublimetext.three com.visualstudio.code com.visualstudio.code-oss com.visualstudio.code.oss com.vscodium.codium cursor Cursor customdesktopmenu deepin-emacs dev.lapce.lapce dev.zed.Zed emacs emacs-nox emacs-snapshot geany gnome-emacs gvim helix io.atom.Atom io.neovim.nvim kdevelop lapce neovim nvim nvim-gtk nvim-qt org.daa.NeovimGtk org.geany.Geany org.gnome.Builder org.gnu.emacs org.kde.kdevelop org.vim.Vim package_development pynvim sublime-text sublime-text-2 sublime-text-3 sublime_text tdevelop vim vim-qt visual-studio-code vscode vscodium windsurf xemacs zed
apps	>_	Alacritty alacritty altyo appimagekit-cool-retro-term appimagekit-kitty appimagekit-org.wezfurlong.wezterm bash com.alacritty.Alacritty com.gexperts.Tilix com.mitchellh.ghostty com.raggesilver.BlackBox contour cool-retro-term deepin-terminal Etermutilities-terminal foot ghostty gksu-debian gnome-eterm gnome-term gnome-terminal gnome-xterm guake guake-indicator hotwire kitty konsole lxterminal mate-terminal mini.xterm openterm org.gnome.Console org.gnome.Ptyxis org.gnome.Terminal org.kde.konsole org.kde.qmlkonsole org.kde.yakuake org.wezfurlong.wezterm org.xfce.terminal org.xfce.terminalemulator qterminal rio roxterm rxvt-unicode sakura st terminal Terminal terminal-tango terminator terminix terminology termite tilda tilix urxvt urxvt_48x48 utilities-terminal utilities-x-terminal uxterm wezterm xconsole xfce-terminal xfce4-terminal xterm xterm-color xterm-color_48x48 yakuake
apps	?	2402_msiexec.0 applets-template application-default-icon application-x-executable application-x-generic com.github.zren.commandoutput configurator cs-cat-prefs cs-general gnome-desktop-item-edit gnome-run gnome-system gnome-system-config image-missing org.xfce.genmon org.xfce.panel.cpugraph org.xfce.settings.editor package_applications package_system preferences-autocompletion preferences-system-session-services system-config-services unknown yast-misc yast-runlevel yast-system
apps	@	aerc appimagekit-tutanota-desktop betterbird ch.protonmail.protonmail-bridge claws-mail com.getmailspring.Mailspring com.github.vladimiry.ElectronMail com.tutanota.Tutanota deepin-mail electron-mail email eu.betterbird.Betterbird evolution evolution-mail geary gnome-balsa gnome-balsa2 instantbird internet-mail io.elementary.mail kmail kube kube-mail mail-client mailnag mailspring mutt neomutt org.claws_mail.Claws-Mail org.gnome.Evolution org.gnome.Geary org.kde.kmail2 org.mozilla.Thunderbird org.mozilla.thunderbird org.mozilla.thunderbird_esr org.xfce.mailreader preferences-mail protonmail-bridge ProtonMail_Bridge sylpheed thunderbird thunderbird-bin thunderbird-icon thunderbird-mozilla-build trojita tutanota-desktop unity-mail xfce-mail xfce-newmail xfmail yast-mail
apps	Aa	appimagekit-org.fontforge.FontForge applications-fonts com.github.fontmatrix.Fontmatrix cs-fonts deepin-font-installer deepin-font-manager font-manager fontforge fontmatrix fonts gnome-font-viewer gnome-settings-font kfontview org.fontforge.FontForge org.gnome.font-viewer org.gnome.FontManager preferences-desktop-font preferences-desktop-font-installer yast-x11
apps	[ ]	accessories-screenshot appimagekit-ksnip applets-screenshooter deepin-screenshot flameshot gnome-screenshot gradia grim io.elementary.screenshot kscreengenie ksnapshot ksnip mate-screenshot nwg-screenshot org.flameshot.Flameshot org.gnome.Screenshot org.kde.spectacle org.ksnip.ksnip org.xfce.screenshooter satty screengrab screenshot shutter spectacle swappy xfce4-screenshooter
apps	[x]	com.github.zren.todolist com.ticktick.TickTick com.todoist.Todoist endeavour errands gnome-todo goa-account-todoist io.github.alainm23.planify io.github.mrvladus.List kongress org.gnome.Todo planify planner task-due ticktick todoist
apps	a11y	access accessibility accessibility-directory accessibility_section ax-applet cs-universal-access kmag kmousetool magnifier mate-ax-applet orca org.xfce.accessibility org.xfce.settings.accessibility preferences-desktop-accessibility preferences-desktop-assistive-technology xfce4-accessibility-settings
apps	a2	audiosurf-2 lutris_audiosurf-2 steam_icon_235800 steam_icon_373960
apps	a78	a7800
apps	a7x	a7xpg
apps	aa	AdobeAnimate AdobeAudition aimp-ac aimp-ate
apps	aae	AdobeAfterEffect
apps	aafm	aafm
apps	aam	amnesia-a-machine-for-pigs lutris_amnesia-a-machine-for-pigs steam_icon_239200
apps	ab	AdobeBridge advert-block FDE2_Bridge.0
apps	aba	a-boy-and-his-blob lutris_a-boy-and-his-blob steam_icon_281200
apps	abd	abdownloadmanager ABDownloadManager
apps	abe	abe
apps	abk	deepin-contacts gnome-contacts org.deepin.contacts org.gnome.Contacts
apps	abr	abricotine Abricotine abrowser
apps	aby	abbaye com.locomalito.abbayedesmorts
apps	ac	adventure-capitalist angular-console asbru-cm aspia_console astah-community astah_community astahc lutris_adventure-capitalist steam_icon_346900
apps	aca	AdobeCharacterAnimator
apps	acc	applications-accessories
apps	acr	accerciser acreloaded acroread AdobeReader9 ca.victorz.acr.AssaultCubeReloaded com.adobe.Reader
apps	acs	acestream
apps	act	Acetino2 acetoneiso actiona actionaz activitywatch furiusisomount preferences-desktop-activities
apps	ad	AdobeDimension AdobeDreamweaver ant-downloader appimagekit-ant-downloader appimagekit-diffuse
apps	adb	audiobook
apps	adc	appimagekit-audacium audacium
apps	add	amnesia-the-dark-descent lutris_amnesia-the-dark-descent steam_icon_57300
apps	adj	aperture-desk-job steam_icon_1902490
apps	adl	ADLplug
apps	adm	administration breeze-settings control-center2 drakconf gkdebconf gkdebconf-icon mateconf-editor mintsysadm paprefs redhat-server_settings redhat-tools
apps	adn	audience
apps	ado	a-dance-of-fire-and-ice steam_icon_977950
apps	adr	org.freedesktop.adriconf
apps	ads	audiosurf lutris_audiosurf steam_icon_12900 steam_icon_12910
apps	adt	org.kde.audiotube
apps	ae	AdobeEncore AdobeMediaEncore akregator_empty apk-icon-editor com.bladecoder.adventure-editor
apps	aea	AdobeEdgeAnimate
apps	aes	apk-editor-studio
apps	aeu	au.edu.uq.esys.escript
apps	af	AdobeFirework AdobeFresco AdobeFuse
apps	afb	AdobeFlashBuilder
apps	afl	afl kali-afl
apps	aft	android-file-transfer appimagekit-android-file-transfer
apps	ag	ark-game astah_gsn lutris_ark-survival-evolved steam_icon_346110
apps	agn	agent agentdesktop com.github.dahenson.agenda
apps	agr	agordejo appimagekit-augur augur
apps	ags	aegisub org.aegisub.Aegisub
apps	agv	agave
apps	ai	AdobeIllustrator AdobeIncopy AdobeIndesign alien-isolation lutris_alien-isolation steam_icon_214490
apps	aimp	aimp
apps	aip	org.gnome.design.AppIconPreview
apps	air	adobe-air AdobeAIR air
apps	akn	akonadi akonaditray
apps	akr	akira akregator com.github.akiraux.akira feedreader internet-feed-reader internet-news-reader org.gnome.FeedReader org.kde.akregator pan rss RSS_feeds rssnow rssowl
apps	al	AdobeLightroom
apps	alc	AdobeLightroomClassic alc
apps	alg	alligator org.kde.alligator
apps	alm	almanah
apps	aln	alien-arena alienarena alienblaster alienfx alienfx-gtk org.alienarena.alienarena
apps	als	allusion appimagekit-allusion com.github.bartzaalberg.alias
apps	alt	alltomp3 alltray alterator altmediawriter altus appimagekit-altus
apps	alva	Alva appimagekit-Alva
apps	alx	alexandra
apps	am	AdobeMuse airwave-manager android-messages-desktop AndroidMessages appimagekit-android-messages-desktop apple-music chrome-hblpgmjcnlmnencfjcjcjdajdhloioam-Default gnome-appfolders-manager
apps	amd	amd amd-ati amd-ddm-mx ccc-large ccc_large slimbookamdcontroller
apps	ame	AdobeMediaEncoder
apps	ams	amsynth
apps	an	aircrack-ng kali-aircrack-ng
apps	anb	anbox
apps	and	android-studio-beta android-studio-canary androidstudio-preview
apps	ang	angrysearch
apps	anj	anjuta
apps	anki	anki net.ankiweb.Anki
apps	anm	com.github.lafydev.animage
apps	ans	anoise
apps	ant	anatine Anatine antidote antigravity com.github.phase1geo.annotator
apps	ao	albion-online ao-app com.albiononline.AlbionOnline
apps	aoe	age-of-empires-2 steam_icon_221380
apps	aoi	aoi
apps	aos	adventures-of-shuggy lutris_the-adventures-of-shuggy steam_icon_211440
apps	ap	AdobePhotoshop AdobePrelude astah-pro astah_professional photoshop
apps	apc	apachedirectorystudio appcode org.apache.directory.studio
apps	apd	com.github.donadigo.appeditor
apps	apf	apifox
apps	api	com.getpostman.Postman insomnia postman rest.insomnia.Insomnia
apps	apk	apktool kali-apktool
apps	apl	applixware
apps	app	AdobePremierePro
apps	apr	AdobePremiereRush
apps	apt	aptana aptana-studio
apps	aq	annas-quest lutris_annas-quest steam_icon_327220
apps	aqd	com.endlessnetwork.aqueducts
apps	aql	aqualung
apps	ar	advanced-rest-client amnesia-rebirth appimagekit-advanced-rest-client atom-rpg audio-recorder lutris_amnesia-rebirth lutris_atom-rpg steam_icon_552620 steam_icon_999220
apps	arc	appimagekit-archipelago archipelago com.github.kjlaw89.archetype
apps	ard	ardour Ardour-Ardour_6.0.0 Ardour-Ardour_6.5.0 Ardour-Ardour_8.0.0 ardour6 ardour7 ardour8 arduino arduino-icon-small arduino-ide cc.arduino.arduinoide org.ardour.Ardour
apps	ares	ares dev.ares.ares
apps	arg	argouml
apps	arm	another-redis-desktop-manager appimagekit-another-redis-desktop-manager armagetronad armello armitage kali-armitage lutris_armello org.armagetronad.ArmagetronAdvanced steam_icon_290340
apps	arn	appimagekit-aranym aranym aranym-jit aranym-mmu arianna around org.kde.arianna
apps	ars	airstrike aurees
apps	art	airtame-application artikulate artsbuilder artscontrol com.airtame.Client org.kde.artikulate
apps	arts	arts
apps	arv	airvpn
apps	ary	appimagekit-auryo auryo
apps	as	AdobeSpeedgrade alien-swarm amazon amazon-store amazonclouddrive android-sdk android-studio androidstudio apollo-studio astah_sysml ayatana-settings com.google.AndroidStudio lutris_alien-swarm steam_icon_630 studio
apps	asa	a-story-about-my-uncle allegorithmic-Substance_Alchemist lutris_a-story-about-my-uncle steam_icon_278360
apps	asb	allegorithmic-Substance_B2M
apps	asc	asciidocfx asciiportal
apps	asd	allegorithmic-Substance_Designer
apps	ash	a-short-hike lutris_a-short-hike steam_icon_1055540
apps	ask	aeskulap
apps	asl	assaultcube net.cubers.assault.AssaultCube
apps	asn	asunder ca.littlesvr.asunder
apps	asp	allegorithmic-Substance_Painter aseprite aspia_client com.github.lainsce.aesop lutris_aseprite steam_icon_431730
apps	asr	alien-swarm-reactive-drop lutris_alien-swarm-reactive-drop steam_icon_563560
apps	ast	astromenace com.viewizard.AstroMenace
apps	ath	app.authpass.AuthPass appimagekit-athens athens authpass authy com.authy.Authy
apps	atl	atlantik atlantikdesigner atlauncher com.atlauncher.ATLauncher org.kde.atlantik
apps	atm	appimagekit-atomic atomic pm.mirko.Atoms
apps	atn	atunes
apps	atom	atom-beta atom-nightly
apps	atr	appimagekit-autoremesher autoremesher
apps	ats	american-truck-simulator lutris_american-truck-simulator steam_icon_270880
apps	au	AdobeUpdate among-us astah_uml lutris_among-us steam_icon_945360
apps	av	AmneziaVPN astah_viewer atari-vault com.github.taiko2k.avvie lutris_atari-vault QtAV steam_icon_400020
apps	avc	appimagekit-avocado avocado avocode avocode-app-icon com.avocode.Avocode
apps	avd	avidemux avidemux_icon org.avidemux.Avidemux
apps	avg	avogadro-icon avogadro2 org.openchemistry.Avogadro2
apps	avm	avimetaedit net.mediaarea.AVIMetaEdit
apps	avt	net.natesales.Aviator
apps	aw	alan-wake lutris_alan-wake steam_icon_108710
apps	awgg	awgg
apps	aws	awesomebump
apps	ax	AdobeXD
apps	axc	ar.xjuan.Cambalache
apps	axy	aaaaxy appimagekit-aaaaxy appimagekit-io.github.divverent.aaaaxy io.github.divverent.aaaaxy
apps	azp	appimagekit-azpainter azpainter
apps	azr	azardi azuredatastudio com.azuredatastudio
apps	b2	beholder-2 borderlands-2 lutris_beholder-2 lutris_borderlands-2 steam_icon_49520 steam_icon_761620
apps	ba	broken-age btrfs-assistant lutris_broken-age steam_icon_232790
apps	babe	babe
apps	bac	blobAndConquer
apps	bai	bendy-and-the-ink-machine lutris_bendy-and-the-ink-machine steam_icon_622650
apps	bak	backintime com.borgbase.Vorta deja-dup grsync kbackup kup luckybackup org.gnome.DejaDup org.gnome.World.PikaBackup pika-backup timeshift vorta vorta32
apps	bas	bass beneath-a-steel-sky beyond-a-steel-sky lutris_beneath-a-steel-sky lutris_beyond-a-steel-sky steam_icon_1146310 steam_icon_1368340
apps	bb	app.bluebubbles.BlueBubbles baldis-basics blush-blush brave-browser-nightly brave-origin-nightly lutris_baldis-basics-in-education-and-learning lutris_baldis-basics-plus lutris_blush-blush steam_icon_1275890 steam_icon_777130
apps	bbc	bbc solstice-bbc-bbc
apps	bbd	brave-browser-beta brave-browser-dev
apps	bc	appimagekit-Black_Chocobo betaflight-configurator Black_Chocobo bridge-constructor io.github.betaflight.BetaflightConfigurator lutris_bridge-constructor steam_icon_250460
apps	bcl	becalm steam_icon_999830
apps	bcm	bcompare bridge-constructor-medieval lutris_bridge-constructor-medieval steam_icon_319850
apps	bcp	bridge-constructor-playground bridge-constructor-portal lutris_bridge-constructor-playground lutris_bridge-constructor-portal steam_icon_279990 steam_icon_684410
apps	bcs	bridge-constructor-stunts steam_icon_419080
apps	bd	beamng-drive black-desert lutris_beamngdrive steam_icon_284160 steam_icon_582660
apps	bdg	com.github.elfenware.badger com.github.rajkumaar23.badgie org.ubuntubudgie.budgiewpreviews
apps	bdl	badland BadlionClient lutris_badland-game-of-the-year-edition steam_icon_269670
apps	bdn	baidunetdisk com.baidu.NetDisk
apps	be	appimagekit-brackets-electron brackets-electron
apps	bf	backdoor-factory blackmagic-Fusion8 blackmagic-Fusion9 kali-backdoor-factory
apps	bfd	big-finish-downloader uk.et1.big-finish-downloader
apps	bfr	bforartists
apps	bg	azote background billard-gl btsync-gui cs-backgrounds cs-desktop daily-wallpaper de.billardgl.Billardgl deepin-show-desktop gnome-desktop-config gnome-settings-background hyprpaper nitrogen org.xfce.panel.showdesktop org.xfce.xfdesktop preferences-desktop-background preferences-desktop-wallpaper preferences-wallpaper show-desktop swww user-desktop variety wallpaper waypaper xfce4-backdrop xfdesktop
apps	bgd	bugdom bugdom-desktopicon io.jor.bugdom
apps	bh	beat-hazard lutris_beat-hazard steam_icon_49600 steam_icon_49610
apps	bh2	beat-hazard-2 lutris_beat-hazard-2 steam_icon_618740
apps	bhl	beholder lutris_beholder steam_icon_475550
apps	bi	bioshock-infinite lutris_bioshock-infinite steam_icon_8870
apps	bisq	bisq network.bisq.Bisq
apps	biy	baba-is-you lutris_baba-is-you steam_icon_736260
apps	bkp	org.gnome.gitlab.ilhooq.Bookup
apps	bkr	appimagekit-beaker-browser beaker beaker-browser com.beakerbrowser.Beaker
apps	bl	appimagekit-bitshares2-light bitshares2-light brightness brightness-systray brightnesssettings com.github.panosx2.brightness display-brightness mate-brightness-applet preferences-system-brightness-lock
apps	blb	blobby bloboats blobwars blobwarsAttrition de.blobbyvolley.BlobbyVolley2
apps	blc	blockbench blockout net.blockbench.Blockbench net.blockout.BlockOutII
apps	blf	bluefish mate-panel-fish nl.openoffice.bluefish
apps	blg	blogilo bluegriffon kblogger
apps	blj	bluej bluejeans org.bluej.BlueJ
apps	blk	bulky
apps	blm	appimagekit-bloomrpc bloomrpc bluemail bubblemail net.blix.BlueMail
apps	bln	blinken com.rafaelmardojai.Blanket org.kde.blinken
apps	blr	com.github.tkashkin.boiler
apps	bls	blastem bless com.github.afrantzis.Bless com.gitlab.nvlgit.Balss com.retrodev.blastem
apps	blt	bibletime info.bibletime.BibleTime
apps	bm	baka-mplayer black-mesa com.github.bartzaalberg.bookmark-manager lutris_black-mesa steam_icon_362890
apps	bmb	bambustudio bomber org.kde.bomber
apps	bmg	boomaga
apps	bmv	appimagekit-baiji-manga-viewer baiji-manga-viewer
apps	bmy	com.github.lainsce.beemy
apps	bnc	binance boinc boinc-manager edu.berkeley.BOINC
apps	bnd	bandcamp
apps	bng	bingwall
apps	bnk	org.tabos.banking
apps	bnr	binary-ninja binaryninja BinaryNinja
apps	boi	lutris_the-binding-of-isaac-rebirth steam_icon_250900 the-binding-of-isaac-rebirth
apps	bomi	bomi
apps	bovo	bovo org.kde.bovo
apps	box	box
apps	boxi	dev.boxi.Boxi
apps	bp	blackmagicraw-player
apps	bpr	beeper beepertexts
apps	bps	borderlands-the-pre-sequel lutris_borderlands-the-pre-sequel steam_icon_261640
apps	bpy	bpython bpytop
apps	br	barrier com.github.debauchee.barrier
apps	brc	brackets
apps	brd	birdfont birdie borderlands com.ulduzsoft.Birdtray io.sam.Boards lutris_borderlands steam_icon_729040 steam_icon_8980
apps	brf	bareftp broforce lutris_broforce steam_icon_274190 yast-tftp-server
apps	brn	barony braindump lutris_barony steam_icon_371970
apps	brs	brosix com.brosix.Brosix
apps	brt	barotrauma steam_icon_602960
apps	brw	browser360-beta
apps	bs	beat-saber bitwig-studio blackmagicraw-speedtest bootstrap-studio boxy-svg broken-sword bstudio com.bitwig.BitwigStudio com.boxy_svg.BoxySVG lutris_beat-saber lutris_broken-sword-1-shadow-of-the-templars-directors-cu net.lugsole.bible_gui org.homelinuxserver.vance.biblereader-symbolic steam_icon_57640 steam_icon_620980
apps	bsg	besiege lutris_besiege steam_icon_346010
apps	bsh	bashtop
apps	bsl	basilisk2 gsplus net.cebix.basilisk
apps	bsn	basingstoke bsnes dev.bsnes.bsnes lutris_basingstoke steam_icon_336940
apps	bsp	bespoke_icon
apps	bst	bastion beast boostnote lutris_bastion org.freedesktop.Bustle steam_icon_107100
apps	bsw	boswars
apps	bt	BambooTracker battleblock-theater blueberry bluedevil blueman blueman-device blueman-manager blueradio blueradio-48 bluetooth bluetooth-48 bluetooth-radio bluetoothradio bt-logo cs-bluetooth gnome-break-timer io.github.kaii_lb.Overskride lutris_battleblock-theater org.gnome.BreakTimer overskride preferences-bluetooth preferences-system-bluetooth steam_icon_238460
apps	btc	bitcoin bitcoin-qt bitcoin128 digital-assets fr.fgrabenstaetter.DigitalAssets org.bitcoincore.bitcoin-qt
apps	btf	io.botfather.Botfather
apps	btm	bitmap2component org.kicad.KiCad.bitmap2component
apps	btr	buttercup-desktop
apps	bts	com.feaneron.Boatswain
apps	buho	buho
apps	buka	appimagekit-buka buka Buka
apps	bum	bum
apps	burp	burp burpsuite BurpSuiteCommunity kali-burpsuite
apps	bv	org.gnome.design.BannerViewer
apps	bwf	bwfmetaedit net.mediaarea.BWFMetaEdit
apps	bxb	io.github.dvlv.boxbuddyrs
apps	byb	byobu
apps	byn	appimagekit-info.beyondallreason.bar beyondallreason info.beyondallreason.bar
apps	byte	com.github.alainm23.byte
apps	bzc	appimagekit-bazecor bazecor
apps	bzf	bzflag org.bzflag.BZFlag
apps	bzh	bizhawk
apps	c2	cyberpunk-2077 lutris_cyberpunk-2077 steam_icon_1091500
apps	c5	cudatext-512 io.github.cudatext.CudaText-Qt io.github.cudatext.CudaText-Qt5
apps	ca	cairo-dock caja-actions cisco-anyconnect crack-attack cs-actions cs-applets fma-config-tool nautilus-actions
apps	cad	freecad freecad-daily librecad openscad org.freecad.FreeCAD org.freecadweb.FreeCAD org.librecad.librecad org.openscad.OpenSCAD
apps	cal	agenda calcurse calendar california calligraplan calligraplanner calligraplanwork cats-are-liquid com.github.georgekap1an.chores config-date date dayfolder dde-calendar deepin-calendar evolution-calendar evolution-tasks gnome-calendar gnome-planner io.elementary.calendar kalendar konsolekalendar korganizer merkuro net.sourceforge.osmo office-calendar office-date orage org.gnome.Calendar org.kde.korganizer org.kde.merkuro.calendar org.xfce.orage osmo plan planwork preferences-calendar-and-tasks solstice-microsoft-outlook-calendar steam_icon_498330 xfcalendar ximian-evolution-calendar
apps	calf	calf
apps	cam	accessories-camera appimagekit-webcamoid camera camera-photo camera-web camorama cheese guvcview io.elementary.camera io.github.webcamoid.Webcamoid kamerka kamoso org.gnome.Cheese org.gnome.Snapshot org.kde.kamoso snapshot webcamoid
apps	cave	lutris_the-cave steam_icon_221810 the-cave
apps	cb	colorhug-backlight
apps	cbe	civilization-beyond-earth lutris_sid-meiers-civilization-beyond-earth steam_icon_65980
apps	cc	carla-control castle-crashers colorhug-ccmx crush-crush lutris_castle-crashers lutris_crush-crush org.coolercontrol.CoolerControl steam_icon_204360 steam_icon_459820
apps	cc3d	cc3d cc3d_128x128_logo
apps	cd	cataclysm-dda chocolate-doom chromium-dev org.chocolate_doom.ChocolateDoom
apps	cdb	cdbaby codeblocks org.codeblocks.codeblocks
apps	cdl	codelite
apps	cdn	cadence
apps	cdr	cider Cider sh.cider.Cider
apps	cds	chocolate-doom-setup
apps	ce	cine-encoder contact-editor
apps	cee	calibre-ebook-edit com.calibre_ebook.calibre.ebook-edit
apps	cemu	cemu Cemu info.cemu.Cemu
apps	cewl	cewl kali-cewl
apps	cf	colorhug-flash
apps	cfg	applications-system budgie-control-center cinnamon-settings computersettings deepin-control-center gnome-control-center gnome-settings gnome-tweak-tool gtk-preferences hyprland-settings io.elementary.settings kcontrol kvantummanager lxappearance lxqt-config mate-control-center nwg-look org.buddiesofbudgie.Settings org.gnome.Settings org.gnome.tweaks org.xfce.settings.manager org.xfce.xfwm4-tweaks package_settings plasma-settings preferences-desktop preferences-desktop-animations preferences-desktop-tweaks preferences-other preferences-system qt5ct qt6ct qtconfig qtconfig-qt5 system-settings systemsettings tweaks-app utilities-tweak-tool xfce-system-settings xfce4-mcs-manager xfce4-settings xfce4-settings-manager yast-powertweak
apps	cfn	caffeine
apps	cg	crab-game lutris_crab-game org.rnd2.cpupower_gui steam_icon_1782210
apps	cgt	cycligent cycligent-icon CycligentGitTool
apps	ch	cache
apps	chc	checkbox checkbox-touch checkra1n
apps	chk	appimagekit-chiaki chiaki chkrootkit kali-chkrootkit re.chiaki.Chiaki
apps	chq	choqok org.kde.choqok
apps	chr	appimagekit-cacher cacher cherrytree chirp io.github.leonardschardijn.Chirurgien net.giuspen.cherrytree
apps	chs	chess chessx dreamchess gnome-chess gnome-glchess net.sourceforge.Chessx org.gnome.Chess pychess xboard
apps	cht	chatterino com.chatterino.chatterino
apps	cid	brave-ieailfmhaghpphfffooibmlghaeopach-Default chrome-ieailfmhaghpphfffooibmlghaeopach-Default
apps	ck2	crusader-kings-2 lutris_crusader-kings-ii steam_icon_203770
apps	ckt	cockatrice io.github.Cockatrice.cockatrice
apps	cl	app-launcher chrome-app-list chromium-app-list clion com.jetbrains.CLion cs-login lightdm-gtk-greeter-settings lightdm-settings liteautologin mdmflexiserver mdmsetup preferences-tweaks-slingshot tdmconfig
apps	clb	appimagekit-colobot colobot info.colobot.Colobot
apps	clc	appimagekit-clickup-desktop clickup-desktop clockify
apps	cld	claudia claudia-launcher
apps	clg	clight
apps	clm	clamav clamtk com.dhsdevelopments.Climaxima com.gitlab.davem.ClamTk
apps	cln	appimagekit-colon colon
apps	clp	appimagekit-clipgrab clipgrab com.github.davidmhewitt.clipped
apps	clr	colorhug colortone com.github.cassidyjames.clairvoyant com.github.huluti.Coulr io.github.lainsce.Colorway lutris_colortone org.coolero.Coolero steam_icon_375320
apps	cls	celeste celestia clustertruck com.hunterwittenborn.Celeste dev.geopjr.Collision lutris_celeste lutris_clustertruck org.gnome.Calls steam_icon_397950 steam_icon_504230
apps	clw	clawsker
apps	cm	conky-manager conky-manager2
apps	cmg	com.github.jeremyvaartjes.comgen
apps	cml	com.github.z.Cumulonimbus cumulonimbus
apps	cmn	application-community gnome-commander mucommander
apps	cmp	bleachbit ccsm compiz compton computerjanitor gcleaner org.bleachbit.BleachBit preferences-system-privacy-housekeeping shredder simple-ccsm ubuntu-cleaner
apps	cms	comsol
apps	cmx	commix kali-commix
apps	cmy	cmyktool
apps	cn	ciano ckb-next com.github.robertsanseries.ciano cs-nightlight
apps	cn6	cen64-qt
apps	cnc	connectagram org.gottcode.Connectagram
apps	cnd	io.conduktor.Conduktor
apps	cnf	at.priv.toastfreeware.ConfClerk confclerk net.kirgroup.confy
apps	cng	codes.nora.gDiceRoller
apps	cnk	appimagekit-conky-logomark-violet conky conky-logomark-violet
apps	cnl	cin cinelerra cinelerra-cv cinelerra-gg cinelerra-hv
apps	cnm	cinema4d
apps	cnr	org.gnome.Epiphany.Canary
apps	cns	construo
apps	cnt	cantor cointop com.github.miguelmota.Cointop io.github.lainsce.Countdown org.gnome.design.Contrast org.kde.cantor org.kde.merkuro.contact
apps	cnv	converseen convertall-icon net.fasterland.converseen
apps	cny	cinny in.cinny.Cinny
apps	co	cs-overview preferences-desktop-gestures-screenedges
apps	cod	call-of-duty call-of-duty-2 lutris_call-of-duty lutris_call-of-duty-2 steam_icon_2620 steam_icon_2630
apps	code	io.elementary.code
apps	coh	company-of-heroes-2 lutris_company-of-heroes-2 steam_icon_231430
apps	coin	com.github.lainsce.coin
apps	col	child-of-light lutris_child-of-light steam_icon_256290
apps	con	crypt-of-the-necrodancer lutris_crypt-of-the-necrodancer steam_icon_247080
apps	cozy	com.github.geigi.cozy cozy
apps	cp	charles-proxy credentials-preferences cronopete_preferences cs-panel goa-panel kcmkicker mate-panel minimizeall org.gnome.Shell.CaptivePortal org.xfce.panel tint2 tint2conf xfce4-cpugraph-plugin xfce4-panel
apps	cpd	crayon-physics-deluxe lutris_crayon-physics-deluxe steam_icon_26900
apps	cph	com.github.arshubham.cipher cuphead lutris_cuphead steam_icon_268910
apps	cpm	cosmigo-pro-motion-icon
apps	cpod	appimagekit-cpod cpod
apps	cpt	caption
apps	cpv	cz.pervoj.valdo-gtk
apps	cpy	com.github.cryptowyrm.copypastegrab com.github.hluk.copyq copyq
apps	cr	brave-cmkncekebbebpfilplodngbpllndjkfo-Default chrome-cmkncekebbebpfilplodngbpllndjkfo-Default chrome-remote-desktop citrix-receiver classic-racers cockos-reaper colorhug-refresh cronopete_restore fm.reaper.Reaper org.cubocore.CoreRenamer steam_icon_1037480
apps	crb	corebird
apps	crc	corectrl
apps	crd	cardo
apps	crl	brave-ljcdbnjegamehjigdeiajddkhpihajpk-Default carla chrome-ljcdbnjegamehjigdeiajddkhpihajpk-Default corelvector curlew studio.kx.carla
apps	crm	cromite
apps	crn	crunchyroll
apps	crs	crashplan crossover crossstudio cxmenu-cxoffice-0-crossover deepin-crossover org.gnome.Crosswords org.gnome.Crosswords.Editor preferences-desktop-accessibility-pointing preferences-desktop-cursors
apps	crt	com.github.huluti.Curtail
apps	crv	cervisia
apps	crw	crawl org.develz.Crawl
apps	cry	appimagekit-cryptr appimagekit-org.cryptomator.Cryptomator cryptomator cryptr org.cryptomator.Cryptomator
apps	cs	cave-story cdogs-sdl chrome-store cities-skylines cmake cmake-gui CMakeSetup CMakeSetup32 com.gitlab.coringao.cavestory-nx CraftStudio cs CubicSDR io.github.cxong.cdogs-sdl lutris_cave-story lutris_cities-skylines lutris_counter-strike samba smb4k steam_icon_10 steam_icon_200900 steam_icon_255710 system-config-samba
apps	cs2	cities-skylines-2 lutris_cities-skylines-II steam_icon_949230
apps	cscz	cscz lutris_counter-strike-condition-zero lutris_counter-strike-condition-zero-deleted-scenes steam_icon_100 steam_icon_80
apps	csgo	csgo csgo_linux64 lutris_counter-strike-global-offensive steam_icon_730
apps	css	css lutris_counter-strike-source steam_icon_240
apps	ct	catia christmas-tree custom-toolbox
apps	ctc	blueman-serial com.gitlab.cutecom.cutecom cutecom kminicom
apps	ctf	com.github.linuxhubit.catfacts
apps	ctg	cutegram
apps	ctl	cuttlefish
apps	ctm	cutemarked cutemaze io.github.cloose.CuteMarkEd org.gottcode.CuteMaze
apps	ctn	cutentr org.gnome.World.Citations
apps	ctp	appimagekit-cutepeaks cutepeaks io.github.labsquare.CutePeaks
apps	ctr	appimagekit-cutter catarina citra cutter org.citra_emu.citra re.rizin.cutter
apps	cura	appimagekit-cura-icon com.ultimaker.cura cura-icon
apps	cuyo	cuyo
apps	cv	calibre-viewer com.calibre_ebook.calibre.ebook-viewer
apps	cvk	cinnamon-virtual-keyboard org.xfce.panel.xkb
apps	cvl	civilization5 civilization6 lutris_sid-meiers-civilization-v lutris_sid-meiers-civilization-vi steam_icon_289070 steam_icon_8930
apps	cvp	cavepacker-icon cvpcb
apps	cvx	caveexpress-icon
apps	cwb	cawbird
apps	cws	org.gnome.gitlab.Cowsay
apps	cx	cpu-x io.github.thetumultuousunicornofdarkness.cpu-x
apps	cyan	appimagekit-Cyan cyan Cyan
apps	cyp	coypu
apps	czk	com.github.qarmin.czkawka
apps	czy	appimagekit-cozydrive cozydrive
apps	d2	diablo-2 opendiablo2
apps	da	cs-default-applications downloader-arrow org.xfce.settings.default-applications preferences-desktop-applications preferences-desktop-default-applications rexloader uos-downloadmanager
apps	dab	double-action-boogaloo lutris_double-action-boogaloo steam_icon_317360
apps	dash	dash-qt
apps	db	asounder audex brasero disk-burner dissenter-browser iso-image-burn k3b org.gnome.Brasero org.xfce.xfburn ripperx stock_xfburn xfburn
apps	dbl	Diablo dooble
apps	dbo	dragon-ball-online-global
apps	dbx	dragon-ball-xenoverse steam_icon_323470
apps	dc	com.discordapp.Discord com.discordapp.DiscordCanary com.github.rickybas.date-countdown dead-cells dev.vencord.Vesktop discord discord-bin discord-canary discord-ptb gtkcord io.github.spacingbat3.webcord lutris_dead-cells solstice-discord-discord steam_icon_588650 vesktop webcord
apps	dcb	org.gnome.Decibels
apps	dcd	com.belmoussaoui.Decoder
apps	dck	appimagekit-dockstation appimagekit-duckstation-qt appimagekit-duckstation-sdl dockbarx dockstation duckduckgo duckstation duckstation-qt duckstation-sdl org.duckstation.DuckStation
apps	dcm	Dicomizer
apps	dcp	deepin-cloud-print-configurator deepin-cloudprint-config-helper printer-driver-deepin-cloud-print
apps	dcs	deepin-cloud-scan-config-helper
apps	dct	aarddict accessories-dictionary artha com.github.lainsce.palaura dictionary flegita gnome-dictionary goldendict org.gnome.Dictionary org.goldendict.GoldenDict org.xfce.Dictionary palaura xfce4-dict
apps	dd	abaddon deepin-draw discord-development dmd-doc dsda-doom
apps	ddl	doki-doki-literature-club doki-doki-literature-club-plus lutris_doki-doki-literature-club steam_icon_1388880 steam_icon_698780
apps	ddm	appimagekit-doki-doki-mod-manager doki-doki-mod-manager
apps	de	ca.desrt.dconf-editor dconf-editor dolphin-emu doom-eternal dosbox-ece lutris_doom-eternal org.DolphinEmu.dolphin-emu steam_icon_782330
apps	demo	gtk3-demo gtk4-demo org.gnome.Adwaita1.Demo
apps	df	appimagekit-balena-etcher-electron balena-etcher balena-etcher-electron balenaetcher blivet-gui com.github.artemanufrij.imageburner d-feet deepin-boot-maker deepin-diskmanager deepin-feedback disk-manager disk-usage-analyzer disk-utility diskmonitor drive-harddisk drive-harddisk-usb etcher etcher-electron gdmap_icon gnome-disk-utility gnome-disks gnome-multi-writer gparted gsmartcontrol imagewriter impression io.elementary.feedback io.gitlab.adhami3310.Impression kcmpartitions kdf kdiskfree kwikdisk matepalimpsest mintstick multibootusb multisystem multisystem-liveusb multisystem-vbox mx-usb-unmounter ntfs-config org.gnome.DiskUtility org.gnome.MultiWriter org.kde.isoimagewriter org.kde.kdf org.kde.partitionmanager palimpsest partitionmanager preferences-desktop-feedback preferences-smart-status QDiskInfo qdiskinfo rosa-imagewriter tuxboot unetbootin usb-creator usb-creator-gtk usb-creator-kde usbimager ventoy xfce-mount yast-disk
apps	dfc	defcon lutris_defcon steam_icon_1520
apps	dfl	deflemask
apps	dfs	diffuse io.github.mightycreak.Diffuse
apps	dft	org.gnome.dfeet
apps	dg	dangerous-golf drweb-gui steam_icon_405500
apps	dgk	digikam org.kde.digikam
apps	dgt	com.scoutshonour.Digital digitallyimported
apps	di	appimagekit-draw.io com.jgraph.drawio.desktop dde-introduction dead-island display-im6.Q16 display-im6.q16 display.im6 draw.io drawio lutris_dead-island-definitive-edition lutris_dead-island-riptide-definitive-edition steam_icon_383150 steam_icon_383180
apps	dia	dia org.gnome.Dia
apps	ding	ding
apps	dino	dino im.dino.Dino
apps	dj	io.github.trytonvanmeer.DungeonJournal
apps	djv	djv
apps	dk	door-kickers lutris_door-kickers steam_icon_248610
apps	dkr	docker docker-desktop
apps	dkt	dukto
apps	dl	dillo dying-light lutris_dying-light steam_icon_239140
apps	dln	brave-jneocipojkkahfcibhjaiilegofacenn-Default chrome-jneocipojkkahfcibhjaiilegofacenn-Default duolingo ro.go.hmlendea.DL-Desktop
apps	dlr	appimagekit-delir delir
apps	dlt	appimagekit-deltachat-desktop chat.delta.desktop deltachat deltachat-desktop deltarune lutris_deltarune steam_icon_1671210 steam_icon_1690940
apps	dm	deepin-manual deepin-movie io.github.lainsce.DotMatrix
apps	dm3	dhewm3 doom3 lutris_doom-3 org.dhewm3.Dhewm3 steam_icon_9050
apps	dm4	org.gtk.Demo4
apps	dmn	appimagekit-dmanager dmanager
apps	dms	doomseeker
apps	dn	claw clipit clipit-trayicon clipman clipse-gui diodon glipper glippy gpaste kali-reporting-tools-trans klipper parcellite qlipper xclipboard xfce4-clipman-plugin
apps	dng	danganronpa lutris_danganronpa-trigger-happy-havoc steam_icon_413410
apps	dnm	denemo org.denemo.Denemo
apps	do	gnome-do gnome-do-panel
apps	doa	dead-or-alive-6 lutris_dead-or-alive-6 steam_icon_838380
apps	dods	dods lutris_day-of-defeat-source steam_icon_30 steam_icon_300
apps	done	dev.edfloreshz.Done
apps	doom	doom freedm io.github.freedoom.FreeDM steam_icon_379720
apps	dot	day-of-the-tentacle-remastered lutris_day-of-the-tentacle-remastered steam_icon_388210
apps	dp	com.github.cassidyjames.dippi davinci-panels DV_Panels
apps	dpg	dgse_logo_128 dupeguru
apps	dpl	duplicati
apps	dpm	appimagekit-dopamine dopamine
apps	dpn	deepin-launcher
apps	dpy	arandr autorandr cs-display cs-screen disper display display-capplet gnome-display-properties grandr gsd-xrandr kscreen lxrandr mate-preferences-desktop-display network.cycles.wdisplays nwg-displays org.xfce.display org.xfce.settings.display preferences-desktop-display randr resapplet system-config-display unity-display-panel video-display wdisplays xfce4-display xfce4-display-settings XrendrMixer
apps	dr	dirt-rally io.github.Youda008.DoomRunner lutris_dirt-rally steam_icon_310560
apps	dra	deepin-remote-assistance
apps	drc	driconf driconf-icon
apps	drd	droidcam Droidcam
apps	drg	com.endlessnetwork.dragonsapprentice dragonframe4
apps	drk	com.github.bluesabre.darkbar darktable org.darktable.Darktable
apps	drm	device-notifier drive-removable-media
apps	drp	caja-dropbox com.dropbox.Client dropbox kdepim-dropbox
apps	drt	deepin-repair-tools dirt4 lutris_dirt-4 steam_icon_421020
apps	drw	appimagekit-drawpile com.github.maoschanz.drawing darwinia drawpile libreoffice-draw libreoffice7.3-draw libreoffice7.4-draw libreoffice7.5-draw libreoffice7.6-draw lutris_darwinia net.drawpile.drawpile org.libreoffice.LibreOffice.draw steam_icon_1500
apps	ds	dont-starve dosbox-staging drill-search drill-search-gtk io.github.dosbox-staging lutris_dont-starve org.dosbox-staging.dosbox-staging steam_icon_219740
apps	ds9	ds9
apps	dsb	com.dosbox.DOSBox dosbox
apps	dsd	dassault-systemes.draftsight draftsight
apps	dse	dse
apps	dsk	app.organicmaps.desktop appimagekit-ark-desktop-wallet appimagekit-deskreen appimagekit-duskplayer ark-desktop-wallet com.github.spheras.desktopfolder deskreen duskplayer io.ark.Desktop
apps	dsm	desmume DeSmuME org.desmume.DeSmuME
apps	dspy	org.gnome.dspy
apps	dsr	desura
apps	dst	appimagekit-Dstroy2 appimagekit-dust3d dont-starve-together Dstroy2 dust3d lutris_dont-starve-together org.dust3d.dust3d steam_icon_322330
apps	dt	applications-development-translation d-tracker deepin-toggle-desktop
apps	dt2	dota2 lutris_dota-2 steam_icon_570
apps	dtc	dotcover
apps	dtf	com.github.aimproxy.dotfonts
apps	dtm	datamodeler dk.tangramgames.mrrescue dotmemory
apps	dtp	com.scoutshonour.dtipbijays dotpeek
apps	dtr	dottrace
apps	dts	com.jetbrains.DataSpell com.jetbrains.dataspell dataspell datastudio jetbrains-dataspell
apps	dtv	datovka org.cznic.Datovka
apps	dtw	com.neatdecisions.Detwinner
apps	du	baobab diskonaut dota-underlords filelight gdmap k4dirstat lutris_dota-underlords mate-disk-usage-analyzer ncdu org.gnome.baobab org.kde.filelight qdirstat steam_icon_1046930
apps	dusk	dusk lutris_dusk steam_icon_519860
apps	dvd	brave-ahiigpfcghkbjfcibpojancebdfjmoop-Default chrome-ahiigpfcghkbjfcibpojancebdfjmoop-Default deepin.com.wechat.devtools devdocs dvdisaster
apps	dvh	appimagekit-devhub devhelp devhub kali-docs org.gnome.Devhelp
apps	dvl	com.github.alcadica.develop devilutionx org.diasurgical.DevilutionX
apps	dvm	davmail org.davmail.DavMail
apps	dvn	deepin-voice-note deviantart dvanalyzer net.mediaarea.DVAnalyzer solstice-deviantart-deviantart
apps	dvp	devpod sh.loft.devpod
apps	dvs	devassistant
apps	dw	applications-development-web me.dusansimic.DynamicWallpaper
apps	dwe	com.github.maoschanz.DynamicWallpaperEditor
apps	dwn	appimagekit-downline downline
apps	dx	com.dosbox_x.DOSBox-X dosbox-x
apps	dyj	com.github.thejambi.dayjournal
apps	dyn	ddaynormandy
apps	dzr	deezer dev.aunetx.deezer lash
apps	e2	lutris_the-escapists-2 steam_icon_641990 the-escapists-2
apps	ea	appimagekit-electrum-axe electrum-axe
apps	eam	io.github.achetagames.epic_asset_manager
apps	ease	ease
apps	eb	enhanced_browsing
apps	ebs	eBook-speaker
apps	ec	appimagekit-electron-cash eclipse-cdt electron-cash
apps	ech	echomixer echonest
apps	ecl	eclipse eiciel mate-eiciel org.eclipse.Java org.eclipse.Javascript
apps	eco	eco lutris_eco steam_icon_382310
apps	ed	edb edb-debugger engauge-digitizer exploit-db io.github.eteran.edb-debugger io.github.markummitchell.Engauge_Digitizer kali-edb-debugger kali-exploitdb org.es_de.emulationstation-de
apps	edc	applications-education package_edutainment
apps	eddy	com.github.donadigo.eddy
apps	edk	com.eduke32.EDuke32 eduke32
apps	eev	easy-ebook-viewer
apps	ef	exfalso io.github.quodlibet.ExFalso
apps	eg	09BE_EpicGamesLauncher.0 ED2E_EpicGamesLauncher.0 edge-game enter-the-gungeon epic-games epiphany-game lutris_edge lutris_enter-the-gungeon lutris_epic-games-store steam_icon_311690 steam_icon_38740
apps	egl	eagle
apps	eia	emily-is-away emily-is-away-too lutris_emily-is-away lutris_emily-is-away-too steam_icon_417860 steam_icon_523780
apps	ejc	com.szibele.e-juice-calc
apps	ekb	eekboard
apps	ekg	ekiga
apps	el	desktop-environment-lxqt electrum-ltc lxqt lxqt-about org.gnome.Eolie
apps	elc	appimagekit-electorrent applications-electronics electorrent electrip electron electron22 electron23 electron24 electron25 electron27 electron31 electron32 electron33 electron34 electron35 electron36 electron37 electrum io.atom.electron.BaseApp net.sourceforge.electrip.Electrip org.electrum.electrum
apps	elm	com.github.eudaldgr.elements element-desktop-nightly element-nightly element4l lutris_element4l steam_icon_235820
apps	elp	de.unifreiburg.ellipticcurve
apps	elx	elixir
apps	em	applications-education-mathematics
apps	emb	org.gnome.design.Emblem
apps	eml	amule amulegui emulationstation emule io.github.lainsce.Emulsion kamule
apps	emp	enjoy-music-player
apps	emt	amor ksmiletris package_toys preferences-desktop-emoticons
apps	enc	appimagekit-encryptpad encryptpad Encryptr encryptr fr.handbrake.ghb handbrake hb-icon
apps	eng	com.github.subhadeepjasu.enigma
apps	ens	com.github.subhadeepjasu.ensembles ensembles
apps	ent	entangle ente_auth enteauth io.ente.auth org.entangle_photo.Manager
apps	ente	ente
apps	env	awf com.github.cjfloss.envelope desktop-environment-gnome envy24control gnome-about-logo gnome-logo-icon gnome-logo-icon-transparent gnome_apps gtk-info gtkconfig kde-gtk-config kpk-desktop-gnome org.gnome.ChromeGnomeShell preferences-gtk-config
apps	enve	appimagekit-enve enve io.github.maurycyliebner.enve
apps	eph	com.github.cassidyjames.ephemeral io.github.htkhiem.Euphonica
apps	eps	epsonscan2 epsxe escan2_app net.epson.epsonscan2 pcsxr pcsxr-icon psx
apps	eq	io.github.ezQuake
apps	eqn	eqonomize
apps	er	abrt apport apport-gtk2 bug-buddy com.github.timecraft.notifier gnome-abrt gnome-warning kali-bugs kbugbuster mintreport org.freedesktop.GnomeAbrt script-error system-error
apps	eric	eric eric6
apps	erk	eureka
apps	es	emby-server endless-sky estmob-sendanywhere io.github.endless_sky.endless_sky lutris_endless-sky media.emby.EmbyServer media.emby.EmbyTheater SendAnywhere steam_icon_404410
apps	esa	edu.stanford.Almond
apps	esc	eeschema gnome-oregano oregano org.kicad.KiCad.eeschema
apps	esk	eiskaltdcpp
apps	esv	lutris_the-elder-scrolls-v-skyrim steam_icon_489830 steam_icon_72850 the-elder-scrolls-v-skyrim
apps	esy	com.github.muriloventuroso.easyssh easyeda easymp3gain easystroke easytag EasyTAG_icon org.gnome.EasyTAG qtgain
apps	et	app.drey.EarTag desktop-environment-tde go kicker tde
apps	eth	etherape ethereumwallet etherwall
apps	etl	com.etlegacy.ETLegacy etl
apps	etm	emerald-theme-manager emerald-theme-manager-icon
apps	etr	eternallands etr ettercap kali-ettercap org.pjbroad.EternallandsClient
apps	ets	euro-truck-simulator-2 lutris_euro-truck-simulator-2 steam_icon_227300
apps	eu	appimagekit-edex-ui desktop-environment-unity edex-ui
apps	eui	europa-universalis-IV lutris_europa-universalis-iv steam_icon_236850
apps	ev	eid-viewer
apps	evl	evelauncher
apps	evnc	evnc
apps	evr	everdo evernote evernote-client everpad eversion lutris_eversion nixnote steam_icon_33680
apps	evt	evtest-qt
apps	ew	ericWeb ericWeb6
apps	exc	excalidraw
apps	exd	exodus io.exodus.Exodus
apps	exl	exult
apps	exm	exmplayer
apps	exp	appimagekit-expandrive expandrive
apps	ext	extraterm org.gnome.Extensions org.gnome.Shell.Extensions
apps	eyes	mate-eyes-applet xeyes xfce4-eyes
apps	ez	endless-zone lutris_endless-zone steam_icon_1368450
apps	f(x)	libreoffice-math libreoffice7.3-math libreoffice7.4-math libreoffice7.5-math libreoffice7.6-math org.libreoffice.LibreOffice.math
apps	f2	f1-2015 f1-2017 lutris_f1-2015 lutris_f1-2017 steam_icon_286570 steam_icon_515220
apps	f3d	f3d io.github.f3d_app.f3d
apps	fb	fran-bow frozen-bubble lutris_fran-bow org.frozen_bubble.frozen-bubble steam_icon_362680
apps	fbl	com.endlessnetwork.fablemaker dk.sunsite.foobillard foobillardplus
apps	fbm	appimagekit-caprine caprine Caprine com.sindresorhus.Caprine FacebookMessenger-facebook.com fbmessenger messengerfordesktop solstice-facebook-facebook-messenger
apps	fbn	foobnix
apps	fbr	fbreader FBReader
apps	fc	apparmor_view_profile com.github.Bleuzen.FFaudioConverter cs-firewall deepin-defender draksec-mdk firewall-config FlashCS6 fwbuilder gufw network-firewall preferences-certificates preferences-system-firewall yast-apparmor yast-firewall
apps	fcb	brave-kippjfofjhjlffjecoapiogbkgbpmgej-Default chrome-kippjfofjhjlffjecoapiogbkgbpmgej-Default facebook facebook-facebook.com facebookresource goa-account-facebook solstice-facebook-facebook unity-webapps-facebook
apps	fcs	focuswriter org.gottcode.FocusWriter
apps	fct	factor factorio lutris_factorio steam_icon_427520
apps	fcx	ca._0ldsk00l.Nestopia fceu fceux nestopia
apps	fd	ffado hi64-apps-ffado org.gustavoperedo.FontDownloader
apps	fdn	feedindicator
apps	fez	fez lutris_fez steam_icon_224760
apps	fft	ftl-faster-than-light lutris_ftl-faster-than-light steam_icon_212680
apps	fg	appimagekit-filmulator-gui fall-guys filmulator-gui filmulator-gui64 lutris_fall-guys org.filmulator.Filmulator steam_icon_1097150
apps	fgm	figma figma-linux io.github.Figma_Linux.figma_linux
apps	fh5	forza-horizon-5 steam_icon_1551360
apps	fhc	FAHControl
apps	fhr	fheroes2 io.github.ihhub.Fheroes2
apps	fia	four-in-a-row org.gnome.Four-in-a-row
apps	fiji	fiji
apps	fish	fish
apps	fk	for-the-king lutris_for-the-king steam_icon_527230
apps	flb	filebot net.filebot.FileBot
apps	flc	com.github.Flacon flacon flickr goa-account-flickr
apps	fld	fluid folder folder_doc_q4os_startmenu org.xfce.panel.directorymenu
apps	flg	flightgear org.flightgear.FlightGear
apps	flj	fluajho
apps	flm	flamerobin
apps	fln	filen filendesktop
apps	flow	calligraflow flow
apps	flp	com.inventwithpython.flippy
apps	flr	de.schmidhuberj.Flare flare flareget org.flarerpg.Flare
apps	fls	adobe-flashplayer AdobeFlash adobeflashplugin com.adobe.Flash-Player-Projector com.flashforge.FlashPrint flash flash-player-properties flashforge flashplayer flashplayerproperties
apps	flt	com.github.tchx84.Flatseal filter net.sourceforge.Fillets preferences-desktop-filter
apps	flw	flowblade io.github.diegoivanme.flowtime io.github.jliljebl.Flowblade
apps	flx	fluxgui
apps	fly	flycast org.flycast.Flycast
apps	fman	fman
apps	fmit	fmit io.github.gillesdegottex.FMIT
apps	fml	ffmulticonverter
apps	fmp	ffmpeg
apps	fmt	famitracker
apps	fnd	com.github.artemanufrij.findfileconflicts com.github.calo001.fondo
apps	fnk	funkin lutris_friday-night-funkin
apps	fnt	appimagekit-fontbase fontbase fontypython
apps	fom	five-or-more org.gnome.five-or-more
apps	fp	application-x-pml18 application-x-pml18free application-x-prl18 application-x-prl18free floating-point freeoffice-planmaker freeoffice-presentations lutris_floating-point steam_icon_302380 xfce4-fsguard-plugin
apps	fpe	appimagekit-ff-password-exporter ff-password-exporter
apps	fpw	xfce4-fsguard-plugin-warning
apps	fr	appimagekit-fluent-reader fluent-reader me.hyliu.fluentreader
apps	fr2	far2l
apps	frc	appimagekit-org.freac.freac freac freeciv-client org.freac.freac org.freeciv.gtk322 org.freeciv.qt org.freeciv.sdl2 org.gnome.Fractal
apps	frd	fdm ferdium freedesktop freedoom1 freedoom2 freedownloadmanager freedroid freedroidrpg io.github.Freedoom-Phase-1 io.github.Freedoom-Phase-2 io.github.freedoom.Phase1 io.github.freedoom.Phase2 org.ferdium.Ferdium org.freedownloadmanager.Manager
apps	frf	firefox-nightly freefilesync org.freefilesync.FreeFileSync
apps	frg	com.endlessnetwork.frogsquash com.frogatto.Frogatto forager freegish frogatto frogr lutris_forager org.gnome.frogr steam_icon_751780
apps	frk	forkgram
apps	frm	com.github.djaler.formatter firmware-manager gnome-firmware kde-frameworks org.gnome.Firmware
apps	frn	appimagekit-franz com.meetfranz.Franz franz freeorion
apps	frp	freeplane org.freeplane.App
apps	frs	foursquare frescobaldi goa-account-foursquare org.frescobaldi.Frescobaldi
apps	frt	appimagekit-Freeter appimagekit-friture com.lakoliu.Furtherance firetools forticlient forticlientsslvpn freetennis Freeter friture fritzing fritzing_icon org.fritzing.Fritzing org.icculus.tennix tennix
apps	frw	firewatch lutris_firewatch steam_icon_383870
apps	frz	appimagekit-freezer freezer
apps	fs	FamiStudio fcitx-sogoupinyin freeciv-server org.famistudio.FamiStudio
apps	fsh	feishin org.jeffvli.feishin
apps	fsl	fslint_icon
apps	fsn	fusion-icon
apps	fspy	appimagekit-fspy fspy
apps	fst	fasttracker2
apps	ft	application-x-tml18 application-x-tml18free freeoffice-textmaker
apps	ftb	com.github.mirkobrombin.football football ftb-app net.sourceforge.TuxFootball steam_icon_378120
apps	fth	feather feathernotes org.featherwallet.Feather
apps	ftp	appimagekit-FreeTexturePacker filezilla FreeTexturePacker org.filezillaproject.Filezilla
apps	ftr	full-throttle-remastered lutris_full-throttle-remastered steam_icon_228360
apps	fu	firejail-ui fs-uae fs-uae-launcher net.fsuae.FS-UAE
apps	fua	fs-uae-arcade
apps	fun	antimicro appimagekit-heroic appimagekit-retroarch appimagekit-sc-controller applications-games bottles ch.tlaun.TL com.heroicgameslauncher.hgl com.libretro.RetroArch com.mojang.Minecraft com.playonlinux.PlayOnLinux4 com.thebrokenrail.MCPIReborn com.usebottles.bottles com.valvesoftware.Steam deepin-game-center faugus-launcher gamehub gnome-games heroic input-gamepad input-joystick io.github.antimicrox.antimicrox io.github.sharkwouter.Minigalaxy io.itch.itch itch jstest-gtk legacylauncher lutris lutris_minecraft minecraft minecraft-launcher minecraft-pi minigalaxy net.lutris.Lutris org.gnome.Games org.libretro.RetroArch org.phoenicis.playonlinux org.prismlauncher.PrismLauncher package_games playonlinux playonlinux4 preferences-desktop-gaming prismlauncher qjoypad retroarch ru.turikhay.tlauncher sc-controller steam steam-icon steam-launcher steam_icon_1118310 steampowered
apps	fuse	fbzx fuse fuse-emulator net.sf.fuse_emulator net.sourceforge.fuse_emulator.Fuse
apps	fv	org.gnome.FontViewer
apps	fwc	fern-wifi-cracker kali-fern-wifi-cracker
apps	fwp	fwupd org.freedesktop.fwupd
apps	fx	fofix fretsonfire net.sourceforge.fretsonfire
apps	fyn	org.fooyin.fooyin
apps	fzb	fyi.zoey.Boop-GTK
apps	g3	gta-3 lutris_grand-theft-auto-iii re3 steam_icon_12100
apps	g30	glabels glabels-3.0 org.gnome.glabels-3
apps	g5	gta-5 lutris_grand-theft-auto-v steam_icon_271590
apps	ga	google-agenda grid-autosport lutris_grid-autosport steam_icon_255220
apps	gau	goa-account-ubuntusso
apps	gb5	gda-browser-5.0
apps	gbr	gbrainy geogebra Geogebra geogebra-classic org.geogebra.GeoGebra org.gnome.gbrainy
apps	gbt	com.github.gabutakut.gabutdm com.github.lachhebo.Gabtag
apps	gbx	goobox media-import-audio-cd
apps	gc	brave-mdpkiolbdkhdjpekfbkbmhigcaggjagi-Default brave-pmcngklofgngifnoceehmchjlildnhkj-Default chrome-mdpkiolbdkhdjpekfbkbmhigcaggjagi-Default chrome-pmcngklofgngifnoceehmchjlildnhkj-Default google-chat google-chat-linux google-contacts grub-customizer
apps	gcc	gda-control-center
apps	gcm	com.endlessnetwork.missilemath gcompris gcompris-qt org.kde.gcompris
apps	gcs	gcstar
apps	gd	brave-aghbiahbpaijignceidepookljebhfak-Default chrome-aghbiahbpaijignceidepookljebhfak-Default google-docs google-drive googledrive grive kdepim-googledrive overgrive unity-scope-gdrive web-google-drive
apps	gdc	gddccontrol
apps	gdl	appimagekit-gdlauncher gdlauncher gdlauncher-appimage gdlauncher-bin io.gdevs.GDLauncher
apps	gdt	godot godot-mono lutris_godot-engine org.godotengine.Godot org.godotengine.Godot3 steam_icon_404790
apps	gdv	com.github.coralynnmay.goodvibesapp gdevilspie goodvibes gst-debug-viewer io.gitlab.Goodvibes org.freedesktop.GstDebugViewer
apps	ge	gcompris-edit gconf-editor gconfeditor preferences-desktop-accessibility-zoom
apps	gens	gens
apps	gep	com.google.EarthPro google-earth google-earth-pro googleearth
apps	gfc	appimagekit-gifcurry com.lettier.gifcurry gifcurry
apps	gfd	org.gabmus.gfeeds org.gabmus.gnome-feeds
apps	gfi	com.github.jmoerman.go-for-it de.manuel_kehl.go-for-it go-for-it
apps	gfie	gfie_icon
apps	gfp	com.github.bharatkalluri.gifup gifup
apps	gfr	brave-egmafekfmcnknbdlbfbhafbllplmjlhn-Default chrome-egmafekfmcnknbdlbfbhafbllplmjlhn-Default com.nvidia.geforcenow geforcenow geforcenow-nativefier grim-fandango-remastered io.github.hmlendea.geforcenow-electron lutris_grim-fandango-remastered steam_icon_316790
apps	gftp	gftp
apps	gg	gens-gs org.srb2.SRB2 srb2
apps	gga	graebert-gmbh.ares-commander
apps	gh	gargoyle-house io.github.garglk.Gargoyle kfm_home
apps	ghd	ghidra org.ghidra_sre.Ghidra
apps	ghex	ghex org.gnome.GHex
apps	ghs	com.github.padjis.ghistory gahshomar org.gahshomar.Gahshomar
apps	gimp	gimp org.gimp.GIMP
apps	gish	gish lutris_gish steam_icon_9500
apps	git	app appimagekit-github-desktop com.axosoft.GitKraken com.github.git_cola.git-cola git git-cola git-dag git-gui gitg github-desktop gitkraken GitKraken io.github.shiftey.Desktop org.gnome.gitg
apps	gjm	gajim org.gajim.Gajim
apps	gk	GPG-Key4
apps	gksu	gksu kali-social-engineering-trans user-admin
apps	gl	giggle goa-account-google google gpk-log gpsd-logo gtk-network org.xfce.Gigolo org.xfce.gigolo
apps	glb	glob2-icon glob2-icon-48x48
apps	gld	gg.guilded.Guilded glade glade-3 gladish guilded net.baseart.Glide org.gnome.Glade
apps	glm	gelemental
apps	gln	gogland
apps	glt	galternatives
apps	gly	golly
apps	gm	app.gummi.gummi brave-kjgfgldnnfoeklkmfkjfagphfepbbdan-Default brave-mnhkaebcjjhencmpkapnbdaogjamfbcj-Default chrome-kjgfgldnnfoeklkmfkjfagphfepbbdan-Default chrome-mnhkaebcjjhencmpkapnbdaogjamfbcj-Default google-maps google-meet gummi io.gitlab.hamadmarri.gamma net.christianbeier.Gromit-MPX solstice-google-maps
apps	gmb	gambas3
apps	gmh	com.github.tkashkin.gamehub
apps	gmic	gmic_qt
apps	gmj	gamejolt
apps	gml	appimagekit-gmail-desktop brave-fmgjjmmmlfnkbppncabfkddbjimcfncm-Default checkgmail chrome-fmgjjmmmlfnkbppncabfkddbjimcfncm-Default gmail gmail-desktop GMail-mail.google.com Gmail-mail.google.com gmail-notify-icon gmail-plasmoid gmailwatcher gnome-gmail solstice-google-gmail unity-webapps-gmail web-google-gmail
apps	gmn	calligragemini gemini
apps	gms	GameMakerStudio2 gammastep
apps	gmt	gmtpicon
apps	gnac	gnac
apps	gnb	gnubg
apps	gng	com.github.jeremypw.gnonograms gngeo
apps	gnk	geonkick
apps	gns3	gns3
apps	gnv	gnvim
apps	gny	genymotion genymotion-bin
apps	go	com.jetbrains.GoLand gmail-offline goland web-google-gmail-offline
apps	gol	com.github.sixpounder.GameOfLife
apps	gp	anbox-com-android-vending brave-ncmjhecbjeaamljdfahankockkkdmedg-Default chrome-ncmjhecbjeaamljdfahankockkkdmedg-Default genymotion-player google-photos google-play gp gpk-prefs guake-prefs solstice-google-photos
apps	gp6	GP6-icon guitarpro6
apps	gpd	gpdftext gpodder mygpo org.gpodder.gpodder
apps	gph	gaphor org.gaphor.Gaphor
apps	gpl	gaupol io.otsaloma.gaupol
apps	gpm	com.googleplaymusicdesktopplayer.GPMDP google-play-music-desktop-player gpmdp
apps	gpn	gpaint
apps	gpr	com.ranfdev.Geopard gpredict-icon net.oz9aec.Gpredict
apps	gpx	gpx-viewer gpxviewer nl.sarine.gpx-viewer
apps	gqrx	appimagekit-gqrx gqrx kali-gqrx
apps	gr	GammaRay green-recorder org.gabmus.giara
apps	gram	app.liten.Gram gram
apps	grb	gerbera gerbview org.kicad.KiCad.gerbview
apps	grd	com.github.GradienceTeam.Gradience com.vzhd1701.gridplayer gridplayer
apps	grf	com.chez.GrafX2 grafx2
apps	grl	it.mijorus.gearlever
apps	grm	gramps gramwallet org.gramps_project.Gramps
apps	grn	clanbomber granatier granule greenfoot kali-exploitation-tools-trans nl.g4d.Girens org.greenfoot.Greenfoot org.kde.granatier
apps	grp	CE93_RobloxPlayerLauncher.0 com.github.artemanufrij.graphui grapejuice grapejuice-roblox-player io.github.vinegarhq.Vinegar.player net.brinkervii.grapejuice net.brinkervii.grapejuice.robloxplayer
apps	grs	631F_RobloxStudioLauncherBeta.0 grapejuice-roblox-studio grass io.github.vinegarhq.Vinegar.studio net.brinkervii.grapejuice.robloxstudio org.osgeo.grass
apps	grt	gretl
apps	grv	groove groovy
apps	gry	garrysmod lutris_garrys-mod steam_icon_4000
apps	gs	appimagekit-glyphr-studio-desktop dev.gbstudio.gb-studio gb-studio glyphr-studio-desktop google-slides icon_gentoo_small io.github.realmazharhussain.GdmSettings
apps	gsc	appimagekit-guiscrcpy guiscrcpy in.srev.guiscrcpy
apps	gsh	gshutdown
apps	gsp	gespeaker
apps	gsr	com.dec05eba.gpu_screen_recorder gpu-screen-recorder
apps	gst	appimagekit-gisto com.gitlab.cunidev.Gestures com.leinardi.gst gisto gst
apps	gt	appimagekit-google-tasks-desktop google-tasks-desktop google-translate gottet net.bartkessels.getit org.gottcode.Gottet
apps	gtb	gitblade
apps	gtf	appimagekit-gitify gitify
apps	gtg	org.gnome.GTG
apps	gth	gitahead github
apps	gtk	gtkhash gtklick gtkorphan gtkpod gtkterm gtkwave io.github.gtkwave.GTKWave multimedia-player org.gtkhash.gtkhash
apps	gtl	gitlab gootool
apps	gtm	gtimelog org.gtimelog.GTimeLog
apps	gtq	appimagekit-gitqlient gitqlient
apps	gtr	appimagekit-guitar geotrans geotranz gitter Gitter goterminal gtranscribe guitar guitarix guitarix2 gx_head im.gitter.Gitter org.gnome.Gtranslator org.guitarix.Guitarix
apps	gts	com.github.linuxhubit.gitscover
apps	gty	com.github.Murmele.Gittyup giteye GitEye gittyup
apps	gu	gear-up lutris_gear-up steam_icon_214420
apps	gv	GPU_Viewer io.github.arunsivaramanneo.GPUViewer
apps	gvc	gta-vice-city lutris_grand-theft-auto-vice-city revc steam_icon_12110
apps	gvm	com.github.muriloventuroso.givemelyrics
apps	gvr	goverlay
apps	gw	google-webdesigner
apps	gwe	com.leinardi.gwe
apps	gwl	gweled
apps	gx	gdm-setup gdm-xnest gdmsetup gnome-window-manager gnome-wm kcmkwm kwin twin
apps	gxl	goxel io.github.guillaumechereau.Goxel
apps	gzd	gzdoom org.zdoom.GZDoom
apps	hb	hubstaff-black
apps	hbs	hubstaff
apps	hbud	io.github.swanux.hbud
apps	hc	hubstaff-color
apps	hck	com.github.mdh34.hackup de.gunibert.Hackgregator hacknet lutris_hacknet steam_icon_365450
apps	hct	horizon-chase-turbo lutris_horizon-chase-turbo steam_icon_389140
apps	hdg	hedgewars org.hedgewars.Hedgewars
apps	hdj	hdajackretask
apps	hdl	headlines io.gitlab.caveman250.headlines
apps	hdm	io.github.jeffshee.Hidamari
apps	hdn	houdini
apps	hds	co.headsetapp.headset hdspconf hdspmixer headset
apps	he	org.horizon_eda.HorizonEDA
apps	helm	helm
apps	hg	hubstaff-gray hubstaff-green
apps	hgc	com.github.ztefn.haguichi haguichi
apps	hgh	org.gnome.World.Highscore
apps	hgn	higan
apps	hiri	hiri
apps	hk	hollow-knight lutris_hollow-knight steam_icon_367520
apps	hkn	hakuneko-desktop io.github.hakuneko.HakuNeko
apps	hl	half-life half-life2 lutris_half-life lutris_half-life-2 steam_icon_220 steam_icon_280 steam_icon_380 steam_icon_420 steam_icon_70
apps	hla	half-life-alyx lutris_half-life-alyx steam_icon_546560
apps	hlb	half-life-blue-shift lutris_half-life-blue-shift steam_icon_130
apps	hld	half-life-deathmatch half-life2-deathmatch lutris_half-life-2-deathmatch lutris_half-life-deathmatch-source steam_icon_320 steam_icon_360 steam_icon_40
apps	hlf	io.github.tfuxu.Halftone
apps	hll	half-life2-lost-coast lutris_half-life-2-lost-coast steam_icon_340
apps	hlm	helium net.imput.helium
apps	hlo	half-life-opposing-force lutris_half-life-opposing-force steam_icon_50
apps	hlt	dev.Cogitri.Health helltaker lutris_helltaker steam_icon_1289310
apps	hlv	org.pipewire.Helvum
apps	hmb	fr.free.Homebank homebank
apps	hms	hamster hamster-applet hamster-indicator hamster-time-tracker org.gnome.Hamster org.gnome.Hamster.GUI
apps	hmt	io.github.cges30901.hmtimer
apps	hn	hidemy.name
apps	ho	hypnospace-outlaw lutris_hypnospace-outlaw steam_icon_844590
apps	hook	hook lutris_hook steam_icon_367580
apps	hp	appimagekit-hw-probe com.endlessm.HatchPreviewer hw-probe org.linux_hardware.hw-probe
apps	hpc	hipchat hipchat4
apps	hpm	harbour-pure-maps io.github.rinigus.PureMaps
apps	hps	hoppscotch
apps	hpt	heaptrack
apps	hr	hubstaff-red
apps	hrd	hardinfo2
apps	hrg	com.github.sgpthomas.hourglass
apps	hrm	harmony
apps	hrp	haroopad
apps	hrs	heroesofnewerth hon honicon_128x128
apps	hrv	com.github.danrabbit.harvey
apps	hrz	horizon-client
apps	hsh	com.github.artemanufrij.hashit hashit
apps	hsk	applications-haskell
apps	htr	hatari hitori httrack org.gnome.Hitori org.tuxfamily.hatari
apps	hts	appimagekit-hotspot hotspot
apps	hub	hub
apps	hulu	hulu
apps	hvl	hivelytracker
apps	hwl	hwloc
apps	hwn	cs-details dialog-information gnome-info gnome-status hwbrowser hwinfo indicator-applet ktip liteinfo mate-indicator-applet stock_view-details xfce-system-info xfce4-indicator-plugin
apps	hxl	hexalate org.gottcode.Hexalate
apps	hyd	h2-icon hydrogen org.gabmus.hydrapaper org.hydrogenmusic.Hydrogen
apps	hyp	appimagekit-hyper com.github.HypatiaProject.hypatia hyper hyperspace hypnotix
apps	i13	ieee1394
apps	i18n	app.drey.Dialect applications-education-language com.github.gi_lom.dialect com.github.rapidfingers.translator config-language crow-translate cs-language cs-region deepin-translator dialect gnome-language-selector gnome-translate io.crow_translate.CrowTranslate klettres language-selector locale lokalize nwg-shell-translate org.kde.klettres org.kde.lokalize preferences-desktop-language preferences-desktop-locale preferences-desktop-locale-symbolic system-config-language translator yast-language
apps	i2pd	i2pd website.i2pd.i2pd
apps	ia	ibus-anthy
apps	ib	ibus-bopomofo iridium-browser
apps	ibn	im.bernard.Nostalgia
apps	ibs	in.bharatkalluri.shortcircuit
apps	ic	application-x-firmware indicator-cpufreq mate-cpu-frequency-applet xfce4-cpufreq-plugin
apps	icd	icedove icedove-uxp
apps	ice	ice
apps	icl	chrome-agedgfbdadefbodjkkkcpihgcmibpcff-Default chrome-ddfcbhajfcbadieedchpomhocpkhgeke-Default icloud
apps	icn	com.github.santileortiz.iconoscope cs-themes gtk3-icon-browser iconoclasts icons iconthemes org.xfce.xfdashboard preferences-desktop-icons steam_icon_393520 xfdashboard
apps	icq	icq icq_protocol licq
apps	icr	icarus
apps	ict	icecat
apps	icw	iceweasel iceweasel-uxp
apps	id	appimagekit-internxt-drive insomnia-designer internxt-drive
apps	idg	com.github.cassidyjames.ideogram
apps	idjc	idjc
apps	idn	org.gnome.gitlab.YaLTeR.Identity
apps	idv	idevice
apps	ie	io.github.ImEditor
apps	iff	fluffychat im.fluffychat.Fluffychat
apps	igdm	igdm
apps	ign	ignuit
apps	iii	ir.imansalmani.IPlan
apps	ij	com.jetbrains.IntelliJ-IDEA-Community com.jetbrains.IntelliJ-IDEA-Ultimate idea idea-community idea-ultimate intellij intellij-idea intellij-idea-ce intellij-idea-community intellij-idea-ue-bundled-jre intellij-idea-ultimate intellij-idea-ultimate-edition intellij_idea
apps	ikn	org.kde.Ikona
apps	ils	avaloniailspy ILSpy
apps	img	AppImageLauncher
apps	imh	imhex net.werwolv.ImHex
apps	imp	Impactor
apps	in	i-nex
apps	inc	incredipede lutris_incredipede steam_icon_230150
apps	ind	indivisible lutris_indivisible steam_icon_421170
apps	inf	infector infinifactory lutris_infinifactory steam_icon_300570 uk.co.mangobrain.Infector
apps	ink	inkscape inkscape-logo org.inkscape.Inkscape
apps	inky	com.inklestudios.Inky inky
apps	ins	brave-akpamiohjfcnimfljfndmaldlcfphjmp-Default chrome-akpamiohjfcnimfljfndmaldlcfphjmp-Default com.github.hezral.inspektor com.github.manexim.insomnia instagram insurgency insync lutris_insurgency msedge-akpamiohjfcnimfljfndmaldlcfphjmp-Default ramme steam_icon_222880
apps	int	applications-interfacedesign gtk3-widget-factory gtk4-widget-factory intel preferences-desktop-theme-applications style xfce-theme-manager
apps	inv	appimagekit-invesalius br.gov.cti.invesalius invesalius
apps	io	com.github.gijsgoudzwaard.image-optimizer iaito-o org.radare.iaito
apps	ip	applications-webapps chinese chrome-cigolahoahpkfmhoomckiodabnlfdhpp-Default cmst connman cs-network dhcpcd gnome-nettool gnome-nettools gnome-network-properties gnome-networktool ibus-pinyin icloud-photos internet-archive kali-nmap kali-p0f kali-web-application-trans kali-wireless-attacks-trans kali-wireshark knemo knetattach knetwalk linssid mate-netspeed-applet mate-network-properties mx-broadcom-manager network-defaultroute network-manager network-workgroup networkmanager nm-applet nm-connection-editor nm-device-wireless nmap nmtui org.kde.knetwalk org.nmap.Zenmap org.wireshark.Wireshark package_network preferences-network preferences-system-network preferences-system-network-proxy proxy q4_findweb q4_netcon repository tdenetworkmanager wicd wicd-gtk wifi-radar wireshark xfce4-netload-plugin yast-device-tree yast-host yast-iscsi-client yast-lan yast-network_services yast-nis yast-ntp-client yast-proxy zenmap
apps	ipl	iron_product_logo
apps	ips	ipscan
apps	ipy	ipython ipython3
apps	ir	com.github.weclaw1.ImageRoll imperator-rome lutris_imperator-rome steam_icon_859580
apps	irc	appimagekit-irccloud-desktop com.irccloud.desktop irccloud irccloud-desktop
apps	ird	com.github.avojak.iridium
apps	irt	com.github.iortcw.iortcw iortcw
apps	is	ice-store inode-symlink preferences-desktop-filetype-association
apps	ish	ibus-setup-hangul ishiiruka
apps	ism	iso-customizer isomaster
apps	iss	im.srain.Srain
apps	it	cs-tablet ib-tws input-tablet preferences-desktop-tablet
apps	itb	ibus-typing-booster
apps	itm	itmages
apps	its	org.gnome.gitlab.cheywood.Iotas org.gnome.World.Iotas
apps	iwg	iwgtk
apps	jadx	com.github.skylot.jadx jadx jadx-gui
apps	jami	jami jami-gnome net.jami.Jami
apps	jasp	jasp org.jaspstats.JASP
apps	java	applications-java java java-1.8.0 java-1.8.0-openjdk java-11-openjdk java-20-openjdk java-21-openjdk java-22-openjdk java-24-openjdk java-25-openjdk java-jdk java-openjdk java11-jdk java11-openjdk java17-openjdk java18-openjdk java19-openjdk java20-openjdk java21-openjdk java24-openjdk java25-openjdk javaws openjdk-11 openjdk-17 openjdk-18 openjdk-19 openjdk-20 openjdk-21 openjdk-22 openjdk-24 openjdk-8 oracle-javaws oracle_java8 sun-java sun-java-jdk8 sun-java-jre8 sun-java32-jdk8 sun-javaws-jdk8 sun-javaws-jre8 sun-javaws32-jdk8 sun-jcontrol-jdk8 sun-jcontrol-jre8 sun-jcontrol32-jdk8
apps	jbl	appimagekit-jubler jblue jubler
apps	jck	cs-cat-hardware cs-drivers ddm deepin-devicemanager deepin-graphics-driver-manager driver-manager glxinfo gnome-device-manager gtk-lshw harddrake hardinfo jackpatch jockey jockey-kde kali-macchanger kcmpci lshw macchanger mintdrivers org.freedesktop.GlxInfo
apps	jcl	cat.xtec.clic.JClic.jclic cat.xtec.clic.JClic.jclicauthor jclic jclicauthor jclicreports
apps	jd	com.jpexs.decompiler.flash ffdec jpexs-decompiler
apps	jdv	jdev_icon jdeveloper
apps	jdw	jdownloader org.jdownloader.JDownloader
apps	jfb	JavaFXSceneBuilder2.0
apps	jfr	JForex
apps	jg	io.github.java_decompiler.jd-gui jd-gui kali-jd-gui
apps	jgr	jgray jgreen
apps	jhn	johnny kali-johnny
apps	ji	appimagekit-junior_install_icon junior_install_icon
apps	jl	julia juliabackend
apps	jly	appimagekit-Jellyamp com.github.iwalton3.jellyfin-media-player com.github.iwalton3.jellyfin-mpv-shim Jellyamp jellyfin jellyfin-desktop org.jellyfin.JellyfinDesktop org.jellyfin.JellyfinServer
apps	jm	com.github.optyfr.JRomManager jack_mixer JRomManager
apps	jml	io.jamulus.Jamulus jamulus
apps	jmn	jamendo jmonkeyengine jmonkeyplatform
apps	jms	jamesdsp me.timschneeberger.jdsp4linux me.timschneeberger.jdsp4linux.pulse
apps	jmv	jamovi org.jamovi.jamovi
apps	jng	jango
apps	joa	journey-of-a-roach lutris_journey-of-a-roach steam_icon_255300
apps	john	com.openwall.John john kali-john
apps	josm	josm org.openstreetmap.josm
apps	jpr	jprofiler
apps	jpy	jupyter jupyterlab-desktop notebook org.jupyter.JupyterLab
apps	jr	JabRef jabref JabRef-bin-icon JabRef-icon org.jabref.jabref
apps	jred	jred
apps	jrn	net.daase.journable
apps	jt	jetbrains-toolbox
apps	jts	appimagekit-jitsi-meet jitsi jitsi-meet jitsi-meet-desktop org.jitsi.jitsi-meet
apps	juci	juci
apps	jvs	javasnoop kali-javasnoop
apps	jyl	jyellow
apps	jzr	jazzradio
apps	kadu	kadu
apps	kaku	appimagekit-kaku kaku
apps	karp	org.kde.karp
apps	kbd	cs-input-method cs-keyboard eu.blumenstingl.martin.keystateplasmoid fcitx fcitx-setting fcitx5 fcitx_ubuntukylin florence gnome-settings-accessibility-keyboard gnome-settings-accessibility-technologies gnome-settings-keybinding gnome-settings-keybindings ibus ibus-engine ibus-keyboard ibus-setup ibus-setup-chewing im-chooser input-keyboard key_bindings keyboard kimtoy ktouch mintlocale-im onboard org.fcitx.Fcitx5 org.kde.ktouch org.xfce.keyboard org.xfce.settings.keyboard preferences-desktop-keyboard preferences-desktop-keyboard-layout preferences-desktop-keyboard-shortcuts system-config-keyboard xfce4-keyboard-settings yast-keyboard
apps	kbl	kblackbox kblocks org.kde.kblackbox org.kde.kblocks
apps	kbn	kbounce org.kde.kbounce
apps	kbp	kubeplayer
apps	kbr	gnubik kbreakout kbruch kubrick lbreakout2 org.kde.kbreakout org.kde.kbruch org.kde.kubrick
apps	kbt	kbibtex org.kde.kbibtex
apps	kc	devede devedeng dvd95 dvd9548 k9-copy k9copy media-optical-copy
apps	kch	kcachegrind org.kde.kcachegrind
apps	kcm	kali-hardware-hacking-trans kcmdevices kcmdf kcmmemory
apps	kd	chromium-bsu kali-dbpwaudit kipi-dngconverter kobo-icon KoboDeluxe kobodeluxe kobodl net.olofson.KoboDeluxe net.sourceforge.chromium-bsu
apps	kdbg	kdbg
apps	kdc	com.github.bajoja.indicator-kdeconnect kdeconnect kdocker keduca org.gnome.Shell.Extensions.GSConnect preferences-kde-connect
apps	kdf	kdiff3
apps	kdl	kodelife
apps	kdm	kdiamond org.kde.kdiamond
apps	kdn	im.kaidan.kaidan kaidan kdenlive org.kde.kdenlive
apps	kdr	addressbook cs-user-accounts kaddressbook office-addressbook
apps	kds	io.github.jonmagon.kdiskmark kdesvn kdiskmark tdesvn
apps	kdt	kdots
apps	ke	kame-editor kipi-expoblending komodo-edit
apps	keep	brave-eilembjdkfgodjkcjnpgpaenohkicgjd-Default chrome-eilembjdkfgodjkcjnpgpaenohkicgjd-Default google-keep keep
apps	kf	com.carpeludum.KegaFusion kega-fusion killing-floor lutris_killing-floor steam_icon_1250
apps	kfl	kfloppy kfoldersync kfouleggs
apps	kfr	kfourinline org.kde.kfourinline
apps	kft	kali-forensics-trans
apps	kg	knights-game steam_icon_476240
apps	kget	kget org.kde.kget
apps	kgh	kghostview
apps	kgl	kgoldrunner org.kde.kgoldrunner
apps	kgr	kgeography kgraphviewer org.kde.kgeography org.kde.kgraphviewer
apps	kh	io.github.seadve.Kooha
apps	khl	appimagekit-kahla kahla
apps	khn	khangman org.kde.khangman
apps	khr	io.github.lainsce.Khronos
apps	kht	khotkeys
apps	kid3	kid3 kid3-qt org.kde.kid3
apps	kig	kig org.kde.kig
apps	kigo	gnome-gnect kigo org.kde.kigo
apps	kile	kile org.kde.kile
apps	kiw	kontact-import-wizard ktnef
apps	kj	jad kali-jad
apps	kjm	gnome-tali kjumpingcube opencubicplayer org.gnome.Tali org.kde.kjumpingcube package_games_board tali
apps	kjn	kajongg
apps	kjt	kjots org.kde.kjots
apps	kl	koala kontena-lens
apps	klb	killbots org.kde.killbots
apps	klc	klickety org.kde.klickety
apps	klg	kalgebra org.kde.kalgebra
apps	kln	gnome-glines klines org.kde.kalendar org.kde.klines
apps	klp	kleopatra org.kde.kleopatra
apps	klr	kolourpaint org.kde.kolourpaint
apps	kls	kollision org.kde.kollision
apps	klt	gnome-klotski klatexformula org.gnome.Klotski
apps	klv	klavaro net.sourceforge.Klavaro
apps	kly	de.klayout.KLayout klayout klystrack
apps	klz	kalzium org.kde.kalzium
apps	km	kali-forums kali-menu kali-tools kali-www system-keyboard-mx
apps	kmd	komodo komodo-ide
apps	kmg	kimagemapeditor org.kde.kimagemapeditor
apps	kmh	kmahjongg org.kde.kmahjongg
apps	kmk	info.febvre.Komikku
apps	kmn	kmines org.kde.kmines
apps	kmp	kmplayer kmplot kompare org.kde.kmplayer org.kde.kmplot org.kde.kompare
apps	kmr	komorebi
apps	kmt	kmouth
apps	kmy	kmymoney org.kde.kmymoney
apps	kn	kakoune
apps	knb	com.github.ryonakano.konbucase kiki-the-nano-bot
apps	knd	kindd
apps	kng	3dchess kanagram knights org.kde.kanagram org.kde.knights
apps	knq	intergalacticfm konquest org.kde.konquest
apps	knt	kanatest kontact org.kde.kontact org.kde.kontrast
apps	knv	knavalbattle org.kde.knavalbattle
apps	knw	appimagekit-knowte knowte
apps	kolf	kolf lutris_golf-with-your-friends org.kde.kolf steam_icon_431240
apps	kp	appimagekit-KittehPlayer hugin kawaii-player king-phisher-icon kipi-panorama KittehPlayer net.sourceforge.Hugin panini Panini ptbatcher
apps	kpc	kpicosim
apps	kph	deepin-camera ephoto gtkam-camera kphotoalbum org.kde.kphotoalbum org.postmarketos.Megapixels showfoto unity-lens-photos
apps	kpm	kapman org.kde.kapman pacman
apps	kps	keepassx keepassx2
apps	kpt	ace gnome-aisleriot gnome-hearts kapptemplate kde-im-log-viewer kopete kopete2 kpat kpatience lutris_kpatience org.gnome.Aisleriot org.kde.kpat package_games_card telepathy-kde yast-messages
apps	kpv	kpovmodeler
apps	kpw	kapow org.gottcode.Kapow
apps	kr	kairo krusader_red krusader_root lutris_kairo steam_icon_233230
apps	krb	calligrakarbon karbon
apps	krc	keurocalc krecipes mate-invest-applet
apps	krg	kregexpeditor
apps	krk	kiriki org.kde.kiriki
apps	krl	gnome-screenruler kruler org.kde.kruler screenruler screenruler-icon screenruler-icon-32x32
apps	krm	com.github.robertsanseries.karim
apps	krn	gnome-pomodoro gprename krename kronometer org.gnome.Sysprof org.kde.krename org.kde.kronometer sysprof sysprof-icon xfce4-stopwatch-plugin xfce4-time-out-plugin
apps	krt	calligrakrita calligrakrita2 krita lutris_krita-gemini org.kde.krita steam_icon_280680
apps	krv	kreversi org.kde.kreversi
apps	ks	com.katawa_shoujo.KatawaShoujo kali-set katawa-shoujo lutris_katawa-shoujo setoolkit
apps	ksd	com.github.parnold-x.sudoku ksudoku org.kde.ksudoku
apps	ksh	kshisen org.kde.kshisen
apps	ksm	ksame
apps	ksn	ksnakeduel org.kde.ksnakeduel
apps	ksp	kerbal-space-program kspaceduel lutris_kerbal-space-program steam_icon_220200
apps	ksq	ksquares org.kde.ksquares
apps	ksr	ksirk org.kde.ksirk
apps	kst	kasteroids kasts kstars maelstrom org.kde.kasts org.kde.kstars org.libsdl.Maelstrom
apps	kt	E51E_KakaoTalk.0 KakaoTalk
apps	ktb	ktuberling org.kde.ktuberling
apps	ktc	ktechlab
apps	ktg	io.github.kotatogram kotatogram
apps	kth	kthememgr
apps	ktk	ktikz
apps	ktm	alarm-timer atomix-icon katomic kitematic kteatime ktimer ktimetracker org.kde.katomic org.kde.kteatime org.kde.ktimetracker xfce4-timer xfce4-timer-plugin
apps	ktn	kiten org.kde.kiten
apps	ktr	drgeo kturtle org.kde.kturtle
apps	ku	io.kopia.KopiaUI kali-sniffing-spoofing-trans kali-undercover kopia-ui krusader_blue krusader_user
apps	kup	kali-unix-privesc-check unix-privesc-check
apps	kuro	appimagekit-kuro kuro
apps	kvn	kvantum
apps	kvr	kvirc net.kvirc.KVIrc
apps	kvw	kuiviewer org.kde.kuiviewer
apps	kwb	keeweb
apps	kwc	komorebi-wallpaper-creator
apps	kwn	appimagekit-kawanime kawanime
apps	kwr	gnome-activity-journal kwordquiz org.kde.kwordquiz
apps	kwt	org.kde.kwatchgnupg
apps	kwv	kwave
apps	kwx	kiwix-desktop org.kiwix.desktop
apps	kxs	kxstitch org.kde.kxstitch
apps	kyb	keybase
apps	kym	key-mon keymon
apps	kys	keysmith org.gnome.Keysign org.kde.keysmith
apps	l4d	l4d steam_icon_500
apps	l4d2	l4d2 lutris_left-4-dead-2 steam_icon_550
apps	lb	luckyBackup
apps	lbp	labplot labplot2 LabPlot2 org.kde.labplot2
apps	lbr	laborejo org.gnome.design.IconLibrary
apps	lbry	io.lbry.lbry-app lbry
apps	lbt	libation
apps	lby	com.github.labyrinth_team.labyrinth labyrinth
apps	lc	libreoffice-chart libreoffice7.3-chart libreoffice7.4-chart libreoffice7.5-chart libreoffice7.6-chart livewallpaper-config net.sapples.LiveCaptions org.libreoffice.LibreOffice.chart
apps	lca	lara-croft-and-the-temple-of-osiris lutris_lara-croft-and-the-temple-of-osiris steam_icon_289690
apps	lcd	appimagekit-leocad leocad lucidchart org.leocad.LeoCAD
apps	lcl	localsend localsend_app org.localsend.localsend_app
apps	ld	latte-dock lutris_the-long-dark steam_icon_305620 the-long-dark
apps	ldt	laditools
apps	ldv	gnome-ldraw io.github.tcobbs.LDView ldview
apps	lf	LyricsFinder
apps	lfg	lifeograph net.sourceforge.Lifeograph
apps	lfr	liferea net.sourceforge.liferea
apps	lftp	lftp lftp-icon
apps	lg	cs-gestures input-touchscreen libinput-gestures preferences-desktop-gestures-touch preferences-desktop-touchscreen
apps	lgh	appimagekit-Lightcord gnome-lightsoff lightcord Lightcord lightsoff lightworks lightzone org.gnome.LightsOff
apps	lgn	cs-startup-programs gmrun launch loginized mate-desktop-item-edit mate-panel-launcher mate-session-properties org.xfce.session preferences-desktop-launch-feedback preferences-system-login preferences-system-session preferences-tweaks-cerbere session-properties xfce4-session yast-bootloader
apps	lgr	fi.skyjake.Lagrange io.gitlab.osslugaru.Lugaru lugaru rabbitvcs rabbitvcs-small
apps	lgs	com.github.reds.LogisimEvolution logisim-icon logisim-icon-128
apps	lgt	appimagekit-laigter io.itch.azagaya.Laigter laigter
apps	lh	luminance-hdr net.sourceforge.qtpfsgui.LuminanceHDR
apps	li	little-inferno lutris_little-inferno steam_icon_221260
apps	lia	lovers-in-a-dangerous-spacetime lutris_lovers-in-a-dangerous-spacetime steam_icon_252110
apps	liri	io.liri.BaseApp liri
apps	lis	life-is-strange lutris_life-is-strange steam_icon_319630
apps	lite	lite
apps	lkb	com.github.danrabbit.lookbook
apps	lkt	lookit luakit
apps	ll	appimagekit-ledger-live-desktop ledger-live-desktop
apps	lm	appimagekit-listen.moe-desktop-app listen-moe-desktop listen.moe-desktop-app
apps	lmb	limbo lutris_limbo steam_icon_48000
apps	lmms	io.lmms.LMMS lmms
apps	lmp	lampa
apps	lnc	com.icons8.Lunacy linconnect linconnect-server lunacy
apps	lnd	uk.me.doof.Lander
apps	lnf	appimagekit-leonflix leonflix
apps	lng	org.nongnu.lingot
apps	lnp	linphone
apps	lnr	appimagekit-lunarclient com.lunarclient.LunarClient lunar-client lunarclient
apps	lnx	com.pypyrev.linuxdcpp linuxdcpp
apps	lo	libreoffice libreoffice-main libreoffice-startcenter libreoffice7.3-main libreoffice7.3-startcenter libreoffice7.4-main libreoffice7.4-startcenter libreoffice7.5-main libreoffice7.5-startcenter libreoffice7.6-main libreoffice7.6-startcenter org.libreoffice.LibreOffice.startcenter
apps	log	activity-log-manager deepin-log-viewer gnome-logs gnome-system-log journal-viewer korg-journal ksystemlog litesystemreport logview logviewer mate-system-log org.gnome.Logs org.kde.ksystemlog plv qjournalctl utilities-log-viewer yast-journal
apps	lol	com.leagueoflegends.Client league-of-legends
apps	loop	net.danigm.loop
apps	love	appimagekit-love love
apps	lp	com.hamrick.VueScan cs-printer cups dde-printer deepin-scanner gnome-printers-panel gscan2pdf hp-logo hp-toolbox hp_logo hplip hplj1020_icon kjobviewer ladi-player lovely-planet lsp-plugins lutris_lovely-planet openoffice4-printeradmin org.gnome.SimpleScan org.kde.skanlite org.kde.skanpage org.librepcb.LibrePCB preferences-desktop-printer preferences-devices-printer print-manager printer printer1 printers printersandfax_q4os_startmenu printmgr scanner simple-scan skanlite skanpage steam_icon_298600 system-config-printer vuescan xsane yast-printer yast-scanner
apps	lp2	lovely-planet-2 steam_icon_1019590
apps	lpa	lovely-planet-arcade steam_icon_436000
apps	lpl	lplayer
apps	lpr	com.github.ryonakano.louper
apps	lqd	liquidwar liquidwar6
apps	lrm	org.gnome.design.Lorem
apps	ls	com.github.libresprite.LibreSprite gnome-layout-switcher libresprite
apps	lsk	gnome-freecell lskat org.kde.lskat
apps	lsl	ladi-system-log losslesscut no.mifi.losslesscut
apps	lst	goa-account-lastfm last-fm lastfm lastfm-audioscrobbler lastfm-valut lastfm-www.last.fm
apps	lt	labwc_tweaks LanguageTool
apps	ltc	litecoin-qt
apps	ltd	liteide
apps	ltl	appimagekit-littleweeb littleweeb
apps	ltp	liteupgrade
apps	ltr	com.github.bartzaalberg.lottery ltris net.sourceforge.lgames.LTris
apps	lts	litesoundsloc
apps	ltw	litetweaks
apps	ltx	gnome-latex latexila org.gnome.gnome-latex
apps	luk	live-usb-kernel-updater
apps	lvim	lvim
apps	lvp	livepatch
apps	lvr	laverna
apps	lvs	lives
apps	lvw	livewallpaper
apps	lyne	lutris_lyne lyne steam_icon_266010
apps	lynx	links links_32x32.xpm lynx
apps	lyr	com.github.naaando.lyrics lyrebird lyricfier
apps	lyx	lyx
apps	lzd	lzdoom
apps	lzp	lazpaint
apps	lzr	lazarus
apps	m2	lutris_magicka-2 magicka-2 steam_icon_238370
apps	m2r	lutris_metro-2033-redux metro-2033-redux steam_icon_286690
apps	m3	brave-ocdlmjhbenodhlknglojajgokahchlkk-Default brave-onhfoihkhodaeblmangmjjgfpfehnlkm-Default chrome-ocdlmjhbenodhlknglojajgokahchlkk-Default chrome-onhfoihkhodaeblmangmjjgfpfehnlkm-Default microsoft-365 msedge-ocdlmjhbenodhlknglojajgokahchlkk-Default msedge-onhfoihkhodaeblmangmjjgfpfehnlkm-Default
apps	ma	deepin-download downloader manjaro-architect maps-alt mintsources-additional mouse-actions mouse-actions-gui mx-alerts
apps	mail	org.kde.merkuro.mail
apps	mame	gmameui mame org.mamedev.MAME
apps	man	4137_winhlp32.0 A35F_hh.0 chmsee-icon debian-reference gnochm gnome-help gtk-help help help-about help-browser help-contents help_index kchmviewer khelpcenter litemanual manpages mate-help org.gnome.Yelp org.kde.khelpcenter stock_help stock_help-agent susehelpcenter system-help uos-service-support xchm-48 xfce-man xfce-unknown xfce_unknown yast-support yelp
apps	maps	gnome-maps gpxsee maps org.gnome.Maps qlandkartegt qmapshack QMapShack
apps	mat	mat
apps	mate	mate mate-desktop mate-logo
apps	max	MAX
apps	maya	maya
apps	mb	maxthon-browser MotionBox mx-boot-repair mx-bootrepair
apps	mbl	info.mumble.Mumble mumble
apps	mbo	mx-boot-options
apps	mc	com.mongodb.Compass fr.romainvigier.MetadataCleaner mc MidnightCommander miktex-console mongodb-compass mongodb-compass-community mx-cleanup mx-codecs mx-conky
apps	mce	mu-editor mu.codewith.editor
apps	mch	lutris_machinarium machinarium steam_icon_40700 steam_icon_40710
apps	mcm	mcomix mcomix3 net.sourceforge.mcomix
apps	mcr	goa-account-microsoft goa-account-msn imagej1 io.github.zyedidia.micro micro microscope microsoft
apps	md	lutris_muse-dash media-downloader muse-dash mx-datetime net.kuribo64.melonDS steam_icon_774171
apps	mdc	appimagekit-mediaconch mediaconch net.mediaarea.MediaConch
apps	mdg	mediaget
apps	mdl	modelio modelsim
apps	mdn	com.github.AmatCoder.mednaffe mednafen mednaffe
apps	mdr	appimagekit-moderndeck moderndeck
apps	mds	mint-dev-settings
apps	mdt	app.midterm.MidtermDesktop appimagekit-midterm midterm
apps	mdw	mediawriter org.fedoraproject.MediaWriter org.gabmus.mdwriter
apps	me	appimagekit-MediaElch MediaElch microsoft-edge-beta moe-era steam_icon_1159660
apps	med	microsoft-edge-dev
apps	mega	mega nz.mega.MEGAsync
apps	meld	meld org.gnome.meld org.gnome.Meld
apps	meow	meow
apps	mess	mess
apps	mf	mintsources-foreign
apps	mg	masterpassword-gui mkv-gui mkvmerge mkvmergeGUI mkvtoolnix-gui org.bunkus.mkvtoolnix-gui
apps	mgb	com.tonikelope.MegaBasterd megabasterd
apps	mgba	io.mgba.mGBA mgba
apps	mgc	kali-magictree magictree
apps	mgl	megaglest org.megaglest.MegaGlest
apps	mgn	magnatune
apps	mgz	megazeux
apps	mh	MediaHuman
apps	mhj	gnome-mahjongg org.gnome.Mahjongg
apps	mhw	mhwaveedit
apps	mi	lutris_melvor-idle melvor-idle steam_icon_1267910
apps	mia	mate-inhibit-applet
apps	miro	miro miro-guide-source
apps	mist	mist
apps	mk3	io.github.mki1967.mki3dgame
apps	mkg	appimagekit-makagiga makagiga
apps	mkh	makehuman makehuman_bg
apps	mkm	com.makemkv.MakeMKV makemkv
apps	mks	mkusb
apps	mkt	appimagekit-mikutter mikutter
apps	mkv	mediainfo mkvinfo net.mediaarea.MediaInfo
apps	mlg	mlgui
apps	mlk	milkytracker org.milkytracker.MilkyTracker
apps	mll	lutris_metro-last-light-redux metro-last-light-redux steam_icon_287390
apps	mlt	kali-maltego lutris_multiwinia maltego mlterm mlterm-icon-24colors-1 molotov multimc multiwinia steam_icon_1530
apps	mlu	mx-live-usb-maker
apps	mlw	appimagekit-mellowplayer com.gitlab.ColinDuquesnoy.MellowPlayer mellowplayer
apps	mm	com.lettier.movie-monad io.github.RodZill4.Material-Maker material-maker mintsources-maintenance
apps	mme	com.github.brandonlujan.exchange mmex money-manager-ex org.moneymanagerex.MMEX
apps	mmg	modem-manager-gui
apps	mna	mx-network-assistant
apps	mnc	lutris_monochroma minicraft+ monochroma steam_icon_265830
apps	mnd	appimagekit-mandelbulber2 com.elsevier.MendeleyDesktop com.github.Anuken.Mindustry com.github.buddhi1980.mandelbulber2 com.github.phase1geo.minder com.github.torikulhabib.mindi lutris_mindustry mandelbulber2 mendeley-desktop mendeleydesktop mindustry Mindustry monodevelop steam_icon_1127400
apps	mng	com.georgefb.mangareader mangareader
apps	mnl	app.devsuite.Manuals beryl-settings com.github.kmal-kenneth.monilet cs-windows gnome-windows lutris_moonlighter mate-panel-window-list menulibre metacity moonlighter Moonlighter obconf org.bluesabre.MenuLibre org.xfce.panel.tasklist org.xfce.panel.windowmenu org.xfce.xfwm4 preferences-desktop-plasma-theme preferences-system-windows preferences-system-windows-actions preferences-tweaks-shadows steam_icon_606150 window-duplicate window_list wmtweaks xfce4-taskbar xfwm4
apps	mnm	mnemosyne
apps	mnp	manaplus org.manaplus.ManaPlus
apps	mnr	monero monero-gui org.getmonero.Monero
apps	mns	ch.theologeek.Manuskript gnome-mines manuskript org.gnome.Mines
apps	mnt	appimagekit-memento appimagekit-minetime com.github.matfantinel.moneta io.github.nokse22.minitext io.github.ripose_jp.Memento lutris_minetest memento minetest minetest-icon minetime minitube mintnanny mintupload minuet mntray net.minetest.Minetest org.kde.minuet org.tordini.flavio.Minitube
apps	mny	manyverse moneydance se.manyver.Manyverse
apps	mo	brave-abnfpfhjmipcnaibcolbacfhgfcmjjbn-Default brave-eigpmdhekjlgjgcppnanaanbdmnlnagl-Default brave-faolnafnngnfdaknnbpnkhgohbobgegn-Default chrome-abnfpfhjmipcnaibcolbacfhgfcmjjbn-Default chrome-eigpmdhekjlgjgcppnanaanbdmnlnagl-Default chrome-faolnafnngnfdaknnbpnkhgohbobgegn-Default io.github.mahmoudbahaa.outlook_for_linux io.gitlab.o20.onenote microsoft-office-online ms-office ms-onedrive ms-onenote ms-outlook outlook-for-linux p3x-onenote solstice-microsoft-365 solstice-microsoft-365-onenote solstice-microsoft-outlook
apps	mog	mog
apps	mon	com.github.stsdc.monitor io.elementary.monitor
apps	mono	mono mono-runtime mono-runtime-common monodoc
apps	mozc	mozc mozc-setup
apps	mp	appimagekit-com.github.coslyk.MoonPlayer com.github.coslyk.MoonPlayer mihomo-party mintsources-ppa mx-packageinstaller
apps	mp3	mp3splt-gtk
apps	mpd	kdisknav kfm mate-panel-drawer ml.prevete.Daty mpd mpdevil org.mpdevil.mpdevil org.xfce.xfmp
apps	mpl	maple
apps	mpn	com.github.efdos.mupengui m64py mupen64plus mupen64plus-qt
apps	mps	mate-panel-separator mps org.xfce.panel.separator
apps	mpvz	mpvz
apps	mpz	mpz
apps	mq	mx-qsi
apps	mrb	marble mrboom org.kde.marble
apps	mrc	mail.ru-cloud
apps	mrd	io.github.purplehorrorrus.Meridius
apps	mrg	morgen
apps	mrk	com.bitstower.Markets com.github.fabiocolacio.marker marknoto markpado org.kde.marknote
apps	mrm	mx-repo-manager
apps	mrp	morpheus
apps	mrs	marsshooter net.sourceforge.mars-game
apps	ms	appimagekit-teams-for-linux com.github.IsmaelMartinez.teams_for_linux io.github.seadve.Mousai Mesen-S MesenSIcon mx-snapshot preferences-management-service solstice-microsoft-365-teams teams teams-for-linux
apps	msc	appimagekit-mosaic appimagekit-mscore-portable com.github.bcedu.museic com.github.fries1234.ncsa-mosaic mosaic mscore mscore-portable musescore Musescore musicbrainz org.musescore.MuseScore
apps	msf	kali-msfpc msfpc
apps	msh	appimagekit-meshlab meshlab net.meshlab.MeshLab
apps	msk	appimagekit-museeks museeks musikcube
apps	msm	manjaro-settings-manager
apps	msn	mesen MesenIcon org.gnunet.Messenger
apps	msq	museeq
apps	msr	moserial org.gnome.moserial
apps	mss	alsa-tools mx-select-sound
apps	mst	gnome-mastermind mstdn
apps	msx	com.musixmatch.Musixmatch musixmatch
apps	mt	com.gitlab.bitseater.meteo com.gitlab.miridyan.Mt io.elementary.meteo mx-tools mx-tweak
apps	mth	mathematica methane wolfram-mathematica
apps	mtl	matlab matlab-desktop
apps	mtp	mtpaint
apps	mtr	appimagekit-motrix com.adrienplazas.Metronome com.github.artemanufrij.metronome com.mattermost.Desktop gtick mattermost mattermost-desktop mattermost-desktop-bin meterbridge meterbridge32x32 metronome motrix net.agalwood.Motrix
apps	mts	kali-metasploit-framework metasploit metasploit-framework
apps	mtv	mtvmusic
apps	mu	io.mrarm.mcpelauncher mcpelauncher-ui-qt mx-updater mx-user
apps	muck	muck steam_icon_1625450
apps	mv	massif-visualizer mullvad-vpn org.kde.massif-visualizer
apps	mvm	movmetaedit net.mediaarea.MOVMetaEdit
apps	mw	mx-welcome
apps	mx	element Element element-desktop element-desktop-bin fractal im.riot.Riot io.element.Element mixxx mixxx-icon mixxx_icon org.mixxx.Mixxx
apps	mxc	mixcloud org.tabos.maxcontrol
apps	mxm	io.github.wxmaxima_developers.wxMaxima maxima maxima-icon maxima-new net.sourceforge.maxima wxmaxima
apps	mxr	com.github.childishgiant.mixer
apps	myr	myrulib
apps	mys	appimagekit-mystiq myspace mystiq
apps	myt	mytourbook
apps	n12	lutris_narcissu-1st-2nd narcissu-1st-2nd steam_icon_264380
apps	na	nautilus-alt
apps	naev	lutris_naev naev org.naev.Naev steam_icon_598530
apps	nasc	com.github.parnold-x.nasc com.github.parnold_x.nasc nasc
apps	nb	bell liteupdatesnotify mate-panel-notification-area preferences-desktop-notification-bell
apps	nbl	gnibbles gnome-gnibbles gnome-nibbles org.gnome.Nibbles
apps	nbt	com.jaquadro.NBTExplorer nbteditor nbtexplorer
apps	nc	nwg-clipman preferences-system-network-connection
apps	nce	dev.vlinkz.NixosConfEditor
apps	nch	org.kde.neochat
apps	ncl	appimagekit-nuclear nuclear org.js.nuclear.Nuclear
apps	ncm	com.github.gmg137.netease-cloud-music-gtk com.netease.CloudMusic netease-cloud-music netease-cloud-music-gtk
apps	ncr	kali-ncrack ncrack
apps	nd	org.gnome.NetworkDisplays
apps	ndm	ndm
apps	nds	ndisgtk
apps	news	com.github.allen-b1.news
apps	nfv	io.otsaloma.nfoview nfoview
apps	ngb	appimagekit-negibox negibox
apps	ngh	appimagekit-nighthawk lutris_nightsky nighthawk nightsky steam_icon_99700
apps	nhk	im.nheko.Nheko io.github.NhekoReborn.Nheko nheko
apps	nhl	lutris_nihilumbra nihilumbra steam_icon_252670
apps	nim	Nim
apps	nino	com.github.torikulhabib.nino
apps	nip2	nip2
apps	niw	lutris_night-in-the-woods night-in-the-woods steam_icon_481510
apps	nkp	lutris_nekopara-vol-0 lutris_nekopara-vol-1 lutris_nekopara-vol-2 lutris_nekopara-vol-3 lutris_nekopara-vol-4 nekopara steam_icon_1406990 steam_icon_333600 steam_icon_385800 steam_icon_420110 steam_icon_602520 steam_icon_899970
apps	nkt	kali-nikto nikto
apps	nl	network_local
apps	nlg	nsm-legacy-gui
apps	nly	nulloy
apps	nm	NoMachine-icon
apps	nmb	com.github.danrabbit.nimbus
apps	nmp	io.thp.numptyphysics numptyphysics
apps	nmr	lutris_no-more-room-in-hell no-more-room-in-hell steam_icon_224260
apps	nms	lutris_no-mans-sky no-mans-sky steam_icon_275850
apps	nmv	nemiver
apps	nn	com.github.dail8859.NotepadNext kali-netsniff-ng netsniff-ng NotepadNext
apps	np	navicat-postgresql nicotine-plus nsm-proxy nwg-icon-picker nwg-panel org.nicotine_plus.Nicotine
apps	np2	np2
apps	nps	com.naps2.Naps2
apps	nr	node-red-icon preferences-system-notifications-rtl
apps	nrb	nwg-readme-browser
apps	nrl	nerolinux nerolinuxexpress
apps	nrm	com.github.dynobo.normcap normcap
apps	nrt	northgard steam_icon_466560
apps	ns	nwg-shell
apps	nsc	dev.vlinkz.NixSoftwareCenter nwg-shell-config
apps	nsg	nsight
apps	nsh	kali-nishang nishang
apps	nsn	io.github.janbar.noson noson
apps	nsp	nz.scuttlebutt.Patchwork
apps	nst	appimagekit-nostlan noisetorch nostlan
apps	nsw	preferences-system-network-share-windows
apps	nt	brave-pnghkaloolpocgfpndmjfbhpjffdmdii-Default chrome-pnghkaloolpocgfpndmjfbhpjffdmdii-Default nos-tv
apps	nt4	null_team-48
apps	ntb	appimagekit-notable netbeans netbeans-beta notable org.apache.netbeans
apps	ntf	netflix netflix-desktop solstice-netflix-netflix
apps	nth	nethack
apps	ntj	io.github.lainsce.Notejot
apps	ntk	net.sf.nootka nootka
apps	ntr	fr.natron.Natron natron netradiant nitroshare org.gabmus.notorious
apps	nts	appimagekit-notesnook com.jianguoyun.Nutstore com.notesnook.Notesnook netsurf Notesnook nutstore org.gnome.Notes org.netsurf_browser.NetSurf
apps	nty	com.github.babluboy.nutty nutty
apps	nu	com.github.philip-scott.notes-up com.github.philip_scott.notes-up
apps	nv	net.nymtech.NymVPN nym-vpn-app org.gnode.NixView
apps	nvc	navicat
apps	nvd	bumblebee com.bxabi.bumblebee-indicator nvidia nvidia-310-settings nvidia-current-settings nvidia-current-updates-settings nvidia-ddm-mx nvidia-drivers-settings nvidia-settings nvidia-x-server-setting nvidia-x-server-settings Nvidiux
apps	nvg	preferences-desktop-navigation
apps	nvl	navalbattle
apps	nvp	novprog org.gottcode.NovProg
apps	nvr	neverball neverputt org.neverball.Neverball
apps	nvt	navit
apps	nvvp	nvvp
apps	nw	naver-whale
apps	nwb	newbreeze
apps	nws	com.gitlab.newsflash
apps	nxn	nixnote2
apps	nxt	com.nextcloud.desktopclient.nextcloud goa-account-owncloud nextcloud Nextcloud
apps	nxz	com.alientrap.nexuiz-classic nexuiz
apps	nz2	com.abagames.noiz2sa noiz2sa
apps	nzb	nozbe Nozbe
apps	oa	cs-online-accounts gnome-online-accounts-gtk OpenAudible preferences-desktop-online-accounts preferences-mail-accounts preferences-online-accounts unity-online-accounts
apps	oab	office-address-book x-office-address-book
apps	ob	otter-browser
apps	obc	obconf-qt
apps	obd	obdautodoctor
apps	obe	opl3_bank_editor opn2_bank_editor
apps	obf	com.belmoussaoui.Obfuscate
apps	obl	com.github.elfenware.obliviate
apps	obs	com.obsproject.Studio obs
apps	oc	net.openra.OpenRA-cnc openmw-cs openra-cnc org.openmw.OpenMW.OpenCS
apps	ocm	ocaml
apps	ocn	ocenaudio
apps	ocr	gimagereader io.github.manisandro.gImageReader ocrfeeder org.gnome.OCRFeeder
apps	ocs	ocsstore
apps	oct	octave org.octave.Octave qtoctave
apps	od	net.openra.OpenRA-d2k openoffice4-draw openra-d2k opera-developer
apps	odc	lutris_octodad-dadliest-catch octodad-dadliest-catch steam_icon_224480
apps	odio	appimagekit-odio odio
apps	ody	com.github.alcinnz.odysseus
apps	ofc	applications-office
apps	oi	openoffice4-impress
apps	ok	org.openkj.OpenKJ
apps	okt	jeex okteta org.kde.okteta org.wxhexeditor.wxHexEditor wxHexEditor
apps	olt	oolite
apps	olv	appimagekit-org.olivevideoeditor.Olive olivia org.olivevideoeditor.Olive
apps	olx	net.sourceforge.OpenLieroX OpenLieroX
apps	oly	kali-ollydbg ollydbg olympus
apps	om	openoffice4-main openoffice4-math openoffice4-startcenter
apps	omn	omnetpp omnishell
apps	omx	com.github.themix_project.Oomox
apps	oni	lutris_oxygen-not-included oxygen-not-included steam_icon_457140
apps	ons	onionshare80 org.onionshare.OnionShare
apps	onv	net.meijn.onvifviewer Onivim2
apps	oo	asc-de onlyoffice-desktopeditors org.onlyoffice.desktopeditors
apps	oph	kali-ophcrack ophcrack
apps	opn	appimagekit-OpenRGB appimagekit-openxcom ch.openboard.OpenBoard com.github.opentyrian.OpenTyrian io.github.ec_.Quake3e.OpenArena io.openrct2.OpenRCT2 jp.yvt.OpenSpades kcmopengl openage openarena openarena128 openbazaar2 openbazaar2client openblok openboard OpenBoard openboardview openbox openbve openclonk opencomic opengl openhardwaremonitor openlp openmw openrct2 openrgb OpenRGB openshot openshot-qt openspades openttd openttd-jgrpp opentyrian openvpn openxcom OPNplug org.openclonk.OpenClonk org.openmw.OpenMW org.openrgb.OpenRGB org.openshot.OpenShot org.openttd.OpenTTD qopenvpn steam_icon_1536610 ws.openarena.OpenArena
apps	opr	opera-beta
apps	opt	com.github.hannesschulze.optimizer
apps	or	kali-maintaining-access-trans net.openra.OpenRA openra-ra org.gnome.OfficeRunner
apps	ord	com.github.candiedoperation.ordne
apps	os	io.github.rinigus.OSMScoutServer offensive-security osmscout-server package_games_strategy
apps	ost	ostinato
apps	osu	osu osu-lazer sh.ppy.osu
apps	ot	io.github.OpenToonz
apps	oth	com.github.ojubaorg.Othman Othman
apps	otl	app-outlet appimagekit-app-outlet com.github.phase1geo.outliner lutris_outlast outlast steam_icon_238320
apps	otp	com.github.paolostivanin.OTPClient
apps	otw	net.jenyay.Outwiker outwiker
apps	ou	opensnitch-ui
apps	ovr	lutris_overcooked lutris_overcooked-2 lutris_overwatch overcooked overcooked2 overwatch steam_icon_2357570 steam_icon_448510 steam_icon_728880
apps	ow	org.opensuse.opensuse_welcome
apps	own	owncloud
apps	p2	lutris_postal-2 postal-2 steam_icon_223470
apps	p2p	biglybt com.biglybt.BiglyBT com.transmissionbt.Transmission de.haeckerfelix.Fragments deluge fragments frostwire ktorrent org.deluge_torrent.deluge org.kde.ktorrent org.qbittorrent.qBittorrent qbittorrent qbittorrent-nox tixati transmission transmission-gtk transmission-qt vuze
apps	p4g	lutris_persona-4-golden persona-4-golden steam_icon_1113000
apps	p8	pico-8
apps	pa	lutris_prison-architect prison-architect steam_icon_233450
apps	pac	pac
apps	pat	lutris_planetary-annihilation-titans planetary-annihilation-titans steam_icon_386070
apps	pbl	com.github.subhadeepjasu.pebbles
apps	pbp	lutris_penumbra-black-plague penumbra-black-plague steam_icon_22120
apps	pc	com.bixense.PasswordCalculator com.github.plugarut.pwned-checker com.jetbrains.PyCharm-Community com.jetbrains.PyCharm-Professional licensequick org.freedesktop.MalcontentControl polychromatic-controller pop-cosmic-launcher preferences-system-parental-controls pycharm pycharm-community pycharm-education pycharm-professional pycharmedu PyCrust
apps	pc8	lexaloffle-pico8 pico8
apps	pca	pop-cosmic-applications
apps	pcb	gnome-genius kicad org.gnome.Genius org.kicad.KiCad org.kicad.KiCad.pcbcalculator org.kicad.KiCad.pcbnew pcbcalculator pcbnew
apps	pck	appimagekit-pocket-casts-linux goa-account-pocket pocket pocket-casts pocket-casts-linux pocketcasts tech.feliciano.pocket-casts
apps	pcl	appimagekit-pcloud pcloud
apps	pcm	picom
apps	pcn	pppoeconf
apps	pcr	org.musicbrainz.Picard picard
apps	pcs	appimagekit-PCSX2 net.pcsx2.PCSX2 pacseek PCSX2 pcsx2
apps	pct	appimagekit-picturama picturama
apps	pcw	pop-cosmic-workspaces
apps	pd	info.puredata.Pd-extended pd pd-extended
apps	pdc	library-podcast org.gnome.Podcasts podcast
apps	pdf	com.github.junrrein.PDFSlicer net.sourceforge.pdfchain pdfchain pdfeditor pdfmod pdfsam pdfstudio pdfstudio18 pdfstudio2019 pdfstudio8
apps	pdl	net.puddletag.puddletag puddletag
apps	pdm	io.podman_desktop.PodmanDesktop podman-desktop
apps	pdr	appimagekit-poddr poddr
apps	pdt	net.poedit.Poedit poedit
apps	pe	org.gottcode.Peg-E peg-e pritunl_client_electron
apps	peek	com.uploadedlobster.peek peek
apps	peeq	com.github.dbhowell.peeq
apps	pep	phoenix-emu-project-logo
apps	pf	kali-python-faraday org.pegasus_frontend.Pegasus pegasus-fe python-faraday
apps	pfg	papirus-folders-gui
apps	pg	com.poweriso.PowerISO poweriso-gui
apps	pg2	net.davidotek.pupgui2 protonup-qt
apps	pga	package_games_arcade
apps	pgm	pgmodeler
apps	pgy	appimagekit-papagayong papagayong
apps	ph	plex-htpc tv.plex.PlexHTPC
apps	phd2	phd2
apps	phn	phantompeer
apps	php	com.jetbrains.PhpStorm phpmyadmin phpstorm
apps	phs	phasmophobia steam_icon_739630
apps	pht	com.endlessm.photos io.github.adrienverge.PhotoCollage io.photoflare.photoflare org.gnome.Photos phatch photocollage photofilmstrip photoflare photogimp photolayoutseditor photopea phototonic xfi
apps	pi	appimagekit-pioneer_install_icon pb-for-desktop phatch-inspector pioneer_install_icon pushbullet-indicator yadpush
apps	pie	ch.protonmail.protonmail-import-export-app gnome-pie lutris_plague-inc-evolved plague-inc-evolved protonmail-import-export-app steam_icon_246620
apps	pk2	net.pistegamez.PekkaKana2 pekka-kana-2
apps	pkg	anaconda appcenter apper appgrid aptdaemon-download aptdaemon-update-cache aptdaemon-upgrade aptdaemon-working bauh calamares cosmic-store cs-software-properties cs-sources debian-installer-launcher deepin-app-store deepin-appstore deepin-installer deepin-installer-oem deepin-software-center dk.yumex.Yumex dnfdragora drakstats edit-urpm-sources flathub gnome-app-install gnome-apt gnome-packagekit gnome-software io.elementary.appcenter io.github.flattool.Warehouse kentoo litesoftware litesources liteupdates lubuntu-software-center mandrivaupdate mintinstall mintsources mintupdate mintupdate-release-upgrade muon muondiscover nwg-shell-update octopi org.gnome.Software org.kde.discover package-manager-icon pamac pamac-manager pamac-updater pirut pk-package-sources pkgbrowser plasmadiscover porthole pup q4os-updatemgr rpmdrake software software-center software-manager software-properties software-properties-mint software-sources software-store softwarecenter softwarecenter-debian softwarecenter-ubuntu storeup swcentre synaptic system-installer system-os-installer system-software-install system-software-installer system-software-update ubiquity ubiquity-kde ubuntu-kylin-software-center ubuntusoftware uos-installtool update-manager update-notifier warehouse x-system-software-sources yast-live-install yast-software yast-sw_single yast-sw_source yast-update-online yast-upgrade yumex yumex-dnf zen-icon zeroinstall
apps	pkr	pokerth
apps	pkt	com.github.lxgr_linux.pokete pokete
apps	pl	kali-pipal pipal
apps	plan	com.krillbite.ThePlan lutris_the-plan steam_icon_250600
apps	play	appimagekit-Play org.purei.Play Play play
apps	plg	com.mattjakeman.ExtensionManager cs-extensions gnome-shell-extension-prefs preferences-plugin yast-addon
apps	pln	com.github.alainm23.planner com.github.diegoivanme.plano plank
apps	plp	org.kde.palapeli palapeli
apps	pls	applications-featured com.github.wwmm.easyeffects com.github.wwmm.pulseeffects cs-desktop-effects desktop-effects dev.pulsar_edit.Pulsar easyeffects gnome-settings-default-applications keditbookmarks package_favorite package_favourite plasmafox plasmagik plasmavault preferences-desktop-effects preferences-tweaks-anim pulsar pulseeffects pulseview yast-high_availability
apps	plt	com.github.alexhuntley.Plots com.github.cassidyjames.palette org.gnome.design.Palette plots
apps	plx	appimagekit-plexamp com.plexamp.Plexamp plexamp
apps	ply	ch.x29a.playitslowly com.github.artemanufrij.playmymusic com.github.artemanufrij.playmyvideos com.polyphone_soundfonts.polyphone org.vinegarhq.Vinegar.player playitslowly polychromatic polyphone
apps	pm	badge-small gnome-encfs-manager info.olasagasti.revelation kali-password-attacks-trans keyring-manager mintsources-keys org.altlinux.userpasswd org.fn2006.PollyMC org.polymc.PolyMC password password-manager passwordmanager passwords pia pia-manager projectM proton-mail revelation stock_keyring
apps	pmc	plasma-media-center
apps	pmd	io.gitlab.idevecore.Pomodoro pomodoneapp
apps	pmp	pumpa
apps	pn	lutris_penumbra-necrologue penumbra-necrologue steam_icon_346290
apps	pnb	pinball
apps	pnc	org.pencil2d.Pencil2D pencil pencil2d pince PINCE
apps	png	pingus pingus-icon
apps	pnp	org.gnome.Pinpoint
apps	pnr	net.pioneerspacesim.Pioneer
apps	pns	io.github.punesemu.puNES punes
apps	pnt	com.github.PintaProject.Pinta pinta
apps	po	lutris_penumbra-overture penumbra-overture penumbra-overture-hib steam_icon_22180
apps	poe	lutris_pillars-of-eternity pillars-of-eternity steam_icon_291650 steam_icon_344550 steam_icon_373340 steam_icon_373740
apps	polo	polo
apps	pp	app.drey.PaperPlane pixel-piracy portal-prelude powder-player prboom-plus psi-plus ru.linux_gaming.PortProtonQt steam_icon_2410180 steam_icon_264140
apps	ppp	gnome-ppp
apps	pr	io.posidon.Paper lutris_penumbra-requiem lutris_postal-redux org.freedesktop.Piper penumbra-requiem portal-reloaded portal-revolution postal-redux PosteRazor posterazor steam_icon_1255980 steam_icon_22140 steam_icon_401680 steam_icon_601360
apps	prc	computer-runprocesscatcher org.processing.processingide
apps	prey	prey
apps	prf	desktop-profiler org.xfce.PanelProfiles performous preferences pureref q4os-swprofiler
apps	prg	io.github.pragha_music_player.pragha pragha
apps	prj	projecteur
apps	prl	org.kde.parley org.parlatype.Parlatype parlatype parley
apps	prm	appimagekit-premid premid
apps	prn	com.github.cassidyjames.principles peerunity pronterface
apps	prp	com.github.aharotias2.parapara prepros
apps	prs	avatar-default com.github.persepolisdm.persepolis mugshot pairs persepolis peruse preferences-desktop-personal
apps	prt	appimagekit-protonmail-desktop-unofficial com.vysp3r.ProtonPlus dev.tchx84.Portfolio edu.stanford.protege info.portfolio_performance.PortfolioPerformance lutris_portal lutris_portal-2 portal portal2 portfolio portfolio-performance-bin portmaster portproton praat protege protonmail-desktop protonmail-desktop-unofficial protonplus ru.linux_gaming.PortProton steam_icon_2012840 steam_icon_400 steam_icon_620
apps	prv	cs-privacy org.paraview.ParaView paraview preferences-system-privacy ssh-askpass-gnome yast-security
apps	prw	paperwork work.openpaper.Paperwork
apps	ps	appimagekit-pling-store appimagekit-pulse-sms com.prusa3d.PrusaSlicer pling-store pop-shop prusa-slicer PrusaSlicer pulse-sms
apps	psb	org.gnome.Passbook
apps	psc	com.system76.Popsicle
apps	psh	com.github.harisvsulaiman.pushy
apps	psi	psi
apps	psm	lutris_portal-stories-mel portal-stories-mel steam_icon_317400
apps	psn	com.github.thejambi.psnotes
apps	psp	org.ppsspp.PPSSPP ppsspp
apps	pspp	org.gnu.pspp pspp
apps	pst	lutris_postal postal postr steam_icon_232770
apps	psw	org.emilien.Password
apps	pt	butter com.github.bartzaalberg.php-tester eu.scarpetta.PDFMixTool net.sourceforge.projectM packet-tracer popcorn-time popcorntime popcorntime-ru prjm16-transparent
apps	pt3	com.github.PopoutApps.popout3d popout3d
apps	ptc	patchage
apps	ptr	com.whitemagicsoftware.kmcaster cs-mouse gnome-mouse gnome-mouse-properties gnome-settings-mouse input-mouse input-touchpad io.github.pwr_solaar.solaar org.xfce.mouse org.xfce.settings.mouse patroneo piper preferences-desktop-mouse preferences-desktop-peripherals solaar xfce-mouse xfce4-mouse-settings
apps	pts	phoronix-test-suite
apps	ptv	org.pitivi.Pitivi pitivi
apps	pty	putty uk.org.greenend.chiark.sgtatham.putty
apps	pu	pulseUi
apps	pvl	com.protonvpn.www proton-vpn-logo protonvpn-logo
apps	pwa	lutris_phoenix-wright-ace-attorney-trilogy-123 phoenix-wright-ace-attorney-trilogy steam_icon_787480
apps	pwg	piwigo
apps	pwr	auto-cpufreq battery battery-full-charging boot com.github.d4nj1.tlpui computer-log-out cpupower-gui cs-power gnome-logout gnome-power-manager gnome-power-statistics gnome-session gnome-session-halt gnome-session-properties gnome-shutdown kali-powersploit mate-power-manager mate-power-statistics nl.brixit.powersupply org.gnome.PowerStats org.xfce.panel.actions org.xfce.powermanager power-profiles powerdevil powermanga powersploit preferences-system-power preferences-system-power-management preferences-web-browser-cache system-log-out system-shut-down system-shutdown tlp tlpui unity-power-panel utilities-energy-monitor wlogout xfce4-battery-plugin xfce4-power-manager xfce4-power-manager-settings xfce4-session-logout xfpm-ac-adapter xfsm-logout xfsm-shutdown
apps	pws	org.pwsafe.pwsafe pwsafe
apps	pxl	com.orama_interactive.Pixelorama io.sourceforge.Pixelitor pixelitor pixelorama pixeluvo pyhoca_x2go-logo-ubuntu
apps	pxt	com.github.linuxhubit.ppaextender
apps	pxw	kali-pixiewps pixiewps
apps	pyd	lutris_payday-2 payday2 steam_icon_218620 steam_icon_450660 steam_icon_468410 steam_icon_487210
apps	pym	org.pymol.PyMOL pymol
apps	pyn	pynocchio
apps	pyr	pyrenamer
apps	pyt	idle idle3 pycad python python3.10 python3.11 python3.8 python3.9
apps	pyz	org.pyzo.pyzo pyzologo
apps	pz	io.poez.Poezio lutris_project-zomboid poezio project-zomboid steam_icon_108600
apps	pzr	pizarra
apps	q4w	q4wine ua.org.brezblock.q4wine
apps	q5	quickgui_512
apps	qa	qmc2-arcade
apps	qbc	qubic steam_icon_509000
apps	qbr	qbrowser
apps	qch	qchdman
apps	qck	com.georgefb.quickaccess com.github.mdh34.quickdocs org.ubuntubudgie.quickchar quickaccess quickhash
apps	qcl	qcalcfilehash
apps	qct	net.mediaarea.QCTools qctools
apps	qdr	gnome-quadrapassel org.gnome.Quadrapassel quadrapassel
apps	qgis	org.qgis.qgis qgis
apps	qgo	cgoban cgoban_32x32 gnome-iagno gnugo gnugo48 iagno qgo
apps	qjc	org.rncbc.qjackctl qjackctl
apps	qk	etqw quake quake1
apps	qk2	quake2
apps	qk3	quake3
apps	qk4	quake4
apps	ql	com.github.johnfactotum.QuickLookup
apps	qlc	org.qelectrotech.QElectroTech qelectrotech
apps	qlt	io.github.lainsce.Quilter
apps	qmmp	com.ylsoftware.qmmp.Qmmp qmmp
apps	qmp	appimagekit-QMPlay2 io.github.zaps166.QMPlay2 QMPlay2 quimup quimup64
apps	qms	com.qq.QQmusic qqmusic
apps	qn	org.qownnotes.QOwnNotes QOwnNotes
apps	qnp	appimagekit-qnapi io.github.qnapi qnapi qnapi-48
apps	qnt	quanta
apps	qomp	qomp
apps	qph	qphotorec
apps	qpr	com.cuperino.qprompt qprompt
apps	qpz	qupzilla
apps	qrs	com.github.mubitosh.qrshare
apps	qrt	qreator
apps	qsm	qasmixer qsampler
apps	qsy	org.rncbc.qsynth qsynth
apps	qt	qt qt5-logo QtIcon qtlogo
apps	qta	quake3-team-arena
apps	qtc	io.qt.QtCreator qt-creator qtcreator qtcreator_logo_32 qtcreatorubuntu QtProject-qtcreator QtProject-qtcreator-qt5 ubuntu-qtcreator
apps	qtd	designer designer-qt5 designer5 io.qt.Designer io.qt.qdbusviewer qdbusviewer qdbusviewer-qt5 qdbusviewer5 qtdbusviewer qtdesigner qtodotxt QtProject-designer QtProject-qdbusviewer
apps	qtfm	qtfm
apps	qtk	qtikz
apps	qtl	io.qt.Linguist linguist linguist-qt5 linguist5 qtlinguist QtProject-linguist
apps	qtm	qtemu qutim
apps	qtp	qtpass-icon
apps	qtqr	qtqr
apps	qtr	com.github.quaternion org.rncbc.qtractor qtractor quaternion quiterss
apps	qts	assistant assistant-qt5 assistant-qt6 assistant5 com.github.alonsoenrique.quotes qtassistant QtProject-assistant qtscrcpy
apps	qtw	qtwebflix
apps	qv2	appimagekit-qv2ray com.github.Qv2ray qv2ray
apps	qv4	qv4l2
apps	qvd	qvidcap
apps	qvge	qvge
apps	qvw	com.interversehq.qView qview
apps	qwn	fjt qwinff winff
apps	rare	io.github.dummerle.rare rare Rare
apps	rb	appimagekit-rclone-browser com.jetbrains.RubyMine rclone-browser rubymine
apps	rb3	robo3t
apps	rbc	lutris_robocraft robocraft steam_icon_301520
apps	rbt	gnome-robots org.gnome.Robots system-reboot system-restart xfsm-reboot
apps	rcc	rog-control-center
apps	rch	lutris_rochard rochard steam_icon_107800
apps	rck	chat.rocket.RocketChat org.artsoft.rocksndiamonds rocketchat rocketchat-desktop rockradio rocksndiamonds
apps	rcl	appimagekit-rclonetray rclonetray
apps	rcp	org.gnome.Recipes recipes
apps	rcr	ca.edestcroix.Recordbox
apps	rcs	kali-recstudio recstudio reicast
apps	rct	dev.atoft.Reactions net.sourceforge.roccat.roccat-tools reactotron roccat
apps	rd	com.jetbrains.Rider renpy-demo rider
apps	rdc	lutris_red-eclipse net.redeclipse.RedEclipse redeclipse steam_icon_967460
apps	rdm	rdm
apps	rdn	app.rednotebook.RedNotebook rednotebook
apps	rdp	anydesk appimagekit-moonlight com.anydesk.Anydesk com.moonlight_stream.Moonlight com.parsecgaming.parsec gnome-connections gnome-rdp gnome-remote-desktop gnome-user-share krdc krfb litenetworkshares moonlight nomachine org.gnome.Connections org.kde.krdc org.remmina.Remmina org.tigervnc.vncviewer org.virt_manager.virt-viewer parsec preferences-desktop-remote-desktop preferences-system-network-remote preferences-system-network-sharing preferences-system-sharing realvnc-vncviewer remmina rustdesk sunshine teamviewer TeamViewer tigervnc uos-remote-assistance vinagre vnc vncviewer vncviewer48x48 x2goclient yast-ldap-server yast-nfs yast-remote yast-samba-client yast-samba-server
apps	rdr	com.github.ADBeveridge.Raider io.github.opendriver2.Redriver2 redirection redream redriver2 steam_icon_305760
apps	rds	com.redis.RedisInsight redisinsight redshift redshift-gtk
apps	rdt	brave-lgnggepjiihbfdbedefdhcffnmhcahbm-Default chrome-lgnggepjiihbfdbedefdhcffnmhcahbm-Default eradio girl glrp gnome-internet-radio-locator gnomeradio gnuradio-grc gradio kdoubanfm kradio kradio4 krudio library-internet-radio radiotray radiotunes reddit reddit-is-a-dead-bird reditr solstice-reddit-reddit
apps	rec	com.github.amikha1lov.RecApp
apps	rfn	page.tesk.Refine
apps	rfr	referencer
apps	rfs	com.github.marinm.songrec re.fossplant.songrec
apps	rg	lutris_ricochet ricochet-game steam_icon_60
apps	rgd	regedit
apps	rgn	lutris_reigns reigns steam_icon_474750
apps	rgx	com.github.artemanufrij.regextester regexxer
apps	ri	repl.it
apps	ril	com.belmoussaoui.ReadItLater
apps	rkr	rakarrack
apps	rkw	rkward
apps	rl	drracket lutris_rocket-league lutris_rogue-legacy net.runelite.RuneLite net.sourceforge.Ri-li org.racket_lang.Racket plt racket-logo Ri-li rocket-league rogue-legacy RuneLite runelite runelite-launcher steam_icon_241600 steam_icon_252950
apps	rlg	rlogo_icon
apps	rlt	realtimesync
apps	rmb	appimagekit-rambox hamsket rambox rambox-os ramboxpro rememberthemilk
apps	rmg	com.github.Rosalie241.RMG rmg
apps	rmm	lutris_rpg-maker-mv rpg-maker-mv steam_icon_363890
apps	rmn	remnote
apps	rmr	remarkable
apps	rmt	RenameMyTVSeries
apps	rmw	lutris_rimworld rimworld steam_icon_294100
apps	rnc	rancher-desktop
apps	rnd	page.codeberg.foreverxml.Random qrenderdoc renderdoc
apps	rnm	com.github.zelikos.rannum
apps	rnp	renpy
apps	rns	com.jagex.RuneScape renoise runescape
apps	rnt	com.github.flxzt.rnote rnote
apps	ro	rolled-out steam_icon_873270
apps	roa	lutris_rivals-of-aether rivals-of-aether steam_icon_383980
apps	rocs	org.kde.rocs rocs
apps	ror	lutris_rigs-of-rods rigs-of-rods rigsofrods ror RoR
apps	rp	radeon-profile rto-proxy
apps	rpc	appimagekit-Ripcord_Icon appimagekit-rpcs3 fm.cancel.Ripcord net.rpcs3.RPCS3 Ripcord_Icon rpcs3
apps	rpd	rapid-photo-downloader rapidsvn
apps	rpm	org.fdroid.Repomaker
apps	rqc	r-quick-share rquickshare
apps	rqs	icon-requests
apps	rr	appimagekit-raven-reader raven-reader roam-research rtt-rlinux rtt-rstudio
apps	rrr	rs.ruffle.Ruffle ruffle
apps	rs	app.riftshare.RiftShare com.jetbrains.RustRover jetbrains-rustrover racket-slideshow rustrover
apps	rsb	rsibreak
apps	rsc	re.sonny.Commit rescuetime RescueTime rescuetime-mx
apps	rsd	residualvm
apps	rsg	com.rosegardenmusic.rosegarden io.github.martinrotter.rssguard io.github.martinrotter.rssguardlite rosegarden rssguard
apps	rsh	resharper resharpercpp
apps	rsj	re.sonny.Junction
apps	rsl	davinci-resolve DV_Resolve resolve
apps	rso	re.sonny.OhMySVG
apps	rsp	kali-responder responder
apps	rst	re.sonny.Tangram restatic restic rstudio
apps	rsz	com.github.peteruithoven.resizer
apps	rt	com.github.unrud.RemoteTouchpad
apps	rtg	com.abagames.rRootage rrootage
apps	rtr	appimagekit-retroshare cc.retroshare.retroshare-gui net.retrodeck.retrodeck retropie retroshare rise-to-ruins SkraperUI steam_icon_328080
apps	rtx	me.mitya57.ReText retext
apps	ru	appimagekit-radicle-upstream radicle-upstream
apps	rust	lutris_rust rust steam_icon_252490
apps	rvgl	re-volt rvgl
apps	rvl	chat.revolt.RevoltDesktop org.perezdecastro.Revolt revolt revolt-desktop
apps	rvr	org.gnome.Reversi
apps	rw	riot riot-web
apps	rwt	com.rawtherapee.RawTherapee rawtherapee
apps	ryg	rygel
apps	ryj	org.ryujinx.Ryujinx ryujinx
apps	rzr	razercommander xyz.z3ntu.razergenie
apps	s2	lutris_sanctum-2 sanctum-2 steam_icon_210770
apps	s3	lutris_the-sims-3 steam_icon_341800 steam_icon_47890 studio-3t Studio-3T the-sims-3
apps	s4	lutris_the-sims-4 steam_icon_1222670 the-sims-4
apps	s5	steam_icon_553850
apps	sa	com.synology.SynologyAssistant synology-assistant synology-uploader-photos
apps	safe	accessories-safe
apps	sas	lutris_sheepy-a-short-adventure sheepy-a-short-adventure steam_icon_1568400
apps	sb	com.gluonhq.SceneBuilder sidekick-browser
apps	sbd	lutris_stealth-bastard-deluxe stealth-bastard-deluxe steam_icon_209190 subdownloader
apps	sbn	org.sabnzbd.sabnzbd sabnzbdplus
apps	sbs	appimagekit-substance org.subsurface_divelog.Subsurface subsonic substance subsurface-icon
apps	sbt	gnome-subtitles org.kde.subtitlecomposer subtitlecomposer subtitleeditor
apps	sc	org.ubuntubudgie.shuffler-control
apps	sc4	org.scintilla.SciTE Sci48M
apps	scd	net.sourceforge.scidavis scidavis
apps	sch	schism schism-icon-128
apps	scid	io.github.benini.scid scid
apps	scl	org.gnome.Social org.scilab.Scilab scilab
apps	scm	org.scummvm.ScummVM scummvm
apps	scn	applications-science atomix com.github._4lex4.ScanTailor-Advanced com.github.unrud.djpdf org.gnome.atomix org.scantailor.ScanTailor scans2pdf scantailor ScanTailor scenarist scinotes
apps	sco	lutris_sven-co-op steam_icon_225840 sven-co-op
apps	scp	sk1-color-picker
apps	scr	com.github.mohelm97.screenrecorder edu.mit.Scratch net.scribus.Scribus scratch scratch-desktop scratch2 screencloud scribus scribus-ng scribus-trunk securecrt securecrt_64
apps	scs	com.synology.CloudStationBackup synology-cloud-station-backup synology-cloud-station-drive
apps	scsi	kcmscsi scsi
apps	sct	scout-app
apps	sd	appimagekit-shadow-dev appimagekit-shadow-testing com.synology.SynologyDrive io.github.parnassius.SysDVR-Qt lutris_sakura-dungeon org.speed_dreams.SpeedDreams sakura-dungeon shadow-dev shadow-testing speed-dreams steam_icon_407330 synology-drive system76-driver
apps	sdk	gnome-sudoku id.sideka.App org.gnome.Sudoku sideka
apps	sdp	kali-ssdeep ssdeep
apps	sdr	org.sdrangel.SDRangel sdrangel sdrangel_icon
apps	se	lutris_space-engineers org.kde.SymbolEditor shutter-encoder space-engineers sr-editor steam_icon_244850 SymbolEditor symboleditor
apps	sf	gnome-samegnome gnome-swell-foop org.gnome.SwellFoop swell-foop
apps	sfe	sweethome3d-furniture-editor
apps	sff	space.fips.Fips
apps	sfl	com.seafile.Client seafile seafile-client seafile-client-qt5
apps	sfs	sofastats
apps	sft	sftpclient
apps	sfxr	sfxr-qt
apps	sfy	io.github.slgobinath.SafeEyes safeeyes
apps	sg	stoken-gui
apps	sgd	com.steamgriddb.SGDBoop
apps	sgl	com.sigil_ebook.Sigil sigil
apps	sgr	steamdeck-gaming-return
apps	sgt	sgt-launcher
apps	sh	gnome-session-hebirnate gnome-session-hibernate lutris_super-hexagon security-high steam_icon_221640 super-hexagon system-hibernate system-suspend-hibernate xfsm-hibernate
apps	shd	appimagekit-shadow appimagekit-shadow-beta appimagekit-shadow-preprod lutris_shadwen net.shadps4.shadPS4 org.shadowsocks.qt5client shadow shadow-beta shadow-preprod shadowsocks-qt5 shadps4 shadPS4 shadwen steam_icon_425210
apps	shl	com.github.linuxhubit.shouldidoit kali-shellnoob shellnoob
apps	shr	appimagekit-sharik com.rafaelmardojai.SharePreview de.haeckerfelix.Shortwave sharik
apps	sht	com.github.bcedu.shutdownscheduler com.shatteredpixel.shatteredpixeldungeon org.shotcut.Shotcut shotcut
apps	shw	com.github.artemanufrij.showmypictures
apps	si	sc_ide sdl_instead
apps	sig	org.signal.Signal signal-desktop signal-desktop-beta
apps	sir	simple-image-reducer
apps	sj	org.gnome.SoundJuicer sound-juicer
apps	sk1	sk1
apps	skl	lutris_skullgirls skullgirls steam_icon_245170
apps	skr	gnucash gnucash-icon org.gnucash.GnuCash org.kde.skrooge skrooge
apps	sky	com.skype.Client ms-skype skydrive skype skypeforlinux solstice-skype-web
apps	sl	cs-screensaver org.emilien.SpaceLaunch preferences-security-firewall security-low smw-leveledit xfce-system-lock
apps	slc	slic3r
apps	sld	net.mancubus.SLADE slade
apps	slf	solfege
apps	slg	so.libdb.gtkcord4
apps	slk	com.slack.Slack silksong slack steam_icon_1030300
apps	slm	slimbookbattery slimjet
apps	sln	com.github.ryanakca.slingshot org.gnome.Solanum selene selinux setroubleshoot_icon slingscold slingshot
apps	slr	org.solarus_games.solarus.Launcher solarus solarus-launcher
apps	sls	soulseek
apps	sm	com.sublimemerge.App lutris_sonic-mania lutris_surviving-mars lutris_synergy security-medium sonic-mania steam_icon_17520 steam_icon_464920 steam_icon_584400 sublime-merge surviving-mars svp-manager4 synergy-mod
apps	smb	appimagekit-somiibo smbx13 somiibo
apps	smc	lutris_secret-maryo-chronicles smc
apps	smf	somafm
apps	smk	smokinguns
apps	sml	appimagekit-seamly2d io.seamly.seamly2d smilla smilla-enlarger smillaenlarger
apps	smn	simon
apps	smp	byzanz com.github.artemanufrij.screencast deepin-screen-recorder gtk-recordmydesktop istanbul kali-recordmydesktop kazam record-desktop recordmydesktop semaphor simplescreenrecorder xvidcap
apps	smr	smartsim
apps	sms	org.gottcode.Simsu simsu
apps	smt	lutris_simutrans simutrans steam_icon_434520 SysMonTask
apps	smw	sm64ex SM64nightly sm64plus smw SuperMario64
apps	sn	appimagekit-session-desktop sage-notebook session-desktop
apps	snb	net.sonobus.SonoBus sonobus
apps	snd	brave-eikjhbkpemdappjfcmdeeeamdpkgabmk-Default chrome-eikjhbkpemdappjfcmdeeeamdpkgabmk-Default com.github.jms55.Sandbox io.github.Soundux oggconvert org.soundconverter.SoundConverter solstice-soundcloud-soundcloud soundcloud soundconverter soundkonverter soundnode soundux soundwire
apps	snf	sunflower
apps	sng	appimagekit-sengi sengi singular Singular songkick
apps	snp	com.github.bartzaalberg.snaptastic
apps	sns	com.snes9x.Snes9x snes9x synology-note-station
apps	snt	sentinel
apps	snv	sunvox
apps	sol	lutris_spec-ops-the-line spec-ops-the-line steam_icon_50300
apps	soma	lutris_soma soma steam_icon_282140
apps	soo	SpiderOakONE
apps	sp	io.github.tlcfem.suanPan lutris_the-stanley-parable net.sonic_pi.SonicPi org.soapui.SoapUI soapui sonic-pi steam_icon_221910 suanPan the-stanley-parable xfce4-sample-plugin xfce4-statusnotifier-plugin
apps	spa	lutris_space-pirates-and-zombies space-pirates-and-zombies steam_icon_107200
apps	spc	com.github.treagod.spectator org.eu.encom.spectral sm.puri.Chatty spacemacs spaceview
apps	spd	spideroak SpiderOak
apps	spek	spek
apps	spf	spflashtool
apps	spl	ksplash preferences-system-splash sepolicy system-config-selinux xfce4-splash
apps	spn	gnome-session-suspend sleep system-suspend xfpm-suspend xfsm-suspend
apps	spot	dev.alextren.Spot
apps	spr	appimagekit-superpaper appimagekit-supertux2 lutris_super-meat-boy net.supertuxkart.SuperTuxKart org.sparkleshare.SparkleShare org.supertux.SuperTux-Milestone1 org.supertuxproject.SuperTux sparkleshare sparklogosmall Sparrow sportstracker steam_icon_1572920 steam_icon_40800 superkaramba supermeatboy superpaper superproductivity supertux supertux2 supertuxkart
apps	sps	sm.puri.Stream
apps	spt	spotify-qt
apps	spy	org.spyder_ide.spyder spyder spyder3
apps	sqe	solarus-quest-editor
apps	sqk	squeak
apps	sql	appimagekit-beekeeper-studio beekeeper-studio calligrakexi com.github.alecaddd.sequeler com.jetbrains.DataGrip datagrip dbeaver dbeaver-ee io.beekeeperstudio.Studio io.dbeaver.DBeaverCommunity kali-database-assessment-trans kexi libreoffice-base libreoffice7.3-base libreoffice7.4-base libreoffice7.5-base libreoffice7.6-base mysql-workbench office-database openoffice4-base oracle-sqldeveloper org.libreoffice.LibreOffice.base org.sqlitebrowser.sqlitebrowser pgadmin pgadmin3 pgadmin4 pgAdmin4 sqldeveloper sqlitebrowser sqliteman x-office-database
apps	sr	com.github.ryonakano.reco deepin-voice-recorder krec lutris_slime-rancher org.gnome.SoundRecorder org.kde.krecorder slime-rancher sound-recorder steam_icon_433340
apps	srb	org.sauerbraten.Sauerbraten org.srb2.SRB2Kart sauerbraten srb2kart
apps	srf	surfshark
apps	srk	sirikali
apps	srm	com.steamgriddb.steam-rom-manager steam-rom-manager
apps	srv	appimagekit-servez kali-system-services-trans preferences-system-services servez serviio servo yast-services-manager yast-sysconfig
apps	ss	com.stepmania.StepMania lutris_sakura-spirit lutris_slay-the-spire sakura-spirit scim-setup SheepShaver slay-the-spire steam_icon_313740 steam_icon_646570 stepmania-ssc SuperSlicer system-save-session
apps	sse	lutris_skyrim-script-extender-64-skse64 skyrim-script-extender steam_icon_365720
apps	st	accessories-screenshot-tool com.github.zocker_160.SyncThingy lutris_shadow-tactics-blades-of-the-shogun shadow-tactics stata statalogo_14 statalogo_16 steam_icon_418240
apps	stc	stack sticky
apps	std	lutris_scania-truck-driving-simulator org.vinegarhq.Vinegar.studio scania-truck-driving-simulator steadyflow steam_icon_258760
apps	ste	sweethome3d-textures-editor
apps	step	step
apps	stl	io.github.stella_emu.Stella lutris_stellaris org.stellarium.Stellarium steam_icon_281990 stella stellaris stellarium
apps	stm	com.valvesoftware.SteamLink steam_icon_250820 steamlink steamvr
apps	stn	org.tuxfamily.StuntRally stuntrally
apps	str	appimagekit-stretchly lutris_starbound net.hovancik.Stretchly starbound stardict stargus staruml steam_icon_211820 streamtuner streamtuner2 stretchly stride
apps	sts	lutris_satisfactory satisfactory spring-tool-suite steam_icon_526870
apps	stz	org.cvfosammmm.Setzer
apps	su	com.github.philip-scott.spice-up com.github.philip_scott.spice-up switchuser system-switch-user xfsm-switch xfsm-switch-user
apps	sums	io.gitlab.leesonwai.Sums
apps	sv	lutris_stardew-valley sonic-visualiser stardew-valley steam_icon_413150
apps	svg	svgcleaner
apps	sw	smw-worldedit StartWine
apps	sw4	sw4stm32
apps	swp	lutris_the-swapper steam_icon_231160 sweeper the-swapper
apps	swt	com.github.keyilan.swatches com.sweethome3d.Sweethome3d swatchbooker sweethome3d
apps	sxb	dvdstyler stock_xfburn-burn-cd
apps	sym	org.gnome.design.SymbolicPreview
apps	syn	appimagekit-synfigstudio io.github.martchus.syncthingtray me.kozec.syncthingtk org.synfig.SynfigStudio quicksynergy syncplay syncthing syncthing-gtk syncthingtray synergy synfig_icon
apps	sys	kali-stress-testing-trans org.xfce.panel.statustray org.xfce.panel.systray syspeek systach systemtray xfce4-systray
apps	t2	lutris_torchlight-ii steam_icon_200710 torchlight-2
apps	t7	lutris_tekken-7 steam_icon_389730 tekken-7
apps	tab	steam_icon_508440 totally-accurate-battle-simulator
apps	tau	org.gnome.Tau
apps	taxi	com.github.alecaddd.taxi taxi
apps	tb	lutris_tibia tibia Tibia tor-browser-nightly
apps	tba	tor-browser-alpha
apps	tbc	org.nickvision.tubeconverter
apps	tbf	de.schmidhuberj.tubefeeder tubefeeder
apps	tc	appimagekit-tc com.moddb.TotalChaos gtk-theme-config stylesheet tc tc-twitch text-css
apps	tc8	com.tic80.TIC_80 tic80
apps	tcc	tuxedo-control-center
apps	tce	tce true-combat-elite
apps	tch	com.github.joseexposito.touche technic-launcher
apps	td	tupitube.desk
apps	tdd	tw.ddnet.ddnet
apps	tdl	chrome-emefpkhgihlhfddcjfghpndaeliajgjj-Default steam_icon_1664410 tidal touhou-dream-logical-world
apps	tdm	tracktion-download-manager
apps	tdp	tdeprintfax
apps	tdw	tdewalletmanager
apps	teo	net.sourceforge.Teo
apps	tf	lutris_team-fortress-2 steam_icon_440 team-fortress2 tumiki-fighters
apps	tfc	lutris_team-fortress-classic steam_icon_20 steam_icon_3545060 team-fortress-classic team-fortress2-classified
apps	tg	brave-ibblmnobmgdmpoeblocemifbpglakpoi-Default brave-majiogicmcnmdhhlgmkahaleckhjbmlk-Default chrome-ibblmnobmgdmpoeblocemifbpglakpoi-Default chrome-majiogicmcnmdhhlgmkahaleckhjbmlk-Default com.github.appadeia.Taigo io.github.tdesktop_x64.TDesktop org.telegram.desktop snap.telegram-desktop. telegram telegram-desktop telegram-desktop-bin
apps	tgl	com.toggl.TogglDesktop toggldesktop
apps	tgn	tagainijisho
apps	tgr	org.nickvision.tagger
apps	th	theia theia-electron theia-ide
apps	thd	lutris_the-dark-mod thedarkmod
apps	thf	com.github.kmwallio.thiefmd
apps	thm	klassy-settings kpersonalizer litedesktop lookswitcher org.xfce.settings.appearance preferences-desktop-theme preferences-desktop-theme-global preferences-theme
apps	thn	com.tdameritrade.ThinkOrSwim cs-thunderbolt org.thonny.Thonny preferences-desktop-thunderbolt thingy thinkorswim thonny thunderbird-beta thunderbolt
apps	thr	appimagekit-thorium thorium
apps	thx	ru.wohlsoft.TheXTech thextech
apps	ti	preferences-desktop-touchpad touchpad touchpad-indicator
apps	tilp	tilp
apps	tkd	org.kde.tokodon tokodon
apps	tkt	brave-nlalbmkafgmoifbeooblidblkmlhhpnc-Default chrome-nlalbmkafgmoifbeooblidblkmlhhpnc-Default tiktok
apps	tl	com.github.bleakgrey.tootle com.github.marbetschar.time-limit
apps	tlb	toolbox
apps	tlc	org.kde.tellico tellico
apps	tld	org.mapeditor.Tiled tiled
apps	tlg	ToneLib-GFX
apps	tlj	ToneLib-Jam
apps	tlm	tilem
apps	tln	lutris_touhou-luna-nights steam_icon_851100 tlauncher touhou-luna-nights
apps	tlp	com.frac_tion.teleport
apps	tls	steam_icon_1105890 tilesetter
apps	tlz	ToneLib-Zoom
apps	tm	indicator-sensors ksensors lutris_to-the-moon mate-sensors-applet psensor steam_icon_206440 thermal-monitor to-the-moon xfce-sensors xsensors
apps	tmb	tumblr
apps	tmc	ca.hamaluik.Timecop teamcity
apps	tmd	timidity
apps	tmh	tomahawk
apps	tmk	timekpr
apps	tmm	tmm
apps	tmp	Temps
apps	tmr	com.github.parnold-x.timer
apps	tms	brave-ikllmbphdgkmdfmmlohklnceeccfoppn-Default chrome-ikllmbphdgkmdfmmlohklnceeccfoppn-Default com.teamspeak.TeamSpeak com.teamspeak.TeamSpeak3 teamspeak3 timestripe vivaldi-ikllmbphdgkmdfmmlohklnceeccfoppn-Default
apps	tmt	com.github.lainsce.timetable com.github.luizaugustomm.tomato com.github.tomatoers.tomato net.danigm.timetrack pomodoro-indicator tamtam-app tomate tomato
apps	tnc	org.tenacityaudio.Tenacity tenacity
apps	tnd	appimagekit-tandem brave-hejiihbkifllpgdfndalmghiodgkefan-Default chat.tandem.Client chrome-hejiihbkifllpgdfndalmghiodgkefan-Default tandem tinder
apps	tnf	lutris_trackmania-nation-forever steam_icon_11020 trackmania-nations-forever
apps	tng	org.gottcode.Tanglet tanglet
apps	tnm	com.github.taiko2k.tauonmb tauonmb
apps	tnr	com.github.louis77.tuner
apps	top	appimagekit-stacer bottom btop deepin-system-monitor gkrellm glances gnethogs gnome-monitor gnome-system-monitor htop io.missioncenter.MissionCenter ksysguard lxtask mate-system-monitor mission-center net.nokyan.Resources nvtop nwg-processes org.gnome.SystemMonitor org.kde.plasma-systemmonitor org.kde.plasma.awesomewidget org.kde.plasma.systemloadviewer org.kde.resourcesMonitor org.xfce.taskmanager package_utilities plasma-systemmonitor qps resources stacer Stacer system-monitor utilities-system-monitor xfce4-taskmanager
apps	tour	org.gnome.Tour
apps	tp	lutris_the-talos-principle lutris_thimbleweed-park steam_icon_257510 steam_icon_569860 the-talos-principle thimbleweed-park
apps	tp1	com.gitlab.tipp10.tipp10 tipp10
apps	tqn	fifteenpuzzle gnome-taquin org.gnome.Taquin
apps	tr	com.toontownrewritten.Launcher io.github.TransmissionRemoteGtk lutris_terraria lutris_tomb-raider lutris_typerider org.equeim.Tremotesf shticker-book-rewritten steam_icon_105600 steam_icon_203160 steam_icon_258890 tegaki-recognize terraria TETR.IO tetrio-desktop tomb-raider tooniversal toontown-rewritten transgui transgui-2 transmission-remote-gtk type-rider
apps	trb	appimagekit-turbowarp-desktop lutris_toribash org.tribler.Tribler org.turbowarp.TurboWarp steam_icon_248570 toribash tribler turbowarp turbowarp-desktop
apps	trc	kali-truecrypt net.sourceforge.torcs org.codeberg.som.Tracks torcs trackma tracktion tracktion7 truecrypt
apps	trd	com.github.chasinglogic.tardis
apps	trg	torguard
apps	trl	com.github.zadam.trilium trelby trello trilium trilium-notes trillian
apps	trm	com.grangerhub.Tremulous com.termius.Termius instant-messenger terminus termius-app tor-messenger tormessenger tremulous trimage
apps	trn	appimagekit-torrenttools appimagekit-trinity-desktop com.github.artemanufrij.translit com.github.bleakgrey.transporter com.github.davidmhewitt.torrential com.github.nick92.tranqil lutris_trine lutris_trine-2-complete-story lutris_trine-3-the-artifacts-of-power steam_icon_319910 steam_icon_35700 steam_icon_35720 torrenttools tranquil transmageddon trine trine2 trine3 trinity-desktop
apps	trs	torrserver trashindicator tresorit
apps	trt	lutris_terratech org.laptop.TurtleArtActivity steam_icon_285920 tartube terratech thg thg_logo tortoisehg turtleart
apps	trv	gnome-tetraves gnome-tetravex org.gnome.Tetravex
apps	ts	cs-cat-admin gksu-root-terminal lutris_tabletop-simulator org.taisei_project.Taisei org.xfce.terminal-settings steam_icon_286160 tabletop-simulator taisei torii-srs utilities-terminal_su yast-sudo
apps	tsc	org.secretchronicles.TSC tizen-studio-certificatemanager tsc
apps	tsd	tizen-studio-dynamicanalyzer
apps	tse	tizen-studio-em
apps	tsi	tizen-studio-ide
apps	tsk	io.elementary.tasks taskbar
apps	tsl	lutris_teslagrad steam_icon_249590 teslagrad
apps	tsm	steam_icon_395160 toby-the-secret-mine
apps	tt	appimagekit-tweet-tray lutris_toki-tori steam_icon_38700 toki-tori tweet-tray
apps	tuhi	org.freedesktop.Tuhi
apps	tusk	tusk tusk-app
apps	tux	net.sourceforge.ExtremeTuxRacer penguin pinguin tux tuxracer
apps	tv	TeighaViewer
apps	tvt	freetuxtv me-tv paromplayer tvmaxe tvtime
apps	tw	preferences-desktop-theme-windowdecorations steam_icon_325610 total-war
apps	twa	lutris_thomas-was-alone steam_icon_220780 thomas-was-alone
apps	twc	tuxedo-webfai-creator
apps	twf	com.belmoussaoui.Authenticator gnome-twofactorauth org.tabos.twofun
apps	twn	twinkle
apps	twp	twupic
apps	twr	com.teeworlds.Teeworlds lutris_teeworlds steam_icon_380840 teeworlds
apps	twt	com.vinszent.GnomeTwitch gnome-twitch goa-account-twitter Nocturn nocturn Nocturn-linux pm.mirko.Twitz solstice-twitter-twitter streamlink-twitch-gui tweetdeck twitter
apps	tx	brave-jgeocpdicgmkeemopbanhokmhcgcflmi-Default chrome-jgeocpdicgmkeemopbanhokmhcgcflmi-Default msedge-jgeocpdicgmkeemopbanhokmhcgcflmi-Default org.tug.texworks TeXmacs texmacs TeXworks twitter-x
apps	txc	tuxcut
apps	txg	ar.com.tuxguitar.TuxGuitar tuxguitar
apps	txh	kali-reverse-engineering-trans text-x-hex
apps	txm	com.tux4kids.tuxmath net.xm1math.Texmaker texmaker tuxmath
apps	txp	org.tuxpaint.Tuxpaint tuxpaint
apps	txs	org.texstudio.TeXstudio texstudio
apps	txt	com.github.liferooter.textpieces com.tux4kids.tuxtype io.github.martinrotter.textosaurus textadept textosaurus tuxtype
apps	typ	com.github.manexim.typewriter io.github.mmstick.FontFinder org.gnome.design.Typography typecatcher
apps	tzl	org.gottcode.Tetzle tetzle
apps	u4d	ubinary ue4editor
apps	uc	ubuntustudio-controls uno-calculator
apps	ue	unity-editor-icon
apps	uget	com.ugetdm.uGet uget uget-icon
apps	uh	org.unknown_horizons.UnknownHorizons unknown-horizons
apps	ukuu	ukuu
apps	ul	com.umlet.Umlet umlet_logo
apps	umb	org.kde.umbrello umbrello
apps	ums	ums
apps	unc	io.github.yairm210.unciv unciv
apps	und	lutris_undertale steam_icon_391540 undertale
apps	uns	brave-cnlnpjpkobmmbdnpbdceplbemhibbhll-Default chrome-cnlnpjpkobmmbdnpbdceplbemhibbhll-Default unison-gtk unsplash
apps	unt	appimagekit-unityhub com.unity.UnityHub lutris_unturned steam_icon_304930 unityhub unturned
apps	up	preferences-ubuntu-panel upload-pictures
apps	upl	lutris_uplink steam_icon_1510 uplink
apps	ups	org.upscayl.Upscayl upscayl upsource
apps	upw	upwork
apps	uqm	net.sourceforge.uqm_mods.UQM-MegaMod uqm
apps	urb	info.urbanterror.UrbanTerror urbanterror uterror
apps	urm	com.github.aleksandar-stefanovic.urmsimulator
apps	urs	urserver
apps	usb	usb usbguard-icon usbview
apps	usg	org.gnome.Usage
apps	usr	calligraauthor config-users cs-user gnome-user-accounts kuser liteusermanager preferences-desktop-user preferences-system-users system-config-authentication system-config-users system-users user-info user-manager user_icon userdrake users-admin yast-auth-client yast-users
apps	ut	ubuntu-tweak
apps	utl	applications-utilities utools
apps	utox	appimagekit-qtox io.github.qtox.qTox qtox ricin toxygen utox
apps	utt	unity-tweak-tool
apps	va	gnome-video-arcade
apps	vb	appimagekit-viper-browser viper-browser
apps	vbam	vbam visualboyadvance-m
apps	vbr	com.viber.Viber io.github.libvibrant.vibrantLinux viber vibrantLinux
apps	vc	veyon-configurator
apps	vcl	com.github.needle-and-thread.vocal com.github.needleandthread.vocal vocal
apps	vcm	vacuum
apps	vct	vectr
apps	vcv	VCVRack
apps	vd	com.github.unrud.VideoDownloader
apps	vdc	com.ozmartians.VidCutter vidcutter
apps	vdm	appimagekit-videomass videomass
apps	vdr	vdrift vdrift-64x64
apps	ve	vscode-exploration
apps	vi	com.vscodium.codium-insiders vscode-insiders vscodium-insiders
apps	vice	net.sf.VICE
apps	vico	vico
apps	vieb	appimagekit-vieb dev.vieb.Vieb vieb
apps	vifm	vifm
apps	vk	vk
apps	vkd	vkaudiosaver
apps	vkn	org.viking.Viking viking
apps	vks	vokoscreen
apps	vl	com.github.corna.Vivado vivado_logo
apps	vlc	com.github.basjam.valacompiler
apps	vld	vivaldi-beta
apps	vlh	lutris_valheim steam_icon_892970 valheim
apps	vlm	drive-removable-media-usb org.xfce.volman
apps	vln	ca.andyholmes.Valent
apps	vlr	lutris_veloran net.veloren.airshipper net.veloren.veloren veloren
apps	vls	com.github.bcedu.valasimplehttpserver
apps	vlt	io.github.mpobaschnig.Vaults
apps	vly	valyriatear
apps	vm	aqemu aqemu-32x32 boxbuddy distrobox gnome-boxes indicator-virtual-box io.github.dvlv.boxbuddy org.gnome.Boxes org.virt_manager.virt-manager qemu qemu-system-aarch64 qemu-system-arm qemu-system-i386 qemu-system-x86_64 qemu-system-x86_64-spice quickemu quickgui VBox veyon-master vimeo virt-manager virt-viewer virtualbox VirtualBox virtualbox-ose vmplayer vmware vmware-player vmware-workstation
apps	vmd	vmd
apps	vmpk	kcmmidi net.sourceforge.VMPK pianoteq pianoteq-stage tdemid vmpk
apps	vn	com.github.vkohaupt.vokoscreenNG vmnetcfg vmware-netcfg vokoscreenNG
apps	vnd	application-vnd.flatpak io.elementary.sideload org.flatpak.qtdemo
apps	vng	io.github.vinegarhq.Vinegar org.vinegarhq.Vinegar
apps	vnt	appimagekit-vnote fun.vnote.app.VNote io.github.vegad.vnotes vnote
apps	vol	alsamixer alsamixergui audio-card audio-speakers audio-volume-high com.saivert.pwvucontrol cs-sound epulse gnome-alsamixer-icon gnome-mixer gnome-settings-sound gnome-sound-properties gnome-sound-recorder gnome-volume-control indicator-sound-switcher kcmsound kmix litesoundsglob multimedia-volume-control mx-system-sounds org.pulseaudio.pavucontrol org.xfce.pulseaudio-plugin pasystray pavucontrol pavucontrol-qt phonon-gstreamer pnmixer preferences-desktop-sound preferences-desktop-text-to-speech preferences-sound pwvucontrol unity-sound-panel volumeicon wxlame xfce-sound xfce4-mixer xfce4-pulseaudio-plugin xfce4-sound yast-sound
apps	vp	visual-paradigm
apps	vpr	vprerex
apps	vrc	veracrypt veracrypt.xpm
apps	vrs	com.virustotal.VirusTotalUploader virustotal
apps	vs	F516_VRoidStudio.0 lutris_vroid-studio org.gnome.design.VectorSlicer vivaldi-snapshot vroid-studio
apps	vsl	visualvm
apps	vst	vstudio
apps	vsz	io.github.veusz.Veusz veusz
apps	vt	org.gnome.gitlab.YaLTeR.VideoTrimmer
apps	vt3	vita3k
apps	vtm	appimagekit-vitomu vitomu
apps	vv	lutris_victor-vran steam_icon_345180 vice-vsid victor-vran vmware-view vmware-vmrc
apps	vvv	lutris_vvvvvv steam_icon_70300 VVVVVV
apps	vw	void-wizard
apps	vx	vice-x128 vice-x64 vice-x64dtv vice-xcbm2 vice-xpet vice-xplus4 vice-xscpu64 vice-xvic
apps	vym	vym
apps	w02	windstille-0.2
apps	w2	lutris_the-witcher-2-assassins-of-kings-enhanced-edition steam_icon_20920 the-witcher-2
apps	w3	lutris_the-witcher-3-wild-hunt steam_icon_292030 the-witcher-3
apps	wa	com.github.birros.WebArchives com.github.eneshecan.WhatsAppForLinux io.github.mimbrero.WhatsAppDesktop lutris_worms-armageddon steam_icon_217200 wazzapp whatsapp whatsapp-desktop whatsapp-for-linux whatsapp-nativefier whatsdesk worms-armageddon zapzap
apps	warp	app.drey.Warp
apps	wav	audacity org.audacityteam.Audacity
apps	waw	eu.scarpetta.QtWAW
apps	wbc	cookie gourmet preferences-web-browser-cookies
apps	wbm	appimagekit-webamp-desktop webamp-desktop
apps	wbp	com.github.artemanufrij.webpin webplotdigitizer
apps	wbr	com.jonathankang.Weibird
apps	wbt	io.webtorrent.WebTorrent webtorrent-desktop
apps	wbw	com.github.kjlaw89.webwatcher
apps	wby	webby
apps	wc	org.ubuntubudgie.wallstreet-control
apps	wch	appimagekit-wewechat com.qq.weixin.deepin com.tencent.WeChat deepin.com.wechat wechat weixin wewechat
apps	wdl	org.widelands.Widelands widelands wl-ico-64
apps	we	wesnoth-1.10_editor-icon wesnoth-1.12_editor-icon wesnoth-1.14_editor-icon wesnoth_editor wesnoth_editor-icon
apps	weka	weka
apps	wf	org.gtk.WidgetFactory4
apps	wg	wpa_gui
apps	wh	C06E_winhlp32.0 D15F_hh.0 wine-help winhelp
apps	whl	com.github.sdv43.whaler social.whalebird.WhalebirdDesktop whalebird
apps	wht	com.ktechpit.whatsie org.gabmus.whatip whatpulse whatsie wihotspot
apps	wi	welle.io
apps	wike	com.github.hugolabe.Wike
apps	wine	1CD8_rundll32.0 2905_wscript.0 5742_rundll32.0 7765_winebrowser.0 appimagekit-wine-launcher bottles_wine D3EE_SwitchBoard.0 deepin-wine-assist org.winehq.Wine wine wine-launcher
apps	wire	appimagekit-wire-desktop com.wire.WireDesktop wire wire-desktop
apps	wkg	com.rafaelmardojai.WebfontKitGenerator
apps	wkp	wikipedia
apps	wl	web-lounge wolfram-language
apps	wlc	wallch
apps	wlf	com.realm667.WolfenDoom_Blade_of_Agony m_doom wolfenstein
apps	wlp	com.github.philip-scott.wallpaperize wallpapoz
apps	wm	com.github.plugarut.wingpanel-monitor cs-tiling deepin-multitasking-view multitasking-view preferences-system-tabbox preferences-system-windows-effect-flipswitch preferences-system-windows-move webapp-manager WickrMe
apps	wmr	com.github.ronnydo.wammer
apps	wmt	com.tencent.wemeet wemeet wemeetapp
apps	wnb	winbox
apps	wnc	bottles_wine-winecfg wine-winecfg winecfg
apps	wnd	windows95 windscribe wunderlist
apps	wnf	winefile
apps	wng	com.github.aggalex.wineglass com.wings3d.WINGS io.elementary.wingpanel io.github.aggalex.Wineglass topmenu-applet wingpanel wings3d
apps	wnm	winemine
apps	wnt	bottles_winetricks com.github.Matoking.protontricks winetricks
apps	woe	com.wps.Office.etmain com.wps.Office2019.etmain wps-office-etmain wps-office2019-etmain
apps	wog	lutris_world-of-goo steam_icon_22000 steam_icon_22010 world-of-goo worldofgoo
apps	wok	wps-office2019-kprometheus
apps	wop	com.wps.Office.pdfmain com.wps.Office2019.pdfmain wps-office-pdfmain wps-office2019-pdfmain
apps	wot	com.worldoftanks.Client world-of-tanks
apps	wow	com.wps.Office.wppmain com.wps.Office.wpsmain com.wps.Office2019.wppmain com.wps.Office2019.wpsmain wps-office-wppmain wps-office-wpsmain wps-office2019-wppmain wps-office2019-wpsmain
apps	wp	wolfram-player
apps	wps	wpscrackgui
apps	wrd	2EF4_wordpad.0 97C1_wordpad.0 dev.mufeed.Wordbook gnome-documents kali-wpscan org.gnome.Documents package_wordprocessing unity-webapps-wordpress wordpad wordpress wordview wordview.xpm wpcom wpscan
apps	wrf	lutris_warframe steam_icon_230410 warframe
apps	wrg	wargus
apps	wrk	appimagekit-workflowy com.amazon.Workspaces Worker workflowy workrave
apps	wrl	net.worldofpadman.WoP wop worldofpadman
apps	wrm	lutris_worms-reloaded org.gna.Warmux steam_icon_22600 steam_icon_22690 steam_icon_233840 steam_icon_327030 warmux warmux_128x128 worms
apps	wrp	org.x.Warpinator warpinator
apps	wrs	net.warsow.Warsow warsow wsw
apps	wrz	net.wz2100.wz2100 warzone2100
apps	ws	com.jetbrains.WebStorm io.github.nroduit.Weasis litewelcome Weasis webstorm welcome-screen Write144x144 write_stylus
apps	wsb	io.wasabiwallet.WasabiWallet wassabee woeusb-logo woeusbgui-icon
apps	wsl	cs-workspaces kpager mate-panel-workspace-switcher nwg-workspace org.xfce.panel.pager org.xfce.workspaces preferences-desktop-virtual workspace-switcher workspace-switcher-left-bottom
apps	wsn	lutris_the-battle-for-wesnoth org.wesnoth.Wesnoth steam_icon_599390 wesnoth wesnoth-1.10-icon wesnoth-1.12-icon wesnoth-1.14-icon wesnoth-icon
apps	wsr	workspace-switcher-right-bottom workspace-switcher-right-top
apps	wst	preferences-desktop-workspaces workspace-switcher-top-left xfce4-workspaces
apps	wt	com.endlessnetwork.tankwarriors in.p1x.TanksOfFreedom lutris_war-thunder net.gaijin.WarThunder net.sourceforge.atanks net.sourceforge.btanks steam_icon_236390 war-thunder
apps	wtc	lutris_the-witcher-enhanced-edition steam_icon_20900 the-witcher
apps	wth	com.librehat.yahooweather cumulus gis-weather gnome-weather indicator-weather meteo-qt org.gnome.Weather org.kde.kweather org.xfce.panel.weather solstice-bbc-bbc-weather solstice-metoffice-weather solstice-nhk-nhk-weather solstice-weathernews-japan weather weather-storm weather-widget xfce4-weather
apps	wtl	wootility
apps	wu	bottles_wine-uninstaller D23E_msiexec.0 msiexec wine-uninstaller
apps	wvb	io.wavebox.Wavebox wavebox
apps	wvf	com.tracktion.Waveform waveform11
apps	wxc	wxcas
apps	wxg	wxglade
apps	wyd	waydroid
apps	wyl	wayland
apps	wyr	io.github.Andrettin.Wyrmsun lutris_wyrmsun steam_icon_370070 wyrmsun
apps	wzn	com.wiz.Note wiznote
apps	x2	lutris_xcom-2 steam_icon_268500 xcom-2
apps	xap	lutris_x3-albion-prelude steam_icon_201310 x3-albion-prelude
apps	xbox	brave-chcecgcbjkilfgeccdhoeaillkophnhg-Default brave-eelgndlbgohgbfkmhamljdkkdpejnemo-Default chrome-chcecgcbjkilfgeccdhoeaillkophnhg-Default chrome-eelgndlbgohgbfkmhamljdkkdpejnemo-Default xbox
apps	xcas	xcas
apps	xcl	xclicker xyz.xclicker.xclicker
apps	xcos	xcos
apps	xdm	xdman
apps	xe	Xfwm4CompositeEditor
apps	xemu	app.xemu.xemu xemu
apps	xeu	lutris_xcom-enemy-unknown steam_icon_200510 xcom-enemy-unknown
apps	xf	lutris_x4-foundations steam_icon_392160 x4-foundations
apps	xfe	xfe
apps	xhy	kali-hydra xhydra
apps	xia	AppImage appimagekit-AppImage application-x-iso9660-appimage
apps	xine	xine
apps	xkcd	com.github.rkoesters.xkcd-gtk
apps	xml	xmlcopyeditor
apps	xmn	net.xmind.XMind net.xmind.XMind8 xmind XMind
apps	xmp	xampp
apps	xmt	org.tuxfamily.XMoto xiaomitool xmoto
apps	xn	xenia
apps	xnc	com.xnview.XnConvert xnconvert
apps	xnr	com.xnview.XnRetro gxneur kdeneur xneur xnretro
apps	xns	com.xnview.XnSketch xnoise xnsketch xonsh
apps	xnt	lutris_xonotic org.xonotic.Xonotic xonotic
apps	xnv	appimagekit-xnviewmp com.xnview.XnViewMP xnview xnviewmp
apps	xorg	kcmx mate-panel-force-quit x xapp xdiagnose xorg
apps	xp	lutris_x-plane-11 steam_icon_269950 steam_icon_292180 x-plane
apps	xph	org.xiphos.Xiphos xiphos
apps	xpm	xt7-player-mpv
apps	xr	lutris_x-rebirth lutris_x3-reunion steam_icon_2810 steam_icon_2870 x-rebirth x3-reunion
apps	xrc	application-x-renderdoc-capture XRCed
apps	xsh	xash3d
apps	xt	lutris_x2-the-threat steam_icon_2800 x-tile x2-the-threat
apps	xtc	lutris_x3-terran-conflict steam_icon_2820 x3-terran-conflict
apps	xz	application-x-zerosize filetypes
apps	yad	yad
apps	yast	yast yast-control-center
apps	yb	ru.yandex.Browser yandex-browser yandex-browser-beta
apps	ybt	com.yubico.yubioath yubioath
apps	ycr	com.yacreader.YACReader YACReader
apps	yd	appimagekit-youtube-dl-gui com.github.JannikHv.Gydl gydl yandex-disk yd-128 youdao-dict youtube-dl youtube-dl-gui youtube-dl-qt-icon YouTubeDownloader
apps	ye	yuzu-ea
apps	yed	yed
apps	yf	your-freedom
apps	yh	kcmprocessor yast-hardware yast-hwinfo
apps	yio	org.flozz.yoga-image-optimizer
apps	ykd	yokadi
apps	yky	yakyak
apps	yl	YACReaderLibrary
apps	ym	app.ytmdesktop.ytmdesktop appimagekit-youtube-music-desktop-app yahoo-mail yandex-music yandexmusic youtube-music-desktop-app
apps	yms	com.yktoo.ymuse ymuse
apps	ynm	yubikey-neo-manager
apps	ypg	yubikey-personalization-gui
apps	ypm	yubikey-piv-manager
apps	yrc	yarock
apps	yrt	yaourtgui
apps	ys	deepin-clone mintbackup systemback yast-snapper
apps	ysh	com.github.lainsce.yishu yoshimi
apps	ytb	brave-agimnkijcaahngcdmfeangaknmldooml-Default chrome-agimnkijcaahngcdmfeangaknmldooml-Default smtube solstice-google-youtube youtube
apps	ytr	youtrack
apps	yuna	appimagekit-yuna yuna
apps	yuzu	appimagekit-yuzu org.yuzu_emu.yuzu yuzu
apps	yv	yast-vpn
apps	yvi	yast-vm-install
apps	yvm	yast-vm-migrate
apps	yvw	appimagekit-de.rwth_aachen.ient.YUView de.rwth_aachen.ient.YUView IENT-YUView-64
apps	yy	appimagekit-yaradio-yamusic yaradio-yamusic
apps	zap	fr.romainvigier.zap
apps	zart	zart
apps	zaz	io.sourceforge.zaz zaz
apps	zb2	steam_icon_61600 zen-bound-2
apps	zbs	zbstudio
apps	zc	zuluCrypt
apps	zdm	zdoom
apps	zeal	org.zealdocs.Zeal zeal
apps	zg	zerotier-gui
apps	zgr	lutris_ziggurat steam_icon_308420 zegrapher ZeGrapher ziggurat
apps	zim	org.zim_wiki.Zim
apps	zint	uk.org.zint.zint-qt zint
apps	zlp	org.zulip.Zulip zulip
apps	zm	appimagekit-zoho-mail-desktop zoho-mail-desktop zuluMount
apps	zmd	com.zamaudio.zamautosat com.zamaudio.zamaximx2 com.zamaudio.zamcomp com.zamaudio.zamcompx2 com.zamaudio.zamdelay com.zamaudio.zamdynamiceq com.zamaudio.zameq2 com.zamaudio.zamgate com.zamaudio.zamgatex2 com.zamaudio.zamgeq31 com.zamaudio.zamgrains com.zamaudio.zamheadx2 com.zamaudio.zamphono com.zamaudio.zamtube com.zamaudio.zamulticomp com.zamaudio.zamulticompx2 com.zamaudio.zamverb zumaudio
apps	zmn	appimagekit-zmninjapro zmninja zmninjapro
apps	zn	ZeroNet
apps	znb	zenbooru
apps	znd	com.zandronum.Zandronum zandronum
apps	znk	zenkit
apps	zns	zanshin
apps	zoom	us.zoom.Zoom Zoom zoom zoom-desktop zoom-icon
apps	zpr	kali-zaproxy org.zaproxy.ZAP zaproxy
apps	zps	lutris_zombie-panic-source steam_icon_17500 zombie-panic-source
apps	zpz	com.rtosta.zapzap
apps	zry	org.zrythm.Zrythm zrythm
apps	zsn	io.github.xyproto.zsnes zsnes
apps	ztr	org.zotero.Zotero zotero
apps	zvd	zevdocs
apps	zyn	zynaddsubfx
apps	zzz	hyprlock i3lock kscreensaver light-locker org.xfce.ScreenSaver preferences-desktop-screensaver screensaver slock swaylock system-lock-screen tdescreensaver xfce4-screensaver xfce4-system-lock xfsm-lock xscreensaver xsecurelock
apps	|>	appimagekit-smplayer celluloid clapper com.github.rafostar.Clapper com.stremio.Stremio deepin-media-player dragonplayer freetube freetube-bin gnome-mplayer gnome-mpv haruna info.smplayer.SMPlayer io.elementary.videos io.freetubeapp.FreeTube io.github.celluloid_player.Celluloid io.mpv.Mpv jellyfin-media-player kaffeine kodi mpc-qt mplayer mpv mpv-icon-8bit-64x64 multimedia-video-player org.gnome.Showtime org.gnome.Totem org.kde.dragonplayer org.kde.haruna org.kde.kaffeine org.videolan.VLC org.xfce.parole parole plex plex-desktop plex-media-player plexhometheater plexmediamanager plexmediaplayer plexmediaserver qmplay2 rosamp sc-apps-haruna showtime smartcode-stremio smplayer stremio totem tv.kodi.Kodi tv.plex.PlexDesktop video-player vlc xmms xplayer
apps	~$	about_kde alacarte alt-distro-logo altlinux applications-all applications-other arcolinux-hello classicmenu-indicator classicmenu-indicator-light configure-debian debian-logo debian-plymouth-manager debian-swirl deepin-deb-installer desktop-environment-kde desktop-environment-xfce distributor-logo distributor-logo-absolute distributor-logo-academix distributor-logo-aix distributor-logo-alpine distributor-logo-alt-linux distributor-logo-android distributor-logo-antix distributor-logo-archbang distributor-logo-archlabs distributor-logo-archlinux distributor-logo-archman distributor-logo-arcolinux distributor-logo-artix distributor-logo-aryalinux distributor-logo-backbox distributor-logo-blackarch distributor-logo-bodhi-linux distributor-logo-bunsenlabs distributor-logo-calculate-linux distributor-logo-condres distributor-logo-crux distributor-logo-debian distributor-logo-deepin distributor-logo-devuan distributor-logo-dragonflybsd distributor-logo-endeavouros distributor-logo-fedora distributor-logo-freebsd distributor-logo-freedos distributor-logo-ghostbsd distributor-logo-hyperbola distributor-logo-kali-linux distributor-logo-kaos distributor-logo-knoppix distributor-logo-korora distributor-logo-linux-lite distributor-logo-linux-mint distributor-logo-lubuntu distributor-logo-lxle distributor-logo-mac distributor-logo-madlinux distributor-logo-manjaro distributor-logo-midnightbsd distributor-logo-ms-dos distributor-logo-mx distributor-logo-netbsd distributor-logo-netrunner distributor-logo-nixos distributor-logo-openbsd distributor-logo-openmandriva distributor-logo-opensuse distributor-logo-parrot distributor-logo-pclinuxos distributor-logo-peppermint distributor-logo-pisilinux distributor-logo-pop-os distributor-logo-puppy-linux distributor-logo-pureos distributor-logo-q4os-m1 distributor-logo-q4os1 distributor-logo-raspbian distributor-logo-rhel distributor-logo-rosa distributor-logo-salentos distributor-logo-simply distributor-logo-smartos distributor-logo-solus distributor-logo-steamos distributor-logo-trueos distributor-logo-tuxedo-os distributor-logo-ubuntu distributor-logo-ubuntu-budgie distributor-logo-ubuntu-mate distributor-logo-ubuntu-studio distributor-logo-ultimate-edition distributor-logo-vanilla-os distributor-logo-void distributor-logo-voyager distributor-logo-windows distributor-logo-xubuntu distributor-logo-zorin drakmenustyle endeavouros endeavouros-icon fedora-release-notes gdeb gdebi gnome-applications gnome-debian gnome-gmenu gnome-menu gnome-settings-ui-behavior gtg io.github.paledega.alpine-rootfs io.github.vanilla-os.FirstSetup kali-panel-menu kalu kbox kde kde-logo kde-start-here kmenu kmenuedit kpk-desktop-xfce liteicon manjaro manjaro-welcome mate-panel-window-menu menu-editor mintsources-mint mintwelcome mozo mx-menu-editor nepomuk nix-snowflake org.debian.TuxPuck org.raspberrypi.rpi-imager org.xfce.about org.xfce.panel.applicationsmenu org.xfce.panel.launcher org.xfce.panel.whiskermenu page.codeberg.libre_menu_editor.LibreMenuEditor plasma plasma-start-here plasmashell pop-os pop-os-logo-icon pop_os preferences-desktop-plasma q4_findmenu q4oslogo redhat redhat-linux remote-raspberry rhel rpi rpi-imager sense_emu_gui start-here start-here-archlinux start-here-arcolinux start-here-debian start-here-fedora start-here-hyperbola start-here-kaos start-here-kde start-here-kde-plasma start-here-korora start-here-linux-mint start-here-lubuntu start-here-manjaro start-here-opensuse start-here-peppermint start-here-pop-os start-here-ubuntu start-here-xfce SUSEgreeter tuxpuck ubuntu-logo-icon ubuntu-mate uos-windesk view-app-grid xfce4-logo xfce4-menueditor xfce4-panel-menu xfce4-whiskermenu xfce4_xicon xfdesktop-menu yast-alternatives yast-release-notes yast-vendor
apps	~/	athena caja d3lphin dde-file-manager deepin-file-manager dolphin doublecmd file-manager io.elementary.files krusader nautilus nemo nnn org.gnome.Nautilus org.kde.dolphin org.kde.index org.kde.krusader org.xfce.filemanager org.xfce.thunar pcmanfm pcmanfm-qt ranger spacefm system-file-manager thunar Thunar xfce-filemanager yazi
places	rm	org.xfce.trash trashcan_empty trashcan_full user-trash user-trash-full
ICONS
}

tile=""
if [[ "$BG" != "none" || "$BORDER" != "none" ]]; then
  stroke=""
  [[ "$BORDER" != "none" ]] && stroke=" stroke=\"$BORDER\" stroke-width=\"1.5\""
  tile="<rect x=\"4\" y=\"4\" width=\"56\" height=\"56\" rx=\"12\" fill=\"$BG\"$stroke/>"
fi

previous="$(previous_theme)"
# Keep the remembered settings from an earlier install, replace the rest.
rm -rf "$THEME_DIR/scalable" "$THEME_DIR/index.theme" "$THEME_DIR/icon-theme.cache" \
  "$HOME/.icons/$THEME_NAME"
mkdir -p "$THEME_DIR/scalable/apps" "$THEME_DIR/scalable/places"
printf '%s\n' "$previous" > "$PREVIOUS_FILE"

cat > "$THEME_DIR/index.theme" <<THEME
[Icon Theme]
Name=$THEME_NAME
Comment=Monospace text icons
Inherits=Papirus-Dark,breeze-dark,Adwaita,hicolor
Directories=scalable/apps,scalable/places

[scalable/apps]
Size=64
MinSize=8
MaxSize=512
Context=Applications
Type=Scalable

[scalable/places]
Size=64
MinSize=8
MaxSize=512
Context=Places
Type=Scalable
THEME

# Lays the text out the same way for every icon: a font size by length,
# centered on the outline bounds, then one path per character.
count="$(awk -F '\t' -v dir="$THEME_DIR/scalable" -v fg="$FG" -v tile="$tile" \
    -v upm=1000 -v advance=600 '
  function num(v) {
    v = sprintf("%.3f", v)
    sub(/0+$/, "", v)
    sub(/\.$/, "", v)
    return v == "-0" ? "0" : v
  }
  BEGIN {
    for (i = 32; i < 127; i++) code[sprintf("%c", i)] = i
    split("30 30 24 18 15", size, " ")
  }
  FNR == NR { bounds[$1] = $2; outline[$1] = $3; next }
  {
    text = $2
    n = length(text)
    scale = size[n > 5 ? 5 : n] / upm
    first = 1
    for (i = 1; i <= n; i++) {
      c = code[substr(text, i, 1)]
      if (bounds[c] == "-") continue
      split(bounds[c], b, " ")
      x = (i - 1) * advance
      if (first || x + b[1] < x0) x0 = x + b[1]
      if (first || b[2] < y0) y0 = b[2]
      if (first || x + b[3] > x1) x1 = x + b[3]
      if (first || b[4] > y1) y1 = b[4]
      first = 0
    }
    cx = (x0 + x1) / 2
    cy = (y0 + y1) / 2
    paths = ""
    for (i = 1; i <= n; i++) {
      c = code[substr(text, i, 1)]
      if (outline[c] == "") continue
      paths = paths sprintf("<path transform=\"matrix(%s 0 0 %s %s %s)\" d=\"%s\"/>",
        num(scale), num(-scale), num(32 + ((i - 1) * advance - cx) * scale),
        num(32 + cy * scale), outline[c])
    }
    svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 64 64\">" tile \
      "<g fill=\"" fg "\">" paths "</g></svg>"
    split($3, names, " ")
    for (j in names) {
      file = dir "/" $1 "/" names[j] ".svg"
      print svg > file
      close(file)
      written++
    }
  }
  END { print written + 0 }
' <(glyphs) <(icons))"

if have gtk-update-icon-cache; then
  gtk-update-icon-cache -f -t "$THEME_DIR" >/dev/null 2>&1 || true
fi
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/icon-cache.kcache"

if (( apply )); then
  # XFCE only reloads icons when the theme name changes, so switch away and back.
  if [[ "$(backend)" == xfce && "$(get_theme)" == "$THEME_NAME" ]]; then
    set_theme "$previous"
    sleep 0.5
  fi
  set_theme "$THEME_NAME"
fi

echo "installed $count icons to $THEME_DIR (text $FG, tile $BG, border $BORDER)"
if (( ! apply )); then
  echo "select $THEME_NAME in your appearance settings to use it"
fi
