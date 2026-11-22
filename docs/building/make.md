# Building with make

The `Makefile` is a thin wrapper around `scripts/build_app.sh` and `flutter build`. It
checks that the requirements are met, runs the same steps as the other guides and picks the
dnix mode for you. **Every build needs Nix**: the flake (`flake.nix`) is the toolchain, and
the four dnix packages are either compiled from source (`PREBUILTS=0`) or taken as verified
prebuilts (`PREBUILTS=1`). Windows (Git Bash) is the one exception: it has no Nix and always
uses the prebuilts.

## Quick start

```sh
make bootstrap-macos                 # macOS: install Nix (asks first) and select a full Xcode
                                     # Linux: make bootstrap-nix (see "Linux" below)
make bootstrap                       # enter the Nix dev shell (or: direnv allow)
make build-macos VERSION=x.y.z BUILD_NUM=nnn
```

`VERSION` and `BUILD_NUM` are required; `BUILD_NUM` must not be below the latest `build_*`
release tag. Without an active Nix shell `make` stops and says what to run.

The flake supports Apple Silicon macOS and Linux (x86_64, aarch64). It provides Flutter, Go,
rustup, sccache, CMake, Meson, Ninja, pkg-config and protoc from a pinned nixpkgs, and
installs the Rust toolchains on first entry. Xcode always comes from the host.

## Versions

The versions live in one place, the top of `flake.nix`: the two Rust toolchains and the Xcode
that dnix source builds need. The dev shell installs the Rust versions and exports all three
as `STACK_RUST_VERSION`, `STACK_DNSSEC_RUST_VERSION` and `STACK_XCODE_VERSION`, which
`make check-reqs` and `make toolchain` read. Flutter and Go come from the pinned nixpkgs; to
change them, change the nixpkgs revision in `flake.nix` and run `nix flake lock`. The Nix shell
provides Flutter 3.47.4 while upstream CI uses 3.47.2 (nixpkgs never packaged 3.47.2).

## Requirements on macOS

| Target | What it does |
|---|---|
| `bootstrap-nix` | installs Nix on macOS or Linux with the official installer (asks before it runs a downloaded script as root; `NIX_INSTALL_YES=1` skips the question) and enables the `nix-command` and `flakes` features |
| `bootstrap-macos` | `bootstrap-nix`, then checks or selects the full Xcode |
| `bootstrap-xcode` | selects an installed full Xcode, accepts the licence and runs first-launch setup when it changes the selection |
| `bootstrap-xcode-download` | opt-in: downloads Xcode from archive.org with an SHA-1 check and Apple's signature check (`XCODE_VERSION=27.0`, `ARGS=-y` to skip prompts); refuses to run in CI and aborts on a hash mismatch before it extracts anything |
| `check-reqs`, `check-reqs-macos`, `check-sdk-macos`, `diagnose-env-macos` | test the requirements (Nix shell, tools, pinned Rust toolchains, Xcode and SDK) and print the environment |

dnix source builds need the pinned Xcode (27.0) installed next to your usual one; it need not
be selected. `check-sdk-macos` fails with the fix when it is missing and `PREBUILTS=0`.

## Linux (Ubuntu and others)

```sh
make bootstrap-nix                   # installs Nix (multi-user with systemd, else single-user)
make bootstrap                       # enter the Nix dev shell (or: direnv allow)
make build-linux VERSION=x.y.z BUILD_NUM=nnn
```

In CI or scripts use `nix develop --command make build-linux ...` instead of an interactive
shell. The flake supplies every build dependency (GTK, libsecret, protoc, the C/C++ and Rust
toolchains), so no `apt` packages are needed.

A bundle built this way is **for the machine that built it, not for distribution**: its ELF
interpreter and `RUNPATH` point into `/nix/store`, so it only starts where those exact store
paths exist. Use the Nix build to develop, test and verify reproducibly. For a release that
runs on a stock Ubuntu, build without Nix as described in the [Linux guide](linux.md) (the CI
image and `-s` system libraries), or package the Nix closure (AppImage, Flatpak).

## Targets

| Target | What it does |
|---|---|
| `build-macos`, `build-ios` | `build_app.sh`, `flutter pub get`, `prebuild.sh`, `flutter build` (iOS without code signing) |
| `build-linux` | the same, plus the libsecret and secp256k1 helpers and `prepare_release_bundle.py` |
| `build-windows` | Git Bash; the same with verified prebuilts (`-d`); no Nix |
| `build-android` | APKs; needs the Android SDK and `android/key.properties` (`make android-dev-key` makes a throw-away test key, never use it for releases) |
| `bootstrap`, `toolchain` | enter the Nix shell; show whether it is active, the pinned versions and the tool paths |
| `clean`, `clean-app`, `clean-native` | remove everything, or build output only (keeps `.dart_tool/hooks_runner`), or the native libraries only |
| `sccache-setup`, `cache-stats` | opt-in sccache for the hooks' Rust/C builds, and its hit rate |

## Variables

| Variable | Default | Meaning |
|---|---|---|
| `VERSION`, `BUILD_NUM` | required | app version and build number |
| `APP_NAME` | `stack_wallet` | `stack_wallet`, `stack_duo` or `campfire` |
| `PREBUILTS` | `0` on Apple Silicon and Linux | `0` builds the four dnix packages from source and verifies their hashes; `1` uses the verified prebuilts (`-d`) |
| `ANDROID_PREBUILTS` | follows `PREBUILTS` on x86_64 Linux, else `1` | dnix mode for Android |
| `SYSTEM_DEPS` | `0` | Linux: `1` uses system libsecret and JsonCPP (as CI does) |
| `CONFIRM` | `0` | `1` answers the wallet-data warning of `build_app.sh` non-interactively |
| `FLUTTER` | from `PATH` | explicit Flutter binary |

`PREBUILTS=0` needs the Nix shell and, on macOS, Apple Silicon; Windows rejects it. Calling
`scripts/build_app.sh` directly without `-d` only needs `nix` on `PATH`.

## Caches and benchmarks

`make sccache-setup` writes `~/.cargo/config.toml` with `rustc-wrapper = "sccache"` if the
file does not exist, because Flutter 3.47.x hooks see sccache only that way; remove the file
to turn it off. `make cache-stats` shows the hit rate. The `bm/` scripts measure what each
cache is worth: see [bm/README.md](../../bm/README.md).

## Notes

- If Flutter's hooks rerun every native build, the environment changed between runs (`PATH`
  or a `NIX_*` variable). Build always from the same shell.
- On NixOS the Android build needs `programs.nix-ld.enable = true` and a writable Flutter SDK;
  see the [Linux guide](linux.md).
