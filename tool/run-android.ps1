$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$asciiRepository = Join-Path $env:USERPROFILE 'develop\kotoba-no-mori'
if (Test-Path $asciiRepository) {
  $alias = Get-Item -LiteralPath $asciiRepository
  if ($alias.LinkType -eq 'Junction' -and $alias.Target -eq (Get-Location).Path) {
    Set-Location $asciiRepository
  }
}
$flutterBin = Join-Path $env:USERPROFILE 'develop\flutter\bin'
if (Test-Path $flutterBin) { $env:PATH = "$flutterBin;$env:PATH" }
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$studioJava = 'C:\Program Files\Android\Android Studio\jbr'
if (Test-Path $studioJava) { $env:JAVA_HOME = $studioJava }
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter SDKが見つかりません。' }
$adb = Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'
if (-not (Test-Path $adb)) { throw 'Android SDKのplatform-toolsが見つかりません。' }
$devices = & $adb devices
if (-not ($devices | Select-String '\sdevice$')) {
  $emulator = Join-Path $env:ANDROID_HOME 'emulator\emulator.exe'
  $avds = @(& $emulator -list-avds)
  if ($avds.Count -eq 0) { throw 'Android StudioのDevice Managerで仮想端末を作成してください。' }
  Start-Process -FilePath $emulator -ArgumentList @('-avd', $avds[0]) -WindowStyle Hidden
  Write-Output 'Android端末の起動を待っています…'
  & $adb wait-for-device
}
$serial = (& $adb devices | Select-String '^\S+\s+device$' | Select-Object -First 1).ToString().Split("`t")[0]
. (Join-Path $PSScriptRoot 'prepare-build.ps1')
flutter run -d $serial
exit $LASTEXITCODE
