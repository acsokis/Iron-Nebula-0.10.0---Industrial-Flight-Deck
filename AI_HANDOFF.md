# Iron Nebula - AI handoff

Read this file before project work and update it after each AI session. Record
verified outcomes and open work; do not imply that an unpublished build is a
release. Local-only implementation notes use the ignored `_o_privat.md` suffix.

## Repository map

- `Source/`: Windows MonoGame game and platform-specific features.
- `Web/`: browser game, automated browser tests and static deployment.
- `Godot/`: local 2.5D engine preview and its regression checks.
- `RUN_GODOT_PREVIEW.bat`: project-root launcher for repeatable Godot testing.

The Windows game and helper checks target .NET 10. The three implementations
have separate storage and networking; do not infer platform parity from a
change or test in another implementation.

## Current working state

- Working branch: `engine/godot-nvidia`; implementation commit:
  `ed31f68c45fc4effc2662b2a4eadee09bcef127c` (pushed to the `contribution`
  remote). Its parent baseline is `4d4547c`.
- Windows targets .NET 10 and includes damage-responsive metallic hull
  presentation and cross-platform gameplay refinements. Runtime source art and
  audio are present in `Assets/`; unused legacy sprites were removed. The
  original soundtrack source remains available to the browser edition and is
  excluded from the Windows package.
- Browser and Godot cross-platform work is present in the project history.
  Godot remains a local visual/physics preview, not network co-op or full
  campaign parity.
- Godot includes the themed loading flow and flight-deck menu, multi-depth
  sector backgrounds, a damage-responsive hull frame, and destructible physical
  station/asteroid scenery with bounded debris and effects.
- Public project documentation was refreshed. `PROJECT_NOTES_o_privat.md` is
  local-only and must not be committed, pushed or included in release packages.

## Verification completed

From the repository root in PowerShell:

```powershell
dotnet build IronNebula.csproj -c Release --no-restore --verbosity minimal
dotnet run --project Tools\CoopChecks\CoopChecks.csproj -c Release
dotnet run --project Tools\VisualChecks\VisualChecks.csproj -c Release
.\.engine\godot-nvidia\bin\godot.windows.editor.x86_64.console.exe --headless --path . --editor --quit
.\.engine\godot-nvidia\bin\godot.windows.editor.x86_64.console.exe --headless --path . --script Godot\tests\gameplay_checks.gd
.\.engine\godot-nvidia\bin\godot.windows.editor.x86_64.console.exe --headless --path . --script Godot\tests\smoke.gd
```

Latest results: Windows Release build succeeded with no warnings or errors;
37 co-op transport/gameplay-rule checks and 20 visual/physics checks passed.
Godot import passed, with 18 gameplay checks and 64 smoke checks passing. The
flight-deck menu and gameplay were reviewed in Forward+ raster captures on an
NVIDIA GeForce RTX 4080. Both release archives were extracted and launched
successfully in isolated temporary directories on the development host.

The Windows ZIP contains one executable and 249 required image/audio assets;
the Godot ZIP contains only its executable and resource pack. These checks do
not prove physical controller compatibility, cross-network co-op, clean-machine
installation, long-session stability or Windows rendered quality. The
GitHub release is not published: the available API credential was rejected
and the integrated browser is signed out. Publishing requires an authenticated
GitHub session with release permissions.

## Open work and constraints

- Complete Windows visual and physical-device review, including the metallic
  hull presentation.
- Validate both archives on a clean Windows environment.
- Publish the built archives after authenticated GitHub release access is
  available; do not manually trigger GitHub Actions.
- Run the browser checks if browser source or deployment settings change.
- Do not publish local private notes, user saves, ignored engine caches or
  unverified binaries. Do not manually trigger GitHub Actions.
- Preserve existing local editor settings and Git stashes.

## Handoff maintenance

Before ending future project work, update this file with the exact branch and
revision, changes actually made, commands and results, remaining release gates,
and any user-reverted edits. Keep public notes concise and outcome-oriented;
retain proprietary tuning, implementation rationale and sensitive behavioral
details only in local ignored notes.
