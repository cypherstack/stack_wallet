#!/usr/bin/env bash
# Run the standard cache comparison one scenario after another and print the report.
# Takes about an hour on a laptop (several full builds). Extra arguments go to every run,
# for example `bash bm/matrix.sh PREBUILTS=1`.
#
#   1  cold, no sccache        the baseline
#   2  warm, no sccache        rebuild with nothing cleaned (Flutter's own caches only)
#   3  cold, sccache           first run fills the cache; needs `make sccache-setup`
#   4  warm, sccache           same, nothing cleaned
#   5  clean-app, sccache      build/ and Pods removed, hooks_runner kept
#   6  clean-native, sccache   native libraries rebuilt, everything else kept (sccache hits)
set -uo pipefail

run() { echo "=== $1"; shift; bash bm/bench.sh "$@" || echo "(run failed, continuing)"; }

run "1/6 cold, no sccache"      --label cold-nosccache   --clean full   --sccache off "$@"
run "2/6 warm, no sccache"      --label warm-nosccache   --clean none   --sccache off "$@"
run "3/6 cold, sccache"         --label cold-sccache     --clean full   --sccache on  "$@"
run "4/6 warm, sccache"         --label warm-sccache     --clean none   --sccache on  "$@"
run "5/6 clean-app, sccache"    --label cleanapp-sccache --clean app    --sccache on  "$@"
run "6/6 clean-native, sccache" --label cleannative-sccache --clean native --sccache on "$@"

echo
bash bm/report.sh
