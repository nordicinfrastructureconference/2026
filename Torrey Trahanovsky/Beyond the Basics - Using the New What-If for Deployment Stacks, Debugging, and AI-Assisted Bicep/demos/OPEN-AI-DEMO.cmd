@echo off
rem Opens the AI demo in its own VS Code window, showing the migration skill and the saved Copilot chat.
rem If a rehearsal changed the files Copilot wrote, this puts them back the way they were at the end
rem of the saved conversation (the brownfield folder and the converted pipeline).
set "AI=%~dp0ai-demo"
if exist "%AI%\chat\recorded\brownfield" robocopy "%AI%\chat\recorded\brownfield" "%AI%\brownfield" /MIR /NFL /NDL /NJH /NJS /NP >nul
if exist "%AI%\chat\recorded\deploy.yml" copy /y "%AI%\chat\recorded\deploy.yml" "%AI%\.github\workflows\deploy.yml" >nul
code -n "%AI%" "%AI%\chat\stack-migration-chat.md" "%AI%\.github\skills\migrate-resources-to-stack\SKILL.md"
