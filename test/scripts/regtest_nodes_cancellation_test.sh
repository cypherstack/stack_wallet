#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
work=$(mktemp -d)
manager=''
child=''
cleanup() {
  [[ -z "$manager" ]] || kill -KILL "$manager" 2>/dev/null || true
  [[ -z "$manager" ]] || wait "$manager" 2>/dev/null || true
  [[ -z "$child" ]] || kill -KILL "$child" 2>/dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT
cat > "$work/bitcoind" <<'FAKE'
#!/usr/bin/env python3
import os, socket, sys, time
open(os.environ['STATE'] + '/child.pid', 'w').write(str(os.getpid()))
if os.environ['MODE'] == 'hung-rpc':
    data = next(x.split('=', 1)[1] for x in sys.argv if x.startswith('-datadir='))
    port = int(next(x.split('=', 1)[1] for x in sys.argv if x.startswith('-rpcport=')))
    os.makedirs(data + '/regtest')
    open(data + '/regtest/.cookie', 'w').write('cookie')
    server = socket.socket()
    server.bind(('127.0.0.1', port))
    server.listen()
    conn, _ = server.accept()
    open(os.environ['STATE'] + '/rpc-connected', 'w').close()
while True:
    time.sleep(1)
FAKE
chmod +x "$work/bitcoind"
export STATE="$work"
for mode in signal hung-rpc; do
  export MODE="$mode"
  rm -f "$work/child.pid" "$work/rpc-connected" "$work/stop"
  args=(--until-signal)
  [[ "$mode" != hung-rpc ]] || args=(--stop-file "$work/stop")
  dart scripts/bitcoin_regtest_nodes.dart --bitcoind "$work/bitcoind" --indexer electrs --indexer-path "$work/bitcoind" "${args[@]}" > "$work/log" 2>&1 &
  manager=$!
  marker="$work/child.pid"
  [[ "$mode" != hung-rpc ]] || marker="$work/rpc-connected"
  for _ in $(seq 100); do [[ -f "$marker" ]] && break; sleep .1; done
  [[ -f "$marker" ]] || { cat "$work/log"; exit 1; }
  child=$(cat "$work/child.pid")
  if [[ "$mode" == signal ]]; then kill -TERM "$manager"; else touch "$work/stop"; fi
  for _ in $(seq 100); do kill -0 "$manager" 2>/dev/null || break; sleep .1; done
  if kill -0 "$manager" 2>/dev/null; then echo 'manager failed to stop' >&2; exit 1; fi
  wait "$manager" || true
  manager=''
  if kill -0 "$child" 2>/dev/null; then
    echo "child survived $mode startup cancellation" >&2; exit 1
  fi
  child=''
done
echo 'signal and stop-file cancellation reaped children during startup and hung RPC'
