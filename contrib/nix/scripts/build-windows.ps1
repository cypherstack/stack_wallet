param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$FlutterRoot = & (Join-Path $ScriptDir 'fetch-flutter-windows.ps1') `
    -ProjectRoot $ProjectRoot
$Flutter = Join-Path $FlutterRoot 'bin\flutter.bat'
$Dart = Join-Path $FlutterRoot 'bin\dart.bat'
$env:PUB_CACHE = Join-Path $ProjectRoot '.pub-cache-nix-windows'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Set-Location $ProjectRoot
Push-Location (Join-Path $ProjectRoot 'scripts')
try {
    & '.\prebuild.ps1'
} finally {
    Pop-Location
}
& $Flutter pub get --enforce-lockfile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$LockContent = Get-Content -Raw (Join-Path $ProjectRoot 'pubspec.lock')
$VersionMatch = [regex]::Match(
    $LockContent,
    '(?ms)^  flutter_mwebd:\r?\n.*?^    version: "([^"]+)"\r?$'
)
if (-not $VersionMatch.Success) {
    throw 'flutter_mwebd was not found in pubspec.lock.'
}
$PluginVersion = $VersionMatch.Groups[1].Value
$PluginDirectory = Join-Path $env:PUB_CACHE "hosted\pub.dev\flutter_mwebd-$PluginVersion"
$PluginPubspec = Join-Path $PluginDirectory 'pubspec.yaml'
if (-not (Test-Path $PluginPubspec)) {
    throw "Locked flutter_mwebd package was not found: $PluginDirectory"
}
$Content = Get-Content -Raw $PluginPubspec
$Patched = [regex]::Replace(
    $Content,
    '(?ms)^      windows:\r?\n        ffiPlugin: true\r?\n',
    ''
)
if ($Patched -eq $Content -and $Content -match '(?m)^      windows:$') {
    throw 'Unexpected flutter_mwebd Windows plugin declaration.'
}
[System.IO.File]::WriteAllText($PluginPubspec, $Patched, $Utf8NoBom)
& $Flutter pub get --enforce-lockfile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$EpicVersion = (& git -C crypto_plugins/flutter_libepiccash `
    describe --tags --exact-match HEAD 2>$null)
if ($EpicVersion -notmatch '^[A-Za-z0-9._+-]+$') { $EpicVersion = 'dev' }
$MwcVersion = (& git -C crypto_plugins/flutter_libmwc `
    describe --tags --exact-match HEAD 2>$null)
if ($MwcVersion -notmatch '^[A-Za-z0-9._+-]+$') { $MwcVersion = 'dev' }
New-Item -ItemType Directory -Force `
    crypto_plugins/flutter_libepiccash/lib,
    crypto_plugins/flutter_libmwc/lib | Out-Null
[System.IO.File]::WriteAllText(
    (Join-Path $ProjectRoot 'crypto_plugins\flutter_libepiccash\lib\git_versions.dart'),
    "String getPluginVersion() => `"$EpicVersion`";`n",
    $Utf8NoBom
)
[System.IO.File]::WriteAllText(
    (Join-Path $ProjectRoot 'crypto_plugins\flutter_libmwc\lib\git_versions.dart'),
    "String getPluginVersion() => `"$MwcVersion`";`n",
    $Utf8NoBom
)

& $Dart run coinlib:build_windows
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Flutter build windows --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$Artifact = Get-ChildItem `
    (Join-Path $ProjectRoot 'build\windows\x64\runner\Release') `
    -File -Filter '*.exe' | Select-Object -First 1
if ($null -eq $Artifact) {
    throw 'Windows release artifact was not produced.'
}
Write-Output "Build complete: $($Artifact.FullName)"
