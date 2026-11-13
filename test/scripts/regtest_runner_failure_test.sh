#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
work=$(mktemp -d)
cleanup() {
  if [[ -f "$work/pids" ]]; then
    while read -r pid; do kill "$pid" 2>/dev/null || true; done < "$work/pids"
  fi
  rm -rf "$work"
}
trap cleanup EXIT
mkdir "$work/bin"
cat > "$work/bin/flutter" <<'FAKE'
#!/usr/bin/env bash
exit 0
FAKE
cat > "$work/bin/dart" <<'FAKE'
#!/usr/bin/env bash
cp "$FAKE_MANAGER" "$5"
chmod +x "$5"
FAKE
cat > "$work/bin/sleep" <<'FAKE'
#!/usr/bin/env bash
/bin/sleep .001
FAKE
cat > "$work/manager" <<'FAKE'
#!/usr/bin/env bash
if [[ -f "$STATE/current" ]] && kill -0 "$(cat "$STATE/current")" 2>/dev/null; then
  echo overlap >> "$STATE/errors"
fi
echo $$ >> "$STATE/pids"
echo $$ > "$STATE/current"
trap 'exit 0' TERM
while :; do /bin/sleep .01; done
FAKE
chmod +x "$work/bin/"* "$work/manager"
export PATH="$work/bin:$PATH" STATE="$work" FAKE_MANAGER="$work/manager"
export FLUTTER_BIN="$work/bin/flutter" BITCOIND="$work/manager" ELECTRS="$work/manager" REGTEST_HOST_NODES=1
if bash scripts/test_bitcoin_regtest.sh linux > "$work/log" 2>&1; then
  echo 'runner unexpectedly succeeded' >&2; exit 1
fi
if [[ -f "$work/errors" ]]; then cat "$work/errors" >&2; exit 1; fi
[[ $(grep -c '^== ' "$work/log") -gt 1 ]] || { cat "$work/log"; exit 1; }
echo 'runner cleaned up each failed startup before advancing'
