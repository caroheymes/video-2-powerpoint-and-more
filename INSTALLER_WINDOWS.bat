@echo off
setlocal
:: Désactiver les alertes de sécurité Windows 'L'éditeur n'a pas pu être vérifié' (Attachment Execution Service)
set SEE_MASK_NOZONECHECKS=1
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '%~dp0' -Recurse -Force | Unblock-File -ErrorAction SilentlyContinue" >nul 2>&1
cd /d "%~dp0demo"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0demo\install_gui.ps1"