#!/usr/bin/env bash
# ==============================================================================
# run_all.sh: Benchmark suite for `make build-macos`.
#
# Run order (cold = after `make clean`, warm = rebuild right after):
#   A. Cold, prebuilt native assets (default)
#   B. Warm, prebuilt native assets
#   C. Cold, native assets compiled from source (PREBUILTS=0)
#   D. Warm, native assets compiled from source
#
# sccache is a machine setting: run the suite once as is, then run
# `make sccache-setup` and run it again; the label records which one it was.
# ==============================================================================
set -euo pipefail

HOST="$(hostname -s 2>/dev/null || echo unknown)"
echo "Stack Wallet full benchmark suite"
echo "Host: $HOST  $(date)"
echo ""

echo "A: cold, prebuilt"
make clean 2>/dev/null || true
bash bm/bench.sh
echo ""

echo "B: warm, prebuilt"
bash bm/bench.sh --warm
echo ""

echo "C: cold, from source"
make clean 2>/dev/null || true
bash bm/bench.sh PREBUILTS=0
echo ""

echo "D: warm, from source"
bash bm/bench.sh --warm PREBUILTS=0
echo ""

echo "Collecting disk and artifact sizes..."
bash bm/collect.sh || true
echo ""
echo "Done. Results: bm/results/$HOST.csv"
echo "View: python3 bm/compare.py bm/results/"
echo "PDF:  python3 bm/compare.py bm/results/ > report.md && ./bm/render.sh report.md"
