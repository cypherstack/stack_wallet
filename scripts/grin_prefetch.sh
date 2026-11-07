#!/usr/bin/env bash
set -euo pipefail

# Fills the cargo git cache with the crates grin_native's build hook needs.
#
# The hook runs cargo without the ssh agent, so it cannot fetch the private
# grin-wallet fork itself. Run this once after `flutter pub get`, and again
# whenever the grin_native ref changes, from a shell that can reach
# git.cypherstack.com. CARGO_HOME must match what the hook sees, which is
# $HOME/.cargo unless you set it here.
#
# Usage: bash scripts/grin_prefetch.sh

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

config=".dart_tool/package_config.json"
if [[ ! -f "$config" ]]; then
  printf '%s not found. Run flutter pub get first.\n' "$config" >&2
  exit 1
fi

package_root="$(
  python3 - "$config" <<'PY'
import json, sys
from pathlib import Path
from urllib.parse import urlparse, unquote

config = Path(sys.argv[1]).resolve()
for package in json.loads(config.read_text())["packages"]:
    if package["name"] != "grin_native":
        continue
    uri = package["rootUri"]
    if uri.startswith("file:"):
        print(Path(unquote(urlparse(uri).path)))
    else:
        print((config.parent / uri).resolve())
    break
PY
)"

if [[ -z "$package_root" ]]; then
  printf 'grin_native is not a dependency. Configure the app with GRIN enabled.\n' >&2
  exit 1
fi

manifest="$package_root/rust/Cargo.toml"
if [[ ! -f "$manifest" ]]; then
  printf 'No Cargo.toml at %s\n' "$manifest" >&2
  exit 1
fi

export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export CARGO_NET_GIT_FETCH_WITH_CLI=true
printf 'Fetching crates for %s into %s\n' "$manifest" "$CARGO_HOME"
cargo fetch --locked --manifest-path "$manifest"
