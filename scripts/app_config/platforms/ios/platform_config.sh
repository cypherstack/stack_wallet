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
