param(
  [ValidateSet('web', 'apk', 'analyze')]
  [string]$Target = 'web',
  [ValidateRange(30, 1800)]
  [int]$TimeoutSeconds = 180,
  [switch]$WithAnalyze
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$flutterCandidates = @(
  'C:\dev\flutter\bin\flutter.bat',
  'E:\flutter\flutter\bin\flutter.bat'
)
$flutter = $flutterCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $flutter) {
  $flutter = (Get-Command flutter.bat -ErrorAction SilentlyContinue).Source
}
if (-not $flutter) {
  throw 'Flutter introuvable. Verifier C:\dev\flutter ou E:\flutter\flutter.'
}

function Invoke-BoundedFlutter {
  param([string[]]$Arguments)

  Write-Host "> $flutter $($Arguments -join ' ')"
  $process = Start-Process -FilePath $flutter -ArgumentList $Arguments -WorkingDirectory $root -NoNewWindow -PassThru
  if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    throw @"
Commande Flutter interrompue apres $TimeoutSeconds secondes.

Si cette commande est lancee depuis Codex, relance Flutter hors sandbox / avec droits systeme.
Le Flutter tool doit pouvoir ecrire dans %APPDATA%\.flutter_tool_state et acceder a C:\dev\flutter.
Voir docs\BUILD_PROCESS.md, section Fast local check.
"@
  }
  if ($process.ExitCode -ne 0) {
    throw "Flutter a retourne le code $($process.ExitCode)."
  }
}

if ($WithAnalyze) {
  Invoke-BoundedFlutter @('analyze', '--no-pub')
}

switch ($Target) {
  'web' { Invoke-BoundedFlutter @('build', 'web', '--release', '--base-href', '/Dice-throne-Solo/', '--no-pub') }
  'apk' { Invoke-BoundedFlutter @('build', 'apk', '--release', '--no-pub') }
  'analyze' { if (-not $WithAnalyze) { Invoke-BoundedFlutter @('analyze', '--no-pub') } }
}

Write-Host "Verification $Target terminee."
