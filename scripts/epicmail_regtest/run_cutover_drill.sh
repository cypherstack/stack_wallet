#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
work="${EPICMAIL_REGTEST_WORK:-$repo_root/.epicmail-regtest}"
runtime="$work/runtime"
src="$work/src"
password="${EPIC_REGTEST_WALLET_PASSWORD:-local-regtest-only}"
amount="${EPIC_CUTOVER_AMOUNT:-0.013}"
mongo_container="${EPIC_REGTEST_MONGO_CONTAINER:-epicmail-regtest-mongo}"
wallet="$src/epic-wallet/target/release/epic-wallet"
epicmail="$src/epicmail/target/release/epicmail"
mixed_pids="$runtime/mixed-pids"
run_id="${EPIC_CUTOVER_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)-$$}"
evidence="$runtime/cutover-$run_id"
cutover_pid=""
cutover_wallet_pid=""
mixed_started=0

for command in docker python3 setsid curl; do
  command -v "$command" >/dev/null || {
    printf 'Missing required command: %s\n' "$command" >&2
    exit 2
  }
done
for path in "$wallet" "$epicmail"; do
  [[ -x "$path" ]] || {
    printf 'Missing %s; run %s/setup.sh first.\n' "$path" "$script_dir" >&2
    exit 2
  }
done
[[ ! -e "$evidence" ]] || {
  printf 'Cutover evidence directory already exists: %s\n' "$evidence" >&2
  exit 2
}
mkdir -p "$evidence"

process_owned() {
  local kind="$1" pid="$2" expected marker
  case "$kind" in
    legacy)
      expected="$(command -v node)"
      marker="$runtime/legacy-epicbox.json"
      ;;
    legacy_wallet | cutover_wallet)
      expected="$wallet"
      marker="$runtime/legacy-wallet"
      ;;
    cutover)
      expected="$epicmail"
      marker="$evidence/epicmail.toml"
      ;;
    *) return 1 ;;
  esac
  [[ "$pid" =~ ^[0-9]+$ && -e "/proc/$pid/exe" ]] || return 1
  [[ "$(readlink -f "/proc/$pid/exe")" == "$(readlink -f "$expected")" ]] || return 1
  grep -Fzq -- "$marker" "/proc/$pid/cmdline"
}

stop_owned() {
  local kind="$1" pid="$2"
  process_owned "$kind" "$pid" || {
    printf 'Refusing to stop unowned %s PID %s.\n' "$kind" "$pid" >&2
    return 1
  }
  kill -TERM "$pid"
  for _ in $(seq 1 40); do
    process_owned "$kind" "$pid" || return 0
    sleep 0.25
  done
  if process_owned "$kind" "$pid"; then
    kill -KILL "$pid"
  fi
  for _ in $(seq 1 40); do
    process_owned "$kind" "$pid" || return 0
    sleep 0.25
  done
  printf '%s PID %s did not stop.\n' "$kind" "$pid" >&2
  return 1
}

cleanup() {
  local status=$?
  trap - EXIT INT TERM
  if [[ -n "$cutover_wallet_pid" ]] &&
    process_owned cutover_wallet "$cutover_wallet_pid"; then
    stop_owned cutover_wallet "$cutover_wallet_pid" || true
  fi
  if [[ -n "$cutover_pid" ]] && process_owned cutover "$cutover_pid"; then
    stop_owned cutover "$cutover_pid" || true
  fi
  if ((mixed_started)); then
    bash "$script_dir/stop_mixed_services.sh" || true
  fi
  if ((status != 0)); then
    printf 'Cutover drill failed; evidence retained at %s\n' "$evidence" >&2
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

[[ ! -f "$mixed_pids" ]] || {
  printf 'Mixed services are already running; stop them before this drill.\n' >&2
  exit 2
}
bash "$script_dir/run_mixed_services.sh" > "$evidence/start.log"
mixed_started=1
[[ -f "$mixed_pids" ]]
docker inspect "$mongo_container" >/dev/null

legacy_pid="$(sed -n 's/^legacy=//p' "$mixed_pids")"
legacy_wallet_pid="$(sed -n 's/^legacy_wallet=//p' "$mixed_pids")"
process_owned legacy "$legacy_pid"
process_owned legacy_wallet "$legacy_wallet_pid"

waiting_count() {
  "$script_dir/docker_mongosh.sh" --quiet \
    mongodb://127.0.0.1:27017/epicbox_regtest \
    --eval 'print(db.slates.countDocuments({made:false}))'
}

before="$(waiting_count)"
[[ "$before" == 0 ]] || {
  printf 'Legacy Mongo queue was not empty at drill start (%s rows).\n' "$before" >&2
  exit 1
}
stop_owned legacy_wallet "$legacy_wallet_pid"

legacy_address="$("$wallet" --usernet -c "$runtime/legacy-wallet" \
  -p "$password" address \
  | sed -n 's/^\([1-9A-HJ-NP-Za-km-z]\{52\}\)@.*/\1/p' | head -1)"
[[ "$legacy_address" =~ ^[1-9A-HJ-NP-Za-km-z]{52}$ ]]
miner_log_size="$(stat -c %s "$runtime/mixed-miner-listener.log")"
SSL_CERT_FILE="$runtime/tls.crt" TERM=xterm-256color "$wallet" --usernet \
  -c "$runtime/miner" -p "$password" send "$amount" -m epicbox \
  -d "$legacy_address@127.0.0.1:43421" -f \
  > "$evidence/send.log" 2>&1

after="$(waiting_count)"
[[ "$after" == 1 ]] || {
  printf 'Expected one queued Mongo slate, found %s.\n' "$after" >&2
  exit 1
}
stop_owned legacy "$legacy_pid"

python3 "$src/epicmail/tools/export-node-mongo.py" \
  --mongosh "$script_dir/docker_mongosh.sh" \
  --uri mongodb://127.0.0.1:27017 --db epicbox_regtest \
  > "$evidence/legacy-waiting.jsonl" 2> "$evidence/export.log"
exported="$(wc -l < "$evidence/legacy-waiting.jsonl")"
[[ "$exported" == 1 ]] || {
  printf 'Expected one exported slate, found %s.\n' "$exported" >&2
  exit 1
}
python3 - "$evidence/legacy-waiting.jsonl" <<'PY'
import json
import sys
from pathlib import Path

rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines()]
if len(rows) != 1 or rows[0].get("kind") != "slate":
    raise SystemExit("export is not exactly one slate")
PY

python3 "$script_dir/configure.py" epicmail-cutover \
  "$evidence/epicmail.toml" "$evidence"
[[ ! -e "$evidence/epicmail-cutover.db" ]]
"$epicmail" import --config "$evidence/epicmail.toml" \
  "$evidence/legacy-waiting.jsonl" > "$evidence/import-first.json"
"$epicmail" import --config "$evidence/epicmail.toml" \
  "$evidence/legacy-waiting.jsonl" > "$evidence/import-repeat.json"
python3 - "$evidence/import-first.json" "$evidence/import-repeat.json" <<'PY'
import json
import sys
from pathlib import Path

first, repeat = (json.loads(Path(p).read_text()) for p in sys.argv[1:])
if first.get("slates") != 1 or first.get("duplicates") != 0:
    raise SystemExit(f"unexpected first import result: {first}")
if repeat.get("slates") != 0 or repeat.get("duplicates") != 1:
    raise SystemExit(f"repeat import was not idempotent: {repeat}")
for result in (first, repeat):
    if result.get("skipped") or result.get("expired") or result.get("errors"):
        raise SystemExit(f"import was not clean: {result}")
PY

setsid "$epicmail" serve --config "$evidence/epicmail.toml" \
  > "$evidence/epicmail.log" 2>&1 &
cutover_pid=$!
for _ in $(seq 1 120); do
  process_owned cutover "$cutover_pid" || {
    tail -n 100 "$evidence/epicmail.log" >&2
    exit 1
  }
  curl -fsS http://127.0.0.1:43421/ready >/dev/null 2>&1 && break
  sleep 0.25
done
curl -fsS http://127.0.0.1:43421/ready >/dev/null

setsid "$wallet" --usernet -c "$runtime/legacy-wallet" -p "$password" \
  listen -m epicbox -n > "$evidence/legacy-wallet.log" 2>&1 &
cutover_wallet_pid=$!

completed=0
for _ in $(seq 1 240); do
  process_owned cutover "$cutover_pid" || exit 1
  process_owned cutover_wallet "$cutover_wallet_pid" || exit 1
  new_sender_log="$(tail -c +$((miner_log_size + 1)) \
    "$runtime/mixed-miner-listener.log")"
  if grep -q 'acked.*transport="classic"' "$evidence/epicmail.log" &&
    grep -q 'result="forwarded"' "$evidence/epicmail.log" &&
    grep -q 'Receive new transaction' "$evidence/legacy-wallet.log" &&
    grep -q 'finalized successfully' <<<"$new_sender_log"; then
    completed=1
    break
  fi
  sleep 0.25
done
[[ "$completed" == 1 ]] || {
  tail -n 100 "$evidence/epicmail.log" \
    "$evidence/legacy-wallet.log" "$runtime/mixed-miner-listener.log" >&2
  exit 1
}

for _ in $(seq 1 80); do
  empty="$(curl -fsS http://127.0.0.1:43421/status.json \
    | python3 -c 'import json,sys; s=json.load(sys.stdin)["store"]; print(int(s["messages_waiting"] == 0 and s["forwards_waiting"] == 0))')"
  [[ "$empty" == 1 ]] && break
  sleep 0.25
done
[[ "$empty" == 1 ]]
TERM=xterm-256color "$wallet" --usernet -c "$runtime/miner" \
  -p "$password" txs > "$evidence/sender-txs.log" 2>&1
grep -F "$legacy_address@127.0.0.1:43421" "$evidence/sender-txs.log" \
  | grep -Eq 'Sent \(Mempool\)|Sent[[:space:]]'

printf 'Mongo-to-SQLite cutover completed a real wallet transaction.\n'
printf 'Evidence: %s\n' "$evidence"
