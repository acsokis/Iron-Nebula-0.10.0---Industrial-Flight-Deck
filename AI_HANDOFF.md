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

- Working branch: `engine/godot-nvidia`; current base commit before this work:
  `4d4547c`. Confirm `git status` and `git log` before committing.
- Windows now targets .NET 10 and includes texture-alpha-aligned metallic
  backing during hull damage, boss attack/shield/damage phases, an exposed-phase
  damage bonus, and restrained party scaling for enemy durability, firing rate
  and pickup rewards. Previously packaged but missing source assets were
  restored to `Assets/`, including the owner-authorized soundtrack.
- The browser and Godot boss/co-op work is present in the existing project
  history. Godot remains a local visual/physics preview, not network co-op or
  full campaign parity.
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
NVIDIA GeForce RTX 4080. Captures are ignored local QA images.

Both release archives were rebuilt and inspected: the Windows ZIP contains one
executable and every runtime asset; the Godot ZIP contains only its executable
and resource pack. These checks do not prove physical controller compatibility,
cross-network co-op, clean-machine installation, long-session stability or
Windows rendered quality. The archives have not been published.

## Open work and constraints

- Complete Windows visual and physical-device review, including the metallic
  hull backing and boss phase transitions.
- Launch both archives in clean environments before publication.
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
