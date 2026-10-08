[CmdletBinding()]
param(
  [string]$BaseUrl = 'http://127.0.0.1:4317',
  [string]$Token = ''
)

$ErrorActionPreference = 'Stop'
$headers = @{}
if ($Token) { $headers['x-the-one-token'] = $Token }

try {
  $health = Invoke-RestMethod -Uri "$($BaseUrl.TrimEnd('/'))/health" -Method Get -Headers $headers -TimeoutSec 6
} catch {
  throw "Bridge health check failed: $($_.Exception.Message)"
}

if (-not $health.ok -or $health.protocolVersion -ne '1.0.0') {
  throw 'Bridge responded, but its health/protocol contract is incompatible.'
}

Write-Host "BRIDGE_HEALTH_PASS $($health.service) protocol=$($health.protocolVersion)"
