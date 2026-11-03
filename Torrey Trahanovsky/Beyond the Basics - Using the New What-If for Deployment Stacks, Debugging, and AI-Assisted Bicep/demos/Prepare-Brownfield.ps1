<#
    Builds the "brownfield" resource group for the AI demo: a few resources made by hand,
    with no template and no deployment stack. Copilot brings these under a stack in the demo.
    Safe to run any number of times. Prepare-Stage.ps1 runs it for you.

        .\Prepare-Brownfield.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$cfg = Get-Content (Join-Path $PSScriptRoot 'demo.config.json') -Raw | ConvertFrom-Json
$rgName = $cfg.brownfieldResourceGroup
$stackName = $cfg.brownfieldStackName
if (-not $rgName -or -not $stackName) { throw 'demo.config.json needs brownfieldResourceGroup and brownfieldStackName.' }

function Say([string]$Text, [string]$Color = 'Gray') { Write-Host $Text -ForegroundColor $Color }

Import-Module Az.Resources -WarningAction SilentlyContinue
$pick = @{ Subscription = $cfg.subscriptionId }
if ($cfg.tenantId -match '^[0-9a-f]{8}-' -and $cfg.tenantId -notmatch '^0{8}-') { $pick.Tenant = $cfg.tenantId }
$null = Set-AzContext @pick -WarningAction SilentlyContinue
$tags = @{ purpose = 'demo'; event = 'NIC 2026' }

function Test-Resource([string]$Type, [string]$Like) {
    # A slow or failed lookup must not look like "missing", or this would try to create it again.
    for ($i = 1; $i -le 3; $i++) {
        try { return [bool](Get-AzResource -ResourceGroupName $rgName -ResourceType $Type -ErrorAction Stop | Where-Object Name -like $Like) }
        catch {
            if ($i -eq 3) { throw "Could not check $Type in $rgName ($(($_.Exception.Message -split "`r?`n")[0])). Run this again." }
            Start-Sleep -Seconds 5
        }
    }
}
function Use-Module([string]$Name) {
    if (-not (Get-Module $Name -ListAvailable)) { throw "$Name is needed to create the brownfield resources. Install-Module $Name -Scope CurrentUser, then run this again." }
    Import-Module $Name -WarningAction SilentlyContinue
}

# 1. Resource group. A slow or failed lookup must not look like "missing".
$rg = $null
for ($i = 1; $i -le 3; $i++) {
    try { $rg = Get-AzResourceGroup -Name $rgName -ErrorAction Stop; break }
    catch {
        if ($_.Exception.Message -match 'does not exist|ResourceGroupNotFound') { break }
        if ($i -eq 3) { throw "Could not check resource group $rgName ($(($_.Exception.Message -split "`r?`n")[0])). Run this again." }
        Start-Sleep -Seconds 5
    }
}
if (-not $rg) {
    $rgTags = @{ purpose = 'demo'; owner = $env:USERNAME; autoDelete = 'true'; event = 'NIC 2026'; created = (Get-Date).ToUniversalTime().ToString('s') + 'Z' }
    $rg = New-AzResourceGroup -Name $rgName -Location $cfg.location -Tag $rgTags
    Say "  OK   created $rgName in $($cfg.location)" Green
}
else { Say "  OK   $rgName ($($rg.Location))" Green }

# 2. If a rehearsal really created the stack, remove it and keep the resources, so they're unmanaged again.
$stack = Get-AzResourceGroupDeploymentStack -ResourceGroupName $rgName -Name $stackName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
if ($stack) {
    Remove-AzResourceGroupDeploymentStack -ResourceGroupName $rgName -Name $stackName -ActionOnUnmanage DetachAll -Force -WarningAction SilentlyContinue | Out-Null
    Say "  OK   removed '$stackName' and kept its resources" Green
}

# 3. The hand-made resources. Only creates what's missing.
if (-not (Test-Resource 'Microsoft.Network/networkSecurityGroups' 'nsg-legacy')) {
    Use-Module Az.Network
    $rule = New-AzNetworkSecurityRuleConfig -Name 'allow-https' -Priority 100 -Direction Inbound -Access Allow -Protocol Tcp `
        -SourceAddressPrefix '*' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '443'
    $null = New-AzNetworkSecurityGroup -ResourceGroupName $rgName -Location $cfg.location -Name 'nsg-legacy' -SecurityRules $rule -Tag $tags -Force
    Say '  OK   created nsg-legacy' Green
}

if (-not (Test-Resource 'Microsoft.Network/virtualNetworks' 'vnet-legacy')) {
    Use-Module Az.Network
    $subnet = New-AzVirtualNetworkSubnetConfig -Name 'snet-web' -AddressPrefix '10.60.1.0/24' -DefaultOutboundAccess $false
    $null = New-AzVirtualNetwork -ResourceGroupName $rgName -Location $cfg.location -Name 'vnet-legacy' -AddressPrefix '10.60.0.0/16' -Subnet $subnet -Tag $tags -Force
    Say '  OK   created vnet-legacy' Green
}

if (-not (Test-Resource 'Microsoft.Storage/storageAccounts' 'stlegacy*')) {
    Use-Module Az.Storage
    $sha = [Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($rg.ResourceId.ToLowerInvariant()))
    $suffix = -join ($sha[0..9] | ForEach-Object { 'abcdefghijklmnopqrstuvwxyz234567'[$_ % 32] })
    $name = "stlegacy$suffix"
    $null = New-AzStorageAccount -ResourceGroupName $rgName -Location $cfg.location -Name $name -SkuName Standard_LRS -Kind StorageV2 `
        -MinimumTlsVersion TLS1_2 -AllowBlobPublicAccess $false -AllowSharedKeyAccess $false -Tag $tags -WarningAction SilentlyContinue
    Say "  OK   created $name" Green
}

# 4. Old What-If results in this resource group.
$old = @(Get-AzResourceGroupDeploymentStackWhatIfResult -ResourceGroupName $rgName -ErrorAction SilentlyContinue)
foreach ($w in $old) { Remove-AzResourceGroupDeploymentStackWhatIfResult -ResourceGroupName $rgName -Name $w.Name -Force -Confirm:$false -ErrorAction SilentlyContinue | Out-Null }
if ($old.Count) { Say "  OK   cleared $($old.Count) old What-If results in $rgName" Green }

$names = (Get-AzResource -ResourceGroupName $rgName | Sort-Object Name).Name -join ', '
Say "  OK   $rgName has: $names (no stack)" Green
