#!/usr/bin/env bash
# Copyright (c) Stack Wallet developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://opensource.org/licenses/MIT.
#
# fetch-cargo-deps.sh — Pre-fetch Cargo crates for each Rust plugin workspace.
# Must be run OUTSIDE the Guix container (needs network).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../libexec/prelude.bash"

CARGO_CACHE="${CARGO_CACHE_DIR}"
mkdir -p "$CARGO_CACHE"

# Use the default Rust toolchain for cargo fetch.
CARGO="${RUST_DIR}/${RUST_VERSION_DEFAULT}/bin/cargo"
if [ ! -x "$CARGO" ]; then
    die "Rust ${RUST_VERSION_DEFAULT} not found at ${RUST_DIR}. Run fetch-pub-deps.sh first."
fi

export CARGO_HOME="${CARGO_CACHE}"

# Vendor crates for a given workspace directory.
vendor_workspace() {
    local name="$1"
    local workspace_dir="$2"
    local rust_version="${3:-${RUST_VERSION_DEFAULT}}"
    local cargo_bin="${RUST_DIR}/${rust_version}/bin/cargo"

    if [ ! -d "$workspace_dir" ]; then
        log_info "Skipping ${name}: workspace not found at ${workspace_dir}"
        return
    fi

    local vendor_dir="${CARGO_CACHE}/vendor-${name}"
    if [ -d "$vendor_dir" ]; then
        log_info "${name}: vendor directory exists, skipping (delete to re-fetch)"
        return
    fi

    log_info "Vendoring crates for ${name} (Rust ${rust_version}) ..."
    mkdir -p "$vendor_dir"

    # cargo vendor prints a .cargo/config.toml snippet to stdout that tells
    # cargo how to redirect all sources (crates-io + git) to the vendor dir.
    # Capture it so build.sh can use it.
    local config_file="${CARGO_CACHE}/vendor-${name}-config.toml"
    (
        cd "$workspace_dir"
        "$cargo_bin" vendor --versioned-dirs "$vendor_dir" 2>/dev/null
    ) > "$config_file"

    log_info "${name}: vendored to ${vendor_dir}"
    log_info "${name}: config saved to ${config_file}"
}

############################################################
# Vendor each Rust plugin workspace                         #
############################################################

CRYPTO="${SOURCE_DIR}/crypto_plugins"

# flutter_libepiccash — the Rust code lives in crypto_plugins/flutter_libepiccash/rust/
vendor_workspace "epiccash" \
    "${CRYPTO}/flutter_libepiccash/rust" \
    "${RUST_VERSION_DEFAULT}"

# flutter_libmwc — Rust code in crypto_plugins/flutter_libmwc/rust/
vendor_workspace "mwc" \
    "${CRYPTO}/flutter_libmwc/rust" \
    "${RUST_VERSION_MWC}"

# frostdart — Rust code in crypto_plugins/frostdart/src/serai/
vendor_workspace "frostdart" \
    "${CRYPTO}/frostdart/src/serai" \
    "${RUST_VERSION_FROSTDART}"

############################################################
# tor_ffi_plugin (cargokit — Rust code in pub git cache)    #
############################################################

# The tor plugin's Rust workspace lives inside the pub git cache, not in
# crypto_plugins.  Locate it by the resolved-ref hash.
TOR_WORKSPACE=""
for d in "${PUB_CACHE_DIR}"/git/tor-*/rust; do
    if [ -f "$d/Cargo.toml" ]; then
        TOR_WORKSPACE="$d"
        break
    fi
done

vendor_workspace "tor" \
    "${TOR_WORKSPACE}" \
    "${RUST_VERSION_DEFAULT}"

############################################################
# Also vendor secp256k1 build deps (cmake-based, no Cargo) #
############################################################

log_info "secp256k1 is built via cmake (no Cargo deps to vendor)"

log_info "=== Cargo dependency fetch complete ==="
log_info "Vendor dirs created in ${CARGO_CACHE}/"
