#!/usr/bin/env bash

set -x -e

# Configure macOS for Duo.
sed -i '' "s/${APP_ID_PLACEHOLDER_CAMEL}/${NEW_APP_ID_CAMEL}/g" "${APP_PROJECT_ROOT_DIR}/macos/Runner.xcodeproj/project.pbxproj"
sed -i '' "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/macos/Runner.xcodeproj/project.pbxproj"
sed -i '' "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme"
sed -i '' "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/macos/Runner/Configs/AppInfo.xcconfig"
sed -i '' "s/${APP_ID_PLACEHOLDER_SNAKE}/${NEW_APP_ID_SNAKE}/g" "${APP_PROJECT_ROOT_DIR}/macos/Runner/Configs/AppInfo.xcconfig"
