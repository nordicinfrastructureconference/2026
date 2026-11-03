<#
    Puts Azure at the V4 demo's starting point. Run it the day before, again the morning of the
    session, and after every practice run. Safe to run any number of times.

        .\Prepare-Stage.ps1           # check and fix the starting point
        .\Prepare-Stage.ps1 -Check    # only check, change nothing (exit code 0 means ready)

    Starting point: rg-demo-nic2026-stacks has vnet-app, nsg-app (HTTPS rule only) and the storage
    account (Standard_LRS) from a regular deployment of app.v1.bicep. No deployment stack, so no
    deny assignments, and no old What-If results. The demo deploys the stack live.
    For the AI demo: rg-demo-nic2026-brownfield with three hand-made resources and no stack.
#>
[CmdletBinding()]
param([string]$SubscriptionId, [switch]$Check)

$ErrorActionPreference = 'Stop'
$cfgFile = Join-Path $PSScriptRoot 'demo.config.json'
$cfg = Get-Content $cfgFile -Raw | ConvertFrom-Json
$v1 = Join-Path $PSScriptRoot 'stacks-whatif-demo\app.v1.bicep'

function Say([string]$Text, [string]$Color = 'Gray') { Write-Host $Text -ForegroundColor $Color }

Say ''
Say $(if ($Check) { 'Checking the Stacks What-If demo' } else { 'Preparing the Stacks What-If demo' }) Cyan
Import-Module Az.Resources -MinimumVersion 10.2.1 -WarningAction SilentlyContinue

# 1. Sign in and pick the subscription. A saved sign-in can be for another account or tenant, or expired,
#    so if it can't reach the subscription, sign in again for the subscription's own tenant.
if ($SubscriptionId) { $cfg.subscriptionId = $SubscriptionId }
$pick = @{ Subscription = $cfg.subscriptionId }
if ($cfg.tenantId -match '^[0-9a-f]{8}-' -and $cfg.tenantId -notmatch '^0{8}-') { $pick.Tenant = $cfg.tenantId }
function Select-DemoSubscription {
    try { Set-AzContext @pick -WarningAction SilentlyContinue -ErrorAction Stop }
    catch { $script:pickError = ($_.Exception.Message -split "`r?`n")[0]; $null }
}
$ctx = $null
if (Get-AzContext -WarningAction SilentlyContinue -ErrorAction SilentlyContinue) { $ctx = Select-DemoSubscription }
if (-not $ctx) {
    if ($Check) { Say "  MISS Azure PowerShell isn't signed in to an account that can reach the demo subscription. Run SETUP-LAPTOP.cmd." Red; exit 1 }
    Say '  Signing in to Azure (a sign-in window opens)...' Yellow
    Connect-AzAccount @pick -WarningAction SilentlyContinue | Out-Null
    $ctx = Select-DemoSubscription
    if (-not $ctx) { throw "Signed in, but subscription $($cfg.subscriptionId) still isn't reachable ($script:pickError). Check the subscription ID in demo.config.json, and that this account has access to it." }
}
if ($ctx.Subscription.Name -match 'prod|production|shared|corp') {
    throw "Subscription '$($ctx.Subscription.Name)' looks like production. Use a disposable test subscription."
}
if (-not $Check) {
    $cfg.subscriptionName = $ctx.Subscription.Name
    # The subscription's own tenant, for the portal links. The tenant you signed in to can be a different one.
    $tenantId = if ($ctx.Subscription.HomeTenantId) { $ctx.Subscription.HomeTenantId } else { $ctx.Tenant.Id }
    $cfg | Add-Member -NotePropertyName tenantId -NotePropertyValue $tenantId -Force
    $cfg | ConvertTo-Json | Set-Content $cfgFile -Encoding utf8
}
Say "  OK   $($ctx.Account.Id) | $($ctx.Subscription.Name)" Green

# 2. Resource group. A slow or failed lookup must not look like "missing".
function Get-RgOrNull([string]$Name) {
    for ($i = 1; $i -le 3; $i++) {
        try { return Get-AzResourceGroup -Name $Name -ErrorAction Stop }
        catch {
            if ($_.Exception.Message -match 'does not exist|ResourceGroupNotFound') { return $null }
            if ($i -eq 3) { throw "Could not check resource group $Name ($(($_.Exception.Message -split "`r?`n")[0])). Run this again." }
            Start-Sleep -Seconds 5
        }
    }
}
$rg = Get-RgOrNull $cfg.resourceGroup
if (-not $rg) {
    if ($Check) { Say "  MISS resource group $($cfg.resourceGroup)" Red; exit 1 }
    $tags = @{ purpose = 'demo'; owner = $env:USERNAME; autoDelete = 'true'; event = 'NIC 2026'; created = (Get-Date).ToUniversalTime().ToString('s') + 'Z' }
    $null = New-AzResourceGroup -Name $cfg.resourceGroup -Location $cfg.location -Tag $tags
    Say "  OK   created $($cfg.resourceGroup) in $($cfg.location)" Green
}
else { Say "  OK   $($cfg.resourceGroup) ($($rg.Location))" Green }

# 3. What the starting point looks like.
function Get-StageState {
    $stack = Get-AzResourceGroupDeploymentStack -ResourceGroupName $cfg.resourceGroup -Name $cfg.stackName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $vnet = Get-AzResource -ResourceGroupName $cfg.resourceGroup -Name 'vnet-app' -ResourceType 'Microsoft.Network/virtualNetworks' -ErrorAction SilentlyContinue
    $nsg = Get-AzResource -ResourceGroupName $cfg.resourceGroup -Name 'nsg-app' -ResourceType 'Microsoft.Network/networkSecurityGroups' -ExpandProperties -ErrorAction SilentlyContinue
    $st = @(Get-AzResource -ResourceGroupName $cfg.resourceGroup -ResourceType 'Microsoft.Storage/storageAccounts' -ExpandProperties -ErrorAction SilentlyContinue | Where-Object Name -like 'stapp*')
    $rules = @($nsg.Properties.securityRules | ForEach-Object { $_.name })
    $whatIfs = @(Get-AzResourceGroupDeploymentStackWhatIfResult -ResourceGroupName $cfg.resourceGroup -ErrorAction SilentlyContinue)
    $extra = @(Get-AzResource -ResourceGroupName $cfg.resourceGroup -ErrorAction SilentlyContinue | Where-Object { $_.ResourceType -notin 'Microsoft.Network/virtualNetworks', 'Microsoft.Network/networkSecurityGroups', 'Microsoft.Storage/storageAccounts', 'Microsoft.Resources/deploymentStacksWhatIfResults' })
    [pscustomobject]@{
        NoStack  = -not $stack
        Vnet     = [bool]$vnet
        NsgV1    = [bool]$nsg -and $rules.Count -eq 1 -and $rules[0] -eq 'allow-https'
        Storage  = $st.Count -eq 1 -and $st[0].Sku.Name -eq 'Standard_LRS'
        WhatIfs  = $whatIfs.Count
        Extra    = @($extra | ForEach-Object Name)
        Stack    = $stack
    }
}
Say "  ..   checking what's in $($cfg.resourceGroup) (about 30 seconds)" DarkGray
$s = Get-StageState
$ready = $s.NoStack -and $s.Vnet -and $s.NsgV1 -and $s.Storage -and $s.WhatIfs -eq 0 -and $s.Extra.Count -eq 0

if ($Check) {
    Say ("  {0} no stack '{1}' yet" -f $(if ($s.NoStack) { 'OK  ' } else { 'MISS' }), $cfg.stackName) $(if ($s.NoStack) { 'Green' } else { 'Red' })
    Say ("  {0} vnet-app, nsg-app (HTTPS rule only), storage account on Standard_LRS" -f $(if ($s.Vnet -and $s.NsgV1 -and $s.Storage) { 'OK  ' } else { 'MISS' })) $(if ($s.Vnet -and $s.NsgV1 -and $s.Storage) { 'Green' } else { 'Red' })
    Say ("  {0} no old What-If results" -f $(if ($s.WhatIfs -eq 0) { 'OK  ' } else { 'MISS' })) $(if ($s.WhatIfs -eq 0) { 'Green' } else { 'Red' })
    if ($s.Extra.Count) { Say "  MISS other resources in the group: $($s.Extra -join ', ')" Red }
    Say $(if ($ready) { 'Ready.' } else { 'Not ready. Run Prepare-Stage.ps1 (or SETUP-LAPTOP.cmd).' }) $(if ($ready) { 'Green' } else { 'Yellow' })
    exit $(if ($ready) { 0 } else { 1 })
}

if ($ready) { Say '  OK   already at the starting point' Green }
else {
    # 4. A practice run leaves a stack behind. Remove it but keep the resources (detach), which also
    #    removes its deny assignment.
    if (-not $s.NoStack) {
        Say "  ..   removing stack '$($cfg.stackName)' and keeping its resources (about a minute)" DarkGray
        Remove-AzResourceGroupDeploymentStack -ResourceGroupName $cfg.resourceGroup -Name $cfg.stackName -ActionOnUnmanage DetachAll -Force -WarningAction SilentlyContinue | Out-Null
        Say "  OK   stack '$($cfg.stackName)' removed, resources kept" Green
    }
    # 5. Leftovers from older rehearsals (V2 added a route table).
    foreach ($name in $s.Extra) {
        $r = Get-AzResource -ResourceGroupName $cfg.resourceGroup -Name $name -ErrorAction SilentlyContinue
        if ($r) { Remove-AzResource -ResourceId $r.ResourceId -Force | Out-Null; Say "  OK   removed leftover $name" Green }
    }
    # 6. A regular deployment of app.v1.bicep puts back the virtual network, the HTTPS-only rule and
    #    Standard_LRS storage.
    #    The demo doesn't change the SKU any more, but an older practice run did. Then Azure won't change
    #    it back until it's done copying the storage account to its geo-redundant region, so this can
    #    take a while.
    Say '  ..   deploying app.v1.bicep with a regular deployment (about a minute)' DarkGray
    $dep = New-AzResourceGroupDeployment -Name 'app-v1' -ResourceGroupName $cfg.resourceGroup -TemplateFile $v1 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -ErrorVariable depErr
    if ($dep.ProvisioningState -eq 'Succeeded') { Say '  OK   app.v1.bicep deployed, no stack' Green }
    else { Say "  WARN app.v1.bicep didn't finish: $(($depErr | Select-Object -First 1).Exception.Message)" Yellow }
    # 7. Old What-If results.
    $old = @(Get-AzResourceGroupDeploymentStackWhatIfResult -ResourceGroupName $cfg.resourceGroup -ErrorAction SilentlyContinue)
    foreach ($w in $old) { Remove-AzResourceGroupDeploymentStackWhatIfResult -ResourceGroupName $cfg.resourceGroup -Name $w.Name -Force -Confirm:$false -ErrorAction SilentlyContinue | Out-Null }
    if ($old.Count) { Say "  OK   cleared $($old.Count) old What-If results" Green }
}

# 8. The brownfield resource group for the AI demo (hand-made resources, no stack).
& (Join-Path $PSScriptRoot 'Prepare-Brownfield.ps1')

$s = Get-StageState
$ready = $s.NoStack -and $s.Vnet -and $s.NsgV1 -and $s.Storage -and $s.WhatIfs -eq 0 -and $s.Extra.Count -eq 0
Say ''
if ($ready) { Say 'Ready for the stage.' Green } else { Say 'Not at the starting point yet. Run this again.' Yellow; exit 1 }
