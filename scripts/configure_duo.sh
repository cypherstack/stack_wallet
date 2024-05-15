# Configure files for Duo.
sed -i 's/Wallet/Duo/g' ../lib/app_config.dart
sed -i 's/Stack Wallet/Stack Duo/g' ../pubspec.yaml
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../android/app/build.gradle
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../android/app/src/debug/AndroidManifest.xml
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../android/app/src/main/AndroidManifest.xml
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../android/app/src/main/kotlin/com/cypherstack/stackwallet/MainActivity.kt
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../android/app/src/main/profile/AndroidManifest.xml
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../android/app/src/profile/AndroidManifest.xml
sed -i 's/Stack Wallet/Stack Duo/g' ../ios/Runner/Info.plist
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../ios/Runner.xcodeproj/project.pbxproj
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../linux/CMakeLists.txt
sed -i 's/Stack Wallet/Stack Duo/g' ../linux/my_application.cc
sed -i 's/com.cypherstack.stackWallet/com.cypherstack.stackDuo/g' ../macos/Runner.xcodeproj/project.pbxproj
sed -i 's/Stack Wallet/Stack Duo/g' ../windows/runner/Runner.rc
