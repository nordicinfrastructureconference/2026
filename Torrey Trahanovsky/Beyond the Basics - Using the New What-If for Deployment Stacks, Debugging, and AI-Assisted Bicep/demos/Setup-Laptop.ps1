<#
    Setup for the Stacks What-If demos (V4) on a new machine, and the reset after a practice run.
    Checks what's needed, asks before installing anything, adds two demo-only shortcuts to VS Code,
    signs in to Azure, puts Azure back at the starting point, then opens the windows.

        .\Setup-Laptop.ps1           # normal
        .\Setup-Laptop.ps1 -NoOpen   # no Azure changes and no windows. It still sets up what's missing on this laptop.
#>
[CmdletBinding()]
param(
    [switch]$NoOpen,
    [string]$KeybindingsPath = (Join-Path $env:APPDATA 'Code\User\keybindings.json')
)

$ErrorActionPreference = 'Continue'
$here = $PSScriptRoot
$ws   = Join-Path $here 'stacks-whatif-demo'
$ok   = $true

function Say([string]$Text, [string]$Color = 'Gray') { Write-Host $Text -ForegroundColor $Color }
function Ask([string]$Question) {
    Write-Host "$Question (Y/N) " -ForegroundColor Yellow -NoNewline
    return ((Read-Host) -match '^(y|yes)$')
}
function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

Say ''
Say 'Stacks What-If demo setup' Cyan
Say ''

# 0. PowerShell 7 (the demo terminal and Az need it).
if ($PSVersionTable.PSVersion.Major -lt 7) {
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @PSBoundParameters
        return
    }
    if (Ask '  PowerShell 7 is missing. Install it with winget now?') {
        winget install -e --id Microsoft.PowerShell --accept-source-agreements --accept-package-agreements
        Say '  Done. Close this window and double-click SETUP-LAPTOP.cmd again.' Yellow
    }
    else { Say '  MISS PowerShell 7' Red }
    return
}
Say "  OK   PowerShell $($PSVersionTable.PSVersion)" Green

# 1. Bicep CLI on PATH (Az PowerShell uses it to read .bicep files).
if (Get-Command bicep -ErrorAction SilentlyContinue) { Say '  OK   Bicep CLI' Green }
elseif (Ask '  Bicep CLI is missing. Install it with winget now?') {
    winget install -e --id Microsoft.Bicep --accept-source-agreements --accept-package-agreements
    Update-SessionPath
    if (Get-Command bicep -ErrorAction SilentlyContinue) { Say '  OK   Bicep CLI installed' Green } else { Say '  MISS Bicep CLI. Open a new window and run this again.' Red; $ok = $false }
}
else { Say '  MISS Bicep CLI' Red; $ok = $false }

# 1a. Bicep CLI version. The talk uses 0.48.1. Older ones still deploy the demo, so this only warns.
$bv = $null; if ((((& bicep --version 2>$null) -join ' ')) -match '(\d+\.\d+\.\d+)') { $bv = [version]$Matches[1] }
if ($bv -and $bv -lt [version]'0.48.1') {
    # winget can only update a Bicep CLI it installed. Otherwise, say so instead of offering an update that fails.
    $viaWinget = (& winget list -e --id Microsoft.Bicep --accept-source-agreements 2>$null | Out-String) -match 'Microsoft\.Bicep'
    if (-not $viaWinget) { Say "  NOTE Bicep CLI $bv. The talk shows 0.48.1, but the demo works with $bv. It wasn't installed with winget, so update it the way you installed it if you want to." Yellow }
    elseif (Ask "  Bicep CLI is $bv. Update it to the latest with winget now?") {
        winget upgrade -e --id Microsoft.Bicep --accept-source-agreements --accept-package-agreements
        Update-SessionPath
    }
    else { Say "  WARN Bicep CLI $bv (the talk shows 0.48.1)" Yellow }
}

# 1b. Azure CLI 2.88 or later has 'az stack-whatif'. The demo runs PowerShell and the az versions are
#     comments in commands.ps1, so this only warns. If you install it here, close every VS Code window and reopen.
$azv = $null
if (Get-Command az -ErrorAction SilentlyContinue) { $azv = [version]((& az version --query '\"azure-cli\"' -o tsv 2>$null) | Select-Object -First 1) }
if ($azv -and $azv -ge [version]'2.88.0') { Say "  OK   Azure CLI $azv" Green }
elseif (Ask "  Azure CLI is $(if ($azv) { $azv } else { 'missing' }). 2.88 or later has 'az stack-whatif'. Install or update it with winget now?") {
    winget install -e --id Microsoft.AzureCLI --accept-source-agreements --accept-package-agreements
    Update-SessionPath
    Say '  Done. Close every VS Code window and reopen so its terminals find the new az.' Yellow
}
else { Say "  WARN Azure CLI $(if ($azv) { $azv } else { 'missing' }) (az stack-whatif needs 2.88+)" Yellow }

# 2. Az.Resources 10.2.1 or later (has the Stacks What-If cmdlets).
$mod = Get-Module Az.Resources -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
if ($mod -and $mod.Version -ge [version]'10.2.1') { Say "  OK   Az.Resources $($mod.Version)" Green }
elseif (Ask '  Az.Resources 10.2.1 (Stacks What-If cmdlets) is missing. Install it now?') {
    Install-Module Az.Resources -RequiredVersion 10.2.1 -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
    $mod = Get-Module Az.Resources -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    if ($mod -and $mod.Version -ge [version]'10.2.1') { Say "  OK   Az.Resources $($mod.Version) installed" Green } else { Say '  MISS Az.Resources' Red; $ok = $false }
}
else { Say '  MISS Az.Resources 10.2.1' Red; $ok = $false }

# 3. VS Code, and the Bicep extension (the AI demo needs it for the Bicep MCP server).
$code = Get-Command code -ErrorAction SilentlyContinue
if ($code) { Say '  OK   VS Code' Green }
elseif (Ask '  VS Code is missing. Install it with winget now?') {
    winget install -e --id Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements
    Update-SessionPath
    $code = Get-Command code -ErrorAction SilentlyContinue
    if ($code) { Say '  OK   VS Code installed' Green } else { Say '  MISS VS Code. Open a new window and run this again.' Red; $ok = $false }
}
else { Say '  MISS VS Code' Red; $ok = $false }

function Test-BicepExtension {
    $dirs = @((Join-Path $env:USERPROFILE '.vscode\extensions'), (Join-Path $env:USERPROFILE '.vscode-insiders\extensions'))
    if ($env:VSCODE_EXTENSIONS) { $dirs += $env:VSCODE_EXTENSIONS }
    foreach ($d in $dirs) {
        if (Get-ChildItem -Path $d -Directory -Filter 'ms-azuretools.vscode-bicep-*' -ErrorAction SilentlyContinue) { return $true }
    }
    if ($code -and ((& code --list-extensions 2>$null) -match 'ms-azuretools\.vscode-bicep')) { return $true }
    return $false
}
if ($code) {
    if (Test-BicepExtension) { Say '  OK   Bicep extension' Green }
    elseif (Ask '  Could not find the Bicep extension for VS Code. Install it now?') {
        & code --install-extension ms-azuretools.vscode-bicep
        if (Test-BicepExtension) { Say '  OK   Bicep extension installed' Green } else { Say '  NOTE Could not confirm the Bicep extension. The Stacks demo still works, but the AI demo needs it.' Yellow }
    }
    else { Say '  NOTE Skipped the Bicep extension. The Stacks demo still works, but the AI demo needs it.' Yellow }
}

# 3b. ZoomIt (optional). Ctrl+1 zooms in where the mouse is, which helps people at the back read the
#     terminal and the portal. It uses Ctrl+1 to Ctrl+4, so click the Edge tabs instead of Ctrl+1/2/3.
function Find-ZoomIt {
    $c = Get-Command ZoomIt64.exe, ZoomIt.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($c) { return $c.Source }
    foreach ($p in @("$env:LOCALAPPDATA\Microsoft\WinGet\Links\ZoomIt64.exe", "$env:LOCALAPPDATA\Microsoft\WinGet\Links\ZoomIt.exe")) { if (Test-Path $p) { return $p } }
    $pkg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Directory -Filter 'Microsoft.Sysinternals.ZoomIt*' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pkg) { $exe = Get-ChildItem $pkg.FullName -Recurse -Filter 'ZoomIt64.exe' -ErrorAction SilentlyContinue | Select-Object -First 1; if ($exe) { return $exe.FullName } }
    return $null
}
$zoomIt = Find-ZoomIt
if ($zoomIt) { Say '  OK   ZoomIt' Green }
elseif (Ask '  ZoomIt is not installed. It zooms in where your mouse is during the demo (optional). Install it with winget now?') {
    winget install -e --id Microsoft.Sysinternals.ZoomIt --accept-source-agreements --accept-package-agreements
    $zoomIt = Find-ZoomIt
    if ($zoomIt) { Say '  OK   ZoomIt installed' Green } else { Say '  NOTE Could not find ZoomIt after installing. Open a new window and run this again.' Yellow }
}
else { Say '  NOTE Skipped ZoomIt. Ctrl+= in VS Code and Edge still zooms in.' Yellow }
# The AI demo folder.
$aiFolder = Join-Path $here 'ai-demo'
if ((Test-Path (Join-Path $aiFolder '.github\skills\migrate-resources-to-stack\SKILL.md')) -and (Test-Path (Join-Path $aiFolder 'whatif.ps1'))) { Say '  OK   AI demo folder' Green }
else { Say '  NOTE The ai-demo folder is missing.' Yellow }

# 4. Two demo-only shortcuts, merged into any existing VS Code keybindings. Ctrl+Enter in
#    commands.ps1 sends the line the cursor is on to the terminal. Enter in commands.ps1, in the
#    app.v*.bicep files and in the validation demo files only moves to the next line (the files are
#    read-only), so a stray Enter never reaches the terminal. If the Enter entry is from before the
#    validation demo used commands.ps1, it gets updated.
$oldEnterWhen = 'resourcePath =~ /stacks-whatif-demo.app.v|stacks-whatif-demo.commands.ps1$/i'
$enterWhen    = 'resourcePath =~ /stacks-whatif-demo.app.v|stacks-whatif-demo-debug.|stacks-whatif-demo.commands.ps1$/i'
$entry = @"
    // Stacks What-If demo V4: in commands.ps1, Ctrl+Enter runs the line in the terminal. In the V4 demo
    // files, Enter only moves to the next line. Delete these two entries when you're done with the demo.
    {
        "key": "ctrl+enter",
        "command": "workbench.action.terminal.runSelectedText",
        "when": "editorTextFocus && resourceFilename == 'commands.ps1' && resourcePath =~ /stacks-whatif-demo/i"
    },
    {
        "key": "enter",
        "command": "cursorDown",
        "when": "editorTextFocus && $enterWhen"
    }
"@
try {
    $kb = if (Test-Path $KeybindingsPath) { "$(Get-Content $KeybindingsPath -Raw)" } else { '' }
    if ($kb -match 'Stacks What-If demo V4' -and $kb.Contains($oldEnterWhen)) {
        Copy-Item $KeybindingsPath "$KeybindingsPath.bak-stacksdemo-v4-enter" -Force
        [System.IO.File]::WriteAllText($KeybindingsPath, $kb.Replace($oldEnterWhen, $enterWhen))
        Say '  OK   Enter shortcut updated for the validation demo' Green
    }
    elseif ($kb -match 'Stacks What-If demo V4') { Say '  OK   Ctrl+Enter shortcut (already there)' Green }
    else {
        if ($kb.Trim() -eq '') {
            $new = "// Place your key bindings in this file to override the defaults`r`n[`r`n$entry`r`n]`r`n"
        }
        else {
            Copy-Item $KeybindingsPath "$KeybindingsPath.bak-stacksdemo-v4" -Force
            # Later entries win in VS Code, so these go at the end of the list.
            $m = [regex]::Match($kb, '(?s)\]\s*$')
            if (-not $m.Success) { throw 'could not find the end of the keybindings list' }
            $head = $kb.Substring(0, $m.Index)
            $body = [regex]::Replace($head, '(?s)/\*.*?\*/|//[^\r\n]*', '')
            $sep  = if ($body.TrimEnd().EndsWith('[') -or $body.TrimEnd().EndsWith(',')) { '' } else { ',' }
            $new  = $head.TrimEnd() + $sep + "`r`n" + $entry + "`r`n]`r`n"
        }
        $dir = Split-Path $KeybindingsPath -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        [System.IO.File]::WriteAllText($KeybindingsPath, $new)
        Say '  OK   Ctrl+Enter shortcut added to VS Code' Green
    }
}
catch { Say "  NOTE Ctrl+Enter shortcut not added ($($_.Exception.Message)). Copy and paste the commands instead." Yellow }

if (-not $ok) { Say ''; Say 'Not ready yet. Fix the red items above, then run this again.' Red; return }

# 5. Sign in and put Azure at the starting point. If this stops, the windows below still open.
if (-not $NoOpen) {
    Say ''
    try {
        & (Join-Path $here 'Prepare-Stage.ps1')
        if (-not $?) { Say 'Azure prep did not finish. Run SETUP-LAPTOP.cmd again. The first Azure call sometimes times out.' Yellow }
    }
    catch { Say "  Azure prep stopped: $(($_.Exception.Message -split "`r?`n")[0])" Yellow }
}

# 6. Check that Azure is at the starting point.
Say ''
& (Get-Process -Id $PID).Path -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'Prepare-Stage.ps1') -Check
$live = ($LASTEXITCODE -eq 0)

# 7. Open everything: the portal, the AI demo window, the validation demo window, and the
#    main demo last so it's in front.
if (-not $NoOpen) {
    & (Join-Path $here 'Open-Portal.ps1')
    Start-Sleep -Seconds 2
    & cmd.exe /c "`"$(Join-Path $here 'OPEN-AI-DEMO.cmd')`""
    Start-Sleep -Seconds 3
    & cmd.exe /c "`"$(Join-Path $here 'OPEN-VALIDATION-DEMO.cmd')`""
    Start-Sleep -Seconds 3
    & code -n "$ws" "$(Join-Path $ws 'commands.ps1')" "$(Join-Path $ws 'app.v1.bicep')" 2>$null
    # ZoomIt runs in the tray. Start it now so Ctrl+1 works on stage.
    if ($zoomIt -and -not (Get-Process ZoomIt64, ZoomIt -ErrorAction SilentlyContinue)) { Start-Process $zoomIt }
}

Say ''
if ($live) { Say 'All set.' Green }
else { Say 'Not ready yet: Azure is not at the starting point. Run SETUP-LAPTOP.cmd again before the talk.' Yellow }
Say '  1. VS Code opens three windows: Stacks What-If demo, Validation demo and AI demo. If one asks'
Say '     whether you trust the authors, click "Yes, I trust the authors".'
Say '  2. In Edge, sign in to the portal if it asks. Leave the three tabs open, and zoom the portal to 175% (Ctrl+plus).'
Say '  3. In the Stacks What-If demo window, press Ctrl + ` (the key under Esc) to open the demo terminal.'
Say '     It loads Azure PowerShell and leaves a PS> prompt. Leave it there.'
Say '     Do the same in the Validation demo window. That one only needs the Bicep CLI.'
Say '  4. The AI demo window shows the recorded Copilot chat as a page, chat\stack-migration-chat.md.'
Say '  5. Then follow README.md.'
