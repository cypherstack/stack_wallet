#!/usr/bin/env bash

set -x -e

for (( i=0; i<=5; i++ )); do
  VAR="ANDROID_TF_${i}"
  FILE="${APP_PROJECT_ROOT_DIR}/${!VAR}"
  TEMPLATE="${TEMPLATES_DIR}/${!VAR}"
  if cmp -s "${TEMPLATE}" "${FILE}"; then
    rm "${FILE}"
    cp -rp "${TEMPLATE}" "${FILE}"
  fi
done


sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/${ANDROID_TF_0}"
sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/${ANDROID_TF_1}"
sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/${ANDROID_TF_2}"
sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/${ANDROID_TF_3}"
sed -i "s/${APP_NAME_PLACEHOLDER}/${NEW_NAME}/g" "${APP_PROJECT_ROOT_DIR}/${ANDROID_TF_3}"
sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/${ANDROID_TF_4}"
sed -i "s/${APP_ID_PLACEHOLDER}/${NEW_APP_ID}/g" "${APP_PROJECT_ROOT_DIR}/${ANDROID_TF_5}"
