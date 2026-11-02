# Iron Nebula

Iron Nebula is an independent science-fiction arcade project maintained across
Windows, browser and Godot implementations. Each platform has a distinct scope;
feature parity and release readiness are tracked separately.

## Platform overview

- **Windows:** .NET 10 MonoGame desktop application with campaign progression,
  controller support, damage-responsive hull presentation and phased boss
  encounters. Release validation is recorded in the [AI handoff](AI_HANDOFF.md).
- **Browser:** WebGL 2 game with solo play, optional online co-op and phone
  control. See the [browser guide](Web/README.md).
- **Godot:** local 2.5D engine preview for visual and physics evaluation. It is
  not a replacement for the complete desktop or browser game. See the
  [Godot preview guide](Godot/README.md).

The shared visual direction includes original sector art, readable combat
effects and damage-responsive ship presentation. The Godot preview is developing
layered scenery, an industrial flight deck and destructible physical space
objects. These features are not claims of cross-platform parity.

## Build and run

- Windows development requires the .NET 10 SDK and Windows build tools. Run
  `BUILD_WINDOWS.bat`; `PUBLISH_WINDOWS.bat` creates the compact release ZIP.
- Browser development uses the commands in [Web/README.md](Web/README.md).
- Godot preview uses the root launcher, `RUN_GODOT_PREVIEW.bat`. Local engine
  build and verification instructions are in [Godot/README.md](Godot/README.md).

## Project records

- [AI handoff and verified state](AI_HANDOFF.md)
- [Release roadmap](ROADMAP.md)
- [Project updates](CHANGELOG.md)
- [Pre-release verification checklist](TEST_CHECKLIST_HU.md)
- [Controller guide](CONTROLLER_SUPPORT.md)
- [Co-op guide](COOP_SUPPORT.md)
- [Security review summary](Web/SECURITY_AUDIT.md)

The browser, Windows and Godot builds use separate storage and networking
contracts. Do not assume that a save, room or feature is transferable between
platforms. Required third-party notices accompany the relevant project assets.
