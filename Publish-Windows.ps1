param([switch]$Overwrite)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$project = Join-Path $repo 'IronNebula.csproj'
$dist = Join-Path $repo 'dist'
$publish = Join-Path $dist '.windows-publish-staging'
$pending = Join-Path $dist '.IronNebula-win-x64.pending.zip'
$archive = Join-Path $dist 'IronNebula-win-x64.zip'
$createdPublish = $false
$createdPending = $false

if (!(Test-Path -LiteralPath $project)) {
    throw "Windows project not found: $project"
}
if ((Test-Path -LiteralPath $archive) -and !$Overwrite) {
    throw "Release archive already exists; pass -Overwrite to replace it: $archive"
}
if (Test-Path -LiteralPath $publish) {
    throw "Refusing to overwrite existing staging directory: $publish"
}
if (Test-Path -LiteralPath $pending) {
    throw "Refusing to overwrite existing pending archive: $pending"
}

New-Item -ItemType Directory -Path $dist -Force | Out-Null
try {
    dotnet restore $project --force -r win-x64 --verbosity minimal
    if ($LASTEXITCODE -ne 0) {
        throw "Windows package restore failed with exit code $LASTEXITCODE."
    }

    $createdPublish = $true
    dotnet publish $project -c Release -r win-x64 --self-contained true --no-restore `
        -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true `
        -p:DebugType=none -p:DebugSymbols=false -o $publish
    if ($LASTEXITCODE -ne 0) {
        throw "Windows release publish failed with exit code $LASTEXITCODE."
    }
    $executable = Join-Path $publish 'IronNebula.exe'
    $music = Join-Path $publish 'Assets\Audio\Propulsive Peak_stream.wav'
    if (!(Test-Path -LiteralPath $executable) -or !(Test-Path -LiteralPath $music)) {
        throw 'The Windows package must contain the single-file executable and licensed soundtrack.'
    }
    $runtimeAssets = @(Get-ChildItem -LiteralPath (Join-Path $repo 'Assets') -Recurse -File |
        Where-Object { $_.Extension -in '.png', '.jpg', '.wav' })
    foreach ($asset in $runtimeAssets) {
        $relative = $asset.FullName.Substring($repo.Length + 1)
        $destination = Join-Path $publish $relative
        if (!(Test-Path -LiteralPath $destination)) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
            Copy-Item -LiteralPath $asset.FullName -Destination $destination
        }
    }
    $missingAssets = @($runtimeAssets | Where-Object {
        $relative = $_.FullName.Substring($repo.Length + 1)
        !(Test-Path -LiteralPath (Join-Path $publish $relative))
    })
    if ($missingAssets.Count -gt 0) {
        throw "Windows publish omitted runtime assets: $($missingAssets.Name -join ', ')"
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $createdPending = $true
    [IO.Compression.ZipFile]::CreateFromDirectory(
        $publish, $pending, [IO.Compression.CompressionLevel]::Optimal, $false)
    $zip = [IO.Compression.ZipFile]::OpenRead($pending)
    try {
        $entries = @($zip.Entries | ForEach-Object { $_.FullName.Replace('/', '\') })
        $packagedAssets = @($entries | Where-Object { $_.StartsWith('Assets\', [StringComparison]::OrdinalIgnoreCase) })
        if ($entries -notcontains 'IronNebula.exe' -or
            $entries -notcontains 'Assets\Audio\Propulsive Peak_stream.wav' -or
            $entries -notcontains 'Assets\HD\player_sideview_refit.png' -or
        @($entries | Where-Object { $_ -match '\.mp3$' }).Count -gt 0 -or
        $packagedAssets.Count -ne $runtimeAssets.Count -or
            @($entries | Where-Object { $_ -match '\.pdb$' }).Count -gt 0) {
            throw 'Windows release archive is missing required content or includes debug symbols.'
        }
        if (@($entries | Where-Object { $_ -notmatch '^(IronNebula\.exe|Assets\\)' }).Count -gt 0) {
            throw 'Windows release archive contains unexpected top-level files.'
        }
    }
    finally {
        $zip.Dispose()
    }

    if (Test-Path -LiteralPath $archive) {
        Move-Item -LiteralPath $pending -Destination $archive -Force
    }
    else {
        Move-Item -LiteralPath $pending -Destination $archive
    }
    $createdPending = $false
    Write-Output "Windows release archive: $archive"
}
finally {
    if ($createdPublish -and (Test-Path -LiteralPath $publish)) {
        Remove-Item -LiteralPath $publish -Recurse -Force
    }
    if ($createdPending -and (Test-Path -LiteralPath $pending)) {
        Remove-Item -LiteralPath $pending -Force
    }
}
