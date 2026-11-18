#!/usr/bin/env bash
# Assemble a validated AppDir and Type 2 runtime into a gzip AppImage.
# Usage: appimage/assemble_appimage.sh <AppDir> <runtime> <output.AppImage> <version>
set -euo pipefail

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=appimage/lib.sh
source "$script_dir/lib.sh"

if [ $# -ne 4 ]; then
  echo "usage: $0 <AppDir> <runtime> <output.AppImage> <version>" >&2
  exit 1
fi

appdir=$1
runtime=$2
output=$3
version=$4
source_date_epoch=${SOURCE_DATE_EPOCH:-0}

if [ ! -d "$appdir" ] || [ -L "$appdir" ]; then
  echo "AppDir must be a directory, not a symbolic link: $appdir" >&2
  exit 1
fi
if [ ! -f "$runtime" ] || [ -L "$runtime" ]; then
  echo "runtime must be a regular file, not a symbolic link: $runtime" >&2
  exit 1
fi
case "$version" in
  ''|*[!A-Za-z0-9._+-]*)
    echo "version contains unsupported characters: $version" >&2
    exit 1
    ;;
esac
case "$source_date_epoch" in
  ''|*[!0-9]*)
    echo "SOURCE_DATE_EPOCH must be a non-negative integer: $source_date_epoch" >&2
    exit 1
    ;;
esac

require_tools appstreamcli basename chmod dd desktop-file-edit \
  desktop-file-validate dirname mkdir mksquashfs mktemp mv readlink realpath \
  rm wc

shopt -s nullglob
root_desktops=("$appdir"/*.desktop)
installed_desktops=("$appdir"/usr/share/applications/*.desktop)
metadata_files=("$appdir"/usr/share/metainfo/*.metainfo.xml)
shopt -u nullglob
if [ "${#root_desktops[@]}" -ne 1 ] ||
   [ "${#installed_desktops[@]}" -ne 1 ] ||
   [ "${#metadata_files[@]}" -ne 1 ]; then
  echo "AppDir must contain exactly one root desktop entry, installed desktop entry, and metainfo file" >&2
  exit 1
fi
if [ "${root_desktops[0]##*/}" != "${installed_desktops[0]##*/}" ]; then
  echo "root and installed desktop entry names must match" >&2
  exit 1
fi
desktop_files=("${root_desktops[0]}" "${installed_desktops[0]}")
for file in "${desktop_files[@]}" "${metadata_files[@]}"; do
  if [ ! -f "$file" ] || [ -L "$file" ]; then
    echo "required packaging metadata not found or is a symbolic link: $file" >&2
    exit 1
  fi
done

if [ ! -f "$appdir/AppRun" ] || [ -L "$appdir/AppRun" ] ||
   [ ! -x "$appdir/AppRun" ]; then
  echo "AppDir must contain an executable, non-symbolic AppRun" >&2
  exit 1
fi

icon_name=""
for desktop in "${desktop_files[@]}"; do
  desktop_icon=$(desktop_entry_value Icon "$desktop")
  if [ -z "$desktop_icon" ] || [ "$desktop_icon" != "${desktop_icon##*/}" ]; then
    echo "desktop entry must name a root icon: $desktop" >&2
    exit 1
  fi
  if [ -n "$icon_name" ] && [ "$desktop_icon" != "$icon_name" ]; then
    echo "root and installed desktop entries must name the same icon" >&2
    exit 1
  fi
  icon_name=$desktop_icon
done
root_icon="$appdir/$icon_name.png"
if [ ! -f "$root_icon" ] || [ -L "$root_icon" ]; then
  echo "desktop entry icon not found: $root_icon" >&2
  exit 1
fi
if [ ! -L "$appdir/.DirIcon" ] ||
   [ "$(readlink -- "$appdir/.DirIcon")" != "$icon_name.png" ]; then
  echo ".DirIcon must be a relative link to the desktop entry icon" >&2
  exit 1
fi

canonical_appdir=$(CDPATH='' cd -- "$appdir" && pwd -P)
output_dir=$(realpath -m -- "$(dirname -- "$output")")
output="$output_dir/$(basename -- "$output")"
case "$output" in
  "$canonical_appdir"|"$canonical_appdir"/*)
    echo "output must be outside the AppDir: $output" >&2
    exit 1
    ;;
esac
mkdir -p "$output_dir"
output_dir=$(CDPATH='' cd -- "$output_dir" && pwd -P)
output="$output_dir/$(basename -- "$output")"

for desktop in "${desktop_files[@]}"; do
  desktop-file-edit --set-key=X-AppImage-Version --set-value="$version" "$desktop"
  desktop-file-validate "$desktop"
done
for metadata in "${metadata_files[@]}"; do
  appstreamcli validate --no-net "$metadata"
done

workdir=$(mktemp -d "$output_dir/.appimage-assemble.XXXXXX")
cleanup() {
  rm -rf -- "$workdir"
}
trap cleanup EXIT
image="$workdir/output.AppImage"
runtime_size=$(wc -c < "$runtime")

# Write the SquashFS directly at the runtime boundary so the large application
# payload is not materialized as a second temporary file. mksquashfs truncates
# the destination, so restore the small runtime prefix afterward.
SOURCE_DATE_EPOCH="$source_date_epoch" \
  mksquashfs "$appdir" "$image" -offset "$runtime_size" \
    -all-root -noappend -no-xattrs -comp gzip >/dev/null
dd if="$runtime" of="$image" conv=notrunc status=none
chmod 0755 "$image"
mv -fT -- "$image" "$output"
