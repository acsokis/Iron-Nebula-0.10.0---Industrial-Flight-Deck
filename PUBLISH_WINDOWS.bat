@echo off
setlocal EnableExtensions
cd /d "%~dp0"
set "STAGE=dist\_IronNebula-win-x64-stage"
where dotnet >nul 2>&1
if errorlevel 1 (
 echo ERROR: .NET 10 SDK not found.
 pause
 exit /b 1
)
dotnet --list-sdks | findstr /b "10." >nul
if errorlevel 1 (
 echo ERROR: .NET 10 SDK not found.
 pause
 exit /b 1
)
if not exist "Assets\HD\outer_frontier_cinematic.png" (
 echo ERROR: Required desktop artwork is missing: Assets\HD\outer_frontier_cinematic.png
 echo Restore the complete Assets folder before publishing.
 exit /b 1
)
if not exist "Assets\ui_atlas.png" (
 echo ERROR: Required desktop artwork is missing: Assets\ui_atlas.png
 echo Restore the complete Assets folder before publishing.
 exit /b 1
)
if not exist "Assets\Audio\Propulsive Peak_stream.wav" (
 echo ERROR: Required licensed soundtrack is missing: Assets\Audio\Propulsive Peak_stream.wav
 exit /b 1
)
if not exist "Assets\Audio\Propulsive Peak.mp3" (
 echo ERROR: Required licensed soundtrack is missing: Assets\Audio\Propulsive Peak.mp3
 exit /b 1
)
echo [1/3] NuGet restore...
dotnet restore IronNebula.csproj --force -r win-x64 --verbosity minimal
if errorlevel 1 goto :failed
if exist "%STAGE%" rmdir /s /q "%STAGE%"
if exist "%STAGE%" goto :failed
echo [2/3] Self-contained Windows x64 publish...
dotnet publish IronNebula.csproj -c Release -r win-x64 --self-contained true --no-restore -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:DebugType=none -p:DebugSymbols=false -o "%STAGE%"
if errorlevel 1 goto :failed
if not exist "%STAGE%\IronNebula.exe" (
 echo ERROR: Published executable is missing.
 goto :failed
)
if not exist "%STAGE%\Assets\HD\outer_frontier_cinematic.png" (
 echo ERROR: Required published artwork is missing.
 goto :failed
)
if not exist "%STAGE%\Assets\ui_atlas.png" (
 echo ERROR: Required published UI artwork is missing.
 goto :failed
)
if not exist "%STAGE%\Assets\Audio\Propulsive Peak_stream.wav" (
 echo ERROR: The licensed streamed soundtrack is missing from the publish output.
 goto :failed
)
if not exist "%STAGE%\Assets\Audio\Propulsive Peak.mp3" (
 echo ERROR: The licensed soundtrack source is missing from the publish output.
 goto :failed
)
echo [3/3] Creating and validating the single-file Windows release download...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $stage='dist\_IronNebula-win-x64-stage'; $archive='dist\IronNebula-win-x64.zip'; Compress-Archive -Path (Join-Path $stage 'IronNebula.exe'),(Join-Path $stage 'Assets') -DestinationPath $archive -Force; Add-Type -AssemblyName System.IO.Compression.FileSystem; $zip=[IO.Compression.ZipFile]::OpenRead($archive); try { $files=@($zip.Entries | Where-Object { !$_.FullName.EndsWith('/') }); $names=@($files | ForEach-Object { $_.FullName.Replace('\','/') }); $root=@($names | Where-Object { $_ -notmatch '/' }); if($root.Count -ne 1 -or $root[0] -ne 'IronNebula.exe' -or $files.Count -lt 100 -or $names -notcontains 'Assets/HD/outer_frontier_cinematic.png' -or $names -notcontains 'Assets/ui_atlas.png' -or $names -notcontains 'Assets/Audio/Propulsive Peak.mp3' -or $names -notcontains 'Assets/Audio/Propulsive Peak_stream.wav'){throw 'Windows release ZIP is missing required content or contains unexpected root files.'} } finally { $zip.Dispose() }; if(Test-Path -LiteralPath 'dist\IronNebula-win-x64'){Remove-Item -LiteralPath 'dist\IronNebula-win-x64' -Recurse -Force}; Remove-Item -LiteralPath $stage -Recurse -Force"
if errorlevel 1 goto :failed
echo.
echo SUCCESS: dist\IronNebula-win-x64.zip
echo SHA-256:
powershell -NoProfile -Command "(Get-FileHash -LiteralPath 'dist\IronNebula-win-x64.zip' -Algorithm SHA256).Hash"
echo The ZIP is the only Windows release file; extract it before running the EXE.
echo The extracted game requires its Assets folder beside the EXE.
exit /b 0
:failed
echo PUBLISH FAILED: ellenorizd a fenti NuGet, build vagy ZIP-hibakat.
pause
exit /b 1
