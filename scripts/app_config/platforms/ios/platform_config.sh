#!/usr/bin/env bash

set -x -e

# Configure ios for Duo.
sed -i '' "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/ios/Runner/Info.plist"
sed -i '' "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/ios/Runner.xcodeproj/project.pbxproj"
