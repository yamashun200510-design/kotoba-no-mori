$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$asciiRepository = Join-Path $env:USERPROFILE 'develop\kotoba-no-mori'
if (Test-Path $asciiRepository) {
  $alias = Get-Item -LiteralPath $asciiRepository
  if ($alias.LinkType -eq 'Junction' -and $alias.Target -eq (Get-Location).Path) {
    Set-Location $asciiRepository
  }
}
$localFlutter = Join-Path $env:USERPROFILE 'develop\flutter\bin'
if (Test-Path (Join-Path $localFlutter 'flutter.bat')) {
  $env:PATH = "$localFlutter;$env:PATH"
}
$localAndroid = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
if (Test-Path $localAndroid) { $env:ANDROID_HOME = $localAndroid }
$studioJava = 'C:\Program Files\Android\Android Studio\jbr'
if (Test-Path $studioJava) { $env:JAVA_HOME = $studioJava }
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter SDKを導入してflutter/binをPATHに追加してください。README.mdを参照。'
}
if (-not (Test-Path android\app\build.gradle.kts)) {
  flutter create --platforms=android,ios --org jp.kotobanomori --project-name kotoba_no_mori .
  if ($LASTEXITCODE -ne 0) { throw 'Flutterプロジェクト生成に失敗しました。' }
}
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'パッケージ取得に失敗しました。' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw '静的解析に失敗しました。' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'テストに失敗しました。' }
. (Join-Path $PSScriptRoot 'prepare-build.ps1')
flutter build apk --debug
if ($LASTEXITCODE -ne 0) { throw 'Androidビルドに失敗しました。flutter doctor -vを確認してください。' }
