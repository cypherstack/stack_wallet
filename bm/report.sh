#!/usr/bin/env bash
# Print bm/results/<host>.csv (or the file you pass) as a plain-text table, with each
# run's wall time compared to the first successful run in the file.
#
#   bash bm/report.sh [bm/results/host.csv]
set -euo pipefail

csv="${1:-bm/results/$(hostname -s 2>/dev/null || echo unknown).csv}"
[ -f "$csv" ] || { echo "no results yet: $csv (run bm/bench.sh or bm/matrix.sh)" >&2; exit 1; }

awk -F, '
  NR == 1 { next }
  {
    wall = $10 + 0; ok = $11
    if (ok == 1 && base == 0) base = wall
    delta = (ok == 1 && base > 0) ? sprintf("%+.0f%%", (wall - base) * 100 / base) : "-"
    status = (ok == 1) ? "ok" : "FAILED"
    printf "%-24s %-7s %-7s %6ds %-7s %7s  %s/%s  %s\n", $2, $7, $8, wall, status, delta, $13, $14, $9
  }
  BEGIN { printf "%-24s %-7s %-7s %7s %-7s %7s  %s  %s\n", "label", "clean", "sccache", "wall", "status", "vs 1st", "hits/miss", "flags" }
' "$csv"
