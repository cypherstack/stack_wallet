#!/usr/bin/env bash

set -x -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <theme specific assets dir name (ex. stack_wallet)> <platform (ex. windows)>"
    exit 1
fi

SELECT_ASSETS_DIR=$1
APP_BUILD_PLATFORM=$2

# declare full paths
ASSET_SOURCES_DIR="${APP_PROJECT_ROOT_DIR}/asset_sources"
ASSETS_DIR="${APP_PROJECT_ROOT_DIR}/assets"


remove_asset_entry() {
  local target="$1"
  if [[ "${APP_BUILD_PLATFORM}" = 'windows' ]]; then
    # rm -rf can follow a Windows junction into its target. Remove the link
    # with cmd.exe first and only fall back for a real copied directory.
    local win_path
    if command -v cygpath >/dev/null 2>&1; then
      win_path="$(cygpath -w "$target")"
    elif command -v wslpath >/dev/null 2>&1; then
      win_path="$(wslpath -w "$target")"
    fi
    if [[ -n "${win_path:-}" ]] && cmd.exe /c rmdir "$win_path" >/dev/null 2>&1; then
      return 0
    fi
  fi
  rm -rf "$target"
}

# finally update symlinks

for dirname in "default_themes" "icon" "lottie" "in_app_logo_icons" "svg"; do
  LINK_SOURCE_DIR="${ASSET_SOURCES_DIR}/${dirname}/${SELECT_ASSETS_DIR}"

  # Remove the previous link or the real directory left by a WINDOWS_COPY_ASSETS run.
  remove_asset_entry "${ASSETS_DIR}/${dirname}"

  if [[ "${APP_BUILD_PLATFORM}" = 'windows' && "${WINDOWS_COPY_ASSETS:-0}" = '1' ]]; then
    # Some Windows hosts cannot create symlinks (for example the GitHub-hosted
    # runner user lacks SeCreateSymbolicLinkPrivilege). Copy instead.
    mkdir -p "${ASSETS_DIR}/${dirname}"
    cp -r "${LINK_SOURCE_DIR}/." "${ASSETS_DIR}/${dirname}/"
  elif [[ "${APP_BUILD_PLATFORM}" = 'windows' ]]; then
    if command -v cygpath >/dev/null 2>&1; then
      LINK_SOURCE_DIR_WIN_PATH_VERSION=$(cygpath -w "${LINK_SOURCE_DIR}")
      LINK_NAME_WIN_PATH_VERSION=$(cygpath -w "${ASSETS_DIR}")
    else
      LINK_SOURCE_DIR_WIN_PATH_VERSION=$(wslpath -w "${LINK_SOURCE_DIR}")
      LINK_NAME_WIN_PATH_VERSION=$(wslpath -w "${ASSETS_DIR}")
    fi
    # Keep CMD switches out of Git Bash's path conversion; paths are native above.
    MSYS2_ARG_CONV_EXCL="/C;/D${MSYS2_ARG_CONV_EXCL:+;$MSYS2_ARG_CONV_EXCL}" \
      cmd.exe /C mklink /D "${LINK_NAME_WIN_PATH_VERSION}\\${dirname}" "${LINK_SOURCE_DIR_WIN_PATH_VERSION}"
  else
    ln -s "${LINK_SOURCE_DIR}" "${ASSETS_DIR}/${dirname}"
  fi
done
