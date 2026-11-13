#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
work=$(mktemp -d)
manager=''
cleanup() {
  [[ -z "$manager" ]] || kill -KILL "$manager" 2>/dev/null || true
  [[ -z "$manager" ]] || wait "$manager" 2>/dev/null || true
  if [[ -f "$work/pids" ]]; then
    while read -r pid; do kill -KILL "$pid" 2>/dev/null || true; done < "$work/pids"
  fi
  rm -rf "$work"
}
trap cleanup EXIT
cat > "$work/node" <<'FAKE'
#!/usr/bin/env python3
import http.server, json, os, socket, sys, time
with open(os.environ['STATE'] + '/pids', 'a') as f: f.write(str(os.getpid()) + '\n')
if any(x.startswith('-datadir=') for x in sys.argv):
    data = next(x.split('=', 1)[1] for x in sys.argv if x.startswith('-datadir='))
    port = int(next(x.split('=', 1)[1] for x in sys.argv if x.startswith('-rpcport=')))
    os.makedirs(data + '/regtest')
    open(data + '/regtest/.cookie', 'w').write('cookie')
    class Handler(http.server.BaseHTTPRequestHandler):
        def log_message(self, *args): pass
        def do_POST(self):
            if self.headers.get('Transfer-Encoding', '').lower() == 'chunked':
                body = b''
                while True:
                    size = int(self.rfile.readline().strip(), 16)
                    if not size:
                        self.rfile.readline()
                        break
                    body += self.rfile.read(size)
                    self.rfile.read(2)
            else:
                body = self.rfile.read(int(self.headers['Content-Length']))
            req = json.loads(body)
            result = {'getblockcount': 101, 'getnewaddress': 'address'}.get(req['method'], {})
            body = json.dumps({'result': result, 'error': None, 'id': req['id']}).encode()
            self.send_response(200); self.end_headers(); self.wfile.write(body)
            if req['method'] == 'stop': os._exit(0)
    http.server.HTTPServer(('127.0.0.1', port), Handler).serve_forever()
else:
    addr = next(x.split('=', 1)[1] for x in sys.argv if x.startswith('--electrum-rpc-addr='))
    server = socket.socket(); server.bind(('127.0.0.1', int(addr.split(':')[1]))); server.listen()
    open(os.environ['STATE'] + '/indexer-started', 'w').close()
    if os.environ['MODE'] == 'partial':
        while True: time.sleep(1)
    while True:
        conn, _ = server.accept()
        conn.recv(4096)
        conn.sendall(b'{"result":{"height":101},"error":null}\n')
        conn.close()
FAKE
chmod +x "$work/node"
export STATE="$work"
for mode in partial ready; do
  export MODE="$mode"
  rm -f "$work/pids" "$work/indexer-started" "$work/log"
  dart scripts/bitcoin_regtest_nodes.dart --bitcoind "$work/node" --indexer electrs --indexer-path "$work/node" --until-signal > "$work/log" 2>&1 &
  manager=$!
  for _ in $(seq 100); do
    if [[ "$mode" == partial && -f "$work/indexer-started" ]] || grep -q '^REGTEST_READY ' "$work/log" 2>/dev/null; then break; fi
    sleep .1
  done
  if [[ "$mode" == partial ]]; then [[ -f "$work/indexer-started" ]]; else grep -q '^REGTEST_READY ' "$work/log"; fi
  kill -TERM "$manager"
  for _ in $(seq 100); do kill -0 "$manager" 2>/dev/null || break; sleep .1; done
  if kill -0 "$manager" 2>/dev/null; then echo 'manager failed to stop' >&2; exit 1; fi
  wait "$manager" || true
  manager=''
  while read -r pid; do
    if kill -0 "$pid" 2>/dev/null; then echo "node survived $mode shutdown" >&2; exit 1; fi
  done < "$work/pids"
done
echo 'partial-indexer cancellation and normal shutdown reaped both nodes'
