[CmdletBinding()]
param(
  [string]$DevEcoRoot = '',
  [string]$CommandLineRoot = '',
  [switch]$Json,
  [switch]$RequireBuildToolchain
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

function Get-CommandPath {
  param([string]$Name)
  $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -eq $command) { return $null }
  return $command.Source
}

function Get-ExistingPath {
  param([string[]]$Candidates)
  foreach ($candidate in $Candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) {
      return (Resolve-Path -LiteralPath $candidate).Path
    }
  }
  return $null
}

function Get-FirstFileUnder {
  param(
    [string[]]$Roots,
    [string[]]$Names
  )
  foreach ($root in $Roots) {
    if (-not $root -or -not (Test-Path -LiteralPath $root -PathType Container)) { continue }
    foreach ($name in $Names) {
      $match = Get-ChildItem -LiteralPath $root -Filter $name -File -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1
      if ($null -ne $match) { return $match.FullName }
    }
  }
  return $null
}

function Get-VersionText {
  param(
    [string]$Executable,
    [string[]]$Arguments = @('--version')
  )
  if (-not $Executable) { return $null }
  try {
    $output = & $Executable @Arguments 2>&1 | Out-String
    return $output.Trim()
  } catch {
    return $null
  }
}

$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
$programFiles = [Environment]::GetFolderPath('ProgramFiles')
$programFilesX86 = [Environment]::GetFolderPath('ProgramFilesX86')
$userProfile = [Environment]::GetFolderPath('UserProfile')

$studioRoots = @()
if ($DevEcoRoot) { $studioRoots += $DevEcoRoot }
if ($env:DEVECO_STUDIO_HOME) { $studioRoots += $env:DEVECO_STUDIO_HOME }
$studioRoots += @(
  (Join-Path $programFiles 'Huawei\DevEco Studio'),
  (Join-Path $programFiles 'Huawei\DevEco Studio Beta'),
  (Join-Path $programFilesX86 'Huawei\DevEco Studio'),
  (Join-Path $localAppData 'Huawei\DevEco Studio'),
  (Join-Path $localAppData 'Programs\Huawei\DevEco Studio'),
  'D:\Program Files\Huawei\DevEco Studio',
  'D:\Program Files\Huawei\DevEco Studio Beta',
  'D:\Huawei\DevEco Studio',
  'D:\DevEco Studio'
)
$studioRoot = Get-ExistingPath $studioRoots

$commandLineRoots = @()
if ($CommandLineRoot) { $commandLineRoots += $CommandLineRoot }
if ($env:HARMONYOS_COMMAND_LINE_TOOLS) { $commandLineRoots += $env:HARMONYOS_COMMAND_LINE_TOOLS }
$commandLineRoots += @(
  'C:\HOS\command-line-tools',
  'C:\HOS',
  (Join-Path $userProfile 'Tools\HarmonyOS\CommandLineTools'),
  (Join-Path $userProfile 'Tools\HarmonyOS\CommandLineTools\command-line-tools'),
  (Join-Path $userProfile 'HarmonyOS\command-line-tools'),
  (Join-Path $userProfile 'Tools\HarmonyOS\command-line-tools'),
  'D:\HarmonyOS\command-line-tools'
)
$commandLineRoot = Get-ExistingPath $commandLineRoots

$sdkRoots = @()
if ($env:DEVECO_SDK_HOME) { $sdkRoots += $env:DEVECO_SDK_HOME }
if ($env:HARMONYOS_SDK_HOME) { $sdkRoots += $env:HARMONYOS_SDK_HOME }
if ($commandLineRoot) { $sdkRoots += (Join-Path $commandLineRoot 'sdk') }
if ($studioRoot) { $sdkRoots += (Join-Path $studioRoot 'sdk') }
$sdkRoots += @(
  (Join-Path $localAppData 'Huawei\Sdk'),
  (Join-Path $userProfile '.harmony\sdk'),
  'D:\Huawei\Sdk',
  'D:\HarmonyOS\Sdk'
)
$sdkRoot = Get-ExistingPath $sdkRoots

$hvigorCandidates = @()
$ohpmCandidates = @()
if ($commandLineRoot) {
  $hvigorCandidates += @(
    (Join-Path $commandLineRoot 'bin\hvigorw.bat'),
    (Join-Path $commandLineRoot 'hvigor\bin\hvigorw.bat')
  )
  $ohpmCandidates += @(
    (Join-Path $commandLineRoot 'bin\ohpm.bat'),
    (Join-Path $commandLineRoot 'ohpm\bin\ohpm.bat')
  )
}
if ($studioRoot) {
  $hvigorCandidates += @(
    (Join-Path $studioRoot 'tools\hvigor\bin\hvigorw.bat'),
    (Join-Path $studioRoot 'tools\hvigor\bin\hvigorw.cmd')
  )
  $ohpmCandidates += @(
    (Join-Path $studioRoot 'tools\ohpm\bin\ohpm.bat'),
    (Join-Path $studioRoot 'tools\ohpm\bin\ohpm.cmd')
  )
}
$hvigorCandidates += @(
  (Get-CommandPath 'hvigorw.bat'),
  (Get-CommandPath 'hvigorw.cmd'),
  (Get-CommandPath 'hvigorw')
)
$ohpmCandidates += @(
  (Get-CommandPath 'ohpm.bat'),
  (Get-CommandPath 'ohpm.cmd'),
  (Get-CommandPath 'ohpm')
)

$hvigorPath = Get-ExistingPath $hvigorCandidates
$ohpmPath = Get-ExistingPath $ohpmCandidates
if (-not $hvigorPath -and $commandLineRoot) {
  $hvigorPath = Get-FirstFileUnder -Roots @($commandLineRoot) -Names @('hvigorw.bat', 'hvigorw.cmd')
}
if (-not $ohpmPath -and $commandLineRoot) {
  $ohpmPath = Get-FirstFileUnder -Roots @($commandLineRoot) -Names @('ohpm.bat', 'ohpm.cmd')
}
$hdcPath = Get-CommandPath 'hdc.exe'
if (-not $hdcPath -and $sdkRoot) {
  $hdcPath = Get-ExistingPath @(
    (Join-Path $sdkRoot 'default\openharmony\toolchains\hdc.exe'),
    (Join-Path $sdkRoot 'toolchains\hdc.exe')
  )
  if (-not $hdcPath) {
    $hdcPath = Get-FirstFileUnder -Roots @($sdkRoot) -Names @('hdc.exe', 'hdc_std.exe')
  }
}

$api26Found = $false
$api26Evidence = $null
if ($sdkRoot) {
  $versionFiles = Get-ChildItem -LiteralPath $sdkRoot -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -in @('sdk-pkg.json', 'oh-uni-package.json', 'component.json') }
  foreach ($file in $versionFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($content -match '(?i)(apiVersion|version|releaseType)[^\r\n]{0,80}(26|26\.0\.0)' -or
        $file.DirectoryName -match '(^|[\\/])26(\.0\.0)?([\\/]|$)') {
      $api26Found = $true
      $api26Evidence = $file.FullName
      break
    }
  }
}

$projectTargetsApi26 = $false
$profilePath = Join-Path $projectRoot 'build-profile.json5'
if (Test-Path -LiteralPath $profilePath) {
  $profileText = Get-Content -LiteralPath $profilePath -Raw -Encoding UTF8
  $projectTargetsApi26 = $profileText.Contains('"compileSdkVersion": "26.0.0"') -and
    $profileText.Contains('"targetSdkVersion": "26.0.0"') -and
    $profileText.Contains('"compatibleSdkVersion": "26.0.0"')
}

$connectedDeviceCount = 0
$deviceProbe = 'HDC_NOT_AVAILABLE'
if ($hdcPath) {
  try {
    $targetLines = & $hdcPath list targets 2>&1 |
      ForEach-Object { $_.ToString().Trim() } |
      Where-Object { $_ -and $_ -notmatch '(?i)empty|list of devices|daemon' }
    $connectedDeviceCount = @($targetLines).Count
    $deviceProbe = if ($connectedDeviceCount -gt 0) { 'CONNECTED' } else { 'NO_TARGETS' }
  } catch {
    $deviceProbe = 'HDC_PROBE_FAILED'
  }
}

$nodePath = Get-CommandPath 'node.exe'
$javaPath = Get-CommandPath 'java.exe'
$devecoCliPath = Get-CommandPath 'devecocli.cmd'
if (-not $devecoCliPath) { $devecoCliPath = Get-CommandPath 'devecocli' }
$codelinterPath = Get-CommandPath 'codelinter.exe'
if (-not $codelinterPath -and $commandLineRoot) {
  $codelinterPath = Get-ExistingPath @(
    (Join-Path $commandLineRoot 'bin\codelinter.bat'),
    (Join-Path $commandLineRoot 'codelinter\bin\codelinter.bat')
  )
  if (-not $codelinterPath) {
    $codelinterPath = Get-FirstFileUnder -Roots @($commandLineRoot) -Names @('codelinter.exe', 'codelinter.bat', 'codelinter.cmd')
  }
}
$hstackPath = Get-CommandPath 'hstack.exe'
if (-not $hstackPath -and $commandLineRoot) {
  $hstackPath = Get-ExistingPath @(
    (Join-Path $commandLineRoot 'bin\hstack.bat'),
    (Join-Path $commandLineRoot 'hstack\bin\hstack.bat')
  )
  if (-not $hstackPath) {
    $hstackPath = Get-FirstFileUnder -Roots @($commandLineRoot) -Names @('hstack.exe', 'hstack.bat', 'hstack.cmd')
  }
}
$npmPath = Get-CommandPath 'npm.cmd'
if (-not $npmPath) { $npmPath = Get-CommandPath 'npm' }
$gitPath = Get-CommandPath 'git.exe'

$result = [ordered]@{
  ProjectRoot = $projectRoot
  ProjectTargetsApi26 = $projectTargetsApi26
  DevEcoStudioRoot = $studioRoot
  DevEcoStudioFound = [bool]$studioRoot
  CommandLineToolsRoot = $commandLineRoot
  CommandLineToolsFound = [bool]$commandLineRoot
  SdkRoot = $sdkRoot
  Api26SdkFound = $api26Found
  Api26Evidence = $api26Evidence
  OhpmPath = $ohpmPath
  OhpmFound = [bool]$ohpmPath
  OhpmVersion = Get-VersionText $ohpmPath @('-v')
  HvigorPath = $hvigorPath
  HvigorFound = [bool]$hvigorPath
  HvigorVersion = Get-VersionText $hvigorPath @('--version')
  HdcPath = $hdcPath
  HdcFound = [bool]$hdcPath
  HdcVersion = Get-VersionText $hdcPath @('-v')
  DeviceProbe = $deviceProbe
  ConnectedDeviceCount = $connectedDeviceCount
  NodePath = $nodePath
  NodeVersion = Get-VersionText $nodePath @('--version')
  JavaPath = $javaPath
  JavaVersion = Get-VersionText $javaPath @('--version')
  DevEcoCliPath = $devecoCliPath
  DevEcoCliVersion = Get-VersionText $devecoCliPath @('--version')
  CodelinterPath = $codelinterPath
  CodelinterFound = [bool]$codelinterPath
  CodelinterVersion = Get-VersionText $codelinterPath @('-v')
  CodelinterConfigPath = (Join-Path $projectRoot 'code-linter.json5')
  CodelinterConfigFound = Test-Path -LiteralPath (Join-Path $projectRoot 'code-linter.json5')
  HstackPath = $hstackPath
  HstackFound = [bool]$hstackPath
  NpmPath = $npmPath
  NpmVersion = Get-VersionText $npmPath @('--version')
  GitPath = $gitPath
  GitVersion = Get-VersionText $gitPath @('--version')
  BuildToolchainReady = [bool]($sdkRoot -and $api26Found -and $ohpmPath -and $hvigorPath)
}

if ($Json) {
  $result | ConvertTo-Json -Depth 4
} else {
  Write-Host 'THE_ONE_MOBILE_PREFLIGHT'
  if ($result.ProjectTargetsApi26) { Write-Host '[OK] Project profile targets HarmonyOS API 26.' } else { Write-Host '[FAIL] Project profile does not consistently target API 26.' }
  if ($result.DevEcoStudioFound) { Write-Host "[OK] DevEco Studio: $($result.DevEcoStudioRoot)" } else { Write-Host '[BLOCKED] DevEco Studio was not found.' }
  if ($result.CommandLineToolsFound) { Write-Host "[OK] Command Line Tools: $($result.CommandLineToolsRoot)" } else { Write-Host '[BLOCKED] Official Command Line Tools were not found.' }
  if ($result.Api26SdkFound) { Write-Host "[OK] API 26 SDK: $($result.SdkRoot)" } else { Write-Host '[BLOCKED] HarmonyOS API 26 SDK was not found.' }
  if ($result.OhpmFound) { Write-Host "[OK] OHPM: $($result.OhpmPath) ($($result.OhpmVersion -replace '[\r\n]+', ' '))" } else { Write-Host '[BLOCKED] OHPM was not found.' }
  if ($result.HvigorFound) { Write-Host "[OK] Hvigor wrapper: $($result.HvigorPath) ($($result.HvigorVersion -replace '[\r\n]+', ' '))" } else { Write-Host '[BLOCKED] Hvigor wrapper was not found.' }
  if ($result.HdcFound) { Write-Host "[OK] HDC: $($result.HdcVersion -replace '[\r\n]+', ' '); connected target count: $connectedDeviceCount" } else { Write-Host '[BLOCKED] HDC was not found; device connectivity cannot be tested.' }
  if ($result.NodePath) { Write-Host "[OK] Node: $($result.NodeVersion)" } else { Write-Host '[WARN] Node was not found.' }
  if ($result.JavaPath) { Write-Host "[OK] Java: $($result.JavaVersion -replace '[\r\n]+', ' ')" } else { Write-Host '[WARN] Java was not found.' }
  if ($result.DevEcoCliPath) { Write-Host "[OK] Official DevEco CLI: $($result.DevEcoCliVersion)" } else { Write-Host '[INFO] Official DevEco CLI is not installed.' }
  if ($result.CodelinterFound) { Write-Host "[OK] codelinter: $($result.CodelinterPath) ($($result.CodelinterVersion -replace '[\r\n]+', ' '))" } else { Write-Host '[BLOCKED] codelinter was not found.' }
  if ($result.CodelinterConfigFound) { Write-Host "[OK] Code Linter config: $($result.CodelinterConfigPath)" } else { Write-Host '[FAIL] code-linter.json5 was not found.' }
  if ($result.HstackFound) { Write-Host "[OK] hstack: $($result.HstackPath)" } else { Write-Host '[BLOCKED] hstack was not found.' }
  if ($result.NpmPath) { Write-Host "[OK] npm: $($result.NpmVersion)" } else { Write-Host '[WARN] npm was not found.' }
  if ($result.GitPath) { Write-Host "[OK] Git: $($result.GitVersion)" } else { Write-Host '[WARN] Git was not found.' }
  if ($result.BuildToolchainReady) { Write-Host 'PREFLIGHT_READY' } else { Write-Host 'PREFLIGHT_BLOCKED' }
}

if ($RequireBuildToolchain -and -not $result.BuildToolchainReady) {
  exit 2
}
