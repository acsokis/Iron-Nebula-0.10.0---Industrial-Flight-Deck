# Iron Nebula — delivery roadmap

This roadmap defines player-facing outcomes and the evidence required before
publication. Implementation notes, tuning rationale and internal design records
are maintained locally and are not part of public release documentation.

## Current delivery position

| Platform | Current scope | Evidence required before release |
|---|---|---|
| Windows | .NET 10 MonoGame campaign, controller support and phased boss encounters | Clean-machine build, gameplay checks and package launch |
| Browser | WebGL 2 solo and online co-op experience | Deployment verification, physical-device testing and sustained-session checks |
| Godot | Playable 2.5D visual and physics preview | Rendered GPU review, collision/destruction validation and a published parity statement |

Passing automated tests does not establish hardware compatibility, complete
campaign quality or cross-platform equivalence.

## Milestones

### Platform stabilization

- Preserve the Windows and browser experiences while validating platform
  specific damage, boss phases, co-op balance and Godot preview work.
- Complete platform-specific smoke, input, graphics and save checks.
- Resolve release-blocking defects before publishing build artifacts.

### Godot preview readiness

- Validate the themed loading and flight-deck screens on supported display sizes.
- Review layered backgrounds, ship presentation, effects and physical damage on
  an actual GPU.
- Confirm resource packaging, launch behavior and the documented limitations.

### Connected play

- Verify co-op operation on separate physical devices and networks.
- Confirm disconnect, recovery and session-exit behavior.
- Document platform boundaries without exposing internal implementation details.

### Stable release

- Complete clean installation, performance, accessibility, legal and security
  reviews.
- Publish verified packages and user-facing release notes.
- Assign any public product identifier only when a release is approved.
