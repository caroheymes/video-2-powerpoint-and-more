@echo off
setlocal
cd /d "%~dp0demo"
call "%~dp0demo\LANCER_PIPELINE.bat" %*
exit /b %ERRORLEVEL%
