#!/usr/bin/env bash
# Enter a reproducible Nix development shell for macOS Flutter development.
#
# Usage:
#   ./scripts/shell-macos.sh              # uses flake.lock as-is
#   ./scripts/shell-macos.sh --pinned     # uses the locked flake inputs
#   ./scripts/shell-macos.sh --refresh    # updates flake inputs to latest, then enters shell
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
SDK_DIR="$PROJECT_ROOT/.flutter-sdk/flutter"

if [ ! -d "$SDK_DIR" ]; then
    echo "Flutter SDK not found. Run scripts/fetch-flutter.sh first."
    exit 1
fi

export PROJECT_ROOT

FLAKE_DIR="path:${NIX_FLAKE_DIR:-$PROJECT_ROOT/nix}"
NIX_ARGS=()

if [ "${1:-}" = "--pinned" ]; then
    echo "Using pinned nixpkgs from nix/flake.lock (reproducible)"
elif [ "${1:-}" = "--refresh" ]; then
    echo "Refreshing nixpkgs inputs to latest..."
    NIX_ARGS+=(--refresh)
else
    echo "Using nixpkgs from nix/flake.lock"
fi

exec nix develop ${NIX_ARGS[@]+"${NIX_ARGS[@]}"} "$FLAKE_DIR" --command bash --init-file <(cat <<INITEOF
export PATH="$SDK_DIR/bin:\$PATH"
export FLUTTER_ROOT="$SDK_DIR"
export PROJECT_ROOT="$PROJECT_ROOT"
echo "Ready. Flutter and macOS/iOS deps provided by Nix."
echo "Try: flutter doctor"
INITEOF
)
