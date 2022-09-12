[![codecov](https://codecov.io/gh/cypherstack/stack_wallet/branch/main/graph/badge.svg?token=PM1N56UTEW)](https://codecov.io/gh/cypherstack/stack_wallet)

# Stack Wallet
Stack Wallet is a fully open source cryptocurrency wallet. With an easy to use user interface and quick and speedy transactions, this wallet is ideal for anyone no matter how much they know about the cryptocurrency space. The app is actively maintained to provide new user friendly features.

[![Playstore](https://bluewallet.io/img/play-store-badge.svg)](https://play.google.com/store/apps/details?id=com.cypherstack.stackwallet)

## Feature List

Highlights include:
- 5 Different cryptocurrencies
- All private keys and seeds stay on device and are never shared.
- Easy backup and restore feature to save all the information that's important to you.
- Trading cryptocurrencies through our partners.
- Custom address book
- Favorite wallets with fast syncing
- Custom Nodes.
- Open source software.

## Build and run
### Prerequisites
- The only OS supported for building is Ubuntu 20.04
- A machine with at least 100 GB of Storage
- Flutter 3.0.5 [(install manually or with git, do not install with snap)](https://docs.flutter.dev/get-started/install)
- Dart SDK Requirement (>=2.17.0, up until <3.0.0)
- Android setup ([Android Studio](https://developer.android.com/studio) and subsequent dependencies)

After that download the project and init the submodules
```
git clone https://github.com/cypherstack/stack_wallet.git
cd stack_wallet
git submodule update --init --recursive
```

You will need to install all dependencies listed in each of the plugins in the crypto_plugins folder. (eg. [Monero](https://github.com/cypherstack/flutter_libmonero), [Epic Cash](https://github.com/cypherstack/flutter_libepiccash) ) as of Sep 8th 2022 that is:

Install [Rust](https://www.rust-lang.org/tools/install)
```
cargo install cargo-ndk
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android

sudo apt install libc6-dev-i386
sudo apt install build-essential cmake git libgit2-dev clang libncurses5-dev libncursesw5-dev zlib1g-dev pkg-config llvm 
sudo apt install build-essential debhelper cmake libclang-dev libncurses5-dev clang libncursesw5-dev cargo rustc opencl-headers libssl-dev pkg-config ocl-icd-opencl-dev
sudo apt install unzip automake build-essential file pkg-config git python libtool libtinfo5 cmake openjdk-8-jre-headless
```

Building plugins for Android
```
cd scripts/android/
./build_all.sh
// when finished go back to the root directory
cd ../..
```

Building plugins for testing on Linux

```
cd scripts/linux/
./build_all.sh
// when finished go back to the root directory
cd ../..
```

Finally, plug in your android device or use the emulator available via Android Studio and then run the following commands:
```
flutter pub get
flutter run
```

Note on Emulators: Only x86_64 emulators are supported, x86 emulators will not work
