param([string]$Avd = 'Kotoba_Forest')
$ErrorActionPreference = 'Stop'
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$executable = Join-Path $sdk 'emulator\emulator.exe'
if (!(Test-Path -LiteralPath $executable)) { throw 'Android SDK emulator was not found.' }
# Use the verified Windows input/audio compatibility options. Keep host audio enabled.
Start-Process -FilePath $executable -ArgumentList @(
    '-avd', $Avd, '-no-snapshot',
    '-feature', '-KeycodeForwarding',
    '-audio', 'dsound'
) -WindowStyle Normal
