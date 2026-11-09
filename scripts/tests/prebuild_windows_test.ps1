# Run with: powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/prebuild_windows_test.ps1
# No Flutter, package dependencies, credentials, or native libraries required.
$ErrorActionPreference = 'Stop'
$sourceScript = Join-Path (Split-Path -Parent $PSScriptRoot) 'prebuild.ps1'
$fixtureBase = Join-Path ([System.IO.Path]::GetTempPath()) ('stack prebuild [paths] ' + [Guid]::NewGuid())
$coins = @('bitcoin', 'bitcoincash', 'dogecoin', 'namecoin', 'firo', 'particl')
$expectedParameters = @'
const TEST_MNEMONIC = "";
const ROOT_WIF = "";
const NODE_WIF_84 = "";
'@

function Assert($condition, $message) {
    if (-not $condition) { throw $message }
}

function New-Fixture($name) {
    $root = Join-Path $fixtureBase $name
    foreach ($relative in @('scripts', 'lib', 'elsewhere')) {
        [System.IO.Directory]::CreateDirectory((Join-Path $root $relative)) | Out-Null
    }
    foreach ($coin in $coins) {
        [System.IO.Directory]::CreateDirectory((Join-Path $root "test/services/coins/$coin")) | Out-Null
    }
    Copy-Item -LiteralPath $sourceScript -Destination (Join-Path $root 'scripts/prebuild.ps1')
    return $root
}

function Parameters-Path($root, $coin) {
    return Join-Path $root "test/services/coins/$coin/${coin}_wallet_test_parameters.dart"
}

try {
    foreach ($cwd in @('.', 'elsewhere')) {
        $root = New-Fixture ('cwd-' + [Guid]::NewGuid())
        Push-Location -LiteralPath (Join-Path $root $cwd)
        try { & (Join-Path $root 'scripts/prebuild.ps1') } finally { Pop-Location }
        Assert (Test-Path -LiteralPath (Join-Path $root 'lib/external_api_keys.dart') -PathType Leaf) 'API key stub was not written in the checkout.'
        foreach ($coin in $coins) {
            $actual = Get-Content -LiteralPath (Parameters-Path $root $coin) -Raw
            Assert ($actual.TrimEnd() -eq $expectedParameters.TrimEnd()) "Invalid Dart wallet stub for $coin."
        }
        Assert (-not (Test-Path -LiteralPath (Join-Path $fixtureBase 'lib/external_api_keys.dart'))) 'prebuild wrote outside its checkout.'
    }

    $root = New-Fixture 'preserve'
    $keys = Join-Path $root 'lib/external_api_keys.dart'
    $parameters = Parameters-Path $root 'bitcoin'
    Set-Content -LiteralPath $keys -Value 'existing keys'
    Set-Content -LiteralPath $parameters -Value 'existing wallet parameters'
    & (Join-Path $root 'scripts/prebuild.ps1')
    Assert ((Get-Content -LiteralPath $keys -Raw).TrimEnd() -eq 'existing keys') 'Existing keys were overwritten.'
    Assert ((Get-Content -LiteralPath $parameters -Raw).TrimEnd() -eq 'existing wallet parameters') 'Existing parameters were overwritten.'

    $root = New-Fixture 'write-failure'
    [System.IO.Directory]::CreateDirectory((Parameters-Path $root 'bitcoin')) | Out-Null
    $failed = $false
    try { & (Join-Path $root 'scripts/prebuild.ps1') } catch { $failed = $true }
    Assert $failed 'A directory at a wallet stub path must fail the script.'
    Assert (-not (Test-Path -LiteralPath (Parameters-Path $root 'bitcoincash'))) 'prebuild continued writing after a failure.'
    Write-Host 'All 4 PowerShell prebuild tests passed.'
} finally {
    if (Test-Path -LiteralPath $fixtureBase) { Remove-Item -LiteralPath $fixtureBase -Recurse -Force }
}
