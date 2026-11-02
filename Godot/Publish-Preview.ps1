$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$build = Join-Path $PSScriptRoot 'Build-Engine.ps1'
$editor = Join-Path $repo '.engine\godot-nvidia\bin\godot.windows.editor.x86_64.exe'
$template = Join-Path $repo '.engine\godot-nvidia\bin\godot.windows.template_release.x86_64.exe'
$staging = Join-Path $repo 'dist\.godot-preview-staging'
$release = Join-Path $staging 'IronNebula-Godot-win-x64.exe'
$pack = [IO.Path]::ChangeExtension($release, '.pck')
$archive = Join-Path $repo 'dist\IronNebula-Godot-win-x64.zip'

& $build -ReleaseTemplate
if ($LASTEXITCODE -ne 0) {
    throw "Godot engine/template build failed with exit code $LASTEXITCODE."
}
if (!(Test-Path -LiteralPath $editor) -or !(Test-Path -LiteralPath $template)) {
    throw 'The pinned Godot editor and release template must both exist before exporting.'
}

if (Test-Path -LiteralPath $staging) {
    Remove-Item -LiteralPath $staging -Recurse -Force
}
New-Item -ItemType Directory -Path $staging -Force | Out-Null
$exportCommand = '"' + $editor + '" --headless --path "' + $repo +
    '" --export-release Windows-x64 "' + $release + '"'
& $env:ComSpec /d /c $exportCommand
if ($LASTEXITCODE -ne 0) {
    throw "Godot release export failed with exit code $LASTEXITCODE."
}
if (!(Test-Path -LiteralPath $release)) {
    throw "Godot export did not create its release executable: $release"
}
if (!(Test-Path -LiteralPath $pack)) {
    throw "Godot export did not create its required resource pack: $pack"
}

Compress-Archive -Path $release, $pack -DestinationPath $archive -Force
$null = Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($archive)
try {
    $files = @($zip.Entries | ForEach-Object { [IO.Path]::GetFileName($_.FullName) })
    if ($files.Count -ne 2 -or
        $files -notcontains [IO.Path]::GetFileName($release) -or
        $files -notcontains [IO.Path]::GetFileName($pack)) {
        throw "Godot release ZIP must contain only $release and $pack."
    }
}
finally {
    $zip.Dispose()
}

Remove-Item -LiteralPath $staging -Recurse -Force
foreach ($payload in @(
    (Join-Path $repo 'dist\IronNebula-Godot-win-x64.exe'),
    (Join-Path $repo 'dist\IronNebula-Godot-win-x64.pck')
)) {
    if (Test-Path -LiteralPath $payload) {
        Remove-Item -LiteralPath $payload -Force
    }
}

Write-Output "Godot release download: $archive (the only Godot release file)"
