#!/usr/bin/env bash

# Print the first value for a key in the main Desktop Entry group.
desktop_entry_value() {
  local key=$1
  local file=$2
  awk -v key="$key" '
    /^\[Desktop Entry\]$/ { in_entry = 1; next }
    /^\[/ { in_entry = 0 }
    in_entry && index($0, key "=") == 1 {
      sub("^" key "=", "")
      print
      exit
    }
  ' "$file"
}

require_tools() {
  local tool
  for tool in "$@"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      echo "required tool not found: $tool" >&2
      return 1
    fi
  done
}
