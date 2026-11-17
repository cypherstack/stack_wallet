#!/usr/bin/env bash
# Print the toolchain pins from stack-bom.toml as shell assignments.
# Usage: eval "$(scripts/bom_values.sh)" or source scripts/bom_values.sh
set -euo pipefail

BOM="${1:-stack-bom.toml}"

value() {
  sed -n "s/^$1[[:space:]]*=[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$BOM" | head -n1
}

FLUTTER_VERSION="$(value flutter_min)"
RUST_VERSION="$(value rust)"
GO_VERSION="$(value go_min)"

[ -n "$FLUTTER_VERSION" ] || { echo "Missing flutter_min in $BOM" >&2; exit 1; }
[ -n "$RUST_VERSION" ] || { echo "Missing rust in $BOM" >&2; exit 1; }
[ -n "$GO_VERSION" ] || { echo "Missing go_min in $BOM" >&2; exit 1; }

printf 'FLUTTER_VERSION=%s\nRUST_VERSION=%s\nGO_VERSION=%s\n' \
  "$FLUTTER_VERSION" "$RUST_VERSION" "$GO_VERSION"
