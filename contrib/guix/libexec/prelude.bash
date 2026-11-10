#!/usr/bin/env bash
# Copyright (c) Stack Wallet developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://opensource.org/licenses/MIT.
#
# prelude.bash — shared variables and helpers for guix build scripts.

set -euo pipefail

################
# Directories  #
################

# Root of the guix contrib tree (where guix-build lives).
GUIX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Root of the stack_wallet source tree.
# Resolve the checkout containing these scripts, including isolated worktrees.
: "${SOURCE_DIR:="$(cd "${GUIX_DIR}/../.." && pwd)"}"

# Pre-fetched dependency caches.
: "${BASE_CACHE:="${GUIX_DIR}/depends"}"

export PUB_CACHE_DIR="${BASE_CACHE}/pub-cache"
export CARGO_CACHE_DIR="${BASE_CACHE}/cargo-cache"
export FLUTTER_SDK_DIR="${BASE_CACHE}/flutter-sdk"
export RUST_DIR="${BASE_CACHE}/rust-toolchains"

# Build output directory (per invocation).
: "${OUTDIR:="${GUIX_DIR}/guix-build-$(date +%Y%m%d%H%M%S)"}"
export OUTDIR

################
# Versions     #
################

export FLUTTER_VERSION="3.47.2"
export FLUTTER_CHANNEL="stable"

export RUST_VERSION_DEFAULT="1.89.0"
export RUST_VERSION_MWC="1.85.1"
export RUST_VERSION_FROSTDART="1.71.0"
export RUST_VERSION_XELIS="1.91.0"

# All Rust versions we need toolchains for.
export RUST_VERSIONS=("${RUST_VERSION_DEFAULT}" "${RUST_VERSION_MWC}" "${RUST_VERSION_FROSTDART}" "${RUST_VERSION_XELIS}")

################
# Build config #
################

: "${APP_NAME_ID:=stack_wallet}"
: "${APP_VERSION:=}"
: "${APP_BUILD_NUMBER:=}"
: "${JOBS:=$(nproc 2>/dev/null || echo 4)}"
: "${HOSTS:=x86_64-linux-gnu}"

export APP_NAME_ID APP_VERSION APP_BUILD_NUMBER JOBS HOSTS

################
# Helpers      #
################

log_info() {
    echo "--- [guix] $*"
}

log_error() {
    echo "!!! [guix] $*" >&2
}

die() {
    log_error "$@"
    exit 1
}

# Verify that a file matches an expected SHA-256 hash.
verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual
    actual="$(sha256sum "$file" | awk '{print $1}')"
    if [ "$actual" != "${expected,,}" ]; then
        die "SHA-256 mismatch for ${file}: expected ${expected}, got ${actual}"
    fi
}

# Extract version and build number from pubspec.yaml if not set.
auto_detect_version() {
    if [ -z "${APP_VERSION}" ] || [ -z "${APP_BUILD_NUMBER}" ]; then
        local pubspec="${SOURCE_DIR}/pubspec.yaml"
        if [ -f "$pubspec" ]; then
            local version_line
            version_line="$(grep '^version:' "$pubspec" | head -1)"
            # Format: version: X.Y.Z+NNN
            if [[ "$version_line" =~ version:\ *([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+) ]]; then
                : "${APP_VERSION:="${BASH_REMATCH[1]}"}"
                : "${APP_BUILD_NUMBER:="${BASH_REMATCH[2]}"}"
                export APP_VERSION APP_BUILD_NUMBER
            fi
        fi
    fi
}

# Compute SOURCE_DATE_EPOCH from git log.
compute_source_date_epoch() {
    if [ -z "${SOURCE_DATE_EPOCH:-}" ]; then
        # -e handles both regular .git dirs and worktree .git files.
        if [ -e "${SOURCE_DIR}/.git" ]; then
            SOURCE_DATE_EPOCH="$(git -C "${SOURCE_DIR}" log -1 --format=%ct)"
        else
            SOURCE_DATE_EPOCH="$(date +%s)"
        fi
        export SOURCE_DATE_EPOCH
    fi
}

# This prototype still manually builds the pre-native-assets Rust workspaces.
# Check before downloads or container setup: a successful textual merge does
# not make its offline build pipeline compatible with current staging.
require_supported_native_layout() {
    local manifest
    for manifest in \
        crypto_plugins/flutter_libepiccash/rust/Cargo.toml \
        crypto_plugins/flutter_libmwc/rust/Cargo.toml \
        crypto_plugins/frostdart/src/serai/Cargo.toml; do
        if [ ! -f "${SOURCE_DIR}/${manifest}" ]; then
            die "Guix native-assets support is not implemented for this checkout.
Missing legacy workspace: ${manifest}
Current staging builds native packages through Dart hooks. Port the offline
Rust/Go/CMake caches and hook toolchain selection before using this prototype.
See contrib/guix/README.md. No dependencies have been downloaded by this check."
        fi
    done
    local template="${SOURCE_DIR}/scripts/app_config/templates/pubspec.template.yaml"
    local plugin
    for plugin in flutter_libepiccash flutter_libmwc frostdart; do
        if [ ! -f "$template" ] || ! grep -Eq \
            "^[#[:space:]]*path:[[:space:]]+\\./crypto_plugins/${plugin}[[:space:]]*$" "$template"; then
            die "Guix native-assets support is not implemented: the dependency template does not select legacy ${plugin}. Stale workspace directories do not make this checkout compatible. See contrib/guix/README.md."
        fi
    done
}

require_flutter_checksum() {
    if [[ ! "${FLUTTER_SDK_SHA256:-}" =~ ^[0-9a-fA-F]{64}$ ]]; then
        die "Set FLUTTER_SDK_SHA256 to the independently verified SHA-256 of the Flutter ${FLUTTER_VERSION} Linux SDK archive."
    fi
}

verify_flutter_sdk_version() {
    local flutter_bin="$1" actual_version
    actual_version="$("$flutter_bin" --version --machine | python3 -c \
        'import json, sys; print(json.load(sys.stdin)["frameworkVersion"])')" || actual_version=""
    if [ "$actual_version" != "$FLUTTER_VERSION" ]; then
        log_error "Flutter version mismatch: expected ${FLUTTER_VERSION}, got ${actual_version:-invalid metadata}"
        return 1
    fi
}
