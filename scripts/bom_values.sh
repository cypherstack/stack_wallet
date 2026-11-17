#!/usr/bin/env bash
# Read one toolchain pin from stack-bom.toml.
#
#   scripts/bom_values.sh --get rust
#   scripts/bom_values.sh --get rust FILE
set -euo pipefail

BOM="${BOM_FILE:-stack-bom.toml}"

section_for() {
  case "$1" in
    rust|dnssec_rust|flutter|flutter_min|go|go_min) echo toolchain ;;
    xcode) echo macos ;;
    *) echo "Unknown BOM key: $1" >&2; return 2 ;;
  esac
}

value() {
  local key="$1" section result
  section="$(section_for "$key")" || exit 2
  result="$(
    sed -n "/^\[$section\]/,/^\[/p" "$BOM" |
      sed -n "s/^${key}[[:space:]]*=[[:space:]]*\"\([^\"]*\)\".*/\1/p" |
      head -n1
  )"
  [ -n "$result" ] || {
    echo "Missing [$section] $key in $BOM" >&2
    return 1
  }
  printf '%s\n' "$result"
}

[ "${1:-}" = "--get" ] || {
  echo "Usage: $0 --get <key> [bom]" >&2
  exit 2
}
[ "$#" -ge 2 ] || {
  echo "Usage: $0 --get <key> [bom]" >&2
  exit 2
}
[ "$#" -ge 3 ] && BOM="$3"
[ -r "$BOM" ] || {
  echo "Cannot read $BOM" >&2
  exit 1
}

value "$2"
