#!/usr/bin/env bash

set -x -e

sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/android/app/build.gradle"
sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/android/app/src/debug/AndroidManifest.xml"
sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/android/app/src/profile/AndroidManifest.xml"
sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/android/app/src/main/AndroidManifest.xml"
sed -i "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/android/app/src/main/AndroidManifest.xml"
sed -i "s/${ORIGINAL_APP_ID}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/android/app/src/main/profile/AndroidManifest.xml"
sed -i "s/${ORIGINAL_APP_ID}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/android/app/src/main/kotlin/com/cypherstack/stackwallet/MainActivity.kt"
