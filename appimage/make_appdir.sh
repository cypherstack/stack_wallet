#!/usr/bin/env bash
# Assemble an AppDir from a built Linux bundle.
# Usage: appimage/make_appdir.sh <stack_wallet|stack_duo|campfire> <bundle dir> <AppDir>
set -euo pipefail

if [ $# -ne 3 ]; then
  echo "usage: $0 <stack_wallet|stack_duo|campfire> <bundle dir> <AppDir>" >&2
  exit 1
fi

app=$1
bundle=$2
appdir=$3

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=appimage/lib.sh
source "$script_dir/lib.sh"
require_tools awk cp find install ln mkdir od stat tr
root=$(CDPATH='' cd -- "$script_dir/.." && pwd)
desktop=""
for candidate in "$root"/flatpak/*.desktop; do
  exec_line=$(desktop_entry_value Exec "$candidate")
  exec_command=${exec_line%%[[:space:]]*}
  if [ "$exec_command" = "$app" ]; then
    if [ -n "$desktop" ]; then
      echo "multiple desktop entries found for app: $app" >&2
      exit 1
    fi
    desktop=$candidate
  fi
done
if [ -z "$desktop" ]; then
  echo "unknown app: $app" >&2
  exit 1
fi
id=${desktop##*/}
id=${id%.desktop}
metainfo="$root/flatpak/$id.metainfo.xml"
icon="$root/asset_sources/icon/$app/icon.png"

if [ ! -d "$bundle" ]; then
  echo "bundle directory not found: $bundle" >&2
  exit 1
fi
if [ ! -e "$bundle/$app" ]; then
  echo "bundle executable not found: $bundle/$app" >&2
  exit 1
fi
if [ ! -f "$bundle/$app" ] || [ -L "$bundle/$app" ] ||
   [ ! -x "$bundle/$app" ]; then
  echo "bundle executable must be an executable regular file, not a symbolic link: $bundle/$app" >&2
  exit 1
fi
for reserved in usr AppRun .DirIcon "$id.desktop" "$id.png"; do
  if [ -e "$bundle/$reserved" ] || [ -L "$bundle/$reserved" ]; then
    echo "bundle contains reserved packaging path: $bundle/$reserved" >&2
    exit 1
  fi
done
extra_desktop=$(find "$bundle" -mindepth 1 -maxdepth 1 -name '*.desktop' \
  -print -quit)
if [ -n "$extra_desktop" ]; then
  echo "bundle contains reserved packaging path: $extra_desktop" >&2
  exit 1
fi
if [ -L "$appdir" ]; then
  echo "AppDir must not be a symbolic link: $appdir" >&2
  exit 1
fi
if [ -e "$appdir" ]; then
  if [ ! -d "$appdir" ]; then
    echo "AppDir is not a directory: $appdir" >&2
    exit 1
  fi
  if [ -n "$(find "$appdir" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
    echo "AppDir is not empty: $appdir" >&2
    exit 1
  fi
fi

# The hicolor directory must agree with the actual source icon. Validate the
# PNG signature before reading its big-endian IHDR width and height.
if [ ! -f "$icon" ] || [ ! -r "$icon" ]; then
  echo "icon is not a readable regular file: $icon" >&2
  exit 1
fi
signature=$(od -An -N8 -tx1 "$icon" 2>/dev/null | tr -d ' \n')
width_hex=$(od -An -j16 -N4 -tx1 "$icon" 2>/dev/null | tr -d ' \n')
height_hex=$(od -An -j20 -N4 -tx1 "$icon" 2>/dev/null | tr -d ' \n')
if [ "$signature" != "89504e470d0a1a0a" ] ||
   [ "${#width_hex}" -ne 8 ] || [ "${#height_hex}" -ne 8 ]; then
  echo "$icon is invalid, expected a 512x512 PNG" >&2
  exit 1
fi
width=$((16#$width_hex))
height=$((16#$height_hex))
if [ "$width" -ne 512 ] || [ "$height" -ne 512 ]; then
  echo "$icon is ${width}x${height}, expected a 512x512 PNG" >&2
  exit 1
fi

mkdir -p "$appdir"
if [ "$(stat -c %d -- "$bundle")" = "$(stat -c %d -- "$appdir")" ]; then
  cp -al "$bundle"/. "$appdir"/
else
  cp -a --reflink=auto "$bundle"/. "$appdir"/
fi
install -m755 "$root/appimage/$app/AppRun" "$appdir/AppRun"
install -m644 "$desktop" "$appdir/$id.desktop"

# The AppImage runtime uses the root icon, while file managers and integrators
# such as Gear Lever and AppImageLauncher read .DirIcon.
install -m644 "$icon" "$appdir/$id.png"
ln -sfn "$id.png" "$appdir/.DirIcon"

# Standard AppDir locations, also read by integrators.
install -Dm644 "$icon" \
  "$appdir/usr/share/icons/hicolor/${width}x${width}/apps/$id.png"
install -Dm644 "$desktop" \
  "$appdir/usr/share/applications/$id.desktop"
install -Dm644 "$metainfo" \
  "$appdir/usr/share/metainfo/$id.metainfo.xml"
