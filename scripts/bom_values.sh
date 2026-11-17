#!/usr/bin/env bash
# Read toolchain pins from stack-bom.toml.
#
#   scripts/bom_values.sh                    # print quoted shell assignments
#   scripts/bom_values.sh --get rust         # print one value
#   scripts/bom_values.sh --get rust FILE    # read another BOM
#
# The default output is safe to eval; the individual lookups are preferred by
# the Makefile and CI so a value can never become shell syntax.
set -euo pipefail

BOM="${BOM_FILE:-stack-bom.toml}"

section_for() {
  case "$1" in
    rust|dnssec_rust|flutter|flutter_min|go|go_min) echo toolchain ;;
    xcode|xcode_build|xcode_xip_sha1) echo macos ;;
    *) echo "Unknown BOM key: $1" >&2; return 2 ;;
  esac
}

value() {
  local key="$1" section result
  section="$(section_for "$key")" || exit 2
  result="$(
    sed -n "/^\[$section\]/,/^\[/p" "$BOM" |
      sed -n "s/^$key[[:space:]]*=[[:space:]]*\"\([^\"]*\)\".*/\1/p" |
      head -n1
  )"
  [ -n "$result" ] || {
    echo "Missing [$section] $key in $BOM" >&2
    return 1
  }
  printf '%s\n' "$result"
}

if [ "${1:-}" = "--get" ]; then
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
  exit
fi

[ "$#" -ge 1 ] && BOM="$1"
[ -r "$BOM" ] || {
  echo "Cannot read $BOM" >&2
  exit 1
}

FLUTTER_VERSION="$(value flutter)"
FLUTTER_MIN="$(value flutter_min)"
RUST_VERSION="$(value rust)"
DNSSEC_RUST="$(value dnssec_rust)"
GO_VERSION="$(value go)"
GO_MIN="$(value go_min)"

printf 'FLUTTER_VERSION=%q\nFLUTTER_MIN=%q\nRUST_VERSION=%q\nDNSSEC_RUST=%q\nGO_VERSION=%q\nGO_MIN=%q\n' \
  "$FLUTTER_VERSION" "$FLUTTER_MIN" "$RUST_VERSION" "$DNSSEC_RUST" "$GO_VERSION" "$GO_MIN"
