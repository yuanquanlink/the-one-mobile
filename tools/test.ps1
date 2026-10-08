[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

Push-Location $projectRoot
try {
  Write-Host 'Running HarmonyOS project structure validation...'
  & node .\tools\validate-project.mjs
  if ($LASTEXITCODE -ne 0) { throw "Project validation failed with exit code $LASTEXITCODE" }

  Write-Host 'Running mobile host-side contract tests...'
  & node --test .\tests\mobile-contract.test.mjs
  if ($LASTEXITCODE -ne 0) { throw "Mobile contract tests failed with exit code $LASTEXITCODE" }

  Write-Host 'Running Bridge and phone-mock integration tests...'
  Push-Location .\bridge
  try {
    if (-not (Test-Path -LiteralPath '.\node_modules')) {
      & npm install
      if ($LASTEXITCODE -ne 0) { throw "Bridge dependency install failed with exit code $LASTEXITCODE" }
    }
    & npm test
    if ($LASTEXITCODE -ne 0) { throw "Bridge tests failed with exit code $LASTEXITCODE" }
  } finally {
    Pop-Location
  }
  Write-Host 'THE_ONE_TESTS_PASS'
} finally {
  Pop-Location
}
