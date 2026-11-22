#!/usr/bin/env bash
# Time one `make build-*` run and append a row to bm/results/<host>.csv.
#
#   bash bm/bench.sh                         cold: `make clean`, then build, sccache as configured
#   bash bm/bench.sh --warm                  build again without cleaning
#   bash bm/bench.sh --clean app             `make clean-app` first (keeps .dart_tool/hooks_runner)
#   bash bm/bench.sh --clean native          `make clean-native` first (rebuilds Rust/Go/C libraries)
#   bash bm/bench.sh --sccache off           run without the sccache rustc-wrapper (config restored after)
#   bash bm/bench.sh --sccache on            require it (run `make sccache-setup` first)
#   bash bm/bench.sh --label some-name PREBUILTS=1
#
# Anything else is passed to make. VERSION, BUILD_NUM and CONFIRM=1 get defaults.
# With sccache installed, its hit/miss counters are reset before and read after the build.
set -euo pipefail

clean=full; sccache=keep; label=""; flags=""
while [ $# -gt 0 ]; do
  case "$1" in
    --warm) clean=none ;;
    --clean) clean="$2"; shift ;;
    --sccache) sccache="$2"; shift ;;
    --label) label="$2"; shift ;;
    *) flags="${flags:+$flags }$1" ;;
  esac
  shift
done
case "$clean" in full|app|native|none) ;; *) echo "--clean: full|app|native|none" >&2; exit 2 ;; esac
case "$sccache" in keep|on|off) ;; *) echo "--sccache: on|off|keep" >&2; exit 2 ;; esac
[ -n "$label" ] || label="$clean-sccache-$sccache"

case "$(uname -s)" in
  Darwin) target=build-macos ;;
  Linux) target=build-linux ;;
  *) echo "bench.sh supports macOS and Linux (use WSL2 on Windows)" >&2; exit 1 ;;
esac

# The Makefile needs VERSION and a BUILD_NUM that is not below the latest release
# tag, and build_app.sh asks a question unless CONFIRM=1.
extra=""
case " $flags " in *" VERSION="*) ;; *) extra="$extra VERSION=0.0.0" ;; esac
case " $flags " in
  *" BUILD_NUM="*) ;;
  *)
    tag_num="$(git tag -l 'build_*' --sort=-v:refname 2>/dev/null | sed -n 's/^build_\([0-9][0-9]*\)$/\1/p' | head -n1)"
    extra="$extra BUILD_NUM=${tag_num:-1}"
    ;;
esac
case " $flags " in *" CONFIRM="*) ;; *) extra="$extra CONFIRM=1" ;; esac

# --- sccache on/off. Flutter 3.47.x hooks only see sccache through the rustc-wrapper
# line in the cargo config, so "off" removes that line for this run and a trap puts the
# file back, also when the build crashes.
cargo_cfg="${CARGO_HOME:-$HOME/.cargo}/config.toml"
has_wrapper() { [ -f "$cargo_cfg" ] && grep -q 'rustc-wrapper' "$cargo_cfg"; }
backup=""
restore() { [ -n "$backup" ] && [ -f "$backup" ] && mv "$backup" "$cargo_cfg" && echo "[bench] cargo config restored"; return 0; }
trap restore EXIT
if [ "$sccache" = off ] && has_wrapper; then
  backup="$cargo_cfg.bench.bak"
  cp -p "$cargo_cfg" "$backup"
  grep -v 'rustc-wrapper' "$backup" > "$cargo_cfg"
  echo "[bench] sccache disabled via $cargo_cfg (backup: $backup)"
elif [ "$sccache" = on ] && ! has_wrapper; then
  echo "[bench] --sccache on, but $cargo_cfg has no rustc-wrapper; run: make sccache-setup" >&2
  exit 1
fi
have_sccache=0; command -v sccache >/dev/null 2>&1 && have_sccache=1
[ "$have_sccache" = 1 ] && sccache --zero-stats >/dev/null 2>&1 || true

host="$(hostname -s 2>/dev/null || echo unknown)"
out="bm/results/$host.csv"
mkdir -p bm/results
[ -f "$out" ] || echo "date,label,commit,host,arch,os,clean,sccache,flags,wall_sec,success,disk_delta_kb,cache_hits,cache_misses" > "$out"

case "$clean" in
  full) make clean >/dev/null 2>&1 ;;
  app) make clean-app >/dev/null 2>&1 ;;
  native) make clean-native >/dev/null 2>&1 ;;
esac
disk_kb() { du -sk . 2>/dev/null | cut -f1; }
disk_before="$(disk_kb)"
start="$(date +%s)"

# A failed build is a result too: keep going so the row is written.
set +e
# shellcheck disable=SC2086
make "$target" $flags $extra 2>&1 | tail -n 5
status=${PIPESTATUS[0]}
set -e
wall=$(( $(date +%s) - start ))

hits="-"; misses="-"
if [ "$have_sccache" = 1 ]; then
  stats="$(sccache --show-stats 2>/dev/null || true)"
  hits="$(printf '%s\n' "$stats" | awk '/^Cache hits[[:space:]]+[0-9]+/ {print $3; exit}')"
  misses="$(printf '%s\n' "$stats" | awk '/^Cache misses[[:space:]]+[0-9]+/ {print $3; exit}')"
  hits="${hits:--}"; misses="${misses:--}"
fi

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ),$label,$(git rev-parse --short HEAD 2>/dev/null || echo unknown),$host,$(uname -m),$(uname -s),$clean,$sccache,${flags:--},$wall,$((status == 0)),$(( $(disk_kb) - disk_before )),$hits,$misses" >> "$out"

if [ "$status" = 0 ]; then echo "[bench] ok in ${wall}s (sccache hits/misses: $hits/$misses)"; else echo "[bench] build FAILED after ${wall}s" >&2; fi
exit "$status"
