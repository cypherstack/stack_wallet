# Create template lib/external_api_keys.dart file if it doesn't already exist
$KEYS = "..\lib\external_api_keys.dart"
if (-not (Test-Path $KEYS)) {
    Write-Host "prebuild.ps1: creating template lib/external_api_keys.dart file"
    "const kChangeNowApiKey = '';" + "`nconst kSimpleSwapApiKey = '';" | Out-File $KEYS -Encoding UTF8
}

# Create template wallet test parameter files if they don't already exist
$coins = @("bitcoin", "bitcoincash", "dogecoin", "namecoin", "firo", "particl") # TODO add monero and wownero when those tests are updated to use the .gitignored test wallet setup: when doing that, make sure to update the test vectors for a new, private development seed

foreach ($coin in $coins) {
    $WALLETTESTPARAMFILE = "..\test\services\coins\$coin\${coin}_wallet_test_parameters.dart"
    if (-not (Test-Path $WALLETTESTPARAMFILE)) {
        Write-Host "prebuild.ps1: creating template test/services/coins/$coin/${coin}_wallet_test_parameters.dart file"
        "const TEST_MNEMONIC = "";" + "`nconst ROOT_WIF = "";" + "`nconst NODE_WIF_84 = "";" | Out-File -FilePath $WALLETTESTPARAMFILE -Encoding UTF8
    }
}
