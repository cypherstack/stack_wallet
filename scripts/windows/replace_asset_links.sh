#!/usr/bin/env bash
# Replace the asset directory links created by link_assets.sh with real copies.
# Needed where `mklink /D` is not allowed (e.g. the GitHub Actions windows-2022 runner user lacks
# SeCreateSymbolicLinkPrivilege), because Flutter's asset resolver cannot follow the broken reparse points.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
for dirname in default_themes icon lottie in_app_logo_icons svg; do
  target="assets/${dirname}"
  source="asset_sources/${dirname}/stack_wallet"
  if [ -e "$target" ] || [ -L "$target" ]; then
    cmd.exe /c rmdir "$(cygpath -w "$target")" 2>/dev/null || rm -rf "$target"
  fi
  mkdir -p "$target"
  cp -r "${source}/." "$target/"
done
