# Run Handee from D: with build caches on D: (avoids full C: drive).
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $ProjectRoot

if (-not $env:GRADLE_USER_HOME) { $env:GRADLE_USER_HOME = "D:\dev\gradle-home" }
if (-not $env:PUB_CACHE) { $env:PUB_CACHE = "D:\dev\pub-cache" }
if (-not $env:TEMP) { $env:TEMP = "D:\dev\tmp" }
if (-not $env:TMP) { $env:TMP = "D:\dev\tmp" }

New-Item -ItemType Directory -Force -Path $env:GRADLE_USER_HOME, $env:PUB_CACHE, $env:TEMP | Out-Null

Write-Host "Project:   $ProjectRoot"
Write-Host "Gradle:    $env:GRADLE_USER_HOME"
Write-Host "Pub cache: $env:PUB_CACHE"
Write-Host "Temp:      $env:TEMP"
Write-Host ""

flutter pub get

if ($args.Count -gt 0 -and $args[0] -eq "--build-only") {
  flutter build apk --debug
  exit 0
}

if ($args.Count -gt 0) {
  flutter run -d $args[0]
} else {
  flutter run
}
