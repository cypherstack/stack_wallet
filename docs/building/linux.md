# Building on Linux

These steps build the Linux desktop app and the Android app on Ubuntu 24.04
(x86_64). For how the build fits together, see the [overview](../building.md).

## Prerequisites

| What | Needed for |
|---|---|
| [Flutter](https://docs.flutter.dev/install/manual) 3.47.2 | Every build |
| The [Ubuntu packages](#ubuntu-packages) below | Every build |
| [Rustup](https://rustup.rs/) | Every app, in both modes |
| [Go](https://go.dev/doc/install) 1.24.1 or newer | Stack Wallet |
| [Nix](https://nixos.org/download/) | Source mode, the default; not needed with `-d` |
| The [Android tools](#android-tools) below | Android builds |

**Rustup:** every app builds its DNSSEC resolver with Rust **1.90.0**, and
Stack Wallet builds Xelis with Rust **1.99.1**. The build hooks install these
toolchains on first use. To install DNSSEC's ahead of time, run
`rustup toolchain install 1.90.0`.

**Nix:** check `nix --version` from the same environment that runs Flutter.
dnix enables the Nix flake features it needs when it invokes Nix.

### Ubuntu packages

```sh
sudo apt-get update
sudo apt-get install build-essential clang cmake ninja-build pkg-config \
  git curl unzip xz-utils python3 libgtk-3-dev liblzma-dev libssl-dev \
  libjsoncpp-dev libsecret-1-dev
```

`build_app.sh` builds JsonCPP and libsecret for the Linux app, which also needs:

```sh
sudo apt-get install meson libgirepository1.0-dev valac xsltproc \
  docbook-xsl libgcrypt20-dev libglib2.0-dev
```

### Android tools

Install [Android Studio](https://developer.android.com/studio/install#linux)
with its SDK command-line tools, platform tools, CMake, and the SDK platform
Flutter requires. The app pins NDK **28.2.13676358** in its Android template;
install it through SDK Manager. Then run `flutter doctor --android-licenses`
and `flutter doctor`. The app supports Android API 24 and newer.

## Build

1. Clone the repository and create the stubs:

   ```sh
   git clone https://github.com/cypherstack/stack_wallet.git
   cd stack_wallet
   bash scripts/prebuild.sh
   ```

2. Configure and build the Linux app:

   ```sh
   bash scripts/build_app.sh -a stack_wallet -p linux -v 1.2.3 -b 123
   flutter pub get
   dart tool/check_native_overrides.dart stack_wallet
   flutter build linux --release
   ```

   For Android, configure with `-p android` and build with
   `flutter build apk --release`. Android release builds need
   `android/key.properties` pointing at your keystore, with `keyAlias`,
   `keyPassword`, `storeFile` and `storePassword`.

Use the version and build number for your checkout, and read the script's
confirmation before continuing. Add `-d` to the configuration command to use
verified dnix prebuilts:

```sh
bash scripts/build_app.sh -a stack_wallet -p linux -v 1.2.3 -b 123 -d
```

See the [configuration options](../building.md#configuration-options). The
override check catches package-local dnix overrides; see
[Local overrides](native-libraries.md#local-overrides).

## Run during development

Use `flutter devices`, then `flutter run -d <device-id>`. For Android, use a
physical device or an x86_64 emulator; 32-bit x86 emulators are not supported.
Enable KVM for hardware-accelerated emulation.

`build_app.sh` builds secp256k1 for the Linux app unless you pass `-i`. If you
skipped it, run `(cd scripts/linux && bash build_secp256k1.sh)` before starting
the app.

Android source builds through dnix need an x86_64 Linux host.

## Prepare a release bundle

After `flutter build linux --release`, run this from the repository root before
archiving the bundle or using it to build an AppImage or Flatpak:

```sh
sudo apt-get install binutils patchelf python3
python3 scripts/linux/prepare_release_bundle.py build/linux/x64/release/bundle
```

The helper clears the executable-stack flag on the bundled Monero, Wownero and
Salvium wallet libraries, which modern Linux loaders can otherwise reject. It
then checks every ELF in the bundle and fails if any still requests an
executable stack. Other libraries are not patched automatically. CI runs this
before producing the Linux tarball, so downstream packagers get the prepared
bundle. Its regression tests are described in
[Testing the build setup](testing.md#linux-release-bundle-tests).

## Troubleshooting

- Run Flutter commands with `-v` for more detail.
- If configuration says Nix is missing, check `nix --version` in the same
  terminal that runs `build_app.sh` and Flutter.
