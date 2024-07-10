#!/usr/bin/env bash

set -x -e

for (( i=0; i<=1; i++ )); do
  VAR="IOS_TF_${i}"
  FILE="${APP_PROJECT_ROOT_DIR}/${!VAR}"
  TEMPLATE="${TEMPLATES_DIR}/${!VAR}"
  if cmp -s "${TEMPLATE}" "${FILE}"; then
    rm "${FILE}"
    cp -rp "${TEMPLATE}" "${FILE}"
  fi
done

# Configure ios for Duo.
sed -i '' "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${IOS_TF_0}"
sed -i '' "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/${IOS_TF_1}"

# use app specific launch images
LAUNCH_IMAGES_DIR="${APP_PROJECT_ROOT_DIR}/ios/Runner/Assets.xcassets/LaunchImage.imageset"
for file in "${LAUNCH_IMAGES_DIR}"/*.png;
do
  # Check if the file exists to avoid errors if no PNG files are found
  if [ -f "${file}" ]; then
    rm "${file}"
  fi
done

LAUNCH_IMAGES_TEMPLATES_DIR="${APP_PROJECT_ROOT_DIR}/asset_sources/other/ios_launch_image/${NEW_BASIC_NAME}"
for file in "${LAUNCH_IMAGES_TEMPLATES_DIR}"/*.png;
do
  # Check if the file exists to avoid errors if no PNG files are found
  if [ -f "${file}" ]; then
    cp "${file}" "${LAUNCH_IMAGES_DIR}/"
  fi
done