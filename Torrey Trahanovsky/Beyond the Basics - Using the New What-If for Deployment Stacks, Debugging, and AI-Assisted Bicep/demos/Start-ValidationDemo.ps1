<#
    The validation demo terminal. Puts main.bicep back the way the demo starts and deletes the snapshot from
    last time, then leaves a plain PowerShell prompt in the folder. The commands are in commands.ps1. They
    all run on this laptop with the Bicep CLI, and nothing here talks to Azure.
#>
try { $Host.UI.RawUI.WindowTitle = 'Validation demo' } catch { }
Set-Location (Join-Path $PSScriptRoot 'stacks-whatif-demo-debug')
Copy-Item main.v1.bicep main.bicep -Force
Remove-Item main.snapshot.json -ErrorAction SilentlyContinue
function global:prompt { 'PS> ' }
try { Clear-Host } catch { }
if (-not (Get-Command bicep -ErrorAction SilentlyContinue)) { Write-Host 'The Bicep CLI is missing. Run SETUP-LAPTOP.cmd, then open a new terminal.' -ForegroundColor Yellow }
