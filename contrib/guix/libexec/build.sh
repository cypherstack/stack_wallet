#!/usr/bin/env bash
# Copyright (c) Stack Wallet developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://opensource.org/licenses/MIT.
#
# build.sh — Inner build script that runs INSIDE the Guix container.
# No network access is available.  All dependencies are pre-mounted.

set -euo pipefail

################
# Determinism  #
################

export LC_ALL=C
export TZ=UTC
umask 0022

# Force single codegen unit in Rust release builds for deterministic output.
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1

# Disable Dart/Flutter analytics and telemetry.
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
export PUB_ENVIRONMENT=guix

################
# Paths        #
################

# These paths correspond to the --share mounts set up by guix-build.
SRC_MOUNT="/sw/src"
OUTPUT_MOUNT="/sw/output"
PUB_CACHE_MOUNT="/sw/pub-cache"
CARGO_CACHE_MOUNT="/sw/cargo-cache"
FLUTTER_MOUNT="/sw/flutter-sdk/flutter"
RUST_MOUNT="/sw/rust"
NATIVE_MOUNT="/sw/native-sources"

BUILD_DIR="/tmp/build"

# Validate mounts.
for d in "$SRC_MOUNT" "$PUB_CACHE_MOUNT" "$FLUTTER_MOUNT" "$RUST_MOUNT"; do
    [ -d "$d" ] || { echo "!!! Missing mount: $d" >&2; exit 1; }
done

################
# Env vars     #
################

HOST="${HOST:?HOST not set}"
JOBS="${JOBS:-$(nproc)}"
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:?SOURCE_DATE_EPOCH not set}"
APP_NAME_ID="${APP_NAME_ID:?APP_NAME_ID not set}"
APP_VERSION="${APP_VERSION:?APP_VERSION not set}"
APP_BUILD_NUMBER="${APP_BUILD_NUMBER:?APP_BUILD_NUMBER not set}"

# Go: offline builds for flutter_mwebd.
export GOMODCACHE="/sw/go-cache"
export GOFLAGS="-buildvcs=false"
export GONOSUMCHECK="*"
export GONOSUMDB="*"
export GOPROXY=off

RUST_VERSION_DEFAULT="${RUST_VERSION_DEFAULT:-1.89.0}"
RUST_VERSION_MWC="${RUST_VERSION_MWC:-1.85.1}"
RUST_VERSION_FROSTDART="${RUST_VERSION_FROSTDART:-1.71.0}"
RUST_VERSION_XELIS="${RUST_VERSION_XELIS:-1.91.0}"

echo "--- [build] Host: ${HOST}"
echo "--- [build] App:  ${APP_NAME_ID} v${APP_VERSION}+${APP_BUILD_NUMBER}"
echo "--- [build] Jobs: ${JOBS}"
echo "--- [build] SOURCE_DATE_EPOCH: ${SOURCE_DATE_EPOCH}"

################
# Helpers      #
################

set_rust_version() {
    local version="$1"
    local rust_prefix="${RUST_MOUNT}/${version}"
    [ -d "$rust_prefix" ] || { echo "!!! Rust ${version} not found at ${rust_prefix}" >&2; exit 1; }

    # Shim dir must come first so the cargo shim intercepts `cargo +VERSION`.
    export PATH="/tmp/shims:${rust_prefix}/bin:${PATH_ORIG}"
    export CARGO_HOME="${CARGO_CACHE_MOUNT}"
    export RUSTUP_HOME="/tmp/fake-rustup"

    # Rust 1.91+ build scripts need libgcc_s.so.1 which lives at /lib/ in the
    # Guix FHS emulation.  Set LD_LIBRARY_PATH so the linker can find it.
    export LD_LIBRARY_PATH="/lib:/lib64:/usr/lib"

    echo "--- [build] Rust version: $(rustc --version)"
}

# Create shims for rustup and cargo so existing scripts work without
# modification inside the container.
install_shims() {
    local shim_dir="/tmp/shims"
    mkdir -p "$shim_dir"

    # rustup shim: silently succeeds so scripts that call `rustup default X`
    # don't fail.
    cat > "$shim_dir/rustup" << 'SHIM'
#!/bin/sh
case "$1" in
    toolchain) echo "rustup shim: toolchain command ignored" ;;
    default)   echo "rustup shim: default command ignored" ;;
    show|--version) echo "rustup-shim 0.0.0 (guix)" ;;
    target)    echo "rustup shim: target command ignored" ;;
    run)
        # `rustup run <toolchain> <cmd> [args...]` — strip 'run' and toolchain,
        # then exec the command.  The correct toolchain is already on PATH.
        shift  # drop 'run'
        shift  # drop toolchain name (e.g. 'stable')
        exec "$@"
        ;;
    *) ;;
esac
exit 0
SHIM
    chmod +x "$shim_dir/rustup"

    # cargo shim: strips `+VERSION` argument (rustup toolchain syntax) and
    # delegates to the real cargo on PATH.  This handles frostdart's
    # `cargo +1.71.0 build ...` without needing rustup.
    cat > "$shim_dir/cargo" << 'CARGO_SHIM'
#!/bin/sh
# Strip +VERSION argument if present (e.g. `cargo +1.71.0 build` → `cargo build`).
# The correct Rust toolchain is already on PATH via set_rust_version().
REAL_CARGO=""
for p in $(echo "$PATH" | tr ':' '\n'); do
    if [ "$p" != "/tmp/shims" ] && [ -x "$p/cargo" ]; then
        REAL_CARGO="$p/cargo"
        break
    fi
done
if [ -z "$REAL_CARGO" ]; then
    echo "cargo shim: cannot find real cargo on PATH" >&2
    exit 1
fi
# Drop the first arg if it starts with '+'
case "${1:-}" in
    +*) shift ;;
esac
exec "$REAL_CARGO" "$@"
CARGO_SHIM
    chmod +x "$shim_dir/cargo"

    # git shim: intercepts `git log` to return BUILT_COMMIT_HASH (since .git
    # is excluded from the rsync copy), and makes `git pull`/`git clone` no-ops
    # for pre-populated native dependency repos.
    local git_real
    git_real="$(command -v git)"
    cat > "$shim_dir/git" << GITSHIM
#!/bin/sh
# Git wrapper for offline Guix builds.
case "\$*" in
    *log*--pretty=format*|*log*--format*)
        # Return the pre-computed commit hash.
        echo "${BUILT_COMMIT_HASH:-0000000000000000000000000000000000000000}"
        exit 0
        ;;
    *pull*|*fetch*)
        exit 0
        ;;
    *clone*)
        # If target dir already exists, succeed silently.
        last_arg="\${*##* }"
        if [ -d "\$last_arg" ]; then
            exit 0
        fi
        ;;
esac
exec "$git_real" "\$@"
GITSHIM
    chmod +x "$shim_dir/git"

    # CRITICAL: Wrap the REAL Dart VM binary to inject --offline for pub
    # commands.  Flutter's PubDependencies.update calls the dart binary at
    # bin/cache/dart-sdk/bin/dart by absolute path (bypassing any PATH shims).
    # It runs `dart pub get --example` on packages/flutter_tools.  Without
    # --offline, this tries to reach pub.dev and fails in the container.
    local dart_sdk_bin="${FLUTTER_MOUNT}/bin/cache/dart-sdk/bin"
    local dart_real="${dart_sdk_bin}/dart.real"
    if [ ! -f "$dart_real" ]; then
        mv "${dart_sdk_bin}/dart" "$dart_real"
    fi
    cat > "${dart_sdk_bin}/dart" << 'DARTWRAP'
#!/bin/bash
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
REAL="${SELF_DIR}/dart.real"
# Intercept pub commands and inject --offline.
is_pub=false
for a in "$@"; do
    [ "$a" = "pub" ] && is_pub=true && break
done
if $is_pub; then
    args=()
    for a in "$@"; do
        args+=("$a")
        case "$a" in
            get|upgrade|downgrade) args+=("--offline") ;;
        esac
    done
    exec "$REAL" "${args[@]}"
fi
exec "$REAL" "$@"
DARTWRAP
    chmod +x "${dart_sdk_bin}/dart"

    # dart shim on PATH: bypass the Flutter SDK's bin/dart shell wrapper
    # (which sources shared.sh and may run update_engine_version.sh, pub
    # upgrade, etc.).  We invoke dart.real directly.
    cat > "$shim_dir/dart" << DARTSHIM
#!/bin/sh
exec "$dart_real" "\$@"
DARTSHIM
    chmod +x "$shim_dir/dart"

    # Replace Flutter SDK's bin/dart wrapper with a simple passthrough too.
    cp "$shim_dir/dart" "${FLUTTER_MOUNT}/bin/dart"

    # flutter shim: bypasses the Flutter SDK's shared.sh which tries to run
    # `dart pub upgrade` on the Flutter tools and passes --packages= pointing
    # to a non-existent file.  Instead, we invoke the pre-built flutter_tools
    # snapshot directly via the Dart VM.
    local snapshot="${FLUTTER_MOUNT}/bin/cache/flutter_tools.snapshot"
    cat > "$shim_dir/flutter" << FLUTTERSHIM
#!/bin/sh
exec "$dart_real" "$snapshot" "\$@"
FLUTTERSHIM
    chmod +x "$shim_dir/flutter"

    export PATH="$shim_dir:$PATH"
}

# Set up Cargo to use vendored crates for a given plugin.
setup_cargo_vendor() {
    local plugin_name="$1"
    local workspace_dir="$2"
    local vendor_dir="${CARGO_CACHE_MOUNT}/vendor-${plugin_name}"

    if [ ! -d "$vendor_dir" ]; then
        echo "!!! Vendor dir not found: ${vendor_dir}" >&2
        return 1
    fi

    mkdir -p "$workspace_dir/.cargo"

    # Use the config generated by `cargo vendor` during fetch (it includes
    # source redirects for both crates-io and git dependencies).
    local vendor_config="${CARGO_CACHE_MOUNT}/vendor-${plugin_name}-config.toml"
    if [ -f "$vendor_config" ]; then
        # The saved config references the vendor dir by its original path.
        # Replace with the container-local path.
        sed "s|directory = .*|directory = \"${vendor_dir}\"|g" \
            "$vendor_config" > "$workspace_dir/.cargo/config.toml"
    else
        # Fallback: basic config for crates-io only.
        cat > "$workspace_dir/.cargo/config.toml" << EOF
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "${vendor_dir}"
EOF
    fi

    # Ensure offline mode.
    cat >> "$workspace_dir/.cargo/config.toml" << 'EOF'

[net]
offline = true
EOF
}

################
# Copy source  #
################

echo "--- [build] Copying source tree to ${BUILD_DIR} ..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
# Use rsync to exclude heavy build artifacts from the copy.
# The source tree can be 30+ GB with build/, .git/, target/ dirs.
rsync -a \
    --exclude='build/' \
    --exclude='.dart_tool/' \
    --exclude='.git/' \
    --exclude='target/' \
    --exclude='.idea/' \
    "$SRC_MOUNT/" "$BUILD_DIR/"

cd "$BUILD_DIR"

# Set up Flutter and Dart (Dart ships inside the Flutter SDK).
# Add the real dart-sdk bin to PATH temporarily — install_shims() will
# prepend shims that bypass the Flutter SDK's shared.sh bootstrap.
export PATH="${FLUTTER_MOUNT}/bin/cache/dart-sdk/bin:${PATH}"
export PUB_CACHE="$PUB_CACHE_MOUNT"

# Disable Flutter upgrade checks and analytics.
export FLUTTER_ROOT="$FLUTTER_MOUNT"

# Install shims BEFORE any dart/flutter invocations.  The shims bypass
# shared.sh which would otherwise try to write to the (read-only) Flutter SDK,
# run `dart pub upgrade`, and download artifacts.
install_shims

# Preconfigure Flutter for linux desktop (now goes through our shim).
flutter config --enable-linux-desktop 2>/dev/null || true

# Save PATH after Flutter and shims are set up but before any Rust modifications.
# set_rust_version() resets PATH to "${rust_prefix}/bin:${PATH_ORIG}" so that
# switching Rust versions doesn't accumulate stale entries.
PATH_ORIG="$PATH"

echo "--- [build] Flutter: $(flutter --version --machine 2>/dev/null | head -1)"

################
# App config   #
################

echo "--- [build] Configuring app variant: ${APP_NAME_ID} ..."

export APP_PROJECT_ROOT_DIR="$BUILD_DIR"

# BUILT_COMMIT_HASH is passed via env from guix-build (computed outside container).
# Fall back to placeholder if not set.
: "${BUILT_COMMIT_HASH:=0000000000000000000000000000000000000000}"
export BUILT_COMMIT_HASH
echo "--- [build] Commit hash: ${BUILT_COMMIT_HASH:0:12}"

# Set placeholder variables (from env.sh, but without sourcing it since it
# recomputes APP_PROJECT_ROOT_DIR relative to the script's own location).
export APP_NAME_PLACEHOLDER="PlaceHolderName"
export APP_ID_PLACEHOLDER="com.place.holder"
export APP_ID_PLACEHOLDER_CAMEL="com.place.holderCamel"
export APP_ID_PLACEHOLDER_SNAKE="com.place.holder_snake"
export APP_BASIC_NAME_PLACEHOLDER="place_holder"

# Step 1: Configure template files (copies pubspec template, platform templates).
# We use `source` (not `bash`) because these scripts `export` variables that
# later steps depend on (LINUX_TF_0, TEMPLATES_DIR, NEW_NAME, etc.).
export BUILD_ISAR_FROM_SOURCE=0
source "$BUILD_DIR/scripts/app_config/templates/configure_template_files.sh"

# Step 2: Update version.
source "$BUILD_DIR/scripts/app_config/shared/update_version.sh" \
    -v "$APP_VERSION" -b "$APP_BUILD_NUMBER"

# Step 3: Link app-specific assets.
source "$BUILD_DIR/scripts/app_config/shared/link_assets.sh" "$APP_NAME_ID" "linux"

# Step 4: Run variant-specific configuration.
# Pass "linux" as $1 — configure_campfire.sh uses it for APP_BUILD_PLATFORM,
# and configure_stack_wallet.sh checks if $1 == "windows".
source "$BUILD_DIR/scripts/app_config/configure_${APP_NAME_ID}.sh" linux

# Step 5: Linux platform config.
source "$BUILD_DIR/scripts/app_config/platforms/linux/platform_config.sh"

# Step 6: Run prebuild.sh to create stub external_api_keys.dart etc.
pushd "$BUILD_DIR/scripts" > /dev/null
bash prebuild.sh
popd > /dev/null

################
# GCC compat   #
################

# Guix provides GCC 15+ which is stricter than the GCC versions Flutter plugins
# were tested with.  The project's APPLY_STANDARD_SETTINGS function applies
# -Wall -Werror to ALL plugin targets, causing new warnings to become errors.
# Relax specific warnings that GCC 15 triggers in upstream plugin code.
_linux_cmake="${BUILD_DIR}/linux/CMakeLists.txt"
if [ -f "$_linux_cmake" ]; then
    echo "--- [build] Relaxing -Werror for GCC 15 compatibility ..."
    sed -i 's/-Wall -Werror/-Wall -Werror -Wno-sign-compare/' "$_linux_cmake"
fi

################
# Native deps  #
################

echo "--- [build] Building native C dependencies ..."

# JsonCPP 1.7.4 CMakeLists.txt predates CMake 3.5 requirement; newer CMake
# refuses to configure without this compatibility flag.  Patch the copied
# build script to add the flag.
sed -i 's/cmake -DCMAKE_BUILD_TYPE/cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE/' \
    "$BUILD_DIR/scripts/linux/build_secure_storage_deps.sh"

# Pre-populate git repos from the pre-fetched native sources cache.
# The existing build scripts do `git -C dir pull || git clone ...` which fails
# offline. The git shim (installed by install_shims) makes pull/clone no-ops
# when the target directory already exists.
LINUX_BUILD="${BUILD_DIR}/scripts/linux/build"
mkdir -p "$LINUX_BUILD"

_prepopulate_repo() {
    local name="$1" tag="$2"
    if [ -d "$NATIVE_MOUNT/$name" ]; then
        cp -a "$NATIVE_MOUNT/$name" "$LINUX_BUILD/$name"
        # Use the real git for checkout (bypass shim).
        local real_git
        for p in $(echo "$PATH" | tr ':' '\n'); do
            if [ "$p" != "/tmp/shims" ] && [ -x "$p/git" ]; then
                real_git="$p/git"
                break
            fi
        done
        "$real_git" -C "$LINUX_BUILD/$name" checkout "$tag" 2>/dev/null || true
        "$real_git" -C "$LINUX_BUILD/$name" remote remove origin 2>/dev/null || true
    fi
}

_prepopulate_repo jsoncpp 1.7.4
_prepopulate_repo libsecret 0.21.4
_prepopulate_repo secp256k1 68b55209f1ba3e6c0417789598f5f75649e9c14c

# Build JsonCPP + libsecret (secure storage deps).
(
    cd "$BUILD_DIR/scripts/linux"
    bash build_secure_storage_deps.sh
)

# Build secp256k1.
(
    cd "$BUILD_DIR/scripts/linux"
    bash build_secp256k1.sh
)

################
# Rust plugins #
################

echo "--- [build] Building Rust crypto plugins for variant: ${APP_NAME_ID} ..."

CRYPTO_DIR="$BUILD_DIR/crypto_plugins"

case "$APP_NAME_ID" in
    stack_wallet)
        # 1. flutter_libepiccash (Rust $RUST_VERSION_DEFAULT)
        echo "--- [build] Building flutter_libepiccash ..."
        set_rust_version "$RUST_VERSION_DEFAULT"
        setup_cargo_vendor "epiccash" "${CRYPTO_DIR}/flutter_libepiccash/rust"
        (
            cd "${CRYPTO_DIR}/flutter_libepiccash/scripts/linux"
            # GCC 15 in Guix: libstdc++ was built without C99 fenv support,
            # so <cfenv> never exposes fesetround/fegetround.  Force the
            # config macros so the C++ wrapper actually includes <fenv.h>.
            export CXXFLAGS="${CXXFLAGS:-} -D_GLIBCXX_HAVE_FENV_H=1 -D_GLIBCXX_USE_C99_FENV=1"
            bash build_all.sh
        )

        # 2. flutter_libmwc (Rust $RUST_VERSION_MWC)
        echo "--- [build] Building flutter_libmwc ..."
        set_rust_version "$RUST_VERSION_MWC"
        setup_cargo_vendor "mwc" "${CRYPTO_DIR}/flutter_libmwc/rust"
        (
            cd "${CRYPTO_DIR}/flutter_libmwc/scripts/linux"
            bash build_all.sh
        )

        # 3. frostdart (Rust $RUST_VERSION_FROSTDART)
        echo "--- [build] Building frostdart ..."
        set_rust_version "$RUST_VERSION_FROSTDART"
        setup_cargo_vendor "frostdart" "${CRYPTO_DIR}/frostdart/src/serai"
        (
            cd "${CRYPTO_DIR}/frostdart/scripts/linux"
            bash build_all.sh
        )
        ;;

    stack_duo)
        # frostdart only.
        echo "--- [build] Building frostdart ..."
        set_rust_version "$RUST_VERSION_FROSTDART"
        setup_cargo_vendor "frostdart" "${CRYPTO_DIR}/frostdart/src/serai"
        (
            cd "${CRYPTO_DIR}/frostdart/scripts/linux"
            bash build_all.sh
        )
        ;;

    campfire)
        # No Rust plugins for Campfire (secp256k1 already built above via cmake).
        echo "--- [build] No Rust plugins needed for campfire"
        ;;

    *)
        echo "!!! Unknown APP_NAME_ID: ${APP_NAME_ID}" >&2
        exit 1
        ;;
esac

# Switch back to default Rust for any remaining steps.
set_rust_version "$RUST_VERSION_DEFAULT"

################
# Cargokit prep #
################

# Cargokit plugins (tor_ffi_plugin, xelis_flutter) build Rust code during
# `flutter build linux` via cmake.  Cargokit's run_build_tool.sh changes
# directory to a temp folder before invoking cargo.  Cargo searches for
# .cargo/config.toml from CWD upwards, so per-workspace configs are not
# found.  Solution: give each Cargokit plugin its own CARGO_HOME with the
# correct vendor config.  We patch each plugin's run_build_tool.sh to
# export CARGO_HOME before running the Dart build tool.

echo "--- [build] Setting up Cargokit vendor configs for offline Rust builds ..."

# Helper: create a per-plugin CARGO_HOME with vendor config.
setup_cargokit_plugin() {
    local plugin_name="$1"
    local plugin_dir="$2"  # root of the plugin (contains cargokit/, rust/, linux/)
    local rust_dir="$plugin_dir/rust"

    # Set up workspace-level vendor config (for any direct cargo invocations).
    setup_cargo_vendor "$plugin_name" "$rust_dir"

    # Create a per-plugin CARGO_HOME with the same config.
    local cargo_home="/tmp/cargo-home-${plugin_name}"
    mkdir -p "$cargo_home"
    cp "$rust_dir/.cargo/config.toml" "$cargo_home/config.toml"

    # Patch run_build_tool.sh to export this CARGO_HOME before running Dart.
    local rbt="$plugin_dir/cargokit/run_build_tool.sh"
    if [ -f "$rbt" ]; then
        sed -i "2i export CARGO_HOME=\"${cargo_home}\"" "$rbt"
    fi
}

for _tor_dir in "${PUB_CACHE_MOUNT}"/git/tor-*/; do
    if [ -f "$_tor_dir/rust/Cargo.toml" ]; then
        setup_cargokit_plugin "tor" "$_tor_dir"
        break
    fi
done
for _xelis_dir in "${PUB_CACHE_MOUNT}"/git/xelis-flutter-ffi-*/ "${PUB_CACHE_MOUNT}"/git/xelis_flutter-*/ "${PUB_CACHE_MOUNT}"/git/xelis-flutter-*/; do
    if [ -f "$_xelis_dir/rust/Cargo.toml" ]; then
        setup_cargokit_plugin "xelis" "$_xelis_dir"
        break
    fi
done

# Use the highest Rust version for the flutter build phase.
# Cargokit plugins (tor, xelis) build via cmake during `flutter build linux`.
# Our rustup shim ignores rust-toolchain.toml, so we must set PATH to a
# version that satisfies all plugins.  1.91.0 >= all requirements.
set_rust_version "$RUST_VERSION_XELIS"

################
# Flutter build #
################

echo "--- [build] Running flutter pub get (offline) ..."
flutter pub get --offline

# Patch FetchContent URLs to use pre-fetched sources (no network in container).
_plugin_symlinks="${BUILD_DIR}/linux/flutter/ephemeral/.plugin_symlinks"

_sqlite3_cmake="${_plugin_symlinks}/sqlite3_flutter_libs/linux/CMakeLists.txt"
if [ -f "$_sqlite3_cmake" ]; then
    echo "--- [build] Patching sqlite3_flutter_libs for offline build ..."
    sed -i "s|URL https://sqlite.org/2024/sqlite-autoconf-3460000.tar.gz|URL file://${NATIVE_MOUNT}/sqlite-autoconf-3460000.tar.gz|g" \
        "$_sqlite3_cmake"
fi

_spark_cmake="${_plugin_symlinks}/flutter_libsparkmobile/src/CMakeLists.txt"
if [ -f "$_spark_cmake" ]; then
    echo "--- [build] Patching flutter_libsparkmobile Boost URL for offline build ..."
    sed -i "s|https://archives.boost.io/release/1.71.0/source/boost_1_71_0.zip|file://${NATIVE_MOUNT}/boost_1_71_0.zip|g" \
        "$_spark_cmake"
fi

# coinlib_flutter uses ExternalProject_Add to git-clone secp256k1 from GitHub.
# Replace with our pre-fetched local clone.
_coinlib_cmake="${_plugin_symlinks}/coinlib_flutter/src/CMakeLists.txt"
if [ -f "$_coinlib_cmake" ]; then
    echo "--- [build] Patching coinlib_flutter secp256k1 for offline build ..."
    sed -i "s|GIT_REPOSITORY https://github.com/bitcoin-core/secp256k1|GIT_REPOSITORY ${NATIVE_MOUNT}/secp256k1|g" \
        "$_coinlib_cmake"
    # Guix's x86_64 CMake defaults CMAKE_INSTALL_LIBDIR to lib64, but
    # coinlib_flutter hardcodes lib/.  Force lib.
    sed -i 's/CMAKE_ARGS ${SECP256K1_ARGS}/CMAKE_ARGS ${SECP256K1_ARGS} -DCMAKE_INSTALL_LIBDIR=lib/' \
        "$_coinlib_cmake"
fi

# Flutter hardcodes CC=clang/CXX=clang++ when running cmake (build_linux.dart:185).
# Guix's libstdc++ headers from GCC 15+ use _GLIBCXX26_* macros that Clang
# doesn't understand.  Patch the Flutter tools source to use GCC and recompile.
_flutter_build_linux="${FLUTTER_MOUNT}/packages/flutter_tools/lib/src/linux/build_linux.dart"
if grep -q "'CC': 'clang'" "$_flutter_build_linux" 2>/dev/null; then
    echo "--- [build] Patching Flutter tools to use GCC instead of Clang ..."
    sed -i "s/'CC': 'clang', 'CXX': 'clang++'/'CC': 'gcc', 'CXX': 'g++'/" \
        "$_flutter_build_linux"
    # Recompile the flutter_tools snapshot from patched source.
    _dart_real="${FLUTTER_MOUNT}/bin/cache/dart-sdk/bin/dart.real"
    _snapshot="${FLUTTER_MOUNT}/bin/cache/flutter_tools.snapshot"
    echo "--- [build] Recompiling flutter_tools.snapshot ..."
    "$_dart_real" compile kernel \
        --output="$_snapshot" \
        "${FLUTTER_MOUNT}/packages/flutter_tools/bin/flutter_tools.dart" 2>&1 || {
        echo "!!! Failed to recompile flutter_tools.snapshot" >&2
        exit 1
    }
fi

echo "--- [build] Building Flutter Linux release ..."
flutter build linux --release --no-pub

################
# Package      #
################

echo "--- [build] Packaging output ..."

BUNDLE_DIR="$BUILD_DIR/build/linux/x64/release/bundle"
[ -d "$BUNDLE_DIR" ] || { echo "!!! Bundle dir not found: $BUNDLE_DIR" >&2; exit 1; }

DIST_NAME="${APP_NAME_ID}-${APP_VERSION}-${HOST}"
STAGING="/tmp/staging/${DIST_NAME}"
rm -rf "/tmp/staging"
mkdir -p "$STAGING"

# Copy bundle contents.
cp -a "$BUNDLE_DIR"/* "$STAGING/"

# Normalize timestamps and permissions for determinism.
find "$STAGING" -exec touch --date="@${SOURCE_DATE_EPOCH}" {} +
find "$STAGING" -type f -exec chmod 644 {} +
find "$STAGING" -type d -exec chmod 755 {} +
# Restore executable bit on the main binary and .so files.
find "$STAGING" -name "*.so" -exec chmod 755 {} +
[ -f "$STAGING/${APP_NAME_ID}" ] && chmod 755 "$STAGING/${APP_NAME_ID}"
# Try alternative binary names.
for candidate in stackwallet stackduo paymint campfire; do
    [ -f "$STAGING/${candidate}" ] && chmod 755 "$STAGING/${candidate}"
done

# Create deterministic tarball.
mkdir -p "$OUTPUT_MOUNT"
TARBALL="${OUTPUT_MOUNT}/${DIST_NAME}.tar.gz"
tar --create \
    --sort=name \
    --mtime="@${SOURCE_DATE_EPOCH}" \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    --gzip \
    --file="$TARBALL" \
    -C "/tmp/staging" \
    "$DIST_NAME"

echo "--- [build] Output: ${TARBALL}"

# Write partial SHA256SUMS.
(cd "$OUTPUT_MOUNT" && sha256sum "${DIST_NAME}.tar.gz") \
    > "${OUTPUT_MOUNT}/SHA256SUMS.part"

echo "--- [build] SHA256SUMS.part:"
cat "${OUTPUT_MOUNT}/SHA256SUMS.part"

echo "--- [build] Build complete for ${HOST}"
