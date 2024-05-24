#!/usr/bin/env bash

set -x -e

for (( i=0; i<=2; i++ )); do
  VAR="WIN_TF_${i}"
  FILE="${APP_PROJECT_ROOT_DIR}/${!VAR}"
  TEMPLATE="${TEMPLATES_DIR}/${!VAR}"
  if cmp -s "${TEMPLATE}" "${FILE}"; then
    rm "${FILE}"
    cp -rp "${TEMPLATE}" "${FILE}"
  fi
done

# Configure Windows for Duo.
sed -i "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${WIN_TF_0}"
sed -i "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${WIN_TF_1}"
sed -i "s/${APP_BASIC_NAME_PLACEHOLDER}/${NEW_BASIC_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${WIN_TF_2}"
