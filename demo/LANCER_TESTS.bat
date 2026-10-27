@echo off
setlocal
cd /d "%~dp0"
title Video to PowerPoint - Banc de Tests & Validation

echo ================================================================
echo   Video to PowerPoint - Banc de Tests Automatiss (Harness)
echo ================================================================
echo.

if not exist ".venv\Scripts\python.exe" (
    echo Environnement virtuel introuvable. Execution de l'installeur...
    call INSTALLER.bat
)

echo Execution de la suite de tests (pytest)...
echo.

.venv\Scripts\python.exe -m pytest tests --rootdir . -s -v

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ================================================================
    echo   [SUCCES] Tous les tests et harnesses ont ete valides !
    echo ================================================================
) else (
    echo.
    echo ================================================================
    echo   [ATTENTION] Un ou plusieurs tests ont echoue.
    echo ================================================================
)

echo.
pause
exit /b %ERRORLEVEL%
