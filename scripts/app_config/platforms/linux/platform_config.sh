#!/usr/bin/env bash

set -x -e

F0="linux/CMakeLists.txt"
F1="linux/my_application.cc"

TEMPLATES="${APP_PROJECT_ROOT_DIR}/scripts/app_config/templates"

for (( i=0; i<=1; i++ )); do
  VAR="F${i}"
  FILE="${APP_PROJECT_ROOT_DIR}/${!VAR}"
  if [ -f "${FILE}" ]; then
    rm "${FILE}"
  fi
  cp "${TEMPLATES}/${!VAR}" "${FILE}"
done

# Configure Linux for Duo.
sed -i "s/${APP_BASIC_NAME_PLACEHOLDER}/${NEW_BASIC_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${F0}"
sed -i "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${F1}"
