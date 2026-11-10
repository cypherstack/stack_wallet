# Bitcoin regtest integration tests

`integration_test/bitcoin_regtest` mines coins on a private Bitcoin regtest
chain and sends them between Stack wallets. Each test file starts its own
`bitcoind` and Electrum server on free loopback ports under a temp dir and
removes them when it ends, so runs are independent and need no network.

The wallets are the app's real `BitcoinWallet`s: Isar and Hive storage,
`NodeService`, ElectrumX sync, coin selection and coinlib signing. Most tests
call `prepareSend`, `prepareRbfSend` and `confirmSend` the way the send and
boost views do. `desktop_send_test.dart` runs the whole app instead and sends
through the desktop send form, so it needs a desktop device.

Configure/build the app and native dependencies first: [building.md](building.md).
You also need `bitcoind` from Bitcoin Core (tested with 31.1) and one or both
Electrum servers:

- Fulcrum (tested with 1.11.1, which Stack's own Bitcoin server runs). Peering
  is turned off so it never contacts public servers.
- electrs 0.10 (romanz/electrs; tested with 0.10.10), as shipped by Umbrel,
  Start9 and most self-hosted nodes. Blockstream's and mempool's electrs forks
  take different flags and are not supported.

```sh
INDEXER=all BITCOIND=/path/to/bitcoind ELECTRS=/path/to/electrs \
  FULCRUM=/path/to/Fulcrum bash scripts/test_bitcoin_regtest.sh
```

`INDEXER` is `electrs` (the default), `fulcrum` or `all`; only the selected
servers' binaries are needed. The device defaults to the host (linux or
macos). On Linux without a display the script runs Flutter under `xvfb-run`.

The script passes `--dart-define=STACK_BITCOIN_REGTEST=true`, which adds a
Bitcoin regtest coin (`bitcoinRegtest`, `bcrt` addresses) to
`AppConfig.coins`. Builds without that define do not contain it.

| file | covers |
|------|--------|
| `send_receive_test.dart` | node funds a new wallet (unconfirmed, then confirmed); Stack to Stack send at a custom fee rate, checked against bitcoind's mempool entry; a send to a P2WPKH address in the node's wallet; restoring from the recovery phrase |
| `rbf_cpfp_test.dart` | an opted-in send signals BIP125 and is replaced at a higher rate; a coin control child of an unconfirmed parent raises the package fee rate |
| `nested_segwit_test.dart` | a restored wallet spends coins that arrived on its BIP49 (P2SH-P2WPKH) address |
| `desktop_send_test.dart` | onboarding, then the desktop send form: address, amount, the default fee (Stack's fallback rate, since regtest has no estimates), confirm and password; the node checks the payment |

On failure the output ends with the app log and the last `bitcoind` and
Electrum server log lines. App data and logs stay in each test's temp dir;
the desktop test sets the logs path pref first, because the app's default
logs dir ignores the data dir override and is shared with real installs.
