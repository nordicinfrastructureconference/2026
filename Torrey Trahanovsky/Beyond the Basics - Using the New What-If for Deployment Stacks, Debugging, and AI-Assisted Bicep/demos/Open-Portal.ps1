<#
    Opens Edge with the portal tabs for the demos, in the order you use them: the demo resource group,
    the stack (it doesn't exist until Demo 2, so press F5 on that tab after you create it), and the
    brownfield resource group for the AI demo. Sign in once, then leave the window open.
#>
$cfg = Get-Content (Join-Path $PSScriptRoot 'demo.config.json') -Raw | ConvertFrom-Json
$tenant = if ($cfg.tenantId) { "@$($cfg.tenantId)" } else { '' }
$base = "https://portal.azure.com/#$tenant/resource/subscriptions/$($cfg.subscriptionId)/resourceGroups"
$urls = @(
    "$base/$($cfg.resourceGroup)/overview",
    "$base/$($cfg.resourceGroup)/providers/Microsoft.Resources/deploymentStacks/$($cfg.stackName)/overview",
    "$base/$($cfg.brownfieldResourceGroup)/overview"
)
Start-Process msedge.exe -ArgumentList (@('--new-window') + $urls)