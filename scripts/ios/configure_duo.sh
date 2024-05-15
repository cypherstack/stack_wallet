# Configure iOS for Duo.
sed -i 's/Stack Wallet/Stack Duo/g' ../ios/Runner/Info.plist
sed -i 's/com.cypherstack.stackwallet/com.cypherstack.stackduo/g' ../ios/Runner.xcodeproj/project.pbxproj
