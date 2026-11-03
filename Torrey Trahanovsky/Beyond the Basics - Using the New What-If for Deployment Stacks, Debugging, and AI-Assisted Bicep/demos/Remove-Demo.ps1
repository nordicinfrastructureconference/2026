<#
    After NIC: deletes the demo stack, everything it manages, and the demo resource group.
    Asks you to type the resource group name before deleting anything.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$cfg = Get-Content (Join-Path $PSScriptRoot 'demo.config.json') -Raw | ConvertFrom-Json
Import-Module Az.Resources -MinimumVersion 10.2.1 -WarningAction SilentlyContinue
$pick = @{ Subscription = $cfg.subscriptionId }
if ($cfg.tenantId -match '^[0-9a-f]{8}-' -and $cfg.tenantId -notmatch '^0{8}-') { $pick.Tenant = $cfg.tenantId }
$ctx = Set-AzContext @pick -WarningAction SilentlyContinue

Write-Host ''
Write-Host "Subscription:   $($ctx.Subscription.Name)" -ForegroundColor Gray
Write-Host "This deletes stack '$($cfg.stackName)', everything it manages, and resource group '$($cfg.resourceGroup)'." -ForegroundColor Yellow
$typed = Read-Host 'Type the resource group name to confirm'
if ($typed -ne $cfg.resourceGroup) { Write-Host 'Name did not match. Nothing was deleted.' -ForegroundColor Gray; return }

$s = Get-AzResourceGroupDeploymentStack -ResourceGroupName $cfg.resourceGroup -Name $cfg.stackName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
if ($s) {
    Remove-AzResourceGroupDeploymentStack -ResourceGroupName $cfg.resourceGroup -Name $cfg.stackName -ActionOnUnmanage DeleteAll -Force -WarningAction SilentlyContinue | Out-Null
    Write-Host '  stack and managed resources deleted' -ForegroundColor Green
}
Remove-AzResourceGroup -Name $cfg.resourceGroup -Force | Out-Null
Write-Host "  resource group $($cfg.resourceGroup) deleted" -ForegroundColor Green
