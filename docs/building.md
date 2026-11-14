# Building

Stack Wallet, Stack Duo and Campfire are built from this repository with
Flutter **3.47.2**. Follow the guide for the computer you build on:

| Your computer | What it builds | Guide |
|---|---|---|
| Linux (Ubuntu 24.04, x86_64) | Linux desktop, Android | [Building on Linux](building/linux.md) |
| Mac with Apple Silicon | macOS, iOS | [Building on macOS](building/macos.md) |
| Windows | Windows desktop | [Building on Windows](building/windows.md) |

Allow at least 100 GB of free disk space. Source builds fill a Nix store as
well as Flutter and native compiler caches.

## How a build works

1. Install the prerequisites listed in your guide, including the SDKs for
   your target, then run `flutter doctor`.
2. Run `scripts/prebuild.sh` to create the API-key and test-wallet stubs the
   app needs to compile.
3. Configure one app for one target with `scripts/build_app.sh`. It checks
   your tools, then generates `pubspec.yaml` and the platform files.
4. Run `flutter pub get`, the override check, and `flutter build`.

Each guide gives the exact commands.

## Source builds and prebuilts

Four native packages are built with [dnix](https://github.com/cypherstack/dnix):

| App | dnix packages |
|---|---|
| Stack Wallet | `frostdart`, `tor_ffi_plugin`, `flutter_libepiccash`, `flutter_libmwc` |
| Stack Duo | `frostdart`, `tor_ffi_plugin` |
| Campfire | `tor_ffi_plugin` |

By default, configuration selects **source** builds: each package is built
from its pinned Nix recipe and checked against the release hashes in its
`dnix.lock`. Add **`-d`** to use the verified prebuilt libraries instead; they
are checked against the same hashes, and you don't need Nix. `-d` applies only
to these four packages; the app's other native libraries build the same way in
either mode.

To switch modes, rerun `build_app.sh`. It regenerates `pubspec.yaml`, so keep
permanent changes in `scripts/app_config/templates/pubspec.template.yaml`.

## Configuration options

`-a`, `-p`, `-v` and `-b` are required:

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

Before it replaces any generated files, configuration checks Rustup, Go for
Stack Wallet, source-mode Nix/WSL/Xcode requirements, the Windows secp256k1
tools, and the WSL tools for Stack Wallet's Windows MWEB build. A failed dnix
check explains how to use `-d` instead; `-d` still needs Rustup.

## More detail

- [Native libraries in depth](building/native-libraries.md): how the dnix
  packages are pinned and verified, local overrides, and what every native
  component needs.
- [Testing the build setup](building/testing.md): configuration tests, Linux
  bundle tests, Xelis integration tests, and checking Tor routing.
- [Building with `make`](building/make.md): optional Makefile wrapper that runs
  the same CI build steps.

## Troubleshooting

Run Flutter commands with `-v` (`--verbose`) to see more detail. Some errors,
such as a missing plugin library, are only reported clearly with verbose
output, especially on Windows.
