#!/usr/bin/env bash
# Replace the asset directory links created by link_assets.sh with real copies.
# With --clean it only removes them (links or copies) and copies nothing: link_assets.sh runs `rm -f`
# on each target, which cannot remove the real directories a previous run left behind.
# Needed where `mklink /D` is not allowed (e.g. the GitHub Actions windows-2022 runner user lacks
# SeCreateSymbolicLinkPrivilege), because Flutter's asset resolver cannot follow the broken reparse points.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
clean_only=0
[ "${1:-}" = "--clean" ] && clean_only=1
for dirname in default_themes icon lottie in_app_logo_icons svg; do
  target="assets/${dirname}"
  source="asset_sources/${dirname}/stack_wallet"
  if [ -e "$target" ] || [ -L "$target" ]; then
    cmd.exe /c rmdir "$(cygpath -w "$target")" 2>/dev/null || rm -rf "$target"
  fi
  [ "$clean_only" = "1" ] && continue
  mkdir -p "$target"
  cp -r "${source}/." "$target/"
done
