#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
work="${EPICMAIL_REGTEST_WORK:-$repo_root/.epicmail-regtest}"
runtime="$work/runtime"
src="$work/src"
pids="$runtime/mixed-pids"
password="${EPIC_REGTEST_WALLET_PASSWORD:-local-regtest-only}"
mongo_container="${EPIC_REGTEST_MONGO_CONTAINER:-epicmail-regtest-mongo}"
mongo_image="mongo@sha256:0f64db83d5926400d1cbcbaf35fbf2b0dfa6a4eaa71e04a26481a38cd803b27b"
epic="$src/epic/target/release/epic"
wallet="$src/epic-wallet/target/release/epic-wallet"
epicmail="$src/epicmail/target/release/epicmail"
legacy_src="$src/epicboxnodejs"

for command in docker openssl setsid curl node python3; do
  command -v "$command" >/dev/null || {
    printf 'Missing required command: %s\n' "$command" >&2
    exit 2
  }
done
for path in "$epic" "$wallet" "$epicmail" \
  "$legacy_src/app_mongo.js" "$legacy_src/node_modules"; do
  [[ -e "$path" ]] || {
    printf 'Missing %s; run %s/setup.sh first.\n' "$path" "$script_dir" >&2
    exit 2
  }
done
[[ ! -f "$runtime/pids" ]] || {
  printf 'Standard services are still running; run stop_services.sh first.\n' >&2
  exit 2
}
[[ ! -f "$pids" ]] || {
  printf 'Mixed-service PID file already exists: %s\n' "$pids" >&2
  exit 2
}
if docker container inspect "$mongo_container" >/dev/null 2>&1; then
  printf 'Docker container already exists: %s\n' "$mongo_container" >&2
  exit 2
fi
[[ -f "$runtime/node/epic-server.toml" && -f "$runtime/miner/epic-wallet.toml" ]] || {
  printf 'Run run_services.sh once to create and fund the test chain, then stop it.\n' >&2
  exit 2
}

mkdir -p "$runtime/legacy-wallet" "$runtime/epicmail" "$runtime/mongo"
if [[ ! -f "$runtime/legacy-wallet/epic-wallet.toml" ]]; then
  umask 077
  (cd "$runtime/legacy-wallet" && "$wallet" --usernet -p "$password" init -w) \
    > "$runtime/legacy-init.log" 2>&1
fi
python3 "$script_dir/configure.py" node \
  "$runtime/node/epic-server.toml" "$runtime/node"
python3 "$script_dir/configure.py" wallet \
  "$runtime/miner/epic-wallet.toml" --relay-port 43420 --no-relay-unsecure
python3 "$script_dir/configure.py" wallet \
  "$runtime/legacy-wallet/epic-wallet.toml" --api-port 43416 \
  --relay-port 43421 --relay-unsecure
python3 "$script_dir/configure.py" epicmail-mixed \
  "$runtime/epicmail/mixed.toml" "$runtime/epicmail"
python3 "$script_dir/configure.py" legacy \
  "$runtime/legacy-epicbox.json" "$legacy_src"
openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
  -keyout "$runtime/tls.key" -out "$runtime/tls.crt" \
  -subj /CN=127.0.0.1 -addext subjectAltName=IP:127.0.0.1 \
  >/dev/null 2>&1

declare -a started=()
mongo_started=0
cleanup() {
  local pid
  for pid in "${started[@]}"; do kill -TERM "$pid" 2>/dev/null || true; done
  if ((mongo_started)); then docker stop "$mongo_container" >/dev/null 2>&1 || true; fi
}
trap cleanup EXIT INT TERM

docker run --rm -d --name "$mongo_container" \
  -p 127.0.0.1:27019:27017 \
  --mount "type=bind,src=$runtime/mongo,dst=/data/db" \
  "$mongo_image" >/dev/null
mongo_started=1
for _ in $(seq 1 120); do
  docker exec "$mongo_container" mongosh --quiet --eval \
    'quit(db.adminCommand({ping:1}).ok ? 0 : 1)' >/dev/null 2>&1 && break
  sleep 0.25
done
docker exec "$mongo_container" mongosh --quiet --eval \
  'quit(db.adminCommand({ping:1}).ok ? 0 : 1)' >/dev/null

setsid "$epic" --usernet server -c "$runtime/node/epic-server.toml" run \
  > "$runtime/mixed-node.log" 2>&1 &
node_pid=$!
started+=("$node_pid")
setsid "$epicmail" serve --config "$runtime/epicmail/mixed.toml" \
  > "$runtime/mixed-epicmail.log" 2>&1 &
epicmail_pid=$!
started+=("$epicmail_pid")
setsid env EPICMAIL_CERT_DIR="$runtime" node "$script_dir/tls_proxy.js" \
  > "$runtime/mixed-proxy.log" 2>&1 &
proxy_pid=$!
started+=("$proxy_pid")
(cd "$legacy_src" && exec setsid env NODE_TLS_REJECT_UNAUTHORIZED=0 \
  node app_mongo.js --config "$runtime/legacy-epicbox.json") \
  > "$runtime/mixed-legacy.log" 2>&1 &
legacy_pid=$!
started+=("$legacy_pid")

for _ in $(seq 1 120); do
  for pid in "$node_pid" "$epicmail_pid" "$proxy_pid" "$legacy_pid"; do
    kill -0 "$pid" 2>/dev/null || {
      tail -n 100 "$runtime"/mixed-*.log >&2
      exit 1
    }
  done
  if curl -fsS http://127.0.0.1:43413/v1/status >/dev/null 2>&1 &&
    curl -fsS http://127.0.0.1:43422/ready >/dev/null 2>&1 &&
    curl --cacert "$runtime/tls.crt" -fsS \
      https://127.0.0.1:43420/ready >/dev/null 2>&1 &&
    grep -q 'Epicbox ready to work' "$runtime/mixed-legacy.log"; then
    break
  fi
  sleep 0.25
done
curl -fsS http://127.0.0.1:43413/v1/status >/dev/null
curl -fsS http://127.0.0.1:43422/ready >/dev/null
curl --cacert "$runtime/tls.crt" -fsS https://127.0.0.1:43420/ready >/dev/null
grep -q 'Epicbox ready to work' "$runtime/mixed-legacy.log"

setsid env SSL_CERT_FILE="$runtime/tls.crt" "$wallet" --usernet \
  -c "$runtime/miner" -p "$password" listen -m epicbox -n \
  > "$runtime/mixed-miner-listener.log" 2>&1 &
miner_wallet_pid=$!
started+=("$miner_wallet_pid")
setsid "$wallet" --usernet -c "$runtime/legacy-wallet" -p "$password" \
  listen -m epicbox -n > "$runtime/mixed-legacy-wallet.log" 2>&1 &
legacy_wallet_pid=$!
started+=("$legacy_wallet_pid")

subscribed=0
legacy_subscribed=0
for _ in $(seq 1 120); do
  kill -0 "$miner_wallet_pid" 2>/dev/null || exit 1
  kill -0 "$legacy_wallet_pid" 2>/dev/null || exit 1
  subscribed="$(curl -fsS http://127.0.0.1:43422/status.json 2>/dev/null \
    | python3 -c 'import json,sys; s=json.load(sys.stdin); print(int(s["classic_subscriptions"] >= 1 and s["listening_mailboxes"] >= 1))' \
    2>/dev/null || true)"
  legacy_subscribed="$(curl --max-time 8 -fsS http://127.0.0.1:43421/ \
    2>/dev/null | sed -n 's/.*subscribes: \([0-9][0-9]*\).*/\1/p' \
    | head -1 || true)"
  if [[ "$subscribed" == 1 && "${legacy_subscribed:-0}" -ge 1 ]]; then
    break
  fi
  sleep 0.25
done
[[ "$subscribed" == 1 ]] || exit 1
[[ "${legacy_subscribed:-0}" -ge 1 ]] || exit 1

printf 'node=%s\nepicmail=%s\ntls_proxy=%s\nlegacy=%s\nminer_wallet=%s\nlegacy_wallet=%s\n' \
  "$node_pid" "$epicmail_pid" "$proxy_pid" "$legacy_pid" \
  "$miner_wallet_pid" "$legacy_wallet_pid" > "$pids"
trap - EXIT INT TERM

printf 'Mixed Epicmail/legacy environment is ready.\n'
printf 'Epicmail identity: 127.0.0.1:43420 (TLS proxy to 43422)\n'
printf 'Legacy identity:   127.0.0.1:43421\n'
printf '\nEpicmail wallet address:\n'
"$wallet" --usernet -c "$runtime/miner" -p "$password" address \
  | sed -n '/Epicbox address/,/Public Proof Address/p'
printf '\nLegacy wallet address:\n'
"$wallet" --usernet -c "$runtime/legacy-wallet" -p "$password" address \
  | sed -n '/Epicbox address/,/Public Proof Address/p'
