# Iron Nebula — browser guide

The browser implementation is a static WebGL 2 game. Solo play does not require
a game server. Browser rooms, phone links and local saves are separate from the
Windows and Godot applications.

## Play

- **Launch Solo** starts a local run. **Continue** resumes a browser save when
  available.
- **Host Wing** creates an online room. Share the displayed invite only with
  intended participants; guests select **Join Wing**. Keep the host tab open
  during play.
- **Phone Pad** pairs a phone with its local game window for touch control.
- Keyboard, mouse and supported gamepads can be used. The on-screen hints follow
  the active input device.

### Controls

| Input | Action |
|---|---|
| WASD / arrow keys | Move |
| Mouse movement / touch | Flight control |
| Space / left mouse / gamepad fire | Fire |
| Shift / right mouse | Precision control |
| Number keys | Select an available weapon |
| Tab / Q | Change weapon or sector where available |
| Escape / P | Open the local menu |
| C | Ready at a co-op transition |

Exact controls can vary by platform and active controller; use the in-game help
for the current layout.

## Graphics and audio

The browser build uses original project artwork, layered space backgrounds and
WebGL effects. Graphics options are capability-gated; unsupported displays use
the standard presentation path. Display output and physical HDR quality require
hardware verification.

Sound begins after a user gesture, as required by browser policy. The project
includes synthesized effects and music controls. The desktop soundtrack is
included only within the owner-approved project distribution.

## Privacy and connection scope

Online play depends on browser connectivity and external signaling services.
Peer-to-peer sessions can expose connection information to participants and
network service providers. Room invitations are access links, not identity
verification. Do not share them publicly or use them with untrusted guests.

Phone control requests no camera or microphone permission. Scan the displayed
pairing code with the phone's normal camera application and use the deployed
secure page for remote devices.

## Development and verification

The workflow uses Node and a lockfile. From this directory:

```powershell
npm.cmd ci --ignore-scripts
npm.cmd test
npm.cmd run build
npm.cmd run release:verify
npm.cmd run test:browser
npm.cmd run dev
```

Browser tests run with Playwright and local test services. Their results do not
replace testing on physical phones, gamepads, HDR displays or separate Internet
connections. Browser source maps, local test controls and unapproved media are
not part of a production package.

## Publication

The repository includes a GitHub Pages deployment workflow. The site owner must
enable or approve publication; workflow runs should not be started manually for
routine local validation. Release readiness and platform status are tracked in
the [AI handoff](../AI_HANDOFF.md) and [roadmap](../ROADMAP.md).
