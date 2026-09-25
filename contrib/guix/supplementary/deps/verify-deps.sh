#!/usr/bin/env bash
# Copyright (c) Stack Wallet developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://opensource.org/licenses/MIT.
#
# verify-deps.sh — Re-verify all pre-fetched dependency hashes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../libexec/prelude.bash"

ERRORS=0

############################################################
# Verify Flutter SDK                                        #
############################################################

verify_flutter() {
    log_info "Verifying Flutter SDK ..."
    local flutter_bin="${FLUTTER_SDK_DIR}/flutter/bin/flutter"
    if [ ! -x "$flutter_bin" ]; then
        log_error "Flutter SDK not found at ${FLUTTER_SDK_DIR}/flutter"
        ERRORS=$((ERRORS + 1))
        return
    fi
    local actual_version
    actual_version="$("$flutter_bin" --version --machine 2>/dev/null | grep -o '"frameworkVersion":"[^"]*"' | cut -d'"' -f4)" || true
    if [ -n "$actual_version" ] && [ "$actual_version" != "$FLUTTER_VERSION" ]; then
        log_error "Flutter version mismatch: expected ${FLUTTER_VERSION}, got ${actual_version}"
        ERRORS=$((ERRORS + 1))
    else
        log_info "  Flutter SDK ${FLUTTER_VERSION}: OK"
    fi
}

############################################################
# Verify Rust toolchains                                    #
############################################################

verify_rust() {
    log_info "Verifying Rust toolchains ..."
    for version in "${RUST_VERSIONS[@]}"; do
        local rustc="${RUST_DIR}/${version}/bin/rustc"
        if [ ! -x "$rustc" ]; then
            log_error "Rust ${version} not found at ${RUST_DIR}/${version}"
            ERRORS=$((ERRORS + 1))
            continue
        fi
        local actual
        actual="$("$rustc" --version | awk '{print $2}')"
        if [ "$actual" != "$version" ]; then
            log_error "Rust version mismatch: expected ${version}, got ${actual}"
            ERRORS=$((ERRORS + 1))
        else
            log_info "  Rust ${version}: OK"
        fi
    done
}

############################################################
# Verify pub hosted packages against pubspec.lock           #
############################################################

verify_hosted_packages() {
    local lockfile="${SOURCE_DIR}/pubspec.lock"
    [ -f "$lockfile" ] || die "pubspec.lock not found"

    log_info "Verifying hosted packages against pubspec.lock ..."

    local count=0 missing=0
    local current_name="" current_version="" current_source=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^\ \ ([a-zA-Z0-9_]+):$ ]]; then
            if [ -n "$current_name" ] && [ "$current_source" = "hosted" ] && [ -n "$current_version" ]; then
                local pkg_dir="${PUB_CACHE_DIR}/hosted/pub.dev/${current_name}-${current_version}"
                if [ -d "$pkg_dir" ]; then
                    count=$((count + 1))
                else
                    log_error "  MISSING: ${current_name}-${current_version}"
                    missing=$((missing + 1))
                fi
            fi
            current_name="${BASH_REMATCH[1]}"
            current_version="" current_source=""
        elif [[ "$line" =~ ^\ {4}source:\ *\"?([a-z]+)\"? ]]; then
            current_source="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^\ {4}version:\ *\"([^\"]+)\" ]]; then
            current_version="${BASH_REMATCH[1]}"
        fi
    done < "$lockfile"

    # Flush last.
    if [ -n "$current_name" ] && [ "$current_source" = "hosted" ] && [ -n "$current_version" ]; then
        local pkg_dir="${PUB_CACHE_DIR}/hosted/pub.dev/${current_name}-${current_version}"
        if [ -d "$pkg_dir" ]; then
            count=$((count + 1))
        else
            log_error "  MISSING: ${current_name}-${current_version}"
            missing=$((missing + 1))
        fi
    fi

    if [ "$missing" -gt 0 ]; then
        log_error "${missing} hosted packages missing!"
        ERRORS=$((ERRORS + missing))
    fi
    log_info "  ${count} hosted packages verified present"
}

############################################################
# Verify git packages                                       #
############################################################

verify_git_packages() {
    local lockfile="${SOURCE_DIR}/pubspec.lock"

    log_info "Verifying git packages ..."

    local count=0 missing=0
    local current_name="" current_source="" current_url="" current_resolved=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^\ \ ([a-zA-Z0-9_]+):$ ]]; then
            if [ -n "$current_name" ] && [ "$current_source" = "git" ] && [ -n "$current_resolved" ]; then
                local checkout_dir="${PUB_CACHE_DIR}/git/${current_name}-${current_resolved}"
                if [ -d "$checkout_dir" ]; then
                    count=$((count + 1))
                else
                    log_error "  MISSING: ${current_name} @ ${current_resolved:0:8}"
                    missing=$((missing + 1))
                fi
            fi
            current_name="${BASH_REMATCH[1]}"
            current_source="" current_url="" current_resolved=""
        elif [[ "$line" =~ ^\ {4}source:\ *\"?([a-z]+)\"? ]]; then
            current_source="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^\ {6}resolved-ref:\ *\"?([0-9a-f]+)\"? ]]; then
            current_resolved="${BASH_REMATCH[1]}"
        fi
    done < "$lockfile"

    # Flush last.
    if [ -n "$current_name" ] && [ "$current_source" = "git" ] && [ -n "$current_resolved" ]; then
        local checkout_dir="${PUB_CACHE_DIR}/git/${current_name}-${current_resolved}"
        if [ -d "$checkout_dir" ]; then
            count=$((count + 1))
        else
            log_error "  MISSING: ${current_name} @ ${current_resolved:0:8}"
            missing=$((missing + 1))
        fi
    fi

    if [ "$missing" -gt 0 ]; then
        log_error "${missing} git packages missing!"
        ERRORS=$((ERRORS + missing))
    fi
    log_info "  ${count} git packages verified present"
}

############################################################
# Verify Cargo vendor directories                           #
############################################################

verify_cargo_vendors() {
    log_info "Verifying Cargo vendor directories ..."
    for name in epiccash mwc frostdart; do
        local vendor_dir="${CARGO_CACHE_DIR}/vendor-${name}"
        if [ -d "$vendor_dir" ]; then
            local crate_count
            crate_count="$(find "$vendor_dir" -mindepth 1 -maxdepth 1 -type d | wc -l)"
            log_info "  ${name}: ${crate_count} crates"
        else
            log_error "  ${name}: vendor directory MISSING"
            ERRORS=$((ERRORS + 1))
        fi
    done
}

############################################################
# Verify native C dependency sources                        #
############################################################

verify_native_sources() {
    log_info "Verifying native C dependency sources ..."
    local native_dir="${BASE_CACHE}/native-sources"
    for repo in jsoncpp libsecret secp256k1; do
        if [ -d "${native_dir}/${repo}/.git" ]; then
            log_info "  ${repo}: OK"
        else
            log_error "  ${repo}: MISSING at ${native_dir}/${repo}"
            ERRORS=$((ERRORS + 1))
        fi
    done
}

############################################################
# Main                                                      #
############################################################

main() {
    log_info "=== Verifying pre-fetched dependencies ==="
    log_info "Source dir: ${SOURCE_DIR}"
    log_info "Cache dir:  ${BASE_CACHE}"

    verify_flutter
    verify_rust
    verify_hosted_packages
    verify_git_packages
    verify_cargo_vendors
    verify_native_sources

    echo ""
    if [ "$ERRORS" -gt 0 ]; then
        die "Verification FAILED with ${ERRORS} error(s). Run fetch scripts to fix."
    fi
    log_info "=== All dependencies verified OK ==="
}

main "$@"
