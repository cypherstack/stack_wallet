#!/usr/bin/env bash

# Checks for full Xcode.app and points xcode-select at it. This is split out
# from install_macos_build_tools.sh because Xcode acquisition is orthogonal to
# whether the rest of the toolchain comes from Homebrew or Nix: neither can
# provide Xcode itself (Apple's license forbids redistributing it), so this
# script must run for both kinds of setups, not just the Homebrew one.
#
# Xcode itself is never auto-installed here: Apple's own download tooling
# (the `xcodes` CLI, `mas`) has proven unreliable in practice -- both hit
# hard failures (a broken Apple API returning 404 regardless of version, and
# `mas install` requiring an interactive sudo TTY) that still ended up
# needing a manual download anyway. Fail with clear instructions instead.
#
# Safe to source (source script.sh) or execute directly (./script.sh)
if [ -n "${ZSH_VERSION:-}" ]; then
  if [[ "${ZSH_EVAL_CONTEXT:-}" == *file* ]]; then
    set -uo pipefail                           # sourced in zsh, don't -e
  else
    set -euo pipefail                          # executed in zsh
  fi
elif [ -n "${BASH_VERSION:-}" ]; then
  if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    set -uo pipefail                           # sourced in bash, don't -e
  else
    set -euo pipefail                          # executed in bash
  fi
else
  set -euo pipefail                            # unknown shell
fi
die() { echo "$@" >&2; return 1 2>/dev/null || exit 1; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  die "This installer is for macOS only."
fi

echo "Checking Xcode..."

XCODE_APP="$(ls -d /Applications/Xcode*.app 2>/dev/null | head -1 || true)"

if [[ -z "$XCODE_APP" ]]; then
  die "[ERROR] Full Xcode is required for macOS/iOS builds (Command Line Tools alone are not enough). Install it, then re-run this script:
  - Mac App Store: search 'Xcode' and install, or run 'mas install 497799835' if you already have 'mas' set up
  - Or download the .xip directly from https://developer.apple.com/download/all/?q=xcode"
fi

if ! xcode-select -p >/dev/null 2>&1 || [[ "$(xcode-select -p)" != *"/Xcode.app"* ]]; then
  echo "Xcode.app found at $XCODE_APP. Setting xcode-select path..."
  sudo xcode-select -s "$XCODE_APP/Contents/Developer"
else
  echo "Xcode.app already configured."
fi

sudo xcodebuild -license accept 2>/dev/null || true
sudo xcodebuild -runFirstLaunch 2>/dev/null || true
