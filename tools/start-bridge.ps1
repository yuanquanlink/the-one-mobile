[CmdletBinding()]
param(
  [string]$HostAddress = '127.0.0.1',
  [ValidateRange(1, 65535)]
  [int]$Port = 4317,
  [string]$Token = ''
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$bridgeRoot = Join-Path $projectRoot 'bridge'
$loopback = $HostAddress -in @('127.0.0.1', 'localhost', '::1')

if (-not $loopback -and $Token.Length -lt 24) {
  throw 'LAN listening requires -Token with at least 24 characters. The token is session-only and is not written to Git.'
}

$env:THE_ONE_BRIDGE_HOST = $HostAddress
$env:THE_ONE_BRIDGE_PORT = $Port.ToString()
if ($Token) { $env:THE_ONE_BRIDGE_TOKEN = $Token }

Push-Location $bridgeRoot
try {
  if (-not (Test-Path -LiteralPath '.\node_modules')) {
    & npm install
    if ($LASTEXITCODE -ne 0) { throw "npm install failed with exit code $LASTEXITCODE" }
  }
  & npm run build
  if ($LASTEXITCODE -ne 0) { throw "Bridge build failed with exit code $LASTEXITCODE" }
  & npm start
  if ($LASTEXITCODE -ne 0) { throw "Bridge exited with code $LASTEXITCODE" }
} finally {
  Pop-Location
}
