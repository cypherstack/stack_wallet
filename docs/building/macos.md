# Building on macOS

These steps build the macOS and iOS apps on a Mac with Apple Silicon. For how
the build fits together, see the [overview](../building.md).

## Prerequisites

| What | Needed for |
|---|---|
| [Flutter](https://docs.flutter.dev/install/manual) 3.47.2 | Every build |
| Your usual Xcode | Building the app, in both modes |
| Xcode **27.0**, release build **27A266a**, installed next to your usual Xcode | Source mode, the default: dnix builds its four packages with it, including during `flutter test`. It doesn't need to be selected; see [Install Xcode 27.0](#install-xcode-270) |
| [Homebrew](https://brew.sh/) packages below | Every build |
| [Rustup](https://rustup.rs/) | Every app, in both modes |
| [Go](https://go.dev/doc/install) 1.24.1 or newer | Stack Wallet |
| [Nix](https://nixos.org/download/) | Source mode, the default; not needed with `-d` |

```sh
brew install autoconf automake libtool cmake cocoapods pkg-config
```

Check `nix --version` from the same environment that runs Flutter, and use
`flutter doctor` to check the Apple SDK and CocoaPods setup. iOS device builds
also need your usual signing configuration. The app's deployment targets are
macOS 12.0 and iOS 15.0.

## Install Xcode 27.0

dnix's source builds of its four packages need exactly Xcode 27.0, release
build 27A266a; a different version can produce different hashes. The rest of
the app builds with whichever Xcode you normally use. Install 27.0 under `/Applications` with a
name matching `Xcode*.app`, next to your existing Xcode. dnix finds it there,
and you can keep a different stable Xcode selected system-wide. If you also
keep 27.0 betas installed, see
[If you have Xcode 27.0 betas installed](#if-you-have-xcode-270-betas-installed).

### With the setup helper

Install the [xcodes CLI](https://github.com/XcodesOrg/xcodes) from
[Homebrew core](https://formulae.brew.sh/formula/xcodes), then run the helper
from the repository root:

```sh
brew install xcodes
dart tool/setup_xcode.dart
```

Use plain `dart`, as shown, so setup does not run the app's native build hooks.
The helper opens a separate Terminal window, reuses an installed 27.0 or
downloads it with `xcodes install 27.0 --no-superuser --update`, then runs
Apple's first-launch setup, which accepts the Xcode license. `xcodes` asks for
your Apple account and the first-launch setup asks for your administrator
password. Wait for **Setup complete** in that window before building. To
preview the commands, run `dart tool/setup_xcode.dart --print`.

If another build of 27.0 is installed and the release is missing, the helper
prints instructions for installing the release manually alongside it, because
`xcodes` can refuse to install two builds of the same version. Existing Xcode
installations are left untouched. See [Setup helper details](#setup-helper-details).

### Manually from Apple

1. Sign in to [Apple Developer Downloads](https://developer.apple.com/download/all/?q=Xcode),
   find the **Xcode 27.0 release**, and download its `.xip` archive.
2. Expand the archive in Finder. Rename the extracted app to `Xcode-27.0-27A266a.app`
   **before** moving it into `/Applications`, preserving your existing Xcode.
3. Open a separate Terminal window and finish setup:

   ```sh
   sudo -k /Applications/Xcode-27.0-27A266a.app/Contents/Developer/usr/bin/xcodebuild -runFirstLaunch
   DEVELOPER_DIR=/Applications/Xcode-27.0-27A266a.app/Contents/Developer xcodebuild -version
   ```

   The first command installs Apple's components and accepts the Xcode license.
   Confirm the second prints `Xcode 27.0` and `Build version 27A266a`, then
   close that setup window. You can also run the setup helper after moving the
   app; it reuses that installation.

## Build the app with Xcode 27.0 (optional)

You don't need to select Xcode 27.0. The app builds with your usual Xcode, and
dnix finds 27.0 under `/Applications` on its own; the exception is described in
[If you have Xcode 27.0 betas installed](#if-you-have-xcode-270-betas-installed).
To build the whole app with 27.0 as well, select it for one terminal session.
Use the path the helper printed (`xcodes` may name the bundle
`Xcode-27.0.0.app`):

```sh
export DEVELOPER_DIR=/Applications/Xcode-27.0-27A266a.app/Contents/Developer
xcodebuild -version
flutter doctor
```

Run the configuration and Flutter build commands in that shell.
`unset DEVELOPER_DIR` returns it to the system default.

## Build

1. Clone the repository and create the stubs:

   ```sh
   git clone https://github.com/cypherstack/stack_wallet.git
   cd stack_wallet
   bash scripts/prebuild.sh
   ```

2. Configure and build the macOS app:

   ```sh
   bash scripts/build_app.sh -a stack_wallet -p macos -v 1.2.3 -b 123
   flutter pub get
   dart tool/check_native_overrides.dart stack_wallet
   flutter build macos --release
   ```

   For iOS, configure with `-p ios` and build with `flutter build ios --release`.

Use the version and build number for your checkout, and read the script's
confirmation before continuing. Add `-d` to the configuration command to use
verified dnix prebuilts. See the
[configuration options](../building.md#configuration-options). The override
check catches package-local dnix overrides; see
[Local overrides](native-libraries.md#local-overrides).

## Run during development

Use `flutter devices`, then `flutter run -d <device-id>`. For the iOS
simulator, install the simulator runtime from the Xcode you build with, in its
Settings > Components.

App builds compile and bundle secp256k1 through the Coinlib Flutter plugin.
Only host-side Dart and Flutter tests need the separate library: run
`dart run coinlib:build_macos` after `flutter pub get`.

## If you have Xcode 27.0 betas installed

Native build hooks do not inherit `DEVELOPER_DIR`. dnix checks the system-wide
Xcode selection first, then scans `/Applications/Xcode*.app`. The current
packages pin version 27.0 but not its build number, so a 27.0 beta can be
selected ahead of the release even after setup succeeds. Configuration rejects
that case in source mode before changing any files. Use `-d`, or keep the beta
outside the scanned paths and make sure it is not the system-wide selection.
Exporting `DEVELOPER_DIR` does not fix this. An upstream build-number pin in
the packages would make the selection unambiguous for direct Flutter builds
too. Other native hooks, such as Spark and MWEB, also find their tools
independently of `DEVELOPER_DIR`.

## Setup helper details

The helper finds `xcodes` on your current PATH before cleaning the environment,
including Mint, MacPorts, Nix, and globally configured mise or asdf shims.
Project-specific shim configuration is not forwarded, so use a globally
configured `xcodes` or its executable directly on PATH. The helper selects the
27A266a release build. Its setup window waits for Return after showing its
result, so you can copy any instructions even with a close-on-exit Terminal
profile.

The installer runs in a clean environment without shell startup files or build
commands. `xcodes` handles the Apple account prompts, and `sudo -k` prompts
directly for the administrator password without creating a reusable sudo
ticket. Dart does not read either password. This separates the terminal and
processes; it is not an OS sandbox. `xcodes` may remember Apple account
credentials in your Keychain according to its own settings.

The helper reads the required Xcode from the packages' metadata; see
[Xcode pins](native-libraries.md#xcode-pins). On a fresh checkout it downloads
that metadata from the pinned GitHub commits, including for `--print`.

## Troubleshooting

- Run Flutter commands with `-v` for more detail.
- If configuration rejects a 27.0 beta, see
  [If you have Xcode 27.0 betas installed](#if-you-have-xcode-270-betas-installed).
- If configuration says Nix is missing, check `nix --version` in the same
  terminal that runs `build_app.sh` and Flutter.
