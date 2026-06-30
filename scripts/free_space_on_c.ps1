# Safe cleanup for full C: drive — run in PowerShell as your user (not admin required).
# Usage: powershell -ExecutionPolicy Bypass -File D:\Handee\handee\scripts\free_space_on_c.ps1

$ErrorActionPreference = "SilentlyContinue"
$freed = 0

function Remove-TreeSize([string]$Path) {
    if (-not (Test-Path $Path)) { return 0 }
    $size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
    Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
    if ($size) { return $size } else { return 0 }
}

Write-Host "=== C: drive before ===" -ForegroundColor Cyan
$before = Get-PSDrive C
Write-Host ("Free: {0:N2} GB" -f ($before.Free / 1GB))

$targets = @(
    "$env:LOCALAPPDATA\Temp\*",
    "$env:TEMP\*",
    "$env:USERPROFILE\.gradle\caches",
    "$env:LOCALAPPDATA\HandeeGradleHome\caches",
    "$env:USERPROFILE\Desktop\Handee\handee\build",
    "$env:USERPROFILE\Desktop\Handee\handee\.dart_tool",
    "$env:USERPROFILE\Desktop\Handee\handee\android\.gradle",
    "$env:USERPROFILE\Desktop\Handee\handee\android\app\build",
    "$env:LOCALAPPDATA\Pub\Cache",
    "$env:LOCALAPPDATA\pip\Cache"
)

# Flutter tool temp folders
Get-ChildItem "$env:LOCALAPPDATA\Temp" -Directory -Filter "flutter_tools.*" -ErrorAction SilentlyContinue |
    ForEach-Object { $targets += $_.FullName }

foreach ($t in $targets) {
  if ($t -like "**") {
    Get-ChildItem $t -ErrorAction SilentlyContinue | ForEach-Object {
      $n = $_.FullName
      Write-Host "Removing: $n"
      $freed += Remove-TreeSize $n
    }
  } else {
    Write-Host "Removing: $t"
    $freed += Remove-TreeSize $t
  }
}

# Empty Recycle Bin
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "Recycle Bin emptied (if accessible)."

Write-Host ""
Write-Host "=== C: drive after ===" -ForegroundColor Cyan
$after = Get-PSDrive C
Write-Host ("Free: {0:N2} GB" -f ($after.Free / 1GB))
Write-Host ("Estimated freed: {0:N2} GB" -f ($freed / 1GB))
Write-Host ""
Write-Host "Next: run the app from D: only:" -ForegroundColor Green
Write-Host "  cd D:\Handee\handee"
Write-Host "  .\run.bat R58M775JX2W"
