$FLUTTER_SDK_ZIP = "C:\development\flutter_windows_3.10.3-stable.zip"
$FLUTTER_SDK_URL = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.10.3-stable.zip"

# Create C:\development
New-Item -Path 'C:\development' -ItemType Directory -ErrorAction Ignore

# $wc = [System.Net.WebClient]::new()
# $publishedHash = '8E28E54D601F0751922DE24632C1E716B4684876255CF82304A9B19E89A9CCAC'
# $FileHash = Get-FileHash -InputStream ($wc.OpenRead("C:\development\flutter_windows_3.7.12-stable.zip"))

# if (-Not [System.IO.File]::Exists("C:\development\flutter_windows_3.7.12-stable.zip") or -Not ($FileHash.Hash -eq $publishedHash)) {
# } else {
# Download flutter_windows_3.7.12-stable.zip
Write-Output "Downloading $FLUTTER_SDK_ZIP"
$ProgressPreference = 'SilentlyContinue' # Speed up download and extraction processes, see https://stackoverflow.com/questions/28682642/powershell-why-is-using-invoke-webrequest-much-slower-than-a-browser-download and https://github.com/PowerShell/Microsoft.PowerShell.Archive/issues/32#issuecomment-642582179
Invoke-WebRequest -Uri $FLUTTER_SDK_URL -OutFile $FLUTTER_SDK_ZIP
# }

# Extract Flutter SDK
Write-Output "Extracting $FLUTTER_SDK_ZIP"
Expand-Archive $FLUTTER_SDK_ZIP -DestinationPath "C:\development"
Add-Type -Assembly "System.IO.Compression.Filesystem"

# See https://stackoverflow.com/a/69239861
function Add-Path {

  param(
    [Parameter(Mandatory, Position=0)]
    [string] $LiteralPath,
    [ValidateSet('User', 'CurrentUser', 'Machine', 'LocalMachine')]
    [string] $Scope 
  )

  Set-StrictMode -Version 1; $ErrorActionPreference = 'Stop'

  $isMachineLevel = $Scope -in 'Machine', 'LocalMachine'
  if ($isMachineLevel -and -not $($ErrorActionPreference = 'Continue'; net session 2>$null)) { throw "You must run AS ADMIN to update the machine-level Path environment variable." }  

  $regPath = 'registry::' + ('HKEY_CURRENT_USER\Environment', 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment')[$isMachineLevel]

  # Note the use of the .GetValue() method to ensure that the *unexpanded* value is returned.
  $currDirs = (Get-Item -LiteralPath $regPath).GetValue('Path', '', 'DoNotExpandEnvironmentNames') -split ';' -ne ''

  if ($LiteralPath -in $currDirs) {
    Write-Verbose "Already present in the persistent $(('user', 'machine')[$isMachineLevel])-level Path: $LiteralPath"
    return
  }

  $newValue = ($currDirs + $LiteralPath) -join ';'

  # Update the registry.
  Set-ItemProperty -Type ExpandString -LiteralPath $regPath Path $newValue

  # Broadcast WM_SETTINGCHANGE to get the Windows shell to reload the
  # updated environment, via a dummy [Environment]::SetEnvironmentVariable() operation.
  $dummyName = [guid]::NewGuid().ToString()
  [Environment]::SetEnvironmentVariable($dummyName, 'foo', 'User')
  [Environment]::SetEnvironmentVariable($dummyName, [NullString]::value, 'User')

  # Finally, also update the current session's `$env:Path` definition.
  # Note: For simplicity, we always append to the in-process *composite* value,
  #        even though for a -Scope Machine update this isn't strictly the same.
  $env:Path = ($env:Path -replace ';$') + ';' + $LiteralPath

  Write-Verbose "`"$LiteralPath`" successfully appended to the persistent $(('user', 'machine')[$isMachineLevel])-level Path and also the current-process value."

}

# Add Flutter SDK to PATH if it's not there already
if ($Env:Path -split ";" -contains 'C:\development\flutter\bin') {
  Write-Output "Flutter SDK in PATH, done"
} else {
  Write-Output "Attempting to add Flutter SDK to PATH"
	Add-Path("C:\development\flutter\bin")
}
