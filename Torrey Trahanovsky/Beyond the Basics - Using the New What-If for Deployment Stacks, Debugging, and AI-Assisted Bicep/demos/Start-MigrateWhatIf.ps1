<#
.SYNOPSIS
    AI demo: Stacks What-If for moving the hand-built resources in the brownfield resource group
    into a new stack. The stack doesn't exist yet. This only creates a What-If result, so nothing
    gets deployed.
.EXAMPLE
    .\whatif.ps1               # from the AI demo folder, uses brownfield\main.bicep (what Copilot wrote)
    .\whatif.ps1 -Fallback     # uses the version made ahead of time
    .\whatif.ps1 -Replay       # saved result, no network
#>
param([string]$TemplateFile = 'brownfield\main.bicep', [switch]$Fallback, [switch]$Replay)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$cfg = Get-Content (Join-Path $root 'demo.config.json') -Raw | ConvertFrom-Json
$rg = $cfg.brownfieldResourceGroup
$stackName = $cfg.brownfieldStackName
$replayFile = Join-Path $root '_replay\migrate-whatif.txt'
$fallbackFile = Join-Path $root 'ai-fallback\brownfield\main.bicep'
$esc = [char]27
if (Get-Variable PSStyle -ErrorAction SilentlyContinue) { $PSStyle.OutputRendering = 'Ansi' }

function Get-Normalized([string]$Path) { ((Get-Content $Path -Raw) -replace "`r`n", "`n").Trim() }

function Format-Result([string]$Text) {
    $prefix = "/subscriptions/$($cfg.subscriptionId)/resourceGroups/$rg/providers/"
    $skip = '^\s*(Resource Id|Stack Resource Id|Correlation Id|Creation Time|Expiration Time|Provisioning State|Name)\s*:'
    $out = New-Object System.Collections.Generic.List[string]
    $blank = 0
    foreach ($l in ($Text -split "\r?\n")) {
        $p = [regex]::Replace($l, "$esc\[[0-9;]*m", '')
        if ($p -cmatch $skip) { continue }
        if ($p -match 'You can help us improve the accuracy|Getting the latest status of all resources') { continue }
        if (-not $p.Trim()) { $blank++; if ($blank -gt 1) { continue } } else { $blank = 0 }
        $out.Add($l.Replace($prefix, ''))
    }
    ($out -join "`n").Trim("`r", "`n")
}

if ($Fallback) { $TemplateFile = $fallbackFile }
elseif (-not (Test-Path $TemplateFile)) {
    if (-not $Replay) { Write-Host "  $TemplateFile isn't there yet. Using the version made ahead of time." -ForegroundColor DarkGray }
    $TemplateFile = $fallbackFile
}
$tf = (Resolve-Path $TemplateFile).Path
$name = 'wi-migrate-' + (Get-Date -Format 'HHmmss')
Write-Host ''
Write-Host "PS> New-AzResourceGroupDeploymentStackWhatIfResult ``" -ForegroundColor Yellow
Write-Host "        -Name $name ``" -ForegroundColor Yellow
Write-Host "        -ResourceGroupName $rg ``" -ForegroundColor Yellow
Write-Host "        -StackResourceId <$stackName ID> ``" -ForegroundColor Yellow
Write-Host "        -TemplateFile $(Split-Path $tf -Leaf) ``" -ForegroundColor Yellow
Write-Host "        -ActionOnUnmanage DetachAll ``" -ForegroundColor Yellow
Write-Host "        -DenySettingsMode None ``" -ForegroundColor Yellow
Write-Host "        -RetentionInterval PT1H ``" -ForegroundColor Yellow
Write-Host "        -Force" -ForegroundColor Yellow
Write-Host ''
Write-Host "  Azure CLI:  az stack-whatif group create --name $name --resource-group $rg --stack-id <$stackName ID> --template-file $(Split-Path $tf -Leaf) --action-on-unmanage detachAll --deny-settings-mode none --retention-interval PT1H" -ForegroundColor DarkGray
Write-Host ''

$isFallback = (Get-Normalized $tf) -eq (Get-Normalized $fallbackFile)
$text = $null
if ($Replay) {
    $text = Get-Content $replayFile -Raw
}
else {
    try {
        Import-Module Az.Resources -MinimumVersion 10.2.1 -WarningAction SilentlyContinue
        $pick = @{ Subscription = $cfg.subscriptionId }
        if ($cfg.tenantId -match '^[0-9a-f]{8}-' -and $cfg.tenantId -notmatch '^0{8}-') { $pick.Tenant = $cfg.tenantId }
        $null = Set-AzContext @pick -WarningAction SilentlyContinue
        $stackId = "/subscriptions/$($cfg.subscriptionId)/resourceGroups/$rg/providers/Microsoft.Resources/deploymentStacks/$stackName"
        Write-Host '  Getting the latest status of all resources... (about 30 seconds)' -ForegroundColor DarkGray
        $r = New-AzResourceGroupDeploymentStackWhatIfResult -Name $name -ResourceGroupName $rg -StackResourceId $stackId -TemplateFile $tf `
            -ActionOnUnmanage DetachAll -DenySettingsMode None -RetentionInterval PT1H -Force -WarningAction SilentlyContinue 6>$null
        $text = Format-Result ($r | Out-String -Width 4096)
        if ($isFallback -and $text) { Set-Content -Path $replayFile -Value $text -Encoding utf8 -NoNewline }
    }
    catch {
        Write-Host ("  (live call failed: " + (($_.Exception.Message -split "`r?`n")[0]) + ")") -ForegroundColor DarkGray
        if (Test-Path $replayFile) {
            Write-Host '  (showing the saved result instead)' -ForegroundColor DarkGray
            $text = Get-Content $replayFile -Raw
        }
    }
}
if ($text) { Write-Host $text }
Write-Host ''
Write-Host '  Nothing was deployed. This only created a What-If result.' -ForegroundColor Green
