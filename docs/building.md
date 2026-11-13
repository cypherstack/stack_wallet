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

The generated settings look like this, with entries for all four packages.
Settings for packages absent from the selected app are ignored:

```yaml
hooks:
  user_defines:
    frostdart:
      build: source
```

Rerun `build_app.sh` to switch modes. It regenerates `pubspec.yaml`, so keep
permanent changes in `scripts/app_config/templates/pubspec.template.yaml`.
Configuration rejects package-local `.dnix-build` overrides in enabled packages:
dnix gives those files precedence over the app's settings, and `dev` mode skips
hash verification. Remove the reported overrides and run `flutter clean` before
reconfiguring. After changing local dependency overrides or resolving packages
separately, rerun `dart tool/check_native_overrides.dart <app>` before building.
This guard checks the selected Git pins and existing package resolution; an old
resolution may need refreshing too. Direct Flutter commands do not run the guard.
See [dnix build modes](https://github.com/cypherstack/dnix/blob/main/doc/configuration.md#build-modes).

Normal builds use the pinned Git packages. If you explicitly override a package
with a local checkout, that package's `dnix.lock` must be present for verified
builds. Without it, dnix falls back to `dev` and skips hash verification even
when source or prebuilt mode is selected. The override guard above does not
check for missing locks. With `-d`, a checkout that keeps its `dnix.lock` gets
that lock's release library, so local native changes are not built; remove the
lock to build them in `dev` mode.

### Which tools are still required?

| Component | Requirements |
|---|---|
| The four dnix packages, source mode | [Nix](https://nixos.org/download/); on Windows, Nix inside WSL2; on a Mac, Xcode **27.0** for every target, including `flutter test`, as pinned by the packages |
| The four dnix packages, `-d` | No Nix or package-specific Rust/C toolchain needed for these libraries |
| Flutter and platform plugins | Target SDKs and the platform's C/C++ build tools in either mode |
| OpenAlias / DNSSEC (every app) | Rustup on the Flutter host in both modes; `dnssec_resolver` builds from source with Rust **1.90.0** |
| Xelis (Stack Wallet) | Rustup; its hook installs Rust **1.99.1** and the required target; Android needs NDK r28 or newer |
| Spark (Stack Wallet and Campfire) | CMake and a C++ compiler; its native-assets hook still builds from source |
| Coinlib secp256k1 | A separate platform build, described below |
| MWEB (Stack Wallet) | Go **1.24.1** or newer; CI uses 1.24.13. The Windows executable has a separate WSL build (Go 1.24.0 or newer) or prebuilt download |
| Linux secure storage | The dependencies to build libsecret and JsonCPP |

`-d` applies to the dnix packages, not every native library in the application.
Their old host Rust toolchain lists, `cbindgen`, `cargo-lipo`, and manually built
Epic/MWC/Tor dependencies are no longer required. **Keep Rustup for every app**:
unconditional `cs_openalias` depends on the source-built `dnssec_resolver`.
Stack Wallet also needs it for Xelis. These hooks install their pinned toolchains
automatically. The optional Isar source build (`-f`) separately uses Rust
**1.99.1**, installing it through Rustup if missing without changing your default
toolchain. Nix supplies the four dnix packages' own pinned toolchains,
independently of the Rust installed on the host.

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

`build_app.sh` builds JsonCPP and libsecret, which also needs:

```sh
sudo apt-get install meson libgirepository1.0-dev valac xsltproc \
  docbook-xsl libgcrypt20-dev libglib2.0-dev
```

Install [Rustup](https://rustup.rs/) for **all three apps**, including prebuilt
mode. You can preinstall DNSSEC's toolchain with `rustup toolchain install
1.90.0`. Stack Wallet also needs [Go](https://go.dev/doc/install) and Xelis'
Rust **1.99.1** toolchain, which its hook installs on first use. The Docker images
install Rustup only; hooks install toolchains under the runtime user's HOME.
Preinstalling them under custom image-only `RUSTUP_HOME`/`CARGO_HOME` paths does
not help because the hook runner does not forward those variables.

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

On an Apple Silicon Mac, install Flutter 3.47.2 and
[Nix](https://nixos.org/download/) for source mode. Check `nix --version` from
the same environment that runs Flutter. **Xcode 27.0 is required
for verified source builds of the Apple libraries** (release build **27A266a**);
a different version can produce different hashes. Prebuilt mode still needs Xcode to build the Flutter
app. Install 27.0 alongside your existing Xcode, under `/Applications` with a
name matching `Xcode*.app`. dnix normally finds the pinned version there; you
can keep a different stable Xcode selected system-wide. See the beta limitation
below when keeping multiple builds of 27.0 installed.

### Install with xcodes

Install the [xcodes CLI](https://github.com/XcodesOrg/xcodes) from
[Homebrew core](https://formulae.brew.sh/formula/xcodes), then run our
standalone helper from the repository root:

```sh
brew install xcodes
dart tool/setup_xcode.dart
```

Use plain `dart`, as shown, so setup does not run the application's native build
hooks. The helper opens a separate Terminal window, reuses an installed 27.0 or
downloads it with `xcodes install 27.0 --no-superuser --update`, then runs Apple's
first-launch setup, which accepts the Xcode license. Wait for **Setup complete**
in that window before building. Preview the commands with
`dart tool/setup_xcode.dart --print`.

The helper finds `xcodes` on your current PATH before cleaning the environment,
including Mint, MacPorts, Nix, and globally configured mise/asdf shims. It selects
the **27A266a** release build. If another build of 27.0 is installed and the
release is missing, it gives manual side-by-side installation instructions:
xcodes can refuse to install two builds of the same version. Existing bundles
are preserved. The setup window waits for Return after displaying its result,
so you can copy the instructions even with a close-on-exit profile.

The helper and preflight read `toolchains.xcode` and, when available,
`toolchains.xcodeBuild` from the packages' `dnix.json`. For the current packages,
which lack a build-number pin, `tool/native_dependency_compatibility.json`
records the reviewed release for each exact Git revision. Updating a revision
requires either an upstream build-number pin or a reviewed compatibility entry.
Preflight checks only packages enabled for the selected app; the standalone
setup helper checks all four packages. On a fresh checkout, metadata is fetched
from the pinned GitHub commits when it is absent from the pub cache; this also
applies to `--print`.

The installer runs in a clean environment without shell startup files or build
commands. `xcodes` handles Apple account prompts; `sudo -k` prompts directly for
the administrator password and does not create a reusable sudo ticket. Dart
does not read either password. This separates the terminal and processes; it
is not an OS sandbox. Project-specific shim configuration is not forwarded;
use a globally configured xcodes installation or its executable directly on
PATH. `xcodes` may remember Apple account credentials in your Keychain according
to its own settings.

### Install from Apple's developer website

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
   Confirm the second prints `Xcode 27.0` and `Build version 27A266a`, then close
   that setup window. You can also run our Dart helper after moving the app; it reuses that installation.

### Select Xcode for a build

In your normal build terminal, select 27.0 for Flutter and Xcode commands in that
shell only. Substitute the path printed by the helper (`xcodes` may name the bundle `Xcode-27.0.0.app`):

```sh
export DEVELOPER_DIR=/Applications/Xcode-27.0-27A266a.app/Contents/Developer
xcodebuild -version
flutter doctor
```

Run configuration and Flutter build commands in this shell. `unset DEVELOPER_DIR`
returns it to the system default. For iOS simulation, install the required
simulator runtime from this Xcode's Settings > Components.

**Native hooks do not inherit `DEVELOPER_DIR`.** dnix checks the system-wide
Xcode selection first, then scans `/Applications/Xcode*.app`. The current
packages pin version 27.0 but do not yet pin `toolchains.xcodeBuild`, so a 27.0
beta can be selected ahead of the release even after setup succeeds. The app's
source preflight rejects that case before changing configuration. Use `-d`, or
keep that beta outside the scanned paths and ensure it is not the system-wide
selection. An upstream package build-number pin is still needed to make this
selection unambiguous for direct Flutter builds too. Exporting `DEVELOPER_DIR`
does not fix it. Other native hooks such as Spark/MWEB also discover tools
independently of this export.

### Other Mac tools

Install [Homebrew](https://brew.sh/) and the remaining native/plugin tools:

```sh
brew install autoconf automake libtool cmake cocoapods pkg-config
```

Install Rustup for **every app**, and Go for Stack Wallet. You do not need to install
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
- Rustup on Windows for every app's DNSSEC hook and Stack Wallet's Xelis hook.
- WSL2 and Nix inside its Linux distribution for dnix source mode.
- Go and `mingw-w64` in the default WSL distribution for Stack Wallet's MWEB
  build, unless you set `MWEBD_FETCH=1` (see [MWEB and secp256k1](#mweb-and-secp256k1)).

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

By default, dnix uses the default WSL distribution. Select it persistently with
`wsl.exe --set-default Ubuntu-24.04`, or put
`export DNIX_WSL_DISTRIBUTION=Ubuntu-24.04` in your Git Bash profile.
`build_app.sh` renders that setting for every enabled dnix package on each run;
`-w Ubuntu-24.04` overrides it for one configuration. Editing only the generated
`pubspec.yaml` will not survive reconfiguration. Keep native checkouts in LF form and preserve
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

In **both** dnix modes, `build_app.sh` builds secp256k1 unless `-i` is supplied.
The helper finds Visual Studio 2022's bundled CMake through `vswhere`, so Git
Bash does not need a Developer Command Prompt. It checks tools before changing
app configuration and stops on failed build commands. After `-i`, run:

```sh
dart scripts/windows/build_secp256k1.dart
```

The helper builds secp256k1 **v0.5.0**
(`e3a885d42a7800c1ccebad94ad1e2b82c4df5c65`) with MSVC. dnix's
hash-verification guarantee applies to its four packages, not secp256k1. Each
build recompiles the DLL; `-i` skips this step during configuration. The old MXE
setup and Epic-specific CMake upgrade are not needed for dnix.

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
bash scripts/build_app.sh -a stack_wallet -p linux -v 1.2.3 -b 123
flutter pub get
dart tool/check_native_overrides.dart stack_wallet
flutter build linux --release
```

Use the appropriate version/build number for your checkout and read the
script's confirmation before proceeding. To use verified dnix prebuilts,
add `-d` to the configuration command. For example:

```sh
bash scripts/build_app.sh -a stack_wallet -p linux -v 1.2.3 -b 123 -d
```

| Option | Meaning |
|---|---|
| `-a` | `stack_wallet`, `stack_duo`, or `campfire` |
| `-p` | `android`, `ios`, `macos`, `linux`, or `windows` |
| `-v`, `-b` | App version and numeric build number |
| `-d` | Verified dnix prebuilts; default is verified source builds |
| `-i` | Skip the script's secure-storage and secp256k1 builds; native-assets hooks still run |
| `-f` | Use the existing optional Isar source-build helper; requires its cached source and Rust |
| `-w` | Set the dnix WSL distribution; overrides `DNIX_WSL_DISTRIBUTION` |
| `-h` | Show help |

Choose `-p` for your target and then run the corresponding Flutter build:

| Target | Build command |
|---|---|
| Android | `flutter build apk --release` |
| Linux | `flutter build linux --release` |
| macOS | `flutter build macos --release` |
| iOS | `flutter build ios --release` |
| Windows | `flutter build windows --release` |

Android release builds need `android/key.properties` pointing at your keystore,
with `keyAlias`, `keyPassword`, `storeFile` and `storePassword`.

Configuration checks Rustup, Go for Stack Wallet, source-mode Nix/WSL/Xcode
requirements, the Windows secp256k1 tools, and the WSL tools for Stack Wallet's
Windows MWEB build before replacing generated files. A dnix requirement
failure explains how to use `-d` instead; `-d` still requires Rustup for DNSSEC.
The icon/splash `dart run` commands use only those executables' dependency
closures and do **not** run the app's native hooks. App hooks run with later
`flutter run`, `flutter test`, and `flutter build` commands, using the selected
mode until you regenerate the configuration.

For development, use `flutter devices` and then `flutter run -d <device-id>`.
The Linux setup builds secp256k1 unless `-i` was supplied. If it was skipped,
run `(cd scripts/linux && bash build_secp256k1.sh)` before starting the app.
On macOS, application builds compile and bundle secp256k1 through the Coinlib
Flutter plugin. Only host-side Dart/Flutter tests need the separate library
from `dart run coinlib:build_macos` after `flutter pub get`.

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
Every app still builds DNSSEC with Rust 1.90.0. Xelis, Spark, and other non-dnix
components keep their existing build paths; CI retains Rustup for all apps.

After configuring an app and running `flutter pub get`, check template/mode
selection without compiling native libraries:

```sh
dart scripts/tests/native_build_config_test.dart
dart scripts/tests/build_input_test.dart
```

Configuration tests exercise all three apps, both modes, persistent WSL settings,
Linux builds, and Windows output locations using stubbed native tools. Separate
tests cover prerequisite failures, Xcode setup, Windows tool discovery, and the
secp256k1 build helper. A small Windows CI job runs the PowerShell prebuild regression
tests. Actual native Windows to WSL builds are tested in dnix's CI; these app
tests do not run WSL.

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
