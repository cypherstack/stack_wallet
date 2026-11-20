#!/usr/bin/env bash
# ==============================================================================
# bench.sh: Simple build benchmark for stack_wallet
#
# Usage:
#   bash bm/bench.sh                    # cold build with sccache (default)
#   bash bm/bench.sh --warm             # warm rebuild (no clean)
#   bash bm/bench.sh SCCACHE=0          # cold, without sccache
#   bash bm/bench.sh SKIP_NATIVE=1      # cold, Dart only
#
# Output: bm/results/<hostname>.csv  (one file per machine, all runs appended)
# ==============================================================================
set -euo pipefail

HOST="$(hostname -s 2>/dev/null || echo unknown)"
OUTDIR="bm/results"
mkdir -p "$OUTDIR"
OUTFILE="${OUTDIR}/${HOST}.csv"

WARM=0
LABEL=""
MAKE_FLAGS=""

# Parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --warm) WARM=1; shift ;;
    --label) LABEL="$2"; shift 2 ;;
    *) MAKE_FLAGS="${MAKE_FLAGS:+${MAKE_FLAGS} }$1"; shift ;;
  esac
done

# Detect platform
case "$(uname -s)" in
  Darwin)  BUILD_TARGET="build-macos" ;;
  Linux)   BUILD_TARGET="build-linux" ;;
  MINGW*|MSYS*|CYGWIN*)
    echo "Git Bash on Windows detected. Benchmarking requires WSL2:"
    echo "  wsl bash bm/bench.sh"
    exit 1
    ;;
  *)       echo "Unknown platform: $(uname -s)"; exit 1 ;;
esac

# Git info
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

# Auto-generate label only if not explicitly set
if [ -z "$LABEL" ]; then
  LABEL=$([ $WARM -eq 1 ] && echo "warm" || echo "cold")
  if echo "$MAKE_FLAGS" | grep -q "SCCACHE=0"; then
    LABEL="${LABEL}-no-sccache"
  elif echo "$MAKE_FLAGS" | grep -q "SCCACHE=1"; then
    LABEL="${LABEL}-sccache"
  fi
  if echo "$MAKE_FLAGS" | grep -q "SKIP_NATIVE=1"; then
    LABEL="${LABEL}-skip-native"
  fi
fi

DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
ARCH="$(uname -m)"
OS_NAME="$(uname -s)"
OS_VER="$(uname -r)"
echo "Benchmark: ${LABEL}" | toilet -f term --metal   
echo "Host: $HOST"
echo "OS: $OS_NAME $OS_VER ($ARCH)"
echo "Branch: $BRANCH"
echo "Commit: $COMMIT"
echo "Target: ${BUILD_TARGET}"
echo "Flags: ${MAKE_FLAGS:-(none)}"
echo ""

# Disk before
DISK_BEFORE=$(du -sk . 2>/dev/null | cut -f1)

# Clean unless warm
if [ $WARM -eq 0 ]; then
  echo "Cleaning" | toilet -f term --metal  
  make clean 2>&1 | tail -1
fi

# Build
echo "Building: make ${BUILD_TARGET} ${MAKE_FLAGS} " | toilet -f term --metal  
START=$(date +%s)
make ${BUILD_TARGET} ${MAKE_FLAGS} 2>&1 | tail -5
RC=$?
END=$(date +%s)
WALL=$((END - START))

# Disk after
DISK_AFTER=$(du -sk . 2>/dev/null | cut -f1)
DISK_DELTA=$((DISK_AFTER - DISK_BEFORE))

# Write CSV header if new file
if [ ! -f "$OUTFILE" ]; then
  echo "label,branch,commit,host,arch,os_name,os_ver,date,warm,flags,wall_sec,success,disk_total_kb,disk_delta_kb,comment" > "$OUTFILE"
fi

echo "${LABEL},${BRANCH},${COMMIT},${HOST},${ARCH},${OS_NAME},${OS_VER},${DATE},${WARM},${MAKE_FLAGS:--},${WALL},$((RC == 0 ? 1 : 0)),${DISK_AFTER},${DISK_DELTA}," >> "$OUTFILE"

echo ""
if [ $RC -eq 0 ]; then
  MIN=$((WALL/60)); SEC=$((WALL%60))
  echo "✓ Build succeeded in ${WALL}s \(${MIN}m ${SEC}s\)"
else
  echo "✗ Build FAILED after ${WALL}s"
fi
echo "Results appended: $OUTFILE" | toilet -f term --metal  

# Show all runs
echo ""
echo "=== All results for $HOST ($ARCH $OS_NAME $OS_VER) ==="
printf "%-12s %-20s %-8s %-10s %4s %10s %8s %s\n" DATE MODE COMMIT FLAGS WARM WALL DISK COMMENT
printf '%s\n' '──────────────────────────────────────────────────────────────────────────────────────'
tail -n +2 "$OUTFILE" | while IFS=, read -r label branch commit host arch os_name os_ver date warm flags wall_sec success disk_total disk_delta comment; do
  delta_mb=$((disk_delta / 1024))
  w=$((wall_sec)); m=$((w/60)); s=$((w%60))
  time_fmt="${m}m${s}s"
  warm_label=$([ "$warm" = "1" ] && echo "yes" || echo "no")
  [ "$success" = "1" ] && ok="✓" || ok="✗"
  printf "%-12s %-20s %-8s %-10s %-4s %10s %8s %s\n" "${date:0:10}" "$label" "${commit:0:7}" "${flags:--}" "$warm_label" "$time_fmt" "$ok ${delta_mb}MB" "$comment"
done
