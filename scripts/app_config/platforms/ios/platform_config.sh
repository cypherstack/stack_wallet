#!/usr/bin/env bash

set -x -e

F0="ios/Runner/Info.plist"
F1="ios/Runner.xcodeproj/project.pbxproj"

TEMPLATES="${APP_PROJECT_ROOT_DIR}/scripts/app_config/templates"

for (( i=0; i<=1; i++ )); do
  VAR="F${i}"
  FILE="${APP_PROJECT_ROOT_DIR}/${!VAR}"
  if [ -f "${FILE}" ]; then
    rm "${FILE}"
  fi
  cp "${TEMPLATES}/${!VAR}" "${FILE}"
done

# Configure ios for Duo.
sed -i '' "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${F0}"
sed -i '' "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/${F1}"
