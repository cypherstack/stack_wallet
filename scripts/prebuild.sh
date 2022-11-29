# Create template lib/external_api_keys.dart file if it doesn't already exist
KEYS=../lib/external_api_keys.dart
if ! test -f "$KEYS"; then
    echo 'prebuild.sh: creating template lib/external_api_keys.dart file'
    printf 'const kChangeNowApiKey = "";\nconst kSimpleSwapApiKey = "";\n' > $KEYS
fi

# Create template wallet test parameter files if they don't already exist
BWTP=../test/services/coins/bitcoin/bitcoin_wallet_test_parameters.dart
if ! test -f "$BWTP"; then
    echo 'prebuild.sh: creating template test/services/coins/bitcoin/bitcoin_wallet_test_parameters.dart file'
    printf 'const TEST_MNEMONIC = "";\nconst ROOT_WIF = "";\nconst NODE_WIF_84 = "";\n' > $BWTP
fi

BCWTP=../test/services/coins/bitcoincash/bitcoincash_wallet_test_parameters.dart
if ! test -f "$BCWTP"; then
    echo 'prebuild.sh: creating template test/services/coins/bitcoincash/bitcoincash_wallet_test_parameters.dart file'
    printf 'const TEST_MNEMONIC = "";\nconst ROOT_WIF = "";\nconst NODE_WIF_84 = "";\n' > $BCWTP
fi

DWTP=../test/services/coins/dogecoin/dogecoin_wallet_test_parameters.dart
if ! test -f "$DWTP"; then
    echo 'prebuild.sh: creating template test/services/coins/dogecoin/dogecoin_wallet_test_parameters.dart file'
    printf 'const TEST_MNEMONIC = "";\nconst ROOT_WIF = "";\nconst NODE_WIF_84 = "";\n' > $DWTP
fi

NWTP=../test/services/coins/namecoin/namecoin_wallet_test_parameters.dart
if ! test -f "$NWTP"; then
    echo 'prebuild.sh: creating template test/services/coins/namecoin/namecoin_wallet_test_parameters.dart file'
    printf 'const TEST_MNEMONIC = "";\nconst ROOT_WIF = "";\nconst NODE_WIF_84 = "";\n' > $NWTP
fi

FWTP=../test/services/coins/firo/firo_wallet_test_parameters.dart
if ! test -f "$FWTP"; then
    echo 'prebuild.sh: creating template test/services/coins/firo/firo_wallet_test_parameters.dart file'
    printf 'const TEST_MNEMONIC = "";\nconst ROOT_WIF = "";\nconst NODE_WIF_84 = "";\n' > $FWTP
fi
