# Online co-op guide

The Windows and browser editions provide separate co-op experiences. A room,
save or invitation is not shared across those platforms. The Godot preview does
not currently include network co-op.

## Joining a session

1. Use the same game edition and compatible build as the host.
2. Select the online co-op option from the main menu.
3. The host creates a room and shares the displayed invitation privately.
4. Guests join with the invitation and wait for the host to begin.
5. Follow the in-game prompts at progression or readiness screens.

Browser co-op requires a modern browser and network access to the configured
signaling service. Windows sessions require direct reachability or an appropriate
private network. Matchmaking and guaranteed Internet relay service are not
provided.

## Session guidance

- Room invitations are access links, not proof of a participant's identity.
- Share invitations only with trusted participants.
- Network conditions and background-tab or window throttling can affect the
  experience.
- Host departure can end the session; reconnect and recovery options vary by
  edition.
- Solo saves remain separate from co-op state.

## Verification boundary

Automated local tests cover representative session behavior. They do not replace
multi-device testing across separate physical computers, routers, networks or
long-duration sessions. Consult the [AI handoff](AI_HANDOFF.md) for the current
platform-specific validation status.
