# Building

Use Flutter **3.47.2**. Run `flutter doctor` after installing Flutter and the
SDKs for your target. The build hosts covered here are Ubuntu 24.04 for Linux
and Android, Apple Silicon macOS for macOS and iOS, and native Windows for
Windows. Allow at least 100 GB of free space; source builds populate a Nix
store as well as Flutter and native compiler caches.

## Native build modes

`scripts/build_app.sh` generates `pubspec.yaml` and the platform configuration.
By default it selects **source** builds for the dnix packages. Add **`-d`** to
use their verified prebuilts instead:

| App | dnix packages |
|---|---|
| Stack Wallet | `frostdart`, `tor_ffi_plugin`, `flutter_libepiccash`, `flutter_libmwc` |
| Stack Duo | `frostdart`, `tor_ffi_plugin` |
| Campfire | `tor_ffi_plugin` |

Source mode builds with each package's pinned Nix recipe and checks the result
against the release hashes in that package's `dnix.lock`. Prebuilt mode downloads
the release library and checks it against the same hashes. A build or hash
failure stops the hook. Source mode can reuse outputs already in the Nix store;
it does not download a second copy of the release just to compare hashes.

The package Git revisions in the pubspec template and `pubspec.lock` pin the
recipes and expected hashes. **Stack Wallet does not need its own `dnix.lock`
or flake.** Updating a package means updating its Git revision and resolving
`pubspec.lock`; there are no app-level prebuilt manifest URLs to maintain.

The generated settings look like this, with an entry for each enabled package:

```yaml
hooks:
  user_defines:
    frostdart:
      build: source
```

Rerun `build_app.sh` to switch modes. It regenerates `pubspec.yaml`, so keep
permanent changes in `scripts/app_config/templates/pubspec.template.yaml`.
Remove any package-local `.dnix-build` development override when checking a
release: dnix gives that file precedence over the app's settings, and `dev`
mode skips hash verification. See [dnix build modes](https://github.com/cypherstack/dnix/blob/main/doc/configuration.md#build-modes).

### Which tools are still required?

| Component | Requirements |
|---|---|
| The four dnix packages, source mode | [Nix](https://nixos.org/download/); on Windows, Nix inside WSL2; for Apple targets, Xcode **27.0**, as pinned by the packages |
| The four dnix packages, `-d` | No Nix or package-specific Rust/C toolchain needed for these libraries |
| Flutter and platform plugins | Target SDKs and the platform's C/C++ build tools in either mode |
| Xelis (Stack Wallet) | Rustup on the Flutter host; its hook installs Rust **1.99.1** and the required target; Android needs NDK r28 or newer |
| Spark (Stack Wallet and Campfire) | CMake and a C++ compiler; its native-assets hook still builds from source |
| Coinlib secp256k1 | A separate platform build, described below |
| MWEB (Stack Wallet) | Go; CI uses **1.24.13**. The Windows executable has a separate WSL build or prebuilt download |
| Linux secure storage | System libraries with `-s`, or the dependencies to build libsecret and JsonCPP |

`-d` applies to the dnix packages, not every native library in the application.
Their old host Rust toolchain lists, `cbindgen`, `cargo-lipo`, and manually built
Epic/MWC/Tor dependencies are no longer required. Keep Rustup for Xelis and for
an optional Isar source build (`-f`). Nix supplies the four dnix packages' own
pinned toolchains, independently of the Rust installed on the host.

The macOS app deployment target is now **12.0** to accommodate the native
libraries. iOS remains 15.0, and the current Flutter Android minimum is API 24.

## Linux host

Install [Flutter](https://docs.flutter.dev/install/manual) 3.47.2 and
[Nix](https://nixos.org/download/) for source mode. Check `nix --version` from
the same environment that runs Flutter. dnix enables the Nix flake features
it needs when invoking Nix.

For Ubuntu 24.04 desktop builds, install:

```sh
sudo apt-get update
sudo apt-get install build-essential clang cmake ninja-build pkg-config \
  git curl unzip xz-utils python3 libgtk-3-dev liblzma-dev libssl-dev \
  libjsoncpp-dev libsecret-1-dev
```

Use `-s` to link the system secure-storage libraries, as CI does. If you leave
out `-s`, `build_app.sh` builds JsonCPP and libsecret and also needs:

```sh
sudo apt-get install meson libgirepository1.0-dev valac xsltproc \
  docbook-xsl libgcrypt20-dev libglib2.0-dev
```

For Stack Wallet, install [Rustup](https://rustup.rs/) and
[Go](https://go.dev/doc/install). Xelis installs its pinned Rust toolchain on
first use; you can install it ahead of time with `rustup toolchain install
1.99.1`.

### Android

Install [Android Studio](https://developer.android.com/studio/install#linux)
and its SDK command-line tools, platform tools, CMake, and the SDK platform
required by Flutter. The app pins NDK **28.2.13676358** in the Android template;
install it through SDK Manager. Run `flutter doctor --android-licenses` and
`flutter doctor` to check the installation. Android source builds through dnix
on Linux require an x86_64 host.

Use a physical Android device or an x86_64 emulator; 32-bit x86 emulators are
not supported. Enable KVM for hardware-accelerated emulation on Linux.

## Mac host

Install Flutter 3.47.2 on an Apple Silicon Mac. For source mode, install Nix
and **Xcode 27.0**, select that Xcode installation with `xcode-select`, and
complete its first-launch setup. The dnix hook checks the Xcode version when
building Apple targets. Prebuilt mode still needs the Xcode installation
required to build the Flutter app.

Install [Homebrew](https://brew.sh/) and the remaining native/plugin tools:

```sh
brew install autoconf automake libtool cmake cocoapods pkg-config
```

For Stack Wallet, also install Rustup and Go. You do not need to install
`cbindgen`, `cargo-lipo`, or the old Epic/MWC dependency list. Use
`flutter doctor` to check the Apple SDK and CocoaPods setup. iOS device builds
also need your usual signing configuration.

## Windows host

Keep Flutter, Dart, and the app checkout on Windows. Run the configuration
script from **Git Bash**, then use native Windows Flutter to build the app.
Install:

- [Flutter](https://docs.flutter.dev/install/manual) 3.47.2 and Git for Windows.
- [Visual Studio 2022](https://docs.flutter.dev/platform-integration/windows/setup)
  with **Desktop development with C++**, CMake tools, and a Windows SDK.
- Windows Developer Mode for symlinks used by Flutter and the asset scripts.
- Rustup on Windows for Stack Wallet's Xelis hook.
- WSL2 and Nix inside its Linux distribution for dnix source mode.

Follow Microsoft's [WSL installation guide](https://learn.microsoft.com/en-us/windows/wsl/install)
to install Ubuntu 24.04, then follow the [Nix installation instructions](https://nixos.org/download/)
inside that distribution. Check from PowerShell:

```powershell
wsl.exe --list --verbose
wsl.exe -d Ubuntu-24.04 -- /nix/var/nix/profiles/default/bin/nix --version
```

Adjust the Nix path if using a different installation. dnix finds Nix on the
WSL distribution's PATH or its standard profile paths. It invokes `wsl.exe`,
translates paths, builds a Windows DLL in Nix, copies it back to Windows, and
verifies it before Flutter bundles it. A second Flutter/Dart installation
inside WSL and manual copying of these four libraries are unnecessary.

By default, dnix uses the default WSL distribution. You can choose it with
`wsl.exe --set-default Ubuntu-24.04`, or add
`wsl_distribution: Ubuntu-24.04` beside `build: source` in **each** enabled
package's hook settings. Keep native package checkouts in LF form and preserve
symlinks and executable permissions; filesystem differences can cause a hash
mismatch. See [dnix Windows source builds](https://github.com/cypherstack/dnix/blob/main/doc/configuration.md#windows-source-builds)
for checkout and environment details.

### MWEB and secp256k1

Stack Wallet's Windows MWEB executable has a separate build path. By default,
its configuration helper uses Go and `x86_64-w64-mingw32-gcc` inside the default
WSL distribution. Install Go there (CI uses 1.24.13) and `sudo apt-get install
mingw-w64`. Alternatively, set `MWEBD_FETCH=1` when running `build_app.sh` to
fetch the existing MWEB release and check its published checksum. This setting
is independent of `-d` and dnix's `wsl_distribution`.

In source mode, `build_app.sh` builds secp256k1 natively when invoked from Git
Bash. With `-d` or `-i`, build it separately after configuring the app:

```sh
flutter pub get
dart run coinlib:build_windows
```

The legacy Linux/WSL configuration path still uses
`scripts/windows/build_secp256k1_wsl.sh` and needs CMake plus MinGW in WSL.
The old MXE setup and Epic-specific CMake upgrade are not needed for dnix.

## Configure and build

Clone the repository, then run the setup from its root:

```sh
git clone https://github.com/cypherstack/stack_wallet.git
cd stack_wallet
bash scripts/prebuild.sh
```

`prebuild.sh` creates the API-key and test-wallet parameter stubs needed to
compile. On Windows you can also use
`powershell -ExecutionPolicy Bypass -File scripts/prebuild.ps1`.

All four configuration arguments are required:

```sh
bash scripts/build_app.sh -a stack_wallet -p linux -v 1.2.3 -b 123 -s
flutter pub get
flutter build linux --release
```

Use the appropriate version/build number for your checkout and read the
script's confirmation before proceeding. To use verified dnix prebuilts,
add `-d` to the configuration command. For example:

```sh
bash scripts/build_app.sh -a stack_wallet -p linux -v 1.2.3 -b 123 -s -d
```

| Option | Meaning |
|---|---|
| `-a` | `stack_wallet`, `stack_duo`, or `campfire` |
| `-p` | `android`, `ios`, `macos`, `linux`, or `windows` |
| `-v`, `-b` | App version and numeric build number |
| `-d` | Verified dnix prebuilts; default is verified source builds |
| `-i` | Skip the script's secure-storage and secp256k1 builds; native-assets hooks still run |
| `-s` | Use system Linux secure-storage libraries |
| `-f` | Use the existing optional Isar source-build helper; requires its cached source and Rust |
| `-h` | Show help |

Choose `-p` for your target and then run the corresponding Flutter build:

| Target | Build command |
|---|---|
| Android | `flutter build apk --release` |
| Linux | `flutter build linux --release` |
| macOS | `flutter build macos --release` |
| iOS | `flutter build ios --release` |
| Windows | `flutter build windows --release` |

The configuration script also runs asset generators on non-Linux targets.
Those `dart run` commands can execute native-assets hooks, so install the
required source-build tools **before** running the configuration script.
The selected mode persists for subsequent `flutter run`, `flutter test`, and
`flutter build` commands until you regenerate the configuration.

For development, use `flutter devices` and then `flutter run -d <device-id>`.
The Linux setup builds secp256k1 unless `-i` was supplied. If it was skipped,
run `(cd scripts/linux && bash build_secp256k1.sh)` before starting the app.
On macOS, run `dart run coinlib:build_macos` after `flutter pub get` to prepare
the separate desktop secp256k1 library.

### Linux release bundle preparation

After `flutter build linux --release`, run this from the repository root before
archiving the bundle or using it to build an AppImage or Flatpak:

```sh
sudo apt-get install binutils patchelf python3
python3 scripts/linux/prepare_release_bundle.py build/linux/x64/release/bundle
```

The helper clears the executable-stack flag on the bundled Monero, Wownero and
Salvium wallet libraries, which modern Linux loaders can otherwise reject. It
then checks every ELF in the bundle and fails if any still requests an executable
stack. Other libraries are not patched automatically. CI runs this before
producing the Linux tarball, so downstream packagers inherit the prepared bundle.

Standalone regression tests (also require a C compiler):

```sh
python3 -m unittest discover -s scripts/linux/tests -p 'test_*.py' -v
```

## CI and configuration checks

Application CI uses `-d` for all three apps, so it verifies the four packages'
prebuilts without rebuilding their Nix recipes or installing Nix/WSL. Native
source-build and reproducibility checks belong to the packages' own CI.
Xelis, Spark, and other non-dnix components keep their existing build paths.

After configuring an app and running `flutter pub get`, check template/mode
selection without compiling native libraries:

```sh
dart scripts/tests/native_build_config_test.dart
dart scripts/tests/build_input_test.dart
```

The configuration tests exercise all three apps, switching modes, and the
Windows/WSL secp256k1 dispatch using stubbed native tools. Actual native Windows
to WSL builds are tested in dnix's CI; these app tests do not run WSL.

## Xelis tests

Run on a configured desktop target (`windows`, `linux`, or `macos`) with
the application's native plugin dependencies:

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

# Troubleshooting

Run with `-v` or `--verbose` to see a more detailed error.  Certain exceptions (like missing a plugin library) may not report quality errors without `verbose`, especially on Windows.

## Tor

To test Tor usage, run Stack Wallet from Android Studio.  Click the Flutter DevTools icon in the Run tab (next to the Hot Reload and Hot Restart buttons) and navigate to the Network tab.  Connections using Tor will show as `GET InternetAddress('127.0.0.1', IPv4) 101 ws`.  Connections outside of Tor will show the destination address directly (although some Tor requests may also show the destination address directly, check the Headers take for *eg.* `{localPort: 59940, remoteAddress: 127.0.0.1, remotePort: 6725}`.  `localPort` should match your Tor port.
