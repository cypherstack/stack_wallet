# Wallet creation integration tests

Real UI tests create and reopen 24 mainnet mnemonic wallets, checking recovery
phrases, derived identities, and persistence. FROST and token subwallets are excluded.
Configure/build the app and native dependencies first: [building.md](building.md).

```sh
dart scripts/test_wallet_creation.dart --list
dart scripts/test_wallet_creation.dart --device macos --coin bitcoin
dart scripts/test_wallet_creation.dart --device macos --all-coins
dart scripts/test_wallet_creation.dart --device macos --report /tmp/creation-results.json
dart scripts/test_wallet_creation.dart --device DEVICE_ID --platform android --disposable-mobile
dart scripts/tests/wallet_creation_runner_test.dart
```

Without `--coin` or `--all-coins`, each coin gets a separate fresh create/reopen pair.
Repeat `--coin` to select several; `--all-coins` shares one installation instead.
Use `linux` or `windows` on those hosts, or `--platform ios` for a dedicated iPhone.
Mobile requires clean, disposable app data and secure storage before each fresh case.
Use `--help` for options. Host runner checks do not launch the app.

Tests use real storage/native libraries and may contact configured nodes.
Desktop fixtures are removed after exit; mobile installations must be reset.
Raw app logs can contain recovery data; share only the sanitized JSON report.

Verified on macOS: combined 24-coin create/reopen and independent Bitcoin/Epic Cash pairs.
Other platforms and the full 24 independent fresh-install pairs remain unverified.
iOS simulator builds are blocked by the device-only Monero framework.
