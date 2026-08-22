#!/usr/bin/env bash

set -euo pipefail

STAGEX_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGEX_PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$STAGEX_SCRIPT_DIR/../../.." && pwd)}"

source "$STAGEX_PROJECT_ROOT/flutter_version.env"

require_docker() {
  command -v docker >/dev/null || {
    echo "Docker is required." >&2
    exit 69
  }
  local version major
  version="$(docker version --format '{{.Server.Version}}' 2>/dev/null)" || {
    echo "The Docker daemon is unavailable." >&2
    exit 69
  }
  major="${version%%.*}"
  [[ "$major" =~ ^[0-9]+$ ]] && [ "$major" -ge 25 ] || {
    echo "Docker 25 or newer is required; found $version." >&2
    exit 69
  }
}

flutter_checksum() {
  case "$1:$2" in
    linux:x64) printf '%s' "$FLUTTER_SHA256_LINUX_X64" ;;
    macos:x64) printf '%s' "$FLUTTER_SHA256_X64" ;;
    macos:arm64) printf '%s' "$FLUTTER_SHA256_ARM64" ;;
    *) return 1 ;;
  esac
}

flutter_marker() {
  local os="$1"
  local arch="$2"
  local checksum
  checksum="$(flutter_checksum "$os" "$arch")" || return 1
  printf '{"schema":1,"os":"%s","arch":"%s","version":"%s","channel":"%s","archive_sha256":"%s"}' \
    "$os" "$arch" "$FLUTTER_VERSION" "$FLUTTER_CHANNEL" "$checksum"
}

require_verified_flutter() {
  local os="$1"
  local arch="$2"
  local sdk="$STAGEX_PROJECT_ROOT/.flutter-sdk/flutter"
  local marker="$sdk/.stagex-verified.json"
  [ -x "$sdk/bin/flutter" ] && [ -f "$marker" ] &&
    [ "$(cat "$marker")" = "$(flutter_marker "$os" "$arch")" ] || {
      echo "The checksum-verified Flutter SDK is missing or stale." >&2
      exit 78
    }
}

prepare_flutter_state() {
  STAGEX_FLUTTER_STATE="$(mktemp -d "${TMPDIR:-/tmp}/stack-stagex-flutter.XXXXXX")"
  STAGEX_FLUTTER_CACHE="$STAGEX_FLUTTER_STATE/cache"
  STAGEX_FLUTTER_TOOLS="$STAGEX_FLUTTER_STATE/flutter_tools"
  mkdir -p "$STAGEX_FLUTTER_CACHE" "$STAGEX_FLUTTER_TOOLS"
  cp -a --reflink=auto \
    "$STAGEX_PROJECT_ROOT/.flutter-sdk/flutter/bin/cache/." \
    "$STAGEX_FLUTTER_CACHE/"
  cp -a --reflink=auto \
    "$STAGEX_PROJECT_ROOT/.flutter-sdk/flutter/packages/flutter_tools/." \
    "$STAGEX_FLUTTER_TOOLS/"
  export STAGEX_FLUTTER_STATE STAGEX_FLUTTER_CACHE STAGEX_FLUTTER_TOOLS
}

remove_flutter_state() {
  [ -z "${STAGEX_FLUTTER_STATE:-}" ] ||
    [ ! -d "$STAGEX_FLUTTER_STATE" ] ||
    rm -rf -- "$STAGEX_FLUTTER_STATE"
  remove_transient_flutter_metadata
}

remove_transient_flutter_metadata() {
  rm -rf -- "$STAGEX_PROJECT_ROOT/.dart_tool"
  rm -f -- "$STAGEX_PROJECT_ROOT/.flutter-plugins-dependencies"
}

safe_remove_output() {
  local relative="$1"
  local current="$STAGEX_PROJECT_ROOT"
  local component
  IFS='/' read -r -a components <<< "$relative"
  for component in "${components[@]}"; do
    [ -n "$component" ] && [ "$component" != . ] && [ "$component" != .. ] || {
      echo "Unsafe build output: $relative" >&2
      exit 64
    }
    current="$current/$component"
    [ ! -L "$current" ] || {
      echo "Refusing build output through symlink: $current" >&2
      exit 64
    }
  done
  [ ! -e "$current" ] || rm -rf -- "$current"
}

build_image() {
  local image="$1"
  local containerfile="$2"
  local context
  context="$(mktemp -d "${TMPDIR:-/tmp}/stack-stagex-context.XXXXXX")"
  docker build --no-cache -t "$image" -f "$containerfile" "$context" || {
    local status=$?
    rmdir "$context"
    return "$status"
  }
  rmdir "$context"
}
