# Configure Android for Duo.
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../../android/app/build.gradle
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../../android/app/src/debug/AndroidManifest.xml
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../../android/app/src/main/AndroidManifest.xml
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../../android/app/src/main/kotlin/com/cypherstack/stackwallet/MainActivity.kt
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../../android/app/src/main/profile/AndroidManifest.xml
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../../android/app/src/profile/AndroidManifest.xml
