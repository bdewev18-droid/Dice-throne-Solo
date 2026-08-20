param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^\d+\.\d+\.\d+$')]
  [string]$Version,
  [Parameter(Mandatory = $true)]
  [ValidateRange(1, 999999)]
  [int]$BuildNumber
)

$ErrorActionPreference = 'Stop'
$pubspecPath = Join-Path $PSScriptRoot '..\pubspec.yaml'
$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
$pubspec = Get-Content -Raw $pubspecPath
$main = Get-Content -Raw $mainPath

$pubspec = [regex]::Replace(
  $pubspec,
  '(?m)^version:\s*\S+\r?$',
  "version: $Version+$BuildNumber",
  1
)
$main = [regex]::Replace(
  $main,
  "const String appVersionLabel = 'Version [^']+';",
  "const String appVersionLabel = 'Version $Version';",
  1
)

Set-Content -Path $pubspecPath -Value $pubspec -NoNewline
Set-Content -Path $mainPath -Value $main -NoNewline
Write-Host "Version synchronisee: $Version+$BuildNumber"
