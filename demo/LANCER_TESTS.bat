@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
title Video to PowerPoint - Banc de Tests & Validation

echo ================================================================
echo   Video to PowerPoint - Banc de Tests Automatisés (Harness)
echo ================================================================
echo.

if not exist ".venv\Scripts\python.exe" (
    echo Environnement virtuel introuvable. Exécution de l'installeur...
    call INSTALLER_WINDOWS.bat
)

echo Exécution de la suite de tests (pytest)...
echo.

.venv\Scripts\python.exe -m pytest tests --rootdir . -s -v

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ================================================================
    echo   [SUCCÈS] Tous les tests et harnesses ont été validés !
    echo ================================================================
) else (
    echo.
    echo ================================================================
    echo   [ATTENTION] Un ou plusieurs tests ont échoué.
    echo ================================================================
)

echo.
pause
exit /b %ERRORLEVEL%
