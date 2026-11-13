# Resolve paths from this script, regardless of the caller's working directory.
$ErrorActionPreference = 'Stop'
$PROJECT_ROOT = Split-Path -Parent $PSScriptRoot

# Create template lib/external_api_keys.dart file if it doesn't already exist
$KEYS = Join-Path $PROJECT_ROOT 'lib/external_api_keys.dart'
if (-not (Test-Path -LiteralPath $KEYS -PathType Leaf)) {
    Write-Host "prebuild.ps1: creating template lib/external_api_keys.dart file"

    @'
const String kChangeNowApiKey = "";
const String kSimpleSwapApiKey = "";
const String kNanswapApiKey = "";
const String kNanoSwapRpcApiKey = "";
const String kWizSwapApiKey = "";
const kShopInBitAccessKey = "";
const kShopInBitPartnerSecret = "";
const kCakePayApiToken = "";
const kExolixApiKey = "";
const kLetsExchangeId = "";
const kLetsExchangeToken = "";
const kCypherGoatApiKey = "";
const kCypherGoatAffiliate = "";
const kTrocadorApiKey = "";
const kTrocadorRefCode = "";
'@ | Out-File -LiteralPath $KEYS -Encoding UTF8
}


# Create template wallet test parameter files if they don't already exist
$coins = @("bitcoin", "bitcoincash", "dogecoin", "namecoin", "firo", "particl") # TODO add monero and wownero when those tests are updated to use the .gitignored test wallet setup: when doing that, make sure to update the test vectors for a new, private development seed

foreach ($coin in $coins) {
    $WALLETTESTPARAMFILE = Join-Path $PROJECT_ROOT "test/services/coins/$coin/${coin}_wallet_test_parameters.dart"
    if (-not (Test-Path -LiteralPath $WALLETTESTPARAMFILE -PathType Leaf)) {
        Write-Host "prebuild.ps1: creating template test/services/coins/$coin/${coin}_wallet_test_parameters.dart file"
        @'
const TEST_MNEMONIC = "";
const ROOT_WIF = "";
const NODE_WIF_84 = "";
'@ | Out-File -LiteralPath $WALLETTESTPARAMFILE -Encoding UTF8
    }
}
