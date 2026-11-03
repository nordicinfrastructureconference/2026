<#
    For when Azure can't be reached. Plays back what one step of commands.ps1 printed in a rehearsal, with
    the same colors, after a line that says it's saved, so it's never mistaken for a live run.
    From the demo terminal:  ..\Show-Saved.ps1 3      (F12 puts this at the prompt in the press-Enter backup)
#>
param([Parameter(Mandatory)][ValidateRange(1, 99)][int]$Step)
$dir = Join-Path $PSScriptRoot '_saved'
$file = @("step-$Step.ansi", "step-$Step.txt") | ForEach-Object { Join-Path $dir $_ } | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $file) { Write-Host "Nothing saved for step $Step." -ForegroundColor Yellow; return }
$when = if (Test-Path (Join-Path $dir 'recorded.txt')) { (Get-Content (Join-Path $dir 'recorded.txt') -TotalCount 1).Trim() } else { (Get-Item $file).LastWriteTime.ToString('d MMMM') }
Write-Host "Saved from a rehearsal on $when, not live:" -ForegroundColor DarkGray
[Console]::Out.Write([IO.File]::ReadAllText($file))
