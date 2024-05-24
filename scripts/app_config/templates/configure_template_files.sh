#!/usr/bin/env bash

set -x -e

export TEMPLATES_DIR="${APP_PROJECT_ROOT_DIR}/scripts/app_config/templates"

export T_PUBSPEC="${TEMPLATES_DIR}/pubspec.template"
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

if [ ! -f "${ACTUAL_PUBSPEC}" ]; then
  cp "${T_PUBSPEC}" "${ACTUAL_PUBSPEC}"
fi

for TF in "${TEMPLATE_FILES[@]}"; do
  FILE="${APP_PROJECT_ROOT_DIR}/${TF}"
  if [ ! -f "${FILE}" ]; then
    cp -rp "${TEMPLATES_DIR}/${TF}" "${FILE}"
  fi
done