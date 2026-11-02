# Iron Nebula — AI Handoff

Read this file before changing the project. Update it at the end of each AI
session with verified changes, tests, branch/commit state and remaining work.
Do not treat a partial implementation as a release.

## Project shape

- `Source/` is the Windows MonoGame game. The `desktop-release-hardening`
  branch targets .NET 10; the `engine/godot-nvidia` branch still has its own
  project-file history. Do not switch branches with local work unstashed.
- `Web/` is the WebGL2 game and browser P2P implementation.
- `Godot/` is an experimental engine preview, not a full campaign or network
  co-op port. `RUN_GODOT_PREVIEW.bat` at the repository root launches it.
- The requested gameplay scope is cross-platform: a damage-dependent,
  texture-alpha-matched metallic hull frame; boss attack/shield/damage phases;
  restrained enemy scaling as co-op party size increases; and improved pickup
  yields for larger parties.

## Verified work in this handoff

On `engine/godot-nvidia`, feature commit `170dd6a` adds the gameplay scope to
Web and the Godot preview. The current branch also contains the documentation
and handoff follow-up; neither commit has been pushed.

- Web package version is `0.10.0` (development; not published).
- Web hull frames appear when damaged and disappear at full repair. Bosses use
  a 13-second cycle: 6 seconds attack, 3 shield, 4 damage. The shield blocks
  damage and the damage window amplifies hits. Enemy HP rises 8% per extra
  player, up to 40%; enemy fire rate and projectile speed rise 2.5% per extra
  player. Five/six-player health, shield and credit pickups give one extra unit.
- Godot preview has the matching damage frame, boss cycle, party-size scaling
  and larger-party health/shield pickups. `--party-size=1..6` exercises party
  scaling; it does not add actual multiplayer.
- The Windows desktop has **not** received these gameplay changes.

## Verification

All commands below passed on the current Web/Godot source:

```powershell
cd Web
npm.cmd test
.\node_modules\.bin\playwright.cmd test features.spec.js -g "six separate browsers exchange real P2P movement, shots and ready state" --workers=1 --repeat-each=3
.\node_modules\.bin\playwright.cmd test damage.spec.js --workers=1
npm.cmd run build
npm.cmd run release:verify
cd ..
.\.engine\godot-nvidia\bin\godot.windows.editor.x86_64.console.exe --headless --path . --script Godot\tests\gameplay_checks.gd
```

Results: 33 Web unit tests passed; the six-browser P2P test passed three times;
the damage Playwright test passed; the production build passed (with the
existing >700 kB chunk-size warning); release verification passed for 61 files
(13.85 MiB); Godot printed `PASS: 16` gameplay checks. The full browser suite
and the .NET 10 desktop Release build were not run for this feature milestone.
Playwright Chromium was installed in the user profile because the prior local
browser cache had completion markers but no executable.

## Branches, local state and constraints

- Current intended source branch: `engine/godot-nvidia`; feature commit `170dd6a`.
- `desktop-release-hardening` remains at `c0137d1` and was clean after a
  desktop implementation attempt was undone in the editor during the session.
  Do not restore or re-create those source edits without the user's explicit
  request.
- The desktop branch, docs, releases, GitHub push and GitHub Release are not
  complete. No Actions workflow was manually started.
- Preserve `stash@{0}` ("Preserve local VS and Godot settings"), which contains
  machine-local `IronNebula.sln`, `project.godot` and
  `Properties/launchSettings.json`. Existing stashes `stash@{1}` and
  `stash@{2}` predate this task; do not drop or pop them automatically.
- Keep ignored `.engine/` and `.godot/` runtime/build caches.
- The original developer's sound-distribution rights were confirmed by the
  user; do not remove the requested soundtrack.

## Next steps

1. Continue only after respecting the editor undo; ask before reapplying those
   desktop source changes.
2. Port and test the same hull, boss-cycle, party and pickup behavior in the
   .NET 10 desktop branch, including both projectile and beam damage paths.
3. Run the .NET 10 Release build and targeted checks. Reconcile version and
   release documentation only after platform parity is verified.
4. Build minimal Windows and Godot release archives; keep archives as GitHub
   Release assets rather than Git blobs. Clean only known generated packaging
   artifacts.
5. Commit and push only after validation. Do not manually trigger Actions.
