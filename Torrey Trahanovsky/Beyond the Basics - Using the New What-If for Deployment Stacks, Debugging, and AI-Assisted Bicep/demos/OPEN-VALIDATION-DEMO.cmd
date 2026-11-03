@echo off
rem Opens the validation demo (snapshot and lint) in its own VS Code window. Then press Ctrl+` to open its terminal.
code -n "%~dp0stacks-whatif-demo-debug" "%~dp0stacks-whatif-demo-debug\commands.ps1" "%~dp0stacks-whatif-demo-debug\main.bicep"
