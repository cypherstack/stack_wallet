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
$GoRoot = & (Join-Path $ScriptDir 'fetch-go-windows.ps1') `
    -ProjectRoot $ProjectRoot
$env:PATH = "$(Join-Path $GoRoot 'bin');$env:PATH"
$BuildState = Join-Path $ProjectRoot '.nix-build-state\windows'
if (Test-Path $BuildState) {
    Remove-Item -Recurse -Force $BuildState
}
New-Item -ItemType Directory -Force $BuildState | Out-Null
$env:PUB_CACHE = Join-Path $BuildState 'pub'
$env:CARGO_HOME = Join-Path $BuildState 'cargo'
$env:GOCACHE = Join-Path $BuildState 'go'
$env:TEMP = Join-Path $BuildState 'tmp'
$env:TMP = $env:TEMP
$env:CARGO_ENCODED_RUSTFLAGS = "--remap-path-prefix=$ProjectRoot=."
New-Item -ItemType Directory -Force $env:TEMP | Out-Null
$env:SOURCE_DATE_EPOCH = '1'
$env:PERL_HASH_SEED = '0'
$env:PERL_PERTURB_KEYS = '0'
$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:DART_SUPPRESS_ANALYTICS = 'true'
$env:GOTOOLCHAIN = 'local'
$env:GOFLAGS = '-modcacherw -trimpath -buildvcs=false'
$RustVersionContent = Get-Content -Raw (Join-Path $ProjectRoot 'rust_version.env')
$RustVersionMatch = [regex]::Match(
    $RustVersionContent,
    '(?m)^RUST_VERSION="([0-9]+\.[0-9]+\.[0-9]+)"\r?$'
)
if (-not $RustVersionMatch.Success) {
    throw 'Invalid rust_version.env.'
}
$PinnedRustVersion = $RustVersionMatch.Groups[1].Value
$env:RUSTUP_HOME = Join-Path `
    (Join-Path $ProjectRoot '.rustup-nix-windows') `
    $PinnedRustVersion
$RustupCommand = Get-Command rustup.exe -ErrorAction SilentlyContinue
if ($null -eq $RustupCommand) {
    throw 'rustup.exe is required on the Windows host.'
}
$env:STACK_NIX_REAL_RUSTUP = $RustupCommand.Source
& $env:STACK_NIX_REAL_RUSTUP set auto-self-update disable
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $env:STACK_NIX_REAL_RUSTUP toolchain install $PinnedRustVersion --profile minimal
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$RustVersion = & $env:STACK_NIX_REAL_RUSTUP run $PinnedRustVersion rustc --version
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if ($RustVersion -notmatch "^rustc $([regex]::Escape($PinnedRustVersion)) ") {
    throw "Unexpected Rust version: $RustVersion"
}
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Set-Location $ProjectRoot
Push-Location (Join-Path $ProjectRoot 'scripts')
try {
    & '.\prebuild.ps1'
} finally {
    Pop-Location
}
& $Flutter clean
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Flutter pub get --enforce-lockfile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Cargokit only searches for rustup.exe on Windows, so pin its otherwise moving
# stable fallback in the isolated Pub cache before Gradle compiles the plugins.
$CargokitBuilders = @(
    Get-ChildItem (Join-Path $env:PUB_CACHE 'git') `
        -Recurse -File -Filter 'builder.dart' |
        Where-Object {
            $_.FullName -match `
                '[\\/]cargokit[\\/]build_tool[\\/]lib[\\/]src[\\/]builder\.dart$'
        }
)
if ($CargokitBuilders.Count -lt 2) {
    throw 'Expected the Tor and Xelis Cargokit builders in the Pub cache.'
}
$MovingRust = "String get _toolchain => _buildOptions?.toolchain.name ?? 'stable';"
$PinnedRust = "String get _toolchain => _buildOptions?.toolchain.name ?? '$PinnedRustVersion';"
foreach ($Builder in $CargokitBuilders) {
    $BuilderContent = Get-Content -Raw $Builder.FullName
    if (-not $BuilderContent.Contains($MovingRust)) {
        throw "Unexpected Cargokit toolchain declaration: $($Builder.FullName)"
    }
    [System.IO.File]::WriteAllText(
        $Builder.FullName,
        $BuilderContent.Replace($MovingRust, $PinnedRust),
        $Utf8NoBom
    )
}

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
$ReleaseDirectory = Join-Path $ProjectRoot 'build\windows\x64\runner\Release'
& $Flutter build windows --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$Artifact = Get-ChildItem `
    $ReleaseDirectory `
    -File -Filter '*.exe' | Select-Object -First 1
if ($null -eq $Artifact) {
    throw 'Windows release artifact was not produced.'
}
& $Dart run contrib\nix\artifact_manifest.dart create `
    $ReleaseDirectory `
    (Join-Path $ProjectRoot 'build\attestations\windows.manifest')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Output "Build complete: $($Artifact.FullName)"
