#!/usr/bin/env bash

set -x -e

export TEMPLATES_DIR="${APP_PROJECT_ROOT_DIR}/scripts/app_config/templates"

export T_PUBSPEC="${TEMPLATES_DIR}/pubspec.template.yaml"
export ACTUAL_PUBSPEC="${APP_PROJECT_ROOT_DIR}/pubspec.yaml"

export ANDROID_TF_0="android/app/build.gradle"
export ANDROID_TF_1="android/app/src/debug/AndroidManifest.xml"
export ANDROID_TF_2="android/app/src/profile/AndroidManifest.xml"
export ANDROID_TF_3="android/app/src/main/AndroidManifest.xml"
export ANDROID_TF_4="android/app/src/main/profile/AndroidManifest.xml"
export ANDROID_TF_5="android/app/src/main/kotlin/com/cypherstack/stackwallet/MainActivity.kt"
export IOS_TF_0="ios/Runner/Info.plist"
export IOS_TF_1="ios/Runner.xcodeproj/project.pbxproj"
export LINUX_TF_0="linux/CMakeLists.txt"
export LINUX_TF_1="linux/my_application.cc"
export MAC_TF_0="macos/Runner.xcodeproj/project.pbxproj"
export MAC_TF_1="macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme"
export MAC_TF_2="macos/Runner/Configs/AppInfo.xcconfig"
export WIN_TF_0="windows/runner/Runner.rc"
export WIN_TF_1="windows/runner/main.cpp"
export WIN_TF_2="windows/CMakeLists.txt"

mkdir -p "${APP_PROJECT_ROOT_DIR}/android/app/src/debug"
mkdir -p "${APP_PROJECT_ROOT_DIR}/android/app/src/profile"
mkdir -p "${APP_PROJECT_ROOT_DIR}/android/app/src/main/profile"
mkdir -p "${APP_PROJECT_ROOT_DIR}/android/app/src/main/kotlin/com/cypherstack/stackwallet"
mkdir -p "${APP_PROJECT_ROOT_DIR}/ios/Runner"
mkdir -p "${APP_PROJECT_ROOT_DIR}/ios/Runner.xcodeproj"
mkdir -p "${APP_PROJECT_ROOT_DIR}/macos/Runner.xcodeproj"
mkdir -p "${APP_PROJECT_ROOT_DIR}/macos/Runner.xcodeproj/xcshareddata/xcschemes"
mkdir -p "${APP_PROJECT_ROOT_DIR}/macos/Runner/Configs"
mkdir -p "${APP_PROJECT_ROOT_DIR}/windows/runner"

TEMPLATE_FILES=(
  "${ANDROID_TF_0}"
  "${ANDROID_TF_1}"
  "${ANDROID_TF_2}"
  "${ANDROID_TF_3}"
  "${ANDROID_TF_4}"
  "${ANDROID_TF_5}"
  "${IOS_TF_0}"
  "${IOS_TF_1}"
  "${LINUX_TF_0}"
  "${LINUX_TF_1}"
  "${MAC_TF_0}"
  "${MAC_TF_1}"
  "${MAC_TF_2}"
  "${WIN_TF_0}"
  "${WIN_TF_1}"
  "${WIN_TF_2}"
)

if [ -f "${ACTUAL_PUBSPEC}" ]; then
  rm "${ACTUAL_PUBSPEC}"
fi
cp "${T_PUBSPEC}" "${ACTUAL_PUBSPEC}"

# ============================================================================
# Isar Source Build Support
# ============================================================================

detect_isar_version() {
    local version="unknown"
    local lock_file="${APP_PROJECT_ROOT_DIR}/pubspec.lock"
    
    if [[ -f "${lock_file}" ]]; then
        version=$(grep -A1 "isar_community:" "${lock_file}" | grep version | awk -F'"' '{print $2}' | head -n1)
    fi
    
    if [[ -z "${version}" || "${version}" == "unknown" ]]; then
        version="3.3.0-dev.2"
        echo "Could not detect isar_community version (fallback: ${version})" >&2
    else
        echo "Detected isar_community version: ${version}" >&2
    fi
    
    echo "${version}"
}

enable_isar_source_build() {
    local isar_version="$1"
    local git_ref="${isar_version#v}"
    
    # Escape special characters for use in sed replacement string
    git_ref=$(printf '%s\n' "${git_ref}" | sed -e 's:[\/&]:\\&:g')

    echo "Enabling Isar source build section in pubspec.yaml (ref: ${git_ref})"
    
    dart "${APP_PROJECT_ROOT_DIR}/tool/process_pubspec_deps.dart" "${ACTUAL_PUBSPEC}" ISAR
    sed -i -E "/(isar_community|isar_community_flutter_libs|isar_community_generator)/,+3 s|(ref:).*|\1 ${git_ref}|" "${ACTUAL_PUBSPEC}"
    echo "Applied isar_community ${git_ref} source override successfully."
}

find_isar_core_lib() {
    local isar_core_path
    isar_core_path=$(find "${HOME}/.pub-cache/git" -type d -path "*/isar_core_ffi" | head -n 1)
    
    if [[ -z "${isar_core_path}" ]]; then
        echo ""
        return 1
    fi
    
    echo "${isar_core_path}"
    return 0
}

build_isar_core() {
    local isar_core_path="$1"
    # Go up 2 levels: isar_core_ffi -> packages -> workspace_root
    local workspace_root=$(dirname $(dirname "${isar_core_path}"))
    
    if [[ ! -f "${workspace_root}/target/release/libisar.so" ]]; then
        echo "Running cargo build --release for Isar core..."
        (cd "${isar_core_path}" && cargo build --release)
    else
        echo "libisar.so already built, skipping rebuild."
    fi
}

copy_isar_lib() {
    local lib_src="$1"
    local lib_dest="$2"
    
    if [[ ! -f "${lib_src}" ]]; then
        echo "Warning: libisar.so not found at ${lib_src}"
        return 1
    fi
    
    mkdir -p "${lib_dest}"
    cp -f "${lib_src}" "${lib_dest}/"
    echo "Copied libisar.so to ${lib_dest}"
}

handle_isar_source_build() {
    echo "------------------------------------------------------------"
    echo "Building Isar database library from source (BUILD_ISAR_FROM_SOURCE=1)"
    echo "------------------------------------------------------------"
    
    local isar_core_path
    isar_core_path=$(find_isar_core_lib) || {
        echo "Error: could not locate isar_core_ffi inside ~/.pub-cache/git."
        return 1
    }
    
    echo "Found isar_core_ffi at: ${isar_core_path}"
    
    # Build the core library
    build_isar_core "${isar_core_path}"
    
    # Go up 2 levels to get workspace root
    local workspace_root=$(dirname $(dirname "${isar_core_path}"))
    local lib_src="${workspace_root}/target/release/libisar.so"
    
    # Handle fallback if libisar.so is in deps subdirectory
    if [[ ! -f "${lib_src}" ]]; then
        local alt_src
        alt_src="${workspace_root}/target/release/deps/libisar.so"
        if [[ -f "${alt_src}" ]]; then
            echo "Found libisar.so in deps subdirectory"
            lib_src="${alt_src}"
        else
            echo "Error: could not produce libisar.so"
            return 1
        fi
    fi
 
    local plugin_path="${APP_PROJECT_ROOT_DIR}/linux/flutter/ephemeral/.plugin_symlinks/isar_community_flutter_libs/linux"
    echo "Copying to Flutter plugin symlink path: ${plugin_path}"
    copy_isar_lib "${lib_src}" "${plugin_path}" || return 1
    
    local bundle_path="${APP_PROJECT_ROOT_DIR}/build/linux/x64/release/bundle/lib"
    echo "Copying to final bundle directory: ${bundle_path}"
    copy_isar_lib "${lib_src}" "${bundle_path}" || return 1
}

if [[ "${BUILD_ISAR_FROM_SOURCE:-0}" -eq 1 ]]; then
    isar_version=$(detect_isar_version)
    enable_isar_source_build "${isar_version}"
    handle_isar_source_build || exit 1
else
    echo "Using prebuilt Isar binaries (pub.dev)"
fi

# ============================================================================
# Copy Template Files
# ============================================================================

for TF in "${TEMPLATE_FILES[@]}"; do
  FILE="${APP_PROJECT_ROOT_DIR}/${TF}"
  if [ -f "${FILE}" ]; then
    rm "${FILE}"
  fi
  cp -rp "${TEMPLATES_DIR}/${TF}" "${FILE}"
done
