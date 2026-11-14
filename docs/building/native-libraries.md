# Native libraries in depth

This page is for maintainers and for anyone overriding native packages. For
build steps, see the [overview](../building.md).

## How the dnix packages are pinned and verified

Source mode builds each dnix package with its pinned Nix recipe and checks the
result against the release hashes in that package's `dnix.lock`. Prebuilt mode
downloads the release library and checks it against the same hashes. A build
or hash failure stops the hook. Source mode can reuse outputs already in the
Nix store; it does not download a second copy of the release just to compare
hashes.

The package Git revisions in the pubspec template and `pubspec.lock` pin the
recipes and expected hashes. **Stack Wallet does not need its own `dnix.lock`
or flake.** Updating a package means updating its Git revision and resolving
`pubspec.lock`; there are no app-level prebuilt manifest URLs to maintain.

`build_app.sh` writes the selected mode into the generated `pubspec.yaml`, with
entries for all four packages. Settings for packages the selected app doesn't
use are ignored:

```yaml
hooks:
  user_defines:
    frostdart:
      build: source
```

See [dnix build modes](https://github.com/cypherstack/dnix/blob/main/doc/configuration.md#build-modes).

## Local overrides

Configuration rejects package-local `.dnix-build` overrides in enabled
packages: dnix gives those files precedence over the app's settings, and `dev`
mode skips hash verification. Remove the reported overrides and run
`flutter clean` before reconfiguring.

After changing local dependency overrides or resolving packages separately,
rerun `dart tool/check_native_overrides.dart <app>` before building. This check
covers the selected Git pins and the existing package resolution; an old
resolution may need refreshing too. Direct Flutter commands don't run it.

## Local checkouts of dnix packages

Normal builds use the pinned Git packages. If you explicitly override a package
with a local checkout, that package's `dnix.lock` must be present for verified
builds. Without it, dnix falls back to `dev` and skips hash verification even
when source or prebuilt mode is selected. The override check does not check for
missing locks. With `-d`, a checkout that keeps its `dnix.lock` gets that
lock's release library, so local native changes are not built; remove the lock
to build them in `dev` mode.

## What each native component needs

| Component | Requirements |
|---|---|
| The four dnix packages, source mode | [Nix](https://nixos.org/download/); on Windows, Nix inside WSL2; on a Mac, Xcode **27.0** for every target, including `flutter test`, as pinned by the packages |
| The four dnix packages, `-d` | No Nix or package-specific Rust/C toolchain needed for these libraries |
| Flutter and platform plugins | Target SDKs and the platform's C/C++ build tools in either mode |
| OpenAlias / DNSSEC (every app) | Rustup on the Flutter host in both modes; `dnssec_resolver` builds from source with Rust **1.90.0** |
| Xelis (Stack Wallet) | Rustup; its hook installs Rust **1.99.1** and the required target; Android needs NDK r28 or newer |
| Spark (Stack Wallet and Campfire) | CMake and a C++ compiler; its native-assets hook builds from source |
| Coinlib secp256k1 | A separate platform build, described in each host guide |
| MWEB (Stack Wallet) | Go **1.24.1** or newer; CI uses 1.24.13. The Windows executable has a separate WSL build (Go 1.24.0 or newer) or prebuilt download |
| Linux secure storage | The dependencies to build libsecret and JsonCPP |

Every app needs Rustup, because the unconditional `cs_openalias` dependency
uses the source-built `dnssec_resolver`. Stack Wallet also needs it for Xelis.
These hooks install their pinned toolchains automatically. The optional Isar
source build (`-f`) uses Rust **1.99.1**, installing it through Rustup if
missing without changing your default toolchain. Nix supplies the dnix
packages' own pinned toolchains, independently of the Rust installed on the
host.

This build doesn't use the earlier manual steps for these packages: host Rust
toolchain lists, `cbindgen`, `cargo-lipo`, building the Epic, MWC and Tor
libraries by hand, the MXE setup, or the Epic-specific CMake upgrade.

## When native hooks run

The icon and splash `dart run` commands during configuration use only those
executables' dependency closures and do **not** run the app's native hooks.
App hooks run with later `flutter run`, `flutter test` and `flutter build`
commands, using the selected mode until you regenerate the configuration.

## Xcode pins

The Xcode setup helper and the configuration check read `toolchains.xcode`
and, when available, `toolchains.xcodeBuild` from the packages' `dnix.json`.
For the current packages, which lack a build-number pin,
`tool/native_dependency_compatibility.json` records the reviewed release for
each exact Git revision. Updating a revision requires either an upstream
build-number pin or a reviewed compatibility entry. The configuration check
reads only the packages enabled for the selected app; the setup helper reads
all four. On a fresh checkout, the metadata is downloaded from the pinned
GitHub commits when it isn't in the pub cache.

## CI and Docker images

Application CI uses `-d` for all three apps, so it verifies the four packages'
prebuilts without rebuilding their Nix recipes or installing Nix or WSL. Native
source-build and reproducibility checks belong to the packages' own CI. Every
app still builds DNSSEC with Rust 1.90.0, and Xelis, Spark and the other
non-dnix components keep their existing build paths, so CI keeps Rustup for
every app.

The Docker images install Rustup only; the hooks install toolchains under the
runtime user's HOME. Preinstalling them under custom image-only `RUSTUP_HOME`
or `CARGO_HOME` paths does not help, because the hook runner does not forward
those variables.
