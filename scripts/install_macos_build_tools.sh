#!/usr/bin/env bash

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

# Homebrew may not be in PATH after a fresh install
if ! command -v brew >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    else
      die "Homebrew installation failed. Install manually: https://brew.sh"
    fi
  fi
fi

# rustup is keg-only in Homebrew (conflicts with rust), so it has to be added to PATH by hand.
# Called again after `brew install`: on a first install the directory does not exist before it.
add_rustup_to_path() {
  local prefix
  prefix="$(brew --prefix rustup 2>/dev/null || true)"
  [[ -n "$prefix" && -d "$prefix/bin" && ":$PATH:" != *":$prefix/bin:"* ]] && export PATH="$prefix/bin:$PATH"
  return 0
}
add_rustup_to_path

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
bash "$SCRIPT_DIR/install_xcode.sh"

echo "Installing Homebrew packages..."
# Do not upgrade formulae that are already installed: a build machine keeps the versions it was set up with.
export HOMEBREW_NO_INSTALL_UPGRADE=1
brew install direnv rustup cmake meson ninja pkg-config gnu-sed cocoapods go protobuf cbindgen autoconf automake libtool sccache
add_rustup_to_path

# Only used for the benchmark reports in bm/. A failure here (for example a link conflict with a
# copy installed another way) must not stop the toolchain setup.
brew install pandoc weasyprint toilet figlet || echo "[WARN] optional report tools were not fully installed; only bm/ report rendering needs them."

# The Homebrew cask always installs the latest Flutter, but the app is built
# and tested against one pinned release. Install that tag from source instead.
FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.4}"
FLUTTER_DIR="${FLUTTER_DIR:-$HOME/development/flutter}"

flutter_installed_version() {
  "$1" --version --machine 2>/dev/null | sed -n 's/.*"frameworkVersion": *"\([^"]*\)".*/\1/p' | head -n 1
}

FLUTTER_BIN="$(command -v flutter 2>/dev/null || true)"
[[ -z "$FLUTTER_BIN" && -x "$FLUTTER_DIR/bin/flutter" ]] && FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"
CURRENT_FLUTTER=""
[[ -n "$FLUTTER_BIN" ]] && CURRENT_FLUTTER="$(flutter_installed_version "$FLUTTER_BIN")"

if [[ "$CURRENT_FLUTTER" == "$FLUTTER_VERSION" ]]; then
  echo "Flutter $FLUTTER_VERSION already installed ($FLUTTER_BIN)."
else
  [[ -n "$CURRENT_FLUTTER" ]] && echo "Found Flutter $CURRENT_FLUTTER at $FLUTTER_BIN, need $FLUTTER_VERSION."
  if [[ -d "$FLUTTER_DIR/.git" ]]; then
    echo "Switching $FLUTTER_DIR to Flutter $FLUTTER_VERSION..."
    git -C "$FLUTTER_DIR" fetch --tags origin
    git -C "$FLUTTER_DIR" checkout "$FLUTTER_VERSION"
  elif [[ -e "$FLUTTER_DIR" ]]; then
    die "$FLUTTER_DIR exists but is not a Flutter git checkout. Move it away or set FLUTTER_DIR."
  else
    echo "Cloning Flutter $FLUTTER_VERSION into $FLUTTER_DIR..."
    mkdir -p "$(dirname "$FLUTTER_DIR")"
    git clone --branch "$FLUTTER_VERSION" --depth 1 https://github.com/flutter/flutter.git "$FLUTTER_DIR"
  fi
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

if ! command -v rustup >/dev/null 2>&1; then
  die "rustup not found in PATH. Check brew install."
fi

echo "Ensuring Rust 1.99.1 toolchain..."
rustup toolchain install 1.99.1
rustup default 1.99.1
rustup target add aarch64-apple-darwin x86_64-apple-darwin aarch64-apple-ios --toolchain 1.99.1 >/dev/null 2>&1 || true

# Homebrew's rustup formula is keg-only and does not necessarily create the
# cargo/rustc shims in ~/.cargo/bin — `rustup toolchain install` alone may leave
# that directory absent, which means no `cargo` on PATH in this shell or any
# future one. Create the shims via rustup-init when they are missing.
if [ ! -x "$HOME/.cargo/bin/cargo" ]; then
  echo "cargo shims missing in ~/.cargo/bin; creating them via rustup-init..."
  if command -v rustup-init >/dev/null 2>&1; then
    rustup-init -y --no-modify-path --default-toolchain 1.99.1 || true
  else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --no-modify-path --default-toolchain 1.99.1 || true
  fi
fi

# cargo/rustc live in ~/.cargo/bin after rustup installs a toolchain
export PATH="$HOME/.cargo/bin:$PATH"
source "$HOME/.cargo/env" 2>/dev/null || true

if ! command -v cargo >/dev/null 2>&1; then
  die "cargo still not on PATH after rustup setup. Run 'rustup-init -y' manually, then re-run this script."
fi

echo "Verifying toolchain..."
if command -v flutter >/dev/null 2>&1; then
  flutter --version
else
  echo "flutter not found in PATH. Add $FLUTTER_DIR/bin to your shell profile."
fi

if command -v dart >/dev/null 2>&1; then
  dart --version
else
  echo "dart not found in PATH. It should come with Flutter."
fi

rustup --version
rustc --version
rustup run 1.99.1 rustc --version
pod --version
go version
autoreconf --version | head -n 1 || true
aclocal --version | head -n 1 || true

echo ""
echo "Done."

# Persist PATH entries for future terminals. Create ~/.zshrc when missing: a
# vanilla macOS install ships without one, and this block used to skip silently
# in that case — leaving new shells unable to find cargo/rustup and
# making `source`ing this script the only way to get a usable environment.
ZSHRC="$HOME/.zshrc"
if [ ! -f "$ZSHRC" ]; then
  touch "$ZSHRC"
  echo "→ Created $ZSHRC (macOS ships without one)"
fi
grep -qF 'brew shellenv' "$ZSHRC" 2>/dev/null || \
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$ZSHRC"
grep -qF "$FLUTTER_DIR/bin" "$ZSHRC" 2>/dev/null || \
  echo "export PATH=\"$FLUTTER_DIR/bin:\$PATH\"" >> "$ZSHRC"
grep -qF '$HOME/.cargo/bin' "$ZSHRC" 2>/dev/null || \
  echo 'export PATH="/opt/homebrew/opt/rustup/bin:$HOME/.cargo/bin:$PATH"' >> "$ZSHRC"
echo "→ PATH entries ensured in $ZSHRC"
echo "  Open a new terminal (or run: source $ZSHRC) before 'make build-macos'."
