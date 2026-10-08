[CmdletBinding()]
param(
  [ValidateSet('debug', 'release')]
  [string]$BuildMode = 'debug',
  [string]$DevEcoRoot = '',
  [string]$CommandLineRoot = '',
  [switch]$SkipDependencyRestore
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$preflightPath = Join-Path $PSScriptRoot 'preflight.ps1'
$validatorPath = Join-Path $PSScriptRoot 'validate-project.mjs'

if (-not (Test-Path -LiteralPath $preflightPath)) {
  throw "Preflight script is missing: $preflightPath"
}

$preflightJson = & $preflightPath -DevEcoRoot $DevEcoRoot -CommandLineRoot $CommandLineRoot -Json
$preflight = $preflightJson | ConvertFrom-Json

function Use-BundledHvigorPluginFallback {
  param($Preflight, [string]$ProjectRoot)

  if (-not $Preflight.CommandLineToolsRoot) { return $false }
  $bundledPlugin = Join-Path $Preflight.CommandLineToolsRoot 'hvigor\hvigor-ohos-plugin'
  if (-not (Test-Path -LiteralPath (Join-Path $bundledPlugin 'package.json') -PathType Leaf)) { return $false }

  $pluginGroup = Join-Path $ProjectRoot 'oh_modules\@ohos'
  $pluginLink = Join-Path $pluginGroup 'hvigor-ohos-plugin'
  if (-not (Test-Path -LiteralPath $pluginLink)) {
    New-Item -ItemType Directory -Path $pluginGroup -Force | Out-Null
    New-Item -ItemType Junction -Path $pluginLink -Target $bundledPlugin | Out-Null
  }
  return (Test-Path -LiteralPath (Join-Path $pluginLink 'package.json') -PathType Leaf)
}

Write-Host 'Running project structure validation...'
& node $validatorPath
if ($LASTEXITCODE -ne 0) {
  throw "Project validation failed with exit code $LASTEXITCODE"
}

if (-not $preflight.BuildToolchainReady) {
  & $preflightPath -DevEcoRoot $DevEcoRoot -CommandLineRoot $CommandLineRoot
  throw @'
HarmonyOS API 26 build toolchain is incomplete. Install the current official Huawei Command Line Tools (SDK is embedded) or DevEco Studio, then rerun:
  powershell -ExecutionPolicy Bypass -File .\tools\preflight.ps1
  powershell -ExecutionPolicy Bypass -File .\tools\build.ps1
Official command-line page: https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos
'@
}

$hvigorWrapper = $preflight.HvigorPath
$ohpmPath = $preflight.OhpmPath
$sdkPath = $preflight.SdkRoot
$env:DEVECO_SDK_HOME = $sdkPath
$env:HARMONYOS_SDK_HOME = $sdkPath

Push-Location $projectRoot
try {
  if (-not $SkipDependencyRestore) {
    Write-Host 'Restoring OHPM dependencies...'
    & $ohpmPath install
    if ($LASTEXITCODE -ne 0) {
      if (Use-BundledHvigorPluginFallback -Preflight $preflight -ProjectRoot $projectRoot) {
        Write-Warning 'OHPM registry restore failed; using the matching Hvigor plugin bundled with the verified official Command Line Tools for this build.'
      } else {
        throw "OHPM dependency restore failed with exit code $LASTEXITCODE"
      }
    }
  }

  Write-Host "Building entry HAP ($BuildMode)..."
  & $hvigorWrapper --no-daemon --mode module -p product=default -p buildMode=$BuildMode assembleHap
  if ($LASTEXITCODE -ne 0) {
    throw "Hvigor build failed with exit code $LASTEXITCODE"
  }

  $hapFiles = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'entry\build') -Filter '*.hap' -File -Recurse -ErrorAction SilentlyContinue
  if (@($hapFiles).Count -eq 0) {
    throw 'Hvigor returned success, but no HAP artifact was found under entry\build.'
  }
  Write-Host 'HAP_BUILD_OK'
  $hapFiles | ForEach-Object { Write-Host $_.FullName }
} finally {
  Pop-Location
}
