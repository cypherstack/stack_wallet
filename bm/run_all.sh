#!/usr/bin/env bash
# ==============================================================================
# run_all.sh: Cold → warm pairs, ordered from simplest to most optimized.
#
# Run order:
#   A. Cold no-sccache  → clean + build without sccache (baseline)
#   B. Warm no-sccache  → rebuild after A (CARGO_TARGET_DIR benefit only)
#   C. Cold sccache     → clean + build with sccache
#   D. Warm sccache     → rebuild after C (sccache + CARGO_TARGET_DIR benefit)
#   E. Cold Dart-only   → clean + SKIP_NATIVE=1 (no Rust at all)
#   F. Warm Dart-only   → rebuild after E (Flutter incremental)
# ==============================================================================
set -euo pipefail

HOST="$(hostname -s 2>/dev/null || echo unknown)"
figlet "Stack Wallet"

echo "  Full Benchmark Suite"
echo "  Host: $HOST  "
echo "  $(date)"
echo ""

echo "Cold build (no sccache)" | toilet -f term -F border --gay
make clean 2>/dev/null || true
bash bm/bench.sh --label cold-nosccache SCCACHE=0
echo ""

echo "Warm after cold no-sccache (CARGO_TARGET_DIR only)" | toilet -f term -F border --gay
echo "━━━ B: Warm rebuild (no sccache, CARGO_TARGET_DIR cache hit) ━━━"
bash bm/bench.sh --warm --label warm-nosccache SCCACHE=0
echo ""

echo "Cold with sccache" | toilet -f term -F border --gay
make clean 2>/dev/null || true
bash bm/bench.sh --label cold-sccache SCCACHE=1
echo ""

echo "Warm after cold sccache (sccache + target dir)" | toilet -f term -F border --gay
echo "━━━ D: Warm rebuild (sccache + CARGO_TARGET_DIR cache hit) ━━━"
bash bm/bench.sh --warm --label warm-sccache SCCACHE=1
echo ""

echo "Cold build (Dart only, SKIP_NATIVE=1)" | toilet -f term -F border --gay
make clean 2>/dev/null || true
bash bm/bench.sh --label cold-dart-only SKIP_NATIVE=1
echo ""

echo "Warm Dart-only" | toilet -f term -F border --gay
bash bm/bench.sh --warm --label warm-dart-only SKIP_NATIVE=1
echo ""

echo "════════════════════════════════════════════════════"
echo "  Done. Results: bm/results/$HOST.csv"
echo "  View:  python3 bm/compare.py bm/results/"
echo "  PDF:   python3 bm/compare.py bm/results/ > report.md && ./bm/render.sh report.md"
echo "════════════════════════════════════════════════════"
