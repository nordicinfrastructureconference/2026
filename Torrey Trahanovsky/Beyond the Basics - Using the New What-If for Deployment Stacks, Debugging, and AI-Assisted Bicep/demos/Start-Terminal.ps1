<#
    The demo terminal. Loads Azure PowerShell, picks the demo subscription and opens in the folder
    with the templates, then leaves a plain PowerShell prompt. Everything after that is real output.
#>
$cfg = Get-Content (Join-Path $PSScriptRoot 'demo.config.json') -Raw | ConvertFrom-Json
try { $Host.UI.RawUI.WindowTitle = 'Stacks What-If demo' } catch { }
Write-Host 'Loading Azure PowerShell...' -ForegroundColor DarkGray
Import-Module Az.Resources -MinimumVersion 10.2.1 -WarningAction SilentlyContinue
$demoPick = @{ Subscription = $cfg.subscriptionId }
if ($cfg.tenantId -match '^[0-9a-f]{8}-' -and $cfg.tenantId -notmatch '^0{8}-') { $demoPick.Tenant = $cfg.tenantId }
$demoSignedIn = $false
try { $demoSignedIn = $null -ne (Set-AzContext @demoPick -WarningAction SilentlyContinue -ErrorAction Stop) } catch { }
# Az prints upgrade and breaking-change warnings that have nothing to do with the demo.
$global:WarningPreference = 'SilentlyContinue'
Set-Location (Join-Path $PSScriptRoot 'stacks-whatif-demo')
function global:prompt { 'PS> ' }
try { Clear-Host } catch { }
if (-not $demoSignedIn) { Write-Host "Azure PowerShell can't reach the demo subscription. Run SETUP-LAPTOP.cmd, then open a new terminal." -ForegroundColor Yellow }
