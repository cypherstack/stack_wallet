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
| Linux | Linux x86_64 with Nix | Full release build passed |
| Android | Linux x86_64 or macOS with Nix | Full unsigned release build passed on Linux |
| macOS | macOS x86_64/arm64 with Nix and Xcode | Shells evaluate; host build pending |
| iOS | macOS x86_64/arm64 with Nix and Xcode | Shells evaluate; host build pending |
| Windows | Windows x86_64, WSL, Nix, and Visual Studio | Shell evaluates; host build pending |

Nix owns the Linux toolchain and the non-Apple tooling on macOS. Xcode,
Visual Studio, and the Windows SDK remain host inputs; the Windows driver uses
a private Pub cache and a checksum-pinned Windows Flutter SDK. The existing
Stack scripts still fetch prebuilt coin libraries. Pub, Gradle, CargoKit, and
Android's version-pinned SDK components also resolve from their locked upstream
repositories. These builds are networked, not hermetic. The hybrid
Apple/Windows targets are repeatable environments, but must not be called
bit-reproducible until two clean builders produce identical artifact manifests.

Linux binaries produced directly in the Nix shell reference its pinned Nix
store closure. They are reproducibility evidence for Nix builders, not a
drop-in replacement for Stack's portable Linux release archive.

Android builds are unsigned unless `android/key.properties` supplies all four
release-signing properties. Signing keys are external release inputs.

The checked-in `nix/flake.lock`, `flutter_version.env`,
`android_sdk_version.env`, and `pubspec.lock` are the reviewed input locks.
Do not use the generated `--refresh` paths for release evidence.

The package-backed helper is pinned to an exact `ManyMath/nix` commit:

```sh
contrib/nix/nix-tool doctor
```
