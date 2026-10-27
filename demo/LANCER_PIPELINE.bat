@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
title Video to PowerPoint

rem Desactivation du controle de zone Windows
set SEE_MASK_NOZONECHECKS=1
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '%~dp0' -Recurse -Force | Unblock-File -ErrorAction SilentlyContinue" >nul 2>&1

rem Masquer les messages avertissement Hugging Face et symlinks
set HF_HUB_DISABLE_SYMLINKS_WARNING=1
set PYTHONWARNINGS=ignore
set TOKENIZERS_PARALLELISM=false

echo ================================================================
echo   Video to PowerPoint - Traitement Automatique
echo ================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_pipeline.ps1" %*

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Une erreur est survenue - code: %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

if exist "%~dp0output" (
    start "" explorer.exe "%~dp0output"
)

exit /b 0
