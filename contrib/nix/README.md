# Nix builds

This branch uses a locked Nix flake plus checksum-pinned Flutter and Android
SDK inputs. Start from a clean recursive checkout and provide an explicit app
version and build number:

```sh
(cd scripts && ./build_app.sh -n -a stack_wallet -p linux -v 2.6.0 -b 310)
```

Supported targets are `linux`, `android`, `macos`, `ios`, and `windows`.
macOS and iOS require a macOS host with Xcode. Native Windows requires
WSL with PowerShell interop and Visual Studio's desktop C++ workload.

| Target | Required host | Current verification |
| --- | --- | --- |
| Linux | Linux x86_64 with Nix | Two clean release manifests matched; full ELF dependency audit passed |
| Android | Linux x86_64 or macOS with Nix | Full unsigned release build passed on Linux |
| macOS | macOS x86_64/arm64 with Nix and Xcode | Shells evaluate; host build pending |
| iOS | macOS x86_64/arm64 with Nix and Xcode | Shells evaluate; host build pending |
| Windows | Windows x86_64, WSL, Nix, and Visual Studio | Shell evaluates; host build pending |

Nix owns the Linux toolchain and the non-Apple tooling on macOS. Xcode,
Visual Studio, and the Windows SDK remain host inputs; the Windows driver uses
a private Pub cache plus checksum-pinned Windows Flutter and Go SDKs. The existing
Stack scripts still fetch prebuilt coin libraries. Pub, Gradle, CargoKit, and
Android's version-pinned SDK components also resolve from their locked upstream
repositories. These builds are networked, not hermetic. The hybrid
Apple/Windows targets are repeatable environments, but must not be called
bit-reproducible until two clean builders produce identical artifact manifests.

Linux binaries produced directly in the Nix shell reference its pinned Nix
store closure. They are reproducibility evidence for Nix builders, not a
drop-in replacement for Stack's portable Linux release archive.

The Android reproducibility driver requires an unsigned checkout and rejects
`android/key.properties`. Signing keys are external release inputs and signed
release packaging remains a separate step.

The checked-in `nix/flake.lock`, `flutter_version.env`, `go_version.env`,
`rust_version.env`, `android_sdk_version.env`, and `pubspec.lock` are the
reviewed input locks.
Do not use the generated `--refresh` paths for release evidence.
Cargokit's moving `stable` Rust request is mapped to Rust 1.91.0. The isolated
toolchain cache is verified before each native build; Windows requires
`rustup.exe` on the host.

Each successful build writes a canonical manifest and its SHA-256 under
`build/attestations`. To compare two clean builds from the same source and host
vector, save the first manifest, repeat the build, then run:

```sh
dart run contrib/nix/artifact_manifest.dart compare \
  /tmp/stack-linux-first.manifest build/attestations/linux.manifest
```

A match covers every file, POSIX mode, and symlink target in the declared
artifact. It does not make the documented network or host inputs hermetic.

The package-backed helper is pinned to an exact `ManyMath/nix` commit:

```sh
contrib/nix/nix-tool doctor
```
