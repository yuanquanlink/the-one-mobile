[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Merge-NoProxy {
  param([string]$Existing)

  $required = @('localhost', '127.0.0.1', '::1', '[::1]')
  $items = @()
  if ($Existing) {
    $items += $Existing -split '[,;\s]+' | Where-Object { $_ }
  }
  foreach ($item in $required) {
    if ($items -notcontains $item) { $items += $item }
  }
  return ($items -join ',')
}

# Scope this change to the child login process. The DevEco CLI callback is still
# being intercepted despite NO_PROXY, so force this login process to use a direct
# connection. Do not alter user, machine, npm, Git, WinHTTP, TLS, certificate,
# firewall, or security settings.
$bypass = Merge-NoProxy $env:NO_PROXY
$env:NO_PROXY = $bypass
$env:no_proxy = $bypass
foreach ($name in @('HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'http_proxy', 'https_proxy', 'all_proxy')) {
  Remove-Item "Env:$name" -ErrorAction SilentlyContinue
}

Write-Host 'Scoped DevEco login direct connection ready; system proxy settings remain unchanged.'
& devecocli auth login
exit $LASTEXITCODE
