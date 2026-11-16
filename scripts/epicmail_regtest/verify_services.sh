#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
work="${EPICMAIL_REGTEST_WORK:-$repo_root/.epicmail-regtest}"
password="${EPIC_REGTEST_WALLET_PASSWORD:-local-regtest-only}"
pids="$work/runtime/pids"

service_owned() {
  local service="$1" pid="$2" expected marker
  case "$service" in
    node)
      expected="$work/src/epic/target/release/epic"
      marker="$work/runtime/node/epic-server.toml"
      ;;
    epicmail)
      expected="$work/src/epicmail/target/release/epicmail"
      marker="$work/runtime/epicmail/epicmail.toml"
      ;;
    wallet_epicbox)
      expected="$work/src/epic-wallet/target/release/epic-wallet"
      marker="$work/runtime/miner"
      ;;
    *) return 1 ;;
  esac
  [[ "$pid" =~ ^[0-9]+$ && -e "/proc/$pid/exe" ]] || return 1
  [[ "$(readlink -f "/proc/$pid/exe")" == "$(readlink -f "$expected")" ]] || return 1
  grep -Fzq -- "$marker" "/proc/$pid/cmdline"
}

[[ -f "$pids" ]] || {
  printf 'No service PID file at %s; run run_services.sh first.\n' "$pids" >&2
  exit 2
}
while IFS='=' read -r service pid; do
  service_owned "$service" "$pid" || {
    printf '%s service is not running (PID %s).\n' "$service" "$pid" >&2
    exit 1
  }
done < "$pids"
curl -fsS http://127.0.0.1:43420/status.json \
  | python3 -c '
import json, sys
s = json.load(sys.stdin)
if s["classic_subscriptions"] < 1 or s["listening_mailboxes"] < 1:
    raise SystemExit("wallet has no authenticated Epicmail subscription")
'

python3 "$work/src/epicmail/tools/ship-probe.py" \
  http://127.0.0.1:43420 --landing
curl -fsS http://127.0.0.1:43413/v1/status \
  | python3 -m json.tool
"$work/src/epic-wallet/target/release/epic-wallet" \
  --usernet -c "$work/runtime/miner" -p "$password" info
