@echo off
setlocal
cd /d "%~dp0demo"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0demo\install_gui.ps1"