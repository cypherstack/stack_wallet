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

# Brand identity is selected by `flutter build windows --flavor <brand>` in the
# CMake template.
