@echo off
setlocal EnableExtensions
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File Publish-Windows.ps1 -Overwrite
if errorlevel 1 (
 echo Windows release packaging failed.
 exit /b 1
)
echo Windows release archive created at dist\IronNebula-win-x64.zip
exit /b 0