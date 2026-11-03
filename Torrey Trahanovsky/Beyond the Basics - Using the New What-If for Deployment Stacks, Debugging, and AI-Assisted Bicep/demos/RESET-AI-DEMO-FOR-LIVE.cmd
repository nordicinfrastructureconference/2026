@echo off
rem Puts the AI demo back to before the Copilot chat, so you can run it live with Copilot.
rem It takes out what Copilot wrote (the brownfield folder) and puts the original pipeline back.
rem OPEN-AI-DEMO.cmd puts the recorded version back when you're done.
set "AI=%~dp0ai-demo"
if exist "%AI%\brownfield" rmdir /s /q "%AI%\brownfield"
if exist "%AI%\chat\original\deploy.yml" copy /y "%AI%\chat\original\deploy.yml" "%AI%\.github\workflows\deploy.yml" >nul
start "" notepad.exe "%AI%\chat\PROMPTS.md"
code -n "%AI%" "%AI%\.github\skills\migrate-resources-to-stack\SKILL.md"
