# CLAUDE.md — Better_stack_wallet

## Project overview

Better_stack_wallet is a fork of Cypher Stack's **Stack Wallet** (`cypherstack/stack_wallet`, GPL-3.0), a large multi-coin, multi-platform Flutter cryptocurrency wallet (~24 coins, mobile + desktop). This checkout tracks upstream's `staging` branch closely (`origin` = `Unnamed2025/Better_stack_wallet`, `upstream` = `cypherstack/stack_wallet`). Upstream is actively maintained; latest upstream release was v2.6.0 (2026-06-26).

**This app custodies real funds, seed phrases, and private keys.** Correctness and security are not optional. A wrong fee, a leaked secret, or a broken migration can cause irreversible loss. Prefer testnet, never log secrets, and treat storage-key/identifier stability as sacred.

---

## CRITICAL — read before touching anything

These traps break fresh checkouts and silently discard edits. Internalize them first.

1. **`pubspec.yaml` and `lib/app_config.g.dart` are GENERATED and git-ignored.** A fresh clone has NEITHER. You cannot run `flutter pub get`, `flutter analyze`, or `flutter test` until the app-config configure step generates them. Never hand-edit `pubspec.yaml` — edit `scripts/app_config/templates/pubspec.template.yaml`. Never hand-edit `lib/app_config.g.dart` — edit the `cat <<EOF` heredoc inside the relevant `scripts/app_config/configure_<flavor>.sh`. Both are throwaway.

2. **Generated code — never hand-edit; regenerate:**
   - `*.g.dart` (Isar/Hive/Drift/mockito codegen — 42 committed, all `part of` their source). Regenerate: `bash scripts/dev/build_runner.sh` (`dart run build_runner build --delete-conflicting-outputs`). There are **no** `*.freezed.dart` files (freezed is not used here).
   - `lib/wl_gen/generated/*` (native-plugin interface impls — NOT committed, absent on fresh checkout). Edit the templates in `tool/wl_templates/*.template.dart`; regenerate via the configure script.
   - `lib/external_api_keys.dart` (git-ignored; absent on fresh checkout — app won't compile without it). Create via `scripts/prebuild.sh`.
   Editing any generated file by hand is silently overwritten on the next build.

3. **Inside `lib/` use RELATIVE imports, not `package:` imports.** Lints `prefer_relative_imports` + `avoid_relative_lib_imports` are on. Write `import '../themes/stack_colors.dart';`, never `import 'package:stackwallet/themes/stack_colors.dart';`. **Tests are the opposite** — `test/` files use `package:stackwallet/...` absolute imports.

4. **Git submodules must be initialized:** `crypto_plugins/flutter_libepiccash`, `crypto_plugins/frostdart`, `crypto_plugins/flutter_libmwc`. Run `git submodule update --init --recursive` or native code won't build.

5. **Native Rust libs need specific toolchains: both `1.89.0` and `1.85.1` installed.** libmwc requires 1.85.1; everything else (libepiccash, frostdart, secp256k1) uses 1.89.0. `scripts/rust_version.sh` will `exit 1` if either is missing.

6. **Strict analyzer + hard 80-char line limit.** `strict-casts`/`strict-inference`/`strict-raw-types` all on; `lines_longer_than_80_chars` on (matches `dart format`'s 80-col default). `avoid_print`, `unawaited_futures`, `prefer_final_locals` enforced.

7. **`build_app.sh` blocks on an interactive `yes/no` prompt** that warns about deleting wallet data. Automated runs must pipe `echo "yes" |`.

---

## Getting a buildable checkout

Nothing works until `pubspec.yaml` + `lib/app_config.g.dart` exist. Tests are hardwired to the `stack_wallet` flavor (package name `stackwallet`); configuring as campfire/stack_duo breaks every `package:stackwallet/...` import.

```
git clone <repo> && cd Better_stack_wallet
git submodule foreach 'git fetch --tags' && git submodule update --init --recursive

# Generate pubspec.yaml + native config for the stack_wallet flavor.
# echo "yes" answers the destructive-data disclaimer. -d fetches prebuilt
# native libs (skip building from source); -s uses system secure-storage deps.
cd scripts && echo "yes" | ./build_app.sh -v "0.0.1" -b "1" -p linux -a stack_wallet -d -s && cd ..

flutter pub get

# Native-plugin version stubs. Only *_example.dart is committed in the
# submodules; git_versions.dart is absent on a fresh checkout, and
# flutter test/analyze won't compile without it (CI creates these too).
for p in flutter_libepiccash flutter_libmwc; do
  echo 'String getPluginVersion() => "stub-for-tests";' \
    > "crypto_plugins/$p/lib/git_versions.dart"
done

bash scripts/ensure_test_app_config.sh   # writes lib/app_config.g.dart if absent
cd scripts && bash prebuild.sh && cd ..   # stub external_api_keys.dart + test params
```

Notes:
- `scripts/ensure_test_app_config.sh` is idempotent: writes a full-coin stack_wallet `app_config.g.dart` only if one doesn't exist.
- `scripts/prebuild.sh` creates `lib/external_api_keys.dart` (empty key constants) and per-coin `test/services/coins/<coin>/<coin>_wallet_test_parameters.dart` stubs (bitcoin, bitcoincash, dogecoin, namecoin, firo, particl) — without them the coin-service tests won't compile.
- `crypto_plugins/{flutter_libepiccash,flutter_libmwc}/lib/git_versions.dart` must exist (only `git_versions_example.dart` is committed). A native plugin build/download can produce it; otherwise create the stub above, exactly as CI does before `flutter test`.
- Linux-only extra: `cd scripts/linux && ./build_secure_storage_deps.sh` (builds a Cypher Stack fork of libsecret + jsoncpp) unless you pass `-s`.
- secp256k1 (coinlib): `dart run coinlib:build_linux` (or `build_macos`/`build_windows`/`build_wsl`), or `scripts/linux/build_secp256k1.sh`.

---

## Build / run / test commands

Only commands verified to exist. Do not invent flags.

```
# Full white-label / native build orchestrator:
#   -a stack_wallet|stack_duo|campfire  -p android|ios|macos|linux|windows
#   -v <version> -b <buildNumber>
#   (no -i/-d) build native plugins from source (slow)
#   -d  download prebuilt native plugins   -i  skip plugin build entirely
#   -f  build Isar from source   -s  use system secure-storage deps
cd scripts && echo "yes" | ./build_app.sh -a stack_wallet -p linux -v 2.1.0 -b 210 && cd ..

flutter run -d linux            # or: -d macos / -d windows / android emulator (x86_64)

# Regenerate codegen (Isar/Hive/Drift models + mockito mocks) after editing an
# annotated source or a mocked class's surface; commit the regenerated *.g.dart:
bash scripts/dev/build_runner.sh

dart format .                   # 80-col; CI enforces on CHANGED files with --set-exit-if-changed
flutter analyze                 # convention; NOT gated in CI (step is commented out)
flutter test                    # CI runs: flutter test --coverage  -> coverage/lcov.info
```

CI gates (`.github/workflows/test.yaml`, on `pull_request`, in `stackwallet-ci:test` container): (1) `dart format --set-exit-if-changed` on changed `.dart` files — **formatting failures fail CI**; (2) `flutter test --coverage`. `flutter analyze` is commented out, so analyzer warnings do NOT fail CI — still run it locally.

Integration tests (`integration_test/`, Page-Object "bot" pattern) are NOT run by `flutter test` and have no CI job — run manually with `flutter test integration_test/...` on a device/emulator.

---

## Architecture — a navigable map of `lib/`

### Wallet domain model (`lib/wallets/`)
Two parallel hierarchies, matched by coin type:
- **`crypto_currency/`** — static coin metadata + address/key math, no network/db state. Base `crypto_currency/crypto_currency.dart` (`CryptoCurrency`); `CryptoCurrencyNetwork` enum = `main/test/stage/test4`. Intermediates in `crypto_currency/intermediate/` (`Bip39Currency`, `Bip39HDCurrency`, `CryptonoteCurrency`, `FrostCurrency`, `NanoCurrency`, `ElectrumCurrency`). Currency mixins in `crypto_currency/interfaces/` (`ElectrumXCurrencyInterface`, `PaynymCurrencyInterface`). Concrete coins in `crypto_currency/coins/<coin>.dart`.
- **`wallet/`** — runtime behavior (db, secure storage, node, sync). Abstract base `wallet/wallet.dart` (`Wallet<T extends CryptoCurrency>`). Intermediates in `wallet/intermediate/` (`Bip39Wallet`, `Bip39HDWallet`, `ExternalWallet`, `CryptonoteWallet`, `LibXelisWallet`, `lib_monero/lib_wownero/lib_salvium_wallet.dart`). Concrete wallets in `wallet/impl/<coin>_wallet.dart`; token sub-wallets in `wallet/impl/sub_wallets/`. Capabilities are composed as mixins in `wallet/wallet_mixin_interfaces/` (`ElectrumXInterface` — the 2500-line BTC engine, `SparkInterface`, `PaynymInterface`, `MultiAddressInterface`, `CoinControlInterface`, `MwebInterface`, `RbfInterface`, etc.).
- **`Wallet._loadWallet` (`wallet/wallet.dart`) is the master coin registry** — a `switch (walletInfo.coin.runtimeType)`; adding a coin requires a `case` here.
- `wallet/api/` — bespoke REST/RPC clients (Tezos tzkt, Cardano Blockfrost).
- **Gotchas:** `identifier` strings are permanent storage keys (must match the legacy `Coin` enum name); renaming makes existing wallets unloadable. `ElectrumCurrency` is a misnomer (Xelis uses it). `Bip39Wallet` is the base for FFI coins (Epiccash, MWC). `TxData` (`wallet/models/tx_data.dart`) is a shared mutable god-object with per-coin fields. `_refresh` hardcodes coin-specific branches (Paynym/Spark/Namecoin) despite TODOs asking not to. Some method names are load-bearing and deliberately ugly (`xmrAndWowSyncSpecificFunction...`) — grep before assuming dead.

### Native-plugin availability seam (`lib/wl_gen/`)
The mechanism that compiles native libraries in/out per flavor. `lib/wl_gen/interfaces/*.dart` declare abstract interfaces AND `export '../generated/<name>_impl.dart'`. The generated impl exposes a top-level getter (`csMonero`, `csWownero`, `csSalvium`, `libXelis`, `libSpark`, `libEpic`, `libMwc`, `frostInterface`, `mwebdServerInterface`, Tor impl). When a marker is disabled, the generated impl is a stub that throws `Exception("<X> not enabled!")` instead of a missing-symbol link error. Interfaces are committed; `generated/` is not.

### Data / persistence (`lib/db/`)
Four coexisting engines (a legacy → modern migration path — not accidental duplication):
- **Isar (`isar_community` 3.3.0-dev.2)** — authoritative main store. `MainDB` singleton (`db/isar/main_db.dart`), one instance `"wallet_data"`. **All collection `*Schema`s are registered in one `Isar.open([...])` call in `MainDB.initMainDB()` — a new `@Collection` is invisible until added here.** Query extensions in `db/queries/queries.dart` (`part of` main_db). Both v1 `Transaction` and `TransactionV2` schemas are live; don't assume v1 is dead. Models in `lib/wallets/isar/models/` and `lib/models/isar/`.
- **Hive (`hive_ce` 2.13.2) — LEGACY** but still authoritative for prefs, nodes, trades, notifications, price cache, favorites, DB-version bookkeeping. `DB` singleton (`db/hive/db.dart`). Adapters are manually registered in `main.dart` (order/typeId is load-bearing).
- **Drift (SQLite, `drift ^2.28.2`)** — per-wallet relational store (`db/drift/database.dart`, `Drift.get(walletId)`) + a shared CakePay/ShopInBit DB (`db/drift/shared_db/`, own `schemaVersion = 2`).
- **Raw `sqlite3`** — Firo/Spark anonymity-set + tags cache in a background isolate (`db/sqlite/firo_cache*.dart`), versioned by filename.
- **Migrations:** Hive `hive_data_version` chain in `db/db_version_migration.dart` (`Constants.currentDataVersion = 16`; recursive tail-chained `switch`; case 6 = the big Hive→Isar wallet migration via `db/migrate_wallets_to_isar.dart`). Run on mobile at `main.dart` startup; on desktop post-login (`pages_desktop_specific/password/desktop_login_view.dart`). Adding one: add `case 16:` writing `value: 17`, bump `currentDataVersion`. Three independent version schemes coexist (Hive 16 / Drift shared 2 / Firo cache filename 2) — they don't interlock.
- **Secure storage** (`lib/utilities/flutter_secure_storage_interface.dart`): `SecureStorageWrapper` branches on desktop. Mobile → OS keychain (`FlutterSecureStorage`). Desktop → in-app-encrypted values in a separate Isar db `"desktopStore"`, keyed off the login passphrase (`utilities/desktop_password_service.dart`, `stack_wallet_backup` pkg). Seeds/keys are keyed `"${walletId}_mnemonic"` / `_mnemonicPassphrase` / `_privateKey` and live ONLY in secure storage — never in the main DBs.

### Services & networking (`lib/services/`, `lib/electrumx_rpc/`, `lib/networking/`)
Blockchain access splits three ways by coin family:
- **ElectrumX (TCP JSON-RPC)** — Bitcoin-family UTXO coins. `electrumx_rpc/electrumx_client.dart` (wraps `electrum_adapter`; `FiroElectrumClient` subclass for Lelantus/Spark). `electrumx_rpc/client_manager.dart` — process-wide singleton owning live clients + chain-height, keyed `"${coinType}_${network}"`; enforces Tor/clearnet consistency. `cached_electrumx_client.dart` caches confirmed tx JSON in Hive. `subscribable_electrumx_client.dart` is entirely commented-out dead code — don't resurrect. SSL certs ARE validated (`acceptUnverified: false`).
- **HTTP JSON-RPC / REST** — Ethereum (`web3dart`), Tezos (`tezart`), Stellar, Solana, Cardano (Blockfrost), Nano/Banano. Logic lives in the wallet impls, not `services/`.
- **Native FFI** — Monero/Wownero/Salvium, Epic, MWC, Spark, Frost, Xelis, MWEB. Via `lib/wl_gen/`.
- Other: `services/node_service.dart` (Hive-backed nodes; defaults from each coin's `defaultNode`), `services/price.dart` (CoinGecko, no key, gated by `Prefs.externalCalls`), `services/exchange/` (ChangeNOW default + Trocador/SimpleSwap/Nanswap/WizardSwap/Exolix), `services/cakepay/` + `services/shopinbit/` (gift cards), `services/notifications_service.dart`, `services/mwebd_service.dart` (local mwebd gRPC), `services/churning_service.dart`, `services/tor_service.dart` (abstract; impl generated).
- Raw HTTP wrapper `networking/http.dart` (`HTTP`) — every method requires an explicit nullable `proxyInfo` (no default); Tor via `socks5_proxy`.

### UI (`lib/pages/`, `lib/pages_desktop_specific/`, `lib/widgets/`)
- **Two page trees:** `pages/` (mobile-first) and `pages_desktop_specific/` (desktop). Many features exist in BOTH — updating a screen often means editing both. `Util.isDesktop` (`utilities/util.dart`) is the responsive switch (not a plain `Platform.isX` — handles iPad-in-macOS, Linux phones, 1220px min desktop width). `widgets/conditional_parent.dart` wraps differently per platform.
- **Widget library** `widgets/` (design system): `background.dart`, `rounded_white_container.dart`, `conditional_parent.dart`, `crypto_notifications.dart`, `custom_pin_put/`, `frost_scaffold.dart`, `widgets/desktop/`.

### State — Riverpod (`lib/providers/` + scattered)
`flutter_riverpod`. Single `ProviderScope` at the root of `main.dart`. Providers are NOT centralized — many live next to their feature (`themes/theme_providers.dart`, `wallets/isar/providers/`, etc.); `providers/providers.dart` is a partial barrel. **Mixed naming** — newer providers use a `p` prefix (`pWallets`, `pNavKey`, `pThemeService`); older use suffixes (`prefsChangeNotifierProvider`, `nodeServiceChangeNotifierProvider`). Mixed API (`ref.read(x.state).state` vs `x.notifier`) — follow the neighbor's pattern. Key globals: `pNavKey` (single navigator key), `prefsChangeNotifierProvider` (`Prefs` singleton), `pWallets`.

### Routing (`lib/route_generator.dart` + `lib/frost_route_generator.dart`)
Manual centralized route table — `RouteGenerator.generateRoute` is one ~230-case `switch (settings.name)` wired as `MaterialApp.onGenerateRoute`. No go_router, no codegen. Each page declares `static const routeName`. **Arguments are untyped `Object?`, manually type-checked** (often `Tuple2`/`Tuple3` or Dart records); a shape mismatch degrades to an error scaffold, not a crash. FROST multisig has its own `frost_route_generator.dart` driving ordered step wizards. Adding a page touches ≥3 places (widget + import + `case`), usually twice if it needs a desktop variant.

### Theming (`lib/themes/`)
`StackColors extends ThemeExtension<StackColors>` (`stack_colors.dart`) — accessed ~500× as `Theme.of(context).extension<StackColors>()!`. `StackTheme` is an **Isar** model (persisted, survives Hive lock). `ThemeService` (`pThemeService`) installs themes from ZIPs (blocks path traversal), fetches sha256-verified remote themes. Theme background assets are on-disk SVG files, not bundled. Gated by `AppFeature.themeSelection`.

### Utilities (`lib/utilities/`)
`Amount` (`amount/amount.dart`) — the money type (`BigInt` base units + `fractionDigits`); **never use raw doubles for money**. `Prefs`, `Constants` (`currentDataVersion = 16`), `Assets` (reference via `Assets.svg.xyz`, never hardcode paths), `STextStyles`, `Logging` (`Logging.instance` — use instead of `print`), `stack_file_system.dart` (all app paths). `app_config.dart` + generated `app_config.g.dart` — `AppConfig.coins`, `AppConfig.hasFeature(AppFeature.x)`; all coin/feature gating flows through here.

### Native submodules (`crypto_plugins/`)
`flutter_libepiccash` (v0.1.6), `flutter_libmwc` (v0.1.1-7), `frostdart` (v0.1.4-6). Built per-platform by `scripts/<platform>/build_all.sh`; Rust toolchains juggled by `scripts/rust_version.sh`.

---

## App flavors

Three build flavors ("app named IDs"), each with `scripts/app_config/configure_<id>.sh` that regenerates `pubspec.yaml` (name + deps) and writes `lib/app_config.g.dart` (features + `_supportedCoins`):

| Flavor | pubspec name | Coins | Notes |
|---|---|---|---|
| `stack_wallet` | `stackwallet` | full ~24-coin set | the default; **tests only run under this flavor** |
| `stack_duo` | `stackduo` | BTC, XMR, BitcoinFrost (+testnets) | slimmed UX |
| `campfire` | `paymint` (legacy) | Firo only | Spark-by-default; has its own migration path (`CampfireMigration` in `main.dart`), BSD-aware `sed`, distinct iOS app id |

Coin/feature sets differ via the app-config marker system: the same marker list (`MWC MWEBD XMR WOW SAL TOR EPIC FIRO XEL FROST`) drives both `tool/process_pubspec_deps.dart` (uncomments deps in the pubspec template) and `tool/gen_interfaces.dart` (generates real vs stub `wl_gen` impls). Features live in the `_features` set of `AppFeature` (`themeSelection, buy, swap, tor, shopinBit, cakePay`). Adding a coin is a coordinated edit across the coin class, `Wallet._loadWallet`, `_supportedCoins` in each configure script, a `tool/wl_templates/` template + `lib/wl_gen/interfaces/` interface, and the marker lists.

---

## Conventions

- **Imports:** relative within `lib/`; `package:stackwallet/...` in `test/`.
- **Lints (`analysis_options.yaml`):** strict-casts/inference/raw-types; `avoid_print`, `unawaited_futures`, `prefer_final_locals`, `prefer_final_in_for_each`, `lines_longer_than_80_chars` all on. `missing_required_param`/`missing_return` escalated to errors; `parameter_assignments` warns (don't reassign params). SCREAMING_CASE consts allowed. `require_trailing_commas` is intentionally disabled — do not re-enable. Excludes `*.g.dart`, `*.freezed.dart`, `*.template.dart`, `integration_test/**`, `crypto_plugins/**`, `lib/wl_gen/generated/**`.
- **Formatting:** `dart format` (80-col). Enforced in CI on changed files.
- **File naming:** snake_case; one primary class per file; generated code via `part`/`part of`.
- **Generated-file discipline:** never hand-edit `*.g.dart`, `pubspec.yaml`, `app_config.g.dart`, or `lib/wl_gen/generated/*`. Regenerate. Commit regenerated `*.mocks.dart` when a mocked class's surface changes.
- **Error handling:** typed exception tree rooted at `SWException` (`lib/exceptions/`) — `NodeTorMismatchConfigException`, `InsufficientBalanceException`, ElectrumX/exchange/json_rpc subtrees. Some failover error detection is string-based (`"JSON-RPC error"`, `"No such mempool or blockchain transaction"`) — brittle, don't rely on message text elsewhere.
- **Deprecated Flutter APIs are in use** (`WidgetsBinding.instance.window`, `MaterialStateProperty`, `withOpacity`) — match surrounding style rather than "fixing" piecemeal.

---

## Testing

- Two mocking systems: **mockito** with committed generated `*.mocks.dart` (regenerate with `scripts/dev/build_runner.sh`), and **mockingjay/mocktail** for navigator/route mocking.
- Test layout: loose unit tests at `test/` root, plus `test/models/`, `test/services/` (coins need `prebuild.sh` params), `test/utilities/`, `test/widget_tests/` (each with a `*.mocks.dart` sibling), `test/screen_tests/`, `test/hive/`, `test/sample_data/`.
- Local validation loop (after the buildable-checkout steps): `bash scripts/dev/build_runner.sh` → `dart format .` → `flutter analyze` → `flutter test`.
- Test on **testnet** where possible — Bitcoin has `main`/`test`/`test4` identifiers.

---

## Security & correctness

- Seeds, passphrases, and private keys live ONLY in secure storage (OS keychain on mobile; passphrase-encrypted Isar `desktopStore` on desktop), never in the main Isar/Hive DBs. Keep it that way.
- **Never log secrets.** `avoid_print` is on; use `Logging.instance`. Don't add mnemonics/keys/xprivs to logs or error messages.
- **Tor is feature-gated and has a clearnet-fallback subtlety:** without `Prefs.torKillSwitch`, a `useTor` session silently falls back to clearnet (warning only) when Tor isn't connected. Do not "simplify" or invert this logic. Traffic is not uniformly Tor-routed — ElectrumX and the `HTTP` wrapper honor Tor, but `NodeService.updateCommunityNodes()` uses raw `package:http` (no proxy), and native RPC coins each re-implement Tor via `socks5_proxy`. Verify per coin.
- `identifier` strings and Hive adapter typeIds are permanent — changing them corrupts existing installs.
- Money is `Amount` (BigInt base units), never `double`. Fee/amount math errors are fund loss.
- `lib/external_api_keys.dart` must be created but never commit real keys (git-ignored). `kTrocadorApiKey` is hardcoded in-source by upstream design.

---

## Tech stack & versions

- **Flutter 3.38.x** (Dockerfile pins tag `3.38.1`; `docs/building.md` says 3.38.5 — treat 3.38.x as the target, don't assume an exact patch), **Dart 3.10.x**. *As of July 2026 this is ~2 stable releases behind — current is Flutter 3.44 / Dart 3.12. Not ancient, but plan an upgrade (3.38 → 3.41 → 3.44); watch Impeller Skia-fallback removal and Android 16KB-page compliance.*
- **Rust:** `1.89.0` and `1.85.1` both required (`scripts/rust_version.sh`). Docker also installs 1.71.0 + stable.
- **State:** `flutter_riverpod` pinned **`^1.0.3`** (resolves 1.0.4) — the **1.x line**, many majors behind the current 3.x (3.3.2 as of ~June 2026). This is *why* the code uses legacy idioms (`ref.read(x.state).state`, `ChangeNotifier` providers). Match the existing 1.x patterns; the 1.x→2.x→3.x migrations are large and API-breaking — do not bump casually.
- **DB / storage liabilities (dated July 2026):** `isar_community 3.3.0-dev.2` is maintenance-mode (original `isar` abandoned; community fork's latest stable is ~3.3.2); `hive_ce ^2.13.2` is the maintained Hive continuation (original `hive` abandoned). `drift ^2.28.2` is healthy (current ~2.34.x). `flutter_secure_storage` is pinned **`^8.0.0`** (current is 10.x) — note the v10 Android rewrite added an automatic keychain-migration path, so any future bump needs careful on-device migration testing for a wallet. A production wallet should plan migration off Isar/original-Hive; do not casually bump any of these.
- Codegen: `build_runner ^2.5.4`, `isar_community_generator 3.3.0-dev.2`, `drift_dev ^2.28.3`, `hive_ce_generator ^1.9.3`. Lints: `flutter_lints ^3.0.1`.

---

## Key file references

- `scripts/app_config/templates/pubspec.template.yaml` — edit instead of `pubspec.yaml`
- `scripts/app_config/configure_{stack_wallet,stack_duo,campfire}.sh` — flavor config + `app_config.g.dart` heredoc
- `tool/gen_interfaces.dart`, `tool/process_pubspec_deps.dart`, `tool/wl_templates/` — the wl_gen marker system
- `scripts/build_app.sh`, `scripts/rust_version.sh`, `scripts/dev/build_runner.sh`, `scripts/prebuild.sh`, `scripts/ensure_test_app_config.sh`
- `lib/main.dart` — order-sensitive startup (adapter registration, migrations, Tor, ProviderScope root)
- `lib/wallets/wallet/wallet.dart` — `Wallet._loadWallet` master coin registry
- `lib/db/isar/main_db.dart` — Isar schema registration
- `lib/db/db_version_migration.dart` — Hive migration chain
- `lib/route_generator.dart` — the route table
- `lib/app_config.dart` (+ generated `app_config.g.dart`) — feature/coin gating
