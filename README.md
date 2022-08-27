# Stack Wallet
put details here

[![Playstore](https://bluewallet.io/img/play-store-badge.svg)](https://play.google.com/store/apps/details?id=com.cypherstack.stackwallet)

## Feature List
put features here

## Build and run
### Prerequisites
- Flutter SDK Requirement (>=2.12.0, up until <3.0.0)
- Android/iOS dev setup (Android Studio, xCode and subsequent dependencies)

After that download the project and init the submodules
```
git clone https://github.com/cypherstack/stack_wallet.git
cd stack_wallet
git submodule update --init --recursive
```

Building plugins for Android
```
cd crypto_plugins/flutter_liblelantus/scripts/android/
// note if you are on a mac go one directory further to android_on_mac
./build_all.sh
// when finished go back to the root directory
cd ../../../..
```

Building plugins for IOS

```
cd crypto_plugins/flutter_liblelantus/scripts/ios/
./build_all.sh
// when finished go back to the root directory
cd ../../../..
```

Building plugins for testing on Linux

```
cd crypto_plugins/flutter_liblelantus/scripts/linux/
./build_all.sh
// when finished go back to the root directory
cd ../../../..
```

Finally, plug in your android device or use the emulator available via Android Studio and then run the following commands:
```
flutter pub get
flutter run
```
