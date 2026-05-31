param(
  [string]$OutDir = "dist"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $root "campus_cli.c"
$outPath = Join-Path (Join-Path $root $OutDir) "campus_cli.exe"

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outPath) | Out-Null

& gcc -O2 -std=c11 -o $outPath $src

Write-Host "Built $outPath"

