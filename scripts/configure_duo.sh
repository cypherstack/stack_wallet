# Configure files for Duo.
sed -i 's/Wallet/Duo/g' ../lib/app_config.dart
sed -i 's/Stack Wallet/Stack Duo/g' ../pubspec.yaml
