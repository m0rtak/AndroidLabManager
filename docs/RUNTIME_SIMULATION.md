# Runtime simulation

The package was tested with a fake `podman` and fake `ss` to exercise manager/runtime behavior without a real emulator:

- old six-column records are normalized
- `repair-records` does not shift empty noVNC fields
- noVNC URL rendering does not produce `server:33`
- enabling noVNC on a headless instance allocates a real noVNC port
- spawning multiple noVNC instances does not duplicate ADB/noVNC ports
- disabling noVNC preserves the ADB port and clears the noVNC port

This does not replace real KVM/emulator boot testing, but it catches the record/port/noVNC URL bugs seen in the web manager.
