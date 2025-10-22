#!/usr/bin/env bash

set -x -e

export TEMPLATES_DIR="${APP_PROJECT_ROOT_DIR}/scripts/app_config/templates"
export T_PUBSPEC="${TEMPLATES_DIR}/pubspec.template.yaml"
export ACTUAL_PUBSPEC="${APP_PROJECT_ROOT_DIR}/pubspec.yaml"

find_isar_core_lib() {
    local isar_core_path
    isar_core_path=$(find "${HOME}/.pub-cache/git" -type d -path "*/isar_core_ffi" -print -quit 2>/dev/null)
    [[ -z "${isar_core_path}" ]] && return 1
    echo "${isar_core_path}"
}

detect_isar_version() {
    local version="unknown"
    local lock_file="${APP_PROJECT_ROOT_DIR}/pubspec.lock"
    [[ -f "${lock_file}" ]] && version=$(grep -A1 "isar_community:" "${lock_file}" 2>/dev/null | grep version | awk -F'"' '{print $2}' | head -n1)
    echo "${version:-3.3.0-dev.2}"
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

build_isar_core() {
    local isar_core_path="$1"
    local workspace_root="$2"

    echo "Building Isar core from: ${isar_core_path}"

    if [[ ! -f "${isar_core_path}/Cargo.toml" ]]; then
        echo "Error: Cargo.toml not found" >&2
        return 1
    fi

    if [[ -f "${workspace_root}/target/release/libisar.so" ]] || \
       [[ -f "${workspace_root}/target/release/deps/libisar.so" ]]; then
        echo "Note: libisar.so already built, skipping build step"
        return 0
    fi

    (cd "${isar_core_path}" && cargo build --release) || {
        echo "Error: cargo build failed for isar_core_ffi" >&2
        return 1
    }
}

find_isar_library() {
    local workspace_root="$1"

    if [[ -f "${workspace_root}/target/release/libisar.so" ]]; then
        echo "${workspace_root}/target/release/libisar.so"
        return 0
    fi

    if [[ -f "${workspace_root}/target/release/deps/libisar.so" ]]; then
        echo "${workspace_root}/target/release/deps/libisar.so"
        return 0
    fi

    echo "Error: could not produce libisar.so" >&2
    return 1
}

enable_isar_source_build() {
    local isar_version="$1"
    local git_ref="${isar_version#v}"
 
    git_ref=$(printf '%s\n' "${git_ref}" | sed -e 's:[\/&]:\\&:g')

    echo "Enabling Isar source build section in pubspec.yaml (ref: ${git_ref})"

    dart "${APP_PROJECT_ROOT_DIR}/tool/process_pubspec_deps.dart" "${ACTUAL_PUBSPEC}" ISAR

    if [[ "$(uname)" == 'Darwin' ]]; then
        sed -i '' -E "/(isar_community|isar_community_flutter_libs|isar_community_generator)/,+3 s|(ref:).*|\1 ${git_ref}|" "${ACTUAL_PUBSPEC}"
    else
        sed -i -E "/(isar_community|isar_community_flutter_libs|isar_community_generator)/,+3 s|(ref:).*|\1 ${git_ref}|" "${ACTUAL_PUBSPEC}"
    fi
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

    local workspace_root=$(dirname $(dirname "${isar_core_path}"))

    build_isar_core "${isar_core_path}" "${workspace_root}" || return 1
 
    local lib_src
    lib_src=$(find_isar_library "${workspace_root}") || return 1

    local plugin_path="${APP_PROJECT_ROOT_DIR}/linux/flutter/ephemeral/.plugin_symlinks/isar_community_flutter_libs/linux"
    if [[ -d "$(dirname "${plugin_path}")" ]]; then
        copy_isar_lib "${lib_src}" "${plugin_path}" || return 1
    fi

    local bundle_path="${APP_PROJECT_ROOT_DIR}/build/linux/x64/release/bundle/lib"
    if [[ -d "$(dirname "${bundle_path}")" ]]; then
        copy_isar_lib "${lib_src}" "${bundle_path}" || return 1
    fi
}

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
  "android/app/build.gradle"
  "android/app/src/debug/AndroidManifest.xml"
  "android/app/src/profile/AndroidManifest.xml"
  "android/app/src/main/AndroidManifest.xml"
  "android/app/src/main/profile/AndroidManifest.xml"
  "android/app/src/main/kotlin/com/cypherstack/stackwallet/MainActivity.kt"
  "ios/Runner/Info.plist"
  "ios/Runner.xcodeproj/project.pbxproj"
  "linux/CMakeLists.txt"
  "linux/my_application.cc"
  "macos/Runner.xcodeproj/project.pbxproj"
  "macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme"
  "macos/Runner/Configs/AppInfo.xcconfig"
  "windows/runner/Runner.rc"
  "windows/runner/main.cpp"
  "windows/CMakeLists.txt"
)

if [ -f "${ACTUAL_PUBSPEC}" ]; then
  rm "${ACTUAL_PUBSPEC}"
fi
cp "${T_PUBSPEC}" "${ACTUAL_PUBSPEC}"

if [[ "${BUILD_ISAR_FROM_SOURCE:-0}" -eq 1 ]]; then
    isar_version=$(detect_isar_version)
    enable_isar_source_build "${isar_version}"
    handle_isar_source_build || exit 1
else
    echo "Using prebuilt Isar binaries (pub.dev)"
fi

for TF in "${TEMPLATE_FILES[@]}"; do
  FILE="${APP_PROJECT_ROOT_DIR}/${TF}"
  if [ -f "${FILE}" ]; then
    rm "${FILE}"
  fi
  cp -rp "${TEMPLATES_DIR}/${TF}" "${FILE}"
done
