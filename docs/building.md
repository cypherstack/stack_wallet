# Building

Here you will find instructions on how to install the necessary tools for building and running the app.

## Prerequisites

- The only OS supported for building Android and Linux desktop is Ubuntu 20.04.  Windows build are completed using Ubuntu 20.04 on WSL2.  Advanced users may also be able to build on other Debian-based distributions like Linux Mint.
- Android setup ([Android Studio](https://developer.android.com/studio) and subsequent dependencies)
- 100 GB of storage

## Linux host
The following instructions are for building and running on a Linux host.  Alternatively, see the [Windows](#Windows host) section.

### Android Studio
Install Android Studio.  Follow instructions here [https://developer.android.com/studio/install#linux](https://developer.android.com/studio/install#linux) or install via snap:
```
# setup android studio
sudo apt install -y openjdk-11-jdk
sudo snap install android-studio --classic
```

Use `Tools > SDK Manager` to install:
 - `SDK Tools > Android SDK (API 30)`
 - `SDK Tools > NDK`
 - `SDK Tools > Android SDK command line tools`
 - `SDK Tools > CMake`

Then in `File > Settings > Plugins`, install the **Flutter** and **Dart** plugins and restart the IDE.  In `File > Settings > Languages & Frameworks > Flutter > Editor`, enable auto format on save to match the project's code style.  If you have problems with the Dart SDK, make sure to run `flutter` in a terminal to download it (use `source ~/.bashrc` to update your environment variables if you're still using the same terminal from which you ran `setup.sh`).  Run `flutter doctor` to install any missing dependencies and review and agree to any license agreements.

Make a Pixel 4 (API 30) x86_64 emulator with 2GB of storage space for emulation

Install basic dependencies
```
sudo apt-get install libssl-dev curl unzip automake build-essential file pkg-config git python libtool libtinfo5 cmake libgit2-dev clang libncurses5-dev libncursesw5-dev zlib1g-dev llvm python3-distutils
```

The following *may* be needed for Android studio:
```
sudo apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386
```

Install [Rust](https://www.rust-lang.org/tools/install) with command:
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.bashrc 
rustup install 1.67.1
rustup default 1.67.1
```

Install the additional components for Rust:
```
cargo install cargo-ndk --version 2.12.7
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

After installing the prerequisites listed above, download the code and init the submodules
```
git clone https://github.com/cypherstack/stack_wallet.git
cd stack_wallet
git submodule update --init --recursive

```

Remove pre-installed system libraries for the following packages built by cryptography plugins in the crypto_plugins folder: `boost iconv libjson-dev libsecret openssl sodium unbound zmq`.  You can use
```
sudo apt list --installed | grep boost
```
for example to find which pre-installed packages you may need to remove with `sudo apt remove`.  Be careful, as some packages (especially boost) are linked to GNOME (GUI) packages: when in doubt, remove `-dev` packages first like with
```
sudo apt-get remove '^libboost.*-dev.*'
```
<!-- TODO: configure compiler to prefer built over system libraries. Should already use them? -->

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
#### Building plugins for Android 
> Warning: This will take a long time, please be patient
```
cd scripts/android
./build_all.sh
```

#### Building plugins for Linux
```
cd scripts/linux
./build_all.sh
```

#### Building plugins for Windows
```
cd scripts/windows
./deps.sh
./build_all.sh
```

### Running
#### Android
Plug in your android device or use the emulator available via Android Studio and then run the following commands:
```
flutter pub get
flutter run android
```

Note on Emulators: Only x86_64 emulators are supported, x86 emulators will not work

#### Linux
Plug in your android device or use the emulator available via Android Studio and then run the following commands:
```
flutter pub get
flutter run linux
```

## Windows host
### Visual Studio
Visual Studio is required for Windows development with the Flutter SDK.  Download it at https://visualstudio.microsoft.com/downloads/ and install the "Desktop development with C++" workload, including all of its default components.

### Building libraries in WSL2
Set up Ubuntu 20.04 in WSL2.  Follow the entire Linux host section to get set up and build windows `dll` libraries.  Copy the resulting `dll`s to their respective positions on the Windows host:

- `stack_wallet/crypto_plugins/flutter_libepiccash/scripts/windows/build/libepic_cash_wallet.dll`
- `stack_wallet/crypto_plugins/flutter_liblelantus/scripts/windows/build/libmobileliblelantus.dll`
<!-- TODO: script the copying or installation of libraries from WSL2 to the parent Windows host -->

### Install Flutter on Windows host
Install Flutter 3.10.3 on your Windows host (not in WSL2) by following these instructions: https://docs.flutter.dev/get-started/install/windows or by running `scripts/windows/deps.ps1`.  You may still have to add `C:\development\flutter\bin` to PATH before proceeding, even if you ran `deps.ps1`.  Run `flutter doctor` in PowerShell to confirm its installation.

### Dependencies
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

Certain test wallet parameter and API key template files must be created in order to run Stack Wallet.  These can be created by script as in
```
cd scripts
./prebuild.ps1
// when finished go back to the root directory
cd ..
```
or manually by creating the files referenced in that script with the specified content.

### Running

Run the following commands:
```
flutter pub get
flutter run -d windows
```
