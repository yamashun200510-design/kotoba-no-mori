param(
    [Parameter(Mandatory = $true)][string]$Flutter,
    [Parameter(Mandatory = $true)][string]$StagingDirectory
)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$stage = [IO.Path]::GetFullPath($StagingDirectory)
if ($stage -match '[^\x00-\x7F]') { throw 'Use an ASCII-only staging path for Windows AOT.' }
if (Test-Path -LiteralPath $stage) { throw 'Choose a new staging directory to avoid overwriting other work.' }
New-Item -ItemType Directory -Path $stage | Out-Null
foreach ($folder in @('lib', 'assets', 'android')) {
    & robocopy (Join-Path $project $folder) (Join-Path $stage $folder) /E /XD .gradle build /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "Source copy failed: $folder" }
}
foreach ($file in @('pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml')) {
    Copy-Item -LiteralPath (Join-Path $project $file) -Destination $stage
}
Get-ChildItem -LiteralPath $stage -Recurse -File -Force | Where-Object IsReadOnly | ForEach-Object { $_.IsReadOnly = $false }
Push-Location $stage
try {
    & $Flutter pub get --offline
    if ($LASTEXITCODE -ne 0) { throw 'pub get failed' }
    & $Flutter build apk --release --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Release build failed' }
    Write-Host "Unsigned APK: $stage\build\app\outputs\flutter-apk\app-release.apk"
} finally {
    Pop-Location
}
