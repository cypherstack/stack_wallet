#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
work="${EPICMAIL_REGTEST_WORK:-$repo_root/.epicmail-regtest}"
pids="$work/runtime/pids"
[[ -f "$pids" ]] || { printf 'No running service PID file.\n'; exit 0; }

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

while IFS='=' read -r service pid; do
  if service_owned "$service" "$pid"; then
    kill -TERM "$pid" 2>/dev/null || true
  elif [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
    printf 'Refusing to signal stale/reused %s PID %s.\n' "$service" "$pid" >&2
  fi
done < "$pids"
for _ in $(seq 1 40); do
  alive=0
  while IFS='=' read -r service pid; do
    service_owned "$service" "$pid" && alive=1
  done < "$pids"
  (( alive == 0 )) && break
  sleep 0.25
done
while IFS='=' read -r service pid; do
  if service_owned "$service" "$pid"; then
    kill -KILL "$pid" 2>/dev/null || true
  fi
done < "$pids"
rm -f -- "$pids"
printf 'Epic regtest services stopped; runtime data was retained at %s/runtime.\n' "$work"
