#!/usr/bin/env bash
# Copyright (c) Stack Wallet developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://opensource.org/licenses/MIT.
#
# fetch-pub-deps.sh — Pre-fetch Dart pub dependencies, Flutter SDK, and Rust
# toolchains.  Must be run OUTSIDE the Guix container (needs network).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../libexec/prelude.bash"

auto_detect_version

############################################################
# Flutter SDK                                               #
############################################################

FLUTTER_TARBALL="flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/${FLUTTER_TARBALL}"
# Pin the SHA-256 of the Flutter SDK tarball.  Update when FLUTTER_VERSION changes.
FLUTTER_SHA256="${FLUTTER_SDK_SHA256:-}"

fetch_flutter_sdk() {
    log_info "Fetching Flutter SDK ${FLUTTER_VERSION} ..."
    mkdir -p "${FLUTTER_SDK_DIR}"

    local tarball="${BASE_CACHE}/${FLUTTER_TARBALL}"
    if [ ! -f "$tarball" ]; then
        curl -L --fail -o "$tarball" "$FLUTTER_URL"
    fi

    if [ -n "$FLUTTER_SHA256" ]; then
        verify_sha256 "$tarball" "$FLUTTER_SHA256"
    else
        log_info "FLUTTER_SDK_SHA256 not set — recording hash for future pinning:"
        sha256sum "$tarball"
    fi

    # Extract only if flutter/bin/flutter doesn't exist yet.
    if [ ! -x "${FLUTTER_SDK_DIR}/flutter/bin/flutter" ]; then
        log_info "Extracting Flutter SDK ..."
        tar -xf "$tarball" -C "${FLUTTER_SDK_DIR}"
    fi
    log_info "Flutter SDK ready at ${FLUTTER_SDK_DIR}/flutter"
}

############################################################
# Rust toolchains                                           #
############################################################

fetch_rust_toolchains() {
    mkdir -p "${RUST_DIR}"
    local target="x86_64-unknown-linux-gnu"

    for version in "${RUST_VERSIONS[@]}"; do
        local dir="${RUST_DIR}/${version}"
        if [ -d "${dir}" ] && [ -x "${dir}/bin/rustc" ]; then
            log_info "Rust ${version} already present, skipping"
            continue
        fi

        log_info "Fetching Rust ${version} ..."
        local tarball="rust-${version}-${target}.tar.gz"
        local url="https://static.rust-lang.org/dist/${tarball}"
        local dest="${BASE_CACHE}/${tarball}"

        curl -L --fail -o "$dest" "$url"

        # Also fetch the SHA-256 checksum file from upstream.
        local sha_url="${url}.sha256"
        local expected
        expected="$(curl -sL --fail "$sha_url" | awk '{print $1}')"
        verify_sha256 "$dest" "$expected"

        local tmp="${BASE_CACHE}/rust-extract-tmp"
        rm -rf "$tmp"
        mkdir -p "$tmp"
        tar -xzf "$dest" -C "$tmp"

        # The official installer places everything under a prefix.
        # Run install.sh with a --prefix to get a usable sysroot.
        (
            cd "${tmp}/rust-${version}-${target}"
            ./install.sh --prefix="${dir}" --without=rust-docs
        )
        rm -rf "$tmp"
        log_info "Rust ${version} installed to ${dir}"
    done

    # Also fetch the Rust src component for versions that need it (some crates
    # use -Z build-std or need the src for proc-macros).
    for version in "${RUST_VERSIONS[@]}"; do
        local src_dir="${RUST_DIR}/${version}/lib/rustlib/src/rust"
        if [ -d "$src_dir" ]; then
            continue
        fi
        log_info "Fetching rust-src for ${version} ..."
        local tarball="rust-src-${version}.tar.gz"
        local url="https://static.rust-lang.org/dist/${tarball}"
        local dest="${BASE_CACHE}/${tarball}"
        curl -L --fail -o "$dest" "$url"

        local tmp="${BASE_CACHE}/rust-src-extract-tmp"
        rm -rf "$tmp"
        mkdir -p "$tmp"
        tar -xzf "$dest" -C "$tmp"
        (
            cd "${tmp}/rust-src-${version}"
            ./install.sh --prefix="${RUST_DIR}/${version}" 2>/dev/null || true
        )
        rm -rf "$tmp"
    done
}

############################################################
# Dart pub hosted packages                                  #
############################################################

fetch_hosted_packages() {
    local lockfile="${1:-${SOURCE_DIR}/pubspec.lock}"
    local label="${2:-pubspec.lock}"
    [ -f "$lockfile" ] || die "Lockfile not found at ${lockfile}"

    local pub_hosted_dir="${PUB_CACHE_DIR}/hosted/pub.dev"
    mkdir -p "$pub_hosted_dir"

    log_info "Parsing hosted packages from ${label} ..."

    # Parse pubspec.lock YAML (simple state machine — no external YAML parser needed).
    local in_packages=0 current_name="" current_version="" current_sha256=""
    local current_source="" count=0 skipped=0

    while IFS= read -r line; do
        # Top-level package name (2-space indent, ends with colon).
        if [[ "$line" =~ ^\ \ ([a-zA-Z0-9_]+):$ ]]; then
            # Flush previous package.
            if [ -n "$current_name" ] && [ "$current_source" = "hosted" ] && [ -n "$current_version" ]; then
                _fetch_one_hosted "$current_name" "$current_version" "$current_sha256"
                count=$((count + 1))
            fi
            current_name="${BASH_REMATCH[1]}"
            current_version=""
            current_sha256=""
            current_source=""
        elif [[ "$line" =~ ^\ {4}source:\ *\"?([a-z]+)\"? ]]; then
            current_source="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^\ {4}version:\ *\"([^\"]+)\" ]]; then
            current_version="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^\ {6}sha256:\ *\"?([0-9a-f]+)\"? ]]; then
            current_sha256="${BASH_REMATCH[1]}"
        fi
    done < "$lockfile"

    # Flush last package.
    if [ -n "$current_name" ] && [ "$current_source" = "hosted" ] && [ -n "$current_version" ]; then
        _fetch_one_hosted "$current_name" "$current_version" "$current_sha256"
        count=$((count + 1))
    fi

    log_info "Fetched ${count} hosted packages from ${label} (${skipped} already cached)"
}

_fetch_one_hosted() {
    local name="$1" version="$2" sha256="$3"
    local pkg_dir="${PUB_CACHE_DIR}/hosted/pub.dev/${name}-${version}"

    if [ -d "$pkg_dir" ]; then
        skipped=$((skipped + 1))
        return
    fi

    local url="https://pub.dev/api/archives/${name}-${version}.tar.gz"
    local tarball="${BASE_CACHE}/pub-archives/${name}-${version}.tar.gz"
    mkdir -p "${BASE_CACHE}/pub-archives"

    if [ ! -f "$tarball" ]; then
        curl -sL --fail -o "$tarball" "$url" || {
            log_error "Failed to fetch ${name}-${version}"
            return 1
        }
    fi

    if [ -n "$sha256" ]; then
        verify_sha256 "$tarball" "$sha256"
    fi

    mkdir -p "$pkg_dir"
    tar -xzf "$tarball" -C "$pkg_dir"
}

############################################################
# Dart pub git packages                                     #
############################################################

fetch_git_packages() {
    local lockfile="${SOURCE_DIR}/pubspec.lock"

    local git_cache_dir="${PUB_CACHE_DIR}/git/cache"
    local git_pkg_dir="${PUB_CACHE_DIR}/git"
    mkdir -p "$git_cache_dir"

    log_info "Parsing git packages from pubspec.lock ..."

    local in_git_desc=0 current_name="" current_url="" current_ref="" current_resolved=""
    local current_source="" current_path="" count=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^\ \ ([a-zA-Z0-9_]+):$ ]]; then
            # Flush previous.
            if [ -n "$current_name" ] && [ "$current_source" = "git" ] && [ -n "$current_url" ]; then
                _fetch_one_git "$current_name" "$current_url" "$current_resolved" "$current_path"
                count=$((count + 1))
            fi
            current_name="${BASH_REMATCH[1]}"
            current_url="" current_ref="" current_resolved="" current_source="" current_path=""
            in_git_desc=0
        elif [[ "$line" =~ ^\ {4}source:\ *\"?([a-z]+)\"? ]]; then
            current_source="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^\ {6}url:\ *\"([^\"]+)\" ]]; then
            current_url="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^\ {6}ref:\ *\"?([^\"[:space:]]+)\"? ]]; then
            current_ref="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^\ {6}resolved-ref:\ *\"?([0-9a-f]+)\"? ]]; then
            current_resolved="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^\ {6}path:\ *\"([^\"]+)\" ]]; then
            current_path="${BASH_REMATCH[1]}"
        fi
    done < "$lockfile"

    # Flush last.
    if [ -n "$current_name" ] && [ "$current_source" = "git" ] && [ -n "$current_url" ]; then
        _fetch_one_git "$current_name" "$current_url" "$current_resolved" "$current_path"
        count=$((count + 1))
    fi

    log_info "Fetched ${count} git packages"
}

_fetch_one_git() {
    local name="$1" url="$2" resolved_ref="$3" path="${4:-.}"

    # Dart pub caches bare repos keyed by a SHA-1 hash of the URL.
    local url_hash
    url_hash="$(echo -n "$url" | sha1sum | cut -c1-40)"
    local bare_dir="${PUB_CACHE_DIR}/git/cache/${url_hash}"

    if [ ! -d "$bare_dir" ]; then
        log_info "Cloning (bare) ${url} ..."
        git clone --bare "$url" "$bare_dir"
    else
        log_info "Updating bare cache for ${url} ..."
        git -C "$bare_dir" fetch --all --prune 2>/dev/null || true
    fi

    # Checkout the resolved ref into the working tree location that pub expects.
    local ref_short="${resolved_ref:0:8}"
    local checkout_dir="${PUB_CACHE_DIR}/git/${name}-${resolved_ref}"

    if [ ! -d "$checkout_dir" ]; then
        log_info "Checking out ${name} at ${ref_short}..."
        git clone --no-checkout "$bare_dir" "$checkout_dir"
        git -C "$checkout_dir" checkout "$resolved_ref"
    fi
}

############################################################
# Path packages (just verify submodules)                    #
############################################################

verify_path_packages() {
    log_info "Verifying path packages (crypto_plugins submodules) ..."
    local crypto_dir="${SOURCE_DIR}/crypto_plugins"
    for plugin in flutter_libepiccash flutter_libmwc frostdart; do
        if [ -d "${crypto_dir}/${plugin}" ]; then
            log_info "  ${plugin}: OK"
        else
            log_error "  ${plugin}: MISSING — run 'git submodule update --init' in the source tree"
        fi
    done
}

############################################################
# Native C dependency sources (cloned at build time by      #
# existing scripts — we pre-fetch them for offline builds)  #
############################################################

fetch_native_sources() {
    local native_dir="${BASE_CACHE}/native-sources"
    mkdir -p "$native_dir"

    # sqlite3 source (used by sqlite3_flutter_libs CMake FetchContent).
    local sqlite_ver="3460000"
    local sqlite_tarball="sqlite-autoconf-${sqlite_ver}.tar.gz"
    local sqlite_dest="${native_dir}/${sqlite_tarball}"
    if [ ! -f "$sqlite_dest" ]; then
        log_info "Fetching sqlite3 source ..."
        curl -L --fail -o "$sqlite_dest" \
            "https://sqlite.org/2024/${sqlite_tarball}"
    fi
    log_info "  sqlite3: OK"

    # Boost 1.71.0 (used by flutter_libsparkmobile CMake FetchContent).
    local boost_zip="boost_1_71_0.zip"
    local boost_dest="${native_dir}/${boost_zip}"
    if [ ! -f "$boost_dest" ]; then
        log_info "Fetching Boost 1.71.0 ..."
        curl -L --fail -o "$boost_dest" \
            "https://archives.boost.io/release/1.71.0/source/${boost_zip}"
    fi
    verify_sha256 "$boost_dest" "85a94ac71c28e59cf97a96714e4c58a18550c227ac8b0388c260d6c717e47a69"
    log_info "  boost: OK"

    # JsonCPP 1.7.4
    local jsoncpp_dir="${native_dir}/jsoncpp"
    if [ ! -d "$jsoncpp_dir" ]; then
        log_info "Cloning jsoncpp ..."
        git clone https://github.com/open-source-parsers/jsoncpp.git "$jsoncpp_dir"
    fi
    git -C "$jsoncpp_dir" fetch --all 2>/dev/null || true
    log_info "  jsoncpp: OK"

    # libsecret 0.21.4 (CypherStack fork)
    local libsecret_dir="${native_dir}/libsecret"
    if [ ! -d "$libsecret_dir" ]; then
        log_info "Cloning libsecret ..."
        git clone https://git.cypherstack.com/Cypher_Stack/libsecret.git "$libsecret_dir"
    fi
    git -C "$libsecret_dir" fetch --all 2>/dev/null || true
    log_info "  libsecret: OK"

    # secp256k1 (bitcoin-core)
    local secp_dir="${native_dir}/secp256k1"
    if [ ! -d "$secp_dir" ]; then
        log_info "Cloning secp256k1 ..."
        git clone https://github.com/bitcoin-core/secp256k1 "$secp_dir"
    fi
    git -C "$secp_dir" fetch --all 2>/dev/null || true
    log_info "  secp256k1: OK"
}

############################################################
# Main                                                      #
############################################################

main() {
    log_info "=== Fetching dependencies for Stack Wallet Guix build ==="
    log_info "Source dir: ${SOURCE_DIR}"
    log_info "Cache dir:  ${BASE_CACHE}"

    fetch_flutter_sdk
    fetch_rust_toolchains
    fetch_hosted_packages "${SOURCE_DIR}/pubspec.lock" "Stack Wallet pubspec.lock"

    # Flutter tools' own dependencies (needed by PubDependencies.update inside
    # the container — Flutter's build tool runs `dart pub get` on its own
    # packages/flutter_tools directory).
    local flutter_tools_lock="${FLUTTER_SDK_DIR}/flutter/packages/flutter_tools/pubspec.lock"
    if [ -f "$flutter_tools_lock" ]; then
        fetch_hosted_packages "$flutter_tools_lock" "Flutter tools pubspec.lock"
    fi

    fetch_git_packages
    verify_path_packages

    # Cargokit build_tool dependencies (tor_ffi_plugin uses cargokit which
    # has its own Dart build tool with pinned dependencies).
    local cargokit_lock
    for cargokit_lock in "${PUB_CACHE_DIR}"/git/tor-*/cargokit/build_tool/pubspec.lock; do
        if [ -f "$cargokit_lock" ]; then
            fetch_hosted_packages "$cargokit_lock" "cargokit build_tool pubspec.lock"
            break
        fi
    done

    fetch_native_sources

    log_info "=== All dependencies fetched ==="
    log_info "Next step: run fetch-cargo-deps.sh, then guix-build"
}

main "$@"
