# Building with `make`

The `Makefile` is a thin wrapper around the steps in the per-host guides
([Linux](linux.md), [macOS](macos.md), [Windows](windows.md)). It runs the same
build steps as CI; CI passes `-d` explicitly for release builds. Run `make help` for all
targets. The toolchain and build paths are diagrammed in
[Make build flow](make-flow.md).

`make build-macos`, `build-linux` and `build-ios` run `verify-bom` before
configuring the app, so a toolchain or plugin-pin drift fails early. `make`
builds are local development builds. macOS/Linux/iOS outputs are not
release-signed; Android APKs are signed with `android/key.properties` (a
throw-away key if created via `make android-dev-key`) and must not be
distributed. If `lib/external_api_keys.dart` is missing, `prebuild.sh` creates
empty stubs, so swap providers are disabled; CI decodes the real keys before
building.

`build_app.sh` asks before replacing generated app files because some
version/build combinations can delete wallet data. `make` keeps that prompt
interactive; pass `CONFIRM=1` for a non-interactive run.

`VERSION` and `BUILD_NUM` set the app version and build number. Both are
required for build targets: `make` validates them and rejects a `BUILD_NUM`
that is not above the latest `build_*` tag. `APP_NAME` selects the app variant
(`stack_wallet`, `stack_duo` or `campfire`).

| Variable | Default | Purpose |
|---|---|---|
| `VERSION`, `BUILD_NUM` | required | App version and a build number above the latest release tag |
| `APP_NAME` | `stack_wallet` | `stack_wallet`, `stack_duo` or `campfire` |
| `PREBUILTS` | `0` on Apple Silicon/Linux when `nix` is on `PATH`; otherwise `1` | `0` builds dnix from source (needs `nix`); `1` uses verified prebuilts (`-d`) |
| `ANDROID_PREBUILTS` | follows `PREBUILTS` on x86_64 Linux when `nix` is on `PATH`, else `1` | Overrides the Android dnix mode |
| `SYSTEM_DEPS` | `0` | Linux: `1` uses system libsecret/JsonCPP (as CI does) |
| `TOOLCHAIN` | `auto` | `auto`, `nix`, `direnv`, `brew`, `host` or `manual` |
| `CONFIRM` | `0` | `1` answers build_app.sh's wallet-data warning non-interactively |

Source mode needs `nix` on `PATH`, whichever toolchain provides the rest of
the build tools. On Apple Silicon macOS and Linux, `PREBUILTS=0` is the
default when `nix` is available: dnix builds the pinned native libraries from
source and verifies their hashes. Without `nix`, the Makefile defaults to
`PREBUILTS=1`; Homebrew, manual and host toolchains can still pass
`PREBUILTS=0` when `nix` is on `PATH`. CI passes `-d` explicitly.

```
make build-macos VERSION=x.y.z BUILD_NUM=nnn              # dnix source (Nix/direnv, Apple Silicon)
make build-macos VERSION=x.y.z BUILD_NUM=nnn PREBUILTS=1  # verified prebuilts (-d), fast
```

## Targets

| Target | What it does |
|---|---|
| `make build-macos` | `build_app.sh -p macos -a $(APP_NAME)`, `flutter pub get`, `prebuild.sh`, `flutter build macos --release`. Source by default only in Nix/direnv on Apple Silicon; `PREBUILTS=1` uses the verified prebuilts |
| `make build-linux` | `prebuild.sh`, `build_app.sh -p linux`, local libsecret and secp256k1 helper builds, `flutter build linux --release`, then `prepare_release_bundle.py`. Source by default only inside Nix/direnv; `PREBUILTS=1` uses the verified prebuilts |
| `make build-windows` | Git Bash: `prebuild.sh`, `MWEBD_FETCH=1 build_app.sh -p windows -d` (`-d` selects verified prebuilts; secp256k1 is always built by this target), `pub get`, `flutter build windows --release`. Always uses the verified dnix prebuilts. Asset directories are copied on Windows. |
| `make build-android` | Same build commands as CI, without the AAB/upload steps; signs with `android/key.properties` (run `make android-dev-key` for a throw-away test key), needs the Android SDK/NDK and Java. Prebuilt dnix on macOS, non-x86_64 Linux and brew/manual toolchains; x86_64 Linux in Nix/direnv follows `PREBUILTS` |
| `make build-ios` | Same build commands as CI, without signing/packaging, on macOS (`flutter build ios --release --no-codesign`). Source by default only in Nix/direnv on Apple Silicon; CI passes `-d` explicitly |
| `make bootstrap` | Enter the Nix dev shell (primary toolchain); no-op when already inside |
| `make bootstrap-macos` | Check and select the full Xcode.app (Xcode is never provided by Nix) |
| `make toolchain` | Show the active toolchain (`nix`, `direnv`, `host`, `manual`) |
| `make bootstrap-xcode` | Check and select an installed full Xcode.app |
| `make check-reqs`, `check-reqs-macos`, `check-sdk-macos`, `diagnose-env-macos` | Prerequisite checks and an environment dump |
| `make verify-bom` | Compare the machine and `pubspec.lock` against `stack-bom.toml` |
| `make clean-app` / `make clean-native` | Remove app output / force the native-asset libraries to rebuild |
| `make clean` | Remove build output, Pods and the Flutter build cache |
| `make sccache-setup` / `make cache-stats` | Opt-in sccache wrapper / show sccache statistics |

## Toolchains on macOS

Source builds require a Nix/direnv shell; the prebuilt path (`PREBUILTS=1`)
uses the host tools on PATH (manual or host), which Homebrew can supply.

| Mode | Setup | Notes |
|---|---|---|
| Nix | `make bootstrap` (enters `nix develop`) | The flake provides Flutter and Go from its pinned nixpkgs (currently Flutter 3.47.2, matching the BOM, and Go 1.26.7; the BOM's `go` is the CI/Docker pin), Dart, rustup (which installs the BOM Rust version on first entry), CMake, Meson, Ninja, pkg-config and protoc. Xcode always comes from the host. |
| direnv | `direnv allow` | The same flake as Nix, loaded automatically. |
| Manual / Homebrew | install the tools yourself (Homebrew for the prebuilt path) | Source builds are not available without Nix. Use `PREBUILTS=1` with the verified dnix prebuilts; Homebrew can install the tooling (Flutter, Rust, Go, CocoaPods, sccache, …). `make check-reqs-macos` reports what is missing. |

`make toolchain` prints the active mode and tool paths.
`TOOLCHAIN=nix|direnv` forces a check; `host` and `manual` use whatever is on `PATH`; `auto` (the default) detects a Nix/direnv shell and otherwise uses the host tools. Any toolchain can use `PREBUILTS=0` when `nix` is on `PATH`; without it the Makefile defaults to prebuilt mode.

`make check-reqs-macos` verifies the result and `make diagnose-env-macos` prints what was found.

## Xcode

`make bootstrap-xcode` only checks and selects an installed Xcode. To install
one, use `dart tool/setup_xcode.dart` (which drives the `xcodes` CLI) or Apple's download
page; the Nix shell never provides Xcode. Source builds (`PREBUILTS=0`, needs
`nix` on `PATH`) need the Xcode 27.0 that dnix pins; `stack-bom.toml` recommends
27.0 for ordinary app builds, including Homebrew/manual prebuilt builds.

To build with another installed Xcode without changing the global selection,
run for example
`DEVELOPER_DIR=/Applications/Xcode_27.0.app/Contents/Developer make build-macos`.
This affects the Flutter/app build; a source build (`PREBUILTS=0`) still needs
the pinned Xcode 27.0. dnix checks the `xcode-select` choice first and then
scans `/Applications/Xcode*.app`.

## Keep the build environment the same between runs

Flutter reruns every native-asset build hook when `PATH` or any `NIX_*` variable differs from the previous build, even if no source changed. Measured on macOS: 33 to 40 s for a repeated build with an unchanged environment, 536 s after putting one extra directory in front of `PATH`, 156 to 164 s after adding a `NIX_*` variable or restoring `PATH`. So build always from the same shell setup (for example only through `make`, or only inside `nix develop`), and do not alternate between a terminal inside `nix develop` and an IDE without it.

## Toolchain bill of materials

`stack-bom.toml` lists the toolchain a build is expected to use (Flutter, Dart, Rust, Go, Xcode). It is not a Homebrew package manifest: the native dnix libraries are pinned in each plugin's `dnix.lock`, and the plugins themselves are pinned by `pubspec.lock`. `make verify-bom` compares the local machine against the BOM and exits with an error on a mismatch (a different recommended Flutter or Xcode version is only a warning). Source builds additionally require the Xcode 27.0 that dnix pins; `build_app.sh` enforces that, while `verify-bom` only warns.

## Optional: sccache for native-asset builds

`make sccache-setup` writes `$CARGO_HOME/config.toml` (or `~/.cargo/config.toml`) with `rustc-wrapper = "sccache"` (it never overwrites an
existing file). The build hooks only see a filtered environment (Flutter 3.47.x, and also the 3.50 beta tried so far), so
exporting `RUSTC_WRAPPER` does nothing in either: sccache saw no compile requests. Cargo still reads this file
through `HOME`, which works with both versions. (With the 3.50 beta the variable `CARGO_BUILD_RUSTC_WRAPPER`
also gets through.) Check `sccache --show-stats`
after a build. Measured on an Apple Silicon Mac for a from-source build of all native assets (one run each):
775 s without sccache, 665 s with a cold sccache, 534 s with a warm one. The prebuilt path
(`PREBUILTS=1`, `-d`) replaces all four dnix packages (frostdart, tor, epiccash and mwc); most of
the one-minute saving comes from the three heavy ones, so it saved about one minute in a cold build
(12 vs. 13 minutes).

## Linux notes

`make build-linux` needs `protoc`, Meson, Ninja, `patchelf` 0.18 or newer, `readelf` and `python3`; inside `nix develop` they are provided. Before building it writes `.cargo/config.toml` with `[env] PROTOC = "<protoc found in PATH>"` if the file does not exist (it is git-ignored). This is needed on NixOS, where a generic-Linux `protoc` shipped inside a crate cannot run and the exported variable does not reach the build hooks. Linux builds use a repo-local `.pub-cache` so cargo finds that file; other targets keep the normal per-user cache. `SYSTEM_DEPS=1` uses the system libsecret/JsonCPP packages (as CI does); the default builds them from source.
