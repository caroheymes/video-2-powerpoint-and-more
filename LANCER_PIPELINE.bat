@echo off
chcp 65001 >nul
setlocal
rem Desactivation du controle de zone Windows
set SEE_MASK_NOZONECHECKS=1
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '%~dp0' -Recurse -Force | Unblock-File -ErrorAction SilentlyContinue" >nul 2>&1
cd /d "%~dp0demo"
call "%~dp0demo\LANCER_PIPELINE.bat" %*
exit /b %ERRORLEVEL%
