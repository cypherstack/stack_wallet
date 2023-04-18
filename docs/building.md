# Installation

Here you will find instructions on how to install the necessary tools for building and running the app.


### Prerequisites

- The OS'es supported for building is Ubuntu (20.04) and Fedora (37)
- A machine with at least 100 GB of Storage

The following prerequisites can be installed with the setup script [`scripts/setup.sh`]["scripts/setup.sh"] or manually as described below:

- Flutter 3.7.6 [(install manually or with git, do not install with snap)](https://docs.flutter.dev/get-started/install)
- Dart SDK Requirement (>=2.19.0, up until <3.0.0) (normally included with a flutter install)
- Android setup ([Android Studio](https://developer.android.com/studio) and subsequent dependencies)

### Scripted setup

[`scripts/setup.sh`]["scripts/setup.sh"] is provided as a tool to set up installation for building: download the script and run it anywhere.  This script should skip the entire [Manual setup](#manual-setup) section below and prepare you for [running](#running).  It will set up the stack_wallet repository in `~/projects/stack_wallet` and build it there. 

### Manual setup

> If you have installed with script, skip to [running](#running) 

Please go to your Linux distribution's title below for instructions on how to manually setup:

- [Ubuntu (20.04)](#ubuntu-2004)
- [Fedora (37) (Work In Progress)](#fedora-37)

#### Ubuntu (20.04)

After installing the prerequisites listed above, download the code and init the submodules
```
git clone https://github.com/cypherstack/stack_wallet.git
cd stack_wallet
git submodule update --init --recursive
```

Install all dependencies listed in each of the plugins in the crypto_plugins folder (eg. [flutter_libmonero](https://github.com/cypherstack/flutter_libmonero/blob/main/howto-build-android.md), [flutter_libepiccash](https://github.com/cypherstack/flutter_libepiccash) ) as of April 18th 2023 that is:

```
sudo apt-get install unzip automake build-essential file pkg-config git python libtool libtinfo5 cmake openjdk-8-jre-headless libgit2-dev clang libncurses5-dev libncursesw5-dev zlib1g-dev llvm debhelper libclang-dev cargo rustc opencl-headers libssl-dev ocl-icd-opencl-dev libc6-dev-i386 cmake
``` 

Install [Rust](https://www.rust-lang.org/tools/install)
```
cargo install cargo-ndk
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
```

Run prebuild script

```
cd scripts
./prebuild.sh
// when finished go back to the root directory
cd ..
```

Remove pre-installed system libraries for the following packages built by cryptography plugins in the crypto_plugins folder: `boost iconv libjson-dev libsecret openssl sodium unbound zmq`.  You can use
```
sudo apt list --installed | grep boost
```
for example to find which pre-installed packages you may need to remove with `sudo apt remove`.  Be careful, as some packages (especially boost) are linked to GNOME (GUI) packages: when in doubt, remove `-dev` packages first like with
```
sudo apt-get remove '^libboost.*-dev.*'
```
<!-- TODO: configure compiler to prefer built over system libraries -->

Building plugins for Android
```
cd scripts/android/
./build_all.sh
// when finished go back to the root directory
cd ../..
```

Building plugins for Linux

```
cd scripts/linux/
./build_all.sh
// when finished go back to the root directory
cd ../..
```

#### Fedora (37) (Work In Progress)

> Note: This is a work in progress and may not work as expected

After installing the prerequisites listed above, download the code and init the submodules
```
git clone https://github.com/cypherstack/stack_wallet.git
cd stack_wallet
git submodule update --init --recursive
```

Install all dependencies listed in each of the plugins in the crypto_plugins folder (eg. [flutter_libmonero](https://github.com/cypherstack/flutter_libmonero/blob/main/howto-build-android.md), [flutter_libepiccash](https://github.com/cypherstack/flutter_libepiccash) ) as of April 18th 2023 that is:

```
sudo dnf install unzip automake file pkg-config git python libtool cmake java-11-openjdk libgit2-devel
```
<!--- 
libtinfo5 is not available in Fedora 37
libncurses5-dev is not available in Fedora 37
libncursesw5-dev is not available in Fedora 37
zlib1g-dev is not available in Fedora 37
libclang-dev is not available in Fedora 37
libssl-dev is not available in Fedora 37
ocl-icd-opencl-dev is not available in Fedora 37
libc6-dev-i386 is not available in Fedora 37
--->

Install [Rust](https://www.rust-lang.org/tools/install)
```
cargo install cargo-ndk
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
```

Run prebuild script

```
cd scripts
./prebuild.sh
// when finished go back to the root directory
cd ..
```
<!-- 
This is still work on progress
--->
Remove pre-installed system libraries for the following packages built by cryptography plugins in the crypto_plugins folder: `boost iconv libjson-dev libsecret openssl sodium unbound zmq`.  You can use
```
sudo apt list --installed | grep boost
```
for example to find which pre-installed packages you may need to remove with `sudo apt remove`.  Be careful, as some packages (especially boost) are linked to GNOME (GUI) packages: when in doubt, remove `-dev` packages first like with
```
sudo apt-get remove '^libboost.*-dev.*'
```
<!-- TODO: configure compiler to prefer built over system libraries -->

Building plugins for Android
```
cd scripts/android/
./build_all.sh
// when finished go back to the root directory
cd ../..
```

Building plugins for Linux

```
cd scripts/linux/
./build_all.sh
// when finished go back to the root directory
cd ../..
```

## Running
### Android
Plug in your android device or use the emulator available via Android Studio and then run the following commands:
```
flutter pub get
flutter run android
```

Note on Emulators: Only x86_64 emulators are supported, x86 emulators will not work

### Linux
Plug in your android device or use the emulator available via Android Studio and then run the following commands:
```
flutter pub get Linux
flutter run linux
```

## Android Studio
Android Studio is the recommended IDE for development, not just for launching on Android devices and emulators but also for Linux desktop development.  Install it and configure it as follows:
```
# setup android studio
sudo apt install -y openjdk-11-jdk
sudo snap install android-studio --classic
```

Use Tools > SDK Manager to install the SDK Tools > Android SDK (API 30), SDK Tools > NDK, SDK Tools > Android SDK command line tools, and SDK Tools > CMake

Then install the Flutter plugin and restart the IDE.  In Android Studio's options for the Flutter language, enable auto format on save to match the project's code style.  If you have problems with the Dart SDK, make sure to run `flutter` in a terminal to download it (use `source ~/.bashrc` to update your environment variables if you're still using the same terminal from which you ran `setup.sh`)

Make a Pixel 4 (API 30) x86_64 emulator with 2GB of storage space for emulation
 
["scripts/setup.sh"]: https://github.com/cypherstack/stack_wallet/blob/main/scripts/setup.sh