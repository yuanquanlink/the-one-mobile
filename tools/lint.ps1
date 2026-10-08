[CmdletBinding()]
param(
  [string]$CommandLineRoot = ''
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$preflightPath = Join-Path $PSScriptRoot 'preflight.ps1'
$configPath = Join-Path $projectRoot 'code-linter.json5'

$preflightJson = & $preflightPath -CommandLineRoot $CommandLineRoot -Json
$preflight = $preflightJson | ConvertFrom-Json

if (-not $preflight.CodelinterConfigFound) {
  throw "Code Linter config is missing: $configPath"
}
if (-not $preflight.CodelinterFound) {
  throw @'
Official HarmonyOS codelinter was not found. Install Huawei Command Line Tools, add its bin directory to PATH, then rerun:
  powershell -ExecutionPolicy Bypass -File .\tools\lint.ps1
Official setup: https://developer.huawei.com/consumer/cn/doc/doccenter-deveco-studio/ide-commandline-get
'@
}

Push-Location $projectRoot
try {
  & $preflight.CodelinterPath -c $configPath $projectRoot
  if ($LASTEXITCODE -ne 0) {
    throw "Code Linter failed with exit code $LASTEXITCODE"
  }
  Write-Host 'CODE_LINTER_PASS'
} finally {
  Pop-Location
}
