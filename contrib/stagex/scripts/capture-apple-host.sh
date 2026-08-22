#!/usr/bin/env bash

set -euo pipefail

[ "$(uname -s)" = Darwin ] || {
  echo "Apple host capture requires macOS." >&2
  exit 69
}

printf 'architecture=%s\n' "$(uname -m)"
printf 'macos_version=%s\n' "$(sw_vers -productVersion)"
printf 'macos_build=%s\n' "$(sw_vers -buildVersion)"
xcodebuild -version | sed \
  -e 's/^Xcode /xcode_version=/' \
  -e 's/^Build version /xcode_build=/'
printf 'developer_dir=%s\n' "$(xcode-select -p)"
