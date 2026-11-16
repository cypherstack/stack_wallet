#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
work="${EPICMAIL_REGTEST_WORK:-$repo_root/.epicmail-regtest}"
src="$work/src"
runtime="$work/runtime"
pids="$runtime/pids"
password="${EPIC_REGTEST_WALLET_PASSWORD:-local-regtest-only}"
epic="$src/epic/target/release/epic"
wallet="$src/epic-wallet/target/release/epic-wallet"
epicmail="$src/epicmail/target/release/epicmail"

for path in "$epic" "$wallet" "$epicmail"; do
  [[ -x "$path" ]] || {
    printf 'Missing %s; run %s/setup.sh first.\n' "$path" "$script_dir" >&2
    exit 2
  }
done
command -v setsid >/dev/null || {
  printf 'Missing setsid (normally provided by util-linux).\n' >&2
  exit 2
}
mkdir -p "$runtime/node" "$runtime/miner" "$runtime/epicmail" \
  "$runtime/stack-data"
chmod 700 "$runtime/stack-data"
if [[ -f "$pids" ]]; then
  printf 'A PID file already exists at %s. Run stop_services.sh first.\n' "$pids" >&2
  exit 2
fi

declare -a started=()
stop_started() {
  local pid
  for pid in "${started[@]}"; do kill -TERM "$pid" 2>/dev/null || true; done
}
trap stop_started EXIT INT TERM

if [[ ! -f "$runtime/miner/epic-wallet.toml" ]]; then
  umask 077
  (cd "$runtime/miner" && "$wallet" --usernet -p "$password" init -w) \
    > "$runtime/miner-init.log" 2>&1
fi
python3 "$script_dir/configure.py" wallet "$runtime/miner/epic-wallet.toml"

if [[ ! -f "$runtime/node/epic-server.toml" ]]; then
  (cd "$runtime/node" && "$epic" --usernet server config >/dev/null)
fi
python3 "$script_dir/configure.py" node \
  "$runtime/node/epic-server.toml" "$runtime/node" --fund
python3 "$script_dir/configure.py" epicmail \
  "$runtime/epicmail/epicmail.toml" "$runtime/epicmail"

setsid "$epic" --usernet server -c "$runtime/node/epic-server.toml" run \
  > "$runtime/node.log" 2>&1 &
node_pid=$!
started+=("$node_pid")
for _ in $(seq 1 120); do
  curl -fsS http://127.0.0.1:43413/v1/status >/dev/null 2>&1 && break
  if ! kill -0 "$node_pid" 2>/dev/null; then
    tail -n 80 "$runtime/node.log" >&2
    exit 1
  fi
  sleep 0.25
done
curl -fsS http://127.0.0.1:43413/v1/status >/dev/null
start_height="$(curl -fsS http://127.0.0.1:43413/v1/status \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["tip"]["height"])')"
spendable="$("$wallet" --usernet -c "$runtime/miner" -p "$password" info 2>&1 \
  | sed -n 's/.*Currently Spendable[[:space:]]*|[[:space:]]*\([0-9.]*\).*/\1/p' \
  | tail -1)"
if python3 - "$spendable" <<'PY'
from decimal import Decimal, InvalidOperation
import sys
try:
    raise SystemExit(0 if Decimal(sys.argv[1]) > 0 else 1)
except (IndexError, InvalidOperation):
    raise SystemExit(1)
PY
then
  target_height=$start_height
else
  target_height=$((start_height + 20))
fi
setsid "$wallet" --usernet -c "$runtime/miner" -p "$password" listen -m http -n \
  > "$runtime/miner-http.log" 2>&1 &
wallet_http_pid=$!
started+=("$wallet_http_pid")

height=0
for _ in $(seq 1 600); do
  if ! kill -0 "$node_pid" 2>/dev/null; then
    tail -n 80 "$runtime/node.log" >&2
    exit 1
  fi
  height="$(curl -fsS http://127.0.0.1:43413/v1/status 2>/dev/null \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["tip"]["height"])' \
    2>/dev/null || true)"
  [[ "$height" =~ ^[0-9]+$ ]] && (( height >= target_height )) && break
  sleep 1
done
if ! [[ "$height" =~ ^[0-9]+$ ]] || (( height < target_height )); then
  printf 'Epic usernet did not reach the funding target height.\n' >&2
  exit 1
fi

kill -TERM "$wallet_http_pid" 2>/dev/null || true
wait "$wallet_http_pid" 2>/dev/null || true

wallet_info="$("$wallet" --usernet -c "$runtime/miner" -p "$password" info 2>&1)"
spendable="$(printf '%s\n' "$wallet_info" \
  | sed -n 's/.*Currently Spendable[[:space:]]*|[[:space:]]*\([0-9.]*\).*/\1/p' \
  | tail -1)"
python3 - "$spendable" <<'PY'
from decimal import Decimal, InvalidOperation
import sys
try:
    funded = Decimal(sys.argv[1]) > 0
except (IndexError, InvalidOperation):
    funded = False
if not funded:
    raise SystemExit("funding wallet has no spendable balance")
PY

kill -TERM "$node_pid" 2>/dev/null || true
wait "$node_pid" 2>/dev/null || true
started=()

python3 "$script_dir/configure.py" node \
  "$runtime/node/epic-server.toml" "$runtime/node"
setsid "$epic" --usernet server -c "$runtime/node/epic-server.toml" run \
  > "$runtime/node.log" 2>&1 &
node_pid=$!
started+=("$node_pid")
setsid "$epicmail" serve --config "$runtime/epicmail/epicmail.toml" \
  > "$runtime/epicmail.log" 2>&1 &
epicmail_pid=$!
started+=("$epicmail_pid")

for _ in $(seq 1 60); do
  for pid in "$node_pid" "$epicmail_pid"; do
    if ! kill -0 "$pid" 2>/dev/null; then
      tail -n 80 "$runtime/node.log" "$runtime/epicmail.log" >&2
      exit 1
    fi
  done
  if curl -fsS http://127.0.0.1:43420/ready >/dev/null 2>&1 &&
    curl -fsS http://127.0.0.1:43413/v1/status >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done
curl -fsS http://127.0.0.1:43420/ready >/dev/null
curl -fsS http://127.0.0.1:43413/v1/status >/dev/null

# The wallet checks the node before opening its relay connection. Start it only
# after the restarted node is reachable, then require Epicmail to report the
# authenticated subscription and listening mailbox.
: > "$runtime/miner-epicbox.log"
setsid "$wallet" --usernet -c "$runtime/miner" -p "$password" listen -m epicbox -n \
  > "$runtime/miner-epicbox.log" 2>&1 &
wallet_epicbox_pid=$!
started+=("$wallet_epicbox_pid")
for _ in $(seq 1 60); do
  if ! kill -0 "$wallet_epicbox_pid" 2>/dev/null; then
    tail -n 80 "$runtime/miner-epicbox.log" >&2
    exit 1
  fi
  subscribed="$(curl -fsS http://127.0.0.1:43420/status.json 2>/dev/null \
    | python3 -c 'import json,sys; s=json.load(sys.stdin); print(int(s["classic_subscriptions"] >= 1 and s["listening_mailboxes"] >= 1))' \
    2>/dev/null || true)"
  [[ "$subscribed" == 1 ]] && break
  sleep 0.25
done
[[ "${subscribed:-}" == 1 ]] || {
  tail -n 80 "$runtime/miner-epicbox.log" "$runtime/epicmail.log" >&2
  exit 1
}
for pid in "$node_pid" "$epicmail_pid" "$wallet_epicbox_pid"; do
  kill -0 "$pid"
done

printf 'node=%s\nepicmail=%s\nwallet_epicbox=%s\n' \
  "$node_pid" "$epicmail_pid" "$wallet_epicbox_pid" > "$pids"
trap - EXIT INT TERM

printf 'Epic usernet and Epicmail are ready.\n'
printf 'Node:      http://127.0.0.1:43413\n'
printf 'Epicmail:  ws://127.0.0.1:43420\n'
printf 'Miner address:\n'
"$wallet" --usernet -c "$runtime/miner" -p "$password" address \
  | sed -n '/Epicbox address/,/Public Proof Address/p'
printf '\nRun Stack Wallet with:\n'
printf '  flutter run -d linux --dart-define=STACK_EPIC_REGTEST=true -a=-d -a=%q\n' \
  "$runtime/stack-data"
