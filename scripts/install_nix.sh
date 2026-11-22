#!/usr/bin/env bash

# Checks for Nix and installs it when missing, on macOS and on Linux. Every build
# needs Nix (the flake is the toolchain), so this runs from `make bootstrap-nix`
# and, on a Mac, from `make bootstrap-macos` alongside the Xcode check. Nix is the
# only host dependency this script installs itself: Xcode cannot be redistributed
# (Apple's licence), and the rest of the toolchain comes from the flake. The
# installer is downloaded and run as root, so the script asks first; it does not
# pin or checksum the installer script.
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

# macOS and Linux (Ubuntu, Debian, Fedora, ...). The multi-user installer needs
# systemd on Linux; without it (containers, WSL1) fall back to a single-user install.
case "$(uname -s)" in
  Darwin) INSTALL_MODE=--daemon ;;
  Linux)
    if [ -d /run/systemd/system ]; then INSTALL_MODE=--daemon; else INSTALL_MODE=--no-daemon; fi
    ;;
  *) die "This installer supports macOS and Linux only." ;;
esac

echo "Checking Nix..."

# A Nix binary on PATH (any install mode) is good enough to build; we do not
# force the daemon if the user already has a working Nix.
if command -v nix >/dev/null 2>&1; then
  echo "Nix already installed: $(command -v nix) ($(nix --version 2>/dev/null || echo 'version unknown'))"
  exit 0
fi

INSTALLER="${NIX_INSTALLER:-https://nixos.org/nix/install}"

echo "Nix not found on PATH. Installing Nix (${INSTALL_MODE#--}) from ${INSTALLER}..."
echo "This downloads a shell script and runs it with sudo; it creates /nix and, for a multi-user install, the nixbld users."
echo "The script is not pinned or checksum-verified here. Inspect it first, or install Nix yourself"
echo "(https://nixos.org/download/) and re-run."

# Never pipe a download into a root shell without an explicit yes.
# NIX_INSTALL_YES=1 skips the prompt for unattended use.
if [[ "${NIX_INSTALL_YES:-0}" != "1" ]]; then
  if ! read -r -p "Download and run the Nix installer now? (yes/no): " answer || [[ ! "$answer" =~ ^[Yy][Ee][Ss]$ ]]; then
    die "Aborted. Install Nix manually, then re-run."
  fi
fi

# `--daemon` is the recommended multi-user mode: it creates the build users and sets up
# launchd/systemd so `nix` works for every user. The flake needs the nix-command and flakes
# features; enable them in the installed nix.conf so `direnv`'s `use flake` works too.
# --yes: we asked above, do not ask again.
conf="$(mktemp "${TMPDIR:-/tmp}/nix-extra-conf.XXXXXX")"
trap 'rm -f "$conf"' EXIT
echo "experimental-features = nix-command flakes" > "$conf"
curl --proto '=https' --tlsv1.2 -fL "$INSTALLER" | sh -s -- "$INSTALL_MODE" --yes --nix-extra-conf-file "$conf"

# The installer puts nix in ~/.nix-profile/bin, which most login shells source
# via .zshrc/.profile. Non-interactive shells (and `make` invoked from an IDE)
# won't have it on PATH until re-sourced or re-logged-in.
if ! command -v nix >/dev/null 2>&1; then
  echo "[WARN] Nix installed but not on PATH in this shell. Open a new terminal, or run:"
  echo "  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh   (single-user: . ~/.nix-profile/etc/profile.d/nix.sh)"
fi

echo "[OK] Nix installed: $(command -v nix 2>/dev/null || echo 'see above')"
