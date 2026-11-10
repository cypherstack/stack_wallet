# Bitcoin regtest integration tests

`integration_test/bitcoin_regtest` mines coins on a private Bitcoin regtest
chain and sends them between Stack wallets. Each test file starts its own
`bitcoind` and electrs on free loopback ports under a temp dir and removes
them when it ends, so runs are independent and need no network.

The wallets are the app's real `BitcoinWallet`s: Isar and Hive storage,
`NodeService`, ElectrumX sync, coin selection and coinlib signing. The test
calls `prepareSend` and `confirmSend` the way the send view does; it does not
drive the UI.

Configure/build the app and native dependencies first: [building.md](building.md).
You also need:

- `bitcoind` from Bitcoin Core (tested with 31.1).
- `electrs` 0.10 (romanz/electrs; tested with 0.10.10). Blockstream's and
  mempool's electrs forks take different flags and are not supported.

```sh
BITCOIND=/path/to/bitcoind ELECTRS=/path/to/electrs \
  bash scripts/test_bitcoin_regtest.sh            # linux or macos by host
```

The script passes `--dart-define=STACK_BITCOIN_REGTEST=true`, which adds a
Bitcoin regtest coin (`bitcoinRegtest`, `bcrt` addresses) to
`AppConfig.coins`. Builds without that define do not contain it. On Linux
without a display the script runs Flutter under `xvfb-run`.

`send_receive_test.dart` covers:

- the node's wallet funding a new Stack wallet, seen unconfirmed and then
  confirmed;
- a Stack to Stack send at a custom fee rate, checked against `bitcoind`'s
  mempool entry (fee, outputs) and both wallets' balances and history;
- a Stack send to a P2WPKH address in the node's wallet, confirmed by the node;
- restoring the first wallet from its recovery phrase.

On failure the error message ends with the last `bitcoind` and electrs log
lines.
