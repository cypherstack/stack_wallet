# Epicmail regtest and compatibility harness

This branch adds a local-only Epic usernet and Epicmail harness for exercising
Stack Wallet's real Epic wallet implementation. Production defaults are
unchanged unless the app is compiled with `STACK_EPIC_REGTEST=true`; custom
non-TLS relay models now correctly retain and probe their `ws` setting.

The harness pins the exact revisions reviewed on 2026-11-16:

| component | revision |
| --- | --- |
| Epic node | `c7e3fe09d823849a03dbe175f72736a2fab486c1` |
| Cypher Stack Epic wallet | `3df6316a08da8350f784f27f2efcc0a68628e2c9` |
| Stack native Epic plugin | `ff496872f9245e32083bfaf8bb46a785b3f59d62` |
| Epicmail 0.1.11 | `fe3249790acade16302d2ad807dbc02e70ff4886` |
| legacy Node Epicbox | `774855da54b1bd56e0c4c9c05e5e1ad76ce4f935` |

Everything binds to loopback. The generated wallets, recovery phrase, chain,
logs and SQLite databases live in the ignored `.epicmail-regtest` directory.
They are disposable test data and must never be funded on a public network.

## Why the Epic node is patched

At the pinned revision the built-in UserTesting miner emits Cuckatoo proofs,
while `only_randomx` rejects them, and it stamps blocks at the Unix epoch. The
node then rejects its own blocks (`InvalidSortAlgo` or `InvalidBlockTime`).
`patches/epic-usernet-test-miner.patch` is deliberately confined to the cloned
test node: it lets the existing switch select Cuckatoo and timestamps blocks
with the current time. It is test infrastructure, not an Epic consensus or
production-node change.

## Start a funded local environment

Linux prerequisites are Git, Rust/Cargo, Node.js 20+, npm, Python 3.9+ and
curl. Docker and OpenSSL are additionally needed for the legacy relay,
migration and mixed-federation exercises.

```sh
bash scripts/epicmail_regtest/setup.sh
bash scripts/epicmail_regtest/run_services.sh
bash scripts/epicmail_regtest/verify_services.sh
```

The setup script clones the pinned sources, applies only the test-miner patch,
builds all four components with their lockfiles, runs Epicmail's complete test
suite, installs the legacy relay's locked npm dependencies and builds its
native signature helper.

The service runner creates a throwaway CLI wallet, mines funding rewards to it,
then restarts the node in burn mode. It leaves these services running:

- Epic node API: `http://127.0.0.1:43413`
- Epicmail HTTP/WebSocket endpoint: `http://127.0.0.1:43420`
- funded CLI wallet listening on Epicmail

Stop them without deleting the evidence or wallet data:

```sh
bash scripts/epicmail_regtest/stop_services.sh
```

Set `EPICMAIL_REGTEST_WORK` to keep clones and runtime data outside the
checkout. `EPIC_REGTEST_WALLET_PASSWORD` overrides the disposable wallet's
default password. Do not use a real password.

## Run Stack Wallet

Build/run the app with the explicit flag and a disposable data directory.
Without the flag, the normal mainnet node, relay, TLS and chain settings remain
in force. A desktop regtest build intentionally refuses to start without
`-d`: this prevents it from opening real wallet data against the test chain.

```sh
work=${EPICMAIL_REGTEST_WORK:-$PWD/.epicmail-regtest}
flutter run -d linux --dart-define=STACK_EPIC_REGTEST=true \
  -a=-d -a="$work/runtime/stack-data"
```

The optional endpoint defines are:

```text
EPIC_REGTEST_NODE_HOST=http://127.0.0.1
EPIC_REGTEST_NODE_PORT=43413
EPIC_REGTEST_RELAY_HOST=127.0.0.1
EPIC_REGTEST_RELAY_PORT=43420
```

Create an Epic wallet in Stack Wallet and copy its Epicbox address. Send a
small amount from the funded CLI wallet:

```sh
work=${EPICMAIL_REGTEST_WORK:-$PWD/.epicmail-regtest}
"$work/src/epic-wallet/target/release/epic-wallet" \
  --usernet -c "$work/runtime/miner" -p local-regtest-only \
  send 1.0 -m epicbox -d 'STACK_ADDRESS@127.0.0.1:43420' -f
```

Then send a small amount back from Stack Wallet to the miner address printed by
`run_services.sh`. Confirm both transactions on-chain, not merely in the relay
logs. Paste the address atomically: the current native parser can abort on the
temporary text `...@host:` while a port is being typed character by character.
That existing explicit-port input bug is independent of Epicmail.

## What a successful compatibility run covers

The 2026-11-16 run completed all of the following with real encrypted slates
and the pinned Stack-linked native wallet:

- Stack receives from the CLI wallet through Epicmail, finalizes and confirms.
- Stack sends through Epicmail, the CLI wallet receives, finalizes and confirms.
- random Epicmail challenges are signed successfully.
- `PostSlate`, delivered `Slate`, message-ID-signed `Made`, queueing and
  acknowledgement all complete.
- a queued transaction survives an Epicmail restart and completes afterward.
- Epicmail and the legacy Mongo relay federate successfully in both initiation
  directions.
- a slate queued in Mongo is exported, imported into SQLite, delivered,
  federated back, acknowledged, finalized and confirmed after cold cutover.

Typical encrypted envelopes in that run were 5.1–9.0 KiB, well under
Epicmail's default 128 KiB `str` limit. The limit is still an operational
setting: exchanges should measure their largest real slates before accepting
the default.

## Mixed legacy/Epicmail federation

First run and stop the normal environment once so the chain and miner wallet
exist and are funded. The mixed runner then starts an isolated MongoDB 8
container, the public pinned legacy relay, Epicmail, both CLI wallets, the node
and the local TLS proxy:

```sh
bash scripts/epicmail_regtest/run_services.sh
bash scripts/epicmail_regtest/stop_services.sh
bash scripts/epicmail_regtest/run_mixed_services.sh
```

The command prints both wallet addresses. Exercise both initiation directions;
the explicit destinations must retain the relay ports:

```sh
work=${EPICMAIL_REGTEST_WORK:-$PWD/.epicmail-regtest}
wallet="$work/src/epic-wallet/target/release/epic-wallet"

SSL_CERT_FILE="$work/runtime/tls.crt" "$wallet" --usernet \
  -c "$work/runtime/miner" -p local-regtest-only \
  send 0.021 -m epicbox -d 'LEGACY_KEY@127.0.0.1:43421' -f

"$wallet" --usernet -c "$work/runtime/legacy-wallet" \
  -p local-regtest-only \
  send 0.011 -m epicbox -d 'EPICMAIL_KEY@127.0.0.1:43420' -f
```

Mine at least one block or use `txs` to verify that each sender reached
`Sent (Mempool)` and that each recipient created a matching `Received` row.
Relay `Ok` messages alone are not transaction success. Stop the environment
with:

```sh
bash scripts/epicmail_regtest/stop_mixed_services.sh
```

The legacy relay hard-codes `wss://` for outbound federation. The mixed runner
therefore puts Epicmail on a plain backend at 43422 and the included
`tls_proxy.js` on 43420 with a throwaway certificate. It disables Node TLS
verification only for the disposable legacy-relay process. Epicmail maps the
legacy identity explicitly:

```toml
[server]
listen = "127.0.0.1:43422"
domain = "127.0.0.1"
port = 43420

[federation]
enabled = true
allow_private = true

[federation.peers]
"127.0.0.1:43421" = "ws://127.0.0.1:43421/"
```

The runner generates a local certificate with an IP SAN and starts the proxy.
The equivalent manual commands are:

```sh
openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
  -keyout "$work/runtime/tls.key" -out "$work/runtime/tls.crt" \
  -subj /CN=127.0.0.1 -addext subjectAltName=IP:127.0.0.1
EPICMAIL_CERT_DIR="$work/runtime" \
  node scripts/epicmail_regtest/tls_proxy.js
```

Production must use a publicly valid certificate; never carry the local TLS
bypass into deployment.

## Mongo-to-SQLite cutover drill

Do this as a cold cutover. Pause wallet operations and stop the legacy relay so
the exported queue cannot change beneath the import. The executable drill is
strict and fail-fast: it starts a clean mixed environment, validates process
ownership, waits for each shutdown and startup, queues one real encrypted
slate, asserts the Mongo export and both import results, and requires delivery,
acknowledgement, federation and sender finalization.

```sh
bash scripts/epicmail_regtest/run_cutover_drill.sh
```

Every drill gets a new timestamped evidence directory. Its JSONL export,
import results, relay logs, transaction listing and SQLite database remain
under `$EPICMAIL_REGTEST_WORK/runtime`. The old Mongo files remain under
`runtime/mongo`; stopping the disposable container does not delete them. If
the export fails or reports skipped rows, the script never starts the new
relay.

The importer is idempotent: importing the same file again reports duplicates.
Keep the old Mongo volume and export until the new relay is accepted.

Two settings are mandatory for in-flight cross-relay transactions:

1. Epicmail must retain the old relay's advertised hostname and port (or a
   correct alias). Those endpoints participate in signed addressing.
2. Federation and its destination policy must already be enabled. An imported
   recipient slate can require an immediate reply to the sender's relay.

An Epicmail `Ok` for a federated post means the relay durably accepted the
forward locally. It does not prove the destination relay accepted it; monitor
the forward queue and retry/failure counters during and after cutover.

Rollback is asymmetric. Mongo is a safe snapshot of the pre-cutover queue, but
new items accepted into Epicmail SQLite are not automatically written back to
Mongo. Inspect/export the Epicmail queue before rolling back and be prepared
for senders to retry those transactions.
