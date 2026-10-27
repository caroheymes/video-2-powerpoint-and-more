@echo off
chcp 65001 >nul
cd /d "%~dp0"

:: Lancement de l'assistant d'installation graphique
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_gui.ps1"
