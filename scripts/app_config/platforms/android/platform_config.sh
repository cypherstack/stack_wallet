#!/usr/bin/env bash

set -x -e

F0="android/app/build.gradle"
F1="android/app/src/debug/AndroidManifest.xml"
F2="android/app/src/profile/AndroidManifest.xml"
F3="android/app/src/main/AndroidManifest.xml"
F4="android/app/src/main/profile/AndroidManifest.xml"
F5="android/app/src/main/kotlin/com/cypherstack/stackwallet/MainActivity.kt"

TEMPLATES="${APP_PROJECT_ROOT_DIR}/scripts/app_config/templates"

for (( i=0; i<=5; i++ )); do
  VAR="F${i}"
  FILE="${APP_PROJECT_ROOT_DIR}/${!VAR}"
  if [ -f "${FILE}" ]; then
    rm "${FILE}"
  fi
  cp "${TEMPLATES}/${!VAR}" "${FILE}"
done


sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/${F0}"
sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/${F1}"
sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/${F2}"
sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/${F3}"
sed -i "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${F3}"
sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/${F4}"
sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/${F5}"
