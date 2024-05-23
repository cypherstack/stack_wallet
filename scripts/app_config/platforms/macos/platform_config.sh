#!/usr/bin/env bash

set -x -e

F0="macos/Runner.xcodeproj/project.pbxproj"
F1="macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme"
F2="macos/Runner/Configs/AppInfo.xcconfig"

TEMPLATES="${APP_PROJECT_ROOT_DIR}/scripts/app_config/templates"

for (( i=0; i<=2; i++ )); do
  VAR="F${i}"
  FILE="${APP_PROJECT_ROOT_DIR}/${!VAR}"
  if [ -f "${FILE}" ]; then
    rm "${FILE}"
  fi
  cp "${TEMPLATES}/${!VAR}" "${FILE}"
done

# Configure macOS for Duo.
sed -i '' "s/${APP_ID_PLACEHOLDER_CAMEL}/${NEW_APP_ID_CAMEL}/g" "${APP_PROJECT_ROOT_DIR}/${F0}"
sed -i '' "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${F0}"
sed -i '' "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${F1}"
sed -i '' "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${F2}"
sed -i '' "s/${APP_ID_PLACEHOLDER_SNAKE}/${NEW_APP_ID_SNAKE}/g" "${APP_PROJECT_ROOT_DIR}/${F2}"
