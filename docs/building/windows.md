# Building on Windows

These steps build the Windows desktop app. Keep Flutter, Dart and the app
checkout on Windows, run the configuration script from **Git Bash**, and build
with Windows Flutter. For how the build fits together, see the
[overview](../building.md).

## Prerequisites

| What | Needed for |
|---|---|
| [Flutter](https://docs.flutter.dev/install/manual) 3.47.2, and Git for Windows, which includes Git Bash | Every build |
| [Visual Studio 2022](https://docs.flutter.dev/platform-integration/windows/setup) with **Desktop development with C++**, CMake tools and a Windows SDK | Every build |
| Windows Developer Mode, for the symlinks Flutter and the asset scripts create | Every build |
| [Rustup](https://rustup.rs/) on Windows | Every app's DNSSEC hook and Stack Wallet's Xelis hook, in both modes |
| WSL2 with Ubuntu 24.04, and [Nix](https://nixos.org/download/) inside it | Source mode, the default; not needed with `-d` |
| Go 1.24.0 or newer and `mingw-w64` in the default WSL distribution | Stack Wallet's [MWEB build](#mweb), unless you set `MWEBD_FETCH=1` |

## Set up WSL and Nix

Follow Microsoft's [WSL installation guide](https://learn.microsoft.com/en-us/windows/wsl/install)
to install Ubuntu 24.04, then follow the [Nix installation instructions](https://nixos.org/download/)
inside that distribution. Check from PowerShell:

```powershell
wsl.exe --list --verbose
wsl.exe -d Ubuntu-24.04 -- /nix/var/nix/profiles/default/bin/nix --version
```

Adjust the Nix path if you use a different installation. dnix finds Nix on the
WSL distribution's PATH or in its standard profile paths. It invokes `wsl.exe`,
translates paths, builds each Windows DLL in Nix, copies it back to Windows, and
verifies it before Flutter bundles it. You don't need Flutter or Dart inside
WSL, or to copy these four libraries by hand.

Keep native checkouts in LF form and preserve symlinks and executable
permissions; filesystem differences can cause a hash mismatch. See
[dnix Windows source builds](https://github.com/cypherstack/dnix/blob/main/doc/configuration.md#windows-source-builds)
for checkout and environment details.

## Build

Run these commands in Git Bash. Configuration stops if it isn't run from Git
Bash.

1. Clone the repository and create the stubs:

   ```sh
   git clone https://github.com/cypherstack/stack_wallet.git
   cd stack_wallet
   bash scripts/prebuild.sh
   ```

   From PowerShell, you can create the stubs with
   `powershell -ExecutionPolicy Bypass -File scripts/prebuild.ps1` instead.

2. Configure and build:

   ```sh
   bash scripts/build_app.sh -a stack_wallet -p windows -v 1.2.3 -b 123
   flutter pub get
   dart tool/check_native_overrides.dart stack_wallet
   flutter build windows --release
   ```

Use the version and build number for your checkout, and read the script's
confirmation before continuing. Add `-d` to the configuration command to use
verified dnix prebuilts. See the
[configuration options](../building.md#configuration-options). The override
check catches package-local dnix overrides; see
[Local overrides](native-libraries.md#local-overrides).

## Choose the WSL distribution

By default, dnix uses the default WSL distribution. Select it persistently with
`wsl.exe --set-default Ubuntu-24.04`, or put
`export DNIX_WSL_DISTRIBUTION=Ubuntu-24.04` in your Git Bash profile.
`build_app.sh` writes that setting for every enabled dnix package on each run;
`-w Ubuntu-24.04` overrides it for one configuration. Editing only the
generated `pubspec.yaml` does not survive reconfiguration.

## MWEB

Stack Wallet's Windows MWEB executable has its own build path. By default, its
configuration helper builds it with Go and `x86_64-w64-mingw32-gcc` inside the
default WSL distribution. Install Go there (CI uses 1.24.13) and run
`sudo apt-get install mingw-w64`. Alternatively, set `MWEBD_FETCH=1` when
running `build_app.sh` to download the existing MWEB release and check its
published checksum. This setting is independent of `-d` and of dnix's WSL
distribution.

## secp256k1

In **both** dnix modes, `build_app.sh` builds secp256k1 unless you pass `-i`.
The helper finds Visual Studio 2022's bundled CMake through `vswhere`, so Git
Bash does not need a Developer Command Prompt. It checks its tools before
configuration changes any files and stops on failed build commands. If you
passed `-i`, run:

```sh
dart scripts/windows/build_secp256k1.dart
```

The helper builds secp256k1 **v0.5.0**
(`e3a885d42a7800c1ccebad94ad1e2b82c4df5c65`) with MSVC and recompiles the DLL
on every build. dnix's hash verification covers its four packages, not
secp256k1.

## Troubleshooting

- Run Flutter commands with `-v` for more detail. Some errors, such as a
  missing plugin library, only show clearly with verbose output.
- If configuration says to use Git Bash, rerun it from Git Bash rather than
  PowerShell or a WSL shell.
