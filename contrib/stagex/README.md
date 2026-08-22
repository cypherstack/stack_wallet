# StageX builds

This branch combines source-addressed StageX images with checksum-pinned
Flutter and Android SDK inputs. Start from a clean recursive checkout and
provide an explicit app version and build number:

```sh
(cd scripts && ./build_app.sh -x -a stack_wallet -p linux -v 2.6.0 -b 310)
```

Supported targets are `linux`, `android`, `macos`, `ios`, and `windows`.
macOS and iOS require a macOS host with Xcode. Native Windows requires WSL,
PowerShell interop, and Visual Studio's desktop C++ workload. Apple and Windows
hosts also require rustup. The drivers install and verify pinned Go and Rust
toolchains from `go_version.env` and `rust_version.env`.

| Target | Required host | Qualification |
| --- | --- | --- |
| Linux | Linux x86_64 with Docker 25+ | Full release build; Stack-specific graph |
| Android | Linux x86_64 with Docker 25+ | Exact clean replay passed; StageX-unqualified |
| macOS | macOS x86_64/arm64 with Xcode | Host build; exact-vector verification pending |
| iOS | macOS x86_64/arm64 with Xcode | Unsigned host build; unqualified |
| Windows | Windows x86_64 with WSL and Visual Studio | Host build; unqualified |

“Unqualified” follows the StageX package's deliberately narrow definition.
StageX currently certifies Linux/web on Linux amd64 and macOS only on one
pinned macOS arm64/Xcode vector. These additional paths are buildable and
repeatable; they must not be described as bit-reproducible until two clean,
identical host vectors produce matching artifact manifests.

Two clean unsigned Android builds on the same Linux vector produced identical
APKs and manifests. Cross-host qualification is still pending.

Stack uses an ejected, project-specific glibc graph because Flutter's native
plugins cannot use the upstream musl image graph. It is source-addressed but
is not accepted by the upstream exact-template verifier. Linux and Android use
the immutable Debian snapshot recorded in `stagex.yaml`; their complete Debian
package closures are checked against the committed `*-packages.lock` files.
Gradle, Pub, Cargo, Go modules, Android `sdkmanager`, and existing Stack coin
library downloads remain networked. Xcode, CocoaPods, Visual Studio, and the
Windows SDK remain host inputs. The build paths are therefore not hermetic.

The StageX Android driver refuses `android/key.properties`, explicitly enables
an unsigned release, and verifies that the APK is unsigned. Ordinary release
builds still require Stack's signing key. iOS uses `--no-codesign`.

Apple reviewers should record their host vector before comparing results:

```sh
contrib/stagex/scripts/capture-apple-host.sh
```

Reviewed inputs live in `stagex.yaml`, `flutter_version.env`,
`android_sdk_version.env`, `go_version.env`, `rust_version.env`,
`contrib/stagex/android-sdk-packages.lock`, and the
digest-pinned Containerfiles. Do not run `stagex_dart pin`: it regenerates the
custom Stack definitions. The drivers are ejected from the exact package
commit recorded in `contrib/stagex/UPSTREAM`, so installing that private
package is not a build prerequisite.

Each successful build writes a canonical manifest and its SHA-256 under
`build/attestations`. To qualify an exact host vector, save the first clean
manifest, repeat the clean build from the same source commit, then compare:

```sh
cp build/attestations/linux.manifest /tmp/stack-linux-first.manifest
dart run contrib/stagex/artifact_manifest.dart compare \
  /tmp/stack-linux-first.manifest build/attestations/linux.manifest
```

A matching manifest proves byte-for-byte equality for all files, modes, and
symlink targets in the declared artifact. It does not make unpinned network or
host inputs hermetic.
