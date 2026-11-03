@echo off
rem Double-click once on a new machine to set up the Stacks What-If demo.
where pwsh.exe >nul 2>nul
if %errorlevel%==0 (
  pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup-Laptop.ps1"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup-Laptop.ps1"
)
echo.
pause
