@echo off
setlocal EnableExtensions
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File Godot\Publish-Preview.ps1
if errorlevel 1 (
 echo Godot release publish failed.
 exit /b 1
)
echo Godot release archive created at dist\IronNebula-Godot-win-x64.zip
