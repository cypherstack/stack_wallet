# Create template lib/external_api_keys.dart file if it doesn't already exist
KEYS=../lib/external_api_keys.dart
if ! test -f "$KEYS"; then
    echo 'prebuild.sh: creating template lib/external_api_keys.dart file'
    printf 'const kChangeNowApiKey = "";\nconst kSimpleSwapApiKey = "";\n' > $KEYS
fi

# Create template wallet test parameter files if they don't already exist
declare -a coins=("bitcoin" "bitcoincash" "dogecoin" "namecoin" "firo") # TODO add monero and wownero when those tests are updated to use the .gitignored test wallet setup: when doing that, make sure to update the test vectors for a new, private development seed

for coin in "${coins[@]}"
do
    WALLETTESTPARAMFILE="../test/services/coins/${coin}/${coin}_wallet_test_parameters.dart"
    if ! test -f "$WALLETTESTPARAMFILE"; then
        echo "prebuild.sh: creating template test/services/coins/${coin}/${coin}_wallet_test_parameters.dart file"
        printf 'const TEST_MNEMONIC = "";\nconst ROOT_WIF = "";\nconst NODE_WIF_84 = "";\n' > $WALLETTESTPARAMFILE
    fi
done
