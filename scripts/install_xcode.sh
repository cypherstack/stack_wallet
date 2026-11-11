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

# Any full Xcode that is already selected stays selected, whatever its file name (Xcode.app,
# Xcode_27.1.app, Xcode-beta.app, ...) and wherever it lives. Only an unusable selection (none, or
# the Command Line Tools) is replaced by an Xcode found in $XCODE_APPS_DIR.
XCODE_APPS_DIR="${XCODE_APPS_DIR:-/Applications}"
SELECTED_DEV="$(xcode-select -p 2>/dev/null || true)"

if [[ "$SELECTED_DEV" == /*.app/Contents/Developer && -x "$SELECTED_DEV/usr/bin/xcodebuild" ]]; then
  echo "Xcode already configured: ${SELECTED_DEV%/Contents/Developer}"
else
  if [[ -n "${XCODE_APP:-}" ]]; then
    if [[ ! -x "$XCODE_APP/Contents/Developer/usr/bin/xcodebuild" ]]; then
      die "[ERROR] XCODE_APP is not a full Xcode.app: $XCODE_APP"
    fi
  elif [[ -d "$XCODE_APPS_DIR/Xcode.app" ]]; then
    XCODE_APP="$XCODE_APPS_DIR/Xcode.app"
  else
    # Prefer the newest versioned install; alphabetically Xcode_16.2.app comes
    # before Xcode_27.1.app, and Xcodes.app is not Xcode.
    XCODE_APP="$(find "$XCODE_APPS_DIR" -maxdepth 1 -type d -name 'Xcode*.app' ! -name 'Xcodes.app' -print 2>/dev/null | sort -V | tail -n 1 || true)"
  fi
  if [[ -z "$XCODE_APP" ]]; then
    die "[ERROR] Full Xcode is required for macOS/iOS builds (Command Line Tools alone are not enough). Install it, then re-run this script:
  - Mac App Store: search 'Xcode' and install, or run 'mas install 497799835' if you already have 'mas' set up
  - Or download the .xip directly from https://developer.apple.com/download/all/?q=xcode"
  fi
  echo "Xcode found at $XCODE_APP. Setting xcode-select path..."
  sudo xcode-select -s "$XCODE_APP/Contents/Developer"
fi

# Only ask for sudo when the license or first-launch setup is actually pending;
# an already-configured Xcode should not trigger these on every bootstrap run.
if ! xcodebuild -license check >/dev/null 2>&1; then
  echo "Accepting the Xcode license..."
  sudo xcodebuild -license accept
fi
if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
  echo "Running Xcode first-launch setup..."
  sudo xcodebuild -runFirstLaunch
fi
