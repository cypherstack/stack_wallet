# Create template lib/external_api_keys.dart file if it doesn't already exist
KEYS=../lib/external_api_keys.dart
if ! test -f "$KEYS"; then
    echo 'prebuild.sh: creating template lib/external_api_keys.dart file'
    echo 'const kChangeNowApiKey = "";' > $KEYS
fi
