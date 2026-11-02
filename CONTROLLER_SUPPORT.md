# Controller support

Windows supports common XInput controllers and native USB/Bluetooth input for
compatible DualSense devices. Browser gamepad support depends on the browser and
operating system. Godot controller behavior remains subject to platform testing.

## Common controls

| Input | Action |
|---|---|
| Left stick / D-pad | Flight and menu navigation |
| Fire button / right trigger | Fire |
| Shoulder buttons | Change available weapon or page |
| Confirm / back | Activate or return |
| Menu / start | Pause or resume |

The in-game help presents the active control scheme. Keyboard and mouse remain
available on desktop.

## Compatibility notes

- Connect a controller before launching the game when possible.
- Button icons and mappings may differ between platforms and controller models.
- Advanced feedback is hardware-dependent and is not required for gameplay.
- Focus changes, disconnects and reconnects should be checked on the target
  operating system.

Automated input tests use synthetic events; they do not prove physical-device
recognition, vibration quality, trigger behavior or wireless reliability.
Detailed hardware and implementation procedures are maintained outside public
product documentation.
