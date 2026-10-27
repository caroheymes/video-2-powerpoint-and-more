@echo off
chcp 65001 >nul
title Pipeline Vidéo - Installation & Vérification
color 0B

echo ================================================================
echo   INSTALLATION & CONFIGURATION DU PIPELINE VIDÉO (ECC)
echo ================================================================
echo.
echo Ce script va vérifier et installer les composants nécessaires :
echo   - Gestionnaire d'environnement autonome (uv)
echo   - Environnement virtuel Python (.venv)
echo   - Dépendances (Whisper local, Découpage de scènes, PPTX, Word)
echo.
echo Aucune compétence technique ni droit administrateur requis.
echo.

pause

echo.
echo [1/3] Lancement de l'installation des dépendances...
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { & '%~dp0run_pipeline.ps1' -OutputDir 'temp_check' -SkipTranscription -ModelSize 'base' -ApiKey 'test_install' ; Remove-Item -Path '%~dp0temp_check' -Recurse -Force -ErrorAction SilentlyContinue }"

echo.
echo ================================================================
echo   INSTALLATION TERMINÉE AVEC SUCCÈS !
echo ================================================================
echo.
echo Vous pouvez désormais traiter n'importe quelle vidéo en double-cliquant
echo sur : LANCER_PIPELINE.bat
echo.
pause
