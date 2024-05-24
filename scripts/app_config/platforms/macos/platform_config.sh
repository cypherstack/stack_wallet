#!/usr/bin/env bash

set -x -e

for (( i=0; i<=2; i++ )); do
  VAR="MAC_TF_${i}"
  FILE="${APP_PROJECT_ROOT_DIR}/${!VAR}"
  TEMPLATE="${TEMPLATES_DIR}/${!VAR}"
  if cmp -s "${TEMPLATE}" "${FILE}"; then
    rm "${FILE}"
    cp -rp "${TEMPLATE}" "${FILE}"
  fi
done

# Configure macOS for Duo.
sed -i '' "s/${APP_ID_PLACEHOLDER_CAMEL}/${NEW_APP_ID_CAMEL}/g" "${APP_PROJECT_ROOT_DIR}/${MAC_TF_0}"
sed -i '' "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${MAC_TF_0}"
sed -i '' "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${MAC_TF_1}"
sed -i '' "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${MAC_TF_2}"
sed -i '' "s/${APP_ID_PLACEHOLDER_SNAKE}/${NEW_APP_ID_SNAKE}/g" "${APP_PROJECT_ROOT_DIR}/${MAC_TF_2}"
