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
  $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $env:ComSpec
  $startInfo.WorkingDirectory = $root
  $startInfo.UseShellExecute = $false
  $startInfo.CreateNoWindow = $false
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  $quotedFlutter = '"' + $flutter + '"'
  $quotedArguments = $Arguments | ForEach-Object {
    if ($_ -match '\s') {
      '"' + ($_ -replace '"', '\"') + '"'
    } else {
      $_
    }
  }
  $startInfo.Arguments = "/d /c call $quotedFlutter $($quotedArguments -join ' ')"
  $process = [System.Diagnostics.Process]::Start($startInfo)
  $stdoutTask = $process.StandardOutput.ReadToEndAsync()
  $stderrTask = $process.StandardError.ReadToEndAsync()
  if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result
    if ($stdout) { Write-Host $stdout }
    if ($stderr) { Write-Host $stderr }
    $combinedOutput = "$stdout`n$stderr"
    $acceptedTimeout =
      ($Arguments[0] -eq 'analyze' -and $combinedOutput -match 'No issues found!') -or
      ($Arguments[0] -eq 'build' -and $Arguments[1] -eq 'web' -and $combinedOutput -match 'Built build\\web') -or
      ($Arguments[0] -eq 'build' -and $Arguments[1] -eq 'apk' -and $combinedOutput -match 'Built build\\app\\outputs\\flutter-apk')
    if ($acceptedTimeout) {
      Write-Host "Flutter a affiche un succes avant le timeout; verification acceptee."
      return
    }
    throw @"
Commande Flutter interrompue apres $TimeoutSeconds secondes.

Si cette commande est lancee depuis Codex, relance Flutter hors sandbox / avec droits systeme.
Le Flutter tool doit pouvoir ecrire dans %APPDATA%\.flutter_tool_state et acceder a C:\dev\flutter.
Voir docs\BUILD_PROCESS.md, section Fast local check.
"@
  }
  $stdout = $stdoutTask.Result
  $stderr = $stderrTask.Result
  if ($stdout) { Write-Host $stdout }
  if ($stderr) { Write-Host $stderr }
  $process.Refresh()
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
