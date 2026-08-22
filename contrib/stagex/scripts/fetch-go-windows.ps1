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

$VersionFile = Join-Path $ProjectRoot 'go_version.env'
$Version = Get-QuotedEnvValue $VersionFile 'GO_VERSION'
$Checksum = Get-QuotedEnvValue $VersionFile 'GO_SHA256_WINDOWS_X64'
if ($Checksum -notmatch '^[0-9a-f]{64}$') {
    throw 'Invalid Windows Go checksum.'
}
$SdkRoot = Join-Path $ProjectRoot '.go-sdk-windows'
$Archive = Join-Path $SdkRoot "go$Version.windows-amd64.zip"
$GoRoot = Join-Path $SdkRoot 'go'
$Marker = Join-Path $GoRoot '.stack-wallet-stagex-sdk'
$ExpectedMarker = "${Version}:${Checksum}"
$Url = "https://go.dev/dl/go$Version.windows-amd64.zip"

New-Item -ItemType Directory -Force -Path $SdkRoot | Out-Null
if (-not (Test-Path $Marker) -or
    [System.IO.File]::ReadAllText($Marker).Trim() -ne $ExpectedMarker -or
    -not (Test-Path (Join-Path $GoRoot 'bin\go.exe'))) {
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
            throw 'Go archive checksum mismatch.'
        }
        Move-Item -Force $Temporary $Archive
    }

    $Extracting = Join-Path $SdkRoot 'extracting'
    if (Test-Path $Extracting) { Remove-Item -Recurse -Force $Extracting }
    if (Test-Path $GoRoot) { Remove-Item -Recurse -Force $GoRoot }
    New-Item -ItemType Directory -Path $Extracting | Out-Null
    Expand-Archive -Path $Archive -DestinationPath $Extracting
    Move-Item (Join-Path $Extracting 'go') $GoRoot
    Remove-Item -Recurse -Force $Extracting
    if (-not (Test-Path (Join-Path $GoRoot 'bin\go.exe'))) {
        throw 'Unexpected Go archive structure.'
    }
    [System.IO.File]::WriteAllText($Marker, "$ExpectedMarker`n")
}

$GoVersion = & (Join-Path $GoRoot 'bin\go.exe') version
if ($LASTEXITCODE -ne 0 -or
    $GoVersion -notmatch "^go version go$([regex]::Escape($Version)) windows/amd64$") {
    throw "Unexpected Go version: $GoVersion"
}
Write-Output $GoRoot
