# Configure macOS for Duo.
sed -i 's/com.cypherstack.stackWallet/com.cypherstack.stackDuo/g' ../macos/Runner.xcodeproj/project.pbxproj
