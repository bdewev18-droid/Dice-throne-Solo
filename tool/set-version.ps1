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
$versionJsonPath = Join-Path $PSScriptRoot '..\web\version.json'
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
if ($main -match 'const int appBuildNumber = \d+;') {
  $main = [regex]::Replace(
    $main,
    "const int appBuildNumber = \d+;",
    "const int appBuildNumber = $BuildNumber;",
    1
  )
}

if (Test-Path $versionJsonPath) {
  try {
    $vJson = Get-Content -Raw $versionJsonPath | ConvertFrom-Json
    $vJson.version = $Version
    $vJson.buildNumber = $BuildNumber
    $vJson | ConvertTo-Json -Depth 4 | Set-Content -Path $versionJsonPath -Encoding utf8
  } catch {
    Write-Warning "Impossible de mettre a jour web/version.json: $_"
  }
}

Set-Content -Path $pubspecPath -Value $pubspec -NoNewline
Set-Content -Path $mainPath -Value $main -NoNewline
Write-Host "Version synchronisee: $Version+$BuildNumber"
