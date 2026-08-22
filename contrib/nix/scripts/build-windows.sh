#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"

grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null || {
    echo "Native Windows builds require WSL." >&2
    exit 69
}
command -v powershell.exe >/dev/null || {
    echo "PowerShell interop is unavailable in WSL." >&2
    exit 69
}

powershell.exe -NoLogo -NoProfile -NonInteractive \
    -ExecutionPolicy Bypass \
    -File "$(wslpath -w "${SCRIPT_DIR}/build-windows.ps1")" \
    -ProjectRoot "$(wslpath -w "$PROJECT_ROOT")"
