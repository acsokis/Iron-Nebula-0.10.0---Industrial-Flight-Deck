# Godot preview

The Godot build is a local 2.5D visual and physics preview. It is not a replacement
for the complete Windows campaign or browser co-op implementation.

## Run and build

From the repository root:

```powershell
.\RUN_GODOT_PREVIEW.bat
.\RUN_GODOT_PREVIEW.bat --editor
.\Godot\Build-Engine.ps1
```

The launcher uses the project-local engine build under the ignored `.engine/`
directory. The build script requires Windows, Git, Python, Visual Studio C++
tools and a Windows SDK. Do not add the engine source or import cache to release
packages.

The application opens with a themed loading screen and then a flight-deck menu.
Select a destination and flight profile, choose **Enter Flight**, press Escape
to return to the menu, or choose **Exit Preview**. The project-root launcher is
the supported local entry point.

## Preview scope

- Original sector panoramas, atmospheric and star layers, and drifting foreground
  asteroid artwork.
- A metallic hull frame that follows the ship texture silhouette and appears
  during hull damage.
- A physical modular station and destructible asteroid/wreck objects. Weapon hits
  remove voxel cells; destroyed objects release bounded debris.
- Atlas-based impact and destruction effects, keyboard/controller movement and
  the local weapon preview.
- An optional NVIDIA path-tracing path with a Forward+ raster fallback.

This preview does not provide the full campaign, online co-op, desktop save
compatibility or confirmed parity with the browser and Windows implementations.
Rendering and controller support must be assessed on the target hardware.

## Verification

```powershell
.\.engine\godot-nvidia\bin\godot.windows.editor.x86_64.console.exe --headless --path . --editor --quit
.\.engine\godot-nvidia\bin\godot.windows.editor.x86_64.console.exe --headless --path . --script Godot\tests\gameplay_checks.gd
.\.engine\godot-nvidia\bin\godot.windows.editor.x86_64.console.exe --headless --path . --script Godot\tests\smoke.gd
```

The smoke check covers menu and loading state, sector selection, weapon firing,
ship damage presentation and physical asteroid damage. Headless checks do not
validate image quality or hardware behavior.

For local visual review, append `-- --capture-preview` to capture the menu, or
`-- --raster-preview --capture-flight-preview` to capture gameplay in raster
mode. Captures are saved under the ignored `.godot/` directory.

## Packaging

`PUBLISH_GODOT_PREVIEW.bat` creates a compact Windows preview archive containing
the optimized executable and resource pack. Build and launch that archive on a
clean machine before publication. Editor files, engine source, import caches and
private project notes do not belong in the release.
