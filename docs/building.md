# Building

Here you will find instructions on how to install the necessary tools for building and running the app.

## Prerequisites

- The only OS supported for building Android and Linux desktop is Ubuntu 20.04.  Windows builds require using Ubuntu 20.04 on WSL2.  macOS builds for itself and iOS.  Advanced users may also be able to build on other Debian-based distributions like Linux Mint.
- Android setup ([Android Studio](https://developer.android.com/studio) and subsequent dependencies)
- 100 GB of storage
- Install go: [https://go.dev/doc/install](https://go.dev/doc/install)

## Linux host

The following instructions are for building and running on a Linux host.  Alternatively, see the [Mac](#mac-host) and/or [Windows](#windows-host) section.  This entire section (except for the Android Studio section) needs to be completed in WSL if building on a Windows host.

### Android Studio
Install Android Studio.  Follow instructions here [https://developer.android.com/studio/install#linux](https://developer.android.com/studio/install#linux) or install via snap:
```
# setup android studio
sudo apt install -y openjdk-11-jdk
sudo snap install android-studio --classic
```

Use `Tools > SDK Manager` to install:
 - `SDK Tools > Android SDK command line tools`
 - `SDK Tools > CMake`
and for Android builds,
 - `SDK Tools > Android SDK (API 35)`
 - `SDK Tools > NDK`

Then in `File > Settings > Plugins`, install the **Flutter** and **Dart** plugins and restart the IDE.  In `File > Settings > Languages & Frameworks > Flutter > Editor`, enable auto format on save to match the project's code style.  If you have problems with the Dart SDK, make sure to run `flutter` in a terminal to download it (use `source ~/.bashrc` to update your environment variables if you're still using the same terminal from which you ran `setup.sh`).  Run `flutter doctor` to install any missing dependencies and review and agree to any license agreements.

Make a Pixel 4 (API 30) x86_64 emulator with 2GB of storage space for emulation.

The following *may* be needed for Android studio:
```
sudo apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386
```

### Build dependencies
Install basic dependencies
```
sudo apt-get install libssl-dev curl unzip automake build-essential file pkg-config git python3 libtool libtinfo6 cmake libgit2-dev clang libncurses5-dev libncursesw5-dev zlib1g-dev llvm g++ gcc gperf libopencv-dev python3-typogrify xsltproc valac gobject-introspection meson
```

For Ubuntu 20.04,
```
sudo apt-get install valac python3-pip
pip3 install --upgrade meson==0.64.1 markdown==3.4.1 markupsafe==2.1.1 jinja2==3.1.2 pygments==2.13.0 toml==0.10.2 typogrify==2.0.7 tomli==2.0.1
```

For Ubuntu 24.04,
```
sudo apt install pipx libgcrypt20-dev libglib2.0-dev libsecret-1-dev
pipx install meson==0.64.1 markdown==3.4.1 markupsafe==2.1.1 jinja2==3.1.2 pygments==2.13.0 toml==0.10.2 typogrify==2.0.7 tomli==2.0.1
```

Install [Rust](https://www.rust-lang.org/tools/install) via [rustup.rs](https://rustup.rs), the required Rust toolchains, and `cargo-ndk` with command:
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.bashrc
rustup install 1.85.1 1.81.0
rustup default 1.85.1
cargo install cargo-ndk
```

Android specific dependencies:
```
sudo apt-get install libc6-dev-i386
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
```

Linux desktop specific dependencies:
```
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev meson python3-pip libgirepository1.0-dev valac xsltproc docbook-xsl
pip3 install --upgrade meson==0.64.1 markdown==3.4.1 markupsafe==2.1.1 jinja2==3.1.2 pygments==2.13.0 toml==0.10.2 typogrify==2.0.7 tomli==2.0.1
```

### Flutter
Install Flutter 3.29.2 by [following their guide](https://docs.flutter.dev/get-started/install/linux/desktop?tab=download#install-the-flutter-sdk).  You can also clone https://github.com/flutter/flutter, check out the `3.29.2` tag, and add its `flutter/bin` folder to your PATH as in
```sh
FLUTTER_DIR="$HOME/development/flutter"
git clone https://github.com/flutter/flutter.git "$FLUTTER_DIR"
cd "$FLUTTER_DIR"
git checkout 3.29.2
echo 'export PATH="$PATH:'"$FLUTTER_DIR"'/bin"' >> "$HOME/.profile"
source "$HOME/.profile"
flutter precache
```

Run `flutter doctor` in a terminal to confirm its installation.

### Clone the repository and initialize submodules
After installing the prerequisites listed above, download the code and init the submodules
```
git clone https://github.com/cypherstack/stack_wallet.git
cd stack_wallet
git submodule update --init --recursive
```

Build the secure storage dependencies in order to target Linux (not needed for Windows or other platforms):
```
cd scripts/linux
./build_secure_storage_deps.sh
// when finished go back to the root directory
cd ../..
```

### Build secp256k1
Coinlib requires a secp256k1 library to be built prior to running Stack Wallet.  It can be built from within the root `stack_wallet` folder on a...
 - Linux host for Linux targets:  `dart run coinlib:build_linux` (requires [Docker](https://docs.docker.com/engine/install/ubuntu/) or [`podman`](https://podman.io/docs/installation))
 - Linux host for Windows targets: `dart run coinlib:build_windows_crosscompile`
 - Windows host: `dart run coinlib:build_windows`
 - WSL2 host: `dart run coinlib:build_wsl`
 - macOS host: `dart run coinlib:build_macos`

or by using `scripts/linux/build_secp256k1.sh` or `scripts/windows/build_secp256k1.bat`.

### Run prebuild script

Certain test wallet parameter and API key template files must be created in order to run Stack Wallet.  These can be created by script as in
```
cd scripts
./prebuild.sh
// when finished go back to the root directory
cd ..
```
or manually by creating the files referenced in that script with the specified content.

### Build plugins
#### Build script: `build_app.sh`
The `build_app.sh` script is used to build the Stack Wallet and its family of applications.  View the script's help message with `./build_app.sh -h` for more information on its usage.

Options:

 - `a <app>`: Specify the application ID (required).  Valid options are `stack_wallet` or `stack_duo`.
 - `b <build_number>`: Specify the build number in 123 (required).
 - `p <platform>`: Specify the platform to build for (required).  Valid options are `android`, `ios`, `macos`, `linux`, or `windows`.
 - `v <version>`: Specify the version of the application in 1.2.3 format (required).
 - `i`: Optional flag to skip building crypto plugins.  Useful for updating `pubspec.yaml` and white-labelling different apps with the same plugins.

For example,
```
./build_app.sh -a stack_wallet -p linux -v 2.1.0 -b 210
```

#### Building plugins for Android 
> Warning: This will take a long time, please be patient
```
cd scripts
./build_app.sh -a stack_wallet -p android
```

#### Building plugins for Linux
```
cd scripts
./build_app.sh -a stack_wallet -p linux
```

#### Building plugins and configure for Windows
Install dependencies like MXE:
```
cd scripts/windows
./deps.sh
```

and use `scripts/build_app.sh` to build plugins:
```
cd ..
./build_app.sh -a stack_wallet -p windows -v 2.1.0 -b 210
```

### Running
#### Android
Plug in your android device or use the emulator available via Android Studio and then run the following commands:
```
flutter pub get
flutter run android
```

Note on Emulators: Only x86_64 emulators are supported, x86 emulators will not work.  You should [configure KVM](https://help.ubuntu.com/community/KVM/Installation) for much better performance.

#### Linux
Run the following commands or launch via Android Studio:
```
flutter pub get
flutter run linux
```

## Mac host

### Dependencies
XCode, Homebrew and several homebrew packages, Rust, and Flutter are required for Mac development with the Flutter SDK.  Multiple IDEs may work, but Android Studio is recommended.

Download and install Xcode at https://developer.apple.com/xcode/, register your device (Mac or iPhone), and enable developer mode for your device as applicable.  After installing XCode, make sure commandline tools are installed with `xcode-select --install`.

Download and install [Homebrew](https://brew.sh/).  The following command can install it via script:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installing Homebrew, install the following packages:
```
brew install autoconf automake boost berkeley-db ca-certificates cbindgen cmake cocoapods curl git libssh2 libsodium make openssl@1.1 openssl@3 perl pkg-config rustup-init unbound unzip xz zmq
```

The following brew formula *may* be needed:
```
brew install brotli cairo coreutils gdbm gettext glib gmp libevent libidn2 libnghttp2 libtool libunistring libx11 libxau libxcb libxdmcp libxext libxrender lzo m4 openldap pcre2 pixman procs rtmpdump tcl-tk xorgproto zstd
```
<!-- TODO: determine which of the above list are not needed at all. -->

Download and install [Rust](https://www.rust-lang.org/tools/install).  [Rustup](https://rustup.rs/) is recommended for Rust setup.  Use `rustc` to confirm successful installation.  Install toolchains 1.81.0 and 1.85.1 and `cbindgen` and `cargo-lipo` too.  You will also have to add the platform target(s) `aarch64-apple-ios` and/or `aarch64-apple-darwin`.  You can use the command(s):
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.bashrc 
rustup install 1.85.1 1.81.0
rustup default 1.85.1
cargo install cargo-ndk
cargo install cbindgen cargo-lipo
rustup target add aarch64-apple-ios aarch64-apple-darwin
```

Optionally download [Android Studio](https://developer.android.com/studio) as an IDE and activate its Dart and Flutter plugins.  VS Code may work as an alternative, but this is not recommended.

### Flutter
Install [Flutter](https://docs.flutter.dev/get-started/install) 3.29.2 on your Mac host by following [these instructions](https://docs.flutter.dev/get-started/install/macos).  Run `flutter doctor` in a terminal to confirm its installation.

### Build plugins and configure
#### Building plugins for iOS 
```
cd scripts
./build_app.sh -a stack_wallet -p ios
```

#### Building plugins for macOS
```
cd scripts
./build_app.sh -a stack_wallet -p macos
```

### Run prebuild script
Certain test wallet parameter and API key template files must be created in order to run Stack Wallet.  These can be created by script as in
```
cd scripts
./prebuild.sh
// when finished go back to the root directory
cd ..
```
or manually by creating the files referenced in that script with the specified content.

### Running
#### iOS
Plug in your iOS device or use an emulato and then run the following commands:
```
flutter pub get
flutter run ios
```

#### macOS
Run the following commands or launch via Android Studio:
```
flutter pub get
flutter run macos
```

## Windows host

### Visual Studio
Visual Studio is required for Windows development with the Flutter SDK.  Download it at https://visualstudio.microsoft.com/downloads/ and install the "Desktop development with C++", "Linux development with C++", and "Visual C++ build tools" workloads.  You may also need the Windows 10, 11, and/or Universal SDK workloads depending on your Windows version.

### Build plugins in WSL2
Set up Ubuntu 20.04 in WSL2.  Follow the entire Linux host section in the WSL2 Ubuntu 20.04 host to get set up to build.  The Android Studio section may be skipped in WSL (it's only needed on the Windows host).

Install the following libraries:
```
sudo apt-get install libgtk2.0-dev
```

The WSL2 host may optionally be navigated to the `stack_wallet` repository on the Windows host in order to build the plugins in-place and skip the next section in which you copy the `dll`s from WSL2 to Windows.  Then build windows `dll` libraries by running the following script on the WSL2 Ubuntu 20.04 host:

- `stack_wallet/scripts/windows/build_all.sh`

If the DLLs were built on the WSL filesystem instead of on Windows, copy the resulting `dll`s to their respective positions on the Windows host:

- `stack_wallet/crypto_plugins/flutter_libepiccash/scripts/windows/build/libepic_cash_wallet.dll`

<!-- TODO: script the copying or installation of libraries from WSL2 to the parent Windows host -->

Frostdart will be built by the Windows host later.

### Install Flutter on Windows host
Install Flutter 3.29.2 on your Windows host (not in WSL2) by [following their guide](https://docs.flutter.dev/get-started/install/windows/desktop?tab=download#install-the-flutter-sdk) or by cloning https://github.com/flutter/flutter, checking out the `3.29.2` tag, and adding its `flutter/bin` folder to your PATH as in
```bat
@echo off
set "FLUTTER_DIR=%USERPROFILE%\development\flutter"
git clone https://github.com/flutter/flutter.git "%FLUTTER_DIR%"
cd /d "%FLUTTER_DIR%"
git checkout 3.29.2
setx PATH "%PATH%;%FLUTTER_DIR%\bin"
echo Flutter setup completed. Please restart your command prompt.
```

Run `flutter doctor` in PowerShell to confirm its installation.

### Rust
Install [Rust](https://www.rust-lang.org/tools/install) on the Windows host (not in WSL2).  Download the installer from [rustup.rs](https://rustup.rs), make sure it works on the commandline (you may need to open a new terminal), and install the following versions:
```
rustup install 1.85.1 1.81.0
rustup default 1.85.1
cargo install cargo-ndk
```

### Windows SDK and Developer Mode
Install the Windows SDK: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/  You may need to install the [Windows 10 SDK](https://developer.microsoft.com/en-us/windows/downloads/sdk-archive/), which can be installed [by Visual Studio](https://stackoverflow.com/a/73923899) (`Tools > Get Tools and Features... > Modify > Individual Components > Windows 10 SDK`).

Enable Developer Mode for symlink support,
```
start ms-settings:developers
```

You may need to install NuGet and CppWinRT / C++/WinRT SDKs version `2.0.210806.1`:
```
winget install 9WZDNCRDMDM3 # NuGet, can also use Microsoft.NuGet
winget install Microsoft.Windows.CppWinRT -Version 2.0.210806.1
```
or [download the package](https://www.nuget.org/packages/Microsoft.Windows.CppWinRT/2.0.210806.1) and [manually install it](https://github.com/Baseflow/flutter-permission-handler/issues/1025#issuecomment-1518576722) by placing it in `flutter/bin` with [nuget.exe](https://dist.nuget.org/win-x86-commandline/latest/nuget.exe) and installing by running `nuget install Microsoft.Windows.CppWinRT -Version 2.0.210806.1` in the root `stack_wallet` folder. 
<!-- TODO: script this NuGet and WinCppRT installation -->

### Run prebuild script

Certain test wallet parameter and API key template files must be created in order to run Stack Wallet on Windows.  These can be created by script using PowerShell on the Windows host as in
```
cd scripts
./prebuild.ps1
cd .. // When finished go back to the root directory.
```
or manually by creating the files referenced in that script with the specified content. 

### Build frostdart

In PowerShell on the Windows host, navigate to the `stack_wallet` folder:
```
cd crypto_plugins/frostdart
./build_all.bat
cd .. // When finished go back to the root directory.
```

### Running

Run the following commands:
```
flutter pub get
flutter run -d windows
```

# Troubleshooting

Run with `-v` or `--verbose` to see a more detailed error.  Certain exceptions (like missing a plugin library) may not report quality errors without `verbose`, especially on Windows.

## Tor

To test Tor usage, run Stack Wallet from Android Studio.  Click the Flutter DevTools icon in the Run tab (next to the Hot Reload and Hot Restart buttons) and navigate to the Network tab.  Connections using Tor will show as `GET InternetAddress('127.0.0.1', IPv4) 101 ws`.  Connections outside of Tor will show the destination address directly (although some Tor requests may also show the destination address directly, check the Headers take for *eg.* `{localPort: 59940, remoteAddress: 127.0.0.1, remotePort: 6725}`.  `localPort` should match your Tor port.
