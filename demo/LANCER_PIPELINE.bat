@echo off
chcp 65001 >nul
title Traitement Vidéo - Restitution Stratégique (ECC)
color 0A

:: Déplacement dans le répertoire du script
cd /d "%~dp0"

echo ================================================================
echo   LANCEMENT DU PIPELINE VIDÉO ➔ LIVRABLES MULTI-FORMATS
echo ================================================================
echo.
echo  [Info] Aucune installation de Python requise (tout est géré automatiquement).
echo.

:: Exécution du script PowerShell avec contournement transparent de la politique d'exécution
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_pipeline.ps1"

:: Vérification du code de sortie
if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo.
    echo ================================================================
    echo   UNE ERREUR S'EST PRODUITE LORS DU TRAITEMENT.
    echo ================================================================
    echo Consultez les messages ci-dessus pour identifier le problème.
    echo.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ================================================================
echo   OUVERTURE DU DOSSIER DES LIVRABLES...
echo ================================================================

:: Ouvrir directement l'explorateur Windows dans le dossier de sortie
if exist "%~dp0output" (
    explorer.exe "%~dp0output"
)

echo.
pause
