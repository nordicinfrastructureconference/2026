<#
    Backup way to run the Stacks What-If demo: press Enter instead of using Ctrl+Enter in commands.ps1.
    Everything on screen is still the real PowerShell prompt and the real output from Azure.

    In the demo terminal, run it once:
        ..\Start-PressEnter.ps1        start at the beginning
        ..\Start-PressEnter.ps1 6      start at step 6 (it puts the $stackId line first)
    Then, at an empty prompt, Enter puts the next command from commands.ps1 at the prompt, and Enter
    again runs it. Typing your own command and pressing Enter works as usual.
    If a step fails because Azure can't be reached, press F12. It puts ..\Show-Saved.ps1 for that
    step at the prompt, and Enter shows what a rehearsal saved, labeled as saved.
        ..\Start-PressEnter.ps1 -Off   puts Enter back to normal
#>
param([ValidateRange(1, 99)][int]$From = 1, [switch]$Off)

if ($Off) {
    Set-PSReadLineKeyHandler -Chord Enter -Function AcceptLine
    Remove-PSReadLineKeyHandler -Chord F12
    Remove-Variable -Name StacksDemo -Scope Global -ErrorAction SilentlyContinue
    Write-Host 'Enter is back to normal.' -ForegroundColor DarkGray
    return
}

# Read the commands from commands.ps1, in order. A diff (a code line) and anything under "# The ..." belong
# to the numbered step after them. Comments, including the Azure CLI lines, are skipped.
$entries = [Collections.Generic.List[object]]::new()
$pending = [Collections.Generic.List[string]]::new()
$current = $null
foreach ($line in Get-Content (Join-Path $PSScriptRoot 'stacks-whatif-demo\commands.ps1')) {
    if ($line -match '^# (\d+)\. ') {
        $current = [int]$Matches[1]
        foreach ($p in $pending) { $entries.Add([pscustomobject]@{ Step = $current; Command = $p }) }
        $pending.Clear()
        continue
    }
    if ($line -match '^# The ') { $current = $null; continue }
    if (-not $line.Trim() -or $line.TrimStart().StartsWith('#')) { continue }
    if ($current -and -not $line.TrimStart().StartsWith('code ')) { $entries.Add([pscustomobject]@{ Step = $current; Command = $line.Trim() }) } else { $pending.Add($line.Trim()) }
}
$queue = @($entries | Where-Object Step -ge $From)
# Starting after the step that sets $stackId, put that line first, since later steps use it.
$id = $entries | Where-Object { $_.Command -like '$stackId =*' } | Select-Object -First 1
if ($id -and $From -gt $id.Step) { $queue = @([pscustomobject]@{ Step = $From; Command = $id.Command }) + $queue }

$global:StacksDemo = [pscustomobject]@{ Queue = $queue; Index = 0 }

Set-PSReadLineKeyHandler -Chord Enter -BriefDescription 'StacksDemoEnter' -Description 'Stacks demo: Enter at an empty prompt shows the next command' -ScriptBlock {
    param($key, $arg)
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    $d = $global:StacksDemo
    if ($d -and [string]::IsNullOrWhiteSpace($line) -and $d.Index -lt $d.Queue.Count) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($d.Queue[$d.Index].Command)
        $d.Index++
    }
    else { [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine($key, $arg) }
}

Set-PSReadLineKeyHandler -Chord F12 -BriefDescription 'StacksDemoSaved' -Description 'Stacks demo: show the saved output for this step' -ScriptBlock {
    $d = $global:StacksDemo
    if (-not $d -or $d.Queue.Count -eq 0) { return }
    $step = $d.Queue[[Math]::Max(0, $d.Index - 1)].Step
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("..\Show-Saved.ps1 $step")
}
