# Windows can leave copied Flutter assets marked read-only after a build.
# Only generated files below this project's build directory are changed.
$appBuildPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'build'
if (Test-Path -LiteralPath $appBuildPath) {
  Get-ChildItem -LiteralPath $appBuildPath -Recurse -Force | ForEach-Object {
    if ($_.Attributes -band [IO.FileAttributes]::ReadOnly) {
      $_.Attributes = $_.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
    }
  }
}
