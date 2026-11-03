# Runs Stacks What-If for moving the brownfield resource group into a new stack. Nothing gets deployed.
#   .\whatif.ps1             uses brownfield\main.bicep, the file Copilot wrote
#   .\whatif.ps1 -Fallback   uses the version made ahead of time
#   .\whatif.ps1 -Replay     shows the saved result, no network
param([string]$TemplateFile = 'brownfield\main.bicep', [switch]$Fallback, [switch]$Replay)
& (Join-Path $PSScriptRoot '..\Start-MigrateWhatIf.ps1') -TemplateFile $TemplateFile -Fallback:$Fallback -Replay:$Replay
