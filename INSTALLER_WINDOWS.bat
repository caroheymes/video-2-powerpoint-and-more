@echo off
chcp 65001 >nul
setlocal
rem Desactivation du controle de zone Windows
set SEE_MASK_NOZONECHECKS=1
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '%~dp0' -Recurse -Force | Unblock-File -ErrorAction SilentlyContinue" >nul 2>&1
cd /d "%~dp0demo"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0demo\install_gui.ps1"
