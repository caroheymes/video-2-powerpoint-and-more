@echo off
setlocal
cd /d "%~dp0"
title Video to PowerPoint

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