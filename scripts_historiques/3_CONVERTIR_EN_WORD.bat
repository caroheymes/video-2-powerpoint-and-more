@echo off
chcp 65001 >nul
set PYTHONIOENCODING=utf-8
title Conversion Markdown (.md) vers Microsoft Word (.docx)
echo ===============================================================================
echo   CONVERSION EN DOCUMENT MICROSOFT WORD (.DOCX) - CABINET D'AVOCATS
echo ===============================================================================
echo.
echo   1. Convertir uniquement FEUILLE_DE_ROUTE_TOTALE_MCP_SKILLS_IP_IT_MARQUES.md
echo   2. Convertir TOUS les rapports et manuels (.md) du dossier en Word (.docx)
echo   3. Choisir un fichier .md specifique
echo.
set /p CHOIX="Votre choix (1, 2 ou 3 - defaut: 2) : "
if "%CHOIX%"=="" set CHOIX=2

if exist "%USERPROFILE%\.gemini\legifrance-env\Scripts\python.exe" (
    set "PY_CMD=%USERPROFILE%\.gemini\legifrance-env\Scripts\python.exe"
) else (
    set "PY_CMD=py"
)

if "%CHOIX%"=="1" (
    "%PY_CMD%" "%~dp0convertir_md_en_word.py" "%~dp0FEUILLE_DE_ROUTE_TOTALE_MCP_SKILLS_IP_IT_MARQUES.md"
) else if "%CHOIX%"=="2" (
    "%PY_CMD%" "%~dp0convertir_md_en_word.py" --all
) else (
    set /p FICHIER="Entrez le nom du fichier .md (ex: RAPPORT_AUDIT_VELORA.md) : "
    "%PY_CMD%" "%~dp0convertir_md_en_word.py" "%~dp0%FICHIER%"
)

echo.
echo ===============================================================================
echo   CONVERSION WORD (.DOCX) TERMINEE !
echo ===============================================================================
echo.
pause
