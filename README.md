# Epic Pay

Epic Pay is an Epic Cash wallet for Android and iOS devices.

## Feature List

Highlights include:
- Simple, beautiful design
- Sending, receiving, and storing Epic Cash
- Address book
- Wallet backup through recovery phrase
- Custom nodes
- Open source software.

## Building
### Prerequisites
- The only OS supported for building is Ubuntu 20.04
- A machine with at least 100 GB of Storage

The following prerequisities can be installed with the setup script `scripts/setup.sh` or manually as described below:

- Flutter 3.0.5 [(install manually or with git, do not install with snap)](https://docs.flutter.dev/get-started/install)
- Dart SDK Requirement (>=2.17.0, up until <3.0.0)
- Android setup ([Android Studio](https://developer.android.com/studio) and subsequent dependencies)

### Scripted setup
[`scripts/setup.sh`](https://github.com/cypherstack/stack_wallet/blob/main/scripts/setup.sh) is provided as a tool to set up a stock Ubuntu 20.04 installation for building: download the script and run it anywhere.  This script should skip the entire [Manual setup](#manual-setup) section below and prepare you for [running](#running).  It will set up the stack_wallet repository in `~/projects/stack_wallet` and build it there. 

### Manual setup
After installing the prerequisites listed above, download the code and init the submodules
```
git clone https://github.com/cypherstack/stack_wallet.git
cd stack_wallet
git submodule update --init --recursive
```

Install all dependencies listed in the plugins in the [flutter_libepiccash](https://github.com/cypherstack/flutter_libepiccash) folder as of Oct 3rd 2022 that is:
```
sudo apt-get install unzip automake build-essential file pkg-config git python libtool libtinfo5 cmake openjdk-8-jre-headless libgit2-dev clang libncurses5-dev libncursesw5-dev zlib1g-dev llvm sudo apt-get install debhelper libclang-dev cargo rustc opencl-headers libssl-dev ocl-icd-opencl-dev
```

Install [Rust](https://www.rust-lang.org/tools/install)
```
cargo install cargo-ndk
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android

sudo apt install libc6-dev-i386
sudo apt install build-essential cmake git libgit2-dev clang libncurses5-dev libncursesw5-dev zlib1g-dev pkg-config llvm 
sudo apt install build-essential debhelper cmake libclang-dev libncurses5-dev clang libncursesw5-dev cargo rustc opencl-headers libssl-dev pkg-config ocl-icd-opencl-dev
sudo apt install unzip automake build-essential file pkg-config git python libtool libtinfo5 cmake openjdk-8-jre-headless
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
## Running
### Android
Plug in your android device or use the emulator available via Android Studio and then run the following commands:
```
flutter pub get
flutter run android
```

Note on Emulators: Only x86_64 emulators are supported, x86 emulators will not work

## Android Studio
Android Studio is the recommended IDE for development.  Install it and configure it as follows:
```
# setup android studio
sudo apt install -y openjdk-11-jdk
sudo snap install android-studio --classic
```

Use Tools > SDK Manager to install the SDK Tools > Android SDK (API 30), SDK Tools > NDK, SDK Tools > Android SDK command line tools, and SDK Tools > CMake

Then install the Flutter plugin and restart the IDE.  In Android Studio's options for the Flutter language, enable auto format on save to match the project's code style.  If you have problems with the Dart SDK, make sure to run `flutter` in a terminal to download it (use `source ~/.bashrc` to update your environment variables if you're still using the same terminal from which you ran `setup.sh`)

Make a Pixel 4 (API 30) x86_64 emulator with 2GB of storage space for emulation
