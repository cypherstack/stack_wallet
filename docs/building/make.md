# Building with `make`

The `Makefile` is a thin wrapper around the steps in the per-host guides
([Linux](linux.md), [macOS](macos.md), [Windows](windows.md)). It runs the same
sequences as CI. Run `make help` for all targets.

`VERSION` and `BUILD_NUM` set the app version and build number. `APP_NAME`
selects the app variant (`stack_wallet`, `stack_duo` or `campfire`).
`PREBUILTS=0` compiles the dnix-pinned native libraries from source instead of
using the verified prebuilts (the `-d` default).

```
make build-macos VERSION=2.1.0 BUILD_NUM=210              # prebuilt native assets (-d), fast
make build-macos VERSION=2.1.0 BUILD_NUM=210 PREBUILTS=0  # compile native assets from source
```

## Targets

| Target | What it does |
|---|---|
| `make build-macos` | `build_app.sh -p macos -a $(APP_NAME) -s`, `flutter pub get`, `prebuild.sh`, `flutter build macos --release` |
| `make build-linux` | `build_app.sh -p linux`, local libsecret and secp256k1 helper builds, `flutter build linux --release`, then `prepare_release_bundle.py` |
| `make build-windows` | Git Bash: `prebuild.sh`, `build_app.sh -p windows -d -s`, `pub get`, `coinlib:build_windows`, `flutter build windows --release` |
| `make build-android` | CI `build-android` steps; needs the Android SDK/NDK and Java |
| `make build-ios` | CI `build-ios` steps on macOS (`flutter build ios --release --no-codesign`) |
| `make bootstrap-macos` | Homebrew host setup: Flutter 3.47.x, Rust 1.99.1, Go, CMake, CocoaPods |
| `make bootstrap-xcode` | Check and select an installed full Xcode.app |
| `make bootstrap-xcode-download` | Opt-in Xcode download from archive.org (SHA-1 and Apple signature checked) |
| `make check-reqs`, `check-reqs-macos`, `check-sdk-macos`, `diagnose-env-macos` | Prerequisite checks and an environment dump |
| `make verify-bom` | Compare the machine and `pubspec.lock` against `stack-bom.toml` |
| `make clean-app` / `make clean-native` | Remove app output / force the native-asset libraries to rebuild |
| `make sccache-setup` / `make cache-stats` | Opt-in sccache wrapper for the Rust/C builds run by native-asset hooks |

## Toolchain on macOS

Two ways to get Flutter 3.47.x, Rust 1.99.1, Go, CMake and CocoaPods. Both need a full Xcode.app.

- **Homebrew:** `make bootstrap-macos` runs `scripts/install_macos_build_tools.sh`. It installs the
  Homebrew packages, then uses an existing Flutter 3.47.2 or 3.47.4 or clones the pinned 3.47.2 tag
  (override with `FLUTTER_VERSION` / `FLUTTER_DIR`). It installs the pinned Rust toolchain via rustup,
  pins it for this checkout with `rustup override` (without changing your global default) and adds the
  PATH entries to `~/.zshrc`.
- **Nix:** `nix develop` (or `direnv allow` with the included `.envrc`) provides the toolchain from
  `flake.lock`. nixpkgs has no Flutter 3.47.2 (it goes from 3.47.0 to 3.47.4), so this shell uses
  Flutter 3.47.4; Rust 1.99.1 is installed through rustup on first entry. Xcode itself always comes from the host.

`make check-reqs-macos` verifies the result and `make diagnose-env-macos` prints what was found.

## Xcode (optional download)

`make bootstrap-xcode` only checks and selects an installed Xcode. To build with another installed Xcode without changing the global selection, run for example `DEVELOPER_DIR=/Applications/Xcode_27.0.app/Contents/Developer make build-macos`. If you have none, you can opt in to
`make bootstrap-xcode-download` (`scripts/download_xcode.sh`), which downloads a `.xip` (set `XCODE_XIP_URL` to use another mirror; the hash and signature are still checked) from
archive.org without an Apple ID. It checks the SHA-1 listed by archive.org and Apple's signature on
the archive, and aborts if either fails. Default is Xcode 27.1; use `XCODE_VERSION=27.0` when you need
the version that dnix pins to rebuild Apple libraries byte for byte. License acceptance and first-launch
setup only run with `ARGS=-y`. This route is not used in CI. Prefer the Mac App Store or developer.apple.com
if you can, since third-party redistribution of Xcode may conflict with Apple's terms.

## Keep the build environment the same between runs

Flutter reruns every native-asset build hook when `PATH` or any `NIX_*` variable differs from the previous build, even if no source changed. Measured on macOS: 33 to 40 s for a repeated build with an unchanged environment, 536 s after putting one extra directory in front of `PATH`, 156 to 164 s after adding a `NIX_*` variable or restoring `PATH`. So build always from the same shell setup (for example only through `make`, or only inside `nix develop`), and do not alternate between a terminal inside `nix develop` and an IDE without it.

## Toolchain bill of materials

`stack-bom.toml` lists the toolchain a build is expected to use (Flutter, Dart, Rust, Go, Xcode) and the git revisions of the pinned native plugins. `make verify-bom` compares the local machine and `pubspec.lock` against it and exits with an error on a mismatch (a different recommended Flutter or Xcode version is only a warning). After changing a plugin pin, run `dart tool/verify_bom.dart --update` to refresh the `[plugins]` section.

## Optional: sccache for native-asset builds

`make sccache-setup` writes `~/.cargo/config.toml` with `rustc-wrapper = "sccache"` (it never overwrites an
existing file). The build hooks only see a filtered environment (Flutter 3.47.x, and also the 3.50 beta tried so far), so
exporting `RUSTC_WRAPPER` does nothing in either: sccache saw no compile requests. Cargo still reads this file
through `HOME`, which works with both versions. (With the 3.50 beta the variable `CARGO_BUILD_RUSTC_WRAPPER`
also gets through.) Check `sccache --show-stats`
after a build. Measured on an Apple Silicon Mac for a from-source build of all native assets (one run each):
775 s without sccache, 665 s with a cold sccache, 534 s with a warm one. The prebuilt path (`-d`, the
`make build-macos` default) only replaces the tor, epiccash and mwc libraries, so it saved about one minute
in a cold build (12 vs. 13 minutes).

## Linux notes

`make build-linux` needs `protoc`, Meson, Ninja, `patchelf`, `readelf` and `python3`; inside `nix develop` they are provided. Before building it writes `.cargo/config.toml` with `[env] PROTOC = "<protoc found in PATH>"` if the file does not exist (it is git-ignored). This is needed on NixOS, where a generic-Linux `protoc` shipped inside a crate cannot run and the exported variable does not reach the build hooks. Linux builds use a repo-local `.pub-cache` so cargo finds that file; other targets keep the normal per-user cache.
