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
  # These values are passed to toolchain actions in the release workflow.
  # Reject anything that is not a plain version so a data-file edit cannot
  # inject a branch, a range or shell syntax.
  if [[ ! "$result" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]]; then
    echo "Invalid [$section] $key value '$result' in $BOM (expected x.y or x.y.z)" >&2
    return 1
  fi
  printf '%s\n' "$result"
}

check_all() {
  local key
  for key in rust dnssec_rust flutter flutter_min go go_min xcode; do
    value "$key" >/dev/null
  done
  echo "BOM values OK"
}

usage() {
  echo "Usage: $0 --get <key> [bom]" >&2
  echo "       $0 --check [bom]" >&2
  exit 2
}

case "${1:-}" in
  --check)
    if [ "$#" -ge 2 ]; then BOM="$2"; fi
    ;;
  --get)
    if [ "$#" -lt 2 ]; then usage; fi
    if [ "$#" -ge 3 ]; then BOM="$3"; fi
    ;;
  *)
    usage
    ;;
esac

[ -r "$BOM" ] || {
  echo "Cannot read $BOM" >&2
  exit 1
}

if [ "$1" = "--check" ]; then
  check_all
  exit 0
fi
value "$2"
