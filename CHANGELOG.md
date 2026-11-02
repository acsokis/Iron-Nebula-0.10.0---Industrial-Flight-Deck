# Project updates

This document records user-visible milestones. It is not a build-by-build
engineering log; source-control history and the private local engineering notes
retain implementation details.

## Current development

- **Godot preview:** includes a Pro-Arcade HUD and score-attack loop, audio,
  spatial FSR options, textured 3D planets, boss phases, damage-responsive hull
  presentation and physical voxel debris. Automated gameplay and smoke checks
  pass; rendered performance remains hardware-dependent.
- **Browser:** provides the existing WebGL 2 game, optional co-op and mobile
  control, with improved cooperative progression and combat presentation.
- **Windows:** targets .NET 10 and includes damage-responsive metallic hull
  backing and cross-platform gameplay refinements. A Release build, gameplay
  checks and complete-asset release archive pass; clean-machine validation
  remains open.

These updates are development work, not a published release. Release packaging
and publication require the platform-specific acceptance evidence in
[ROADMAP.md](ROADMAP.md).

## Previously delivered capabilities

- Windows campaign progression, desktop audio, save support and controller input.
- Browser flight, sector progression, online co-op and phone control.
- Shared original art direction, platform-specific visual effects and loading
  flows.
- Godot engine preview with a local launcher, input, physics and automated
  regression checks.
