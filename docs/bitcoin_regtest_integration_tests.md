# Bitcoin regtest integration tests

`integration_test/bitcoin_regtest` mines coins on a private Bitcoin regtest
chain and sends them between Stack wallets. Every test file gets a fresh
`bitcoind` and Electrum server on free loopback ports under a temp dir, so
runs are independent and need no network.

The wallets are the app's real `BitcoinWallet`s: Isar and Hive storage,
`NodeService`, ElectrumX sync, coin selection and coinlib signing. Most tests
call `prepareSend`, `prepareRbfSend` and `confirmSend` the way the send and
boost views do. `desktop_send_test.dart` runs the whole app instead and sends
through the desktop send form, so it needs a desktop device.

## Quick start (macOS or Linux)

```sh
bash scripts/fetch_bitcoin_regtest_bins.sh
(cd scripts && ./prebuild.sh && echo yes | ./build_app.sh -v 0.0.1 -b 1 -p macos -a stack_wallet -d)
bash scripts/test_bitcoin_regtest.sh
```

Use `-p linux` on Linux. The first build takes a few minutes; see
[building.md](building.md) for the toolchain.

`fetch_bitcoin_regtest_bins.sh` puts the node programs in
`~/.cache/stack_wallet_regtest` (or `REGTEST_BIN_DIR`), where the runner looks
for them after `BITCOIND`, `ELECTRS`, `FULCRUM` and `PATH`:

- `bitcoind` 31.1 from bitcoincore.org, checked against its `SHA256SUMS`.
- electrs 0.10.10 (romanz/electrs), built with `cargo install`, so it needs
  Rust and clang. This is what Umbrel, Start9 and most self-hosted nodes run.
  Blockstream's and mempool's electrs forks take different flags and are not
  supported.
- Fulcrum 1.11.1, which Stack's own Bitcoin server runs, from its GitHub
  release, checked against the release's sums. Linux only: there is no macOS
  release. Peering is turned off so it never contacts public servers.

## Runner

```sh
INDEXER=all bash scripts/test_bitcoin_regtest.sh [device] [flutter test options]
```

`INDEXER` is `electrs` (the default), `fulcrum` or `all`; only the selected
servers are needed. The device defaults to the host (`linux`, `macos` or
`windows`). On Linux without a display the script runs Flutter under
`xvfb-run`. The script works with the bash 3.2 that ships with macOS.

On Linux and Windows the test starts the nodes itself. The macOS app is
sandboxed, so it can run neither `bitcoind` nor read its cookie; there the
runner starts the nodes on the host with `scripts/bitcoin_regtest_nodes.dart`
and passes their ports and an RPC password to the test. `REGTEST_HOST_NODES=1`
does the same on Linux and Windows.

## Mobile

The nodes run on the host and the simulator or emulator connects to them, so
these run on a Mac (iOS) or a Mac or Linux machine (Android). The desktop UI
test is skipped. Physical devices are not supported: the nodes listen on the
host's loopback only.

iOS simulator: the Monero, Wownero and Salvium frameworks are device-only, so
configure a build with only the Tor plugin. Stack's ElectrumX client needs
Tor's service even with Tor off.

```sh
(cd scripts && ./prebuild.sh && echo yes | STACK_PLUGINS=TOR ./build_app.sh -v 0.0.1 -b 1 -p ios -a stack_wallet -d)
xcrun simctl boot <simulator udid>              # xcrun simctl list devices
REGTEST_TARGET=ios bash scripts/test_bitcoin_regtest.sh <simulator udid>
```

Android emulator (x86_64): the full build works. The emulator reaches the
host's loopback as `10.0.2.2`, which the runner passes to the test.

```sh
(cd scripts && ./prebuild.sh && echo yes | ./build_app.sh -v 0.0.1 -b 1 -p android -a stack_wallet -d)
REGTEST_TARGET=android bash scripts/test_bitcoin_regtest.sh emulator-5554
```

Configuring for one platform rewrites generated files, so use a separate
checkout (or worktree) per platform.

## Tests

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
Electrum server log lines (printed by the runner when it started the nodes).
App data and logs stay in each test's temp dir; the desktop test sets the
logs path pref first, because the app's default
logs dir ignores the data dir override and is shared with real installs.

## Troubleshooting

- macOS build fails with `tapi error: malformed file` and `unknown
  architecture ... arm64e.x1-macos` while compiling Rust build scripts: the
  Command Line Tools have a newer macOS SDK than the selected Xcode's linker
  understands (compare `xcode-select -p` with
  `ls /Library/Developer/CommandLineTools/SDKs`). This breaks any Stack Wallet
  macOS build, not only these tests. Setting `SDKROOT` or `DEVELOPER_DIR` does
  not help, because the Rust build hooks do not see them; select an Xcode at
  least as new as the Command Line Tools (`sudo xcode-select -s ...`) or
  update the two together. `fetch_bitcoin_regtest_bins.sh` already builds
  electrs against the selected Xcode's SDK.
