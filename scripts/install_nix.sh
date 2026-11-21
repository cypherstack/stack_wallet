#!/usr/bin/env bash

# Checks for Nix and installs it (multi-user daemon) when missing. Source builds
# require Nix (it supplies the dnix libraries and the toolchain), so this runs
# from `make bootstrap-macos` alongside the Xcode check. Nix is the only host
# dependency this script auto-installs: unlike Xcode (Apple's licensing forbids
# redistributing it) and unlike the app's own toolchain (pinned in the BOM),
# Nix is a general build tool with an official, signature-checked installer.
#
# Run directly (bash script.sh). On error this exits the shell; do not source.
if [[ -n "${ZSH_VERSION:-}" ]]; then
  if [[ "${ZSH_EVAL_CONTEXT:-}" == *file* ]]; then
    set -uo pipefail                           # sourced in zsh, don't -e
  else
    set -euo pipefail                          # executed in zsh
  fi
elif [[ -n "${BASH_VERSION:-}" ]]; then
  if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    set -uo pipefail                           # sourced in bash, don't -e
  else
    set -euo pipefail                          # executed in bash
  fi
else
  set -euo pipefail                            # unknown shell
fi
die() { echo "$@" >&2; exit 1; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  die "This installer is for macOS only."
fi

echo "Checking Nix..."

# A Nix binary on PATH (any install mode) is good enough to build; we do not
# force the daemon if the user already has a working Nix.
if command -v nix >/dev/null 2>&1; then
  echo "Nix already installed: $(command -v nix) ($(nix --version 2>/dev/null || echo 'version unknown'))"
  exit 0
fi

INSTALLER="${NIX_INSTALLER:-https://nixos.org/nix/install}"

echo "Nix not found on PATH. Installing the multi-user Nix (daemon) from ${INSTALLER}..."
echo "This downloads a shell script and runs it with sudo; it configures /nix/store and the nixbld users."
echo "The script is not pinned or checksum-verified here. Inspect it first, or install Nix yourself"
echo "(https://nixos.org/download/) and re-run."

# Never pipe a download into a root shell without an explicit yes.
# NIX_INSTALL_YES=1 skips the prompt for unattended use.
if [[ "${NIX_INSTALL_YES:-0}" != "1" ]]; then
  if ! read -r -p "Download and run the Nix installer now? (yes/no): " answer || [[ ! "$answer" =~ ^[Yy][Ee][Ss]$ ]]; then
    die "Aborted. Install Nix manually, then re-run."
  fi
fi

# `--daemon` is the recommended multi-user mode on macOS: it creates the build
# users and sets up launchd so `nix` works for every user. It prompts for sudo.
curl --proto '=https' --tlsv1.2 -fL "$INSTALLER" | sh -s -- --daemon

# The installer puts nix in ~/.nix-profile/bin, which most login shells source
# via .zshrc/.profile. Non-interactive shells (and `make` invoked from an IDE)
# won't have it on PATH until re-sourced or re-logged-in.
if ! command -v nix >/dev/null 2>&1; then
  echo "[WARN] Nix installed but not on PATH in this shell. Open a new terminal, or run:"
  echo "  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
fi

echo "[OK] Nix installed: $(command -v nix 2>/dev/null || echo 'see above')"
