# Testing the build setup

For build steps, see the [overview](../building.md).

## Configuration tests

After configuring an app and running `flutter pub get`, check template and mode
selection without compiling native libraries:

```sh
dart scripts/tests/native_build_config_test.dart
dart scripts/tests/build_input_test.dart
```

These tests exercise all three apps, both modes, persistent WSL settings, Linux
builds, and Windows output locations, using stubbed native tools. Separate
tests cover prerequisite failures, Xcode setup, Windows tool discovery, and the
secp256k1 build helper. A small Windows CI job runs the PowerShell prebuild
regression tests. Actual native Windows-to-WSL builds are tested in dnix's CI;
these app tests don't run WSL.

## Linux release bundle tests

These are standalone regression tests for the
[release bundle helper](linux.md#prepare-a-release-bundle). They also need a C
compiler:

```sh
python3 -m unittest discover -s scripts/linux/tests -p 'test_*.py' -v
```

## Grin integration tests

The unit tests in `test/wallets/grin` use fakes and need no native code.

`integration_test/grin/grin_test_chain_test.dart` drives `GrinWallet` against
the real `grin-ffi` library on its in-process test chain. It covers mining,
Slatepack S1/S2/S3, invoices, cancellation, reposting, payment proofs,
mnemonic restore with a scan, and wallet deletion. Run it through the wrapper:

```sh
bash scripts/grin_e2e_test.sh          # host desktop
bash scripts/grin_e2e_test.sh linux    # explicit device
```

The wrapper temporarily enables `grin_native`'s `test_utils` build, restores
the generated pubspec files when it exits, and removes the test-enabled Grin
library from the application build directory. If the process is killed before
cleanup, configure the app again and delete its build output before producing
a distributable build.

After a normal release build, verify that it contains only the 36 production
exports and no `grin_test_` exports:

```sh
bash scripts/grin_symbol_gate.sh build/linux/x64/release/bundle
```

## Xelis integration tests

Run these on a configured desktop target (`windows`, `linux`, or `macos`) with
the app's native plugin dependencies:

```sh
flutter test integration_test/xelis/xelis_adapter_test.dart -d windows
flutter test integration_test/xelis/xelis_restore_test.dart -d windows
flutter test integration_test/xelis/xelis_swb_test.dart -d windows
```

The transfer test starts a temporary devnet node using a host `xelis_daemon`
1.25 executable:

```sh
flutter test integration_test/xelis/xelis_local_transfer_test.dart -d windows \
  --dart-define=XELIS_LOCAL_DAEMON=/absolute/path/to/xelis_daemon
```

Missing `XELIS_LOCAL_DAEMON` or an invalid path fails the test.

## Checking Tor routing

To test Tor usage, run Stack Wallet from Android Studio. Click the Flutter
DevTools icon in the Run tab, next to the Hot Reload and Hot Restart buttons,
and open the Network tab. Connections through Tor show as
`GET InternetAddress('127.0.0.1', IPv4) 101 ws`. Connections outside Tor show
the destination address directly. Some Tor requests may also show the
destination address directly, so check their headers, for example
`{localPort: 59940, remoteAddress: 127.0.0.1, remotePort: 6725}`; `localPort`
should match your Tor port.
