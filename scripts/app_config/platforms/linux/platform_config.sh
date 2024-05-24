#!/usr/bin/env bash

set -x -e

for (( i=0; i<=1; i++ )); do
  VAR="LINUX_TF_${i}"
  FILE="${APP_PROJECT_ROOT_DIR}/${!VAR}"
  TEMPLATE="${TEMPLATES_DIR}/${!VAR}"
  if cmp -s "${TEMPLATE}" "${FILE}"; then
    rm "${FILE}"
    cp -rp "${TEMPLATE}" "${FILE}"
  fi
done

# Configure Linux for Duo.
sed -i "s/${APP_BASIC_NAME_PLACEHOLDER}/${NEW_BASIC_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${LINUX_TF_0}"
sed -i "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${LINUX_TF_1}"
