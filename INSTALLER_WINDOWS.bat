@echo off
chcp 65001 >nul
cd /d "%~dp0demo"

:: Lancement de l'assistant d'installation graphique sans console noire parasite
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0demo\install_gui.ps1"
