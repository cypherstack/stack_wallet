#!/usr/bin/env bash

set -x -e
: "${APP_PROJECT_ROOT_DIR:?APP_PROJECT_ROOT_DIR must be set (run through build_app.sh)}"

if [ $# -ne 2 ]; then
    echo "Usage: $0 <theme specific assets dir name (ex. stack_wallet)> <platform (ex. windows)>"
    exit 1
fi

SELECT_ASSETS_DIR=$1
# $2 (platform) is required by the callers' interface but no longer changes
# behaviour: Windows is detected from the host (uname), not the target.

# declare full paths
ASSET_SOURCES_DIR="${APP_PROJECT_ROOT_DIR}/asset_sources"
ASSETS_DIR="${APP_PROJECT_ROOT_DIR}/assets"

# Windows hosts get real copies: symlink privilege is not guaranteed and the
# asset tree is small. Other hosts use symlinks.
WINDOWS_HOST=0
case "$(uname -s)" in
MINGW*|MSYS*|CYGWIN*) WINDOWS_HOST=1 ;;
esac
for dirname in "default_themes" "icon" "lottie" "in_app_logo_icons" "svg"; do
  LINK_SOURCE_DIR="${ASSET_SOURCES_DIR}/${dirname}/${SELECT_ASSETS_DIR}"

  # Remove an old Windows junction as a link, not by recursing into its target.
  if [[ "${WINDOWS_HOST}" = 1 && -d "${ASSETS_DIR}/${dirname}" ]]; then
    TARGET_WIN_PATH="$(cygpath -w "${ASSETS_DIR}/${dirname}")"
    if ! MSYS2_ARG_CONV_EXCL="/C" cmd.exe /C rmdir "$TARGET_WIN_PATH" 2>/dev/null; then
      # A real copy directory cannot be removed by rmdir; a reparse point must
      # never fall through to rm -rf, which may follow it into asset_sources.
      if MSYS2_ARG_CONV_EXCL="/C" cmd.exe /C fsutil reparsepoint query "$TARGET_WIN_PATH" >/dev/null 2>&1; then
        echo >&2 "[ERROR] cannot remove the Windows junction ${ASSETS_DIR}/${dirname}; remove it manually."
        exit 1
      fi
    fi
  fi
  if [[ "${WINDOWS_HOST}" = 1 ]]; then
    rm -rf "${ASSETS_DIR:?}/${dirname:?}"
  else
    # Only symlinks here: rm -f refuses a real directory instead of deleting it.
    rm -f "${ASSETS_DIR:?}/${dirname:?}"
  fi

  if [[ "${WINDOWS_HOST}" = 1 ]]; then
    mkdir -p "${ASSETS_DIR}/${dirname}"
    cp -r "${LINK_SOURCE_DIR}/." "${ASSETS_DIR}/${dirname}/"
  else
    ln -s "${LINK_SOURCE_DIR}" "${ASSETS_DIR}/${dirname}"
  fi
done
