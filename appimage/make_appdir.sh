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

case "$app" in
  stack_wallet) id=com.cypherstack.stackwallet ;;
  stack_duo) id=com.cypherstack.stackduo ;;
  campfire) id=com.cypherstack.campfire ;;
  *) echo "unknown app: $app" >&2; exit 1 ;;
esac

root=$(cd "$(dirname "$0")/.." && pwd)
icon="$root/asset_sources/icon/$app/icon.png"

# hicolor directories are named after the icon size, so read it from the
# PNG header (width and height are big-endian at bytes 16 and 20).
width=$((16#$(od -An -j16 -N4 -tx1 "$icon" | tr -d ' \n')))
height=$((16#$(od -An -j20 -N4 -tx1 "$icon" | tr -d ' \n')))
if [ "$width" -ne "$height" ]; then
  echo "$icon is ${width}x${height}, expected a square icon" >&2
  exit 1
fi

mkdir -p "$appdir"
cp -r "$bundle"/. "$appdir"/
install -m755 "$root/appimage/$app/AppRun" "$appdir/AppRun"
install -m644 "$root/appimage/$app/$id.desktop" "$appdir/$id.desktop"

# appimagetool embeds the icon named by Icon= from the AppDir root. File
# managers and integrators (Gear Lever, AppImageLauncher) read .DirIcon.
install -m644 "$icon" "$appdir/$id.png"
ln -sfn "$id.png" "$appdir/.DirIcon"

# Standard AppDir locations, also read by integrators.
install -Dm644 "$icon" \
  "$appdir/usr/share/icons/hicolor/${width}x${width}/apps/$id.png"
install -Dm644 "$root/appimage/$app/$id.desktop" \
  "$appdir/usr/share/applications/$id.desktop"
# No usr/share/metainfo: appimagetool would validate it with appstreamcli,
# which fetches every <url> and fails the build when one is unreachable.
