@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0demo"
call "%~dp0demo\LANCER_TESTS.bat" %*
exit /b %ERRORLEVEL%
