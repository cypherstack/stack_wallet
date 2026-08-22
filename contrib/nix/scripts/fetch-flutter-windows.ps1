param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'

function Get-QuotedEnvValue {
    param([string]$Path, [string]$Name)

    $Pattern = '^{0}="([^"]*)"$' -f [regex]::Escape($Name)
    foreach ($Line in [System.IO.File]::ReadLines($Path)) {
        $Match = [regex]::Match($Line, $Pattern)
        if ($Match.Success) { return $Match.Groups[1].Value }
    }
    throw "Missing $Name in $Path."
}

$VersionFile = Join-Path $ProjectRoot 'flutter_version.env'
$Version = Get-QuotedEnvValue $VersionFile 'FLUTTER_VERSION'
$Checksum = Get-QuotedEnvValue $VersionFile 'FLUTTER_SHA256_WINDOWS_X64'
if ($Checksum -notmatch '^[0-9a-f]{64}$') {
    throw 'Invalid Windows Flutter checksum.'
}
$SdkRoot = Join-Path $ProjectRoot '.flutter-sdk-windows'
$Archive = Join-Path $SdkRoot "flutter_windows_${Version}-stable.zip"
$FlutterRoot = Join-Path $SdkRoot 'flutter'
$Url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_${Version}-stable.zip"
$Marker = Join-Path $FlutterRoot '.stack-wallet-nix-sdk'
$ExpectedMarker = "${Version}:${Checksum}"

New-Item -ItemType Directory -Force -Path $SdkRoot | Out-Null
if (-not (Test-Path $Marker) -or
    [System.IO.File]::ReadAllText($Marker).Trim() -ne $ExpectedMarker -or
    -not (Test-Path (Join-Path $FlutterRoot 'bin\flutter.bat'))) {
    if (-not (Test-Path $Archive) -or
        (Get-FileHash -Algorithm SHA256 $Archive).Hash.ToLowerInvariant() -ne $Checksum) {
        $Temporary = "$Archive.partial"
        for ($Attempt = 1; $Attempt -le 4; $Attempt++) {
            try {
                Invoke-WebRequest -Uri $Url -OutFile $Temporary
                break
            } catch {
                Remove-Item -Force -ErrorAction SilentlyContinue $Temporary
                if ($Attempt -eq 4) { throw }
                Start-Sleep -Seconds (2 * $Attempt)
            }
        }
        if ((Get-FileHash -Algorithm SHA256 $Temporary).Hash.ToLowerInvariant() -ne $Checksum) {
            Remove-Item -Force $Temporary
            throw 'Flutter archive checksum mismatch.'
        }
        Move-Item -Force $Temporary $Archive
    }

    $Extracting = Join-Path $SdkRoot 'extracting'
    if (Test-Path $Extracting) { Remove-Item -Recurse -Force $Extracting }
    if (Test-Path $FlutterRoot) { Remove-Item -Recurse -Force $FlutterRoot }
    New-Item -ItemType Directory -Path $Extracting | Out-Null
    Expand-Archive -Path $Archive -DestinationPath $Extracting
    Move-Item (Join-Path $Extracting 'flutter') $FlutterRoot
    Remove-Item -Recurse -Force $Extracting
    if (-not (Test-Path (Join-Path $FlutterRoot 'bin\flutter.bat'))) {
        throw 'Unexpected Flutter archive structure.'
    }
    [System.IO.File]::WriteAllText($Marker, "$ExpectedMarker`n")
}

Write-Output $FlutterRoot
